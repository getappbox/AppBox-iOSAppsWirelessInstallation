#!/bin/bash
#
#  build-release.sh
#  AppBox
#
#  Builds, signs (Developer ID) and packages the shippable products into one versioned
#  release directory:
#
#    dist/AppBox-<version>/
#      AppBox.dmg         the GUI app, drag-to-Applications (what getappbox.com/download serves)
#      AppBox.app.zip     the same AppBox.app, zipped (what install.sh downloads)
#      appboxcli.zip      the standalone CLI (binary + AppBoxCore resource bundle + install.sh)
#
#  Usage:  Scripts/build-release.sh [actions] [targets] [options]
#  Run    Scripts/build-release.sh --help  for the flag list.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$REPO_ROOT/AppBox.xcodeproj"
CONFIGURATION="Release"

TEAM_ID="${APPBOX_TEAM_ID:-3PQ7E4L589}"
SIGN_IDENTITY="${APPBOX_SIGN_IDENTITY:-Developer ID Application}"
KEYCHAIN_PROFILE="${APPBOX_NOTARY_PROFILE:-}"
OUTPUT_DIR="$REPO_ROOT/dist"

# Actions (composable; no action flag at all means --build).
RUN_TESTS=0
DO_BUILD=0
NOTARIZE=0

# Targets (neither flag means both).
BUILD_GUI=0
BUILD_CLI=0

SIGN=1
# On by default: getappbox.com/download links straight at the release's
# AppBox.dmg, so a GUI release without one 404s for every visitor.
MAKE_DMG=1
CLEAN=0
VERBOSE=0
VERSION_OVERRIDE=""
TEST_SUITES="all"
TEST_TIMEOUT="${APPBOX_TEST_TIMEOUT:-1200}"

