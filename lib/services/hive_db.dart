import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveDb {
  static const String settingsBoxName = 'msk_settings';
  static const String userBoxName = 'msk_user';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(settingsBoxName);
    await Hive.openBox(userBoxName);
  }

  // --- Onboarding & Setup ---
  static bool get isOnboardingCompleted {
    final box = Hive.box(settingsBoxName);
    return box.get('onboarding_done', defaultValue: false) as bool;
  }

  static Future<void> setOnboardingCompleted(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put('onboarding_done', value);
  }

  // --- Premium Status ---
  static bool get isPremium {
    final box = Hive.box(settingsBoxName);
    return box.get('is_premium', defaultValue: false) as bool;
  }

  static Future<void> setPremiumStatus(bool value) async {
    final box = Hive.box(settingsBoxName);
    await box.put('is_premium', value);
  }

  // --- User Profiles ---
  static Map<String, dynamic>? get currentUser {
    final box = Hive.box(userBoxName);
    final data = box.get('profile');
    if (data != null) {
      return Map<String, dynamic>.from(data as Map);
    }
    return null;
  }

  static Future<void> saveUser(Map<String, dynamic> userProfile) async {
    final box = Hive.box(userBoxName);
    await box.put('profile', userProfile);
  }

  static Future<void> clearUser() async {
    final box = Hive.box(userBoxName);
    await box.delete('profile');
    await setPremiumStatus(false);
  }

  // --- Custom Download Settings ---
  // (Removed concurrent download limit — app manages concurrency internally)
  
  static String get downloadDirectory {
    final box = Hive.box(settingsBoxName);
    return box.get('download_dir', defaultValue: 'Default Storage') as String;
  }

  /// Returns the resolved download directory path.
  /// If user selected a custom path, that is returned.
  /// Otherwise attempts to return the device's default Downloads folder.
  static Future<String> getResolvedDownloadDirectory() async {
    final box = Hive.box(settingsBoxName);
    final stored = box.get('download_dir', defaultValue: 'Default Storage') as String;
    if (stored != 'Default Storage' && stored.isNotEmpty) return stored;

    try {
      if (Platform.isAndroid) {
        final sd = Directory('/storage/emulated/0/Download');
        if (await sd.exists()) return sd.path;

        final ext = await getExternalStorageDirectory();
        if (ext != null) {
          // Try to approximate downloads folder relative to external storage
          final parts = ext.path.split(Platform.pathSeparator);
          if (parts.length >= 4) {
            final root = parts.sublist(0, 3).join(Platform.pathSeparator);
            final candidate = Directory('$root${Platform.pathSeparator}Download');
            if (await candidate.exists()) return candidate.path;
          }
          return ext.path;
        }
      } else if (Platform.isIOS) {
        final docs = await getApplicationDocumentsDirectory();
        return docs.path;
      } else {
        final downloads = await getDownloadsDirectory();
        if (downloads != null) return downloads.path;
      }
    } catch (_) {}

    final fallback = await getApplicationDocumentsDirectory();
    return fallback.path;
  }

  static Future<void> setDownloadDirectory(String value) async {
    final box = Hive.box(settingsBoxName);
    await box.put('download_dir', value);
  }
}
