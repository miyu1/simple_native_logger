import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_logger_platform_interface.dart';

/// An implementation of [NativeLoggerPlatform] that uses method channels.
class MethodChannelNativeLogger extends NativeLoggerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('native_logger');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  /*
  @override
  Future<void> logTest(String message) async {
    final arguments = {
      'message': message,
    };
    await methodChannel.invokeMethod('logTest', arguments);
  }
  */

  @override
  Future<void> log(int level, String tag, String message) async {
    final arguments = {
      'level' : level,
      'tag' : tag,
      'message': message,
    };
    await methodChannel.invokeMethod('log', arguments);
  }

}
