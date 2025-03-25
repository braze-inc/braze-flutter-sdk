package com.braze.brazeplugin

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import com.braze.Braze
import com.braze.BrazeUser
import com.braze.Constants
import com.braze.enums.BrazePushEventType
import com.braze.enums.Gender
import com.braze.enums.Month
import com.braze.enums.NotificationSubscriptionType
import com.braze.events.BrazePushEvent
import com.braze.events.BrazeSdkAuthenticationErrorEvent
import com.braze.events.SimpleValueCallback
import com.braze.models.Banner
import com.braze.models.FeatureFlag
import com.braze.models.cards.Card
import com.braze.models.inappmessage.IInAppMessage
import com.braze.models.inappmessage.IInAppMessageImmersive
import com.braze.models.outgoing.AttributionData
import com.braze.models.outgoing.BrazeProperties
import com.braze.support.BrazeLogger.Priority.I
import com.braze.support.BrazeLogger.Priority.W
import com.braze.support.BrazeLogger.brazelog
import com.braze.ui.activities.ContentCardsActivity
import com.braze.ui.inappmessage.BrazeInAppMessageManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import java.math.BigDecimal
import java.util.*
import org.json.JSONArray
import org.json.JSONObject
import BrazeUIHandler

@Suppress("LargeClass")
class BrazePlugin : MethodCallHandler, FlutterPlugin, ActivityAware {

    private lateinit var context: Context
    private lateinit var channel: MethodChannel
    private lateinit var flutterConfiguration: FlutterConfiguration

    // The Flutter Plugin Binding attached to the BrazePlugin
    private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null

    // The activity attached to the BrazePlugin
    private var activity: Activity? = null

    // --
    // Setup
    // --

    private fun initPlugin(context: Context, messenger: BinaryMessenger) {
        flutterConfiguration = FlutterConfiguration(context)
        val channel = MethodChannel(messenger, "braze_plugin")
        channel.setMethodCallHandler(this)
        this.context = context
        this.channel = channel
        activePlugins.add(this)

        Braze.getInstance(context)
            .subscribeToSdkAuthenticationFailures { message: BrazeSdkAuthenticationErrorEvent ->
                this.handleSdkAuthenticationError(message)
            }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        this.initPlugin(
            flutterPluginBinding.applicationContext,
            flutterPluginBinding.binaryMessenger
        )
        this.flutterPluginBinding = flutterPluginBinding
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        activePlugins.remove(this)
        channel.setMethodCallHandler(null)
    }

    // --
    // ActivityAware
    // --

