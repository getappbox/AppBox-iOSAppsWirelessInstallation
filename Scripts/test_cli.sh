#!/bin/bash
#
# AppBox CLI Test Script
# Tests multiple upload scenarios with various option combinations.
# Replace dummy values with real ones before running.
#

set -e

# Timeout per test in seconds (kill test if it hangs)
TEST_TIMEOUT=900 # 15 minutes

# Parse arguments: pass test numbers to run specific tests
# Usage: ./test_cli.sh          (run all tests)
#        ./test_cli.sh 15       (run only test 15)
#        ./test_cli.sh 1,2,15   (run tests 1, 2, and 15)
#        APPBOX_CLI=/path/to/appboxcli ./test_cli.sh 18,19   (test a local build)
RUN_TESTS=""
if [ -n "$1" ]; then
    RUN_TESTS=",$1,"
fi

# ============================================================
# CONFIGURATION - Replace these with real values before running
# ============================================================

IPA_PATH="/path/to/your/small-app.ipa"
LARGE_IPA_PATH="/path/to/your/large-app.ipa"
EMAILS="dev1@example.com,dev2@example.com"
SINGLE_EMAIL="tester@example.com"
MESSAGE="New build {BUILD_NAME} v{BUILD_VERSION} ({BUILD_NUMBER}) is ready for testing!"
WEBHOOK_MESSAGE="🚀 *{BUILD_NAME}* v{BUILD_VERSION} ({BUILD_NUMBER}) uploaded!\nInstall: {SHARE_URL}"
SLACK_WEBHOOK="https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
MSTEAMS_WEBHOOK="https://outlook.office.com/webhook/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX/IncomingWebhook/XXXXXXXXXXXXXXXX/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
DB_FOLDER="TestScriptBuilds"

# Path to appboxcli binary (adjust if needed, or set APPBOX_CLI)
CLI="${APPBOX_CLI:-appboxcli}"

# Log file (overwritten each run)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/test_cli.log"
> "$LOG_FILE"

# Tee helper: write to both stdout and log file (strips color codes for log)
log() {
    echo -e "$@"
    echo -e "$@" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE"
}

# ============================================================
# TEST HELPERS
# ============================================================

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
TEST_NUM=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    log ""
    log "============================================================"
    log " AppBox CLI Test Suite"
    log "============================================================"
    log ""
}

run_test() {
    local test_name="$1"
    shift
    local cmd="$@"

    TEST_NUM=$((TEST_NUM + 1))

    # Skip if not in the filter list
    if [ -n "$RUN_TESTS" ] && [[ "$RUN_TESTS" != *",$TEST_NUM,"* ]]; then
        return
    fi

    log "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${CYAN}TEST $TEST_NUM: $test_name${NC}"
    log "${CYAN}CMD:  $cmd${NC}"
    log "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    local output
    local exit_code
    local tmp_output
    tmp_output=$(mktemp)

    # Run command in background with timeout
    bash -c "$cmd" > "$tmp_output" 2>&1 &
    local cmd_pid=$!

    # Wait with timeout
    local elapsed=0
    while kill -0 "$cmd_pid" 2>/dev/null; do
        if [ $elapsed -ge $TEST_TIMEOUT ]; then
            kill -9 "$cmd_pid" 2>/dev/null
            wait "$cmd_pid" 2>/dev/null
            output=$(cat "$tmp_output")
            rm -f "$tmp_output"
            log "${RED}⏱️  TIMEOUT: $test_name (exceeded ${TEST_TIMEOUT}s)${NC}"
            FAIL_COUNT=$((FAIL_COUNT + 1))
            if [ -n "$output" ]; then
                echo "$output" >> "$LOG_FILE"
            fi
            log ""
            return
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done

    exit_code=0
    wait "$cmd_pid" || exit_code=$?
    output=$(cat "$tmp_output")
    rm -f "$tmp_output"

    if [ $exit_code -eq 0 ]; then
        log "${GREEN}✅ PASSED: $test_name${NC}"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        log "${RED}❌ FAILED: $test_name (exit code: $exit_code)${NC}"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    # Log command output
    if [ -n "$output" ]; then
        echo "$output" >> "$LOG_FILE"
    fi
    log ""
}

skip_test() {
    local test_name="$1"
    local reason="$2"

    TEST_NUM=$((TEST_NUM + 1))

    # Skip if not in the filter list
    if [ -n "$RUN_TESTS" ] && [[ "$RUN_TESTS" != *",$TEST_NUM,"* ]]; then
        return
    fi

    log "${YELLOW}⏭️  SKIPPED TEST $TEST_NUM: $test_name${NC}"
    log "${YELLOW}    Reason: $reason${NC}"
    SKIP_COUNT=$((SKIP_COUNT + 1))
    log ""
}

print_summary() {
    log ""
    log "============================================================"
    log " TEST SUMMARY"
    log "============================================================"
    log " Total:   $TEST_NUM"
    log " ${GREEN}Passed:  $PASS_COUNT${NC}"
    log " ${RED}Failed:  $FAIL_COUNT${NC}"
    log " ${YELLOW}Skipped: $SKIP_COUNT${NC}"
    log "============================================================"
    log ""
    log "Log file: $LOG_FILE"

    if [ $FAIL_COUNT -gt 0 ]; then
        exit 1
    fi
}

