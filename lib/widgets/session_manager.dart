import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static Future<void> saveUserRole(String role) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
  }

  static Future<String?> getUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  static Future<void> clearUserSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
  }
}
