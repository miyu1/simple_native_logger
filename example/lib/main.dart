import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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
  @override
  void initState() {
    super.initState();
    //initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeWidget(),
    );
  }
}

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  final _nativeLogger = SimpleNativeLogger(tag: "MyApp");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: TextButton(
              child: const Text(
                'View Logs',
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ViewLogsWidget()),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              //Text('Running on: $_platformVersion\n'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('use isLoggable'),
                  Checkbox(
                      value: _nativeLogger.useIsLoggable,
                      onChanged: (value) {
                        setState(
                          () {
                            _nativeLogger.useIsLoggable = value!;
                          },
                        );
                      })
                ],
              ),
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

class ViewLogsWidget extends StatefulWidget {
  const ViewLogsWidget({super.key});

  @override
  State<ViewLogsWidget> createState() => _ViewLogsWidgetState();
}

class _ViewLogsWidgetState extends State<ViewLogsWidget> {
  @override
  Widget build(BuildContext context) {
    Widget body = const Center(
      child: Text('No logs available.'),
    );
    if (SimpleNativeLogger.cachedLogList.isNotEmpty) {
      body = ListView.builder(
        itemCount: SimpleNativeLogger.cachedLogList.length,
        itemBuilder: (context, index) {
          final length = SimpleNativeLogger.cachedLogList.length;
          final item = SimpleNativeLogger.cachedLogList[length - index - 1];
          final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
          final timeStr = formatter.format(item.timestamp.toLocal());
          var type = '';
          switch (item.level) {
            case LogLevel.verbose:
              type = 'V';
              break;
            case LogLevel.debug:
              type = 'D';
              break;
            case LogLevel.info:
              type = 'I';
              break;
            case LogLevel.warning:
              type = 'W';
              break;
            case LogLevel.error:
              type = 'E';
              break;
            case LogLevel.fatal:
              type = 'F';
              break;
            case LogLevel.silent:
              type = 'S';
              break;
          }
          return ListTile(
            title: Text('$timeStr $type/${item.tag}'),
            subtitle: Text(item.message),
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cached Log List'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: TextButton(
              child: const Text(
                'Clear',
              ),
              onPressed: () {
                setState(() {
                  SimpleNativeLogger.cachedLogList.clear();
                });
              },
            ),
          ),
        ],
      ),
      body: body,
    );
  }
}