RED=$'\033[1;31m'; GREEN=$'\033[1;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[1;34m'; RESET=$'\033[0m'
log()  { printf '%s==>%s %s\n' "$BLUE" "$RESET" "$*"; }
ok()   { printf '%s  ✓%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '%swarning:%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
die()  { printf '%serror:%s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }

usage() {
	cat <<'USAGE'
Build, sign and package the AppBox GUI app and the standalone appboxcli tool.

  Scripts/build-release.sh [actions] [targets] [options]

Actions — combine freely. Short flags cluster, so -tb is -t -b. Default: -b.
  -t, --test                  Run the unit tests. On failure nothing is built.
  -b, --build                 Build, sign and package.
  -n, --notarize              Notarize and staple (implies -b).

Targets — default: both.
  -g, --gui                   AppBox.app.
  -c, --cli                   The standalone appboxcli.

Options
  -s, --suite <core|app|all>  Suites -t runs (default: all). core = the AppBoxCore package,
                              app = the AppBoxTests test plan.
  -T, --test-timeout <secs>   Per-suite watchdog (default: 1200). See the note below.
  -d, --dmg                   Produce a DMG for the GUI (implies -b). On by default.
      --no-dmg                Skip the DMG. Faster, but do not ship such a build:
                              getappbox.com/download links directly at AppBox.dmg.
  -i, --identity <name>       Signing identity (default: "Developer ID Application").
  -k, --keychain-profile <p>  notarytool keychain profile to notarize with.
  -V, --release-version <v>   Override the version in the release directory name.
  -o, --output <dir>          Output directory (default: dist/).
  -C, --clean                 Remove the output directory first.
  -v, --verbose               Stream full xcodebuild and test output.
      --team-id <id>          Development team (default: 3PQ7E4L589).
      --no-sign               Skip code signing (local smoke builds; not distributable).
  -h, --help                  Show this help.

Every long option also accepts --name=value.

Examples
  Scripts/build-release.sh -tb                test, then build both products
  Scripts/build-release.sh -t -s core         only the AppBoxCore package tests
  Scripts/build-release.sh -bc                build only the standalone CLI
  Scripts/build-release.sh -tbndk AppBox      test, build, DMG, notarize + staple

Tests
  `core` runs `xcrun swift test` in AppBoxCore (never bare `swift` — the swiftly toolchain on
  PATH cannot build against the Xcode SDK). `app` runs the AppBoxTests test plan, whose host
  app is known to hang at launch in DropboxSession.setup on some machines — the watchdog kills
  it and the run fails rather than blocking a release; `-s core` skips it entirely.

Notarization credentials
  Preferred:  xcrun notarytool store-credentials "AppBox" \
                --apple-id <id> --team-id <team> --password <app-specific-password>
              then run with -k AppBox (or APPBOX_NOTARY_PROFILE=AppBox).
  Otherwise:  export APPLE_ID, APPLE_TEAM_ID and APPLE_APP_PASSWORD.
USAGE
}

# Short flags, split by whether they consume the next argument. Only the last flag of a
# cluster may take a value — `-tbndk AppBox` is `-t -b -n -d -k AppBox`.
NO_VALUE_SHORT_FLAGS="tbngcdCvh"
VALUE_SHORT_FLAGS="sTikVo"

# Normalises the command line before parsing: splits --name=value pairs and unpacks short-flag
# clusters. A cluster the rules above cannot explain is passed through for the parser to reject.
expand_args() {
	EXPANDED_ARGS=()
	local arg name value index last char allowed clusterable
	for arg in "$@"; do
		case "$arg" in
			--*=*)
				name="${arg%%=*}"
				value="${arg#*=}"
				EXPANDED_ARGS+=("$name" "$value")
				continue
				;;
			--*)
				;;
			-?*)
				clusterable=1
				last=$(( ${#arg} - 1 ))
				for (( index = 1; index <= last; index++ )); do
					char="${arg:$index:1}"
					if [ "$index" -eq "$last" ]; then
						allowed="$NO_VALUE_SHORT_FLAGS$VALUE_SHORT_FLAGS"
					else
						allowed="$NO_VALUE_SHORT_FLAGS"
					fi
					case "$allowed" in
						*"$char"*) ;;
						*) clusterable=0; break ;;
					esac
				done
				if [ "$clusterable" -eq 1 ]; then
					for (( index = 1; index <= last; index++ )); do
						EXPANDED_ARGS+=("-${arg:$index:1}")
					done
					continue
				fi
				;;
		esac
		EXPANDED_ARGS+=("$arg")
	done
}

if [ $# -gt 0 ]; then
	expand_args "$@"
	set -- "${EXPANDED_ARGS[@]}"
fi

while [ $# -gt 0 ]; do
	case "$1" in
		-t|--test) RUN_TESTS=1 ;;
		-b|--build) DO_BUILD=1 ;;
		-n|--notarize) NOTARIZE=1; DO_BUILD=1 ;;
		-g|--gui) BUILD_GUI=1 ;;
		-c|--cli) BUILD_CLI=1 ;;
		-d|--dmg) MAKE_DMG=1; DO_BUILD=1 ;;
		--no-dmg) MAKE_DMG=0 ;;
		-s|--suite) TEST_SUITES="${2:?-s needs core, app or all}"; shift ;;
		-T|--test-timeout) TEST_TIMEOUT="${2:?-T needs a value in seconds}"; shift ;;
		-i|--identity) SIGN_IDENTITY="${2:?-i needs an identity name}"; shift ;;
		-k|--keychain-profile) KEYCHAIN_PROFILE="${2:?-k needs a profile name}"; shift ;;
		-V|--release-version) VERSION_OVERRIDE="${2:?-V needs a version}"; shift ;;
		-o|--output) OUTPUT_DIR="${2:?-o needs a directory}"; shift ;;
		-C|--clean) CLEAN=1 ;;
		-v|--verbose) VERBOSE=1 ;;
		--team-id) TEAM_ID="${2:?--team-id needs a value}"; shift ;;
		--no-sign) SIGN=0 ;;
		-h|--help) usage; exit 0 ;;
		*) die "unknown option: $1 (try --help)" ;;
	esac
	shift
