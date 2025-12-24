import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_native_logger/simple_native_logger.dart';
import 'package:simple_native_logger/simple_native_logger_platform_interface.dart';
import 'package:simple_native_logger/simple_native_logger_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSimpleNativeLoggerPlatform
    with MockPlatformInterfaceMixin
    implements SimpleNativeLoggerPlatform {
  int level = 0;
  String tag = "";
  String message = "";
  bool useIsLoggable = false;

  @override
  Future<void> log(
      int level, String tag, String message, bool useIsLoggable) async {
    this.level = level;
    this.tag = tag;
    this.message = message;
    this.useIsLoggable = useIsLoggable;
  }

  void clear() {
    level = 0;
    tag = "";
    message = "";
    useIsLoggable = false;
  }
}

// utility fuction to log by each level
void testUtilLogByLevel(
    SimpleNativeLogger logger, LogLevel level, Object message,
    {StackTrace? stack}) {
  switch (level) {
    case LogLevel.verbose:
      logger.v(message, stack: stack);
      break;
    case LogLevel.debug:
      logger.d(message, stack: stack);
      break;
    case LogLevel.info:
      logger.i(message, stack: stack);
      break;
    case LogLevel.warning:
      logger.w(message, stack: stack);
      break;
    case LogLevel.error:
      logger.e(message, stack: stack);
      break;
    case LogLevel.fatal:
      logger.f(message, stack: stack);
      break;
    default:
      break;
  }
}

