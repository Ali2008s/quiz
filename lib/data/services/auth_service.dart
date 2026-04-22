import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Note: Conditional imports are better but let's try a simpler approach if possible
// We'll use the 'package:shared_preferences' and a simple error handling
// and I will explain to the user why Hot Restart is the problem.

class AuthService {
  static const String _userNameKey = 'user_name';
  static const String _userAvatarKey = 'user_avatar';
  static String? _cachedName;
  static String? _cachedAvatar;

  static const List<String> availableAvatars = [
    'https://api.dicebear.com/7.x/avataaars/png?seed=Felix',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Aneka',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Buddy',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Coco',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Daisy',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Eden',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Fluffy',
    'https://api.dicebear.com/7.x/avataaars/png?seed=George',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Honey',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Izzy',
  ];

  static Future<String?> getUserName() async {
    if (_cachedName != null) return _cachedName;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedName = prefs.getString(_userNameKey);
      return _cachedName;
    } catch (e) {
      debugPrint('Error loading name: $e');
      return _cachedName;
    }
  }

  static Future<String?> getUserAvatar() async {
    if (_cachedAvatar != null) return _cachedAvatar;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedAvatar = prefs.getString(_userAvatarKey) ?? availableAvatars[0];
      return _cachedAvatar;
    } catch (e) {
      debugPrint('Error loading avatar: $e');
      return _cachedAvatar ?? availableAvatars[0];
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

  static Future<void> setUserAvatar(String avatarUrl) async {
    _cachedAvatar = avatarUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userAvatarKey, avatarUrl);
    } catch (e) {
      debugPrint('Error saving avatar: $e');
    }
  }
}
