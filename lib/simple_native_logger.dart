import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'simple_native_logger_platform_interface.dart';

/// Log level. This also is used as [SimpleNativeLogger.logLevel] property.
enum LogLevel {
  /// Verbose log level. This is lowest log level.
  verbose,

  /// Debug log level
  debug,

  /// Information log level
  info,

  /// Warning log level
  warning,

  /// Error log level
  error,

  /// Fatal log level. This is highest log level.
  fatal,

  /// Special log level to suppress all log output.
  silent
}

/// Main class of this plugin.
///
/// Example :
/// ```dart
/// import 'package:simple_native_logger/simple_native_logger.dart';
///
/// void main() {
///   SimpleNativeLogger.init();
///   ...
/// }
///   ...
///   final _nativeLogger = SimpleNativeLogger(tag: "MyApp");
///   _nativeLogger.w("<log message>");
///
///   try {
///     ...
///   } catch (ex, stack) {
///     _nativeLogger.e(ex, stack: stack);
///   }
/// ```
///
/// Following table is list of logging methods and it's corresponding platform methods.
///
/// | methods | android | iOS/macos |
/// -|-|-
/// | [SimpleNativeLogger.v] | Log.v | Logger.debug |
/// | [SimpleNativeLogger.d] | Log.d | Logger.debug |
/// | [SimpleNativeLogger.i] | Log.i | Logger.info |
/// | [SimpleNativeLogger.w] | Log.w | Logger.notice |
/// | [SimpleNativeLogger.e] | Log.e | Logger.error |
/// | [SimpleNativeLogger.f] | Log.wtf | Logger.fault |
///
class SimpleNativeLogger {
  /// static initialize method.
  ///
  /// This method must be called once before using this class.
  static void init() {
    if (!_isInitialized) {
      _listenerLoop();
    }
  }

  SimpleNativeLogger(
      {this.tag = 'flutter',
      this.logLevel = LogLevel.verbose,
      this.stackCount = 3,
      this.addLineNumber = true});

  /// Used to categorize log message.
  ///
  /// for android, mapped to tag parameter
  /// for iOS/macos, mapped to category parameter
  String tag;

  /// Determine which log level to output.
  ///
  /// .verbose : every log to output
  /// .silent : every log to suppress
  /// If .error is set for example,
  /// error and fatal log to output and other to suppress.
  LogLevel logLevel;

  /// Depth of stack trace to be logged.
  ///
  /// This property is used if optional stack trace parameter is
  /// passed to logging methods.
  /// Set minus value to log full stack .
  int stackCount;

  /// Whether add source filename and line number to log message
  bool addLineNumber;

  /// Log verbose message
  void v(Object message, {StackTrace? stack}) {
    log(LogLevel.verbose, message, stack);
  }

  /// Log debug message
  void d(Object message, {StackTrace? stack}) {
    log(LogLevel.debug, message, stack);
  }

  /// Log info message
  void i(Object message, {StackTrace? stack}) {
    log(LogLevel.info, message, stack);
  }

  /// Log warning message
  void w(Object message, {StackTrace? stack}) {
    log(LogLevel.warning, message, stack);
  }

  /// Log error message
  void e(Object message, {StackTrace? stack}) {
    log(LogLevel.error, message, stack);
  }

  /// Log fatal message
  void f(Object message, {StackTrace? stack}) {
    log(LogLevel.fatal, message, stack);
  }

  /// Low level log method.
  void log(LogLevel level, Object message, StackTrace? stack) {
    if (level == LogLevel.silent) {
      return;
    }

    if (level.index < logLevel.index) {
      return;
    }

    var addLineNumberTmp = addLineNumber;
    if (message is FlutterErrorDetails) {
      // FlutterErrorDetails contains stacktrace,
      // so line number is not needed
      addLineNumberTmp = false;
    }

    var str1 = message.toString();
    if (stack != null) {
      var stackStr = "";
      if (stackCount < 0) {
        stackStr = stack.toString();
      } else if (stackCount > 0) {
        final traces = stack.toString().split("\n");
        var count = stackCount;
        if (traces.length < count) {
          count = traces.length;
        }
        stackStr = traces.sublist(0, count).join("\n");
      }
      if (stackStr.isNotEmpty) {
        str1 += "\nstack trace:\n$stackStr";
      }
    } else if (addLineNumberTmp) {
      final traces = StackTrace.current.toString().split("\n");
      //print(traces);
      var index = 1;
      while (true) {
        if (traces[index].contains('NativeLogger.')) {
          index += 1;
          continue;
        }
        break;
      }
      final index2 = traces[index].indexOf("(");
      str1 += " ${traces[index].substring(index2)}";
    }

    final logInfo = LogInfo(level, tag, str1);
    _streamController.add(logInfo);

    //final tt = isEchoNeeded(logInfo.level);
    //print("isEchoNeeded: $tt");
    if (isEchoNeeded(logInfo.level)) {
      echo(logInfo);
    }
  }

  /// Internal method used to determine whether echo back needed.
  ///
  /// If you want change echo function, override this method.
  bool isEchoNeeded(LogLevel logLevel) {
    if (kReleaseMode) {
      return false;
    }
    if (Platform.isAndroid) {
      return false;
    }
    return true;
  }

  /// Internal method used to echo back to console.
  ///
  /// If you want change echo function, override this method.
  void echo(LogInfo info) {
    var kind = "";

    switch (info.level) {
      case LogLevel.verbose:
        kind = "V";
        break;
      case LogLevel.debug:
        kind = "D";
        break;
      case LogLevel.info:
        kind = "I";
        break;
      case LogLevel.warning:
        kind = "W";
        break;
      case LogLevel.error:
        kind = "E";
        break;
      case LogLevel.fatal:
        kind = "F";
        break;
      default:
        break;
    }
    debugPrint("[${info.tag}:$kind] ${info.message}");
  }

  static final _streamController = StreamController<LogInfo>();
  static var _isInitialized = false;

  // eternal loop to await for log request
  static void _listenerLoop() async {
    _isInitialized = true;
    final stream = _streamController.stream;
    await for (final value in stream) {
      await SimpleNativeLoggerPlatform.instance
          .log(value.level.index, value.tag, value.message);
    }
  }
}

/// This structure is internally used by [SimpleNativeLogger]
class LogInfo {
  LogInfo(this.level, this.tag, this.message);

  final LogLevel level;
  final String tag;
  final String message;
}
