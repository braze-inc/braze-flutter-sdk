package braze.com.brazepluginexample

import android.view.View
import com.appboy.events.IEventSubscriber
import com.appboy.models.cards.Card
import com.braze.Braze
import com.braze.BrazeActivityLifecycleCallbackListener
import com.braze.events.ContentCardsUpdatedEvent
import com.braze.models.inappmessage.IInAppMessage
import com.braze.models.inappmessage.MessageButton
import com.braze.ui.inappmessage.BrazeInAppMessageManager
import com.braze.ui.inappmessage.InAppMessageCloser
import com.braze.ui.inappmessage.InAppMessageOperation
import com.braze.ui.inappmessage.listeners.IInAppMessageManagerListener
import com.braze.brazeplugin.BrazePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
  private var mContentCardsUpdatedSubscriber: IEventSubscriber<ContentCardsUpdatedEvent>? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    this.getApplication().registerActivityLifecycleCallbacks(BrazeActivityLifecycleCallbackListener())
    this.subscribeToContentCardsUpdatedEvent()

    BrazeInAppMessageManager.getInstance().setCustomInAppMessageManagerListener(
            BrazeInAppMessageManagerListener())
    Braze.getInstance(this).logCustomEvent("flutter_sample_opened")
  }

  private fun subscribeToContentCardsUpdatedEvent() {
    Braze.getInstance(this).removeSingleSubscription(mContentCardsUpdatedSubscriber, ContentCardsUpdatedEvent::class.java)
    mContentCardsUpdatedSubscriber = IEventSubscriber { event ->
      val allCards = event.allCards as ArrayList<Card>
      BrazePlugin.processContentCards(allCards)
    }
    Braze.getInstance(this).subscribeToContentCardsUpdates(mContentCardsUpdatedSubscriber)
    Braze.getInstance(this).requestContentCardsRefresh(true)
  }

  class BrazeInAppMessageManagerListener() : IInAppMessageManagerListener {
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
