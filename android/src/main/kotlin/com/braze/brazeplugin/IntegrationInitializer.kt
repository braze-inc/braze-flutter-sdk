package com.braze.brazeplugin

import android.app.Application
import android.content.Context
import com.braze.Braze
import com.braze.BrazeActivityLifecycleCallbackListener
import com.braze.events.BrazePushEvent
import com.braze.events.ContentCardsUpdatedEvent
import com.braze.events.FeatureFlagsUpdatedEvent
import com.braze.events.IEventSubscriber
import com.braze.models.inappmessage.IInAppMessage
import com.braze.support.BrazeLogger.brazelog
import com.braze.ui.inappmessage.BrazeInAppMessageManager
import com.braze.ui.inappmessage.InAppMessageOperation
import com.braze.ui.inappmessage.listeners.DefaultInAppMessageManagerListener

object IntegrationInitializer {
    var isUninitialized = true
    private var contentCardsUpdatedSubscriber: IEventSubscriber<ContentCardsUpdatedEvent>? = null
    private var featureFlagsUpdatedSubscriber: IEventSubscriber<FeatureFlagsUpdatedEvent>? = null
    private var pushNotificationsUpdatedSubscriber: IEventSubscriber<BrazePushEvent>? = null

    internal fun initializePlugin(application: Application, config: FlutterConfiguration) {
        application.registerActivityLifecycleCallbacks(BrazeActivityLifecycleCallbackListener())
        val ctx = application.applicationContext
        subscribeToContentCardsUpdatedEvent(ctx)
        subscribeToFeatureFlagsUpdatedEvent(ctx)
        subscribeToPushNotificationEvents(ctx)

        BrazeInAppMessageManager.getInstance()
                .setCustomInAppMessageManagerListener(
                        BrazeInAppMessageManagerListener(
                                config.automaticIntegrationInAppMessageOperation()
                        )
                )
        isUninitialized = false
    }

    private fun subscribeToContentCardsUpdatedEvent(ctx: Context) {
        Braze.getInstance(ctx)
                .removeSingleSubscription(
                        contentCardsUpdatedSubscriber,
                        ContentCardsUpdatedEvent::class.java
                )
        contentCardsUpdatedSubscriber = IEventSubscriber {
            BrazePlugin.processContentCards(it.allCards)
        }
        contentCardsUpdatedSubscriber?.let {
            Braze.getInstance(ctx).subscribeToContentCardsUpdates(it)
        }
        Braze.getInstance(ctx).requestContentCardsRefreshFromCache()
    }

    private fun subscribeToPushNotificationEvents(ctx: Context) {
        Braze.getInstance(ctx)
                .removeSingleSubscription(
                        pushNotificationsUpdatedSubscriber,
                        BrazePushEvent::class.java
                )
        pushNotificationsUpdatedSubscriber = IEventSubscriber {
            BrazePlugin.processPushNotificationEvent(it)
        }
        pushNotificationsUpdatedSubscriber?.let {
            Braze.getInstance(ctx).subscribeToPushNotificationEvents(it)
        }
    }

    private fun subscribeToFeatureFlagsUpdatedEvent(ctx: Context) {
        Braze.getInstance(ctx)
                .removeSingleSubscription(
                        featureFlagsUpdatedSubscriber,
                        FeatureFlagsUpdatedEvent::class.java
                )
        featureFlagsUpdatedSubscriber = IEventSubscriber {
            BrazePlugin.processFeatureFlags(it.featureFlags)
        }
        featureFlagsUpdatedSubscriber?.let {
            Braze.getInstance(ctx).subscribeToFeatureFlagsUpdates(it)
        }
        Braze.getInstance(ctx).refreshFeatureFlags()
    }

    private class BrazeInAppMessageManagerListener(
            val defaultInAppMessageOperation: InAppMessageOperation
    ) : DefaultInAppMessageManagerListener() {
        override fun beforeInAppMessageDisplayed(
                inAppMessage: IInAppMessage
        ): InAppMessageOperation {
            super.beforeInAppMessageDisplayed(inAppMessage)
            BrazePlugin.processInAppMessage(inAppMessage)
            brazelog {
                "Returning $defaultInAppMessageOperation in Flutter automatic integration IInAppMessageManagerListener#beforeInAppMessageDisplayed()"
            }
            return defaultInAppMessageOperation
        }
    }
}
