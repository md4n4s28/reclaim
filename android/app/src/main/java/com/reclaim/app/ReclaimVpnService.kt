package com.reclaim.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.nio.charset.Charset

/**
 * ReclaimVpnService — DNS-only VPN proxy that blocks adult content.
 */
class ReclaimVpnService : VpnService() {

    private var vpnInterface: ParcelFileDescriptor? = null
    private var dnsThread: Thread? = null
    private val blockedDomains = mutableSetOf<String>()

    // Upstream family-safe DNS servers
    private var upstreamDnsList = mutableListOf<String>()

    companion object {
        const val ACTION_START = "com.reclaim.START_VPN"
        const val ACTION_STOP = "com.reclaim.STOP_VPN"
        const val NOTIFICATION_ID = 1
        const val CHANNEL_ID = "reclaim_vpn"
        const val TAG = "ReclaimVPN"

        // Default family-safe DNS
        private val DEFAULT_DNS = listOf(
            "185.228.168.168", // CleanBrowsing Family Filter
            "1.1.1.3",          // Cloudflare Family
            "94.140.14.15"      // AdGuard Family Protection
        )

        @Volatile
        var isRunning: Boolean = false
            private set
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return when (intent?.action) {
            ACTION_STOP -> {
                stopVpn()
                START_NOT_STICKY
            }
            else -> {
                startVpn()
                START_STICKY
            }
        }
    }

    private fun startVpn() {
        if (isRunning) {
            Log.d(TAG, "VPN already running")
            return
        }

        Log.d(TAG, "🚀 Starting VPN (DNS-only mode)...")
        loadUpstreamDns()
        loadBlocklist()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())

