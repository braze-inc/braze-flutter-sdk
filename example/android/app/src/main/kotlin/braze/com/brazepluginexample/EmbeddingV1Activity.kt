@file:Suppress("DEPRECATION")
package braze.com.brazepluginexample

import android.os.Bundle
import android.util.Log
import com.braze.brazeplugin.BrazePlugin
import dev.flutter.plugins.integration_test.IntegrationTestPlugin
import io.flutter.app.FlutterActivity
import io.flutter.view.FlutterMain

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

class EmbeddingV1Activity : FlutterActivity() {
  private var mContentCardsUpdatedSubscriber: IEventSubscriber<ContentCardsUpdatedEvent>? = null

  override fun onCreate(savedInstanceState: Bundle?) {
    Log.d(null, "Initializing plugin with V1 Embedding.")
    FlutterMain.startInitialization(this)
    super.onCreate(savedInstanceState)
    BrazePlugin.registerWith(registrarFor("com.braze.brazeplugin.BrazePlugin"))
    IntegrationTestPlugin.registerWith(registrarFor("dev.flutter.plugins.integration_test.IntegrationTestPlugin"))

    this.getApplication().registerActivityLifecycleCallbacks(BrazeActivityLifecycleCallbackListener())
    this.subscribeToContentCardsUpdatedEvent()

    BrazeInAppMessageManager.getInstance().setCustomInAppMessageManagerListener(
            MainActivity.BrazeInAppMessageManagerListener())
    Braze.getInstance(this).logCustomEvent("flutter_sample_opened_v1")
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
