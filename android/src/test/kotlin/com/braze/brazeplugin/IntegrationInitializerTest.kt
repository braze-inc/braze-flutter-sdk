package com.braze.brazeplugin

import android.app.Activity
import android.content.Context
import android.os.Looper
import androidx.test.core.app.ApplicationProvider
import com.braze.Braze
import com.braze.BrazeUser
import com.braze.events.SimpleValueCallback
import com.braze.models.inappmessage.IInAppMessage
import com.braze.ui.inappmessage.InAppMessageOperation
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.StandardMethodCodec
import io.flutter.plugin.platform.PlatformViewRegistry
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mockito.clearInvocations
import org.mockito.Mockito.verify
import org.mockito.Mockito.`when`
import org.mockito.kotlin.any
import org.mockito.kotlin.argumentCaptor
import org.mockito.kotlin.eq
import org.mockito.kotlin.isNull
import org.mockito.kotlin.mock
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf

@RunWith(RobolectricTestRunner::class)
class IntegrationInitializerTest {
    private var mockBinaryMessenger: BinaryMessenger = mock()
    private var mockFlutterPluginBinding: FlutterPlugin.FlutterPluginBinding = mock()
    private var mockActivityPluginBinding: ActivityPluginBinding = mock()
    private var mockBraze: Braze = mock()
    private var mockBrazeUser: BrazeUser = mock()
    private var mockPlatformViewRegistry: PlatformViewRegistry = mock {
        on { registerViewFactory(any(), any()) }.thenReturn(true)
    }

    private lateinit var brazePlugin: BrazePlugin

    private val activity: Activity
        get() = Robolectric.buildActivity(TestActivityForJunitRunner::class.java).get()

    private val context: Context
        get() = ApplicationProvider.getApplicationContext()

    @Before
    fun setUp() {
        `when`(mockFlutterPluginBinding.applicationContext).thenReturn(context)
        `when`(mockFlutterPluginBinding.binaryMessenger).thenReturn(mockBinaryMessenger)
        `when`(mockFlutterPluginBinding.platformViewRegistry).thenReturn(mockPlatformViewRegistry)
        `when`(mockActivityPluginBinding.activity).thenReturn(activity)

        BrazePlugin.setMockBrazeInstance(mockBraze)
        `when`(mockBraze.getCurrentUser(any())).thenAnswer { invocation ->
            val callback = invocation.getArgument<SimpleValueCallback<BrazeUser>>(0)
            callback.onSuccess(mockBrazeUser)
        }

        // processInAppMessage fans out to activePlugins; attach one so the bridge is observable
        brazePlugin = BrazePlugin()
        brazePlugin.onAttachedToEngine(mockFlutterPluginBinding)
        brazePlugin.onAttachedToActivity(mockActivityPluginBinding)
    }

    @After
    fun tearDown() {
        BrazePlugin.setMockBrazeInstance(null)
        BrazePlugin.activePlugins.clear()
        BrazePlugin.pendingPushEvents.clear()
    }

    @Test
    fun whenBeforeInAppMessageDisplayed_forwardsToProcessInAppMessageAndReturnsConfiguredOperation() {
        val listener = IntegrationInitializer.BrazeInAppMessageManagerListener(
            InAppMessageOperation.DISCARD
        )
        val mockInAppMessage: IInAppMessage = mock()
        val iamJson = JSONObject("""{"type":"modal","message":"hello"}""")
        `when`(mockInAppMessage.forJsonPut()).thenReturn(iamJson)
        clearInvocations(mockBinaryMessenger)

        val operation = listener.beforeInAppMessageDisplayed(mockInAppMessage)
        shadowOf(Looper.getMainLooper()).idle()

        assertEquals(InAppMessageOperation.DISCARD, operation)

        val bufferCaptor = argumentCaptor<java.nio.ByteBuffer>()
        verify(mockBinaryMessenger).send(eq("braze_plugin"), bufferCaptor.capture(), isNull())
        bufferCaptor.firstValue.rewind()
        val decoded: MethodCall =
            StandardMethodCodec.INSTANCE.decodeMethodCall(bufferCaptor.firstValue)
        assertEquals("handleBrazeInAppMessage", decoded.method)

        @Suppress("UNCHECKED_CAST")
        val args = decoded.arguments as Map<String, String>
        assertEquals(iamJson.toString(), args["inAppMessage"])
    }

    @Test
    fun whenBeforeInAppMessageDisplayed_withDisplayNow_returnsDisplayNow() {
        val listener = IntegrationInitializer.BrazeInAppMessageManagerListener(
            InAppMessageOperation.DISPLAY_NOW
        )
        val mockInAppMessage: IInAppMessage = mock()
        `when`(mockInAppMessage.forJsonPut()).thenReturn(JSONObject("""{"type":"slideup"}"""))

        val operation = listener.beforeInAppMessageDisplayed(mockInAppMessage)

        assertEquals(InAppMessageOperation.DISPLAY_NOW, operation)
    }
}
