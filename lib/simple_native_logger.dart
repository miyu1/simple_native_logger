
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'simple_native_logger_platform_interface.dart';

enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  fatal,
  // special log level to suppress all log output
  // do not use this with log method
  silent
}

class SimpleNativeLogger { 
  // static initialize method.
  // This method must be called once before using NativeLogger class
  static void init() {
    if (!_isInitialized) {
      _listenerLoop();
    }
  }

  // constructor
  SimpleNativeLogger({
    this.tag = 'flutter',
    this.logLevel = LogLevel.verbose,
    this.stackCount = 3,
    this.addLineNumber = true
  });

  // categorize log message.
  // for android, mapped to tag parameter
  // for iOS/macos, mapped to category parameter
  String tag;

  // determin which log level to output.
  // .verbose : every log to output
  // .silent : every log to suppress
  // If .error is set for example,
  // .error and .fatal to output and other to suppress.
  LogLevel logLevel;

  // number of stack trace to be logged.
  // set -1 to full stack 
  int stackCount;

  // set true when add source filename and line number to log message
  bool addLineNumber;

  // log verbose message
  void v(Object message, {StackTrace? stack}) {
    log(LogLevel.verbose, message, stack);
  }

  // log debug message
  void d(Object message, {StackTrace? stack}) {
    log(LogLevel.debug, message, stack);
  }

  // log info message
  void i(Object message, {StackTrace? stack}) {
    log(LogLevel.info, message, stack);
  }

  // log warning message
  void w(Object message, {StackTrace? stack}) {
    log(LogLevel.warning, message, stack);
  }

  // log error message
  void e(Object message, {StackTrace? stack}) {
    log(LogLevel.error, message, stack);
  }

  // log fatal message
  void f(Object message, {StackTrace? stack}) {
    log(LogLevel.fatal, message, stack);
  }

  // low level log method
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
    } else  if(addLineNumberTmp) {
      final traces = StackTrace.current.toString().split("\n");
      //print(traces);
      var index = 1;
      while(true) {
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

  // internal method to determine whether echo back needed
  bool isEchoNeeded(LogLevel logLevel) {
    if (kReleaseMode) {
      return false;
    }
    if (Platform.isAndroid) {
      return false;
    }
    return true;
  }

  void echo(LogInfo info) {
    var kind = "";

    switch(info.level) {
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
    await for(final value in stream) {
      await NativeLoggerPlatform.instance.log(value.level.index, value.tag, value.message);
    }
  }
}

class LogInfo {
  LogInfo(this.level, this.tag, this.message);

  final LogLevel level;
  final String tag;
  final String message;
}