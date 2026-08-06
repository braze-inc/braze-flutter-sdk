package com.braze.brazeplugin

import android.app.Activity
import android.content.Context
import android.os.Looper
import androidx.test.core.app.ApplicationProvider
import com.braze.ui.banners.BannerDismissSnapshot
import com.braze.ui.banners.BannerView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.kotlin.mock
import org.mockito.kotlin.verify
import org.mockito.kotlin.verifyNoInteractions
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf

@RunWith(RobolectricTestRunner::class)
class BrazeBannerViewTest {
    private lateinit var activity: Activity
    private lateinit var context: Context
    private lateinit var mockEventSink: EventChannel.EventSink
    private lateinit var uiHandler: BrazeUIHandler

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        activity = Robolectric.buildActivity(TestActivityForJunitRunner::class.java).setup().get()
        mockEventSink = mock()
        uiHandler = BrazeUIHandler(mock<BinaryMessenger>())
        uiHandler.onListen(null, mockEventSink)
    }

    @Test
    fun whenCreated_withValidParams_setsPlacementIdOnBannerView() {
        val banner = BrazeBannerView(
            context,
            mapOf("placementId" to "home_banner", "containerId" to "container_1"),
            uiHandler,
            activity
        )

        val bannerView = banner.view as BannerView
        assertEquals("home_banner", bannerView.placementId)
        assertNotNull(bannerView.heightCallback)
        assertNotNull(bannerView.onDismissCallback)
    }

    @Test
    fun whenCreated_withMissingParams_doesNotCrash() {
        val banner = BrazeBannerView(context, emptyMap(), uiHandler, activity)

        assertNotNull(banner.view)
        val bannerView = banner.view as BannerView
        // Missing placement still wires callbacks so later events are safe
        assertNotNull(bannerView.heightCallback)
        assertNotNull(bannerView.onDismissCallback)
    }

    @Test
    fun whenHeightCallbackFires_sendsResizeEventWithContainerId() {
        val banner = BrazeBannerView(
            context,
            mapOf("placementId" to "home_banner", "containerId" to "container_1"),
            uiHandler,
            activity
        )
        val bannerView = banner.view as BannerView

        bannerView.heightCallback?.invoke(64.0)
        shadowOf(Looper.getMainLooper()).idle()

        verify(mockEventSink).success(
            mapOf(
                "height" to 64.0,
                "containerId" to "container_1"
            )
        )
    }

    @Test
    fun whenDismissCallbackFires_withCompleteSnapshot_sendsDismissEvent() {
        val banner = BrazeBannerView(
            context,
            mapOf("placementId" to "home_banner", "containerId" to "container_1"),
            uiHandler,
            activity
        )
        val bannerView = banner.view as BannerView

        bannerView.onDismissCallback?.invoke(
            BannerDismissSnapshot(
                placementId = "home_banner",
                stableKey = "stable_abc",
                trackingId = "track_xyz"
            )
        )
        shadowOf(Looper.getMainLooper()).idle()

        verify(mockEventSink).success(
            mapOf(
                "action" to "dismiss",
                "placementId" to "home_banner",
                "stableKey" to "stable_abc",
                "trackingId" to "track_xyz"
            )
        )
    }

    @Test
    fun whenDismissCallbackFires_withBlankPlacementId_doesNotSendEvent() {
        val banner = BrazeBannerView(
            context,
            mapOf("placementId" to "home_banner", "containerId" to "container_1"),
            uiHandler,
            activity
        )
        val bannerView = banner.view as BannerView

        bannerView.onDismissCallback?.invoke(
            BannerDismissSnapshot(
                placementId = "",
                stableKey = "stable_abc",
                trackingId = "track_xyz"
            )
        )
        shadowOf(Looper.getMainLooper()).idle()

        verifyNoInteractions(mockEventSink)
    }

    @Test
    fun whenDismissCallbackFires_withBlankStableKey_doesNotSendEvent() {
        val banner = BrazeBannerView(
            context,
            mapOf("placementId" to "home_banner", "containerId" to "container_1"),
            uiHandler,
            activity
        )
        val bannerView = banner.view as BannerView

        bannerView.onDismissCallback?.invoke(
            BannerDismissSnapshot(
                placementId = "home_banner",
                stableKey = " ",
                trackingId = "track_xyz"
            )
        )
        shadowOf(Looper.getMainLooper()).idle()

        verifyNoInteractions(mockEventSink)
    }

    @Test
    fun whenDismissCallbackFires_withBlankTrackingId_doesNotSendEvent() {
        val banner = BrazeBannerView(
            context,
            mapOf("placementId" to "home_banner", "containerId" to "container_1"),
            uiHandler,
            activity
        )
        val bannerView = banner.view as BannerView

        bannerView.onDismissCallback?.invoke(
            BannerDismissSnapshot(
                placementId = "home_banner",
                stableKey = "stable_abc",
                trackingId = ""
            )
        )
        shadowOf(Looper.getMainLooper()).idle()

        verifyNoInteractions(mockEventSink)
    }

    @Test
    fun whenDisposed_sendsZeroHeightResizeEvent() {
        val banner = BrazeBannerView(
            context,
            mapOf("placementId" to "home_banner", "containerId" to "container_1"),
            uiHandler,
            activity
        )

        banner.dispose()
        shadowOf(Looper.getMainLooper()).idle()

        verify(mockEventSink).success(
            mapOf(
                "height" to 0.0,
                "containerId" to "container_1"
            )
        )
    }
}
