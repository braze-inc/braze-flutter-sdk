package com.braze.brazeplugin

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.kotlin.mock
import org.mockito.kotlin.verify
import org.mockito.kotlin.verifyNoInteractions
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class BrazeUIHandlerTest {
    private lateinit var mockBinaryMessenger: BinaryMessenger
    private lateinit var mockEventSink: EventChannel.EventSink
    private lateinit var uiHandler: BrazeUIHandler

    @Before
    fun setUp() {
        mockBinaryMessenger = mock()
        mockEventSink = mock()
        uiHandler = BrazeUIHandler(mockBinaryMessenger)
        uiHandler.onListen(null, mockEventSink)
    }

    @Test
    fun whenSendResizeEvent_withActiveListener_sendsHeightAndContainerId() {
        uiHandler.sendResizeEvent(42.5, "container_1")

        verify(mockEventSink).success(
            mapOf(
                "height" to 42.5,
                "containerId" to "container_1"
            )
        )
    }

    @Test
    fun whenSendDismissEvent_withActiveListener_sendsDismissPayload() {
        uiHandler.sendDismissEvent(
            placementId = "placement_1",
            stableKey = "stable_1",
            trackingId = "track_1"
        )

        verify(mockEventSink).success(
            mapOf(
                "action" to "dismiss",
                "placementId" to "placement_1",
                "stableKey" to "stable_1",
                "trackingId" to "track_1"
            )
        )
    }

    @Test
    fun whenSendResizeEvent_afterCancel_doesNotSend() {
        uiHandler.onCancel(null)

        uiHandler.sendResizeEvent(10.0, "container_1")

        verifyNoInteractions(mockEventSink)
    }

    @Test
    fun whenSendDismissEvent_afterCancel_doesNotSend() {
        uiHandler.onCancel(null)

        uiHandler.sendDismissEvent("placement_1", "stable_1", "track_1")

        verifyNoInteractions(mockEventSink)
    }

    @Test
    fun whenSendResizeEvent_beforeListen_doesNotCrashOrSend() {
        val unusedSink: EventChannel.EventSink = mock()
        val handlerWithoutListen = BrazeUIHandler(mock())

        handlerWithoutListen.sendResizeEvent(1.0, "unused")

        verifyNoInteractions(unusedSink)
    }
}
