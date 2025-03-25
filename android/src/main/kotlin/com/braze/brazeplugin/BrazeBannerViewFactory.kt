package com.braze.brazeplugin

import android.app.Activity
import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import BrazeUIHandler

class BrazeBannerViewFactory(
    val uiHandler: BrazeUIHandler,
    val activity: Activity
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, id: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<String, Any?>
        return BrazeBannerView(context, creationParams, uiHandler, activity)
    }
}
