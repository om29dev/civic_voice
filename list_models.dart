import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = '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'; 
  final url = Uri.parse('https://api.groq.com/openai/v1/models');

  try {
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $apiKey'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> models = data['data'];
      print('Available Models:');
      for (var model in models) {
        print('- ${model['id']}');
      }
    } else {
      print('Error: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Exception: $e');
  }
}
