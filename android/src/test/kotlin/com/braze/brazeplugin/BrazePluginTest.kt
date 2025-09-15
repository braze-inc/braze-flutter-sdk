package com.braze.brazeplugin

import android.app.Activity
import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.braze.Braze
import com.braze.BrazeUser
import com.braze.events.SimpleValueCallback
import com.braze.models.FeatureFlag
import com.braze.models.inappmessage.IInAppMessage
import com.braze.models.inappmessage.IInAppMessageImmersive
import com.braze.models.inappmessage.MessageButton
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformViewRegistry
import org.json.JSONObject
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mockito.verify
import org.mockito.Mockito.`when`
import org.mockito.kotlin.any
import org.mockito.kotlin.eq
import org.mockito.kotlin.mock
import org.mockito.kotlin.never
import org.mockito.kotlin.verifyNoInteractions
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
@Suppress("LargeClass")
class BrazePluginTest {
    private var mockBinaryMessenger: BinaryMessenger = mock()
    private var mockFlutterPluginBinding: FlutterPlugin.FlutterPluginBinding = mock()
    private var mockActivityPluginBinding: ActivityPluginBinding = mock()
    private var mockBraze: Braze = mock()
    private var mockBrazeUser: BrazeUser = mock()
    private var mockMethodChannelResult: MethodChannel.Result = mock()
    private var mockPlatformViewRegistry: PlatformViewRegistry = mock {
        on { registerViewFactory(any(), any()) }.thenReturn(true)
    }

    private lateinit var brazePlugin: BrazePlugin

    val activity: Activity
        get() {
            val controller = Robolectric.buildActivity(
                TestActivityForJunitRunner::class.java
            )
            return controller.get()
        }

    val context: Context
        get() = ApplicationProvider.getApplicationContext()

    @Before
    fun setUp() {
        // Setup mocks
        `when`(mockFlutterPluginBinding.applicationContext).thenReturn(context)
        `when`(mockFlutterPluginBinding.binaryMessenger).thenReturn(mockBinaryMessenger)
        `when`(mockFlutterPluginBinding.platformViewRegistry).thenReturn(mockPlatformViewRegistry)
        `when`(mockActivityPluginBinding.activity).thenReturn(activity)

        // Set mock Braze instance
        BrazePlugin.setMockBrazeInstance(mockBraze)
        setupBrazeUserCallback(mockBraze, mockBrazeUser)

        // Create plugin instance
        brazePlugin = BrazePlugin()
        brazePlugin.onAttachedToEngine(mockFlutterPluginBinding)
        brazePlugin.onAttachedToActivity(mockActivityPluginBinding)
    }

    @After
    fun tearDown() {
        BrazePlugin.setMockBrazeInstance(null)
        BrazePlugin.activePlugins.clear()
        BrazePlugin.pendingPushEvents.clear()
    }

    @Test
    fun whenNotGivenSdkAuthToken_changeUser_callsStandardChangeUser() {
        // Given
        val userId = "test_user_id"
        val arguments = mapOf("userId" to userId)

        // When
        val call = MethodCall("changeUser", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBraze).changeUser(userId)
    }

    @Test
    fun whenGivenSdkAuthToken_changeUser_callsStandardChangeUser() {
        // Given
        val userId = "test_user_id"
        val sdkAuthToken = "test_sdk_auth_token"
        val arguments = mapOf("userId" to userId, "sdkAuthSignature" to sdkAuthToken)

        // When
        val call = MethodCall("changeUser", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBraze).changeUser(userId, sdkAuthToken)
    }

    @Test
    fun whenLogInAppMessageButtonClicked_withValidButtonId_logsButtonClick() {
        // Given
        val inAppMessageString = "test_in_app_message_string"
        val buttonId = 123
        val mockInAppMessage: IInAppMessageImmersive = mock()
        val mockButton: MessageButton = mock()

        `when`(mockButton.id).thenReturn(buttonId)
        `when`(mockInAppMessage.messageButtons).thenReturn(listOf(mockButton))
        `when`(mockBraze.deserializeInAppMessageString(inAppMessageString)).thenReturn(
            mockInAppMessage
        )

        val arguments = mapOf(
            "inAppMessageString" to inAppMessageString,
            "buttonId" to buttonId
        )

        // When
        val call = MethodCall("logInAppMessageButtonClicked", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockInAppMessage).logButtonClick(mockButton)
    }

    @Test
    fun whenLogInAppMessageButtonClicked_withNonImmersiveMessage_doesNotLogButtonClick() {
        // Given
        val inAppMessageString = "test_in_app_message_string"
        val buttonId = 123
        val mockInAppMessage: IInAppMessage = mock() // Not immersive

        `when`(mockBraze.deserializeInAppMessageString(inAppMessageString)).thenReturn(
            mockInAppMessage
        )

        val arguments = mapOf(
            "inAppMessageString" to inAppMessageString,
            "buttonId" to buttonId
        )

        // When
        val call = MethodCall("logInAppMessageButtonClicked", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBraze).deserializeInAppMessageString(any())
        verifyNoInteractions(mockInAppMessage)
    }

