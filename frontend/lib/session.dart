import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class UserSession {
  static const _idKey = 'userId';
  static const _nameKey = 'userName';
  static const _locationPermissionPromptedKey = 'locationPermissionPrompted';
  static const _locationPermissionGrantedKey = 'locationPermissionGranted';

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_idKey, user.id);
    await prefs.setString(_nameKey, user.name);
  }

  static Future<String?> userId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_idKey);
  }

  static Future<void> setLocationPermissionPrompted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationPermissionPromptedKey, value);
  }

  static Future<void> setLocationPermissionGranted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationPermissionGrantedKey, value);
  }

  static Future<bool> locationPermissionPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_locationPermissionPromptedKey) ?? false;
  }

  static Future<bool> locationPermissionGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_locationPermissionGrantedKey) ?? false;
  }
}