    override fun onDetachedFromActivity() {
        this.activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.activity = binding.activity
        if (IntegrationInitializer.isUninitialized &&
            flutterConfiguration.isAutomaticInitializationEnabled()
        ) {
            brazelog(I) { "Running Flutter BrazePlugin automatic initialization" }
            this.activity?.application?.let {
                IntegrationInitializer.initializePlugin(it, flutterConfiguration)
            }
        }

        // We need both the the running activity and the Flutter Plugin Binding to register the
        // ViewFactory in order to ensure UI logic is executed on the main thread.
        this.flutterPluginBinding?.let { pluginBinding ->
            val uiHandler = BrazeUIHandler(pluginBinding.binaryMessenger)
            pluginBinding.platformViewRegistry.registerViewFactory(
                "BrazeBannerView",
                BrazeBannerViewFactory(uiHandler, binding.activity)
            )
        }

        reprocessPendingPushEvents()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    // --
    // Braze SDK bindings
    // --
    @Suppress("LongMethod", "ComplexMethod", "ComplexCondition", "NestedBlockDepth", "ReturnCount")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "changeUser" -> {
                    val userId = call.argument<String>("userId")
                    val sdkAuthSignature = call.argument<String>("sdkAuthSignature")
                    if (sdkAuthSignature == null) {
                        Braze.getInstance(context).changeUser(userId)
                    } else {
                        Braze.getInstance(context).changeUser(userId, sdkAuthSignature)
                    }
                }

                "getUserId" -> {
                    Braze.getInstance(context).runOnUser {
                        if (it.userId.isBlank()) {
                            result.success(null)
                        } else {
                            result.success(it.userId)
                        }
                    }
                }

                "setSdkAuthenticationSignature" -> {
                    val sdkAuthSignature = call.argument<String>("sdkAuthSignature")
                    if (sdkAuthSignature != null) {
                        Braze.getInstance(context).setSdkAuthenticationSignature(sdkAuthSignature)
                    }
                }

                "setBrazePluginIsReady" -> {
                    isBrazePluginIsReady = true
                    reprocessPendingPushEvents()
                }

                "requestContentCardsRefresh" -> {
                    Braze.getInstance(context).requestContentCardsRefresh()
                }

                "launchContentCards" -> {
                    if (this.activity != null) {
                        val intent = Intent(this.activity, ContentCardsActivity::class.java)
                        intent.flags =
                            Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                        this.context.startActivity(intent)
                    }
                }

                "getCachedContentCards" -> {
                    val contentCards = Braze.getInstance(context).getCachedContentCards()
                    if (contentCards != null) {
                        result.success(
                            contentCards.map { contentCard ->
                                contentCard.forJsonPut().toString()
                            }
                        )
                    }
                }

                "logContentCardClicked" -> {
                    val contentCardString = call.argument<String>("contentCardString")
                    if (contentCardString != null) {
                        Braze.getInstance(context)
                            .deserializeContentCard(contentCardString)
                            ?.logClick()
                    }
                }

                "logContentCardImpression" -> {
                    val contentCardString = call.argument<String>("contentCardString")
                    if (contentCardString != null) {
                        Braze.getInstance(context)
                            .deserializeContentCard(contentCardString)
                            ?.logImpression()
                    }
                }

                "logContentCardDismissed" -> {
                    val contentCardString = call.argument<String>("contentCardString")
                    if (contentCardString != null) {
                        Braze.getInstance(context)
                            .deserializeContentCard(contentCardString)
                            ?.isDismissed = true
                    }
                }

                "getBanner" -> {
                    val placementId = call.argument<String>("placementId")
                    if (placementId == null) {
                        brazelog(W) { "Unexpected null placementId in `getBanner`." }
                        return
                    }
                    val banner = Braze.getInstance(context).getBanner(placementId)
                    // Unwrap the "banner" outer layer of the object before sending to Dart
                    val bannerString = banner?.let { it.forJsonPut().get("banner").toString() }
                    result.success(bannerString)
                }

                "requestBannersRefresh" -> {
                    val placementIds = call.argument<List<String>>("placementIds")
                    if (placementIds == null) {
                        brazelog(W) { "Unexpected null ids in `requestBannersRefresh`." }
                        return
                    }
                    Braze.getInstance(context).requestBannersRefresh(placementIds)
                    result.success("`requestBannersRefresh` called.")
                }

                "logInAppMessageClicked" -> {
                    Braze.getInstance(context)
                        .deserializeInAppMessageString(call.argument("inAppMessageString"))
                        ?.logClick()
                }

                "logInAppMessageImpression" -> {
                    Braze.getInstance(context)
                        .deserializeInAppMessageString(call.argument("inAppMessageString"))
                        ?.logImpression()
                }

                "logInAppMessageButtonClicked" -> {
                    val inAppMessage =
                        Braze.getInstance(context)
                            .deserializeInAppMessageString(
                                call.argument("inAppMessageString")
                            )
                    if (inAppMessage is IInAppMessageImmersive) {
                        val buttonId = call.argument<Int>("buttonId") ?: 0
                        for (button in inAppMessage.messageButtons) {
                            if (button.id == buttonId) {
                                inAppMessage.logButtonClick(button)
                                break
                            }
                        }
                    }
                }

                "hideCurrentInAppMessage" -> {
                    BrazeInAppMessageManager.getInstance().hideCurrentlyDisplayingInAppMessage(true)
                }

                "addAlias" -> {
                    val aliasName = call.argument<String>("aliasName")
                    val aliasLabel = call.argument<String>("aliasLabel")
                    if (aliasName == null || aliasLabel == null) {
                        brazelog(W) { "Unexpected null parameter(s) in `addAlias`." }
                        return
                    }
                    Braze.getInstance(context).runOnUser { user ->
                        user.addAlias(aliasName, aliasLabel)
                    }
                }

                "logCustomEvent" -> {
                    val eventName = call.argument<String>("eventName")
                    val properties =
                        convertToBrazeProperties(call.argument<Map<String, *>>("properties"))
                    Braze.getInstance(context).logCustomEvent(eventName, properties)
                }

                "logPurchase" -> {
                    val productId = call.argument<String>("productId")
                    val currencyCode = call.argument<String>("currencyCode")
                    val price = call.argument<Double>("price") ?: 0.0
                    val quantity = call.argument<Int>("quantity") ?: 1
                    val properties =
                        convertToBrazeProperties(call.argument<Map<String, *>>("properties"))
                    Braze.getInstance(context)
                        .logPurchase(
                            productId,
                            currencyCode,
                            BigDecimal(price),
                            quantity,
                            properties
                        )
                }

                "addToCustomAttributeArray" -> {
                    val key = call.argument<String>("key")
                    val value = call.argument<String>("value")
                    if (key == null || value == null) {
                        brazelog(W) {
                            "Unexpected null parameter(s) in `addToCustomAttributeArray`."
                        }
                        return
                    }
                    Braze.getInstance(context).runOnUser { user ->
                        user.addToCustomAttributeArray(key, value)
                    }
                }

                "removeFromCustomAttributeArray" -> {
                    val key = call.argument<String>("key")
                    val value = call.argument<String>("value")
                    if (key == null || value == null) {
                        brazelog(W) {
                            "Unexpected null parameter(s) in `removeFromCustomAttributeArray`."
                        }
                        return
                    }
                    Braze.getInstance(context).runOnUser { user ->
                        user.removeFromCustomAttributeArray(key, value)
                    }
                }

                "setNestedCustomUserAttribute" -> {
                    val key = call.argument<String>("key")
                    val value = call.argument<Map<String, *>>("value")?.let { JSONObject(it) }
                    val shouldMerge = call.argument<Boolean>("merge") ?: false
                    if (key == null || value == null) {
                        brazelog(W) {
                            "Unexpected null parameter(s) in `setNestedCustomUserAttribute`."
                        }
                        return
                    }
                    Braze.getInstance(context).runOnUser { user ->
                        user.setCustomUserAttribute(key, value, shouldMerge)
                    }
                }

                "setCustomUserAttributeArrayOfStrings" -> {
                    val key = call.argument<String>("key")
                    val value = call.argument<List<String?>>("value")?.toTypedArray()
                    if (key == null || value == null) {
                        brazelog(W) {
                            "Unexpected null parameter(s) in `setCustomUserAttributeArrayOfStrings`."
                        }
                        return
                    }
                    Braze.getInstance(context).runOnUser { user ->
                        user.setCustomAttributeArray(key, value)
                    }
                }

                "setCustomUserAttributeArrayOfObjects" -> {
                    val key = call.argument<String>("key")
                    val value =
                        JSONArray(
                            call.argument<List<Map<String, *>>>("value")?.map {
                                JSONObject(it)
                            }
                        )
                    if (key == null) {
                        brazelog(W) {
                            "Unexpected null parameter(s) in `setCustomUserAttributeArrayOfObjects`."
                        }
                        return
                    }
                    Braze.getInstance(context).runOnUser { user ->
                        user.setCustomAttribute(key, value)
                    }
                }

                "setStringCustomUserAttribute" -> {
                    val key = call.argument<String>("key")
                    val value = call.argument<String>("value")
                    if (key == null || value == null) {
                        brazelog(W) {
                            "Unexpected null parameter(s) in `setStringCustomUserAttribute`."
                        }
                        return
                    }
                    Braze.getInstance(context).runOnUser { user ->
                        user.setCustomUserAttribute(key, value)
                    }
                }

                "setDoubleCustomUserAttribute" -> {
                    val key = call.argument<String>("key")
                    val value = call.argument<Double>("value") ?: 0.0
                    if (key == null) {
                        brazelog(W) { "Unexpected null key in `setDoubleCustomUserAttribute`" }
                        return
                    }
                    Braze.getInstance(context).runOnUser { user ->
                        user.setCustomUserAttribute(key, value)
                    }
                }

                "setDateCustomUserAttribute" -> {
                    val key = call.argument<String>("key")
                    val value = (call.argument<Int>("value") ?: 0).toLong()
                    if (key == null) {
                        brazelog(W) { "Unexpected null key in `setDateCustomUserAttribute`." }
                        return
                    }
                    Braze.getInstance(context).runOnUser { user ->
                        user.setCustomUserAttributeToSecondsFromEpoch(key, value)
                    }
                }

                "setIntCustomUserAttribute" -> {
                    val key = call.argument<String>("key")
                    val value = call.argument<Int>("value") ?: 0
                    if (key == null) {
                        brazelog(W) { "Unexpected null key in `setIntCustomUserAttribute`." }
                        return
                    }
                    Braze.getInstance(context).runOnUser { user ->
                        user.setCustomUserAttribute(key, value)
                    }
                }

                "incrementCustomUserAttribute" -> {
                    val key = call.argument<String>("key")
                    val value = call.argument<Int>("value") ?: 0
                    if (key == null) {
                        brazelog(W) { "Unexpected null key in `incrementCustomUserAttribute`." }
                        return
                    }
                    Braze.getInstance(context).runOnUser { user ->
                        user.incrementCustomUserAttribute(key, value)
                    }
                }

                "setBoolCustomUserAttribute" -> {
                    val key = call.argument<String>("key")

                    @Suppress("BooleanPropertyNaming")
                    val value = call.argument<Boolean>("value") ?: false
                    if (key == null) {
                        brazelog(W) { "Unexpected null key in `setBoolCustomUserAttribute`." }
                        return
                    }
                    Braze.getInstance(context).runOnUser { user ->
                        user.setCustomUserAttribute(key, value)
                    }
                }

                "unsetCustomUserAttribute" -> {
                    val key = call.argument<String>("key")
                    if (key == null) {
                        brazelog(W) { "Unexpected null key in `unsetCustomUserAttribute`." }
                        return
                    }
                    Braze.getInstance(context).runOnUser { user ->
                        user.unsetCustomUserAttribute(key)
                    }
                }

                "setPushNotificationSubscriptionType" -> {
                    val type = getSubscriptionType(call.argument<String>("type").orEmpty())
                    if (type == null) {
                        brazelog(W) {
                            "Unexpected null type in `setPushNotificationSubscriptionType`."
                        }
                        return
                    }
                    Braze.getInstance(context).runOnUser { user ->
                        user.setPushNotificationSubscriptionType(type)
                    }
                }

                "setEmailNotificationSubscriptionType" -> {
                    val type = getSubscriptionType(call.argument<String>("type").orEmpty())
                    if (type == null) {
                        brazelog(W) {
                            "Unexpected null type in `setEmailNotificationSubscriptionType`."
                        }
                        return
                    }
                    Braze.getInstance(context).runOnUser { user ->
                        user.setEmailNotificationSubscriptionType(type)
                    }
                }

                "addToSubscriptionGroup" -> {
                    val groupId = call.argument<String>("groupId")
                    if (groupId == null) {
                        brazelog(W) { "Unexpected null groupId in `addToSubscriptionGroup`." }
                        return
                    }
                    Braze.getInstance(context).runOnUser { user ->
                        user.addToSubscriptionGroup(groupId)
                    }
                }

                "removeFromSubscriptionGroup" -> {
                    val groupId = call.argument<String>("groupId")
                    if (groupId == null) {
                        brazelog(W) { "Unexpected null groupId in `removeFromSubscriptionGroup`." }
                        return
                    }
                    Braze.getInstance(context).runOnUser { user ->
                        user.removeFromSubscriptionGroup(groupId)
                    }
                }

                "setLocationCustomAttribute" -> {
                    val key = call.argument<String>("key")
                    val lat = call.argument<Double>("lat") ?: 0.0
                    val long = call.argument<Double>("long") ?: 0.0
                    if (key == null) {
                        brazelog(W) { "Unexpected null key in `setLocationCustomAttribute`." }
                        return
                    }
                    Braze.getInstance(context).runOnUser { user ->
                        user.setLocationCustomAttribute(key, lat, long)
                    }
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
                    val year = call.argument<Int>("year") ?: 0
                    val month = getMonth(call.argument<Int>("month") ?: 0)
                    val day = call.argument<Int>("day") ?: 0
                    Braze.getInstance(context).runOnUser { user ->
                        user.setDateOfBirth(year, month, day)
                    }
                }

                "setEmail" -> {
                    val email = call.argument<String>("email")
                    Braze.getInstance(context).runOnUser { user -> user.setEmail(email) }
                }

                "setGender" -> {
                    val gender = call.argument<String>("gender")
                    val genderUpper = gender?.uppercase(Locale.getDefault()) ?: ""
                    val genderEnum =
                        when {
                            genderUpper.startsWith("F") -> {
                                Gender.FEMALE
                            }

                            genderUpper.startsWith("M") -> {
                                Gender.MALE
                            }

                            genderUpper.startsWith("N") -> {
                                Gender.NOT_APPLICABLE
                            }

                            genderUpper.startsWith("O") -> {
                                Gender.OTHER
                            }

                            genderUpper.startsWith("P") -> {
                                Gender.PREFER_NOT_TO_SAY
                            }

                            genderUpper.startsWith("U") -> {
                                Gender.UNKNOWN
                            }

                            else -> {
                                return
                            }
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
                    Braze.getInstance(context).runOnUser { user ->
                        user.setPhoneNumber(phoneNumber)
                    }
                }

                "setAttributionData" -> {
                    val network = call.argument<String>("network")
                    val campaign = call.argument<String>("campaign")
                    val adGroup = call.argument<String>("adGroup")
                    val creative = call.argument<String>("creative")
                    if (network == null || campaign == null || adGroup == null || creative == null
                    ) {
                        brazelog(W) { "Unexpected null parameter(s) in `setAttributionData`." }
                        return
                    }
                    val attributionData = AttributionData(network, campaign, adGroup, creative)
                    Braze.getInstance(context).runOnUser { user ->
                        user.setAttributionData(attributionData)
                    }
                }

                "registerPushToken" -> {
                    val pushToken = call.argument<String>("pushToken")
                    Braze.getInstance(context).registeredPushToken = pushToken
                }

                "getDeviceId" -> {
                    result.success(Braze.getInstance(context).deviceId)
                }

                "setGoogleAdvertisingId" -> {
                    val id = call.argument<String>("id") ?: return
                    val isAdTrackingEnabled = call.argument<Boolean>("adTrackingEnabled") ?: return
                    Braze.getInstance(context).setGoogleAdvertisingId(id, isAdTrackingEnabled)
                }

                "setAdTrackingEnabled" -> {
                    val isAdTrackingEnabled = call.argument<Boolean>("adTrackingEnabled") ?: return
                    val id = call.argument<String>("id") ?: return
                    Braze.getInstance(context).setGoogleAdvertisingId(id, isAdTrackingEnabled)
                }

                "updateTrackingPropertyAllowList" -> {
                    // No-op on Android
                }

                "wipeData" -> {
                    Braze.wipeData(context)
                }

                "requestLocationInitialization" -> {
                    Braze.getInstance(context).requestLocationInitialization()
                }

                "setLastKnownLocation" -> {
                    val latitude = call.argument<Double>("latitude")
                    val longitude = call.argument<Double>("longitude")
                    val accuracy = call.argument<Double>("accuracy")
                    val altitude = call.argument<Double?>("altitude")
                    if (latitude == null || longitude == null) {
                        brazelog(W) { "Unexpected null parameter(s) in `setLastKnownLocation`." }
                        return
                    }
                    Braze.getInstance(context).runOnUser { user ->
                        user.setLastKnownLocation(latitude, longitude, altitude, accuracy)
                    }
                }

                "enableSDK" -> {
                    Braze.enableSdk(context)
                }

                "disableSDK" -> {
                    Braze.disableSdk(context)
                }

                "setSdkAuthenticationDelegate" -> {
                    // No-op on Android
                }

                "getFeatureFlagByID" -> {
                    val ffId = call.argument<String>("id")
                    if (ffId == null) {
                        brazelog(W) { "Unexpected null id in `getFeatureFlagByID`." }
                        return
                    }

                    val featureFlag = Braze.getInstance(context).getFeatureFlag(ffId)
                    if (featureFlag == null) {
                        result.success(null)
                    } else {
                        result.success(featureFlag.forJsonPut().toString())
                    }
                }

                "getAllFeatureFlags" -> {
                    val featureFlags = Braze.getInstance(context).getAllFeatureFlags()
                    result.success(
                        featureFlags.map { featureFlag -> featureFlag.forJsonPut().toString() }
                    )
                }

                "refreshFeatureFlags" -> {
                    Braze.getInstance(context).refreshFeatureFlags()
                }

                "logFeatureFlagImpression" -> {
                    val ffId = call.argument<String>("id")
                    if (ffId == null) {
                        brazelog(W) { "Unexpected null id in `logFeatureFlagImpression`." }
                        return
                    }
                    Braze.getInstance(context).logFeatureFlagImpression(ffId)
                }

                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("Exception encountered", call.method, e)
        }
    }

