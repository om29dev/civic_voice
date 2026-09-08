import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';

class _AWSTemporaryCredentials {
  final String accessKeyId;
  final String secretAccessKey;
  final String sessionToken;
  final DateTime expiration;

  _AWSTemporaryCredentials({
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.sessionToken,
    required this.expiration,
  });

  bool get isValid =>
      DateTime.now().isBefore(expiration.subtract(const Duration(minutes: 5)));
}

class AWSBedrockService {
  static const String _region = AIConfig.bedrockRegion;

  // Cognito & STS configuration for Guest (Unauthenticated) Bedrock Access
  static const String _cognitoRegion = 'ap-south-1';
  static const String _identityPoolId =
      'ap-south-1:b2b7786b-f8e2-47b9-b246-e87480016a8d';
  static const String _unauthRoleArn =
      'arn:aws:iam::742435394268:role/amplify-civicvoice-dev-71deb-unauthRole';

  static _AWSTemporaryCredentials? _cachedGuestCreds;

  /// Fetches guest credentials using Cognito OpenID Token + STS AssumeRoleWithWebIdentity
  /// (Classic Auth Flow). This flow bypasses Cognito's restrictive guest session policy,
  /// granting full unauthRole Bedrock permissions without requiring the user to sign in.
  static Future<_AWSTemporaryCredentials> _fetchGuestCredentials() async {
    if (_cachedGuestCreds != null && _cachedGuestCreds!.isValid) {
      return _cachedGuestCreds!;
    }

    debugPrint(
        'Bedrock: Obtaining fresh guest credentials via STS Classic Flow...');

    // 1. Get Identity ID from Cognito
    final idResponse = await http.post(
      Uri.parse('https://cognito-identity.$_cognitoRegion.amazonaws.com/'),
      headers: {
        'Content-Type': 'application/x-amz-json-1.1',
        'X-Amz-Target': 'AWSCognitoIdentityService.GetId',
      },
      body: jsonEncode({'IdentityPoolId': _identityPoolId}),
    );

    if (idResponse.statusCode != 200) {
      throw Exception('Failed to get Cognito Identity ID: ${idResponse.body}');
    }

    final idData = jsonDecode(idResponse.body) as Map<String, dynamic>;
    final identityId = idData['IdentityId'] as String;

    // 2. Get OpenID Token from Cognito
    final tokenResponse = await http.post(
      Uri.parse('https://cognito-identity.$_cognitoRegion.amazonaws.com/'),
      headers: {
        'Content-Type': 'application/x-amz-json-1.1',
        'X-Amz-Target': 'AWSCognitoIdentityService.GetOpenIdToken',
      },
      body: jsonEncode({'IdentityId': identityId}),
    );

    if (tokenResponse.statusCode != 200) {
      throw Exception(
          'Failed to get Cognito OpenId Token: ${tokenResponse.body}');
    }

    final tokenData = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
    final openIdToken = tokenData['Token'] as String;

    // 3. Assume unauthRole using STS AssumeRoleWithWebIdentity
    final stsResponse = await http.post(
      Uri.parse('https://sts.$_cognitoRegion.amazonaws.com/'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'Action': 'AssumeRoleWithWebIdentity',
        'Version': '2011-06-15',
        'RoleArn': _unauthRoleArn,
        'RoleSessionName': 'civicvoice-guest',
        'WebIdentityToken': openIdToken,
        'DurationSeconds': '3600',
      },
    );

    if (stsResponse.statusCode != 200) {
      throw Exception(
          'Failed to assume unauth role via STS: ${stsResponse.body}');
    }

    final xml = stsResponse.body;
    final accessKeyId =
        RegExp(r'<AccessKeyId>(.*?)</AccessKeyId>').firstMatch(xml)?.group(1);
    final secretAccessKey = RegExp(r'<SecretAccessKey>(.*?)</SecretAccessKey>')
        .firstMatch(xml)
        ?.group(1);
    final sessionToken =
        RegExp(r'<SessionToken>(.*?)</SessionToken>').firstMatch(xml)?.group(1);
    final expirationStr =
        RegExp(r'<Expiration>(.*?)</Expiration>').firstMatch(xml)?.group(1);

    if (accessKeyId == null || secretAccessKey == null || sessionToken == null) {
      throw Exception('Could not parse STS credentials from response: $xml');
    }

    final expiration = expirationStr != null
        ? DateTime.tryParse(expirationStr) ??
            DateTime.now().add(const Duration(hours: 1))
        : DateTime.now().add(const Duration(hours: 1));

    _cachedGuestCreds = _AWSTemporaryCredentials(
      accessKeyId: accessKeyId,
      secretAccessKey: secretAccessKey,
      sessionToken: sessionToken,
      expiration: expiration,
    );

    debugPrint('Bedrock: Guest credentials cached successfully.');
    return _cachedGuestCreds!;
  }

  /// Invokes a Bedrock model with SigV4 signing.
  /// Works for both signed-in users AND anonymous guest users.
  static Future<Map<String, dynamic>> invokeModel({
    required String modelId,
    required Map<String, dynamic> body,
    String api = 'invoke',
  }) async {
    try {
      // 1. Get AWS Credentials (from logged in user or classic guest flow)
      final session =
          await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;

      String accessKeyId;
      String secretAccessKey;
      String? sessionToken;

      if (session.isSignedIn) {
        final creds = session.credentialsResult.value;
        accessKeyId = creds.accessKeyId;
        secretAccessKey = creds.secretAccessKey;
        sessionToken = creds.sessionToken;
      } else {
        // Guest mode: Obtain STS credentials via Classic Flow to bypass Cognito session policy
        final guestCreds = await _fetchGuestCredentials();
        accessKeyId = guestCreds.accessKeyId;
        secretAccessKey = guestCreds.secretAccessKey;
        sessionToken = guestCreds.sessionToken;
      }

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
        return jsonDecode(responseBody) as Map<String, dynamic>;
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
