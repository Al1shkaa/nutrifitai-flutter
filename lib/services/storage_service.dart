import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("jwt", token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("jwt");
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("jwt");
  }

  // Profile data methods
  static Future<void> saveProfileName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("profile_name", name);
  }

  static Future<String?> getProfileName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("profile_name");
  }

  static Future<void> saveProfileHeight(String height) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("profile_height", height);
  }

  static Future<String?> getProfileHeight() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("profile_height");
  }

  static Future<void> saveProfileWeight(String weight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("profile_weight", weight);
  }

  static Future<String?> getProfileWeight() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("profile_weight");
  }

  static Future<void> saveProfileAge(String age) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("profile_age", age);
  }

  static Future<String?> getProfileAge() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("profile_age");
  }

  static Future<void> saveProfileActivity(String activity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("profile_activity", activity);
  }

  static Future<String?> getProfileActivity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("profile_activity");
  }

  static Future<void> saveProfileGoal(String goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("profile_goal", goal);
  }

  static Future<String?> getProfileGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("profile_goal");
  }
}
