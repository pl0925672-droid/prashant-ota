import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService {
  // New stable API Key
  final String _apiKey = 'AIzaSyBsPfbze1YxXhFsFAa_hp8HClP5fDapAy8';

  Future<String> getStudyHelp(String query) async {
    final String instruction = "Your name is Prashant. You are a professional study assistant. Answer clearly in Hinglish. If someone asks for your name, always say your name is Prashant.";

    // Using v1 endpoint for guaranteed stability
    final String url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{
            "parts": [{"text": "$instruction\n\nQuestion: $query"}]
          }]
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        }
      }
      return "AI (Prashant) is busy. Please try again in a moment.";
    } catch (e) {
      return "Prashant could not connect. Check your internet.";
    }
  }
}
