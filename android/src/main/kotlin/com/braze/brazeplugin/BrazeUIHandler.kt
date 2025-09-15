package com.braze.brazeplugin

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

/**
 * Handles UI events for native Android views.
 */
class BrazeUIHandler(binaryMessenger: BinaryMessenger) : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null

    init {
        EventChannel(binaryMessenger, "braze_banner_view_channel").setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun sendResizeEvent(height: Double, identifier: String) {
        val resizeData = mapOf("height" to height, "containerId" to identifier)
        eventSink?.success(resizeData)
    }
}
