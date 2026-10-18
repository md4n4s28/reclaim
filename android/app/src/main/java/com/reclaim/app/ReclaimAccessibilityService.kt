package com.reclaim.app

import android.accessibilityservice.AccessibilityService
import android.app.ActivityManager
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.content.Context
import android.content.ComponentName
import android.app.admin.DevicePolicyManager

/**
 * ReclaimAccessibilityService — monitors browser URL bars for blocked content.
 *
 * When a blocked URL or adult keyword is detected:
 * 1. Shows a full-screen overlay using TYPE_ACCESSIBILITY_OVERLAY
 * 2. The overlay cannot be dismissed with Back button
 * 3. User must tap "Go Back" (which performs GLOBAL_ACTION_BACK) or "Open Reclaim"
 */
class ReclaimAccessibilityService : AccessibilityService() {

    companion object {
        const val TAG = "ReclaimA11y"
        private const val CACHE_REFRESH_MS = 60_000L // Refresh blocklist every 60s
        private const val DEBOUNCE_MS = 3_000L // 3-second debounce
    }

    // Browser package → address bar view IDs
    private val browserAddressBarIds = mapOf(
        "com.android.chrome" to listOf(
            "com.android.chrome:id/url_bar",
            "com.android.chrome:id/omnibox_url_field"
        ),
        "org.mozilla.firefox" to listOf(
            "org.mozilla.firefox:id/mozac_browser_toolbar_url_view",
            "org.mozilla.firefox:id/url_bar_title"
        ),
        "com.brave.browser" to listOf(
            "com.brave.browser:id/url_bar"
        ),
        "com.sec.android.app.sbrowser" to listOf(
            "com.sec.android.app.sbrowser:id/location_bar_edit_text",
            "com.sec.android.app.sbrowser:id/url_bar_text"
        ),
        "com.opera.browser" to listOf(
            "com.opera.browser:id/url_field"
        ),
        "com.microsoft.emmx" to listOf(
            "com.microsoft.emmx:id/url_bar",
            "com.microsoft.emmx:id/url_bar_title"
        ),
        "com.duckduckgo.mobile.android" to listOf(
            "com.duckduckgo.mobile.android:id/omnibarTextInput"
        ),
        "com.opera.mini.native" to listOf(
            "com.opera.mini.native:id/url_field"
        ),
        // Add Snaptube support (Snaptube package is often com.snaptube.premium or com.lotus.videodownloader)
        "com.snaptube.premium" to listOf(
            "com.snaptube.premium:id/url_bar",
            "com.snaptube.premium:id/input_url"
        ),
        "com.lotus.videodownloader" to listOf(
            "com.lotus.videodownloader:id/url_bar",
            "com.lotus.videodownloader:id/input_url"
        )
    )

    private val supportedBrowserPackages = browserAddressBarIds.keys

    // Blocklist (loaded from SharedPrefs + defaults)
    private var blockedDomains = setOf<String>()
    private var blockedPackages = setOf<String>()
    private var lastCacheRefresh = 0L

    // Adult keywords for search/URL blocking - COMPREHENSIVE LIST
    private val adultKeywords = setOf(
        // Core adult content terms
        "porn", "pornography", "xxx", "adult video", "adult film",
        "hentai", "anime sex", "nude", "naked", "nsfw",
        "sex", "sexo", "seks", "seksi", "sesso",
        "sex video", "sex cam", "sex chat", "sex story", "sex site",
        "adult video", "adult content", "adult site",
        "sexvideo", "adultvideo", "adultfilm",

        // Adult sites and services
        "onlyfans", "chaturbate", "stripchat", "livejasmin",
        "brazzers", "bangbros", "pornhub", "xvideos", "xnxx",
        "xhamster", "redtube", "youporn", "spankbang", "beeg",
        "cam4", "myfreecams", "camsoda", "streamate",
        "fleshlight", "dildo", "vibrator", "adult toys",

        // Sexual acts
        "fap", "masturbation", "minx", "milf", "gloryhole",
        "creampie", "gangbang", "orgy", "threesome", "foursome",
        "prostitute", "escort", "hooker", "whore",

        // Beastiality and illegal content
        "bestiality", "zoophilia", "zoosex", "animal sex",
        "child", "underage", "minor", "cp", "teen porn",

        // Webcam and cam sites
        "camgirl", "camboy", "webcam", "live sex", "sexcam",
        "cam chat", "live cam", "webcam girl",

        // Erotic content
        "erotic", "erotica", "literotica", "xxx manga",
        "doujinshi", "rule34", "r34", "hentai manga",

        // Other adult services
        "massage", "happy ending", "happyending", "massage parlor",
        "escort service",

        // Asian adult content (common searches)
        "jav", "japanese porn", "korean porn",
        "thai porn", "indian sex", "desi porn",

        // Incest content
        "incest", "family sex", "mom son", "sister brother",
        "taboo", "forbidden",

        // Other variations
        "boobs", "tits", "naked girl",
        "naked man", "nude photo", "nude video", "nude pic",
        "topless", "playboy", "penthouse", "hustler"
    )


