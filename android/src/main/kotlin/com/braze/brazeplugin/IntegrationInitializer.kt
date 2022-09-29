package com.braze.brazeplugin

import android.app.Application
import android.content.Context
import com.braze.Braze
import com.braze.BrazeActivityLifecycleCallbackListener
import com.braze.events.ContentCardsUpdatedEvent
import com.braze.events.IEventSubscriber
import com.braze.models.inappmessage.IInAppMessage
import com.braze.support.BrazeLogger.brazelog
import com.braze.ui.inappmessage.BrazeInAppMessageManager
import com.braze.ui.inappmessage.InAppMessageOperation
import com.braze.ui.inappmessage.listeners.DefaultInAppMessageManagerListener

object IntegrationInitializer {
    var isUninitialized = true
    private var contentCardsUpdatedSubscriber: IEventSubscriber<ContentCardsUpdatedEvent>? = null

    internal fun initializePlugin(application: Application, config: FlutterCachedConfiguration) {
        application.registerActivityLifecycleCallbacks(BrazeActivityLifecycleCallbackListener())
        val ctx = application.applicationContext
        subscribeToContentCardsUpdatedEvent(ctx)

        BrazeInAppMessageManager.getInstance().setCustomInAppMessageManagerListener(
            BrazeInAppMessageManagerListener(config.automaticIntegrationInAppMessageOperation())
        )
        isUninitialized = false
    }

    private fun subscribeToContentCardsUpdatedEvent(ctx: Context) {
        Braze.getInstance(ctx).removeSingleSubscription(contentCardsUpdatedSubscriber, ContentCardsUpdatedEvent::class.java)
        contentCardsUpdatedSubscriber = IEventSubscriber { BrazePlugin.processContentCards(it.allCards) }
        contentCardsUpdatedSubscriber?.let { Braze.getInstance(ctx).subscribeToContentCardsUpdates(it) }
        Braze.getInstance(ctx).requestContentCardsRefresh(true)
    }

    private class BrazeInAppMessageManagerListener(val defaultInAppMessageOperation: InAppMessageOperation) : DefaultInAppMessageManagerListener() {
        override fun beforeInAppMessageDisplayed(inAppMessage: IInAppMessage): InAppMessageOperation {
            super.beforeInAppMessageDisplayed(inAppMessage)
            BrazePlugin.processInAppMessage(inAppMessage)
            brazelog { "Returning $defaultInAppMessageOperation in Flutter automatic integration IInAppMessageManagerListener#beforeInAppMessageDisplayed()" }
            return defaultInAppMessageOperation
        }
    }
}
