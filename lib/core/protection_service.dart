import 'package:flutter/services.dart';

/// Unified service for all native protection methods:
/// VPN blocking, device admin, accessibility/browser protection, and blocklist sync.
class ProtectionService {
  static const _vpnChannel = MethodChannel('com.reclaim.app/vpn');
  static const _adminChannel = MethodChannel('com.reclaim.app/admin');
  static const _protectionChannel = MethodChannel('com.reclaim.app/protection');

  // ──────────────────── VPN Methods ────────────────────

  /// Starts the local VPN service for DNS-level blocking.
  /// Returns `true` on success, or `false` if a permission dialog was shown / error occurred.
  static Future<bool> startVpn() async {
    try {
      final result = await _vpnChannel.invokeMethod<bool>('startVpn');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Stops the VPN service.
  static Future<bool> stopVpn() async {
    try {
      final result = await _vpnChannel.invokeMethod<bool>('stopVpn');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Checks whether the VPN service is currently running.
  static Future<bool> isVpnRunning() async {
    try {
      final result = await _vpnChannel.invokeMethod<bool>('isVpnRunning');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // ──────────────────── Admin Methods ────────────────────

  /// Check if device admin is active.
  static Future<bool> isAdminActive() async {
    try {
      final result = await _adminChannel.invokeMethod<bool>('isAdminActive');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Request device admin privileges.
  static Future<bool> requestAdminPrivileges() async {
    try {
      final result = await _adminChannel.invokeMethod<bool>('requestAdmin');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Lock app from uninstallation.
  static Future<void> lockApp() async {
    try {
      await _adminChannel.invokeMethod('lockApp');
    } catch (e) {
      // Handle error silently
    }
  }

  // ──────────────────── Protection Methods ────────────────────

  /// Sends the full domain blocklist to the native side for the VPN / accessibility service.
  static Future<bool> syncBlocklist(List<String> sites) async {
    try {
      final result = await _protectionChannel.invokeMethod<bool>(
        'syncBlocklist',
        {'sites': sites},
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Sends the custom DNS list to the native side for the VPN service.
  static Future<bool> syncDnsList(List<String> dns) async {
    try {
      final result = await _protectionChannel.invokeMethod<bool>(
        'syncDnsList',
        {'dns': dns},
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Checks whether the accessibility service is enabled in system settings.
  static Future<bool> isAccessibilityEnabled() async {
    try {
      final result = await _protectionChannel.invokeMethod<bool>('isAccessibilityEnabled');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Opens the device accessibility settings so the user can enable the service.
  static Future<void> openAccessibilitySettings() async {
    try {
      await _protectionChannel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      // Handle error silently
    }
  }

  /// Opens the device Private DNS settings (Android 9+).
  static Future<void> openPrivateDnsSettings() async {
    try {
      await _protectionChannel.invokeMethod('openPrivateDnsSettings');
    } catch (e) {
      // Handle error silently
    }
  }
}
