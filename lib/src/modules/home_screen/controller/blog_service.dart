import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:write_up/app/utils/apiurls.dart';
import 'package:write_up/src/modules/home_screen/model/blog_model.dart';

class BlogService {
  /// POST /api/blogs
  /// Body: { "title": "string", "description": "string", "tags": ["string"], "image": "string" }
  Future<BlogResponseModel> createBlog(
    BlogRequestModel request, {
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse(Apiurls.blogs),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    final Map<String, dynamic> json = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return BlogResponseModel.fromJson(json);
    } else {
      final String errorMessage = json['message'] ?? 'Failed to create blog';
      throw Exception(
        '$errorMessage (Status: ${response.statusCode}, Body: ${response.body})',
      );
    }
  }

  /// GET /api/blogs
  /// Returns all published blogs for the home feed.
  Future<List<BlogData>> getAllBlogs({String? category}) async {
    String url = Apiurls.blogs;
    if (category != null && category != 'All') {
      url += '?category=$category';
    }
    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    final dynamic decoded = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (decoded is List) {
        return decoded.map((e) => BlogData.fromJson(e)).toList();
      } else if (decoded is Map<String, dynamic>) {
        final List<dynamic> list = decoded['data'] ?? [];
        return list.map((e) => BlogData.fromJson(e)).toList();
      }
      return [];
    } else {
      final String message = (decoded is Map && decoded.containsKey('message'))
          ? decoded['message']
          : 'Failed to fetch blogs (${response.statusCode})';
      throw Exception(message);
    }
  }

  /// GET /api/blogs/my
  /// Returns the authenticated user's blogs.
  Future<List<BlogData>> getMyBlogs({String? token}) async {
    final response = await http.get(
      Uri.parse(Apiurls.myBlogs),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    final dynamic decoded = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (decoded is List) {
        return decoded.map((e) => BlogData.fromJson(e)).toList();
      } else if (decoded is Map<String, dynamic>) {
        final List<dynamic> list = decoded['data'] ?? [];
        return list.map((e) => BlogData.fromJson(e)).toList();
      }
      return [];
    } else {
      final String message = (decoded is Map && decoded.containsKey('message'))
          ? decoded['message']
          : 'Failed to fetch blogs (${response.statusCode})';
      throw Exception(message);
    }
  }

  /// PUT /api/blogs/{id}
  /// Body: { "title": "string", "description": "string", "tags": ["string"], "image": "string" }
  Future<BlogResponseModel> updateBlog(
    String id,
    BlogRequestModel request, {
    String? token,
  }) async {
    final response = await http.put(
      Uri.parse(Apiurls.blogById(id)),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    final Map<String, dynamic> json = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return BlogResponseModel.fromJson(json);
    } else {
      throw Exception(
        json['message'] ?? 'Failed to update blog (${response.statusCode})',
      );
    }
  }

  /// DELETE /api/blogs/{id}
  Future<void> deleteBlog(String id, {String? token}) async {
    final response = await http.delete(
      Uri.parse(Apiurls.blogById(id)),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      throw Exception(
        json['message'] ?? 'Failed to delete blog (${response.statusCode})',
      );
    }
  }

  /// PATCH /api/blogs/{id}/react
  /// Body: { "emoji": "string" }
  Future<BlogData> reactToBlog(String id, String emoji, {String? token}) async {
    final response = await http.patch(
      Uri.parse(Apiurls.react(id)),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'emoji': emoji}),
    );

    final Map<String, dynamic> json = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Assuming it returns the updated blog data
      return BlogData.fromJson(json['data'] ?? json);
    } else {
      throw Exception(
        json['message'] ?? 'Failed to react to blog (${response.statusCode})',
      );
    }
  }

  /// GET /api/blogs/categories
  Future<List<String>> getCategories() async {
    final response = await http.get(
      Uri.parse(Apiurls.categories),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return List<String>.from(decoded);
      } else if (decoded is Map && decoded.containsKey('categories')) {
        return List<String>.from(decoded['categories']);
      } else if (decoded is Map && decoded.containsKey('data')) {
        final data = decoded['data'];
        if (data is List) return List<String>.from(data);
        if (data is Map && data.containsKey('categories')) {
          return List<String>.from(data['categories']);
        }
      }
      return [];
    } else {
      throw Exception('Failed to fetch categories (${response.statusCode})');
    }
  }
}
