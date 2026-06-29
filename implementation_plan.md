# Block Tab — Complete Premium Redesign

Redesign the Block Tab from a raw settings page into a premium security dashboard. Each section will be implemented **one at a time** in sequence, verified before moving to the next, to prevent any crashes.

> [!IMPORTANT]
> The existing **Protection Active** card (`_ProtectionStatus`) will be **kept and enhanced** — never removed.

---

## Proposed Changes

### Phase 1: Enhanced AppProvider + Data Layer
Add new fields/methods to the provider to support category toggles, user-added websites (separate from built-in), stats counters, and recent activity tracking. This is the foundation for all UI changes.

#### [MODIFY] [app_provider.dart](file:///d:/Code%20Project/Android%20Project/Reclaim/Reclaim/lib/core/app_provider.dart)
- Add category toggle fields (`adultEnabled`, `gamblingEnabled`, etc.) persisted via SharedPreferences
- Add `userAddedWebsites` list (separate from built-in blocked sites)
- Add stats: `blockedAttempts`, `websitesBlockedToday`, `appsRestrictedToday`, `focusTimeSavedMinutes`
- Add `recentActivity` list (max 5 entries with timestamps)
- Add computed getters: `builtInSiteCount`, `userSiteCount`, `blockedAppCount`
- Add methods: `addUserWebsite()`, `removeUserWebsite()`, `toggleCategory()`, `addRecentActivity()`

---

### Phase 2: Redesign Block Screen — Hero Card Enhancement
Keep the existing `_ProtectionStatus` widget but upgrade it to the premium Hero Protection Card from the spec.

#### [MODIFY] [block_screen.dart](file:///d:/Code%20Project/Android%20Project/Reclaim/Reclaim/lib/features/block/block_screen.dart)
- Upgrade `_ProtectionStatus` → premium Hero card with shield icon, gradient background, pulse animation
- Display: Protection Active, Real-Time Monitoring, Adult Websites: 5945+, Blocked Apps: X, Custom Websites: X, Coverage: Excellent
- Keep the existing accessibility check logic intact

---

### Phase 3: Protection Overview Stats Row
Add 3 compact horizontal stat cards below the Hero card.

#### [MODIFY] [block_screen.dart](file:///d:/Code%20Project/Android%20Project/Reclaim/Reclaim/lib/features/block/block_screen.dart)
- Add `_ProtectionOverview` widget with 3 cards: Adult Websites (5945+), Custom Websites (X), Blocked Apps (X)
- Each card: icon, count, label, tap animation

---

### Phase 4: Quick Protection Categories
Horizontal scroll section with category cards and toggle switches.

#### [MODIFY] [block_screen.dart](file:///d:/Code%20Project/Android%20Project/Reclaim/Reclaim/lib/features/block/block_screen.dart)
- Add `_QuickCategories` widget with horizontally scrollable category cards
- Categories: Adult Content (ON), Gambling (ON), Dating (ON), Social Media (OFF), Streaming (OFF), Gaming (OFF)
- Each card: icon, name, website count, toggle switch, active styling
- Toggles persist via provider/SharedPreferences

---

### Phase 5: Custom Blocking Hub Card
Replace the current App Blocker card and Add Website card with a single premium "Custom Blocking" card.

#### [MODIFY] [block_screen.dart](file:///d:/Code%20Project/Android%20Project/Reclaim/Reclaim/lib/features/block/block_screen.dart)
- Remove `_AppBlockerCard` and `_AddSiteCard` from the ListView
- Add `_CustomBlockingHub` card with feature list and "View / Manage Blocking" button
- Button navigates to new `CustomBlockingScreen`

---

### Phase 6: Today's Protection Dashboard Card
Add a stats card showing today's blocking activity.

#### [MODIFY] [block_screen.dart](file:///d:/Code%20Project/Android%20Project/Reclaim/Reclaim/lib/features/block/block_screen.dart)
- Add `_TodaysProtection` card with 4 stats: Blocked Attempts, Websites Blocked, Apps Restricted, Focus Time Saved
- Use provider data where available, placeholders otherwise

---

### Phase 7: Recent Activity Card
Show last 5 blocking events in a scrollable card.

#### [MODIFY] [block_screen.dart](file:///d:/Code%20Project/Android%20Project/Reclaim/Reclaim/lib/features/block/block_screen.dart)
- Add `_RecentActivity` card showing max 5 recent events
- Each entry: blocked item name, time ago
- Remove the raw website list (`_SiteItem` widgets, `_BlockedSitesHeader`)

---

### Phase 8: Remove Raw Website List
Remove the display of individual blocked domain names from the main screen.

#### [MODIFY] [block_screen.dart](file:///d:/Code%20Project/Android%20Project/Reclaim/Reclaim/lib/features/block/block_screen.dart)
- Remove `_SiteItem` and `_BlockedSitesHeader` widgets
- Remove the `.take(50)` loop rendering individual domains
- The built-in database stays internal, only counts shown

---

### Phase 9: Custom Blocking Screen
Create the central management interface with TabBar for App Blocker and Website Blocker.

#### [NEW] [custom_blocking_screen.dart](file:///d:/Code%20Project/Android%20Project/Reclaim/Reclaim/lib/features/block/custom_blocking_screen.dart)
- `TabBar` + `TabBarView` with 2 tabs: App Blocker, Website Blocker
- **Tab 1 (App Blocker)**: Reuse existing `AppBlockerScreen` logic — app list, search, toggle, blocked indicator
- Add blocking modes: Permanent Block, Timed Block (15m/30m/1h/2h/custom), countdown timer
- Visual states: Red (blocked), Orange (timed), Gray (disabled)
- **Tab 2 (Website Blocker)**: Manage user-added websites only (not built-in database)
- Search bar, add website input, domain validation, duplicate prevention
- Each entry: domain, toggle, edit, delete, block mode indicator
- Timed block with countdown, auto-remove on expiry

#### [MODIFY] [main.dart](file:///d:/Code%20Project/Android%20Project/Reclaim/Reclaim/lib/main.dart)
- Add route: `'/custom_blocking': (_) => const CustomBlockingScreen()`

---

## Verification Plan

### After Each Phase
- Hot restart the app
- Navigate to Block Tab
- Verify no crashes
- Verify the Protection Active card is visible and functional
- Verify all existing functionality still works (accessibility check, navigation)

### Final Verification
- Full app cold start
- Navigate through all tabs
- Test Custom Blocking Screen navigation
- Test category toggles persist
- Test add/remove user websites
- Test timed blocking countdown
- Verify no raw domain names shown on main Block Tab

---

## Open Questions

> [!IMPORTANT]
> **Category Website Lists**: The spec mentions Gambling (1200), Dating (800), Social Media (150), etc. Should I create separate asset files for each category, or just use the counts as display-only for now (with actual filtering deferred)?

> [!NOTE]
> **Timed Blocking Backend**: The timed blocking requires a timer mechanism. Since this is Flutter, I'll use `Timer` for in-app countdowns and persist expiry times in SharedPreferences. The native side auto-unblocking will need platform channel updates. Should I implement the Flutter-side timer logic only for now and defer the native integration?
