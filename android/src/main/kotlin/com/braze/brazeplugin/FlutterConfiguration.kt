package com.braze.brazeplugin

import android.annotation.SuppressLint
import android.content.Context
import com.braze.ui.inappmessage.InAppMessageOperation

class FlutterConfiguration(private val context: Context) {
    @SuppressLint("DiscouragedApi")
    fun isAutomaticInitializationEnabled(): Boolean {
        val isEnabledDefaultValue = true
        val resId = context.resources.getIdentifier(ENABLE_AUTOMATIC_INTEGRATION_INITIALIZER, "bool", context.packageName)
        if (resId == MISSING_RESOURCE_IDENTIFIER) {
            return isEnabledDefaultValue
        }

        return try {
            context.resources.getBoolean(resId)
        } catch (_: Exception) {
            isEnabledDefaultValue
        }
    }

    @SuppressLint("DiscouragedApi")
    fun automaticIntegrationInAppMessageOperation(): InAppMessageOperation {
        val defaultValue = InAppMessageOperation.DISPLAY_NOW
        val resId = context.resources.getIdentifier(AUTOMATIC_INTEGRATION_IAM_OPERATION, "string", context.packageName)
        if (resId == MISSING_RESOURCE_IDENTIFIER) {
            return defaultValue
        }

        return try {
            val value = context.resources.getString(resId).uppercase()
            IAM_OPERATION_ENUM_MAP[value] ?: defaultValue
        } catch (_: Exception) {
            defaultValue
        }
    }

    companion object {
        private const val ENABLE_AUTOMATIC_INTEGRATION_INITIALIZER =
            "com_braze_flutter_enable_automatic_integration_initializer"
        private const val AUTOMATIC_INTEGRATION_IAM_OPERATION = "com_braze_flutter_automatic_integration_iam_operation"
        private val IAM_OPERATION_ENUM_MAP = InAppMessageOperation.values().associateBy { it.name }
        private const val MISSING_RESOURCE_IDENTIFIER = 0
    }
}