    @Test
    fun whenLogInAppMessageButtonClicked_withButtonIdZero_usesDefaultButtonId() {
        // Given
        val inAppMessageString = "test_in_app_message_string"
        val mockInAppMessage: IInAppMessageImmersive = mock()
        val mockButton: MessageButton = mock()

        `when`(mockButton.id).thenReturn(0)
        `when`(mockInAppMessage.messageButtons).thenReturn(listOf(mockButton))
        `when`(mockBraze.deserializeInAppMessageString(inAppMessageString)).thenReturn(
            mockInAppMessage
        )

        val arguments = mapOf(
            "inAppMessageString" to inAppMessageString
            // buttonId not provided, should default to 0
        )

        // When
        val call = MethodCall("logInAppMessageButtonClicked", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockInAppMessage).logButtonClick(mockButton)
    }

    @Test
    fun whenSetSdkAuthenticationSignature_withValidSignature_callsSetSdkAuthenticationSignature() {
        // Given
        val sdkAuthSignature = "test_sdk_auth_signature"
        val arguments = mapOf("sdkAuthSignature" to sdkAuthSignature)

        // When
        val call = MethodCall("setSdkAuthenticationSignature", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBraze).setSdkAuthenticationSignature(sdkAuthSignature)
    }

    @Test
    fun whenSetSdkAuthenticationSignature_withNullSignature_doesNotCallSetSdkAuthenticationSignature() {
        // Given
        val arguments = mapOf<String, String?>("sdkAuthSignature" to null)

        // When
        val call = MethodCall("setSdkAuthenticationSignature", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBraze, never()).setSdkAuthenticationSignature(any())
    }

    @Test
    fun whenRequestContentCardsRefresh_callsRequestContentCardsRefresh() {
        // Given
        val arguments = emptyMap<String, Any>()

        // When
        val call = MethodCall("requestContentCardsRefresh", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBraze).requestContentCardsRefresh()
    }

    @Test
    fun whenGetCachedContentCards_withValidCards_returnsContentCards() {
        // Given
        val mockCard: com.braze.models.cards.Card = mock()
        val mockCardJson = "{\"id\":\"test_card\"}"
        `when`(mockCard.forJsonPut()).thenReturn(org.json.JSONObject(mockCardJson))
        `when`(mockBraze.getCachedContentCards()).thenReturn(listOf(mockCard))

        val arguments = emptyMap<String, Any>()

        // When
        val call = MethodCall("getCachedContentCards", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockMethodChannelResult).success(listOf(mockCardJson))
    }

