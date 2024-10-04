import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:flutter_test/flutter_test.dart';

import 'common.dart';

// This test code works by flutter test command,
// but not with flutter run command or vscode ,
// because they try to run this code in target OS.
//
// I have to test what is outputted to stdout, so this test is complicated. 
//
// Proccesses needed for this test is,
// - target OS
//   - flutter run integration_test/test_stub.dart
// - host OS
//   - this test code.
//   - websocket server for communicate with test stub
//     (test/websocket_server.dart) 
//   - log command for macOS
//
void main() {
  test("macos integration test", () async {
    const tag = "Stub";

    final networks = await NetworkInterface.list();
    expect(networks, isNotEmpty, reason: "need network address of this host");
    final ipaddresses = networks.first.addresses;
    expect(ipaddresses, isNotEmpty);
    final ipaddress = ipaddresses.first.address;
    expect(ipaddress, isNotEmpty);
    debugPrint("ipaddress: $ipaddress");

    final deviceName = await findMacDevice();
    debugPrint("macos device: $deviceName");
    expect(deviceName, isNotEmpty, reason: "run in macos.");

    debugPrint("start log process");
    final logc = await ProcessRunner.start(
      "log",
      ["stream", "--level", "debug",
       "--predicate", "subsystem = \"io.github.miyu1.nativeLoggerExample\"" ]
    );
    /*
    await Future.delayed(const Duration(seconds: 3));
    for (final line in logc.stdout) {
      print("log: $line");
    }
    */

    debugPrint("start server process");
    final server = await ProcessRunner.start(
      "dart",
      ["run", "test/websocket_server.dart", ipaddress]
    );
    await Future.delayed(const Duration(seconds: 1));

    debugPrint("start stub process");
    final stub = await ProcessRunner.start(
      "flutter",
      ["-d", deviceName, "run", "-t", "integration_test/test_stub.dart",
       "--dart-define=ARGS=$ipaddress"
       ],
      //["-d", "macos", "run", "-t", "integration_test/test_stub.dart"],
    );

    var socket = await connect("ws://$ipaddress:4040/ws"); // WebSocket.connect("ws://$ipaddress:4040/ws");

    // have to wait flutter to build and run test_stub
    var timeoutSocket = socket.timeout(const Duration(seconds: 60));
    
    // handshake
    socket.add("waiting");
    try {
      var command = "";
      var state = 0;
      await for(final response in timeoutSocket) {
        // now got response from stub

        //print("response: $response");
        expect(response, "ok");

        // print("state: $state");
        Iterable<String> stublogs = [];
        Iterable<String> logclogs = [];

        // check result
        switch(state) {
        case 1: // verbose
          stublogs = stub.stdout.where((line) => 
            line.contains("[$tag:V]") && line.contains(command));
          logclogs  =  logc.stdout.where((line) => 
            line.contains(tag) && line.contains("Debug") && line.contains(command));
          break;
        case 2: // debug
          stublogs = stub.stdout.where((line) => 
            line.contains("[$tag:D]") && line.contains(command));
          logclogs  =  logc.stdout.where((line) => 
            line.contains(tag) && line.contains("Debug") && line.contains(command));
          break;
        case 3: // info
          stublogs = stub.stdout.where((line) => 
            line.contains("[$tag:I]") && line.contains(command));
          logclogs  =  logc.stdout.where((line) => 
            line.contains(tag) && line.contains("Info") && line.contains(command));
          break;
        case 4: // warning
          stublogs = stub.stdout.where((line) => 
            line.contains("[$tag:W]") && line.contains(command));
          logclogs  =  logc.stdout.where((line) => 
            line.contains(tag) && line.contains("Default") && line.contains(command));
          break;
        case 5: // error
          stublogs = stub.stdout.where((line) => 
            line.contains("[$tag:E]") && line.contains(command));
          logclogs  =  logc.stdout.where((line) => 
            line.contains(tag) && line.contains("Error") && line.contains(command));
          break;
        case 6: // fatal
          stublogs = stub.stdout.where((line) => 
            line.contains("[$tag:F]") && line.contains(command));
          logclogs  =  logc.stdout.where((line) => 
            line.contains(tag) && line.contains("Fault") && line.contains(command));
          break;
        case 7: // exception
          stublogs = stub.stdout.where((line) => 
            line.contains("[$tag:E]") && line.contains(command));
          logclogs  =  logc.stdout.where((line) => 
            line.contains(tag) && line.contains("Error") && line.contains(command));
          break;
        }
        if (state >= 1) {
          //print("stublogs: $stublogs");
          /*
          for(final line in stub.stdout) {
            print("stub: $line");
          }
          */
          expect(stublogs, isNotEmpty);

          //print("logclogs: $logclogs");
          expect(logclogs, isNotEmpty);
        }
        if (state == 7) {
          stublogs = stub.stdout.where((line) => line.contains("stack trace"));
          //print("stublogs: $stublogs");

          logclogs  = logc.stdout.where((line) => line.contains("stack trace"));
          //print("logclogs: $logclogs");

          expect(stublogs, isNotEmpty);
          expect(logclogs, isNotEmpty);
        }

        state += 1;
        if (state == 8) {
          break;
        }
        stub.clearStdout();
        logc.clearStdout();
        // send command to stub
        switch(state) {
        case 1:
          command = "verbose";
          socket.add(command);
          break;
        case 2:
          command = "debug";
          socket.add(command);
          break;
        case 3:
          command = "info";
          socket.add(command);
          break;
        case 4:
          command = "warning";
          socket.add(command);
          break;
        case 5:
          command = "error";
          socket.add(command);
          break;
        case 6:
          command = "fatal";
          socket.add(command);
          break;
        case 7:
          command = "exception";
          socket.add(command);
          break;
        }
        debugPrint("$command test");        
      }
    } catch (ex) {
      // timeout?
      debugPrint("no response: $ex");
      for(final line in stub.stdout) {
        debugPrint("stub: $line");
      }
      fail("no response from stub");
    }

    socket.add("exit");
    await socket.close();

    debugPrint("waiting for stub close");
    await stub.process.exitCode;

    debugPrint("waiting for server to close");
    await server.process.exitCode;    
    
    debugPrint("waiting for log close");
    logc.process.kill();
    await logc.process.exitCode;
    
  },
  // need retry because in some cases stub fails to start
  // when it takes long time to build and start stub and timeout exception occurs
  testOn: "mac-os", timeout: const Timeout.factor(3), retry: 3);  

  test("macos release build (no stdout echo)", () async {
    const tag = "Stub";

    final networks = await NetworkInterface.list();
    expect(networks, isNotEmpty, reason: "need network address of this host");
    final ipaddresses = networks.first.addresses;
    expect(ipaddresses, isNotEmpty);
    final ipaddress = ipaddresses.first.address;
    expect(ipaddress, isNotEmpty);
    debugPrint("ipaddress: $ipaddress");

    final deviceName = await findMacDevice();
    debugPrint("macos device: $deviceName");
    expect(deviceName, isNotEmpty, reason: "run on mac.");

    debugPrint("start log process");
    final logc = await ProcessRunner.start(
      "log",
      ["stream", "--level", "debug",
       "--predicate", "subsystem = \"io.github.miyu1.nativeLoggerExample\"" ]
    );
    /*
    await Future.delayed(const Duration(seconds: 3));
    for (final line in logc.stdout) {
      print("log: $line");
    }
    */

    debugPrint("start server process");
    final server = await ProcessRunner.start(
      "dart",
      ["run", "test/websocket_server.dart", ipaddress]
    );
    await Future.delayed(const Duration(seconds: 1));

    debugPrint("start stub process");
    final stub = await ProcessRunner.start(
      "flutter",
      ["-d", deviceName, "run", "--release", "-t", "integration_test/test_stub.dart",
       "--dart-define=ARGS=$ipaddress"
       ],
      //["-d", "macos", "run", "-t", "integration_test/test_stub.dart"],
    );

    var socket = await connect("ws://$ipaddress:4040/ws"); // WebSocket.connect("ws://$ipaddress:4040/ws");

    // have to wait flutter to build and run test_stub
    var timeoutSocket = socket.timeout(const Duration(seconds: 60));
    
    // handshake
    socket.add("waiting");
    try {
      var command = "";
      var state = 0;
      await for(final response in timeoutSocket) {
        // now got response from stub

        //print("response: $response");
        expect(response, "ok");

        // print("state: $state");
        Iterable<String> stublogs = [];
        Iterable<String> logclogs = [];

        // check result
        switch(state) {
        case 1: // verbose
          stublogs = stub.stdout.where((line) => 
            line.contains("[$tag:V]") && line.contains(command));
          logclogs  =  logc.stdout.where((line) => 
            line.contains(tag) && line.contains("Debug") && line.contains(command));
          break;
        case 2: // debug
          stublogs = stub.stdout.where((line) => 
            line.contains("[$tag:D]") && line.contains(command));
          logclogs  =  logc.stdout.where((line) => 
            line.contains(tag) && line.contains("Debug") && line.contains(command));
          break;
        case 3: // info
          stublogs = stub.stdout.where((line) => 
            line.contains("[$tag:I]") && line.contains(command));
          logclogs  =  logc.stdout.where((line) => 
            line.contains(tag) && line.contains("Info") && line.contains(command));
          break;
        case 4: // warning
          stublogs = stub.stdout.where((line) => 
            line.contains("[$tag:W]") && line.contains(command));
          logclogs  =  logc.stdout.where((line) => 
            line.contains(tag) && line.contains("Default") && line.contains(command));
          break;
        case 5: // error
          stublogs = stub.stdout.where((line) => 
            line.contains("[$tag:E]") && line.contains(command));
          logclogs  =  logc.stdout.where((line) => 
            line.contains(tag) && line.contains("Error") && line.contains(command));
          break;
        case 6: // fatal
          stublogs = stub.stdout.where((line) => 
            line.contains("[$tag:F]") && line.contains(command));
          logclogs  =  logc.stdout.where((line) => 
            line.contains(tag) && line.contains("Fault") && line.contains(command));
          break;
        case 7: // exception
          stublogs = stub.stdout.where((line) => 
            line.contains("[$tag:E]") && line.contains(command));
          logclogs  =  logc.stdout.where((line) => 
            line.contains(tag) && line.contains("Error") && line.contains(command));
          break;
        }
        if (state >= 1) {
          //print("stublogs: $stublogs");
          /*
          for(final line in stub.stdout) {
            print("stub: $line");
          }
          */
          expect(stublogs, isEmpty);

          //print("logclogs: $logclogs");
          expect(logclogs, isNotEmpty);
        }
        if (state == 7) {
          stublogs = stub.stdout.where((line) => line.contains("stack trace"));
          //print("stublogs: $stublogs");

          logclogs  = logc.stdout.where((line) => line.contains("stack trace"));
          //print("logclogs: $logclogs");

          expect(stublogs, isEmpty);
          expect(logclogs, isNotEmpty);
        }

        state += 1;
        if (state == 8) {
          break;
        }
        stub.clearStdout();
        logc.clearStdout();
        // send command to stub
        switch(state) {
        case 1:
          command = "verbose";
          socket.add(command);
          break;
        case 2:
          command = "debug";
          socket.add(command);
          break;
        case 3:
          command = "info";
          socket.add(command);
          break;
        case 4:
          command = "warning";
          socket.add(command);
          break;
        case 5:
          command = "error";
          socket.add(command);
          break;
        case 6:
          command = "fatal";
          socket.add(command);
          break;
        case 7:
          command = "exception";
          socket.add(command);
          break;
        }
        debugPrint("$command test");        
      }
    } catch (ex) {
      // timeout?
      debugPrint("no response: $ex");
      for(final line in stub.stdout) {
        debugPrint("stub: $line");
      }
      fail("no response from stub");
    }

    socket.add("exit");
    await socket.close();

    debugPrint("waiting for stub close");
    stub.process.kill();
    await stub.process.exitCode;

    debugPrint("waiting for server to close");
    await server.process.exitCode;    
    
    debugPrint("waiting for log close");
    logc.process.kill();
    await logc.process.exitCode;
  },
  // need retry because in some cases stub fails to start
  // when it takes long time to build and start stub and timeout exception occurs
  testOn: "mac-os", timeout: const Timeout.factor(3), retry: 3);
}

Future<String> findMacDevice() async {
    final runner = await ProcessRunner.start(
      "flutter", ["devices"],
    );
    await runner.process.exitCode;

    final devices = runner.stdout.where(
      (line) => line.contains(" • ") && line.contains("macos"));
    if (devices.isEmpty) {
      return "";
    }
    final device = devices.first;
    final elems = device.split(" • ");
    //print("elements: $elems");
    return elems[1].trim();
}