check_prerequisites() {
    log "Checking prerequisites..."

    # Check CLI exists
    if ! command -v "$CLI" &>/dev/null; then
        log "${RED}ERROR: '$CLI' not found in PATH.${NC}"
        log "  Install with: AppBox > Menu > Install CLI"
        log "  Or set CLI variable to the full binary path."
        exit 1
    fi
    log "  ✓ CLI found: $(which $CLI)"

    # Check IPA exists
    if [ ! -f "$IPA_PATH" ]; then
        log "${RED}ERROR: IPA file not found at: $IPA_PATH${NC}"
        log "  Update IPA_PATH in this script."
        exit 1
    fi
    log "  ✓ IPA found: $IPA_PATH ($(du -h "$IPA_PATH" | cut -f1))"

    # Check large IPA exists
    if [ ! -f "$LARGE_IPA_PATH" ]; then
        log "${YELLOW}WARNING: Large IPA file not found at: $LARGE_IPA_PATH${NC}"
        log "  Large file test will be skipped."
    else
        log "  ✓ Large IPA found: $LARGE_IPA_PATH ($(du -h "$LARGE_IPA_PATH" | cut -f1))"
    fi

    # Check Dropbox auth (CLI requires AppBox to be authenticated)
    log "  ⚠ Make sure AppBox has an active Dropbox session."
    log ""
}

# ============================================================
# SCENARIO HELPERS (exported so run_test's `bash -c` can call them)
# ============================================================

# The install link the last upload wrote to ~/.appbox_share_value.json.
last_share_url() {
    local url
    url=$(plutil -extract APPBOX_SHARE_URL raw -o - "$HOME/.appbox_share_value.json") && [ -n "$url" ] && echo "$url"
}

# Fails unless the newest build in `appboxcli list` kept `link` in `folder`.
expect_newest_build() {
    local cli="$1" folder="$2" link="$3"
    local listing newest
    listing=$("$cli" list) || return 1
    if [[ "$(sed -n 1p <<< "$listing")" != *"SAME LINK"* ]]; then
        echo "$cli has no SAME LINK column in 'list'; set APPBOX_CLI to a build of this branch."
        return 1
    fi
    newest=$(sed -n 2p <<< "$listing")
    if [[ "$newest" != *"  $folder  "* || "$newest" != *"$link"* ]]; then
        echo "Expected the newest build to keep $link in $folder, got: $newest"
        return 1
    fi
}

# Two keep-same-link uploads into a nested folder share one link, and list shows the whole folder.
nested_folder_keeps_link() {
    local cli="$1" ipa="$2" folder="$3"
    local first_link second_link
    "$cli" --ipa "$ipa" --keepsamelink --dbfolder "$folder" || return 1
    first_link=$(last_share_url) || return 1
    "$cli" --ipa "$ipa" --keepsamelink --dbfolder "$folder" || return 1
    second_link=$(last_share_url) || return 1
    if [ "$first_link" != "$second_link" ]; then
        echo "The nested folder didn't keep its link: $first_link, then $second_link"
        return 1
    fi
    expect_newest_build "$cli" "$folder" "$second_link"
}

# Deleting the only build in a nested folder removes that folder, not its parent.
nested_folder_delete_keeps_parent() {
    local cli="$1" ipa="$2" parent="$3"
    local child="$parent/App$(date +%Y%m%d%H%M%S)"
    local parent_link child_link relinked
    "$cli" --ipa "$ipa" --keepsamelink --dbfolder "$parent" || return 1
    parent_link=$(last_share_url) || return 1
    "$cli" --ipa "$ipa" --keepsamelink --dbfolder "$child" || return 1
    child_link=$(last_share_url) || return 1
    expect_newest_build "$cli" "$child" "$child_link" || return 1
    printf '1\ny\n' | "$cli" delete || return 1
    "$cli" --ipa "$ipa" --keepsamelink --dbfolder "$parent" || return 1
    relinked=$(last_share_url) || return 1
    if [ "$relinked" != "$parent_link" ]; then
        echo "The parent folder lost its link ($parent_link) when its nested folder's last build was deleted."
        return 1
    fi
}

export -f last_share_url expect_newest_build nested_folder_keeps_link nested_folder_delete_keeps_parent

# ============================================================
# TEST CASES
# ============================================================

print_header
check_prerequisites

# ---------- Test 1: Basic upload (IPA only, minimum args) ----------
run_test "Basic upload - IPA only" \
    "$CLI --ipa \"$IPA_PATH\""

# ---------- Test 2: Upload with single email ----------
run_test "Upload with single email" \
    "$CLI --ipa \"$IPA_PATH\" --emails \"$SINGLE_EMAIL\""

# ---------- Test 3: Upload with multiple emails ----------
run_test "Upload with multiple emails" \
    "$CLI --ipa \"$IPA_PATH\" --emails \"$EMAILS\""

