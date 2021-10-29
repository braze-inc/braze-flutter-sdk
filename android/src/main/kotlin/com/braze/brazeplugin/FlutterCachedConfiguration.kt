package com.braze.brazeplugin

import android.content.Context
import com.braze.configuration.CachedConfigurationProvider

class FlutterCachedConfiguration(context: Context, useCache: Boolean) : CachedConfigurationProvider(context, useCache) {
    companion object {
        private const val ENABLE_AUTOMATIC_INTEGRATION_INITIALIZER = "com_braze_flutter_enable_automatic_integration_initializer"
    }

    fun isAutomaticInitializationEnabled(): Boolean {
        return getBooleanValue(ENABLE_AUTOMATIC_INTEGRATION_INITIALIZER, true)
    }
}
