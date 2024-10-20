import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'simple_native_logger_platform_interface.dart';

/// An implementation of [SimpleNativeLoggerPlatform] that uses method channels.
class MethodChannelSimpleNativeLogger extends SimpleNativeLoggerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('simple_native_logger');

  @override
  Future<void> log(int level, String tag, String message, bool useIsLoggable) async {
    final arguments = {
      'level': level,
      'tag': tag,
      'message': message,
      'useIsLoggable': useIsLoggable 
    };
    await methodChannel.invokeMethod('log', arguments);
  }
}
