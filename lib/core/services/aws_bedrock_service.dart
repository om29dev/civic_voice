import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../config/ai_config.dart';

class AWSBedrockService {
  static const String _region = AIConfig.bedrockRegion;


  // In-memory cache for Bedrock responses (cost & latency optimization)
  static final Map<String, _CachedResponse> _responseCache = {};

  static String _generateCacheKey(String modelId, Map<String, dynamic> body) {
    final raw = '$modelId:${jsonEncode(body)}';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  /// Invokes a Bedrock model with SigV4 signing.
  /// Zero-Trust Enforced: Requires a verified Cognito user session.
  static Future<Map<String, dynamic>> invokeModel({
    required String modelId,
    required Map<String, dynamic> body,
    String api = 'invoke',
  }) async {
    // 1. Check cache first to optimize AWS resource utilization
    final cacheKey = _generateCacheKey(modelId, body);
    final cached = _responseCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      debugPrint('Bedrock: Serving from memory cache ($cacheKey)');
      return cached.data;
    }

    try {
      // 2. Zero-Trust Authenticated Session Check
      final session =
          await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;

      if (!session.isSignedIn) {
        throw const AuthRequiredException(
          'Authentication required: Please sign in with your Citizen Account to access Amazon Bedrock.',
        );
      }

      final creds = session.credentialsResult.value;
      final accessKeyId = creds.accessKeyId;
      final secretAccessKey = creds.secretAccessKey;
      final sessionToken = creds.sessionToken;

      final signer = AWSSigV4Signer(
        credentialsProvider: AWSCredentialsProvider(
          AWSCredentials(
            accessKeyId,
            secretAccessKey,
            sessionToken,
          ),
        ),
      );

      final scope = AWSCredentialScope(
        region: _region,
        service: AWSService.bedrock,
      );

      // 2. Build the request
      final endpoint = 'bedrock-runtime.$_region.amazonaws.com';
      // Bedrock requires the modelId to be percent-encoded in the path for signing (specifically the colon)
      final encodedModelId = Uri.encodeComponent(modelId);
      final path = '/model/$encodedModelId/$api';
      final bodyBytes = utf8.encode(jsonEncode(body));

      final request = AWSHttpRequest.post(
        Uri.parse('https://$endpoint$path'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Amz-Content-Sha256': hex.encode(sha256.convert(bodyBytes).bytes),
        },
        body: bodyBytes,
      );

      // 3. Sign and Send
      debugPrint('Bedrock: Requesting $modelId at $endpoint$path');
      final signedRequest = await signer.sign(
        request,
        credentialScope: scope,
        serviceConfiguration: const BaseServiceConfiguration(
          signBody: true,
        ),
      );

      final client = AWSHttpClient();
      final operation = client.send(signedRequest);
      final response = await operation.response;

      final responseBody = await response.decodeBody();
      debugPrint('Bedrock Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('Bedrock Success Result: $responseBody');
        final parsed = jsonDecode(responseBody) as Map<String, dynamic>;
        _responseCache[cacheKey] = _CachedResponse(data: parsed, timestamp: DateTime.now());
        return parsed;
      } else {
        final errorMsg = 'Bedrock Error ${response.statusCode}: $responseBody';
        debugPrint(errorMsg);
        throw Exception(errorMsg);
      }
    } catch (e, stack) {
      debugPrint('Bedrock Service Exception: $e');
      debugPrint('Stack trace: $stack');
      rethrow;
    }
  }

