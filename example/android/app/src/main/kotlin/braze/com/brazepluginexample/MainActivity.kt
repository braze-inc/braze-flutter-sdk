package braze.com.brazepluginexample

import android.view.View
import com.appboy.Appboy
import com.appboy.AppboyLifecycleCallbackListener
import com.appboy.events.ContentCardsUpdatedEvent
import com.appboy.events.IEventSubscriber
import com.appboy.models.IInAppMessage
import com.appboy.models.MessageButton
import com.appboy.models.cards.Card
import com.appboy.ui.inappmessage.AppboyInAppMessageManager
import com.appboy.ui.inappmessage.InAppMessageCloser
import com.appboy.ui.inappmessage.InAppMessageOperation
import com.appboy.ui.inappmessage.listeners.IInAppMessageManagerListener
import com.braze.brazeplugin.BrazePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
  private var mContentCardsUpdatedSubscriber: IEventSubscriber<ContentCardsUpdatedEvent>? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    this.getApplication().registerActivityLifecycleCallbacks(AppboyLifecycleCallbackListener())
    this.subscribeToContentCardsUpdatedEvent()

    AppboyInAppMessageManager.getInstance().setCustomInAppMessageManagerListener(
            BrazeInAppMessageManagerListener())
    Appboy.getInstance(this).logCustomEvent("flutter_sample_opened")
  }

  private fun subscribeToContentCardsUpdatedEvent() {
    Appboy.getInstance(this).removeSingleSubscription(mContentCardsUpdatedSubscriber, ContentCardsUpdatedEvent::class.java)
    mContentCardsUpdatedSubscriber = IEventSubscriber { event ->
      val allCards = event.allCards as ArrayList<Card>
      BrazePlugin.processContentCards(allCards)
    }
    Appboy.getInstance(this).subscribeToContentCardsUpdates(mContentCardsUpdatedSubscriber)
    Appboy.getInstance(this).requestContentCardsRefresh(true)
  }

  class BrazeInAppMessageManagerListener() : IInAppMessageManagerListener {
    override fun onInAppMessageReceived(inAppMessage: IInAppMessage): Boolean {
      return false
    }

    override fun beforeInAppMessageDisplayed(inAppMessage: IInAppMessage): InAppMessageOperation {
      BrazePlugin.processInAppMessage(inAppMessage)
      return InAppMessageOperation.DISPLAY_NOW
    }

    override fun onInAppMessageClicked(inAppMessage: IInAppMessage,
                                       inAppMessageCloser: InAppMessageCloser): Boolean {
      return false
    }

    override fun onInAppMessageButtonClicked(inAppMessage: IInAppMessage, button: MessageButton,
                                             inAppMessageCloser: InAppMessageCloser): Boolean {
      return false
    }

    override fun onInAppMessageDismissed(inAppMessage: IInAppMessage) {}

    override fun beforeInAppMessageViewClosed(inAppMessageView: View, inAppMessage: IInAppMessage) {}

    override fun afterInAppMessageViewClosed(inAppMessage: IInAppMessage) {}

    override fun beforeInAppMessageViewOpened(inAppMessageView: View, inAppMessage: IInAppMessage) {}

    override fun afterInAppMessageViewOpened(inAppMessageView: View, inAppMessage: IInAppMessage) {}
  }
}
