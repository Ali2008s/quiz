import 'package:shared_preferences/shared_preferences.dart';

class PointService {
  static const String _pointsKey = 'user_points';
  static const String _adFreeUntilKey = 'ad_free_until';

  // Get current points
  static Future<int> getPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pointsKey) ?? 5; // Initial 5 points only
  }

  // Add points
  static Future<void> addPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    int current = await getPoints();
    await prefs.setInt(_pointsKey, current + points);
  }

  // Deduct points (for spending)
  static Future<bool> spendPoints(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    int current = await getPoints();
    if (current >= amount) {
      await prefs.setInt(_pointsKey, current - amount);
      return true;
    }
    return false;
  }

  // Purchase ad-free time (in minutes)
  static Future<void> buyAdFreeTime(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();
    DateTime currentAdFree = await getAdFreeUntil();
    
    DateTime baseTime = currentAdFree.isAfter(now) ? currentAdFree : now;
    DateTime newDate = baseTime.add(Duration(minutes: minutes));
    
    await prefs.setString(_adFreeUntilKey, newDate.toIso8601String());
  }

  // Check if user is currently ad-free
  static Future<DateTime> getAdFreeUntil() async {
    final prefs = await SharedPreferences.getInstance();
    String? dateStr = prefs.getString(_adFreeUntilKey);
    if (dateStr == null) return DateTime.now();
    return DateTime.parse(dateStr);
  }

  static Future<bool> isAdFree() async {
    DateTime until = await getAdFreeUntil();
    return until.isAfter(DateTime.now());
  }
}
