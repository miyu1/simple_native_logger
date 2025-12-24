//import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:integration_test/integration_test.dart';

import 'package:simple_native_logger/simple_native_logger.dart';

// flutter run -t integration_test/test_stub.dart --dart-define=ARGS=<ip address>
void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  SimpleNativeLogger.init();

  const ipaddress = String.fromEnvironment("ARGS");
  //print("start ($ipaddress) ${DateTime.now()}");
  if (ipaddress.isEmpty) {
    debugPrint("ip address is empty");
    exit(1);
  }

  var socket = await WebSocket.connect("ws://$ipaddress:4040/ws");
  socket.add("ready");
  var timeoutSocket = socket.timeout(const Duration(seconds: 3));

  final nativeLogger = SimpleNativeLogger(tag: "Stub");

  await Future.delayed(const Duration(seconds: 1));
  debugPrint('stub process start listening');

  try {
    await for (final value in timeoutSocket) {
      debugPrint("command: $value");
      if (value == "exit") {
        break;
      }
      switch (value) {
        case "useIsLoggable":
          nativeLogger.useIsLoggable = true;
          socket.add(response());
          break;
        case "verbose":
          nativeLogger.v("verbose");
          await Future.delayed(const Duration(seconds: 1));
          socket.add(response());
          break;
        case "debug":
          nativeLogger.d("debug");
          await Future.delayed(const Duration(seconds: 1));
          socket.add(response());
          break;
        case "info":
          nativeLogger.i("info");
          await Future.delayed(const Duration(seconds: 1));
          socket.add(response());
          break;
        case "warning":
          nativeLogger.w("warning");
          await Future.delayed(const Duration(seconds: 1));
          socket.add(response());
          break;
        case "error":
          nativeLogger.e("error");
          await Future.delayed(const Duration(seconds: 1));
          socket.add(response());
          break;
        case "fatal":
          nativeLogger.f("fatal");
          await Future.delayed(const Duration(seconds: 1));
          socket.add(response());
          break;
        case "exception":
          try {
            throw Exception("some exception");
          } catch (ex, stack) {
            nativeLogger.e(ex, stack: stack);
          }
          await Future.delayed(const Duration(seconds: 1));
          socket.add(response());
          break;
        case 'clear':
          SimpleNativeLogger.cachedLogList.clear();
          socket.add(response());
          break;
      }
    }
  } on TimeoutException {
    debugPrint("timeout");
  }
  await socket.close();

  /*
  final cmdLine = stdin
    .timeout(const Duration(seconds: 5))
    .transform(const Utf8Decoder())
    .transform(const LineSplitter());
  
  try {
    await for(final value in cmdLine) {
     print("input $value");
    }
    //final value = stdin.readLineSync();
    //print("input: $value");
  } on TimeoutException {
    print("timeout ${DateTime.now()}");
  }
  */
  debugPrint("exit");
  exit(0);

  //test("this is stub", (){});
}

String response() {
  final buffer = StringBuffer();
  buffer.writeln('ok ${SimpleNativeLogger.cachedLogList.length}');
  if (SimpleNativeLogger.cachedLogList.isNotEmpty) {
    final lastLog = SimpleNativeLogger.cachedLogList.last;
    buffer.write('${lastLog.level}/${lastLog.tag} ${lastLog.message}');
  }
  final ret = buffer.toString();
  return ret;
}
