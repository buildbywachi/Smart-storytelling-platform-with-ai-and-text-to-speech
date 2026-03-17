import 'dart:convert';
import 'package:http/http.dart' as http;


class ApiService {
  
  static const String baseUrl = 'http://10.0.2.2:8000'; 

  static Future<Map<String, dynamic>> generateStory(String topic, String voice) async {
    try {
      
      final url = Uri.parse('$baseUrl/generate'); 

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"topic": topic, "voice": voice}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          "story": data['story'] ?? "ไม่พบเนื้อเรื่อง",
          "audio": data['audio']
        };
      } else {
        return {"story": "Error: ${response.statusCode}", "audio": null};
      }
    } catch (e) {
      return {"story": "Error: เชื่อมต่อไม่ได้ ($e)", "audio": null};
    }
  }
}