void main() {
  final SimpleNativeLoggerPlatform initialPlatform =
      SimpleNativeLoggerPlatform.instance;
  SimpleNativeLogger.init();

  test('MethodChannelNativeLogger is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSimpleNativeLogger>());
  });

  test('log basic test', () async {
    const tag = "TAG";
    const message = "LogMessage";

    SimpleNativeLogger nativeLoggerPlugin =
        SimpleNativeLogger(tag: tag, addLineNumber: false);
    MockSimpleNativeLoggerPlatform fakePlatform =
        MockSimpleNativeLoggerPlatform();
    SimpleNativeLoggerPlatform.instance = fakePlatform;

    for (final level in LogLevel.values) {
      if (level == LogLevel.silent) {
        continue;
      }
      debugPrint("testing for level: $level");
      fakePlatform.clear();
      testUtilLogByLevel(nativeLoggerPlugin, level, message);
      await Future.delayed(const Duration(seconds: 1));
      expect(fakePlatform.level, level.index);
      expect(fakePlatform.tag, tag);
      expect(fakePlatform.message, message);

      expect(SimpleNativeLogger.cachedLogList.length, 1);
      final logInfo = SimpleNativeLogger.cachedLogList[0];
      expect(logInfo.level, level);
      expect(logInfo.tag, tag);
      expect(logInfo.message, message);

      SimpleNativeLogger.cachedLogList.clear();
    }
  });

  test('suppress log by loglevel', () async {
    const tag = "TAG2";
    const message = "LogMessage";

    SimpleNativeLogger nativeLoggerPlugin = SimpleNativeLogger(
        tag: tag, logLevel: LogLevel.warning, addLineNumber: false);
    final fakePlatform = MockSimpleNativeLoggerPlatform();
    SimpleNativeLoggerPlatform.instance = fakePlatform;

    for (final level in [LogLevel.warning, LogLevel.error, LogLevel.fatal]) {
      debugPrint("testing for level: $level");
      fakePlatform.clear();
      testUtilLogByLevel(nativeLoggerPlugin, level, message);
      await Future.delayed(const Duration(seconds: 1));

      expect(fakePlatform.level, level.index);
      expect(fakePlatform.tag, tag);
      expect(fakePlatform.message, message);
    }

    for (final level in [LogLevel.verbose, LogLevel.debug, LogLevel.info]) {
      debugPrint("testing for level: $level");
      fakePlatform.clear();
      testUtilLogByLevel(nativeLoggerPlugin, level, message);
      await Future.delayed(const Duration(seconds: 1));

      expect(fakePlatform.level, 0);
      expect(fakePlatform.tag, isEmpty);
      expect(fakePlatform.message, isEmpty);
    }
  });

  test('log with line number', () async {
    const tag = "TAG";
    const message = "LogMessage";

    SimpleNativeLogger nativeLoggerPlugin =
        SimpleNativeLogger(tag: tag, addLineNumber: true);
    final fakePlatform = MockSimpleNativeLoggerPlatform();
    SimpleNativeLoggerPlatform.instance = fakePlatform;

    for (final level in LogLevel.values) {
      if (level == LogLevel.silent) {
        continue;
      }
      debugPrint("testing for level: $level");
      fakePlatform.clear();
      testUtilLogByLevel(nativeLoggerPlugin, level, message);
      await Future.delayed(const Duration(seconds: 1));

      //debugPrint('message: ${fakePlatform.message}');
      expect(fakePlatform.level, level.index);
      expect(fakePlatform.tag, tag);
      expect(fakePlatform.message, startsWith(message));
      expect(fakePlatform.message,
          contains('native_logger_test')); // this filename
    }
  });

  test('log with full stack', () async {
    const tag = "TAG";
    final ex = Exception("log message");
    final message = ex.toString();

    SimpleNativeLogger nativeLoggerPlugin =
        SimpleNativeLogger(tag: tag, stackCount: -1);
    final fakePlatform = MockSimpleNativeLoggerPlatform();
    SimpleNativeLoggerPlatform.instance = fakePlatform;

    final stack = StackTrace.current;
    //debugPrint("stack: $stack");
    final actualStackCount = stack.toString().split("\n").length;

    for (final level in LogLevel.values) {
      if (level == LogLevel.silent) {
        continue;
      }
      debugPrint("testing for level: $level");
      fakePlatform.clear();
      testUtilLogByLevel(nativeLoggerPlugin, level, ex, stack: stack);
      await Future.delayed(const Duration(seconds: 1));

      //debugPrint('message: ${fakePlatform.message}');
      expect(fakePlatform.level, level.index);
      expect(fakePlatform.tag, tag);
      expect(fakePlatform.message, startsWith(message));

      final messageList = fakePlatform.message.split("\n");
      expect(messageList.length, actualStackCount + 2);
      expect(messageList[1], "stack trace:");
    }
  });

  test('log with limited stack', () async {
    const tag = "TAG";
    final ex = Exception("log message");
    final message = ex.toString();
    const stackCount = 2;

    final nativeLoggerPlugin =
        SimpleNativeLogger(tag: tag, stackCount: stackCount);
    final fakePlatform = MockSimpleNativeLoggerPlatform();
    SimpleNativeLoggerPlatform.instance = fakePlatform;

    final stack = StackTrace.current;
    //debugPrint("stack: $stack");
    //final actualStackCount = stack.toString().split("\n").length;

    for (final level in LogLevel.values) {
      if (level == LogLevel.silent) {
        continue;
      }
      debugPrint("testing for level: $level");
      fakePlatform.clear();
      testUtilLogByLevel(nativeLoggerPlugin, level, ex, stack: stack);
      await Future.delayed(const Duration(seconds: 1));

      // debugPrint('message: ${fakePlatform.message}');
      expect(fakePlatform.level, level.index);
      expect(fakePlatform.tag, tag);
      expect(fakePlatform.message, startsWith(message));

      final messageList = fakePlatform.message.split("\n");
      expect(messageList.length, stackCount + 2);
      expect(messageList[1], "stack trace:");
    }
  });

  test('useIsLoggable test', () async {
    const tag = "TAG";
    const message = "LogMessage";

    var nativeLoggerPlugin = SimpleNativeLogger(tag: tag, useIsLoggable: false);
    MockSimpleNativeLoggerPlatform fakePlatform =
        MockSimpleNativeLoggerPlatform();
    SimpleNativeLoggerPlatform.instance = fakePlatform;

    for (final level in LogLevel.values) {
      if (level == LogLevel.silent) {
        continue;
      }
      debugPrint("testing for level: $level");
      fakePlatform.clear();
      testUtilLogByLevel(nativeLoggerPlugin, level, message);
      await Future.delayed(const Duration(seconds: 1));
      expect(fakePlatform.level, level.index);
      expect(fakePlatform.tag, tag);
      expect(fakePlatform.message, contains(message));
      expect(fakePlatform.useIsLoggable, false);
    }

    nativeLoggerPlugin = SimpleNativeLogger(tag: tag, useIsLoggable: true);
    for (final level in LogLevel.values) {
      if (level == LogLevel.silent) {
        continue;
      }
      debugPrint("testing for level: $level");
      fakePlatform.clear();
      testUtilLogByLevel(nativeLoggerPlugin, level, message);
      await Future.delayed(const Duration(seconds: 1));
      expect(fakePlatform.level, level.index);
      expect(fakePlatform.tag, tag);
      expect(fakePlatform.message, contains(message));
      expect(fakePlatform.useIsLoggable, true);
    }
  });

  test('cached log list is limited by count', () async {
    const tag = "TAG";

    SimpleNativeLogger nativeLoggerPlugin =
        SimpleNativeLogger(tag: tag, addLineNumber: false);
    MockSimpleNativeLoggerPlatform fakePlatform =
        MockSimpleNativeLoggerPlatform();
    SimpleNativeLoggerPlatform.instance = fakePlatform;

    for (int i = 0; i < 150; i++) {
      nativeLoggerPlugin.i("log message $i");
    }
    await Future.delayed(const Duration(seconds: 1));
    expect(SimpleNativeLogger.cachedLogList.length,
        SimpleNativeLogger.maxLogCount);
    expect(SimpleNativeLogger.cachedLogList[0].message, "log message 50");
    expect(SimpleNativeLogger.cachedLogList[99].message, "log message 149");

    // change max log count
    SimpleNativeLogger.maxLogCount = 5;
    for (int i = 0; i < 3; i++) {
      nativeLoggerPlugin.i("additional log message $i");
    }
    await Future.delayed(const Duration(seconds: 1));
    expect(SimpleNativeLogger.cachedLogList.length,
        SimpleNativeLogger.maxLogCount);
    expect(SimpleNativeLogger.cachedLogList[0].message, 'log message 148');
    expect(SimpleNativeLogger.cachedLogList[4].message,
        'additional log message 2');
  });
}
