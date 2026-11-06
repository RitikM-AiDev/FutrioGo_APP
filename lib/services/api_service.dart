import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/api_keys.dart';

class ApiResult {
  final String text;
  final String? url;
  final bool hasUrl;

  const ApiResult({
    required this.text,
    this.url,
    this.hasUrl = false,
  });
}

class ApiService {
  static const String queryEndpoint =
      'https://futrio-go-backend.onrender.com/api/ask/automate/query/adhd/sjds/user';

  static const String transcribeEndpoint =
      'https://futrio-go-backend.onrender.com/api/admin/futrio/transcribe/at/live/244/futrio';

  /// Sends a text query to the backend and handles external actions (like YouTube / search URLs)
  static Future<ApiResult> sendQuery({
    required String query,
    required ApiKeys keys,
  }) async {
    final response = await http.post(
      Uri.parse(queryEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': keys.gemini,
        'X-Tavily-Key': keys.tavily,
        'X-Serper-Key': keys.serper,
      },
      body: jsonEncode({'query': query.trim()}),
    );

    return _processResponse(response);
  }

  /// Sends a recorded audio file to the transcription endpoint
  static Future<ApiResult> sendAudio({
    required String audioPath,
    required ApiKeys keys,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(transcribeEndpoint),
    );

    request.headers.addAll({
      'X-Groq-Key': keys.groq,
      'X-API-Key': keys.gemini,
      'X-Tavily-Key': keys.tavily,
      'X-Serper-Key': keys.serper,
    });

    final fileExtension = audioPath.split('.').last.toLowerCase();

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        audioPath,
        filename: 'recording.$fileExtension',
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _processResponse(response);
  }

  /// Parses JSON response, opens URL externally if present, and extracts clean text
  static Future<ApiResult> _processResponse(http.Response response) async {
    dynamic data;
    try {
      data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    } catch (_) {
      data = {'response': response.body};
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorMsg = data is Map
          ? (data['detail'] ?? data['message'] ?? data['error'] ?? 'Request failed (${response.statusCode})')
          : 'Request failed (${response.statusCode})';
      throw Exception(errorMsg);
    }

    String? actionUrl;
    if (data is Map && data['url'] != null) {
      final rawUrl = data['url'].toString().trim();
      if (rawUrl.isNotEmpty && rawUrl != 'None') {
        actionUrl = rawUrl;
        // Launch directly in external app (YouTube, Chrome, etc.)
        await launchExternalUrl(actionUrl);
      }
    }

    final replyText = _extractReplyText(data);
    return ApiResult(
      text: replyText,
      url: actionUrl,
      hasUrl: actionUrl != null,
    );
  }

  /// Extracts the assistant's reply without raw URL badges
  static String _extractReplyText(dynamic data) {
    if (data is String) return data;
    if (data is Map) {
      final reply = data['response'] ??
          data['answer'] ??
          data['message'] ??
          data['result'] ??
          data['reply'];
      if (reply != null && reply is String) return reply;
      return jsonEncode(data);
    }
    return data?.toString() ?? '';
  }

  /// Direct intent launcher for external applications (YouTube, Web, etc.)
  static Future<bool> launchExternalUrl(String rawUrl) async {
    try {
      var urlStr = rawUrl.trim();
      if (urlStr.isEmpty || urlStr == 'None') return false;

      if (!urlStr.startsWith('http://') &&
          !urlStr.startsWith('https://') &&
          !urlStr.startsWith('vnd.youtube:')) {
        urlStr = 'https://$urlStr';
      }

      final uri = Uri.parse(urlStr);
      // Attempt external application launch (e.g. YouTube app directly)
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      return launched;
    } catch (e) {
      return false;
    }
  }
}
