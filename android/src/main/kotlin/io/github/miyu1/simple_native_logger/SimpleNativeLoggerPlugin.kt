package io.github.miyu1.simple_native_logger

import androidx.annotation.NonNull
import android.util.Log

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** SimpleNativeLoggerPlugin */
class SimpleNativeLoggerPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "simple_native_logger")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "log") {
      val level = call.argument<Int>("level")
      val tag = call.argument<String>("tag")
      val message = call.argument<String>("message")
      if (level != null && level >= 0 && level < 6 &&
          tag != null && message != null) {
        when(level) {
          1 -> {
            if (Log.isLoggable(tag, Log.DEBUG)) {
              Log.d(tag, message)
            }
          }
          2 -> {
            if (Log.isLoggable(tag, Log.INFO)) {
              Log.i(tag, message)
            }
          }
          3 -> {
            if (Log.isLoggable(tag, Log.WARN)) {
              Log.w(tag, message)
            }
          }
          4 -> {
            if (Log.isLoggable(tag, Log.ERROR)) {
              Log.e(tag, message)
            }
          }
          5 -> {
            if (Log.isLoggable(tag, Log.ASSERT)) {
              Log.wtf(tag, message)
            }
          }
          else -> {
            if (Log.isLoggable(tag, Log.VERBOSE)) {
              Log.v(tag, message)
            }
          }
        }
        result.success(0)
      } else {
        result.error(
          "PARAMETER",
          "parameter level:$level, tag:$tag, msg:$message",
          null)
      }
    } else if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
