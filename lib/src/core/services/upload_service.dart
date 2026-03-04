import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:write_up/app/utils/apiurls.dart';

class UploadService {
  /// POST /api/upload/image
  /// Uploads a single image file (field name: "file").
  Future<String?> uploadSingleImage(File file, {String? token}) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(Apiurls.uploadSingle),
    );

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final String extension = file.path.split('.').last.toLowerCase();
    final String contentType = extension == 'png' ? 'image/png' : 'image/jpeg';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType.parse(contentType),
      ),
    );

    final urls = await _send(request);
    return urls.isNotEmpty ? urls.first : null;
  }

  /// DELETE /api/upload/delete
  /// Deletes a file from storage.
  Future<void> deleteFile(String url, {String? token}) async {
    final response = await http.delete(
      Uri.parse(Apiurls.deleteFile),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'url': url}),
    );

    if (response.statusCode != 200) {
      try {
        final json = jsonDecode(response.body);
        throw Exception(json['message'] ?? 'Delete failed');
      } catch (_) {
        throw Exception('Delete failed with status: ${response.statusCode}');
      }
    }
  }

  Future<List<String>> _send(http.MultipartRequest request) async {
    request.headers['Accept'] = 'application/json';
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    // Check if response is JSON
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      final bodySnippet = response.body.length > 200
          ? '${response.body.substring(0, 200)}...'
          : response.body;
      throw Exception('Upload failed (${response.statusCode}): $bodySnippet');
    }

    final Map<String, dynamic> json = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic data = json['data'] ?? json['urls'] ?? json['url'];
      if (data is List) {
        return List<String>.from(data);
      }
      if (data is String) return [data];
      return [];
    } else {
      throw Exception(
        json['message'] ?? 'Upload failed (${response.statusCode})',
      );
    }
  }
}
