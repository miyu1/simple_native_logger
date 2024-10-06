package io.github.miyu1.simple_native_logger

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.test.Test
import org.mockito.Mockito

/*
 * This demonstrates a simple unit test of the Kotlin portion of this plugin's implementation.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * you can run them directly from IDEs that support JUnit such as Android Studio.
 */

internal class SimpleNativeLoggerPluginTest {
  /*
  @Test
  fun onMethodCall_getPlatformVersion_returnsExpectedValue() {
    val plugin = SimpleNativeLoggerPlugin()

    val call = MethodCall("getPlatformVersion", null)
    val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
    plugin.onMethodCall(call, mockResult)

    Mockito.verify(mockResult).success("Android " + android.os.Build.VERSION.RELEASE)
  }
  */

  @Test
  fun onMethodCall_log() {
    println("onMethodCall_log start")

    val plugin = SimpleNativeLoggerPlugin()

    val args = mapOf(
      "level" to 3,
      "tag" to "tagA",
      "message" to "log message"
    )
    val call = MethodCall("getPlatformVersion", args)
    val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
    plugin.onMethodCall(call, mockResult)

    println("onMethodCall_log end")
    //Mockito.verify(mockResult).success("Android " + android.os.Build.VERSION.RELEASE)
  }
}
