package com.braze.brazeplugin

import android.app.Application
import android.content.Context
import com.appboy.events.IEventSubscriber
import com.braze.Braze
import com.braze.BrazeActivityLifecycleCallbackListener
import com.braze.events.ContentCardsUpdatedEvent
import com.braze.models.inappmessage.IInAppMessage
import com.braze.ui.inappmessage.BrazeInAppMessageManager
import com.braze.ui.inappmessage.InAppMessageOperation
import com.braze.ui.inappmessage.listeners.DefaultInAppMessageManagerListener

object IntegrationInitializer {
    var isUninitialized = true
    private var contentCardsUpdatedSubscriber: IEventSubscriber<ContentCardsUpdatedEvent>? = null

    internal fun initializePlugin(application: Application) {
        application.registerActivityLifecycleCallbacks(BrazeActivityLifecycleCallbackListener())
        val ctx = application.applicationContext
        subscribeToContentCardsUpdatedEvent(ctx)

        BrazeInAppMessageManager.getInstance().setCustomInAppMessageManagerListener(
            BrazeInAppMessageManagerListener()
        )
        isUninitialized = false
    }

    private fun subscribeToContentCardsUpdatedEvent(ctx: Context) {
        Braze.getInstance(ctx).removeSingleSubscription(contentCardsUpdatedSubscriber, ContentCardsUpdatedEvent::class.java)
        contentCardsUpdatedSubscriber = IEventSubscriber { BrazePlugin.processContentCards(it.allCards) }
        Braze.getInstance(ctx).subscribeToContentCardsUpdates(contentCardsUpdatedSubscriber)
        Braze.getInstance(ctx).requestContentCardsRefresh(true)
    }

    private class BrazeInAppMessageManagerListener : DefaultInAppMessageManagerListener() {
        override fun beforeInAppMessageDisplayed(inAppMessage: IInAppMessage): InAppMessageOperation {
            super.beforeInAppMessageDisplayed(inAppMessage)
            BrazePlugin.processInAppMessage(inAppMessage)
            return InAppMessageOperation.DISPLAY_NOW
        }
    }
}
