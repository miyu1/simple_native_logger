import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_native_logger/simple_native_logger_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelSimpleNativeLogger();
  const MethodChannel channel = MethodChannel('simple_native_logger');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  /*
  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
  */
  test('log', () async {
    try {
      // success if no error thrown
      await platform.log(1, "tagA", "message");
    } catch (ex) {
      fail(ex.toString());
    }
  });

}
