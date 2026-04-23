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
    'https://api.dicebear.com/7.x/avataaars/png?seed=Felix&backgroundColor=b6e3f4',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Aneka&backgroundColor=ffdfbf',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Buddy&backgroundColor=c0aede',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Coco&backgroundColor=ffd5dc',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Daisy&backgroundColor=b6e3f4',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Eden&backgroundColor=a8f0c6',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Fluffy&backgroundColor=ffd5dc',
    'https://api.dicebear.com/7.x/avataaars/png?seed=George&backgroundColor=ffdfbf',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Honey&backgroundColor=c0aede',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Izzy&backgroundColor=b6e3f4',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Jack&backgroundColor=a8f0c6',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Kai&backgroundColor=ffd5dc',
  ];

  // شخصيات إضافية بأسلوب مختلف (Pixel Art & Fun)
  static const List<String> extraAvatars = [
    'https://api.dicebear.com/7.x/bottts/png?seed=Robot1&backgroundColor=b6e3f4',
    'https://api.dicebear.com/7.x/bottts/png?seed=Robot2&backgroundColor=ffdfbf',
    'https://api.dicebear.com/7.x/bottts/png?seed=Cyborg&backgroundColor=c0aede',
    'https://api.dicebear.com/7.x/bottts/png?seed=Mech&backgroundColor=ffd5dc',
    'https://api.dicebear.com/7.x/fun-emoji/png?seed=Dragon',
    'https://api.dicebear.com/7.x/fun-emoji/png?seed=Tiger',
    'https://api.dicebear.com/7.x/fun-emoji/png?seed=Lion',
    'https://api.dicebear.com/7.x/fun-emoji/png?seed=Wolf',
    'https://api.dicebear.com/7.x/pixel-art/png?seed=Ninja&backgroundColor=292929',
    'https://api.dicebear.com/7.x/pixel-art/png?seed=Knight&backgroundColor=1a1a2e',
    'https://api.dicebear.com/7.x/pixel-art/png?seed=Wizard&backgroundColor=2d1b69',
    'https://api.dicebear.com/7.x/pixel-art/png?seed=Archer&backgroundColor=0a3d62',
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
