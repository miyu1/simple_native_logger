# native_logger

A new Flutter plugin project.

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/to/develop-plugins),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

| native_logger | android | iOS/macos | 
-|-|-
| NativeLogger.v | Log.v | Logger.debug |
| NativeLogger.d | Log.d | Logger.debug |
| NativeLogger.i | Log.i | Logger.info |
| NativeLogger.w | Log.w | Logger.notice |
| NativeLogger.e | Log.e | Logger.error |
| NativeLogger.f | Log.wtf | Logger.fault |

iOS 14.0+ macOS 11.0+
 Debug (trace)
 Info
 Notice(default)
 Error (warning)
 Fault (critical)

 android
 Log.v verbose
 Log.d debug
 Log.i info
 Log.w warning
 Log.e error
 Log.wtf

  ./adb -s 'HA1QR3B0' shell 'logcat -v time --pid=$(pidof -s io.github.miyu1.native_logger_example)'
   ./adb -s 'HA1QR3B0' shell 'setprop log.tag.MyApp V' 
  log stream  --level debug --predicate 'subsystem = "io.github.miyu1.nativeLoggerExample"'
  xcrun simctl spawn 450F57A5-5BC3-460F-90F7-D7E9057FB829 log stream --level debug --predicate 'subsystem = "io.github.miyu1.nativeLoggerExample"'