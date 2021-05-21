package com.braze.brazeplugin

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

// Android V2 embedding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.FlutterPlugin

import com.appboy.enums.Gender
import com.appboy.enums.Month
import com.appboy.enums.NotificationSubscriptionType
import com.appboy.events.SimpleValueCallback
import com.appboy.models.cards.Card
import com.appboy.models.IInAppMessage
import com.appboy.models.IInAppMessageImmersive
import com.appboy.models.outgoing.AppboyProperties
import com.appboy.models.outgoing.AttributionData
import com.appboy.services.AppboyLocationService
import com.appboy.ui.activities.AppboyContentCardsActivity
import com.braze.Braze
import com.braze.BrazeUser

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.annotation.NonNull

import java.math.BigDecimal
import java.io.IOException

class BrazePlugin: MethodCallHandler, FlutterPlugin, ActivityAware {
  lateinit var context : Context
  lateinit var channel : MethodChannel
  var activity : Activity? = null

  //--
  // Setup
  //--

  private fun initPlugin(context: Context, messenger: BinaryMessenger) {
    val channel = MethodChannel(messenger, "braze_plugin")
    channel.setMethodCallHandler(this)
    this.context = context
    this.channel = channel
    activePlugins.add(this)
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    this.initPlugin(flutterPluginBinding.applicationContext, flutterPluginBinding.binaryMessenger)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    activePlugins.remove(this)
    channel.setMethodCallHandler(null)
  }

  companion object {
    // Contains all plugins that have been initialized and are attached to a Flutter engine.
    // If using Embedding V1 APIs, there can only be one plugin in this list.
    var activePlugins : ArrayList<BrazePlugin> = arrayListOf<BrazePlugin>()

    /**
     * Registers the plugin with the v1 embedding API for backward compatibility.
     */
    @JvmStatic
    @Suppress("unused")
    fun registerWith(registrar: Registrar) {
      var pluginInstance = BrazePlugin()
      pluginInstance.activity = registrar.activity()
      pluginInstance.initPlugin(registrar.context(), registrar.messenger())
    }

    //--
    // Braze public APIs
    //--

    @JvmStatic
    fun processInAppMessage(inAppMessage: IInAppMessage) {
      if (activePlugins.isEmpty()) {
        Log.e(null, "There are no active Braze Plugins. Not calling 'handleBrazeInAppMessage'.")
        return
      }

      val inAppMessageMap: HashMap<String, String> =
        hashMapOf("inAppMessage" to inAppMessage.forJsonPut().toString())

      for (plugin in activePlugins) {
        if (plugin.activity != null) {
          plugin.activity?.runOnUiThread(Runnable {
            plugin.channel.invokeMethod("handleBrazeInAppMessage", inAppMessageMap)
          })
        }
      }
    }

    @JvmStatic
    fun processContentCards(contentCardList: ArrayList<Card>) {
      if (activePlugins.isEmpty()) {
        Log.e(null, "There are no active Braze Plugins. Not calling 'handleBrazeContentCards'.")
        return
      }

      val cardStringList = arrayListOf<String>()
      for (card in contentCardList) {
        cardStringList.add(card.forJsonPut().toString())
      }
      val contentCardMap: HashMap<String, ArrayList<String>> = hashMapOf("contentCards" to cardStringList)

      for (plugin in activePlugins) {
        if (plugin.activity != null) {
          plugin.activity?.runOnUiThread(Runnable {
            plugin.channel.invokeMethod("handleBrazeContentCards", contentCardMap)
          })
        }
      }
    }
  }

  //--
  // ActivityAware
  //--

  override fun onDetachedFromActivity() {
    this.activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    this.activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity()
  }

  //--
  // Braze SDK bindings
  //--

