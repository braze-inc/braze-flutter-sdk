package braze.com.brazepluginexample

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.StrictMode
import android.os.StrictMode.ThreadPolicy
import android.util.Log
import com.braze.Braze
import com.braze.support.BrazeLogger
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.util.HashMap

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        Braze.getInstance(this).logCustomEvent("flutter_sample_opened")

        // - Flush Braze SDK logs to the Dart layer.
        // This is strictly for testing purposes to display logs in the sample app.
        BrazeLogger.logLevel = 4
        BrazeLogger.onLoggedCallback =
            fun(priority: BrazeLogger.Priority, message: String, throwable: Throwable?) {
                val logLevel = when (priority) {
                    BrazeLogger.Priority.V -> "verbose"
                    BrazeLogger.Priority.D -> "debug"
                    BrazeLogger.Priority.I -> "info"
                    BrazeLogger.Priority.W -> "warn"
                    BrazeLogger.Priority.E -> "error"
                }

                val arguments: HashMap<String, String> =
                    hashMapOf("logString" to message, "level" to logLevel)

                // MethodChannel calls must be invoked on the main thread since we
                // are inside a coroutine scope.
                Handler(Looper.getMainLooper()).post {
                    MethodChannel(
                        flutterEngine.dartExecutor.binaryMessenger,
                        "brazeLogChannel"
                    ).invokeMethod("printLog", arguments)
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        StrictMode.setThreadPolicy(
            ThreadPolicy.Builder()
                .detectDiskReads()
                .detectDiskWrites()
                .detectNetwork() // or .detectAll() for all detectable problems
                .penaltyLog()
                .build()
        )
        BrazeLogger.logLevel = Log.VERBOSE

        super.onCreate(savedInstanceState)
        handleDeepLink(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleDeepLink(intent)
    }

    private fun handleDeepLink(intent: Intent) {
        val binaryMessenger = flutterEngine?.dartExecutor?.binaryMessenger
        if (intent.action == Intent.ACTION_VIEW && binaryMessenger != null) {
            MethodChannel(binaryMessenger, "deepLinkChannel")
                .invokeMethod("receivedLink", intent.data.toString())
        }
    }
}
