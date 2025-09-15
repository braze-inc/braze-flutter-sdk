package com.braze.brazeplugin

import android.app.Activity
import android.os.Bundle

class TestActivityForJunitRunner : Activity() {
    public override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // We purposely don't set the content view since neither test nor human looks at the content.
        // This is a performance measure since inflating views takes time.
        // setContentView(R.layout.main);

        // Explicitly setting the dexmaker cache to support KitKat.
        System.setProperty("dexmaker.dexcache", cacheDir.toString())
    }
}
