import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // Test the key found in list_models.dart
  const apiKey = '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';
  
  print("Testing Backup API Key: ${apiKey.substring(0, 10)}...");

  final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
  
  try {
     final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile', 
          'messages': [
            {'role': 'user', 'content': 'Test'}
          ],
          'max_tokens': 5,
        }),
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");
      
  } catch (e) {
    print("Exception: $e");
  }
}
