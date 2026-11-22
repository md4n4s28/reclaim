# Reclaim - Blocker & Urge Control (v2.1.0 Release Notes)

**Tag:** `v2.1.0`  
**Release Title:** `Reclaim v2.1.0 - Blocker & Urge Control: Home Screen Widget, Redesigned Emergency Mode & 4-Digit Security`  
**Target Branch:** `main`  

---

## What's New in v2.1.0

### 1. Discrete Home Screen Widget (ReclaimStreakWidget)
- **Privacy-First Design:** Added a dedicated Android Home Screen AppWidget (`widget_streak_layout.xml`) that displays your clean streak progress in a sleek, neutral styling so you can keep accountability on your phone's home screen without exposing sensitive habit context to onlookers.
- **Dynamic Live Updates:** Integrated native Kotlin BroadcastReceiver with instant sync to Flutter's live streak clock.

### 2. Overhauled Emergency Mode & Urge Surfing
- **Top Urge-Surfing Timer:** The active craving countdown is now prominently mounted at the top of Emergency Mode so you can focus on breathing through peak neurochemical waves.
- **Dynamic Craving Wave Simulator:** Custom-painted animated dual-layer sine wave canvas rendering real-time craving crests and troughs with luminous accents.
- **Gesture Bar Navigation Fix:** Re-engineered bottom modal action sheets (Cold Water, Push-ups, Room Change) with full `SafeArea` inset protection, preventing system gesture bar clipping on modern Android devices.

### 3. Dedicated 4-Digit Security PIN & Dialpad
- **Dedicated Circular Dialpad:** Replaced all generic text inputs with a purpose-built 4-dot numeric keypad featuring glowing fill animations, auto-advance verification on the 4th digit, and error micro-shake feedback.
- **Unified Settings Route:** Removed legacy dialogs across `SettingsScreen` and `AdvancedProtectionScreen` - creating, changing, and removing PINs now routes seamlessly to the unified `PinSetupSheet`.

### 4. Multi-Protocol Guided Breathwork
- **Interactive Protocol Selector:** Switch seamlessly between **4-7-8 Relaxing Breath**, **4-4-4-4 Box Breathing**, and **5-5 Coherent Balance**.
- **Tactile Breathing Orb:** Expanding and contracting radial glow orb synchronized with micro-haptic stage transitions.

### 5. Reimagined Journal & App Blocker
- **Bento Journal Cards:** Redesigned daily reflections with mood emoji indicators, filter tags (*All*, *Victories*, *Struggles*), and quick inspiration prompts.
- **Fluid App Blocker:** High-performance search, quick category filtering (*Browsers & Media*, *Restricted*), and native toggle switches with instant background persistence.

### 6. Native Zero-Latency Anti-Cheat Hardening
- Instant Accessibility watchdog (`notificationTimeout="0"`) protecting Reclaim from unauthorized deactivation in Settings.
- Full compatibility with Flutter 3.24+ and Android 14 (API 34).

---

## Downloads & Assets
- `app-release.apk` (Production signed or release artifact)
- Source code (zip, tar.gz)

---

**Full Changelog**: https://github.com/md4n4s28/reclaim/compare/v1.0.0...v2.1.0