    // --
    // Private methods
    // --
    private fun handleSdkAuthenticationError(errorEvent: BrazeSdkAuthenticationErrorEvent) {
        if (activePlugins.isEmpty()) {
            brazelog(W) {
                "There are no active Braze Plugins. Not calling 'handleSdkAuthenticationError'."
            }
            return
        }

        val errorEventMap =
            hashMapOf(
                "code" to errorEvent.errorCode.toString(),
                "reason" to errorEvent.errorReason,
                "userId" to errorEvent.userId,
            )

        val sdkAuthenticationErrorMap: HashMap<String, String> =
            hashMapOf(
                "sdkAuthenticationError" to JSONObject(errorEventMap.toString()).toString()
            )

        executeOnAllPlugins {
            it.channel.invokeMethod("handleSdkAuthenticationError", sdkAuthenticationErrorMap)
        }
    }

    /** Attempts to fetch the current user and then runs a block on it. */
    private fun Braze.runOnUser(block: (user: BrazeUser) -> Unit) {
        this.getCurrentUser(
            object : SimpleValueCallback<BrazeUser>() {
                override fun onSuccess(value: BrazeUser) {
                    super.onSuccess(value)
                    block(value)
                }
            }
        )
    }

    private fun getSubscriptionType(type: String): NotificationSubscriptionType? {
        return when (type.trim()) {
            "SubscriptionType.subscribed" -> NotificationSubscriptionType.SUBSCRIBED
            "SubscriptionType.opted_in" -> NotificationSubscriptionType.OPTED_IN
            "SubscriptionType.unsubscribed" -> NotificationSubscriptionType.UNSUBSCRIBED
            else -> null
        }
    }

