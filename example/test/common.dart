import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

Future<WebSocket> connect(String url) async {
  SocketException? socketEx; 

  for(var retry = 0; retry < 5; retry ++) {
    try {
      final socket = await WebSocket.connect(url);
      return socket;
    } catch (ex) {
      if (ex is SocketException) {
        socketEx = ex;
        debugPrint("wait and retry connect $retry");
        await Future.delayed(const Duration(seconds: 3));
      } else {
        rethrow;
      }
    }
  }
  socketEx ??= const SocketException("some error code?");
  throw socketEx;
}

class ProcessRunner {
  final String executable;
  final List<String> arguments;
  Process process;
  List<String> stdout = [];

  // do not use
  ProcessRunner(this.executable, this.arguments, this.process){
    final stdoutStream = process.stdout
      //.timeout(const Duration(seconds: 10))
      .transform(systemEncoding.decoder)
      .transform(const LineSplitter());
    stdoutStream.listen((value){
      stdout.add(value);
    });
  }

  static Future<ProcessRunner> start(String executable, List<String> arguments) async {
    final process = await Process.start(executable, arguments);
    final ret = ProcessRunner(executable, arguments, process);
    return ret;
  }

  void clearStdout() {
    stdout = [];
  }
}