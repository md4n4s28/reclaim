# Contributing to Reclaim

Thank you for your interest in contributing to **Reclaim**! Reclaim is a client-side digital discipline, self-restraint, and habit recovery utility built with **Flutter** and **Native Android (Kotlin)**.

We welcome contributions from developers, designers, writers, and security enthusiasts. Whether you are fixing bugs, improving battery efficiency, refining UI/UX animations, or expanding domain filtering rules, your help is appreciated.

---

## Code of Conduct

Please maintain a respectful, welcoming, supportive, and constructive environment. Remember that Reclaim is used by people striving to improve their mental health and conquer compulsive behaviors. Sensitivity, privacy protection, and ethical engineering are fundamental values of this project.

---

## How Can You Contribute?

1. **Reporting Bugs:**
   - Search the GitHub Issues tab to ensure the issue hasn't been reported already.
   - If not, open a new issue detailing:
     - Android OS version and device model.
     - Steps to reproduce.
     - Expected vs actual behavior.
     - Relevant logcat snippets (if available).

2. **Feature Requests & Ideas:**
   - Open a GitHub Discussion or Issue describing the proposed feature and why it benefits users' self-discipline journey.

3. **Code Contributions:**
   - Performance improvements in Native Android accessibility event processing.
   - Modernizing Flutter UI and animations with smooth haptics and dark theme consistency.
   - Strengthening anti-tamper mechanisms and app-blocking routines.
   - Enhancing home screen widgets (`AppWidget`).

4. **Curating Domain Blocklists:**
   - Update `assets/listofsitetoblock.md` with verified explicit domains while keeping zero false positives on educational or medical health resources.

---

## Development Setup

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (`v3.0.0` or higher, tested on `3.24+`)
- [Android Studio](https://developer.android.com/studio) with Android SDK 34+
- Physical Android device (recommended for testing Accessibility Service and AppWidget capabilities; emulators may have restricted accessibility gestures).

### Step-by-Step Setup

1. **Fork and Clone the Repository:**
   ```bash
   git clone https://github.com/md4n4s28/reclaim.git
   cd reclaim
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the Project on Your Test Device:**
   ```bash
   flutter run
   ```

---

## Submitting Pull Requests

1. **Create a branch** for your feature or fix:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. **Commit your changes** with clear, imperative commit messages:
   ```bash
   git commit -m "feat(widget): add discrete streak widget support"
   ```
3. **Keep UI consistent** with the dark OLED theme (`AppColors.background`, `AppColors.card`, `AppColors.primaryGlow`, `AppColors.accent`).
4. **Push to your fork** and submit a Pull Request to `main`.
5. Clearly describe the problem solved, testing performed, and any screenshots if UI changes were made.

---

## Security & Disclosure

If you discover a security bypass or vulnerability that allows circumventing Reclaim's protections unintentionally, please open an issue or contact the maintainer directly at [@md4n4s28](https://github.com/md4n4s28).
