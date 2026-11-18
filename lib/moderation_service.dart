import 'dart:convert';
import 'package:http/http.dart' as http;

// ----------------- Backend Response Model & JSON Parsing -----------------
class ModerationResult {
  final bool allowed;
  final String reason;
  final dynamic detail;

  ModerationResult({
    required this.allowed, //required
    required this.reason,
    this.detail, //optional
  });

  factory ModerationResult.fromJson(Map<String, dynamic> json) {
    return ModerationResult(
      allowed: json['allowed'] == true, // Only true is considered allowed
      reason: (json['reason'] ?? 'none').toString(), // // Use 'none' if reason is null(??)
      detail: json['detail'],
    );
  }
}

class ModerationService {
    static const String baseUrl = 'http://localhost:8000'; //backend server

// Sends a message to the backend for moderation
  static Future<ModerationResult> checkMessage(String text) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/check-message'), // Specifies the API endpoint
          headers: {'Content-Type': 'application/json'}, // Sets the request content type to JSON
          body: jsonEncode({'text': text}), // Converts the message into JSON format before sending
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) { //reques successful
      final Map<String, dynamic> data = jsonDecode(response.body); // Converts the JSON response into a Dart Map
      return ModerationResult.fromJson(data); // Converts the JSON data into a ModerationResult object
    } else {
      throw Exception('Server returned status code: ${response.statusCode}'); // Throws an exception if the server request fails
    }
  }
}