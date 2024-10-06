import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'simple_native_logger_method_channel.dart';

abstract class SimpleNativeLoggerPlatform extends PlatformInterface {
  /// Constructs a NativeLoggerPlatform.
  SimpleNativeLoggerPlatform() : super(token: _token);

  static final Object _token = Object();

  static SimpleNativeLoggerPlatform _instance = MethodChannelSimpleNativeLogger();

  /// The default instance of [NativeLoggerPlatform] to use.
  ///
  /// Defaults to [MethodChannelNativeLogger].
  static SimpleNativeLoggerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativeLoggerPlatform] when
  /// they register themselves.
  static set instance(SimpleNativeLoggerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> log(int level, String tag, String message) {
    throw UnimplementedError('log() has not been implemented.');
  }
}
