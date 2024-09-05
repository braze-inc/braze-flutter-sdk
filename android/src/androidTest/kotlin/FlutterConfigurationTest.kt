import android.content.Context
import android.content.res.Resources
import com.braze.brazeplugin.FlutterConfiguration
import com.braze.ui.inappmessage.InAppMessageOperation
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.mockito.kotlin.doReturn
import org.mockito.kotlin.mock

class FlutterConfigurationTest {

    @Test
    fun whenBooleanValueExistsInResources_isAutomaticInitializationEnabled_returnsValue() {
        val key = "com_braze_flutter_enable_automatic_integration_initializer"
        val testResId = 1234
        val value = false
        val testPackageName = "foo.bar.braze"
        val mockResources = mock<Resources>() {
            on { getIdentifier(key, "bool", testPackageName) } doReturn 1234
            on { getBoolean(testResId) } doReturn value
        }

        val context: Context = mock<Context>() {
            on { resources } doReturn mockResources
            on { packageName } doReturn testPackageName
        }
        val flutterConfiguration = FlutterConfiguration(context)
        assertEquals(
            value,
            flutterConfiguration.isAutomaticInitializationEnabled()
        )
    }

    @Test
    fun whenBooleanValueDoesNotExistInResources_isAutomaticInitializationEnabled_returnsTrue() {
        val key = "com_braze_flutter_enable_automatic_integration_initializer"
        val testPackageName = "foo.bar.braze"
        val mockResources = mock<Resources>() {
            on { getIdentifier(key, "bool", testPackageName) } doReturn 0
        }

        val context: Context = mock<Context>() {
            on { resources } doReturn mockResources
            on { packageName } doReturn testPackageName
        }
        val flutterConfiguration = FlutterConfiguration(context)
        assertTrue(
            flutterConfiguration.isAutomaticInitializationEnabled()
        )
    }

    @Test
    fun whenStringValueExistsInResources_automaticIntegrationInAppMessageOperation_returnsValue() {
        val key = "com_braze_flutter_automatic_integration_iam_operation"
        val testResId = 1234
        val value = "DISCARD"
        val testPackageName = "foo.bar.braze"
        val mockResources = mock<Resources>() {
            on { getIdentifier(key, "string", testPackageName) } doReturn 1234
            on { getString(testResId) } doReturn value
        }

        val context: Context = mock<Context>() {
            on { resources } doReturn mockResources
            on { packageName } doReturn testPackageName
        }
        val flutterConfiguration = FlutterConfiguration(context)
        assertEquals(
            InAppMessageOperation.DISCARD,
            flutterConfiguration.automaticIntegrationInAppMessageOperation()
        )
    }

    @Test
    fun whenStringValueDoesNotExistInResources_automaticIntegrationInAppMessageOperation_returnsDisplayNow() {
        val key = "com_braze_flutter_automatic_integration_iam_operation"
        val testPackageName = "foo.bar.braze"
        val mockResources = mock<Resources>() {
            on { getIdentifier(key, "string", testPackageName) } doReturn 1234
        }

        val context: Context = mock<Context>() {
            on { resources } doReturn mockResources
            on { packageName } doReturn testPackageName
        }
        val flutterConfiguration = FlutterConfiguration(context)
        assertEquals(
            InAppMessageOperation.DISPLAY_NOW,
            flutterConfiguration.automaticIntegrationInAppMessageOperation()
        )
    }

    @Test
    fun whenStringValueIsGarbage_automaticIntegrationInAppMessageOperation_returnsDisplayNow() {
        val key = "com_braze_flutter_automatic_integration_iam_operation"
        val testResId = 1234
        val value = "yeet_it"
        val testPackageName = "foo.bar.braze"
        val mockResources = mock<Resources>() {
            on { getIdentifier(key, "string", testPackageName) } doReturn 1234
            on { getString(testResId) } doReturn value
        }

        val context: Context = mock<Context>() {
            on { resources } doReturn mockResources
            on { packageName } doReturn testPackageName
        }
        val flutterConfiguration = FlutterConfiguration(context)
        assertEquals(
            InAppMessageOperation.DISPLAY_NOW,
            flutterConfiguration.automaticIntegrationInAppMessageOperation()
        )
    }

    @Test
    fun whenStringValueIsMixedCaseInResources_automaticIntegrationInAppMessageOperation_returnsValue() {
        val key = "com_braze_flutter_automatic_integration_iam_operation"
        val testResId = 1234
        val value = "DiSpLay_LaTeR"
        val testPackageName = "foo.bar.braze"
        val mockResources = mock<Resources>() {
            on { getIdentifier(key, "string", testPackageName) } doReturn 1234
            on { getString(testResId) } doReturn value
        }

        val context: Context = mock<Context>() {
            on { resources } doReturn mockResources
            on { packageName } doReturn testPackageName
        }
        val flutterConfiguration = FlutterConfiguration(context)
        assertEquals(
            InAppMessageOperation.DISPLAY_LATER,
            flutterConfiguration.automaticIntegrationInAppMessageOperation()
        )
    }
}
