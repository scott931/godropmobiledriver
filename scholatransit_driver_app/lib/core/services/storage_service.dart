import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/app_config.dart';

class StorageService {
  static late SharedPreferences _prefs;
  static late Box _box;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _box = await Hive.openBox('scholatransit_driver');
  }

  // SharedPreferences methods
  static Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs.getString(key);
  }

  static Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  static int? getInt(String key) {
    return _prefs.getInt(key);
  }

  static Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  static Future<void> setDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }

  static double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  static Future<void> setStringList(String key, List<String> value) async {
    await _prefs.setStringList(key, value);
  }

  static List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  static Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  static Future<void> clear() async {
    await _prefs.clear();
  }

  // Hive methods for complex data
  static Future<void> setObject(String key, dynamic value) async {
    await _box.put(key, value);
  }

  static T? getObject<T>(String key) {
    return _box.get(key);
  }

  static Future<void> deleteObject(String key) async {
    await _box.delete(key);
  }

  static Future<void> clearBox() async {
    await _box.clear();
  }

  // Auth token methods
  static Future<void> saveAuthToken(String token) async {
    await setString(AppConfig.authTokenKey, token);
  }

  static String? getAuthToken() {
    return getString(AppConfig.authTokenKey);
  }

  static Future<void> saveRefreshToken(String token) async {
    await setString(AppConfig.refreshTokenKey, token);
  }

  static String? getRefreshToken() {
    return getString(AppConfig.refreshTokenKey);
  }

  static Future<void> clearAuthTokens() async {
    await remove(AppConfig.authTokenKey);
    await remove(AppConfig.refreshTokenKey);
  }

  // User profile methods
  static Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    await setObject(AppConfig.userProfileKey, profile);
  }

  static Map<String, dynamic>? getUserProfile() {
    return getObject<Map<String, dynamic>>(AppConfig.userProfileKey);
  }

  static Future<void> clearUserProfile() async {
    await deleteObject(AppConfig.userProfileKey);
  }

  // Driver ID methods
  static Future<void> saveDriverId(int driverId) async {
    await setInt(AppConfig.driverIdKey, driverId);
  }

  static int? getDriverId() {
    return getInt(AppConfig.driverIdKey);
  }

  static Future<void> clearDriverId() async {
    await remove(AppConfig.driverIdKey);
  }

  // Current trip methods
  static Future<void> saveCurrentTrip(Map<String, dynamic> trip) async {
    await setObject(AppConfig.currentTripKey, trip);
  }

  static Map<String, dynamic>? getCurrentTrip() {
    return getObject<Map<String, dynamic>>(AppConfig.currentTripKey);
  }

  static Future<void> clearCurrentTrip() async {
    await deleteObject(AppConfig.currentTripKey);
  }

  // Location history methods
  static Future<void> saveLocationHistory(
    List<Map<String, dynamic>> locations,
  ) async {
    await setObject(AppConfig.locationHistoryKey, locations);
  }

  static List<Map<String, dynamic>>? getLocationHistory() {
    return getObject<List<Map<String, dynamic>>>(AppConfig.locationHistoryKey);
  }

  static Future<void> clearLocationHistory() async {
    await deleteObject(AppConfig.locationHistoryKey);
  }

  // Notification settings methods
  static Future<void> saveNotificationSettings(
    Map<String, dynamic> settings,
  ) async {
    await setObject(AppConfig.notificationSettingsKey, settings);
  }

  static Map<String, dynamic>? getNotificationSettings() {
    return getObject<Map<String, dynamic>>(AppConfig.notificationSettingsKey);
  }

  static Future<void> clearNotificationSettings() async {
    await deleteObject(AppConfig.notificationSettingsKey);
  }

  // Clear all data
  static Future<void> clearAllData() async {
    await clear();
    await clearBox();
  }
}


