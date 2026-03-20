import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_progress.dart';

class StorageService {
  static const _progressKey = 'user_progress';
  static const _apiKeyKey = 'anthropic_api_key';

  Future<UserProgress> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_progressKey);
    if (json == null) return const UserProgress();
    return UserProgress.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> saveProgress(UserProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, jsonEncode(progress.toJson()));
  }

  Future<String?> loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, key);
  }
}