# ---------- Test 4: Upload with emails + custom message ----------
run_test "Upload with emails and custom message" \
    "$CLI --ipa \"$IPA_PATH\" --emails \"$EMAILS\" --message \"$MESSAGE\""

# ---------- Test 5: Upload with keep same link ----------
run_test "Upload with --keepsamelink" \
    "$CLI --ipa \"$IPA_PATH\" --keepsamelink"

# ---------- Test 6: Upload with keep same link + custom folder ----------
run_test "Upload with --keepsamelink and --dbfolder" \
    "$CLI --ipa \"$IPA_PATH\" --keepsamelink --dbfolder \"$DB_FOLDER\""

# ---------- Test 7: Upload with Slack webhook ----------
run_test "Upload with Slack webhook" \
    "$CLI --ipa \"$IPA_PATH\" --slackwebhook \"$SLACK_WEBHOOK\""

# ---------- Test 8: Upload with Slack webhook + custom message ----------
run_test "Upload with Slack webhook and custom message" \
    "$CLI --ipa \"$IPA_PATH\" --slackwebhook \"$SLACK_WEBHOOK\" --webhookmessage \"$WEBHOOK_MESSAGE\""

# ---------- Test 9: Upload with MS Teams webhook ----------
run_test "Upload with MS Teams webhook" \
    "$CLI --ipa \"$IPA_PATH\" --msteamswebhook \"$MSTEAMS_WEBHOOK\""

# ---------- Test 10: Upload with MS Teams webhook + custom message ----------
run_test "Upload with MS Teams webhook and custom message" \
    "$CLI --ipa \"$IPA_PATH\" --msteamswebhook \"$MSTEAMS_WEBHOOK\" --webhookmessage \"$WEBHOOK_MESSAGE\""

# ---------- Test 11: Upload with both Slack and Teams webhooks ----------
run_test "Upload with both Slack and MS Teams webhooks" \
    "$CLI --ipa \"$IPA_PATH\" --slackwebhook \"$SLACK_WEBHOOK\" --msteamswebhook \"$MSTEAMS_WEBHOOK\" --webhookmessage \"$WEBHOOK_MESSAGE\""

# ---------- Test 12: Full options (everything combined) ----------
run_test "Full upload - all options combined" \
    "$CLI --ipa \"$IPA_PATH\" \
        --emails \"$EMAILS\" \
        --message \"$MESSAGE\" \
        --keepsamelink \
        --dbfolder \"$DB_FOLDER\" \
        --slackwebhook \"$SLACK_WEBHOOK\" \
        --msteamswebhook \"$MSTEAMS_WEBHOOK\" \
        --webhookmessage \"$WEBHOOK_MESSAGE\""

# ---------- Test 13: Keep same link without dbfolder (uses bundle ID) ----------
run_test "Upload with --keepsamelink without --dbfolder (default bundle ID folder)" \
    "$CLI --ipa \"$IPA_PATH\" --keepsamelink --emails \"$SINGLE_EMAIL\" --message \"$MESSAGE\""

# ---------- Test 14: Emails + webhooks (no custom messages) ----------
run_test "Upload with emails + webhooks, no custom messages" \
    "$CLI --ipa \"$IPA_PATH\" --emails \"$EMAILS\" --slackwebhook \"$SLACK_WEBHOOK\" --msteamswebhook \"$MSTEAMS_WEBHOOK\""

# ---------- Test 15: Invalid IPA path (should fail gracefully) ----------
run_test "Invalid IPA path - should fail gracefully" \
    "! $CLI --ipa \"/nonexistent/path/fake.ipa\""

# ---------- Test 16: No arguments (should show usage error) ----------
run_test "No arguments - should show usage error" \
    "! $CLI"

# ---------- Test 17: Large IPA file upload (chunked upload) ----------
if [ -f "$LARGE_IPA_PATH" ]; then
    run_test "Large IPA file upload (chunked session upload)" \
        "$CLI --ipa \"$LARGE_IPA_PATH\""
else
    skip_test "Large IPA file upload (chunked session upload)" \
        "LARGE_IPA_PATH not found: $LARGE_IPA_PATH"
fi

# ---------- Test 18: Keep same link in a nested custom folder ----------
run_test "Upload twice with --keepsamelink into a nested --dbfolder (same link, full folder listed)" \
    "nested_folder_keeps_link \"$CLI\" \"$IPA_PATH\" \"$DB_FOLDER/Nested/App\""

# ---------- Test 19: Delete the last build of a nested folder, parent keeps its link ----------
if pgrep -xq AppBox; then
    skip_test "Delete the only build in a nested --dbfolder (parent keeps its link)" \
        "AppBox is running, and appboxcli delete refuses to run alongside it"
else
    run_test "Delete the only build in a nested --dbfolder (parent keeps its link)" \
        "nested_folder_delete_keeps_parent \"$CLI\" \"$IPA_PATH\" \"$DB_FOLDER/NestedDelete\""
fi

# ============================================================
# SUMMARY
# ============================================================

print_summary
