package com.braze.brazeplugin

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.view.View
import com.braze.support.BrazeLogger.Priority.W
import com.braze.support.BrazeLogger.brazelog
import com.braze.ui.banners.BannerView
import io.flutter.plugin.platform.PlatformView

internal class BrazeBannerView(
    context: Context,
    creationParams: Map<String, Any?>?,
    uiHandler: BrazeUIHandler,
    val activity: Activity
) : PlatformView {
    // Communication of UI updates must run on main thread
    private val bannerUIHandler: BrazeUIHandler = uiHandler

    // The Braze banner view from the native Android SDK
    private val bannerView: BannerView = BannerView(context)

    // The identifier of the Dart container view around the banner
    private val containerId: String

    init {
        // For when there's no content displayed, e.g. Control banners
        bannerView.setBackgroundColor(Color.TRANSPARENT)

        val placementId = creationParams?.get("placementId") as? String
        val containerIdentifier = creationParams?.get("containerId") as? String
        if (placementId == null || containerIdentifier == null) {
            brazelog(W) {
                """
                Invalid empty parameter. Banner will not render properly:
                - Placement id: $placementId
                - Banner container id: $containerIdentifier
                """
            }
        }
        bannerView.placementId = placementId
        containerId = containerIdentifier.orEmpty()

        bannerView.heightCallback = { height: Double ->
            activity.runOnUiThread {
                bannerUIHandler.sendResizeEvent(height, containerId)
            }
        }
    }

    override fun getView(): View = bannerView

    override fun dispose() {
        activity.runOnUiThread {
            bannerUIHandler.sendResizeEvent(0.0, containerId)
            bannerView.destroy()
        }
    }
}