done

case "$TEST_SUITES" in
	core|app|all) ;;
	*) die "-s/--suite takes core, app or all (got \"$TEST_SUITES\")" ;;
esac

if [ "$RUN_TESTS" -eq 0 ] && [ "$DO_BUILD" -eq 0 ]; then
	DO_BUILD=1
fi
if [ "$BUILD_GUI" -eq 0 ] && [ "$BUILD_CLI" -eq 0 ]; then
	BUILD_GUI=1
	BUILD_CLI=1
fi

# MARK: - Preflight

preflight() {
	command -v xcodebuild >/dev/null || die "xcodebuild not found. Install Xcode and run xcode-select --switch."
	[ -d "$PROJECT" ] || die "AppBox.xcodeproj not found at $PROJECT"

	if [ "$DO_BUILD" -eq 0 ]; then
		return 0
	fi

	if [ ! -f "$REPO_ROOT/.env" ]; then
		warn "no .env at the repo root — the build will embed EMPTY secrets (see .env.example)."
		warn "Dropbox login and the AppBox backend will not work in the produced binaries."
	fi

	if [ "$SIGN" -eq 1 ]; then
		security find-identity -v -p codesigning | grep -q "$SIGN_IDENTITY" \
			|| die "no codesigning identity matching \"$SIGN_IDENTITY\" in the keychain."
	else
		warn "signing disabled — the artifacts are for local testing only."
		[ "$NOTARIZE" -eq 0 ] || die "-n/--notarize requires signing; drop --no-sign."
	fi

	if [ "$NOTARIZE" -eq 1 ] && [ -z "$KEYCHAIN_PROFILE" ]; then
		: "${APPLE_ID:?--notarize needs --keychain-profile or APPLE_ID/APPLE_TEAM_ID/APPLE_APP_PASSWORD}"
		: "${APPLE_APP_PASSWORD:?--notarize needs APPLE_APP_PASSWORD (an app-specific password)}"
	fi
}

resolve_version() {
	if [ -n "$VERSION_OVERRIDE" ]; then
		printf '%s' "$VERSION_OVERRIDE"
		return
	fi
	local value
	value="$(xcodebuild -project "$PROJECT" -target AppBox -configuration "$CONFIGURATION" -showBuildSettings 2>/dev/null \
		| awk -F' = ' '/[[:space:]]MARKETING_VERSION = /{ gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit }')"
	[ -n "$value" ] || die "could not read MARKETING_VERSION from the project."
	printf '%s' "$value"
}

signing_args() {
	if [ "$SIGN" -eq 1 ]; then
		printf '%s\n' \
			"CODE_SIGN_STYLE=Manual" \
			"CODE_SIGN_IDENTITY=$SIGN_IDENTITY" \
			"DEVELOPMENT_TEAM=$TEAM_ID" \
			"PROVISIONING_PROFILE_SPECIFIER=" \
			"OTHER_CODE_SIGN_FLAGS=--timestamp"
	else
		printf '%s\n' \
			"CODE_SIGN_IDENTITY=-" \
			"CODE_SIGNING_REQUIRED=NO" \
			"CODE_SIGNING_ALLOWED=NO"
	fi
}

run_xcodebuild() {
	local log="$1"; shift
	if [ "$VERBOSE" -eq 1 ]; then
		xcodebuild "$@" 2>&1 | tee "$log"
	else
		xcodebuild "$@" 2>&1 | tee "$log" | grep -E '(^\*\*|error:|warning: unable)' || true
	fi
	local status="${PIPESTATUS[0]}"
	[ "$status" -eq 0 ] || { tail -40 "$log" >&2; die "xcodebuild failed — full log: $log"; }
}

sign_path() {
	[ "$SIGN" -eq 1 ] || return 0
	codesign --force --timestamp --options runtime --sign "$SIGN_IDENTITY" "$1"
}

