package com.reclaim.app

import android.app.Activity
import android.content.Intent
import android.os.Bundle

/**
 * InterventionActivity — launched by AccessibilityService when a blocked
 * site is detected. Delegates UI to Flutter's /intervention route.
 */
class InterventionActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Launch Flutter app at the intervention route
        val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            putExtra("route", "/intervention")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        intent?.let { startActivity(it) }
        finish()
    }
}
