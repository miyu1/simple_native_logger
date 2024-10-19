import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:simple_native_logger/simple_native_logger.dart';

void main() {
  SimpleNativeLogger.init();

  final logger = SimpleNativeLogger(tag: "MainError");

  FlutterError.onError = (FlutterErrorDetails details) {
    logger.e(details.toStringShort(), stack: details.stack);
    //logger.e(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (error is PlatformException || error is MissingPluginException) {
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
  //String _platformVersion = 'Unknown';
  final _nativeLogger = SimpleNativeLogger(tag: "MyApp");

  @override
  void initState() {
    super.initState();
    //initPlatformState();
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              //Text('Running on: $_platformVersion\n'),
              ElevatedButton(
                  onPressed: () {
                    _nativeLogger.v("verbose log");
                  },
                  child: const Text('verbose log')),
              ElevatedButton(
                  onPressed: () {
                    _nativeLogger.d("debug log\n\tadditional line");
                  },
                  child: const Text('debug log')),
              ElevatedButton(
                  onPressed: () {
                    _nativeLogger.i("info log");
                  },
                  child: const Text('info log')),
              ElevatedButton(
                  onPressed: () {
                    _nativeLogger.w("warning log");
                  },
                  child: const Text('warning log')),
              ElevatedButton(
                  onPressed: () {
                    _nativeLogger.e("error log");
                  },
                  child: const Text('error log')),
              ElevatedButton(
                  onPressed: () {
                    _nativeLogger.f("fatal log");
                  },
                  child: const Text('fatal log')),
              /*
              ElevatedButton(
                onPressed: () {
                  _nativeLogger.log(LogLevel.silent, "silent log", null);
                },
                child: const Text('silent')
              ),
              */
              ElevatedButton(
                  onPressed: () {
                    try {
                      const s = 'abc';
                      s.substring(-1);
                    } catch (ex, stack) {
                      _nativeLogger.e(ex, stack: stack);
                    }
                  },
                  child: const Text('exception')),
              ElevatedButton(
                  onPressed: () {
                    throw Exception('uncaught exception');
                  },
                  child: const Text('uncaught exception')),
              ElevatedButton(
                  onPressed: () async {
                    throw Exception('uncaught exception (async)');
                  },
                  child: const Text('uncaught exception (async)')),
            ],
          ),
        ),
      ),
    );
  }
}