# MARK: - Tests

# Runs a command to a log file under a watchdog, so a hung test host cannot stall a release.
# Returns the command's exit status, or 124 when the watchdog fired.
run_step_with_timeout() {
	local seconds="$1" log="$2"
	shift 2
	"$@" > "$log" 2>&1 &
	local pid=$! tail_pid="" waited=0 status=0
	if [ "$VERBOSE" -eq 1 ]; then
		tail -f -n +1 "$log" & tail_pid=$!
	fi
	while kill -0 "$pid" 2>/dev/null; do
		if [ "$waited" -ge "$seconds" ]; then
			kill -TERM "$pid" 2>/dev/null || true
			sleep 3
			kill -KILL "$pid" 2>/dev/null || true
			[ -z "$tail_pid" ] || kill "$tail_pid" 2>/dev/null || true
			wait "$pid" 2>/dev/null || true
			return 124
		fi
		sleep 5
		waited=$(( waited + 5 ))
		if [ "$VERBOSE" -eq 0 ] && [ $(( waited % 120 )) -eq 0 ]; then
			printf '    …still running (%dm)\n' "$(( waited / 60 ))"
		fi
	done
	wait "$pid" || status=$?
	[ -z "$tail_pid" ] || kill "$tail_pid" 2>/dev/null || true
	return "$status"
}

report_suite_failure() {
	local name="$1" status="$2" log="$3"
	if [ "$status" -eq 124 ]; then
		warn "$name timed out after ${TEST_TIMEOUT}s (raise it with -T/--test-timeout)."
		tail -5 "$log" | sed 's/^/    /' >&2
	else
		warn "$name failed (exit $status)."
		local highlights
		highlights="$(grep -E "error:|XCTAssert|Test Case .* failed|Test run with .* failure" "$log" | tail -20 || true)"
		if [ -n "$highlights" ]; then
			printf '%s\n' "$highlights" | sed 's/^/    /' >&2
		else
			tail -20 "$log" | sed 's/^/    /' >&2
		fi
	fi
	printf '    full log: %s\n' "$log" >&2
}

run_tests() {
	local failed=0 status=0

	if [ "$TEST_SUITES" = "all" ] || [ "$TEST_SUITES" = "core" ]; then
		log "Testing the AppBoxCore package…"
		local core_log="$OUTPUT_DIR/logs/test-core.log"
		# `xcrun swift`, never bare `swift`: a swiftly-managed toolchain on PATH cannot build
		# against the Xcode SDK.
		if run_step_with_timeout "$TEST_TIMEOUT" "$core_log" \
			bash -c 'cd "$1" && exec xcrun swift test' _ "$REPO_ROOT/AppBoxCore"; then
			ok "AppBoxCore package tests passed"
		else
			status=$?
			report_suite_failure "the AppBoxCore package tests" "$status" "$core_log"
			failed=1
		fi
	fi

	if [ "$TEST_SUITES" = "all" ] || [ "$TEST_SUITES" = "app" ]; then
		log "Running the AppBoxTests test plan…"
		local app_log="$OUTPUT_DIR/logs/test-app.log"
		if run_step_with_timeout "$TEST_TIMEOUT" "$app_log" \
			xcodebuild test -project "$PROJECT" -scheme AppBoxTests -testPlan AppBoxTests \
				-destination 'platform=macOS' \
				CODE_SIGN_IDENTITY= CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO; then
			ok "AppBoxTests test plan passed"
		else
			status=$?
			report_suite_failure "the AppBoxTests test plan" "$status" "$app_log"
			[ "$status" -ne 124 ] || warn "the test host is known to hang at launch in DropboxSession.setup; -s core skips this suite."
			failed=1
		fi
	fi

	[ "$failed" -eq 0 ] || die "tests failed — nothing was built or packaged."
	ok "all requested tests passed"
}

# MARK: - GUI

