//
//  Log.swift
//
//
//  Created by Vineet Choudhary on 16/09/23.
//

import Foundation
import Logging

/// Logger for AppBox
///
/// Log Levels:
/// `trace` Appropriate for messages that contain information normally of use only when tracing the execution of a program.
///
/// `debug` Appropriate for messages that contain information normally of use only when debugging a program.
///
/// `info` Appropriate for informational messages.
///
/// `notice` Appropriate for conditions that are not error conditions, but that may require special handling.
///
/// `warning` Appropriate for messages that are not error conditions, but more severe than `.notice`.
///
/// `error` Appropriate for error conditions.
///
/// `critical` Appropriate for critical error conditions that usually require immediate  attention.
///
public final class Log {
	private static var initialized = false
	private static var logger = Logger(label: "AppBox")

	private init() { }

	static func initialize() {
		if initialized {
			Log.info("Log class already initialised.")
			return
		}

		logger.logLevel = .trace

		initialized = true
	}

	public static func trace(
		_ message: String,
		source: String? = nil,
		context: Any? = nil,
		file: String = #fileID, function: String = #function, line: UInt = #line) {
			logger.trace(
				.init(stringLiteral: messageWithContext(message: message, context: context)),
				source: source,
				file: file,
				function: function,
				line: line)
		}

	public static func debug(
		_ message: String,
		source: String? = nil,
		context: Any? = nil,
		file: String = #fileID, function: String = #function, line: UInt = #line) {
			logger.debug(
				.init(stringLiteral: messageWithContext(message: message, context: context)),
				source: source,
				file: file,
				function: function,
				line: line)
		}

	public static func info(
		_ message: String,
		source: String? = nil,
		context: Any? = nil,
		file: String = #fileID, function: String = #function, line: UInt = #line) {
			logger.info(
				.init(stringLiteral: messageWithContext(message: message, context: context)),
				source: source,
				file: file,
				function: function,
				line: line)
		}

	public static func notice(
		_ message: String,
		source: String? = nil,
		context: Any? = nil,
		file: String = #fileID, function: String = #function, line: UInt = #line) {
			logger.notice(
				.init(stringLiteral: messageWithContext(message: message, context: context)),
				source: source,
				file: file,
				function: function,
				line: line)
		}

	public static func warning(
		_ message: String,
		source: String? = nil,
		context: Any? = nil,
		file: String = #fileID, function: String = #function, line: UInt = #line) {
			logger.warning(
				.init(stringLiteral: messageWithContext(message: message, context: context)),
				source: source,
				file: file,
				function: function,
				line: line)
		}

	public static func error(
		_ message: String,
		source: String? = nil,
		context: Any? = nil,
		file: String = #fileID, function: String = #function, line: UInt = #line) {
			logger.error(
				.init(stringLiteral: messageWithContext(message: message, context: context)),
				source: source,
				file: file,
				function: function,
				line: line)
		}

	public static func critical(
		_ message: String,
		source: String? = nil,
		context: Any? = nil,
		file: String = #fileID, function: String = #function, line: UInt = #line) {
			logger.critical(
				.init(stringLiteral: messageWithContext(message: message, context: context)),
				source: source,
				file: file,
				function: function,
				line: line)
		}

	private static func messageWithContext(message: String, context: Any?) -> String {
		context == nil ? message : message + "\nContext: \(String(describing: context))"
	}
}