    private fun getMonth(value: Int): Month {
        val month = Month.getMonth(value - 1)
        if (month == null) {
            brazelog(W) { "Invalid `null` month. Defaulting to January." }
            return Month.JANUARY
        }
        return month
    }

    private fun convertToBrazeProperties(arguments: Map<String, *>?): BrazeProperties {
        if (arguments == null) {
            return BrazeProperties()
        }

        val jsonObject = JSONObject(arguments)
        return BrazeProperties(jsonObject)
    }

    companion object {
        // Contains all plugins that have been initialized and are attached to a Flutter engine.
        var activePlugins = mutableListOf<BrazePlugin>()

        // Contains all push events that have been received before the plugin was initialized.
        var pendingPushEvents = mutableListOf<BrazePushEvent>()

        // Indicates if the Dart layer has finished initializing
        private var isBrazePluginIsReady: Boolean = false

        // --
        // Braze public APIs
        // --

        /**
         * Used to pass in In App Message data from the Braze SDK native layer to the Flutter layer.
         */
        @JvmStatic
        fun processInAppMessage(inAppMessage: IInAppMessage) {
            if (activePlugins.isEmpty()) {
                brazelog(W) {
                    "There are no active Braze Plugins. Not calling 'handleBrazeInAppMessage'."
                }
                return
            }

            val inAppMessageMap: HashMap<String, String> =
                hashMapOf("inAppMessage" to inAppMessage.forJsonPut().toString())

            executeOnAllPlugins {
                it.channel.invokeMethod("handleBrazeInAppMessage", inAppMessageMap)
            }
        }

        /**
         * Used to pass in Content Card data from the Braze SDK native layer to the Flutter layer.
         */
        @JvmStatic
        fun processContentCards(contentCardList: List<Card>) {
            if (activePlugins.isEmpty()) {
                brazelog(W) {
                    "There are no active Braze Plugins. Not calling 'handleBrazeContentCards'."
                }
                return
            }

            val cardStringList = arrayListOf<String>()
            for (card in contentCardList) {
                cardStringList.add(card.forJsonPut().toString())
            }
            val contentCardMap: HashMap<String, ArrayList<String>> =
                hashMapOf("contentCards" to cardStringList)

            executeOnAllPlugins {
                it.channel.invokeMethod("handleBrazeContentCards", contentCardMap)
            }
        }

        /**
         * Used to pass in Banner data from the Braze SDK native layer to the Flutter layer.
         *
         * Parameter bannerList: The list of banners from the native Android SDK, where each
         * object has an outer key called "banner" with the value being the banner data.
         */
        @JvmStatic
        fun processBanners(bannerList: List<Banner>) {
            if (activePlugins.isEmpty()) {
                brazelog(W) {
                    "There are no active Braze Plugins. Not calling 'handleBrazeBanners'."
                }
                return
            }

            val bannerStringList = arrayListOf<String>()
            for (banner in bannerList) {
                // Unwrap the "banner" outer layer of the object before sending to the Flutter layer
                bannerStringList.add(banner.forJsonPut().get("banner").toString())
            }
            val bannersMap: HashMap<String, ArrayList<String>> =
                hashMapOf("banners" to bannerStringList)

            executeOnAllPlugins { it.channel.invokeMethod("handleBrazeBanners", bannersMap) }
        }

        /**
         * Used to pass in Push Notification event data from the Braze SDK native layer to the
         * Flutter layer.
         *
         * If there are no active Braze Plugins, it stores the event for later processing.
         */
        @JvmStatic
        fun processPushNotificationEvent(event: BrazePushEvent) {
            if (activePlugins.isEmpty() || !isBrazePluginIsReady) {
                brazelog(W) {
                    "There are no active Braze Plugins. Not calling 'handleBrazePushNotificationEvent'. Storing the event for later processing."
                }
                // Store the event for later processing.
                pendingPushEvents.add(event)
                return
            }

            handlePushEvent(event)
        }

        /**
         * Reprocesses all pending push events if there are any active plugins and the Dart layer
         * has finished initializing.
         */
        private fun reprocessPendingPushEvents() {
            if (pendingPushEvents.isNotEmpty() && activePlugins.isNotEmpty() && isBrazePluginIsReady
            ) {
                for (event in pendingPushEvents) {
                    handlePushEvent(event)
                }
                pendingPushEvents.clear()
            }
        }

        /**
         * Handles the push event by converting it to a JSON object and sending it to the Dart
         * layer.
         */
        private fun handlePushEvent(event: BrazePushEvent) {
            val pushType =
                when (event.eventType) {
                    BrazePushEventType.NOTIFICATION_RECEIVED -> "push_received"
                    BrazePushEventType.NOTIFICATION_OPENED -> "push_opened"
                    else -> return Unit
                }
            val eventData = event.notificationPayload

            val data =
                JSONObject().apply {
                    put("payload_type", pushType)
                    put("url", eventData.deeplink)
                    put("title", eventData.titleText)
                    put("body", eventData.contentText)
                    put("summary_text", eventData.summaryText)
                    eventData.notificationBadgeNumber?.let { put("badge_count", it) }
                    eventData
                        .notificationExtras
                        .getLong("braze_push_received_timestamp")
                        .takeUnless { it == 0L }
                        ?.let { put("timestamp", it.toLong()) }
                    put(
                        "use_webview",
                        eventData.notificationExtras.getString("ab_use_webview") == "true"
                    )
                    put(
                        "is_silent",
                        eventData.titleText == null && eventData.contentText == null
                    )
                    put(
                        "is_braze_internal",
                        eventData.isUninstallTrackingPush || eventData.shouldSyncGeofences || eventData.shouldRefreshFeatureFlags
                    )
                    put("image_url", eventData.bigImageUrl)
                    put("android", convertToMap(eventData.notificationExtras))
                }
            val brazePropertiesMap =
                convertToMap(
                    eventData.brazeExtras,
                    setOf(Constants.BRAZE_PUSH_BIG_IMAGE_URL_KEY)
                )
            data.put("braze_properties", brazePropertiesMap)
            val pushEventMap = hashMapOf("pushEvent" to data.toString())

            executeOnAllPlugins {
                it.channel.invokeMethod("handleBrazePushNotificationEvent", pushEventMap)
            }
        }

        /**
         * Used to pass in Feature Flag data from the Braze SDK native layer to the Flutter layer.
         */
        @JvmStatic
        fun processFeatureFlags(featureFlagList: List<FeatureFlag>) {
            if (activePlugins.isEmpty()) {
                brazelog(W) {
                    "There are no active Braze Plugins. Not calling 'handleBrazeFeatureFlags'."
                }
                return
            }

            val ffStringList = featureFlagList.map { it.forJsonPut().toString() }
            val featureFlagMap = hashMapOf("featureFlags" to ffStringList)

            executeOnAllPlugins {
                it.channel.invokeMethod("handleBrazeFeatureFlags", featureFlagMap)
            }
        }

        private fun executeOnAllPlugins(block: (BrazePlugin) -> Unit) {
            for (plugin in activePlugins) {
                plugin.activity?.runOnUiThread { block(plugin) }
            }
        }

        private fun convertToMap(
            bundle: Bundle,
            filteringKeys: Set<String> = emptySet()
        ): JSONObject {
            val map = JSONObject()
            bundle.keySet()
                .filter { !filteringKeys.contains(it) }
                .associateWith { @Suppress("deprecation") bundle[it] }
                .forEach { map.put(it.key, it.value) }
            return map
        }
    }
}