build_gui() {
	local version="$1"
	local archive="$OUTPUT_DIR/AppBox.xcarchive"
	local export_dir="$OUTPUT_DIR/gui-export"

	log "Archiving AppBox.app ($CONFIGURATION)…"
	rm -rf "$archive" "$export_dir"
	local -a args
	while IFS= read -r line; do args+=("$line"); done < <(signing_args)
	run_xcodebuild "$OUTPUT_DIR/logs/gui-archive.log" archive \
		-project "$PROJECT" -scheme AppBox -configuration "$CONFIGURATION" \
		-destination 'generic/platform=macOS' \
		-archivePath "$archive" \
		"${args[@]}"

	if [ "$SIGN" -eq 1 ]; then
		log "Exporting with the Developer ID profile…"
		cat > "$OUTPUT_DIR/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>developer-id</string>
	<key>teamID</key>
	<string>$TEAM_ID</string>
	<key>signingStyle</key>
	<string>manual</string>
	<key>signingCertificate</key>
	<string>$SIGN_IDENTITY</string>
	<key>destination</key>
	<string>export</string>
	<key>stripSwiftSymbols</key>
	<true/>
</dict>
</plist>
PLIST
		run_xcodebuild "$OUTPUT_DIR/logs/gui-export.log" -exportArchive \
			-archivePath "$archive" \
			-exportOptionsPlist "$OUTPUT_DIR/ExportOptions.plist" \
			-exportPath "$export_dir"
	else
		mkdir -p "$export_dir"
		cp -R "$archive/Products/Applications/AppBox.app" "$export_dir/"
	fi

	GUI_APP="$export_dir/AppBox.app"
	[ -d "$GUI_APP" ] || die "AppBox.app not produced (looked in $export_dir)"

	local embedded="$GUI_APP/Contents/SharedSupport/appboxcli"
	[ -x "$embedded" ] || warn "appboxcli is missing from AppBox.app/Contents/SharedSupport — the app's CLI installer will not work."
	[ -d "$GUI_APP/Contents/SharedSupport/AppBoxCore_AppBoxCore.bundle" ] \
		|| warn "AppBoxCore_AppBoxCore.bundle is missing from SharedSupport — the embedded CLI cannot load the Core Data model."

	verify_signature "$GUI_APP"
	ok "AppBox.app $version"
}

# MARK: - Standalone CLI

build_cli() {
	local version="$1"
	local derived="$OUTPUT_DIR/cli-derived"
	local products="$derived/Build/Products/$CONFIGURATION"

	log "Building appboxcli ($CONFIGURATION)…"
	rm -rf "$derived"
	local -a args
	while IFS= read -r line; do args+=("$line"); done < <(signing_args)
	run_xcodebuild "$OUTPUT_DIR/logs/cli-build.log" build \
		-project "$PROJECT" -scheme AppBoxCLI -configuration "$CONFIGURATION" \
		-destination 'generic/platform=macOS' \
		-derivedDataPath "$derived" \
		"${args[@]}"

	[ -x "$products/appboxcli" ] || die "appboxcli not produced (looked in $products)"
	[ -d "$products/AppBoxCore_AppBoxCore.bundle" ] \
		|| die "AppBoxCore_AppBoxCore.bundle not produced — the CLI cannot load the Core Data model without it."

	CLI_STAGE="$OUTPUT_DIR/cli-stage/appboxcli"
	rm -rf "$CLI_STAGE"
	mkdir -p "$CLI_STAGE"
	cp "$products/appboxcli" "$CLI_STAGE/"
	cp -R "$products/AppBoxCore_AppBoxCore.bundle" "$CLI_STAGE/"
	write_cli_installer "$CLI_STAGE/install.sh"

	# The resource bundle is signed first: it is nested payload, and the tool's own signature must be the last one written.
	sign_path "$CLI_STAGE/AppBoxCore_AppBoxCore.bundle"
	sign_path "$CLI_STAGE/appboxcli"

	verify_signature "$CLI_STAGE/appboxcli"
	ok "appboxcli $version ($(du -h "$CLI_STAGE/appboxcli" | cut -f1 | tr -d ' '))"
}