    // Overlay state
    private var overlayView: View? = null
    private var isOverlayShowing = false
    private var lastBlockedTime = 0L
    private val handler = Handler(Looper.getMainLooper())
    private var currentBlockedPackage = ""
    private var blockAttemptCount = 0

    // Prevent cheating
    private val systemSettingsPackages = listOf(
        "com.android.settings",
        "com.android.packageinstaller",
        "com.google.android.packageinstaller",
        "com.samsung.android.packageinstaller",
        "com.samsung.android.settings",
        "com.miui.securitycenter",
        "com.coloros.securitycenter"
    )

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event ?: return
        val pkg = event.packageName?.toString() ?: return

        // 1. FAST PATH: MONITOR SYSTEM SETTINGS FIRST (0ms latency, before any blocklist checks)
        if (pkg.contains("settings") || pkg.contains("packageinstaller") || pkg in systemSettingsPackages) {
            monitorSettingsForCheating(event)
            return
        }

        // Always check and refresh blocklist/package lists from SharedPreferences
        refreshBlocklistIfNeeded()

        // Check package level app blocker first
        if (blockedPackages.contains(pkg)) {
            Log.e(TAG, "🛑 APP BLOCKED: $pkg")
            showBlockingOverlay()
            performGlobalAction(GLOBAL_ACTION_HOME)
            return
        }

        if (pkg !in supportedBrowserPackages) return

        // 2. Check URL bar for blocked domains or keywords in search URL
        val url = extractUrl(event, pkg) ?: ""
        if (url.isNotBlank() && isBlocked(url)) {
            triggerBlocking(pkg, "URL: $url")
            return
        }

