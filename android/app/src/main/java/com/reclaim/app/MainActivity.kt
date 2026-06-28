package com.reclaim.app

import android.app.Activity
import android.app.AppOpsManager
import android.app.admin.DevicePolicyManager
import android.app.usage.UsageStatsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {

    private val ADMIN_CHANNEL = "com.reclaim.app/admin"
    private val PROTECTION_CHANNEL = "com.reclaim.app/protection"
    private val USAGE_CHANNEL = "com.reclaim.app/usage"
    private val ADMIN_REQUEST_CODE = 101

    private var adminResult: MethodChannel.Result? = null

    companion object {
        const val TAG = "ReclaimMain"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        MotivationReceiver.scheduleMotivationAlarms(this)
    }
    
    override fun onResume() {
        super.onResume()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
                "syncBlockedPackages" -> {
                    try {
                        @Suppress("UNCHECKED_CAST")
                        val packages = call.argument<List<String>>("packages") ?: emptyList()
                        val prefs = getSharedPreferences("reclaim_blocklist", MODE_PRIVATE)
                        val packageSet = packages.map { it.lowercase().trim() }.toSet()
                        prefs.edit().putStringSet("blocked_packages", packageSet).apply()
                        Log.d(TAG, "Synced ${packageSet.size} blocked packages to native SharedPreferences")
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error syncing blocked packages", e)
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
                "getInstalledApps" -> {
                    try {
                        val pm = packageManager
                        // Query launcher intents to find user launchable apps
                        val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
                            addCategory(Intent.CATEGORY_LAUNCHER)
                        }
                        val resolvedInfos = pm.queryIntentActivities(mainIntent, 0)
                        val appsList = mutableListOf<Map<String, String>>()
                        val addedPackages = mutableSetOf<String>()

                        for (info in resolvedInfos) {
                            val pkgName = info.activityInfo.packageName
                            if (pkgName == packageName) continue // Skip Reclaim
                            if (addedPackages.add(pkgName)) {
                                val appLabel = info.loadLabel(pm).toString()
                                appsList.add(mapOf(
                                    "packageName" to pkgName,
                                    "appName" to appLabel
                                ))
                            }
                        }
                        // Sort by appName case insensitively
                        appsList.sortBy { it["appName"]?.lowercase() }
                        result.success(appsList)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error fetching installed apps", e)
                        result.success(emptyList<Map<String, String>>())
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

        // Usage Stats Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USAGE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkUsagePermission" -> {
                    val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
                    val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
                    } else {
                        @Suppress("DEPRECATION")
                        appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
                    }
                    result.success(mode == AppOpsManager.MODE_ALLOWED)
                }
                "requestUsagePermission" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        })
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "getDailyUsage" -> {
                    val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                    
                    // Strictly calculate today 00:00:00
                    val calendar = Calendar.getInstance()
                    calendar.set(Calendar.HOUR_OF_DAY, 0)
                    calendar.set(Calendar.MINUTE, 0)
                    calendar.set(Calendar.SECOND, 0)
                    calendar.set(Calendar.MILLISECOND, 0)
                    
                    val start = calendar.timeInMillis
                    val end = System.currentTimeMillis()

                    // queryUsageStats is more accurate than queryAndAggregateUsageStats for "today only"
                    val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, start, end)
                    val resultMap = mutableMapOf<String, Long>()
                    
                    // Filter out noise and system apps
                    val systemPackages = listOf("com.android.launcher", "com.android.systemui", "com.reclaim.app", "android")

                    for (stat in stats) {
                        val pkg = stat.packageName
                        if (stat.totalTimeInForeground > 0 && 
                            !systemPackages.any { pkg.startsWith(it) } &&
                            stat.lastTimeUsed >= start) {
                            
                            // Because queryUsageStats can return multiple entries for different time slices, 
                            // we always take the maximum or the latest total for that interval.
                            val existing = resultMap[pkg] ?: 0L
                            if (stat.totalTimeInForeground > existing) {
                                resultMap[pkg] = stat.totalTimeInForeground
                            }
                        }
                    }
                    result.success(resultMap)
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

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        when (requestCode) {
            ADMIN_REQUEST_CODE -> {
                val isActive = resultCode == Activity.RESULT_OK
                adminResult?.success(isActive)
                adminResult = null
            }
        }
        super.onActivityResult(requestCode, resultCode, data)
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
