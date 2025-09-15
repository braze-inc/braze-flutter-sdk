package com.braze.brazeplugin

import android.app.Activity
import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class BrazeBannerViewFactory(
    val uiHandler: BrazeUIHandler,
    val activity: Activity
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, id: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val creationParams = args as? Map<String, Any?>
        return BrazeBannerView(context, creationParams, uiHandler, activity)
    }
}