    @Test
    fun whenGetCachedContentCards_withNullCards_doesNotCallCallback() {
        // Given
        `when`(mockBraze.getCachedContentCards()).thenReturn(null)
        val arguments = emptyMap<String, Any>()

        // When
        val call = MethodCall("getCachedContentCards", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verifyNoInteractions(mockMethodChannelResult)
    }

    @Test
    fun whenLogContentCardClicked_withValidCardString_logsCardClick() {
        // Given
        val contentCardString = "test_content_card_string"
        val mockCard: com.braze.models.cards.Card = mock()
        `when`(mockBraze.deserializeContentCard(contentCardString)).thenReturn(mockCard)

        val arguments = mapOf("contentCardString" to contentCardString)

        // When
        val call = MethodCall("logContentCardClicked", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockCard).logClick()
    }

    @Test
    fun whenLogContentCardImpression_withValidCardString_logsCardImpression() {
        // Given
        val contentCardString = "test_content_card_string"
        val mockCard: com.braze.models.cards.Card = mock()
        `when`(mockBraze.deserializeContentCard(contentCardString)).thenReturn(mockCard)

        val arguments = mapOf("contentCardString" to contentCardString)

        // When
        val call = MethodCall("logContentCardImpression", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockCard).logImpression()
    }

    @Test
    fun whenLogContentCardDismissed_withValidCardString_setsCardDismissed() {
        // Given
        val contentCardString = "test_content_card_string"
        val mockCard: com.braze.models.cards.Card = mock()
        `when`(mockBraze.deserializeContentCard(contentCardString)).thenReturn(mockCard)

        val arguments = mapOf("contentCardString" to contentCardString)

        // When
        val call = MethodCall("logContentCardDismissed", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockCard).isDismissed = true
    }

    @Test
    fun whenGetBanner_withValidPlacementId_returnsBanner() {
        // Given
        val placementId = "test_placement_id"
        val mockBanner: com.braze.models.Banner = mock()
        val mockBannerJson = "{\"banner\":{\"id\":\"test_banner\"}}"
        `when`(mockBanner.forJsonPut()).thenReturn(org.json.JSONObject(mockBannerJson))
        `when`(mockBraze.getBanner(placementId)).thenReturn(mockBanner)

        val arguments = mapOf("placementId" to placementId)

        // When
        val call = MethodCall("getBanner", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockMethodChannelResult).success("{\"id\":\"test_banner\"}")
    }

    @Test
    fun whenGetBanner_withNullPlacementId_returnsEarly() {
        // Given
        val arguments = mapOf<String, String?>("placementId" to null)

        // When
        val call = MethodCall("getBanner", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBraze, never()).requestBannersRefresh(any())
        verify(mockBraze, never()).getBanner(any())
    }

    @Test
    fun whenRequestBannersRefresh_withValidPlacementIds_callsRequestBannersRefresh() {
        // Given
        val placementIds = listOf("placement1", "placement2")
        val arguments = mapOf("placementIds" to placementIds)

        // When
        val call = MethodCall("requestBannersRefresh", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBraze).requestBannersRefresh(placementIds)
        verify(mockMethodChannelResult).success("`requestBannersRefresh` called.")
    }

    @Test
    fun whenRequestBannersRefresh_withNullPlacementIds_returnsEarly() {
        // Given
        val arguments = mapOf<String, List<String>?>("placementIds" to null)

        // When
        val call = MethodCall("requestBannersRefresh", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBraze, never()).requestBannersRefresh(any())
    }

    @Test
    fun whenLogInAppMessageClicked_withValidMessageString_logsMessageClick() {
        // Given
        val inAppMessageString = "test_in_app_message_string"
        val mockInAppMessage: IInAppMessage = mock()
        `when`(mockBraze.deserializeInAppMessageString(inAppMessageString)).thenReturn(
            mockInAppMessage
        )

        val arguments = mapOf("inAppMessageString" to inAppMessageString)

        // When
        val call = MethodCall("logInAppMessageClicked", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockInAppMessage).logClick()
    }

    @Test
    fun whenLogInAppMessageImpression_withValidMessageString_logsMessageImpression() {
        // Given
        val inAppMessageString = "test_in_app_message_string"
        val mockInAppMessage: IInAppMessage = mock()
        `when`(mockBraze.deserializeInAppMessageString(inAppMessageString)).thenReturn(
            mockInAppMessage
        )

        val arguments = mapOf("inAppMessageString" to inAppMessageString)

        // When
        val call = MethodCall("logInAppMessageImpression", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockInAppMessage).logImpression()
    }

    @Test
    fun whenAddAlias_withValidParameters_addsAliasToUser() {
        // Given
        val aliasName = "test_alias"
        val aliasLabel = "test_label"
        val arguments = mapOf(
            "aliasName" to aliasName,
            "aliasLabel" to aliasLabel
        )

        // When
        val call = MethodCall("addAlias", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).addAlias(eq(aliasName), eq(aliasLabel))
    }

    @Test
    fun whenAddAlias_withNullParameters_returnsEarly() {
        // Given
        val arguments = mapOf<String, String?>(
            "aliasName" to null,
            "aliasLabel" to "test_label"
        )

        // When
        val call = MethodCall("addAlias", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser, never()).addAlias(any(), any())
    }

    @Test
    fun whenLogCustomEvent_withValidParameters_logsCustomEvent() {
        // Given
        val eventName = "test_event"
        val properties = mapOf("key" to "value")
        val arguments = mapOf(
            "eventName" to eventName,
            "properties" to properties
        )

        // When
        val call = MethodCall("logCustomEvent", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBraze).logCustomEvent(eq(eventName), any())
    }

    @Test
    fun whenLogPurchase_withValidParameters_logsPurchase() {
        // Given
        val productId = "test_product"
        val currencyCode = "USD"
        val price = 9.99
        val quantity = 2
        val properties = mapOf("key" to "value")
        val arguments = mapOf(
            "productId" to productId,
            "currencyCode" to currencyCode,
            "price" to price,
            "quantity" to quantity,
            "properties" to properties
        )

        // When
        val call = MethodCall("logPurchase", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBraze).logPurchase(
            eq(productId),
            eq(currencyCode),
            any(),
            eq(quantity),
            any()
        )
    }

    @Test
    fun whenLogPurchase_withDefaultValues_usesDefaultPriceAndQuantity() {
        // Given
        val productId = "test_product"
        val currencyCode = "USD"
        val arguments = mapOf(
            "productId" to productId,
            "currencyCode" to currencyCode
            // price and quantity not provided, should default to 0.0 and 1
        )

        // When
        val call = MethodCall("logPurchase", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBraze).logPurchase(
            eq(productId),
            eq(currencyCode),
            any(),
            eq(1),
            any()
        )
    }

    @Test
    fun whenGetUserId_withValidUserId_returnsUserId() {
        // Given
        val userId = "test_user_id"
        `when`(mockBrazeUser.userId).thenReturn(userId)
        setupBrazeUserCallback(mockBraze, mockBrazeUser)

        // When
        val call = MethodCall("getUserId", emptyMap<String, Any>())
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockMethodChannelResult).success(userId)
    }

