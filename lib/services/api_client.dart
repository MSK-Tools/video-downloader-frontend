import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiClient {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS simulator/desktop
  static String get baseUrl {
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {}
    return 'http://localhost:8000';
  }

  static Future<Map<String, dynamic>> analyzeUrl(String url) async {
    try {
      final uri = Uri.parse('$baseUrl/api/downloads/analyze/');
      print('🔗 Analyzing URL at: $uri');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url}),
      ).timeout(const Duration(seconds: 10));
      print('✅ Analyze response: ${response.statusCode}');
      return _processResponse(response);
    } catch (e) {
      print('❌ Analyze error: $e');
      return {'error': 'Network error: Please make sure backend is running.'};
    }
  }

  static Future<Map<String, dynamic>> triggerDownload({
    required String url,
    required String videoId,
    required String title,
    required String thumbnailUrl,
    required String format,
    required String quality,
    required int fileSize,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/downloads/download/');
      print('🔗 Triggering download at: $uri');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'url': url,
          'video_id': videoId,
          'title': title,
          'thumbnail_url': thumbnailUrl,
          'format': format,
          'quality': quality,
          'file_size': fileSize,
        }),
      ).timeout(const Duration(seconds: 10));
      print('✅ Download response: ${response.statusCode}');
      final result = _processResponse(response);
      
      // Extract download URL for client-side saving if provided by backend
      if (result['download_url'] != null) {
        print('📥 Download URL from backend: ${result['download_url']}');
      }
      
      return result;
    } catch (e) {
      print('❌ Download error: $e');
      return {'error': 'Network error: Failed to trigger download.'};
    }
  }

  static Future<List<dynamic>> fetchQueue() async {
    try {
      final uri = Uri.parse('$baseUrl/api/downloads/queue/');
      print('🔗 Fetching queue at: $uri');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        print('✅ Queue response: ${response.statusCode}');
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (e) {
      print('❌ Queue error: $e');
    }
    return [];
  }

  static Future<List<dynamic>> fetchHistory() async {
    try {
      final uri = Uri.parse('$baseUrl/api/downloads/history/');
      print('🔗 Fetching history at: $uri');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        print('✅ History response: ${response.statusCode}');
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (e) {
      print('❌ History error: $e');
    }
    return [];
  }

  static Future<bool> pauseDownload(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/api/downloads/queue/$id/pause/');
      print('🔗 Pausing download at: $uri');
      final response = await http.post(uri).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Pause error: $e');
    }
    return false;
  }

  static Future<bool> resumeDownload(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/api/downloads/queue/$id/resume/');
      print('🔗 Resuming download at: $uri');
      final response = await http.post(uri).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Resume error: $e');
    }
    return false;
  }

  static Future<bool> deleteDownload(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/api/downloads/queue/$id/delete/');
      print('🔗 Deleting download at: $uri');
      final response = await http.delete(uri).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Delete error: $e');
    }
    return false;
  }

  static Future<Map<String, dynamic>> loginUser(String email, String name, bool isGoogle) async {
    try {
      final uri = Uri.parse('$baseUrl/api/accounts/login/');
      print('🔗 Logging in at: $uri with email=$email');
      print('📱 Using base URL: $baseUrl');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'name': name,
          'is_google': isGoogle,
        }),
      ).timeout(const Duration(seconds: 10));
      print('✅ Login response: ${response.statusCode}');
      print('📦 Login body: ${response.body}');
      return _processResponse(response);
    } catch (e) {
      print('❌ Login error: $e');
      return {'error': 'Login failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> fetchSubscriptionPlans() async {
    try {
      final uri = Uri.parse('$baseUrl/api/subscriptions/plans/');
      print('🔗 Fetching plans at: $uri');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      print('✅ Plans response: ${response.statusCode}');
      return _processResponse(response);
    } catch (e) {
      print('❌ Plans error: $e');
      return {'plans': []};
    }
  }

  static Future<Map<String, dynamic>> purchasePlan(String planId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/subscriptions/purchase/');
      print('🔗 Purchasing plan at: $uri');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'plan_id': planId}),
      ).timeout(const Duration(seconds: 10));
      print('✅ Purchase response: ${response.statusCode}');
      return _processResponse(response);
    } catch (e) {
      print('❌ Purchase error: $e');
      return {'success': false, 'error': 'Purchase failed: $e'};
    }
  }

  static Future<void> logAnalyticsEvent(String eventName, Map<String, dynamic> params) async {
    try {
      final uri = Uri.parse('$baseUrl/api/analytics/log-event/');
      print('🔗 Logging event at: $uri');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'event_name': eventName,
          'parameters': params,
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      print('❌ Analytics error: $e');
    }
  }

  static Map<String, dynamic> _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      try {
        final errBody = jsonDecode(response.body);
        return {'error': errBody['error'] ?? 'Server error'};
      } catch (_) {
        return {'error': 'Unexpected response from server: ${response.statusCode}'};
      }
    }
  }
}
