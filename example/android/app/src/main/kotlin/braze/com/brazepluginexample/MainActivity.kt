package braze.com.brazepluginexample

import android.content.Intent
import android.os.Bundle
import com.braze.Braze
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        Braze.getInstance(this).logCustomEvent("flutter_sample_opened")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
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
