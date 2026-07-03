package app.kumaanime

import android.widget.Toast
import android.app.PictureInPictureParams
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.os.Looper
import android.os.Handler
import android.util.Rational
import androidx.annotation.NonNull
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity: FlutterActivity() {

    private lateinit var channel: MethodChannel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
    }

    override fun onPostResume() {
        super.onPostResume()
        enableEdgeToEdge()
    }

    private fun enableEdgeToEdge() {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isStatusBarContrastEnforced = false
            window.isNavigationBarContrastEnforced = false
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kumaanime.app/utils")
        channel.setMethodCallHandler {
                call, result ->
            when (call.method) {
                "showToast" -> {
                val message = call.argument<String>("message")
                if(message == null || message.length == 0) {
                    result.error("MESSAGE_NOT_PROVIDED", "MESSAGE IS NULL OR EMPTY", null)
                }
                showToast(message ?: "")
                }
                "showSystemBars" -> {
                    runOnUiThread {
                        enableEdgeToEdge()
                        val controller = WindowInsetsControllerCompat(window, window.decorView)
                        controller.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_DEFAULT
                        controller.show(WindowInsetsCompat.Type.systemBars())
                    }
                    result.success(null)
                }
                "hideSystemBars" -> {
                    runOnUiThread {
                        val controller = WindowInsetsControllerCompat(window, window.decorView)
                        controller.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                        controller.hide(WindowInsetsCompat.Type.systemBars())
                    }
                    result.success(null)
                }
                "enterPip" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        try {
                            val params = PictureInPictureParams.Builder()
                                .setAspectRatio(Rational(16, 9))
                                .build()
                            enterPictureInPictureMode(params)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onUserLeaveHint() {
         super.onUserLeaveHint()
         channel.invokeMethod("onUserLeaveHint", null);
    }

    fun showToast(message: String) {
        Handler(Looper.getMainLooper()).post {
            Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
        }
    }
}