write_cli_installer() {
	cat > "$1" <<'INSTALLER'
#!/bin/bash
#
# Installs the standalone AppBox CLI. The tool loads its Core Data model from the
# AppBoxCore_AppBoxCore.bundle sitting next to the executable, so both are copied into
# <prefix>/lib/appbox and only the executable is symlinked onto PATH.
#
#   ./install.sh              install into /usr/local
#   PREFIX=~/.local ./install.sh
#   ./install.sh --uninstall

set -euo pipefail

PREFIX="${PREFIX:-/usr/local}"
LIB_DIR="$PREFIX/lib/appbox"
BIN_DIR="$PREFIX/bin"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

uninstall() {
	rm -f "$BIN_DIR/appboxcli"
	rm -rf "$LIB_DIR"
	echo "Removed appboxcli from $PREFIX."
}

install_cli() {
	mkdir -p "$LIB_DIR" "$BIN_DIR"
	rm -rf "$LIB_DIR/appboxcli" "$LIB_DIR/AppBoxCore_AppBoxCore.bundle"
	cp "$SOURCE_DIR/appboxcli" "$LIB_DIR/"
	cp -R "$SOURCE_DIR/AppBoxCore_AppBoxCore.bundle" "$LIB_DIR/"
	ln -sfn "$LIB_DIR/appboxcli" "$BIN_DIR/appboxcli"
	echo "Installed appboxcli to $BIN_DIR/appboxcli"
	case ":$PATH:" in
		*":$BIN_DIR:"*) ;;
		*) echo "Note: $BIN_DIR is not on your PATH." ;;
	esac
	echo "Run 'appboxcli login' to connect your Dropbox account."
}

if [ "${1:-}" = "--uninstall" ]; then
	action=uninstall
else
	action=install_cli
fi

if [ -w "$PREFIX" ] || [ -w "$(dirname "$PREFIX")" ]; then
	"$action"
else
	echo "$PREFIX is not writable; re-running with sudo."
	exec sudo -p "Password for %u to write to $PREFIX: " PREFIX="$PREFIX" bash "${BASH_SOURCE[0]}" "$@"
fi
INSTALLER
	chmod +x "$1"
}

# MARK: - Verify / package / notarize

verify_signature() {
	local target="$1"
	[ "$SIGN" -eq 1 ] || return 0
	codesign --verify --strict --verbose=1 "$target" 2>&1 | sed 's/^/    /'
	codesign --display --verbose=2 "$target" 2>&1 | grep -E 'Authority=|TeamIdentifier=|flags=' | sed 's/^/    /' || true
}

zip_artifact() {
	local source="$1" destination="$2"
	rm -f "$destination"
	ditto -c -k --sequesterRsrc --keepParent "$source" "$destination"
}

make_dmg() {
	local app="$1" version="$2"
	local dmg="$RELEASE_DIR/AppBox.dmg"
	local staging="$OUTPUT_DIR/dmg-staging"
	log "Building the DMG…"
	rm -rf "$staging" "$dmg"
	mkdir -p "$staging"
	cp -R "$app" "$staging/"
	ln -s /Applications "$staging/Applications"
	hdiutil create -volname "AppBox $version" -srcfolder "$staging" -ov -format UDZO "$dmg" >/dev/null
	rm -rf "$staging"
	[ "$SIGN" -eq 0 ] || codesign --force --timestamp --sign "$SIGN_IDENTITY" "$dmg"
	DMG_PATH="$dmg"
	ok "$(basename "$dmg")"
}

