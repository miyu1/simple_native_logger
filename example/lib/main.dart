import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:native_logger/native_logger.dart';

void main() {
  NativeLogger.init();

  final logger = NativeLogger(tag: "MainError");

  FlutterError.onError = (FlutterErrorDetails details) {
    logger.e(details.toStringShort(), stack: details.stack);
    //logger.e(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (error is PlatformException) {
      // error on method channel. cannot use native logger
      debugPrint("$error\n$stack");
    } else {
      logger.e(error, stack: stack);
    }
    return true;
  };

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _nativeLogger = NativeLogger(tag: "MyApp" );

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _nativeLogger.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [
              Text('Running on: $_platformVersion\n'),
              ElevatedButton(
                onPressed: () {
                  _nativeLogger.v("verbose log");
                },
                child: const Text('verbose log')
              ),
              ElevatedButton(
                onPressed: () {
                  _nativeLogger.d("debug log\n\tadditional line");
                },
                child: const Text('debug log')
              ),
              ElevatedButton(
                onPressed: () {
                  _nativeLogger.i("info log");
                },
                child: const Text('info log')
              ),
              ElevatedButton(
                onPressed: () {
                  _nativeLogger.w("warning log");
                },
                child: const Text('warning log')
              ),
              ElevatedButton(
                onPressed: () {
                  _nativeLogger.e("error log");
                },
                child: const Text('error log')
              ),
              ElevatedButton(
                onPressed: () {
                  _nativeLogger.f("fatal log");
                },
                child: const Text('fatal log')
              ),
              ElevatedButton(
                onPressed: () {
                  try {
                    const s = 'abc';
                    s.substring(-1);
                  } catch (ex, stack) {
                    _nativeLogger.e(ex, stack: stack);
                  }
                },
                child: const Text('catch exception')
              ),
              ElevatedButton(
                onPressed: () {
                  throw Exception('uncaught exception');
                  //_nativeLoggerPlugin.logTest2('logTest1');
                },
                child: const Text('uncaught exception')
              ),
              ElevatedButton(
                onPressed: () async {
                  throw Exception('uncaught exception (async)');
                  //_nativeLoggerPlugin.logTest2('logTest1');
                },
                child: const Text('uncaught exception (async)')
              ),
            ],
          ),
        ),
      ),
    );
  }
}