        // 3. Scan entire screen ONLY if on a search engine to prevent false positives on news/github
        val rootNode = rootInActiveWindow ?: event.source
        if (rootNode != null && isSearchEngineUrl(url)) {
            if (scanNodeForCriticalKeywords(rootNode)) {
                triggerBlocking(pkg, "Screen Keyword detected")
            }
        }
    }

    private fun isSearchEngineUrl(url: String): Boolean {
        val lower = url.lowercase()
        return lower.contains("google.com/search") || 
               lower.contains("duckduckgo.com") || 
               lower.contains("bing.com/search") ||
               lower.contains("search.yahoo.com")
    }

    // Anti-cheat overlay state
    private var antiCheatOverlayView: View? = null

    /**
     * Prevent user from disabling Private DNS, Accessibility service, or Device Admin for Reclaim.
     * Surgically targets ONLY Reclaim settings sub-pages (NOT the main Accessibility list or other apps).
     */
    private fun monitorSettingsForCheating(event: AccessibilityEvent) {
        val rootNode = rootInActiveWindow ?: event.source ?: return

        if (containsReclaimCheatAttempt(rootNode)) {
            Log.e(TAG, "🛡️ RECLAIM CHEAT ATTEMPT DETECTED in Settings - INSTANT RESET")

            // 1. IMMEDIATELY send HOME and BACK commands (executes in <1ms)
            performGlobalAction(GLOBAL_ACTION_HOME)
            performGlobalAction(GLOBAL_ACTION_BACK)

            // 2. Kill Settings background process to clear sub-page backstack in Recents
            try {
                val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                val pkg = event.packageName?.toString() ?: "com.android.settings"
                am.killBackgroundProcesses(pkg)
                am.killBackgroundProcesses("com.android.settings")
                am.killBackgroundProcesses("com.samsung.android.settings")
                am.killBackgroundProcesses("com.miui.securitycenter")
                am.killBackgroundProcesses("com.coloros.securitycenter")
            } catch (e: Exception) {
                Log.e(TAG, "Error killing settings process", e)
            }

            // 3. Show instant touch-blocking anti-cheat overlay over Settings
            showAntiCheatOverlay()

            // 4. Re-open Reclaim
            try {
                val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                }
                intent?.let { startActivity(it) }
            } catch (e: Exception) {
                Log.e(TAG, "Error launching Reclaim app", e)
            }
        }
    }

    private fun containsReclaimCheatAttempt(rootNode: AccessibilityNodeInfo?): Boolean {
        rootNode ?: return false
        try {
            val sb = StringBuilder()
            collectNodeTexts(rootNode, sb)
            val windowText = sb.toString().lowercase()

            // 1. MUST specifically target Reclaim
            val mentionsReclaim = windowText.contains("reclaim") || windowText.contains("com.reclaim.app")
            if (!mentionsReclaim) return false

            // 2. Check if we are on the MAIN Accessibility Menu list (contains other services)
            val isMainAccessibilityList = windowText.contains("talkback") ||
                                         windowText.contains("select to speak") ||
                                         windowText.contains("switch access") ||
                                         windowText.contains("accessibility menu") ||
                                         windowText.contains("installed services") ||
                                         windowText.contains("downloaded apps") ||
                                         windowText.contains("downloaded services") ||
                                         windowText.contains("interaction controls") ||
                                         windowText.contains("text-to-speech")

            // DO NOT block the Main Accessibility list (allows user to manage other apps' accessibility!)
            if (isMainAccessibilityList) {
                return false
            }

            val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val adminComponent = ComponentName(applicationContext, ReclaimDeviceAdminReceiver::class.java)
            val isAdminActive = dpm.isAdminActive(adminComponent)

            // Allow initial activation of device admin when NOT yet active
            val isInitialAdminActivation = !isAdminActive &&
                (windowText.contains("activate this device admin") || windowText.contains("activate this device app")) &&
                !windowText.contains("deactivate") && !windowText.contains("uninstall") && !windowText.contains("remove")

            if (isInitialAdminActivation) {
                return false
            }

            // 3. Detect Reclaim's SPECIFIC Accessibility detail sub-page:
            val isAccessibilitySubPage = windowText.contains("use reclaim") ||
                                         windowText.contains("stop reclaim") ||
                                         windowText.contains("turn off reclaim") ||
                                         windowText.contains("reclaim shortcut") ||
                                         windowText.contains("allow reclaim") ||
                                         (windowText.contains("reclaim protection service") && (windowText.contains("use") || windowText.contains("shortcut") || windowText.contains("stop")))

            // 4. Detect Reclaim's App Info page:
            val isAppInfoPage = windowText.contains("uninstall") ||
                                windowText.contains("force stop") ||
                                (windowText.contains("app info") && windowText.contains("reclaim")) ||
                                (windowText.contains("app details") && windowText.contains("reclaim"))

            // 5. Detect Device Admin deactivation page:
            val isDeviceAdminPage = windowText.contains("deactivate this device admin") ||
                                    windowText.contains("deactivate device admin") ||
                                    windowText.contains("remove device admin")

            // 6. Detect Search in Settings specifically for Reclaim:
            val isSearchForReclaim = windowText.contains("search") && windowText.contains("reclaim")

            return isAccessibilitySubPage || isAppInfoPage || isDeviceAdminPage || isSearchForReclaim
        } catch (_: Exception) {}
        return false
    }

    private fun collectNodeTexts(node: AccessibilityNodeInfo?, sb: StringBuilder) {
        node ?: return
        try {
            val text = node.text?.toString()
            if (!text.isNullOrBlank()) {
                sb.append(text).append(" ")
            }
            val desc = node.contentDescription?.toString()
            if (!desc.isNullOrBlank()) {
                sb.append(desc).append(" ")
            }
            for (i in 0 until node.childCount) {
                collectNodeTexts(node.getChild(i), sb)
            }
        } catch (_: Exception) {}
    }

    private fun showAntiCheatOverlay() {
        handler.post {
            try {
                if (antiCheatOverlayView != null) return@post
                val wm = getSystemService(WINDOW_SERVICE) as WindowManager

                val layout = LinearLayout(this).apply {
                    orientation = LinearLayout.VERTICAL
                    gravity = Gravity.CENTER
                    setBackgroundColor(Color.parseColor("#EE0B0F19"))
                    isClickable = true
                    isFocusable = true
                    setPadding(dpToPx(32), dpToPx(32), dpToPx(32), dpToPx(32))

                    val iconView = ImageView(this@ReclaimAccessibilityService).apply {
                        setImageResource(android.R.drawable.ic_dialog_alert)
                        setColorFilter(Color.parseColor("#EF4444"))
                        layoutParams = LinearLayout.LayoutParams(dpToPx(72), dpToPx(72)).apply {
                            bottomMargin = dpToPx(20)
                        }
                    }
                    addView(iconView)

                    val titleView = TextView(this@ReclaimAccessibilityService).apply {
                        text = "🛡️ Reclaim Security Lockout"
                        setTextColor(Color.WHITE)
                        textSize = 22f
                        typeface = Typeface.DEFAULT_BOLD
                        gravity = Gravity.CENTER
                    }
                    addView(titleView)

                    val subtitleView = TextView(this@ReclaimAccessibilityService).apply {
                        text = "Access to Reclaim protection settings is locked to preserve your commitment."
                        setTextColor(Color.parseColor("#9CA3AF"))
                        textSize = 14f
                        gravity = Gravity.CENTER
                        layoutParams = LinearLayout.LayoutParams(
                            LinearLayout.LayoutParams.MATCH_PARENT,
                            LinearLayout.LayoutParams.WRAP_CONTENT
                        ).apply { topMargin = dpToPx(12) }
                    }
                    addView(subtitleView)
                }

                val params = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                            WindowManager.LayoutParams.FLAG_FULLSCREEN,
                    PixelFormat.TRANSLUCENT
                )
                params.gravity = Gravity.CENTER

                wm.addView(layout, params)
                antiCheatOverlayView = layout

                handler.postDelayed({
                    removeAntiCheatOverlay()
                }, 1800L)
            } catch (e: Exception) {
                Log.e(TAG, "Error showing anti-cheat overlay", e)
            }
        }
    }

    private fun removeAntiCheatOverlay() {
        handler.post {
            try {
                if (antiCheatOverlayView != null) {
                    val wm = getSystemService(WINDOW_SERVICE) as WindowManager
                    wm.removeView(antiCheatOverlayView)
                    antiCheatOverlayView = null
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error removing anti-cheat overlay", e)
            }
        }
    }

    private fun dpToPx(dp: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP, dp.toFloat(), resources.displayMetrics
        ).toInt()
    }

    private fun triggerBlocking(pkg: String, reason: String) {
        Log.e(TAG, "🚨 BLOCKED CONTENT: $reason")
        currentBlockedPackage = pkg
        
        // 1. Immediately redirect the browser to a motivational blog
        try {
            val intent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse("https://easypeasymethod.org/"))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            
            // FORCE the intent to open in the specific browser the user is currently using
            // so they don't get kicked out to a different default browser (e.g. from Brave to Chrome).
            intent.setPackage(pkg)
            
            try {
                startActivity(intent)
            } catch (ex: android.content.ActivityNotFoundException) {
                // Fallback: If for some reason the specific package can't handle it,
                // try without specifying the package to let the system default handle it.
                intent.setPackage(null)
                startActivity(intent)
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error redirecting to blog", e)
        }
        
        // 2. We skip forcing the home screen so they can read the blog, 
        // but we still clear recent apps internally so they can't easily go back to the porn tab.
        // We will also skip the overlay here because the redirect is the primary intervention.
        // This solves the "stuck" overlay issue while forcing them to read the blog.
    }

    private fun scanNodeForCriticalKeywords(node: AccessibilityNodeInfo?): Boolean {
        node ?: return false
        try {
            val text = node.text?.toString()
            val contentDesc = node.contentDescription?.toString()
            
            val combinedText = "${text ?: ""} ${contentDesc ?: ""}".lowercase()
            
            if (combinedText.isNotBlank()) {
                // High-confidence keywords that almost always indicate porn
                val severeKeywords = listOf(
                    "pornhub", "xvideos", "xnxx", "xhamster", "brazzers", 
                    "bangbros", "porn video", "sex video", "adult video", 
                    "free porn", "hentai video", "xxx video"
                )
                
                if (severeKeywords.any { combinedText.contains(it) }) {
                    return true
                }
            }

            for (i in 0 until node.childCount) {
                if (scanNodeForCriticalKeywords(node.getChild(i))) return true
            }
        } catch (_: Exception) {}
        return false
    }

    private fun refreshBlocklistIfNeeded() {
        val now = System.currentTimeMillis()
        // Always reload packages from prefs to get immediate sync when updated in UI,
        // and reload domains according to cache refresh interval.
        try {
            val prefs = getSharedPreferences("reclaim_blocklist", MODE_PRIVATE)
            blockedPackages = prefs.getStringSet("blocked_packages", emptySet()) ?: emptySet()
        } catch (_: Exception) {}

        if (now - lastCacheRefresh > CACHE_REFRESH_MS || blockedDomains.isEmpty()) {
            loadBlocklist()
            lastCacheRefresh = now
        }
    }

    private fun loadBlocklist() {
        try {
            val prefs = getSharedPreferences("reclaim_blocklist", MODE_PRIVATE)
            val domains = prefs.getStringSet("blocked_domains", emptySet()) ?: emptySet()
            blockedDomains = domains + DEFAULT_DOMAINS
            blockedPackages = prefs.getStringSet("blocked_packages", emptySet()) ?: emptySet()
            Log.d(TAG, "Loaded ${blockedDomains.size} blocked domains and ${blockedPackages.size} blocked packages")
        } catch (e: Exception) {
            Log.e(TAG, "Error loading blocklist", e)
            blockedDomains = DEFAULT_DOMAINS
            blockedPackages = emptySet()
        }
    }

    /**
     * Extract URL text from browser address bar.
     * Tries known view IDs first, then falls back to recursive text search.
     */
    private fun extractUrl(event: AccessibilityEvent, packageName: String): String? {
        val rootNode = rootInActiveWindow ?: event.source ?: return null

        // Try known address bar IDs for this browser
        val viewIds = browserAddressBarIds[packageName] ?: emptyList()
        for (viewId in viewIds) {
            try {
                val nodes = rootNode.findAccessibilityNodeInfosByViewId(viewId)
                if (nodes.isNotEmpty()) {
                    val text = nodes[0].text?.toString()
                    if (!text.isNullOrBlank()) return text
                }
            } catch (_: Exception) {}
        }

        // Fallback: try to find any EditText or search-related node
        return findUrlInNodeTree(rootNode)
    }

    /**
     * Recursively search the accessibility node tree for URL-like text.
     */
    private fun findUrlInNodeTree(node: AccessibilityNodeInfo?): String? {
        node ?: return null
        try {
            val text = node.text?.toString()
            if (!text.isNullOrBlank()) {
                val lower = text.lowercase()
                // Only pick up text that looks like a URL or search query to avoid false positives
                if (lower.contains(".com") || lower.contains(".org") ||
                    lower.contains(".net") || lower.contains("www.") || 
                    lower.contains("http") || lower.contains("search?") ||
                    lower.contains("query=") || lower.contains("?q=") ||
                    lower.contains("google.com/search")
                ) {
                    return text
                }
            }

            for (i in 0 until node.childCount) {
                val child = node.getChild(i)
                val result = findUrlInNodeTree(child)
                if (result != null) return result
            }
        } catch (_: Exception) {}
        return null
    }

    /**
     * Check if a URL or text should be blocked.
     * Refined to prevent false positives like 'nanni pari college'.
     */
    private fun isBlocked(url: String): Boolean {
        val lower = url.lowercase().trim()

        // 1. Check search queries with adult keywords
        val searchPatterns = listOf(
            Regex("search[?&].*q=([^&]*)"),
            Regex("[?&]q=([^&]*)"),
            Regex("search[?&]p=([^&]*)"),
            Regex("query=([^&]*)"),
            Regex("keyword=([^&]*)")
        )

        for (pattern in searchPatterns) {
            val match = pattern.find(lower)
            if (match != null) {
                try {
                    val searchTerm = java.net.URLDecoder.decode(match.groupValues.getOrNull(1) ?: "", "UTF-8")
                    // Exact/boundary keyword matching to avoid matching substrings like "sex" in "unisex" or "college" in adult college queries
                    val searchWords = searchTerm.lowercase().split(Regex("\\s+"))
                    if (searchWords.any { word -> adultKeywords.contains(word) }) {
                        Log.e(TAG, "🚨 ADULT SEARCH DETECTED: $searchTerm")
                        return true
                    }
                } catch (_: Exception) {}
            }
        }

        // 2. Clean URL for domain matching
        val domain = lower
            .removePrefix("https://")
            .removePrefix("http://")
            .removePrefix("www.")
            .split("/")[0]
            .split("?")[0]
            .split(":")[0]

        // 3. Wildcard matching for xhamster and other major porn brands
        val brandWildcards = listOf("xhamster", "pornhub", "xnxx", "xvideos", "redtube", "youporn", "spankbang")
        if (brandWildcards.any { domain.contains(it) }) {
            Log.e(TAG, "🚨 BRAND WILDCARD BLOCKED: $domain")
            return true
        }

        // 4. Check domain blocklist
        if (blockedDomains.any { blocked ->
                domain == blocked || domain.endsWith(".$blocked")
            }) {
            Log.e(TAG, "🚨 BLOCKLIST DOMAIN BLOCKED: $domain")
            return true
        }

        // 5. Keyword match in entire URL (check for standalone words to prevent blocking news/educational resources)
        val criticalKeywords = listOf("porn", "hentai", "sexvideo", "adultvideo", "sexcam")
        return criticalKeywords.any { kw -> 
            val regex = Regex("\\b${kw}\\b")
            regex.containsMatchIn(lower)
        }
    }

    /**
     * Show a full-screen blocking overlay using TYPE_ACCESSIBILITY_OVERLAY.
     * We make it FOCUSABLE so buttons can receive click events.
     */
    private fun showBlockingOverlay() {
        handler.post {
            try {
                val wm = getSystemService(WINDOW_SERVICE) as WindowManager
                
                // If overlay is already showing, don't add another one
                if (isOverlayShowing) return@post

                val layout = createOverlayLayout()

                // IMPORTANT: Removed FLAG_NOT_FOCUSABLE to allow button interactions
                val params = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                            WindowManager.LayoutParams.FLAG_FULLSCREEN,
                    PixelFormat.TRANSLUCENT
                )
                params.gravity = Gravity.CENTER

                wm.addView(layout, params)
                overlayView = layout
                isOverlayShowing = true
                Log.d(TAG, "✅ Blocking overlay shown")
            } catch (e: Exception) {
                Log.e(TAG, "Error showing overlay", e)
            }
        }
    }

    /**
     * Force close a specific browser app.
     */
    private fun forceBrowserClose(packageName: String) {
        try {
            // Request home screen first to hide the app
            performGlobalAction(GLOBAL_ACTION_HOME)
            
            // Use ActivityManager to kill the package
            handler.postDelayed({
                val runtime = Runtime.getRuntime()
                runtime.exec("am force-stop $packageName")
                Log.e(TAG, "✅ BROWSER FORCE CLOSED: $packageName")
            }, 300)
        } catch (e: Exception) {
            Log.e(TAG, "Error force-closing browser", e)
        }
    }

    private fun removeOverlay() {
        handler.post {
            try {
                if (overlayView != null) {
                    val wm = getSystemService(WINDOW_SERVICE) as WindowManager
                    wm.removeView(overlayView)
                    overlayView = null
                    isOverlayShowing = false
                    Log.d(TAG, "Blocking overlay removed")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error removing overlay", e)
            }
        }
    }

    private fun createOverlayLayout(): View {
        val dp = { value: Int ->
            TypedValue.applyDimension(
                TypedValue.COMPLEX_UNIT_DIP, value.toFloat(), resources.displayMetrics
            ).toInt()
        }

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#EE121218")) // Semi-transparent dark
            setPadding(dp(32), dp(32), dp(32), dp(32))
            
            // INTERCEPT ALL TOUCHES - make it impossible to click behind
            isClickable = true
            isFocusable = true
        }

        // Icon
        val iconView = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_dialog_alert)
            setColorFilter(Color.parseColor("#FF4444"))
            layoutParams = LinearLayout.LayoutParams(dp(80), dp(80)).apply {
                bottomMargin = dp(24)
            }
        }
        layout.addView(iconView)

        // Title
        val titleView = TextView(this).apply {
            text = "Blocked by Reclaim"
            setTextColor(Color.WHITE)
            textSize = 28f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = dp(16) }
        }
        layout.addView(titleView)

        // Message
        val messageView = TextView(this).apply {
            text = "Blocked by Reclaim. Focus on what matters."
            setTextColor(Color.parseColor("#CCCCCC"))
            textSize = 18f
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = dp(40) }
        }
        layout.addView(messageView)

        // "Return Home" button (Primary)
        val returnHomeButton = Button(this).apply {
            text = "🏠 Go to Home Screen"
            setTextColor(Color.WHITE)
            textSize = 16f
            typeface = Typeface.DEFAULT_BOLD
            isAllCaps = false
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#4CAF50"))
                cornerRadius = dp(12).toFloat()
            }
            setPadding(dp(24), dp(16), dp(24), dp(16))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = dp(16) }
            setOnClickListener {
                removeOverlay()
                performGlobalAction(GLOBAL_ACTION_HOME)
            }
        }
        layout.addView(returnHomeButton)

        // "Open Reclaim" button
        val openAppButton = Button(this).apply {
            text = "🛡️ Open Reclaim App"
            setTextColor(Color.WHITE)
            textSize = 14f
            isAllCaps = false
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#2196F3"))
                cornerRadius = dp(12).toFloat()
            }
            setPadding(dp(24), dp(14), dp(24), dp(14))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            setOnClickListener {
                removeOverlay()
                val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                }
                intent?.let { startActivity(it) }
            }
        }
        layout.addView(openAppButton)

        return layout
    }

    /**
     * Clear browser recent apps to prevent quick re-access.
     * Since am force-stop requires root/system, we use GLOBAL_ACTION_HOME
     * and suggest the user closes it manually or use device admin if available.
     */
    private fun clearBrowserRecentApps() {
        try {
            // Request home screen to hide the browser
            performGlobalAction(GLOBAL_ACTION_HOME)
            
            Log.d(TAG, "✅ Requested Home screen to hide browser")
        } catch (e: Exception) {
            Log.e(TAG, "Error clearing browser recent apps", e)
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility service interrupted")
    }

    override fun onDestroy() {
        removeOverlay()
        super.onDestroy()
    }

    // Default blocked domains (always active even without sync)
    private val DEFAULT_DOMAINS = setOf(
        "pornhub.com", "xvideos.com", "xnxx.com", "redtube.com",
        "youporn.com", "tube8.com", "xhamster.com", "spankbang.com",
        // xhamster variants
        "xhamster.desi", "xhamster.tv", "xhamster.press",
        "xhamster19.com", "xhamster18.com", "xhamster17.com",
        "xhamster20.com", "xhamster21.com", "xhamster22.com",
        "xhamstersex.com", "xhamster26.com", "xhamster23.com",
        // More variants
        "pornone.com", "eporner.com", "tnaflix.com", "beeg.com",
        "youjizz.com", "porn.com", "fuq.com", "thumbzilla.com",
        "chaturbate.com", "stripchat.com", "livejasmin.com",
        "bongacams.com", "myfreecams.com", "camsoda.com",
        "onlyfans.com", "brazzers.com", "bangbros.com",
        "hentaihaven.xxx", "hanime.tv", "nhentai.net", "rule34.xxx",
    )
}
