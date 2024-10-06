import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_native_logger/simple_native_logger.dart';
import 'package:simple_native_logger/simple_native_logger_platform_interface.dart';
import 'package:simple_native_logger/simple_native_logger_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativeLoggerPlatform
    with MockPlatformInterfaceMixin
    implements NativeLoggerPlatform {

  int level = 0;
  String tag = "";
  String message = "";

  @override
  Future<void> log(int level, String tag, String message) async {  
    this.level = level;
    this.tag = tag;
    this.message = message;
  }

  void clear() {
    level = 0;
    tag = "";
    message = "";
  }
}

// utility fuction to log by each level
void testUtilLogByLevel(NativeLogger logger, LogLevel level, Object message, {StackTrace? stack}) {
  switch(level) {
  case LogLevel.verbose :
    logger.v(message, stack: stack);
    break;
  case LogLevel.debug :
    logger.d(message, stack: stack);
    break;
  case LogLevel.info :
    logger.i(message, stack: stack);
    break;
  case LogLevel.warning :
    logger.w(message, stack: stack);
    break;
  case LogLevel.error :
    logger.e(message, stack: stack);
    break;
  case LogLevel.fatal :
    logger.f(message, stack: stack);
    break;
  default :
    break;
  }
}

void main() {
  final NativeLoggerPlatform initialPlatform = NativeLoggerPlatform.instance;
  NativeLogger.init();

  test('MethodChannelNativeLogger is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNativeLogger>());
  });

  /*
  test('getPlatformVersion', () async {
    NativeLogger nativeLoggerPlugin = NativeLogger();
    MockNativeLoggerPlatform fakePlatform = MockNativeLoggerPlatform();
    NativeLoggerPlatform.instance = fakePlatform;

    expect(await nativeLoggerPlugin.getPlatformVersion(), '42');
  });
  */
  test('log basic test', () async {
    const tag = "TAG";
    const message = "LogMessage";

    NativeLogger nativeLoggerPlugin = NativeLogger(tag: tag, addLineNumber: false);
    MockNativeLoggerPlatform fakePlatform = MockNativeLoggerPlatform();
    NativeLoggerPlatform.instance = fakePlatform;

    for(final level in LogLevel.values) {
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
    }
  });

  test('suppress log by loglevel', () async {
    const tag = "TAG2";
    const message = "LogMessage";

    NativeLogger nativeLoggerPlugin = NativeLogger(
      tag: tag,
      logLevel: LogLevel.warning,
      addLineNumber: false
    );
    MockNativeLoggerPlatform fakePlatform = MockNativeLoggerPlatform();
    NativeLoggerPlatform.instance = fakePlatform;

    for(final level in [LogLevel.warning, LogLevel.error, LogLevel.fatal]) {
      debugPrint("testing for level: $level");
      fakePlatform.clear();
      testUtilLogByLevel(nativeLoggerPlugin, level, message);
      await Future.delayed(const Duration(seconds: 1));

      expect(fakePlatform.level, level.index);
      expect(fakePlatform.tag, tag);
      expect(fakePlatform.message, message);
    }

    for(final level in [LogLevel.verbose, LogLevel.debug, LogLevel.info]) {
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

    NativeLogger nativeLoggerPlugin = NativeLogger(tag: tag, addLineNumber: true);
    MockNativeLoggerPlatform fakePlatform = MockNativeLoggerPlatform();
    NativeLoggerPlatform.instance = fakePlatform;

    for(final level in LogLevel.values) {
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
      expect(fakePlatform.message, contains('native_logger_test')); // this filename
    }
  });

  test('log with full stack', () async {
    const tag = "TAG";
    final ex = Exception("log message");
    final message = ex.toString();

    NativeLogger nativeLoggerPlugin = NativeLogger(tag: tag, stackCount: -1);
    MockNativeLoggerPlatform fakePlatform = MockNativeLoggerPlatform();
    NativeLoggerPlatform.instance = fakePlatform;

    final stack = StackTrace.current;
    //debugPrint("stack: $stack");
    final actualStackCount = stack.toString().split("\n").length;

    for(final level in LogLevel.values) {
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

    NativeLogger nativeLoggerPlugin = NativeLogger(tag: tag, stackCount: stackCount);
    MockNativeLoggerPlatform fakePlatform = MockNativeLoggerPlatform();
    NativeLoggerPlatform.instance = fakePlatform;

    final stack = StackTrace.current;
    //debugPrint("stack: $stack");
    //final actualStackCount = stack.toString().split("\n").length;

    for(final level in LogLevel.values) {
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
}