  override fun onMethodCall(call: MethodCall, result: Result) {
    try {
      when (call.method) {
        "changeUser" -> {
          val userId = call.argument<String>("userId")
          Braze.getInstance(context).changeUser(userId)
        }
        "requestContentCardsRefresh" -> {
          Braze.getInstance(context).requestContentCardsRefresh(false)
        }
        "launchContentCards" -> {
          if (this.activity != null) {
            val intent = Intent(this.activity, AppboyContentCardsActivity::class.java)
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            this.context.startActivity(intent)
          }
        }
        "logContentCardClicked" -> {
          val contentCardString = call.argument<String>("contentCardString")
          if (contentCardString != null) {
            val contentCard = Braze.getInstance(context).deserializeContentCard(contentCardString)
            if (contentCard != null) {
              contentCard.logClick()
            }
          }
        }
        "logContentCardImpression" -> {
          val contentCardString = call.argument<String>("contentCardString")
          if (contentCardString != null) {
            val contentCard = Braze.getInstance(context).deserializeContentCard(contentCardString)
            if (contentCard != null) {
              contentCard.logImpression()
            }
          }
        }
        "logContentCardDismissed" -> {
          val contentCardString = call.argument<String>("contentCardString")
          if (contentCardString != null) {
            val contentCard = Braze.getInstance(context).deserializeContentCard(contentCardString)
            if (contentCard != null) {
              contentCard.setIsDismissed(true)
            }
          }
        }
        "logInAppMessageClicked" -> {
          val inAppMessage = Braze.getInstance(context)
              .deserializeInAppMessageString(call.argument<String>("inAppMessageString"))
          if (inAppMessage != null) {
            inAppMessage.logClick()
          }
        }
        "logInAppMessageImpression" -> {
          val inAppMessage = Braze.getInstance(context)
              .deserializeInAppMessageString(call.argument<String>("inAppMessageString"))
          if (inAppMessage != null) {
            inAppMessage.logImpression()
          }
        }
        "logInAppMessageButtonClicked" -> {
          val inAppMessage = Braze.getInstance(context)
              .deserializeInAppMessageString(call.argument<String>("inAppMessageString"))
          if (inAppMessage is IInAppMessageImmersive) {
            val buttonId = call.argument<Int>("buttonId")?: 0
            val inAppMessageImmersive = inAppMessage as IInAppMessageImmersive
            for (button in inAppMessageImmersive.getMessageButtons().orEmpty()) {
              if (button.getId() === buttonId) {
                inAppMessageImmersive.logButtonClick(button)
                break
              }
            }
          }
        }
        "addAlias" -> {
          val aliasName = call.argument<String>("aliasName")
          val aliasLabel = call.argument<String>("aliasLabel")
          Braze.getInstance(context).runOnUser { user -> user.addAlias(aliasName, aliasLabel) }
        }
        "logCustomEvent" -> {
          val eventName = call.argument<String>("eventName")
          val properties = convertToAppboyProperties(
                  call.argument<Map<String, *>>("properties"))
          Braze.getInstance(context).logCustomEvent(eventName, properties)
        }
        "logPurchase" -> {
          val productId = call.argument<String>("productId")
          val currencyCode = call.argument<String>("currencyCode")
          val price = call.argument<Double>("price")?: 0.0
          val quantity = call.argument<Int>("quantity")?: 1
          val properties = convertToAppboyProperties(
                  call.argument<Map<String, *>>("properties"))
          Braze.getInstance(context).logPurchase(productId, currencyCode, BigDecimal(price),
                  quantity, properties)
        }
        "addToCustomAttributeArray" -> {
          val key = call.argument<String>("key")
          val value = call.argument<String>("value")
          Braze.getInstance(context).runOnUser { user -> user.addToCustomAttributeArray(key, value) }
        }
        "removeFromCustomAttributeArray" -> {
          val key = call.argument<String>("key")
          val value = call.argument<String>("value")
          Braze.getInstance(context).runOnUser { user -> user.removeFromCustomAttributeArray(key, value) }
        }
        "setStringCustomUserAttribute" -> {
          val key = call.argument<String>("key")
          val value = call.argument<String>("value")
          Braze.getInstance(context).runOnUser { user -> user.setCustomUserAttribute(key, value) }
        }
        "setDoubleCustomUserAttribute" -> {
          val key = call.argument<String>("key")
          val value = call.argument<Double>("value")?: 0.0
          Braze.getInstance(context).runOnUser { user -> user.setCustomUserAttribute(key, value) }
        }
        "setDateCustomUserAttribute" -> {
          val key = call.argument<String>("key")
          val value = (call.argument<Int>("value")?: 0).toLong()
          Braze.getInstance(context).runOnUser { user -> user.setCustomUserAttributeToSecondsFromEpoch(key, value) }
        }
        "setIntCustomUserAttribute" -> {
          val key = call.argument<String>("key")
          val value = call.argument<Int>("value")?: 0
          Braze.getInstance(context).runOnUser { user -> user.setCustomUserAttribute(key, value) }
        }
        "incrementCustomUserAttribute" -> {
          val key = call.argument<String>("key")
          val value = call.argument<Int>("value")?: 0
          Braze.getInstance(context).runOnUser { user -> user.incrementCustomUserAttribute(key, value) }
        }
        "setBoolCustomUserAttribute" -> {
          val key = call.argument<String>("key")
          val value = call.argument<Boolean>("value")?: false
          Braze.getInstance(context).runOnUser { user -> user.setCustomUserAttribute(key, value) }
        }
        "unsetCustomUserAttribute" -> {
          val key = call.argument<String>("key")
          Braze.getInstance(context).runOnUser { user -> user.unsetCustomUserAttribute(key) }
        }
        "setPushNotificationSubscriptionType" -> {
          val type = getSubscriptionType(call.argument<String>("type")?: "")
          Braze.getInstance(context).runOnUser { user -> user.setPushNotificationSubscriptionType(type) }
        }
        "setEmailNotificationSubscriptionType" -> {
          val type = getSubscriptionType(call.argument<String>("type")?: "")
          Braze.getInstance(context).runOnUser { user -> user.setEmailNotificationSubscriptionType(type) }
        }
        "setLocationCustomAttribute" -> {
          val key = call.argument<String>("key")
          val lat = call.argument<Double>("lat")?: 0.0
          val long = call.argument<Double>("long")?: 0.0
          Braze.getInstance(context).runOnUser { user -> user.setLocationCustomAttribute(key, lat, long) }
        }
        "requestImmediateDataFlush" -> {
          Braze.getInstance(context).requestImmediateDataFlush()
        }
        "setFirstName" -> {
          val firstName = call.argument<String>("firstName")
          Braze.getInstance(context).runOnUser { user -> user.setFirstName(firstName) }
        }
        "setLastName" -> {
          val lastName = call.argument<String>("lastName")
          Braze.getInstance(context).runOnUser { user -> user.setLastName(lastName) }
        }
        "setDateOfBirth" -> {
          val year = call.argument<Int>("year")?: 0
          val month = getMonth(call.argument<Int>("month")?: 0)
          val day = call.argument<Int>("day")?: 0
          Braze.getInstance(context).runOnUser { user -> user.setDateOfBirth(year, month, day) }
        }
        "setEmail" -> {
          val email = call.argument<String>("email")
          Braze.getInstance(context).runOnUser { user -> user.setEmail(email) }
        }
        "setGender" -> {
          val gender = call.argument<String>("gender")
          val genderUpper = gender?.toUpperCase()?: ""
          val genderEnum: Gender
          if (genderUpper.startsWith("F")) {
            genderEnum = Gender.FEMALE
          } else if (genderUpper.startsWith("M")) {
            genderEnum = Gender.MALE
          } else if (genderUpper.startsWith("N")) {
            genderEnum = Gender.NOT_APPLICABLE
          } else if (genderUpper.startsWith("O")) {
            genderEnum = Gender.OTHER
          } else if (genderUpper.startsWith("P")) {
            genderEnum = Gender.PREFER_NOT_TO_SAY
          } else if (genderUpper.startsWith("U")) {
            genderEnum = Gender.UNKNOWN
          } else {
            return
          }
          Braze.getInstance(context).runOnUser { user -> user.setGender(genderEnum) }
        }
        "setLanguage" -> {
          val language = call.argument<String>("language")
          Braze.getInstance(context).runOnUser { user -> user.setLanguage(language) }
        }
        "setCountry" -> {
          val country = call.argument<String>("country")
          Braze.getInstance(context).runOnUser { user -> user.setCountry(country) }
        }
        "setHomeCity" -> {
          val homeCity = call.argument<String>("homeCity")
          Braze.getInstance(context).runOnUser { user -> user.setHomeCity(homeCity) }
        }
        "setPhoneNumber" -> {
          val phoneNumber = call.argument<String>("phoneNumber")
          Braze.getInstance(context).runOnUser { user -> user.setPhoneNumber(phoneNumber) }
        }
        "setAttributionData" -> {
          val network = call.argument<String>("network")
          val campaign = call.argument<String>("campaign")
          val adGroup = call.argument<String>("adGroup")
          val creative = call.argument<String>("creative")
          val attributionData = AttributionData(network, campaign, adGroup, creative)
          Braze.getInstance(context).runOnUser { user -> user.setAttributionData(attributionData) }
        }
        "setAvatarImageUrl" -> {
          val avatarImageUrl = call.argument<String>("avatarImageUrl")
          Braze.getInstance(context).runOnUser { user -> user.setAvatarImageUrl(avatarImageUrl) }
        }
        "registerAndroidPushToken" -> {
          val pushToken = call.argument<String>("pushToken")
          Braze.getInstance(context).registerAppboyPushMessages(pushToken)
        }
        "getInstallTrackingId" -> {
          result.success(Braze.getInstance(context).getInstallTrackingId())
        }
        "setGoogleAdvertisingId" -> {
          val id = call.argument<String>("id") ?: return
          val adTrackingEnabled = call.argument<Boolean>("adTrackingEnabled") ?: return
          Braze.getInstance(context).setGoogleAdvertisingId(id, adTrackingEnabled)
        }
        "wipeData" -> {
          Braze.wipeData(context)
        }
        "requestLocationInitialization" -> {
          AppboyLocationService.requestInitialization(context);
        }
        "enableSDK" -> {
          Braze.enableSdk(context)
        }
        "disableSDK" -> {
          Braze.disableSdk(context)
        }
        else -> result.notImplemented()
      }
    } catch (e: IOException) {
      result.error("IOException encountered", call.method, e)
    }
  }

