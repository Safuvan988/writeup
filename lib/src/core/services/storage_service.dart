import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:write_up/src/modules/auth/model/user_model.dart';

class StorageService {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'user_data';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_keyUser);
    if (userStr != null) {
      return User.fromJson(jsonDecode(userStr));
    }
    return null;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static const String _keyBookmarks = 'bookmarked_blogs';

  Future<List<String>> getBookmarkedBlogIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyBookmarks) ?? [];
  }

  Future<void> toggleBookmark(String blogId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(_keyBookmarks) ?? [];
    if (bookmarks.contains(blogId)) {
      bookmarks.remove(blogId);
    } else {
      bookmarks.add(blogId);
    }
    await prefs.setStringList(_keyBookmarks, bookmarks);
  }

  Future<bool> isBookmarked(String blogId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(_keyBookmarks) ?? [];
    return bookmarks.contains(blogId);
  }

  // ── Reactions ─────────────────────────────────────────────────────────────

  Future<int> getReactionCount(String blogId, String emoji) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('reaction_${blogId}_$emoji') ?? 0;
  }

  Future<void> incrementReaction(String blogId, String emoji) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('reaction_${blogId}_$emoji') ?? 0;
    await prefs.setInt('reaction_${blogId}_$emoji', current + 1);
  }
}
