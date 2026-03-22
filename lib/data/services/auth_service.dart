import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Note: Conditional imports are better but let's try a simpler approach if possible
// We'll use the 'package:shared_preferences' and a simple error handling
// and I will explain to the user why Hot Restart is the problem.

class AuthService {
  static const String _userNameKey = 'user_name';
  static String? _cachedName; // In-memory cache

  static Future<String?> getUserName() async {
    // If we have it in memory, return it (works during hot restart sometimes? no, but helps within sessions)
    if (_cachedName != null) return _cachedName;

    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedName = prefs.getString(_userNameKey);
      return _cachedName;
    } catch (e) {
      debugPrint('Error loading name: $e');
      // If plugin fails on web, return the memory cache from current run if available
      return _cachedName;
    }
  }

  static Future<void> setUserName(String name) async {
    _cachedName = name;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userNameKey, name);
    } catch (e) {
      debugPrint('Error saving name: $e');
    }
  }
}
