package braze.com.brazepluginexample

import android.content.Intent
import android.os.Bundle
import android.os.StrictMode
import android.os.StrictMode.ThreadPolicy
import com.braze.Braze
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant


class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        Braze.getInstance(this).logCustomEvent("flutter_sample_opened")
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

        super.onCreate(savedInstanceState)
        handleDeepLink(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleDeepLink(intent)
    }

    private fun handleDeepLink(intent: Intent) {
        val binaryMessenger = flutterEngine?.dartExecutor?.binaryMessenger
        if (intent?.action == Intent.ACTION_VIEW && binaryMessenger != null) {
            MethodChannel(binaryMessenger, "deepLinkChannel")
                .invokeMethod("receivedLink", intent?.data.toString())
        }
    }
}
