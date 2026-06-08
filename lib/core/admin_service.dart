// Backward compatibility re-export.
// All protection logic now lives in ProtectionService.
export 'protection_service.dart';

// Keep AdminService as a thin wrapper so any old direct references still compile.
import 'protection_service.dart';

class AdminService {
  /// Check if device admin is active
  static Future<bool> isAdminActive() => ProtectionService.isAdminActive();

  /// Request device admin privileges
  static Future<bool> requestAdminPrivileges() => ProtectionService.requestAdminPrivileges();

  /// Lock app from uninstallation
  static Future<void> lockApp() => ProtectionService.lockApp();
}