  //--
  // Private methods
  //--

  /**
   * Attempts to fetch the current user and then runs a block on it
   */
  private fun Braze.runOnUser(block: (user: BrazeUser) -> Unit) {
    this.getCurrentUser(object : SimpleValueCallback<BrazeUser>() {
      override fun onSuccess(user: BrazeUser) {
        super.onSuccess(user)
        block(user)
      }
    })
  }

  private fun getSubscriptionType(type: String): NotificationSubscriptionType? {
    return when (type.trim()) {
      "SubscriptionType.subscribed" -> NotificationSubscriptionType.SUBSCRIBED
      "SubscriptionType.opted_in" -> NotificationSubscriptionType.OPTED_IN
      "SubscriptionType.unsubscribed" -> NotificationSubscriptionType.UNSUBSCRIBED
      else -> null
    }
  }

  private fun getMonth(month: Int): Month? {
    return when (month) {
      1 -> Month.JANUARY
      2 -> Month.FEBRUARY
      3 -> Month.MARCH
      4 -> Month.APRIL
      5 -> Month.MAY
      6 -> Month.JUNE
      7 -> Month.JULY
      8 -> Month.AUGUST
      9 -> Month.SEPTEMBER
      10 -> Month.OCTOBER
      11 -> Month.NOVEMBER
      12 -> Month.DECEMBER
      else -> null
    }
  }

  private fun convertToAppboyProperties(arguments: Map<String, *>?): AppboyProperties {
    val properties = AppboyProperties()
    if (arguments == null) {
      return properties
    }
    for (key in arguments.keys) {
      val value = arguments[key]
      if (value is Int) {
        properties.addProperty(key, value)
      } else if (value is String) {
        properties.addProperty(key, value)
      } else if (value is Double) {
        properties.addProperty(key, value)
      } else if (value is Boolean) {
        properties.addProperty(key, value)
      } else if (value is Long) {
        properties.addProperty(key, value.toInt())
      }
    }
    return properties
  }
}
