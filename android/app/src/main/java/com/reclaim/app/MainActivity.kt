package com.reclaim.app

import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val VPN_CHANNEL = "com.reclaim.app/vpn"
    private val ADMIN_CHANNEL = "com.reclaim.app/admin"
    private val PROTECTION_CHANNEL = "com.reclaim.app/protection"
    private val VPN_REQUEST_CODE = 100
    private val ADMIN_REQUEST_CODE = 101

    private var adminResult: MethodChannel.Result? = null
    private var vpnResult: MethodChannel.Result? = null

    companion object {
        const val TAG = "ReclaimMain"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }
    
    override fun onResume() {
        super.onResume()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // VPN Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startVpn" -> requestVpnPermission(result)
                "stopVpn" -> {
                    val intent = Intent(this, ReclaimVpnService::class.java).apply {
                        action = ReclaimVpnService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(true)
                }
                "isVpnRunning" -> result.success(ReclaimVpnService.isRunning)
                else -> result.notImplemented()
            }
        }

        // Admin Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ADMIN_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAdminActive" -> result.success(isAdminActive())
                "requestAdmin" -> {
                    adminResult = result
                    requestAdminPrivileges()
                }
                "lockApp" -> {
                    lockAppFromUninstall()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Protection Channel (NEW — blocklist sync, accessibility check)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PROTECTION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "syncBlocklist" -> {
                    try {
                        @Suppress("UNCHECKED_CAST")
                        val sites = call.argument<List<String>>("sites") ?: emptyList()
                        val prefs = getSharedPreferences("reclaim_blocklist", MODE_PRIVATE)
                        val domainSet = sites.map { it.lowercase().trim() }.toSet()
                        prefs.edit().putStringSet("blocked_domains", domainSet).apply()
                        Log.d(TAG, "Synced ${domainSet.size} domains to native SharedPreferences")
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error syncing blocklist", e)
                        result.success(false)
                    }
                }
                "syncDnsList" -> {
                    try {
                        @Suppress("UNCHECKED_CAST")
                        val dns = call.argument<List<String>>("dns") ?: emptyList()
                        val prefs = getSharedPreferences("reclaim_blocklist", MODE_PRIVATE)
                        prefs.edit().putStringSet("custom_dns", dns.toSet()).apply()
                        Log.d(TAG, "Synced ${dns.size} DNS servers to native SharedPreferences")
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error syncing DNS list", e)
                        result.success(false)
                    }
                }
                "isAccessibilityEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "openAccessibilitySettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error opening accessibility settings", e)
                        result.success(false)
                    }
                }
                "openPrivateDnsSettings" -> {
                    try {
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            Intent("android.settings.PRIVATE_DNS_SETTINGS").apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                        } else {
                            Intent(Settings.ACTION_WIRELESS_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        // Fallback to general settings
                        try {
                            val intent = Intent(Settings.ACTION_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.success(false)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Check if our accessibility service is enabled.
     */
    private fun isAccessibilityServiceEnabled(): Boolean {
        try {
            val serviceId = "$packageName/${ReclaimAccessibilityService::class.java.canonicalName}"
            val serviceIdShort = "$packageName/.ReclaimAccessibilityService"

            val enabledServices = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            ) ?: return false

            val colonSplitter = TextUtils.SimpleStringSplitter(':')
            colonSplitter.setString(enabledServices)

            while (colonSplitter.hasNext()) {
                val service = colonSplitter.next()
                if (service.equals(serviceId, ignoreCase = true) ||
                    service.equals(serviceIdShort, ignoreCase = true)
                ) {
                    return true
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking accessibility service", e)
        }
        return false
    }

    private fun requestVpnPermission(result: MethodChannel.Result) {
        val intent = VpnService.prepare(this)
        if (intent == null) {
            // Permission already granted — start VPN
            startVpnService()
            result.success(true)
        } else {
            vpnResult = result
            startActivityForResult(intent, VPN_REQUEST_CODE)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        when (requestCode) {
            VPN_REQUEST_CODE -> {
                if (resultCode == Activity.RESULT_OK) {
                    startVpnService()
                    vpnResult?.success(true)
                } else {
                    vpnResult?.success(false)
                }
                vpnResult = null
            }
            ADMIN_REQUEST_CODE -> {
                val isActive = resultCode == Activity.RESULT_OK
                adminResult?.success(isActive)
                adminResult = null

                // If admin was just activated, also try to start VPN
                if (isActive && !ReclaimVpnService.isRunning) {
                    val vpnIntent = VpnService.prepare(this)
                    if (vpnIntent == null) {
                        startVpnService()
                    }
                }
            }
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun startVpnService() {
        Log.d(TAG, "Starting VPN service...")
        val intent = Intent(this, ReclaimVpnService::class.java).apply {
            action = ReclaimVpnService.ACTION_START
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun isAdminActive(): Boolean {
        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponent = ComponentName(this, ReclaimDeviceAdminReceiver::class.java)
        return dpm.isAdminActive(adminComponent)
    }

    private fun requestAdminPrivileges() {
        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponent = ComponentName(this, ReclaimDeviceAdminReceiver::class.java)

        if (!dpm.isAdminActive(adminComponent)) {
            val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
                putExtra(
                    DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                    "🛡️ Reclaim Protection\n\n" +
                    "Device Administrator privileges are required to:\n\n" +
                    "✓ Prevent accidental uninstallation\n" +
                    "✓ Block app from being disabled\n" +
                    "✓ Protect your commitment\n" +
                    "✓ Ensure continuous protection\n\n" +
                    "Your data stays private on your device."
                )
            }
            startActivityForResult(intent, ADMIN_REQUEST_CODE)
        } else {
            adminResult?.success(true)
            adminResult = null
        }
    }

    private fun lockAppFromUninstall() {
        try {
            val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val adminComponent = ComponentName(this, ReclaimDeviceAdminReceiver::class.java)

            if (dpm.isAdminActive(adminComponent)) {
                dpm.setUninstallBlocked(adminComponent, packageName, true)
                dpm.setApplicationHidden(adminComponent, packageName, false)
            }
        } catch (e: Exception) {
            // Some features require device owner — silently ignore
            Log.d(TAG, "lockApp: some features not available (not device owner)")
        }
    }
}
