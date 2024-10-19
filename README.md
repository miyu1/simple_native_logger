# Native Logger

Android has logcat system for application logging,
and macOS/iOS also has similar logging system.

Native logger is flutter plugin to put logs to these platform native logging system.  
It also shows log to console. 

| |Android|macOS|iOS|
-|-|-|-
| Support |all| 11.0+ | 14.0+ |

On Android, you can see the logs using adb command.

```
$ adb shell 'logcat -v time --pid=$(pidof -s io.github.miyu1.simple_native_logger_example)'
10-07 17:41:51.515 V/MyApp   (27300): verbose log
10-07 17:41:53.623 D/MyApp   (27300): debug log
10-07 17:41:53.623 D/MyApp   (27300): 	additional line
10-07 17:42:07.351 I/MyApp   (27300): info log
10-07 17:42:09.065 W/MyApp   (27300): warning log
10-07 17:42:11.107 E/MyApp   (27300): error log
10-07 17:42:12.923 E/MyApp   (27300): fatal log
```

On macOS/iOS, you can see the logs using macOS Console app,
![Console App](https://github.com/miyu1/simple_native_logger/raw/main/doc/images/console_app.png "Console App")  

or by log command.
(For iOS simulator, run 'xcrun simctl spawn booted log' command with same parameter.)

```
$ log stream  --level debug --predicate 'subsystem = "io.github.miyu1.simpleNativeLoggerExample"'
Filtering the log data using "subsystem == "io.github.miyu1.simpleNativeLoggerExample""
Timestamp                       Thread     Type        Activity             PID    TTL  
2024-10-07 17:27:14.563742+0900 0x12365d   Debug       0x0                  47876  0    simple_native_logger_example: (simple_native_logger) [io.github.miyu1.simpleNativeLoggerExample:MyApp] verbose log
2024-10-07 17:27:19.193394+0900 0x12365d   Debug       0x0                  47876  0    simple_native_logger_example: (simple_native_logger) [io.github.miyu1.simpleNativeLoggerExample:MyApp] debug log
	additional line
2024-10-07 17:27:22.057604+0900 0x12365d   Info        0x0                  47876  0    simple_native_logger_example: (simple_native_logger) [io.github.miyu1.simpleNativeLoggerExample:MyApp] info log
2024-10-07 17:27:23.590778+0900 0x12365d   Default     0x0                  47876  0    simple_native_logger_example: (simple_native_logger) [io.github.miyu1.simpleNativeLoggerExample:MyApp] warning log 
2024-10-07 17:27:24.658391+0900 0x12365d   Error       0x0                  47876  0    simple_native_logger_example: (simple_native_logger) [io.github.miyu1.simpleNativeLoggerExample:MyApp] error log
2024-10-07 17:27:26.124623+0900 0x12365d   Fault       0x213311             47876  0    simple_native_logger_example: (simple_native_logger) [io.github.miyu1.simpleNativeLoggerExample:MyApp] fatal log 
```

## Usage

```dart
import 'package:simple_native_logger/simple_native_logger.dart';

void main() {
  SimpleNativeLogger.init();
  ...
}
  ...
  final _nativeLogger = SimpleNativeLogger(tag: "MyApp");
  _nativeLogger.w("<log message>");

  try {
    ... 
  } catch (ex, stack) {
    _nativeLogger.e(ex, stack: stack);
  }
```

To use simple_native_logger, you have to call
[SimpleNativeLogger](https://pub.dev/documentation/simple_native_logger/latest/simple_native_logger/SimpleNativeLogger-class.html).init() once,
may be in main.  
Then anywhere in code, you can use
[SimpleNativeLogger](https://pub.dev/documentation/simple_native_logger/latest/simple_native_logger/SimpleNativeLogger-class.html)
class for logging.  
You can also pass optional stack trace parameter.

Following table lists SimpleNativeLogger methods and corresponding method on each platform. 

| simple_native_logger | android | iOS/macos | 
-|-|-
| [SimpleNativeLogger.v](https://pub.dev/documentation/simple_native_logger/latest/simple_native_logger/SimpleNativeLogger/v.html) | Log.v | Logger.debug |
| [SimpleNativeLogger.d](https://pub.dev/documentation/simple_native_logger/latest/simple_native_logger/SimpleNativeLogger/d.html) | Log.d | Logger.debug |
| [SimpleNativeLogger.i](https://pub.dev/documentation/simple_native_logger/latest/simple_native_logger/SimpleNativeLogger/i.html) | Log.i | Logger.info |
| [SimpleNativeLogger.w](https://pub.dev/documentation/simple_native_logger/latest/simple_native_logger/SimpleNativeLogger/w.html) | Log.w | Logger.notice |
| [SimpleNativeLogger.e](https://pub.dev/documentation/simple_native_logger/latest/simple_native_logger/SimpleNativeLogger/e.html) | Log.e | Logger.error |
| [SimpleNativeLogger.f](https://pub.dev/documentation/simple_native_logger/latest/simple_native_logger/SimpleNativeLogger/f.html) | Log.wtf | Logger.fault |

On Android, android.util.Log class is used to implement.  
Tag property of SimpleNativeLogger is used as tag parameter of the Log class.  
Log.isLoggable is also called before log.

On macOS/iOS, os.Logger class is used to implement.  
Tag property of SimpleNativeLogger is used as
category parameter of the Logger class.  
Subsystem parameter of os.Logger is fixed to bundle ID.

## Notice for Android

By default, verbose and debug log is not logged.  
Use adb command to change behavior.  
Currently android log is also shown to flutter console,
and the adb settings also affects to it.

```
$ adb shell
emu64xa:/ $ setprop log.tag.MyApp V
emu64xa:/ $ exit
$ flutter run
...
V/MyApp   ( 4150): verbose log (package:simple_native_logger_example/main.dart:87:33)
D/MyApp   ( 4150): debug log
D/MyApp   ( 4150): 	additional line (package:simple_native_logger_example/main.dart:93:33)
I/MyApp   ( 4150): info log (package:simple_native_logger_example/main.dart:99:33)
W/MyApp   ( 4150): warning log (package:simple_native_logger_example/main.dart:105:33)
E/MyApp   ( 4150): error log (package:simple_native_logger_example/main.dart:111:33)
E/MyApp   ( 4150): fatal log (package:simple_native_logger_example/main.dart:117:33)
```

MyApp is a tag I used in exmaple app.
Change it to your own.  

To reset,
```
$ adb shell  
emu64xa:/ $ setprop log.tag.MyApp ""
emu64xa:/ $ exit
```

## Notice for macOS/iOS
By default, verbose, debug and info log is not shown by console app or log command.  
To change this behavior on console app, use Action menu of it.

![Console App Menu](https://github.com/miyu1/simple_native_logger/raw/main/doc/images/console_app_menu.png "Console App Menu") 

For log command, and '--level debug' option.

Currently, macOS/iOS logs are not shown in flutter console.  
So I added code to show logs to flutter console.
[isEchoNeeded](https://pub.dev/documentation/simple_native_logger/latest/simple_native_logger/SimpleNativeLogger/isEchoNeeded.html)
and
[echo](https://pub.dev/documentation/simple_native_logger/latest/simple_native_logger/SimpleNativeLogger/echo.html)
method of SimpleNativeLogger do the job. 

```
$ flutter run
flutter: [MyApp:V] verbose log (package:simple_native_logger_example/main.dart:87:33)
flutter: [MyApp:D] debug log
flutter: 	additional line (package:simple_native_logger_example/main.dart:93:33)
flutter: [MyApp:I] info log (package:simple_native_logger_example/main.dart:99:33)
flutter: [MyApp:W] warning log (package:simple_native_logger_example/main.dart:105:33)
flutter: [MyApp:E] error log (package:simple_native_logger_example/main.dart:111:33)
flutter: [MyApp:F] fatal log (package:simple_native_logger_example/main.dart:117:33)
```
