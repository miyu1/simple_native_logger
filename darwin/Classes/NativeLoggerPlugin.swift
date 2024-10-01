#if os(macOS)
import FlutterMacOS
#else
import Flutter
#endif
//import UIKit
import os

public class NativeLoggerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
#if os(macOS)
    let channel = FlutterMethodChannel(name: "native_logger", binaryMessenger: registrar.messenger)
#else
    let channel = FlutterMethodChannel(name: "native_logger", binaryMessenger: registrar.messenger())
#endif    
    let instance = NativeLoggerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
#if os(macOS)
      let version = "macOS " + ProcessInfo.processInfo.operatingSystemVersionString
#else
      let version = "iOS " + UIDevice.current.systemVersion
#endif
      result(version)
    case "logTest":
      if let args = call.arguments as? Dictionary<String, Any> {
        if let message = args["message"] as? String {
          print("logTest2:", message)
          let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier!, category: "test1")
          logger.error("error! \(message, privacy: .public)")
        }
      }

      result(0)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