        try {
            // FIX: Only route DNS traffic to the TUN interface to avoid internet breakage.
            // We use a fake DNS IP (10.0.0.1) and only route that single IP.
            vpnInterface = Builder()
                .addAddress("10.0.0.2", 32)
                .addDnsServer("10.0.0.1")
                .addRoute("10.0.0.1", 32) // Only intercept DNS
                .setSession("Reclaim - Family Protection")
                .setMtu(1500)
                .setBlocking(true)
                .establish()

            if (vpnInterface == null) {
                Log.e(TAG, "❌ Failed to establish VPN interface")
                stopSelf()
                return
            }

            isRunning = true
            dnsThread = Thread({ runDnsProxy() }, "ReclaimDNS").also { it.start() }
            Log.d(TAG, "✅ VPN started successfully (DNS-only)")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to start VPN", e)
            stopSelf()
        }
    }

    private fun loadBlocklist() {
        try {
            val prefs = getSharedPreferences("reclaim_blocklist", MODE_PRIVATE)
            val domains = prefs.getStringSet("blocked_domains", emptySet()) ?: emptySet()
            blockedDomains.clear()
            blockedDomains.addAll(domains)
            Log.d(TAG, "Loaded ${domains.size} domains from SharedPreferences")
        } catch (e: Exception) {
            Log.e(TAG, "Error loading blocklist from prefs", e)
        }

        // Always include hardcoded defaults
        blockedDomains.addAll(DEFAULT_BLOCKED_DOMAINS)
        Log.d(TAG, "Total blocked domains: ${blockedDomains.size}")
    }

    private fun loadUpstreamDns() {
        try {
            val prefs = getSharedPreferences("reclaim_blocklist", MODE_PRIVATE)
            val dnsList = prefs.getStringSet("custom_dns", emptySet()) ?: emptySet()
            upstreamDnsList.clear()
            if (dnsList.isNotEmpty()) {
                upstreamDnsList.addAll(dnsList)
                Log.d(TAG, "Loaded ${dnsList.size} custom DNS servers: $upstreamDnsList")
            } else {
                upstreamDnsList.addAll(DEFAULT_DNS)
                Log.d(TAG, "Using default DNS servers: $upstreamDnsList")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error loading custom DNS", e)
            upstreamDnsList.clear()
            upstreamDnsList.addAll(DEFAULT_DNS)
        }
    }

    /**
     * Main DNS proxy loop.
     */
    private fun runDnsProxy() {
        val fd = vpnInterface?.fileDescriptor ?: return
        val input = FileInputStream(fd)
        val output = FileOutputStream(fd)
        val packet = ByteArray(32767)

        Log.d(TAG, "DNS proxy loop started")

        while (isRunning) {
            try {
                val length = input.read(packet)
                if (length <= 0) {
                    Thread.sleep(5)
                    continue
                }

                // Parse IPv4 header
                val version = (packet[0].toInt() ushr 4) and 0xF
                if (version != 4) continue 

                val ihl = (packet[0].toInt() and 0xF) * 4
                if (length < ihl + 8) continue 

                val protocol = packet[9].toInt() and 0xFF
                if (protocol != 17) continue 

                // Parse UDP header
                val udpOffset = ihl
                val dstPort = ((packet[udpOffset + 2].toInt() and 0xFF) shl 8) or
                        (packet[udpOffset + 3].toInt() and 0xFF)
                
                if (dstPort != 53) continue 

                // Parse DNS query
                val dnsOffset = udpOffset + 8
                if (length < dnsOffset + 12) continue 

                val domain = parseDnsDomain(packet, dnsOffset + 12, length)
                if (domain == null) {
                    forwardAndRespond(packet, length, ihl, dnsOffset, output)
                    continue
                }

                if (isDomainBlocked(domain)) {
                    Log.e(TAG, "🛑 VPN BLOCKED: $domain")
                    val response = buildNxdomainResponse(packet, length, ihl, dnsOffset)
                    if (response != null) {
                        output.write(response)
                        output.flush()
                    }
                } else {
                    forwardAndRespond(packet, length, ihl, dnsOffset, output)
                }
            } catch (e: Exception) {
                if (!isRunning) break
                try { Thread.sleep(50) } catch (_: Exception) {}
            }
        }

        Log.d(TAG, "DNS proxy loop ended")
        try { input.close() } catch (_: Exception) {}
        try { output.close() } catch (_: Exception) {}
    }

    /**
     * Parse domain name from DNS QNAME section.
     */
    private fun parseDnsDomain(packet: ByteArray, offset: Int, packetLength: Int): String? {
        try {
            val parts = mutableListOf<String>()
            var pos = offset

            while (pos < packetLength) {
                val labelLen = packet[pos].toInt() and 0xFF
                if (labelLen == 0) break
                if (labelLen > 63) return null
                pos++
                if (pos + labelLen > packetLength) return null

                val label = String(packet, pos, labelLen, Charsets.US_ASCII)
                parts.add(label)
                pos += labelLen
            }

            return if (parts.isNotEmpty()) parts.joinToString(".").lowercase() else null
        } catch (e: Exception) {
            return null
        }
    }

    /**
     * Check if a domain is blocked.
     */
    fun isDomainBlocked(domain: String): Boolean {
        val lower = domain.lowercase()
        
        // 1. Check blocked domains list (exact or parent)
        val inList = blockedDomains.any { blocked ->
            lower == blocked || lower.endsWith(".$blocked")
        }
        if (inList) return true

        // 2. Wildcard/Keyword check for major platforms that use variants
        val patterns = listOf("xhamster", "pornhub", "xnxx", "xvideos", "sex", "porn", "redtube", "youporn")
        return patterns.any { lower.contains(it) }
    }

    /**
     * Forward DNS query to upstream family DNS and write response back to TUN.
     */
    private fun forwardAndRespond(
        originalPacket: ByteArray, originalLength: Int,
        ihl: Int, dnsOffset: Int, output: FileOutputStream
    ) {
        if (upstreamDnsList.isEmpty()) {
            Log.w(TAG, "No upstream DNS available")
            return
        }

        var socket: DatagramSocket? = null
        try {
            val dnsPayload = originalPacket.copyOfRange(dnsOffset, originalLength)

            socket = DatagramSocket()
            protect(socket)
            socket.soTimeout = 5000

            var lastException: Exception? = null
            for (dnsServer in upstreamDnsList) {
                try {
                    val upstreamAddr = InetAddress.getByName(dnsServer)
                    val sendPacket = DatagramPacket(dnsPayload, dnsPayload.size, upstreamAddr, 53)
                    socket.send(sendPacket)

                    val responseBuffer = ByteArray(4096)
                    val receivePacket = DatagramPacket(responseBuffer, responseBuffer.size)
                    socket.receive(receivePacket)

                    val dnsResponse = responseBuffer.copyOfRange(0, receivePacket.length)

                    val response = buildForwardResponse(originalPacket, originalLength, ihl, dnsOffset, dnsResponse)
                    if (response != null) {
                        output.write(response)
                        output.flush()
                        return 
                    }
                } catch (e: Exception) {
                    lastException = e
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error setting up DNS forward", e)
        } finally {
            try { socket?.close() } catch (_: Exception) {}
        }
    }

    /**
     * Build NXDOMAIN response packet for a blocked domain.
     */
    private fun buildNxdomainResponse(
        originalPacket: ByteArray, originalLength: Int,
        ihl: Int, dnsOffset: Int
    ): ByteArray? {
        try {
            val response = originalPacket.copyOfRange(0, originalLength)

            for (i in 0 until 4) {
                val tmp = response[12 + i]
                response[12 + i] = response[16 + i]
                response[16 + i] = tmp
            }

            val udpOffset = ihl
            for (i in 0 until 2) {
                val tmp = response[udpOffset + i]
                response[udpOffset + i] = response[udpOffset + 2 + i]
                response[udpOffset + 2 + i] = tmp
            }

            response[dnsOffset + 2] = 0x81.toByte()
            response[dnsOffset + 3] = 0x83.toByte()

            response[dnsOffset + 6] = 0
            response[dnsOffset + 7] = 0
            response[dnsOffset + 8] = 0
            response[dnsOffset + 9] = 0
            response[dnsOffset + 10] = 0
            response[dnsOffset + 11] = 0

            response[udpOffset + 6] = 0
            response[udpOffset + 7] = 0

            recalculateIpChecksum(response, ihl)
            return response
        } catch (e: Exception) {
            return null
        }
    }

    /**
     * Build response packet with upstream DNS response payload.
     */
    private fun buildForwardResponse(
        originalPacket: ByteArray, originalLength: Int,
        ihl: Int, dnsOffset: Int, dnsResponse: ByteArray
    ): ByteArray? {
        try {
            val udpHeaderLen = 8
            val newTotalLen = ihl + udpHeaderLen + dnsResponse.size
            val response = ByteArray(newTotalLen)

            System.arraycopy(originalPacket, 0, response, 0, ihl)

            for (i in 0 until 4) {
                val tmp = response[12 + i]
                response[12 + i] = response[16 + i]
                response[16 + i] = tmp
            }

            response[2] = ((newTotalLen shr 8) and 0xFF).toByte()
            response[3] = (newTotalLen and 0xFF).toByte()

            val udpOffset = ihl
            response[udpOffset] = originalPacket[udpOffset + 2]
            response[udpOffset + 1] = originalPacket[udpOffset + 3]
            response[udpOffset + 2] = originalPacket[udpOffset]
            response[udpOffset + 3] = originalPacket[udpOffset + 1]

            val udpLen = udpHeaderLen + dnsResponse.size
            response[udpOffset + 4] = ((udpLen shr 8) and 0xFF).toByte()
            response[udpOffset + 5] = (udpLen and 0xFF).toByte()

            response[udpOffset + 6] = 0
            response[udpOffset + 7] = 0

            System.arraycopy(dnsResponse, 0, response, ihl + udpHeaderLen, dnsResponse.size)

            recalculateIpChecksum(response, ihl)
            return response
        } catch (e: Exception) {
            return null
        }
    }

    private fun recalculateIpChecksum(packet: ByteArray, ihl: Int) {
        packet[10] = 0
        packet[11] = 0

        var sum = 0L
        for (i in 0 until ihl step 2) {
            val word = ((packet[i].toInt() and 0xFF) shl 8) or (packet[i + 1].toInt() and 0xFF)
            sum += word
        }

        while ((sum shr 16) > 0) {
            sum = (sum and 0xFFFF) + (sum shr 16)
        }

        val checksum = sum.toInt().inv() and 0xFFFF
        packet[10] = ((checksum shr 8) and 0xFF).toByte()
        packet[11] = (checksum and 0xFF).toByte()
    }

    private fun stopVpn() {
        Log.d(TAG, "Stopping VPN...")
        isRunning = false
        dnsThread?.interrupt()
        dnsThread = null
        try { vpnInterface?.close() } catch (_: Exception) {}
        vpnInterface = null
        stopForeground(true)
        stopSelf()
    }

    override fun onRevoke() {
        stopVpn()
        super.onRevoke()
    }

    override fun onDestroy() {
        stopVpn()
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Reclaim Protection",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps content protection active"
                setShowBadge(false)
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("Reclaim Protection Active")
                .setContentText("DNS filtering is protecting you")
                .setSmallIcon(android.R.drawable.ic_lock_lock)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("Reclaim Protection Active")
                .setContentText("DNS filtering is protecting you")
                .setSmallIcon(android.R.drawable.ic_lock_lock)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .build()
        }
    }

    private val DEFAULT_BLOCKED_DOMAINS = setOf(
        "pornhub.com", "xvideos.com", "xnxx.com", "redtube.com",
        "youporn.com", "tube8.com", "xhamster.com", "spankbang.com",
        "pornone.com", "eporner.com", "tnaflix.com", "drtuber.com",
        "txxx.com", "hclips.com", "porntrex.com", "thumbzilla.com",
        "beeg.com", "youjizz.com", "porn.com", "4tube.com",
        "porntube.com", "sunporno.com", "pornpics.com", "fuq.com",
        "xhamster.desi", "xhamster.tv", "xhamster.press",
        "xhamster19.com", "xhamster18.com", "xhamster17.com",
        "xhamster20.com", "xhamster21.com", "xhamster22.com",
        "xhamstersex.com", "xhamster26.com", "xhamster23.com",
        "hentaihaven.xxx", "hanime.tv", "nhentai.net", "rule34.xxx",
        "e-hentai.org", "gelbooru.com", "danbooru.donmai.us",
        "hentaihaven.com", "hentaimanga.com", "porne.io",
        "chaturbate.com", "stripchat.com", "livejasmin.com",
        "bongacams.com", "cam4.com", "myfreecams.com", "camsoda.com",
        "streamate.com", "cabana.ca", "hentaicams.com",
        "onlyfans.com", "brazzers.com", "bangbros.com", "naughtyamerica.com",
        "realitykings.com", "mofos.com", "digitalplayground.com",
        "wicked.com", "julesjordan.com", "evilangel.com",
        "fleshlight.com", "hustlerflix.com", "sundayschool.com",
        "literotica.com", "imagefap.com", "motherless.com",
        "xnxx.tv", "pornhd.com", "porn300.com", "porngo.com",
        "fapvid.com", "cliphunter.com", "alohatube.com",
        "eporner.com", "spankmonster.com", "adultfriendfinder.com",
        "kink.com", "wgirls.net", "bellesa.com",
        "exoclick.com", "trafficjunky.com", "juicyads.com",
        "ero-advertising.com", "trafficfactory.biz",
        "plugrush.com", "adxpansion.com", "sexcam.com",
        "pornadvertising.com", "cdnstream.com"
    )
}
