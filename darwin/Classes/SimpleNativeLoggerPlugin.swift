#if os(macOS)
import FlutterMacOS
#else
import Flutter
#endif
//import UIKit
import os

public class SimpleNativeLoggerPlugin: NSObject, FlutterPlugin {
  var tag = "flutter"
  var logger = os.Logger(subsystem: Bundle.main.bundleIdentifier!, category: "flutter")
  
  public static func register(with registrar: FlutterPluginRegistrar) {
#if os(macOS)
    let channel = FlutterMethodChannel(name: "simple_native_logger", binaryMessenger: registrar.messenger)
#else
    let channel = FlutterMethodChannel(name: "simple_native_logger", binaryMessenger: registrar.messenger())
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
    case "log" :
      if let args = call.arguments as? Dictionary<String, Any> {
        if let level = args["level"] as? Int,
          let tag = args["tag"] as? String,
          let message = args["message"] as? String
        {
          if (tag != self.tag) {
            logger = os.Logger(subsystem: Bundle.main.bundleIdentifier!, category: tag)
            self.tag = tag
          }
          switch(level) {
          case 0:
            logger.debug("\(message, privacy: .public)")
            result(0)
          case 1:
            logger.debug("\(message, privacy: .public)")
            result(0)
          case 2:
            logger.info("\(message, privacy: .public)")
            result(0)
          case 3:
            logger.notice("\(message, privacy: .public)")
            result(0)
          case 4:
            logger.error("\(message, privacy: .public)")
            result(0)
          case 5:
            logger.fault("\(message, privacy: .public)")
            result(0)
          default:
            result(
              FlutterError(
                code: "PARAMETER",
                message:"parameter level:\(level), tag:\(tag), msg:\(message)",
                details: nil
              )
            )
          } // end switch
        }
      }
    /*
    case "logTest":
      if let args = call.arguments as? Dictionary<String, Any> {
        if let message = args["message"] as? String {
          print("logTest2:", message)
          let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier!, category: "test1")
          logger.error("error! \(message, privacy: .public)")
        }
      }

      result(0)
    */
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
