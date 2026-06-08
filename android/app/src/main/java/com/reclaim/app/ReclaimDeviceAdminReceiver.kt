package com.reclaim.app

import android.app.admin.DeviceAdminReceiver
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.Toast

class ReclaimDeviceAdminReceiver : DeviceAdminReceiver() {

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Toast.makeText(context, "🛡️ Reclaim Protection Enabled", Toast.LENGTH_LONG).show()
        
        // Enable maximum security
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponent = ComponentName(context, ReclaimDeviceAdminReceiver::class.java)
        
        try {
            // Prevent app from being disabled
            dpm.setUninstallBlocked(adminComponent, context.packageName, true)
        } catch (e: Exception) {
            // Some devices may not support this
        }
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        // Show warning when user tries to disable admin
        return "⚠️ WARNING: Disabling Reclaim Protection will remove all website blocks and allow access to harmful content. Are you sure you want to break your commitment?"
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Toast.makeText(context, "⚠️ Reclaim Protection Disabled - You are now vulnerable", Toast.LENGTH_LONG).show()
    }

    companion object {
        fun isAdminActive(context: Context): Boolean {
            val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val adminComponent = ComponentName(context, ReclaimDeviceAdminReceiver::class.java)
            return dpm.isAdminActive(adminComponent)
        }

        fun requestAdminPrivileges(context: Context) {
            val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val adminComponent = ComponentName(context, ReclaimDeviceAdminReceiver::class.java)
            
            if (!dpm.isAdminActive(adminComponent)) {
                val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                    putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
                    putExtra(
                        DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                        "Reclaim needs Device Administrator privileges to:\n\n" +
                        "• Prevent accidental uninstallation\n" +
                        "• Protect your commitment to self-control\n" +
                        "• Ensure continuous website blocking\n" +
                        "• Maintain your progress and streak\n\n" +
                        "This helps you stay accountable to your goals."
                    )
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(intent)
            }
        }
    }
}
