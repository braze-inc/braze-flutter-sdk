package com.braze.brazeplugin

import android.content.Context
import com.braze.configuration.CachedConfigurationProvider
import com.braze.ui.inappmessage.InAppMessageOperation

class FlutterCachedConfiguration(context: Context, useCache: Boolean) : CachedConfigurationProvider(context, useCache) {
    companion object {
        private const val ENABLE_AUTOMATIC_INTEGRATION_INITIALIZER = "com_braze_flutter_enable_automatic_integration_initializer"
        private const val AUTOMATIC_INTEGRATION_IAM_OPERATION = "com_braze_flutter_automatic_integration_iam_operation"
        private val IAM_OPERATION_ENUM_MAP = InAppMessageOperation.values().associateBy { it.name }
    }

    fun isAutomaticInitializationEnabled(): Boolean = getBooleanValue(ENABLE_AUTOMATIC_INTEGRATION_INITIALIZER, true)

    fun automaticIntegrationInAppMessageOperation(): InAppMessageOperation {
        val value = getStringValue(AUTOMATIC_INTEGRATION_IAM_OPERATION, "")?.uppercase()
        return IAM_OPERATION_ENUM_MAP[value] ?: InAppMessageOperation.DISPLAY_NOW
    }
}
