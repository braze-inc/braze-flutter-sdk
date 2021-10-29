@file:Suppress("DEPRECATION")

package braze.com.brazepluginexample

import android.os.Bundle
import android.util.Log
import com.braze.Braze
import com.braze.brazeplugin.BrazePlugin
import dev.flutter.plugins.integration_test.IntegrationTestPlugin
import io.flutter.app.FlutterActivity
import io.flutter.view.FlutterMain

class EmbeddingV1Activity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        Log.d(null, "Initializing plugin with V1 Embedding.")
        FlutterMain.startInitialization(this)
        super.onCreate(savedInstanceState)
        BrazePlugin.registerWith(registrarFor("com.braze.brazeplugin.BrazePlugin"))
        IntegrationTestPlugin.registerWith(registrarFor("dev.flutter.plugins.integration_test.IntegrationTestPlugin"))

        Braze.getInstance(this).logCustomEvent("flutter_sample_opened_v1")
    }
}
