package com.reclaim.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * BootReceiver — DISABLED VPN auto-start.
 * VPN was causing internet breakage.
 * Now using Accessibility Service for blocking instead.
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        const val TAG = "ReclaimBoot"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "Device boot detected")

            // VPN DISABLED - No longer auto-starting VPN
            // Protection is now handled by Accessibility Service
            // which doesn't break internet connectivity

            // Old code (disabled):
            // val vpnIntent = Intent(context, ReclaimVpnService::class.java).apply {
            //     action = ReclaimVpnService.ACTION_START
            // }
            // context.startForegroundService(vpnIntent)

            Log.d(TAG, "VPN disabled - using Accessibility Service for protection")
        }
    }
}
