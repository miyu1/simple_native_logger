import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'simple_native_logger_platform_interface.dart';

/// An implementation of [NativeLoggerPlatform] that uses method channels.
class MethodChannelNativeLogger extends NativeLoggerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('native_logger');

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
