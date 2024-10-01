import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'native_logger_method_channel.dart';

abstract class NativeLoggerPlatform extends PlatformInterface {
  /// Constructs a NativeLoggerPlatform.
  NativeLoggerPlatform() : super(token: _token);

  static final Object _token = Object();

  static NativeLoggerPlatform _instance = MethodChannelNativeLogger();

  /// The default instance of [NativeLoggerPlatform] to use.
  ///
  /// Defaults to [MethodChannelNativeLogger].
  static NativeLoggerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativeLoggerPlatform] when
  /// they register themselves.
  static set instance(NativeLoggerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /*
  Future<void> logTest(String message) {
    throw UnimplementedError('logTest() has not been implemented.');
  }
  */

  Future<void> log(int level, String tag, String message) {
    throw UnimplementedError('log() has not been implemented.');
  }
}