  /// Specialized helper for Amazon Nova Micro (Cheapest text model on Bedrock: ~$0.035/1M in, $0.14/1M out)
  static Future<String> chatWithNovaMicro(
    String prompt, {
    double temperature = 0.5,
    String? systemPrompt,
  }) async {
    // Strip any Llama-specific markup tokens if passed from legacy formatters
    final cleanPrompt = prompt.replaceAll(RegExp(r'<\|[a-z_]+\|>'), '').trim();

    final body = {
      if (systemPrompt != null && systemPrompt.isNotEmpty)
        "system": [
          {"text": systemPrompt}
        ],
      "messages": [
        {
          "role": "user",
          "content": [
            {"text": cleanPrompt}
          ]
        }
      ],
      "inferenceConfig": {
        "maxTokens": 512,
        "temperature": temperature,
        "topP": 0.9,
      }
    };

    final result = await invokeModel(
      modelId: AIConfig.bedrockNovaMicro,
      body: body,
      api: 'converse',
    );

    final output = result['output'];
    if (output != null && output['message'] != null) {
      final content = output['message']['content'] as List?;
      if (content != null) {
        for (final item in content) {
          if (item is Map && item.containsKey('text')) {
            String text = item['text'] as String;
            return text.replaceAll(RegExp(r'<\|[a-z_]+\|>'), '').trim();
          }
        }
      }
    }

    return '';
  }

  /// Backward-compatible helper that routes to Amazon Nova Micro
  static Future<String> chatWithLlama3(String prompt,
      {double temperature = 0.5}) async {
    return chatWithNovaMicro(prompt, temperature: temperature);
  }

  /// Specialized helper for Document Extraction using Multimodal Vision (Converse API)
  static Future<Map<String, dynamic>> extractWithVision({
    required String prompt,
    required Uint8List imageBytes,
    String? systemPrompt,
    String? modelId,
    String mimeType = 'image/jpeg',
  }) async {
    final format = mimeType.split('/').last; // e.g., 'jpeg', 'png'
    final validFormats = ['jpeg', 'png', 'gif', 'webp'];
    final safeFormat = validFormats.contains(format) ? format : 'jpeg';

    final body = {
      if (systemPrompt != null)
        "system": [
          {"text": systemPrompt}
        ],
      "messages": [
        {
          "role": "user",
          "content": [
            {
              "image": {
                "format": safeFormat,
                "source": {"bytes": base64Encode(imageBytes)}
              }
            },
            {"text": prompt}
          ]
        }
      ],
      "inferenceConfig": {
        "maxTokens": 2048,
        "temperature": 0.0,
        "topP": 0.9,
      }
    };

    final result = await invokeModel(
      modelId: modelId ?? AIConfig.bedrockNovaLite,
      body: body,
      api: 'converse',
    );

    // Converse API response structure: output.message.content[{text: ...}]
    final output = result['output'];
    if (output != null && output['message'] != null) {
      final content = output['message']['content'] as List;

      // Robust search for the text block in the content list
      String? text;
      for (final item in content) {
        if (item is Map && item.containsKey('text')) {
          text = item['text'] as String;
          break;
        }
      }

      if (text != null) {
        // Parse JSON from text - handle markdown markers or preambles
        try {
          final jsonStart = text.indexOf('{');
          final jsonEnd = text.lastIndexOf('}') + 1;
          if (jsonStart != -1 && jsonEnd > jsonStart) {
            final jsonStr = text.substring(jsonStart, jsonEnd);
            final Map<String, dynamic> parsed =
                jsonDecode(jsonStr) as Map<String, dynamic>;

            // Robust numeric normalization (Convert string numbers to doubles)
            parsed.forEach((key, value) {
              if (value is String) {
                final double? d = double.tryParse(value);
                if (d != null &&
                    (key == 'confidence' || key.contains('score'))) {
                  parsed[key] = d;
                }
              }
            });

            return parsed;
          }
        } catch (e) {
          debugPrint('JSON Parse Error: $e in text: $text');
        }
      }
    }

    throw Exception(
        'Failed to extract valid JSON from Vision response: $result');
  }
}

class AuthRequiredException implements Exception {
  final String message;
  const AuthRequiredException(this.message);
  @override
  String toString() => message;
}

class _CachedResponse {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  _CachedResponse({required this.data, required this.timestamp});
  bool get isExpired =>
      DateTime.now().difference(timestamp) > const Duration(minutes: 30);
}
