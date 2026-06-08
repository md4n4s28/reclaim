# Reclaim

Reclaim is a digital discipline and self-control application built with Flutter. It provides system-level content blocking, real-time browser monitoring, and habit-tracking tools to assist users in recovery from digital addictions.

## Architecture

The application is structured using a standard Flutter/Provider architecture combined with native Android services for strict enforcement.

*   **Frontend**: Flutter, utilizing Provider for state management.
*   **Persistent Storage**: SharedPreferences for local state.
*   **Native Enforcement (Android)**:
    *   `DevicePolicyManager`: Prevents uninstallation via Device Administrator privileges.
    *   `AccessibilityService`: Actively monitors browser URLs and screen content to block access to adult material. Implements a "Strict Mode" that prevents users from disabling protective settings (e.g., Private DNS, Accessibility) during moments of weakness.
*   **DNS Filtering**: Provides users with straightforward instructions to configure system-wide DNS-over-TLS (e.g., AdGuard, CleanBrowsing).

## Core Features

*   **Progress Tracking**: Tracks current streak, longest streak, and logs relapses on a dynamic calendar.
*   **Emergency Mode**: Provides immediate grounding techniques (5-4-3-2-1 method) and quick physical actions to redirect focus during high-intensity urges.
*   **Journaling**: A private space for reflection, tracking triggers, and logging daily gratitude.
*   **Daily Habits**: A tracker to replace negative behaviors with positive daily routines.
*   **Strict Mode**: An anti-bypass system that forcefully closes the Android Settings application if a user attempts to remove their established protections.

## Setup Instructions

1.  Ensure you have the Flutter SDK installed (version 3.0.0 or higher).
2.  Clone the repository.
3.  Run `flutter pub get` to install dependencies.
4.  Run `flutter run` to launch the application on a connected device or emulator.

## License

This project is intended for personal use and recovery. Please refer to the repository owner for licensing details.