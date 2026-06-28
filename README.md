# Reclaim
A Client-Side Application for Digital Discipline, Habit Tracking, and Network-Level Content Filtering

Reclaim is a self-control utility built using the Flutter framework. The project integrates an active dark-themed UI with native Android security APIs to assist users in establishing digital boundaries, tracking behavioral habits, and enforcing strict content constraints.

---

## Technical Overview

The application architecture utilizes Flutter's declarative layout system and SharedPreferences-based persistence on the frontend. The security model relies on native Android components to prevent bypass attempts:

1. **Native Accessibility Service (`ReclaimAccessibilityService`):** Monitors browser view structures, extracts search parameters, and checks queries against dynamic keyword blocklists. It also acts as an application watchdog, terminating blacklisted apps and preventing the user from disabling the service itself.
2. **Device Administration (`ReclaimDeviceAdminReceiver`):** Enforces uninstall prevention by locking the application package block state.
3. **Private DNS Mode Configuration:** Alters system-wide DNS configurations to use CleanBrowsing Family Filter endpoints to restrict adult content requests at the network level.

---

## Features and Subsystems

### Content Filtering and Search Interception
- **Boundary-Based Search Analysis:** Evaluates queries using exact word boundary matching. This blocks adult searches without triggering false positives on general strings.
- **3rd party browser and Webview Hooking:** Actively monitors third-party address bars and webviews to filter content within embedded browser utilities.

### Network Enforcement
- **CleanBrowsing Integration:** Modifies Android's Private DNS mode to `family-filter-dns.cleanbrowsing.org` and configures DHCP fallback addresses (`185.228.168.168`, `185.228.169.168`) when administration privileges are activated.

### App Blocker
- **Dynamic Package Listing:** Queries the Android Package Manager to retrieve installed application records, allowing users to toggle blocks on specific applications.
- **Immediate Task Interruption:** Detects target package launch intents and brings the home screen forward to block usage.

### Accountability and Recovery Tools
- **Consecutive Streak Tracker:** Calculates clean intervals based on stored relapse timestamps relative to the installation date.
- **TableCalendar Activity Logging:** Visualizes history, distinguishing clean days from reported relapse days.
- **Emergency Panic Panel:** Provides tactile countdown grounding exercises to redirect attention during urges.
- **Scheduled Motivation System:** Utilizes AlarmManager to schedule motivational notifications every three hours between 8 AM and 11 PM.

### Security Controls
- **4-Digit Access PIN:** Enforces verification before granting access to dashboard features. Includes verification and configuration dialogues.

---

## App Screenshots

<p align="left">
  <img src="screenshorts/homeScreen.png" width="220" alt="Home Dashboard" />
  <img src="screenshorts/urges.png" width="220" alt="Urges Tracker" />
  <img src="screenshorts/progressTab.png" width="220" alt="Journey Progress" />
  <img src="screenshorts/usage.png" width="220" alt="Usage Analytics" />
</p>

<p align="left">
  <img src="screenshorts/blockTab.png" width="220" alt="Block List Settings" />
  <img src="screenshorts/appBlock.png" width="220" alt="Application Blocker" />
  <img src="screenshorts/settings.png" width="220" alt="Settings Overview" />
  <img src="screenshorts/advanceSettings.png" width="220" alt="Advanced Protection Settings" />
</p>

<p align="left">
  <img src="screenshorts/panicMode.png" width="220" alt="Emergency Panic Screen" />
  <img src="screenshorts/journals.png" width="220" alt="Daily Journal Screen" />
</p>

---

## Installation and Deployment

### Development Prerequisites
- Flutter SDK (v3.0.0 or higher)
- Android SDK (with developer configuration active on the test device)

### Setup Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/reclaim.git
   cd reclaim
   ```

2. **Retrieve package dependencies:**
   ```bash
   flutter pub get
   ```

3. **Deploy the debug artifact to the connected device:**
   ```bash
   flutter run
   ```

4. **Grant permissions:**
   Complete the onboarding configuration wizard inside the app to activate Device Administration, System Accessibility, and Private DNS options.