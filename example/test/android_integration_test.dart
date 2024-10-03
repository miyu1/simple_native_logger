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
//   - adb command for Android
//
void main() {
  test("android integration test", () async {
    const tag = "Stub";

    //final networks = await NetworkInterface.list(type: InternetAddressType.IPv4);
    final networks = await NetworkInterface.list();
    expect(networks, isNotEmpty, reason: "need network address of this host");
    final ipaddresses = networks.first.addresses;
    expect(ipaddresses, isNotEmpty);
    final ipaddress = ipaddresses.first.address;
    expect(ipaddress, isNotEmpty);
    debugPrint("ipaddress: $ipaddress");

    //Process.start("dart", ["run", "test/test/websocket_server.dart"],);
    final deviceName = await findAndroidDevice();
    debugPrint("android device: $deviceName");
    expect(deviceName, isNotEmpty, reason: "connect any android device.");
    
    debugPrint("start adb process");
    final adbc = await ProcessRunner.start(
      "adb",
      ["-s", deviceName, "shell" ]
    );
    adbc.process.stdin.writeln("setprop log.tag.$tag V");
    const s = "logcat -v brief $tag:V flutter:V *:S";
    //print("adb command: $s");
    adbc.process.stdin.writeln(s);
    /*
    await Future.delayed(const Duration(seconds: 3));
    print("adb len: ${adb.stdout.length}");
    for (final line in adb.stdout) {
      print("adb: $line");
    }
    */

    debugPrint("start server process");
    final server = await ProcessRunner.start(
      "dart",
      ["run", "test/websocket_server.dart", ipaddress]
    );
    await Future.delayed(const Duration(seconds: 1));
    /*
    for(final line in server.stdout) {
      print("server: $line");
    }
    */

    debugPrint("start stub process");
    final stub = await ProcessRunner.start(
      "flutter",
      ["-d", deviceName, "run", "-t", "integration_test/test_stub.dart",
       "--dart-define=ARGS=$ipaddress"
       ],
      //["-d", "macos", "run", "-t", "integration_test/test_stub.dart"],
    );

    var socket = await connect("ws://$ipaddress:4040/ws");

    // have to wait flutter to build and run test_stub
    var timeoutSocket = socket.timeout(const Duration(seconds: 60));
    
    // handshake
    socket.add("waiting");
    try {
      var command = "";
      var state = 0;
      await for(final response in timeoutSocket) {
        //print("response: $response");
        expect(response, "ok");

        // print("state: $state");
        Iterable<String> stublogs = [];
        Iterable<String> adblogs = [];

        // check result
        switch(state) {
        case 1:
          stublogs = stub.stdout.where((line) => line.contains("V/$tag") && line.contains(command));
          adblogs  = adbc.stdout.where((line) => line.contains("V/$tag") && line.contains(command));
          break;
        case 2:
          stublogs = stub.stdout.where((line) => line.contains("D/$tag") && line.contains(command));
          adblogs  = adbc.stdout.where((line) => line.contains("D/$tag") && line.contains(command));
          break;
        case 3:
          stublogs = stub.stdout.where((line) => line.contains("I/$tag") && line.contains(command));
          adblogs  = adbc.stdout.where((line) => line.contains("I/$tag") && line.contains(command));
          break;
        case 4:
          stublogs = stub.stdout.where((line) => line.contains("W/$tag") && line.contains(command));
          adblogs  = adbc.stdout.where((line) => line.contains("W/$tag") && line.contains(command));
          break;
        case 5:
          stublogs = stub.stdout.where((line) => line.contains("E/$tag") && line.contains(command));
          adblogs  = adbc.stdout.where((line) => line.contains("E/$tag") && line.contains(command));
          break;
        case 6:
          stublogs = stub.stdout.where((line) => line.contains("E/$tag") && line.contains(command));
          adblogs  = adbc.stdout.where((line) => line.contains("E/$tag") && line.contains(command));
          break;
        case 7:
          stublogs = stub.stdout.where((line) => line.contains("E/$tag") && line.contains(command));
          adblogs  = adbc.stdout.where((line) => line.contains("E/$tag") && line.contains(command));
          break;
        }

        if (state >= 1) {
          // print("stublogs: $stublogs");
          expect(stublogs, isNotEmpty);
          /*
          for(final line in stub.stdout) {
            print("stub: $line");
          }
          */

          // print("adblogs: $adblogs");
          expect(adblogs, isNotEmpty);
          /*
          for (final line in adb.stdout) {
            print("adb: $line");
          }
          */
        }
        if (state == 7) {
          stublogs = stub.stdout.where((line) => line.contains("E/$tag") && line.contains("stack trace"));
          adblogs  = adbc.stdout.where((line) => line.contains("E/$tag") && line.contains("stack trace"));
          expect(stublogs, isNotEmpty);
          expect(adblogs, isNotEmpty);
        }

        state += 1;
        if (state == 8) {
          break;
        }

        stub.clearStdout();
        adbc.clearStdout();
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

    debugPrint("waiting for server close");
    await server.process.exitCode;

    debugPrint("waiting for adb close");
    adbc.process.kill();
    await adbc.process.exitCode;

    final adb2 = await ProcessRunner.start(
      "adb",
      ["-s", deviceName, "shell" ]
    );
    adb2.process.stdin.writeln("setprop log.tag.$tag \"\"");
    adb2.process.stdin.writeln("exit");
    await adb2.process.exitCode;

    /*
    print("stub output3");
    stub.stdout.forEach((value) => print("stub: $value"));
    for (final line in adb2.stdout) {
      print("adb2: $line");
    }
    */
  }, timeout: const Timeout.factor(3));
}

Future<String> findAndroidDevice() async {
    final runner = await ProcessRunner.start(
      "flutter", ["devices"],
    );
    await runner.process.exitCode;

    final devices = runner.stdout.where(
      (line) => line.contains(" • ") && line.contains("android"));
    if (devices.isEmpty) {
      return "";
    }
    final device = devices.first;
    final elems = device.split(" • ");
    //print("elements: $elems");
    return elems[1].trim();
}