notarize_artifact() {
	local artifact="$1"
	local -a args=(submit "$artifact" --wait)
	if [ -n "$KEYCHAIN_PROFILE" ]; then
		args+=(--keychain-profile "$KEYCHAIN_PROFILE")
	else
		args+=(--apple-id "$APPLE_ID" --team-id "${APPLE_TEAM_ID:-$TEAM_ID}" --password "$APPLE_APP_PASSWORD")
	fi
	log "Notarizing $(basename "$artifact")…"

	# notarytool does not reliably exit non-zero on a completed-but-rejected submission, and a
	# bare executable cannot be stapled, so the status is checked here rather than being left to
	# a later stapler call.
	local log_file="$OUTPUT_DIR/logs/notarize-$(basename "$artifact").log"
	local status=0
	xcrun notarytool "${args[@]}" > "$log_file" 2>&1 || status=$?
	sed 's/^/    /' "$log_file"
	[ "$status" -eq 0 ] || die "notarytool failed for $(basename "$artifact") (exit $status) — see $log_file"
	grep -qi 'status: Accepted' "$log_file" \
		|| die "notarization was not accepted for $(basename "$artifact") — see $log_file, and 'xcrun notarytool log <submission-id>' for the reasons."

	local submission_id
	submission_id="$(awk '/id:/ { print $2; exit }' "$log_file")"
	[ -z "$submission_id" ] || printf '    submission %s accepted\n' "$submission_id"
}

# MARK: - Main

preflight
[ "$CLEAN" -eq 0 ] || rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/logs"

[ "$RUN_TESTS" -eq 0 ] || run_tests

if [ "$DO_BUILD" -eq 0 ]; then
	exit 0
fi

VERSION="$(resolve_version)"
log "AppBox $VERSION — team $TEAM_ID, identity \"$SIGN_IDENTITY\"$([ "$SIGN" -eq 1 ] || printf ' (SIGNING OFF)')"

RELEASE_DIR="$OUTPUT_DIR/AppBox-$VERSION"
mkdir -p "$RELEASE_DIR"

GUI_APP=""
CLI_STAGE=""
DMG_PATH=""
ARTIFACTS=()

if [ "$BUILD_GUI" -eq 1 ]; then
	build_gui "$VERSION"
	GUI_ZIP="$RELEASE_DIR/AppBox.app.zip"
	zip_artifact "$GUI_APP" "$GUI_ZIP"
	if [ "$NOTARIZE" -eq 1 ]; then
		notarize_artifact "$GUI_ZIP"
		xcrun stapler staple "$GUI_APP"
		zip_artifact "$GUI_APP" "$GUI_ZIP"
		spctl --assess --type exec --verbose=2 "$GUI_APP" 2>&1 | sed 's/^/    /' || warn "spctl rejected AppBox.app"
	fi
	ARTIFACTS+=("$GUI_ZIP")
	if [ "$MAKE_DMG" -eq 1 ]; then
		make_dmg "$GUI_APP" "$VERSION"
		if [ "$NOTARIZE" -eq 1 ]; then
			notarize_artifact "$DMG_PATH"
			xcrun stapler staple "$DMG_PATH"
		fi
		ARTIFACTS+=("$DMG_PATH")
	fi
fi

if [ "$BUILD_CLI" -eq 1 ]; then
	build_cli "$VERSION"
	CLI_ZIP="$RELEASE_DIR/appboxcli.zip"
	zip_artifact "$CLI_STAGE" "$CLI_ZIP"
	if [ "$NOTARIZE" -eq 1 ]; then
		notarize_artifact "$CLI_ZIP"
		warn "a bare executable cannot be stapled; Gatekeeper checks the CLI's notarization online on first run."
	fi
	ARTIFACTS+=("$CLI_ZIP")
fi

log "Release $VERSION — $RELEASE_DIR"
for artifact in "${ARTIFACTS[@]}"; do
	printf '    %s  %s  %s\n' \
		"$(shasum -a 256 "$artifact" | cut -d' ' -f1)" \
		"$(du -h "$artifact" | cut -f1 | tr -d ' ')" \
		"$(basename "$artifact")"
done
