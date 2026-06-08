package com.reclaim.app

import android.accessibilityservice.AccessibilityService
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
    )

    private val supportedBrowserPackages = browserAddressBarIds.keys

    // Blocklist (loaded from SharedPrefs + defaults)
    private var blockedDomains = setOf<String>()
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
        "massage", "happy ending", "massage parlor",
        "dating", "hookup", "adult dating", "affair",
        "sugar daddy", "sugar baby", "escort service",

        // Asian adult content (common searches)
        "jav", "japanese porn", "korean porn",
        "thai porn", "indian sex", "desi porn",

        // Incest content
        "incest", "family sex", "mom son", "sister brother",
        "taboo", "forbidden", "family fun",

        // Other variations
        "boobs", "tits", "ass", "butt", "naked girl",
        "naked man", "nude photo", "nude video", "nude pic",
        "topless", "bikini", "lingerie model",
        "playboy", "penthouse", "hustler",
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

        // 1. MONITOR SYSTEM SETTINGS (Cheat Prevention)
        if (pkg in systemSettingsPackages || pkg.contains("settings") || pkg.contains("packageinstaller")) {
            monitorSettingsForCheating(event)
            return
        }

        if (pkg !in supportedBrowserPackages) return

        // Refresh blocklist cache if needed
        refreshBlocklistIfNeeded()

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

    /**
     * Prevent user from disabling Private DNS or Accessibility service.
     */
    private fun monitorSettingsForCheating(event: AccessibilityEvent) {
        val rootNode = rootInActiveWindow ?: event.source ?: return
        
        // Scan for keywords that indicate the user is trying to "cheat"
        if (scanNodeForCheatKeywords(rootNode)) {
            Log.e(TAG, "🛡️ CHEAT ATTEMPT DETECTED in Settings - REDIRECTING")
            
            // Redirect to home screen immediately
            performGlobalAction(GLOBAL_ACTION_HOME)
            
            // Re-open Reclaim to remind the user
            val intent = packageManager.getLaunchIntentForPackage(packageName)
            intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            startActivity(intent)
        }
    }

    private fun scanNodeForCheatKeywords(node: AccessibilityNodeInfo?): Boolean {
        node ?: return false
        try {
            val text = node.text?.toString()?.lowercase() ?: ""
            val contentDesc = node.contentDescription?.toString()?.lowercase() ?: ""
            
            val combinedText = "$text $contentDesc"
            
            // Block access to DNS, Accessibility Service settings, and uninstall pages
            // Covers Motorola, Samsung, Xiaomi, and stock Android variations
            val cheatKeywords = listOf(
                "private dns", 
                "accessibility service",
                "device admin",
                "device administrators",
                "device admin apps",
                "admin apps",
                "uninstall reclaim",
                "reclaim app info",
                "deactivate this device admin"
            )
            
            if (cheatKeywords.any { combinedText.contains(it) }) {
                return true
            }

            // Aggressively block searching for these terms in the Settings app
            if (node.className == "android.widget.EditText" || node.className == "android.widget.AutoCompleteTextView") {
                if (combinedText.contains("admin") || combinedText.contains("dns") || combinedText.contains("uninstall")) {
                    return true
                }
            }

            for (i in 0 until node.childCount) {
                if (scanNodeForCheatKeywords(node.getChild(i))) return true
            }
        } catch (_: Exception) {}
        return false
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
            Log.d(TAG, "Loaded ${blockedDomains.size} blocked domains")
        } catch (e: Exception) {
            Log.e(TAG, "Error loading blocklist", e)
            blockedDomains = DEFAULT_DOMAINS
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
     * Check if a URL should be blocked.
     * AGGRESSIVE BLOCKING - Matches against domain blocklist AND adult keywords.
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
                    if (adultKeywords.any { searchTerm.contains(it) }) {
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
        // We check if the domain CONTAINS the brand name to catch variants like xhamster19.com
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

        // 5. Keyword match in entire URL (strict but broad)
        // We only block if it's a clear porn keyword
        val criticalKeywords = listOf("porn", "hentai", "sexvideo", "adultvideo", "sexcam")
        return criticalKeywords.any { lower.contains(it) }
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
            text = "You are stronger than this urge.\nChoose consciously."
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
