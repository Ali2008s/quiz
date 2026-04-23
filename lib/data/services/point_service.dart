import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class PointService {
  static const String _pointsKey = 'user_points';
  static const String _adFreeUntilKey = 'ad_free_until';
  static final _supabase = Supabase.instance.client;

  // Get current points
  static Future<int> getPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pointsKey) ?? 5; // Initial 5 points only
  }

  // Add points
  static Future<void> addPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    int current = await getPoints();
    final newTotal = current + points;
    await prefs.setInt(_pointsKey, newTotal);

    // Sync with Supabase for leaderboard
    final name = await AuthService.getUserName();
    if (name != null) {
      await _syncToSupabase(name, newTotal);
    }
  }

  static Future<void> _syncToSupabase(String name, int totalPoints) async {
    try {
      await _supabase.from('profiles').upsert({
        'name': name,
        'points': totalPoints,
      }, onConflict: 'name');
    } catch (e) {
      // Ignore sync errors for offline play
    }
  }

  static Future<void> recordWin() async {
    final name = await AuthService.getUserName();
    if (name == null) return;
    try {
      // Fetch current wins or increment in one go if possible
      // Profiles table should have 'wins' column
      final data = await _supabase
          .from('profiles')
          .select('wins')
          .eq('name', name)
          .maybeSingle();
      int currentWins = data?['wins'] ?? 0;
      await _supabase.from('profiles').upsert({
        'name': name,
        'wins': currentWins + 1,
      }, onConflict: 'name');
    } catch (e) {}
  }

  // Deduct points (for spending)
  static Future<bool> spendPoints(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    int current = await getPoints();
    if (current >= amount) {
      final newTotal = current - amount;
      await prefs.setInt(_pointsKey, newTotal);

      final name = await AuthService.getUserName();
      if (name != null) _syncToSupabase(name, newTotal);

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

  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('name, points, wins')
          .order('points', ascending: false)
          .limit(20)
          .timeout(const Duration(seconds: 5));
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }
}
