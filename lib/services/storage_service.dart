import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _userNameKey = "user_name";

  // Sauvegarder le nom
  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  // Récupérer le nom
  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey) ?? "Utilisateur";
  }
}