    @Test
    fun whenGetUserId_withEmptyUserId_returnsNull() {
        // Given
        `when`(mockBrazeUser.userId).thenReturn("")
        setupBrazeUserCallback(mockBraze, mockBrazeUser)

        // When
        val call = MethodCall("getUserId", emptyMap<String, Any>())
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockMethodChannelResult).success(null)
    }

    @Test
    fun whenGetUserId_withBlankUserId_returnsNull() {
        // Given
        `when`(mockBrazeUser.userId).thenReturn("   ")
        setupBrazeUserCallback(mockBraze, mockBrazeUser)

        // When
        val call = MethodCall("getUserId", emptyMap<String, Any>())
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockMethodChannelResult).success(null)
    }

    @Test
    fun whenAddToCustomAttributeArray_withValidParameters_addsToCustomAttributeArray() {
        // Given
        val key = "test_key"
        val value = "test_value"
        val arguments = mapOf(
            "key" to key,
            "value" to value
        )

        // When
        val call = MethodCall("addToCustomAttributeArray", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        verify(mockBrazeUser).addToCustomAttributeArray(eq(key), eq(value))
    }

    @Test
    fun whenAddToCustomAttributeArray_withNullParameters_returnsEarly() {
        // Given
        val arguments = mapOf<String, String?>(
            "key" to null,
            "value" to "test_value"
        )

        // When
        val call = MethodCall("addToCustomAttributeArray", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verifyNoInteractions(mockMethodChannelResult)
    }

    @Test
    fun whenRemoveFromCustomAttributeArray_withValidParameters_removesFromCustomAttributeArray() {
        // Given
        val key = "test_key"
        val value = "test_value"
        val arguments = mapOf(
            "key" to key,
            "value" to value
        )

        // When
        val call = MethodCall("removeFromCustomAttributeArray", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).removeFromCustomAttributeArray(eq(key), eq(value))
    }

    @Test
    fun whenRemoveFromCustomAttributeArray_withNullParameters_returnsEarly() {
        // Given
        val arguments = mapOf<String, String?>(
            "key" to null,
            "value" to "test_value"
        )

        // When
        val call = MethodCall("removeFromCustomAttributeArray", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verifyNoInteractions(mockMethodChannelResult)
    }

    @Test
    fun whenSetNestedCustomUserAttribute_withValidParameters_setsNestedCustomUserAttribute() {
        // Given
        val key = "test_key"
        val value = mapOf("nested" to "value")
        val shouldMerge = true
        val arguments = mapOf(
            "key" to key,
            "value" to value,
            "merge" to shouldMerge
        )

        // When
        val call = MethodCall("setNestedCustomUserAttribute", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setCustomUserAttribute(eq(key), any(), eq(shouldMerge))
    }

    @Test
    fun whenSetNestedCustomUserAttribute_withNullParameters_returnsEarly() {
        // Given
        val arguments = mapOf<String, Any?>(
            "key" to null,
            "value" to mapOf("nested" to "value")
        )

        // When
        val call = MethodCall("setNestedCustomUserAttribute", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verifyNoInteractions(mockMethodChannelResult)
    }

    @Test
    fun whenSetCustomUserAttributeArrayOfStrings_withValidParameters_setsCustomAttributeArray() {
        // Given
        val key = "test_key"
        val value = listOf("value1", "value2")
        val arguments = mapOf(
            "key" to key,
            "value" to value
        )

        // When
        val call = MethodCall("setCustomUserAttributeArrayOfStrings", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setCustomAttributeArray(eq(key), eq(value.toTypedArray()))
    }

    @Test
    fun whenSetCustomUserAttributeArrayOfStrings_withNullParameters_returnsEarly() {
        // Given
        val arguments = mapOf<String, Any?>(
            "key" to null,
            "value" to listOf("value1", "value2")
        )

        // When
        val call = MethodCall("setCustomUserAttributeArrayOfStrings", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verifyNoInteractions(mockMethodChannelResult)
    }

    @Test
    fun whenSetCustomUserAttributeArrayOfObjects_withValidParameters_setsCustomAttribute() {
        // Given
        val key = "test_key"
        val value = listOf(mapOf("obj1" to "value1"), mapOf("obj2" to "value2"))
        val arguments = mapOf(
            "key" to key,
            "value" to value
        )

        // When
        val call = MethodCall("setCustomUserAttributeArrayOfObjects", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setCustomAttribute(
            eq(key),
            any(),
            any()
        )
    }

    @Test
    fun whenSetCustomUserAttributeArrayOfObjects_withNullKey_returnsEarly() {
        // Given
        val arguments = mapOf<String, Any?>(
            "key" to null,
            "value" to listOf(mapOf("obj1" to "value1"))
        )

        // When
        val call = MethodCall("setCustomUserAttributeArrayOfObjects", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verifyNoInteractions(mockMethodChannelResult)
    }

    @Test
    fun whenSetStringCustomUserAttribute_withValidParameters_setsCustomUserAttribute() {
        // Given
        val key = "test_key"
        val value = "test_value"
        val arguments = mapOf(
            "key" to key,
            "value" to value
        )

        // When
        val call = MethodCall("setStringCustomUserAttribute", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setCustomUserAttribute(eq(key), eq(value))
    }

    @Test
    fun whenSetStringCustomUserAttribute_withNullParameters_returnsEarly() {
        // Given
        val arguments = mapOf<String, String?>(
            "key" to null,
            "value" to "test_value"
        )

        // When
        val call = MethodCall("setStringCustomUserAttribute", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verifyNoInteractions(mockMethodChannelResult)
    }

    @Test
    fun whenSetDoubleCustomUserAttribute_withValidParameters_setsCustomUserAttribute() {
        // Given
        val key = "test_key"
        val value = 42.5
        val arguments = mapOf(
            "key" to key,
            "value" to value
        )

        // When
        val call = MethodCall("setDoubleCustomUserAttribute", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setCustomUserAttribute(eq(key), eq(value))
    }

    @Test
    fun whenSetDoubleCustomUserAttribute_withDefaultValue_usesDefaultValue() {
        // Given
        val key = "test_key"
        val arguments = mapOf("key" to key)
        // value not provided, should default to 0.0

        // When
        val call = MethodCall("setDoubleCustomUserAttribute", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setCustomUserAttribute(eq(key), eq(0.0))
    }

    @Test
    fun whenSetDateCustomUserAttribute_withValidParameters_setsCustomUserAttribute() {
        // Given
        val key = "test_key"
        val value = 1640995200 // Unix timestamp
        val arguments = mapOf(
            "key" to key,
            "value" to value
        )

        // When
        val call = MethodCall("setDateCustomUserAttribute", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setCustomUserAttributeToSecondsFromEpoch(
            eq(key),
            eq(value.toLong())
        )
    }

    @Test
    fun whenSetDateCustomUserAttribute_withDefaultValue_usesDefaultValue() {
        // Given
        val key = "test_key"
        val arguments = mapOf("key" to key)
        // value not provided, should default to 0

        // When
        val call = MethodCall("setDateCustomUserAttribute", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setCustomUserAttributeToSecondsFromEpoch(
            eq(key),
            eq(0L)
        )
    }

    @Test
    fun whenSetIntCustomUserAttribute_withValidParameters_setsCustomUserAttribute() {
        // Given
        val key = "test_key"
        val value = 42
        val arguments = mapOf(
            "key" to key,
            "value" to value
        )

        // When
        val call = MethodCall("setIntCustomUserAttribute", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setCustomUserAttribute(eq(key), eq(value))
    }

    @Test
    fun whenSetIntCustomUserAttribute_withDefaultValue_usesDefaultValue() {
        // Given
        val key = "test_key"
        val arguments = mapOf("key" to key)
        // value not provided, should default to 0

        // When
        val call = MethodCall("setIntCustomUserAttribute", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setCustomUserAttribute(eq(key), eq(0))
    }

    @Test
    fun whenIncrementCustomUserAttribute_withValidParameters_incrementsCustomUserAttribute() {
        // Given
        val key = "test_key"
        val value = 5
        val arguments = mapOf(
            "key" to key,
            "value" to value
        )

        // When
        val call = MethodCall("incrementCustomUserAttribute", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).incrementCustomUserAttribute(
            eq(key),
            eq(value)
        )
    }

    @Test
    fun whenIncrementCustomUserAttribute_withDefaultValue_usesDefaultValue() {
        // Given
        val key = "test_key"
        val arguments = mapOf("key" to key)
        // value not provided, should default to 0

        // When
        val call = MethodCall("incrementCustomUserAttribute", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).incrementCustomUserAttribute(
            eq(key),
            eq(0)
        )
    }

    @Test
    fun whenSetBoolCustomUserAttribute_withValidParameters_setsCustomUserAttribute() {
        // Given
        val key = "test_key"
        val value = true
        val arguments = mapOf(
            "key" to key,
            "value" to value
        )

        // When
        val call = MethodCall("setBoolCustomUserAttribute", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setCustomUserAttribute(eq(key), eq(value))
    }

    @Test
    fun whenSetBoolCustomUserAttribute_withDefaultValue_usesDefaultValue() {
        // Given
        val key = "test_key"
        val arguments = mapOf("key" to key)
        // value not provided, should default to false

        // When
        val call = MethodCall("setBoolCustomUserAttribute", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setCustomUserAttribute(eq(key), eq(false))
    }

    @Test
    fun whenUnsetCustomUserAttribute_withValidKey_unsetsCustomUserAttribute() {
        // Given
        val key = "test_key"
        val arguments = mapOf("key" to key)

        // When
        val call = MethodCall("unsetCustomUserAttribute", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).unsetCustomUserAttribute(eq(key))
    }

    @Test
    fun whenUnsetCustomUserAttribute_withNullKey_returnsEarly() {
        // Given
        val arguments = mapOf<String, String?>("key" to null)

        // When
        val call = MethodCall("unsetCustomUserAttribute", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verifyNoInteractions(mockMethodChannelResult)
    }

    @Test
    fun whenSetPushNotificationSubscriptionType_withValidType_setsPushNotificationSubscriptionType() {
        // Given
        val type = "SubscriptionType.subscribed"
        val arguments = mapOf("type" to type)

        // When
        val call = MethodCall("setPushNotificationSubscriptionType", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setPushNotificationSubscriptionType(any())
    }

    @Test
    fun whenSetPushNotificationSubscriptionType_withInvalidType_returnsEarly() {
        // Given
        val type = "InvalidType"
        val arguments = mapOf("type" to type)

        // When
        val call = MethodCall("setPushNotificationSubscriptionType", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verifyNoInteractions(mockMethodChannelResult)
    }

    @Test
    fun whenSetEmailNotificationSubscriptionType_withValidType_setsEmailNotificationSubscriptionType() {
        // Given
        val type = "SubscriptionType.opted_in"
        val arguments = mapOf("type" to type)

        // When
        val call = MethodCall("setEmailNotificationSubscriptionType", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setEmailNotificationSubscriptionType(any())
    }

    @Test
    fun whenSetEmailNotificationSubscriptionType_withInvalidType_returnsEarly() {
        // Given
        val type = "InvalidType"
        val arguments = mapOf("type" to type)

        // When
        val call = MethodCall("setEmailNotificationSubscriptionType", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verifyNoInteractions(mockMethodChannelResult)
    }

    @Test
    fun whenAddToSubscriptionGroup_withValidGroupId_addsToSubscriptionGroup() {
        // Given
        val groupId = "test_group_id"
        val arguments = mapOf("groupId" to groupId)

        // When
        val call = MethodCall("addToSubscriptionGroup", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).addToSubscriptionGroup(eq(groupId))
    }

    @Test
    fun whenAddToSubscriptionGroup_withNullGroupId_returnsEarly() {
        // Given
        val arguments = mapOf<String, String?>("groupId" to null)

        // When
        val call = MethodCall("addToSubscriptionGroup", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verifyNoInteractions(mockMethodChannelResult)
    }

    @Test
    fun whenRemoveFromSubscriptionGroup_withValidGroupId_removesFromSubscriptionGroup() {
        // Given
        val groupId = "test_group_id"
        val arguments = mapOf("groupId" to groupId)

        // When
        val call = MethodCall("removeFromSubscriptionGroup", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).removeFromSubscriptionGroup(eq(groupId))
    }

    @Test
    fun whenRemoveFromSubscriptionGroup_withNullGroupId_returnsEarly() {
        // Given
        val arguments = mapOf<String, String?>("groupId" to null)

        // When
        val call = MethodCall("removeFromSubscriptionGroup", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verifyNoInteractions(mockMethodChannelResult)
    }

    @Test
    fun whenSetLocationCustomAttribute_withValidParameters_setsLocationCustomAttribute() {
        // Given
        val key = "test_key"
        val latitude = 40.7128
        val longitude = -74.0060
        val arguments = mapOf(
            "key" to key,
            "lat" to latitude,
            "long" to longitude
        )

        // When
        val call = MethodCall("setLocationCustomAttribute", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setLocationCustomAttribute(
            eq(key),
            eq(latitude),
            eq(longitude),
        )
    }

    @Test
    fun whenSetLocationCustomAttribute_withDefaultValues_usesDefaultValues() {
        // Given
        val key = "test_key"
        val arguments = mapOf("key" to key)
        // lat and long not provided, should default to 0.0

        // When
        val call = MethodCall("setLocationCustomAttribute", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setLocationCustomAttribute(
            eq(key),
            eq(0.0),
            eq(0.0),
        )
    }

    @Test
    fun whenSetLocationCustomAttribute_withNullKey_returnsEarly() {
        // Given
        val arguments = mapOf<String, Any?>(
            "key" to null,
            "lat" to 40.7128,
            "long" to -74.0060
        )

        // When
        val call = MethodCall("setLocationCustomAttribute", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verifyNoInteractions(mockMethodChannelResult)
    }

    @Test
    fun whenRequestImmediateDataFlush_callsRequestImmediateDataFlush() {
        // Given
        val arguments = emptyMap<String, Any>()

        // When
        val call = MethodCall("requestImmediateDataFlush", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBraze).requestImmediateDataFlush()
    }

    @Test
    fun whenSetFirstName_withValidFirstName_setsFirstName() {
        // Given
        val firstName = "John"
        val arguments = mapOf("firstName" to firstName)

        // When
        val call = MethodCall("setFirstName", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setFirstName(eq(firstName))
    }

    @Test
    fun whenSetLastName_withValidLastName_setsLastName() {
        // Given
        val lastName = "Doe"
        val arguments = mapOf("lastName" to lastName)

        // When
        val call = MethodCall("setLastName", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setLastName(eq(lastName))
    }

    @Test
    fun whenSetDateOfBirth_withValidParameters_setsDateOfBirth() {
        // Given
        val year = 1990
        val month = 6
        val day = 15
        val arguments = mapOf(
            "year" to year,
            "month" to month,
            "day" to day
        )

        // When
        val call = MethodCall("setDateOfBirth", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setDateOfBirth(
            eq(year),
            any(),
            eq(day)
        )
    }

    @Test
    fun whenSetDateOfBirth_withDefaultValues_usesDefaultValues() {
        // Given
        val arguments = mapOf<String, Int>()
        // year, month, day not provided, should default to 0

        // When
        val call = MethodCall("setDateOfBirth", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setDateOfBirth(
            eq(0),
            any(),
            eq(0)
        )
    }

    @Test
    fun whenSetEmail_withValidEmail_setsEmail() {
        // Given
        val email = "test@example.com"
        val arguments = mapOf("email" to email)

        // When
        val call = MethodCall("setEmail", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setEmail(eq(email))
    }

    @Test
    fun whenSetGender_withValidGender_setsGender() {
        // Given
        val gender = "M"
        val arguments = mapOf("gender" to gender)

        // When
        val call = MethodCall("setGender", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setGender(any())
    }

    @Test
    fun whenSetLanguage_withValidLanguage_setsLanguage() {
        // Given
        val language = "en"
        val arguments = mapOf("language" to language)

        // When
        val call = MethodCall("setLanguage", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setLanguage(eq(language))
    }

    @Test
    fun whenSetCountry_withValidCountry_setsCountry() {
        // Given
        val country = "US"
        val arguments = mapOf("country" to country)

        // When
        val call = MethodCall("setCountry", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setCountry(eq(country))
    }

    @Test
    fun whenSetHomeCity_withValidHomeCity_setsHomeCity() {
        // Given
        val homeCity = "New York"
        val arguments = mapOf("homeCity" to homeCity)

        // When
        val call = MethodCall("setHomeCity", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setHomeCity(eq(homeCity))
    }

    @Test
    fun whenSetPhoneNumber_withValidPhoneNumber_setsPhoneNumber() {
        // Given
        val phoneNumber = "+1234567890"
        val arguments = mapOf("phoneNumber" to phoneNumber)

        // When
        val call = MethodCall("setPhoneNumber", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setPhoneNumber(eq(phoneNumber))
    }

    @Test
    fun whenSetAttributionData_withValidParameters_setsAttributionData() {
        // Given
        val network = "test_network"
        val campaign = "test_campaign"
        val adGroup = "test_ad_group"
        val creative = "test_creative"
        val arguments = mapOf(
            "network" to network,
            "campaign" to campaign,
            "adGroup" to adGroup,
            "creative" to creative
        )

        // When
        val call = MethodCall("setAttributionData", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setAttributionData(any())
    }

    @Test
    fun whenSetAttributionData_withNullParameters_returnsEarly() {
        // Given
        val arguments = mapOf<String, String?>(
            "network" to null,
            "campaign" to "test_campaign",
            "adGroup" to "test_ad_group",
            "creative" to "test_creative"
        )

        // When
        val call = MethodCall("setAttributionData", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verifyNoInteractions(mockMethodChannelResult)
    }

    @Test
    fun whenRegisterPushToken_withValidToken_setsRegisteredPushToken() {
        // Given
        val pushToken = "test_push_token"
        val arguments = mapOf("pushToken" to pushToken)

        // When
        val call = MethodCall("registerPushToken", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBraze).registeredPushToken = pushToken
    }

    @Test
    fun whenGetDeviceId_returnsDeviceId() {
        // Given
        val deviceId = "test_device_id"
        `when`(mockBraze.deviceId).thenReturn(deviceId)
        val arguments = emptyMap<String, Any>()

        // When
        val call = MethodCall("getDeviceId", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockMethodChannelResult).success(deviceId)
    }

    @Test
    fun whenSetGoogleAdvertisingId_withValidParameters_callsSetGoogleAdvertisingId() {
        // Given
        val id = "test_advertising_id"
        val isAdTrackingEnabled = true
        val arguments = mapOf(
            "id" to id,
            "adTrackingEnabled" to isAdTrackingEnabled
        )

        // When
        val call = MethodCall("setGoogleAdvertisingId", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBraze).setGoogleAdvertisingId(
            id,
            isAdTrackingEnabled
        )
    }

    @Test
    fun whenSetGoogleAdvertisingId_withNullId_returnsEarly() {
        // Given
        val arguments = mapOf<String, Any?>(
            "id" to null,
            "adTrackingEnabled" to true
        )

        // When
        val call = MethodCall("setGoogleAdvertisingId", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verifyNoInteractions(mockMethodChannelResult)
    }

    @Test
    fun whenSetAdTrackingEnabled_withValidParameters_callsSetGoogleAdvertisingId() {
        // Given
        val isAdTrackingEnabled = false
        val id = "test_advertising_id"
        val arguments = mapOf(
            "adTrackingEnabled" to isAdTrackingEnabled,
            "id" to id
        )

        // When
        val call = MethodCall("setAdTrackingEnabled", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBraze).setGoogleAdvertisingId(
            id,
            isAdTrackingEnabled
        )
    }

    @Test
    fun whenSetAdTrackingEnabled_withNullId_returnsEarly() {
        // Given
        val arguments = mapOf<String, Any?>(
            "adTrackingEnabled" to true,
            "id" to null
        )

        // When
        val call = MethodCall("setAdTrackingEnabled", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verifyNoInteractions(mockMethodChannelResult)
    }

    @Test
    fun whenUpdateTrackingPropertyAllowList_doesNothing() {
        // Given
        val arguments = emptyMap<String, Any>()

        // When
        val call = MethodCall("updateTrackingPropertyAllowList", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        // This method is iOS-only and does nothing on Android
        // The test ensures the method call doesn't throw an exception
        verifyNoInteractions(mockMethodChannelResult)
    }

    @Test
    fun whenRequestLocationInitialization_callsRequestLocationInitialization() {
        // Given
        val arguments = emptyMap<String, Any>()

        // When
        val call = MethodCall("requestLocationInitialization", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBraze).requestLocationInitialization()
    }

    @Test
    fun whenSetLastKnownLocation_withValidParameters_setsLastKnownLocation() {
        // Given
        val latitude = 40.7128
        val longitude = -74.0060
        val accuracy = 10.0
        val altitude = 100.0
        val arguments = mapOf(
            "latitude" to latitude,
            "longitude" to longitude,
            "accuracy" to accuracy,
            "altitude" to altitude
        )

        // When
        val call = MethodCall("setLastKnownLocation", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setLastKnownLocation(
            eq(latitude),
            eq(longitude),
            eq(altitude),
            eq(accuracy),
            eq(null)
        )
    }

    @Test
    fun whenSetLastKnownLocation_withDefaultValues_usesDefaultValues() {
        // Given
        val latitude = 40.7128
        val longitude = -74.0060
        val arguments = mapOf(
            "latitude" to latitude,
            "longitude" to longitude
        )
        // accuracy and altitude not provided, should default to 0.0 and null

        // When
        val call = MethodCall("setLastKnownLocation", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBrazeUser).setLastKnownLocation(
            eq(latitude),
            eq(longitude),
            eq(null),
            eq(null),
            eq(null)
        )
    }

    @Test
    fun whenSetLastKnownLocation_withNullParameters_returnsEarly() {
        // Given
        val arguments = mapOf<String, Any?>(
            "latitude" to null,
            "longitude" to -74.0060
        )

        // When
        val call = MethodCall("setLastKnownLocation", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verifyNoInteractions(mockMethodChannelResult)
    }

    @Test
    fun whenSetSdkAuthenticationDelegate_doesNothing() {
        // Given
        val arguments = emptyMap<String, Any>()

        // When
        val call = MethodCall("setSdkAuthenticationDelegate", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        // This method is iOS-only and does nothing on Android
        // The test ensures the method call doesn't throw an exception
        verifyNoInteractions(mockMethodChannelResult)
    }

    @Test
    fun whenGetFeatureFlagByID_withValidId_returnsFeatureFlag() {
        // Given
        val ffId = "test_feature_flag_id"
        val mockFeatureFlag: com.braze.models.FeatureFlag = mock()
        val mockFeatureFlagJson = "{\"id\":\"test_ff\"}"
        `when`(mockFeatureFlag.forJsonPut()).thenReturn(JSONObject(mockFeatureFlagJson))
        `when`(mockBraze.getFeatureFlag(ffId)).thenReturn(mockFeatureFlag)

        val arguments = mapOf("id" to ffId)

        // When
        val call = MethodCall("getFeatureFlagByID", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockMethodChannelResult).success(mockFeatureFlagJson)
    }

    @Test
    fun whenGetFeatureFlagByID_withNullId_returnsEarly() {
        // Given
        val arguments = mapOf<String, String?>("id" to null)

        // When
        val call = MethodCall("getFeatureFlagByID", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verifyNoInteractions(mockMethodChannelResult)
    }

    @Test
    fun whenGetFeatureFlagByID_withNonExistentId_returnsNull() {
        // Given
        val ffId = "non_existent_id"
        `when`(mockBraze.getFeatureFlag(ffId)).thenReturn(null)

        val arguments = mapOf("id" to ffId)

        // When
        val call = MethodCall("getFeatureFlagByID", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockMethodChannelResult).success(null)
    }

    @Test
    fun whenGetAllFeatureFlags_returnsAllFeatureFlags() {
        // Given
        val mockFeatureFlag1: FeatureFlag = mock()
        val mockFeatureFlag2: FeatureFlag = mock()
        val mockFeatureFlagJson1 = "{\"id\":\"ff1\"}"
        val mockFeatureFlagJson2 = "{\"id\":\"ff2\"}"

        `when`(mockFeatureFlag1.forJsonPut()).thenReturn(JSONObject(mockFeatureFlagJson1))
        `when`(mockFeatureFlag2.forJsonPut()).thenReturn(JSONObject(mockFeatureFlagJson2))
        `when`(mockBraze.getAllFeatureFlags()).thenReturn(
            listOf(
                mockFeatureFlag1,
                mockFeatureFlag2
            )
        )

        val arguments = emptyMap<String, Any>()

        // When
        val call = MethodCall("getAllFeatureFlags", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockMethodChannelResult).success(listOf(mockFeatureFlagJson1, mockFeatureFlagJson2))
    }

    @Test
    fun whenRefreshFeatureFlags_callsRefreshFeatureFlags() {
        // Given
        val arguments = emptyMap<String, Any>()

        // When
        val call = MethodCall("refreshFeatureFlags", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBraze).refreshFeatureFlags()
    }

    @Test
    fun whenLogFeatureFlagImpression_withValidId_logsFeatureFlagImpression() {
        // Given
        val ffId = "test_feature_flag_id"
        val arguments = mapOf("id" to ffId)

        // When
        val call = MethodCall("logFeatureFlagImpression", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockBraze).logFeatureFlagImpression(ffId)
    }

    @Test
    fun whenLogFeatureFlagImpression_withNullId_returnsEarly() {
        // Given
        val arguments = mapOf<String, String?>("id" to null)

        // When
        val call = MethodCall("logFeatureFlagImpression", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verifyNoInteractions(mockMethodChannelResult)
    }

    @Test
    fun whenUnknownMethodCalled_returnsNotImplemented() {
        // Given
        val arguments = emptyMap<String, Any>()

        // When
        val call = MethodCall("unknownMethod", arguments)
        brazePlugin.onMethodCall(call, mockMethodChannelResult)

        // Then
        verify(mockMethodChannelResult).notImplemented()
    }

    /**
     * Helper method to setup Braze user callback
     */
    private fun setupBrazeUserCallback(mockBraze: Braze, mockBrazeUser: BrazeUser) {
        `when`(mockBraze.getCurrentUser(any()))
            .thenAnswer { invocation ->
                val callback = invocation.getArgument<SimpleValueCallback<BrazeUser>>(0)
                callback.onSuccess(mockBrazeUser)
            }
    }
}
