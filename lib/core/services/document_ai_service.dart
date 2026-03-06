// ═══════════════════════════════════════════════════════════════════════════════
// DOCUMENT AI SERVICE — Gemini Vision API for document data extraction
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../config/ai_config.dart';
import '../../models/cvi_document_model.dart';

class DocumentAIService {
  // ────────────────────────────────────────────────────────────────────────────
  // EXTRACT FROM BYTES (Main entry point)
  // ────────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> extractFromDocumentBytes({
    required Uint8List imageBytes,
    required String documentType,
  }) async {
    return _extractFromImage(
      imageBytes: imageBytes,
      documentType: documentType,
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // GEMINI EXTRACTION LOGIC
  // ────────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> _extractFromImage({
    required Uint8List imageBytes,
    required String documentType,
  }) async {
    try {
      // Step 1: Compress image to under 800KB
      Uint8List compressed = imageBytes;
      
      if (imageBytes.length > 800000) {
        final result = await FlutterImageCompress.compressWithList(
          imageBytes,
          quality: 70,
          minWidth: 1024,
          minHeight: 1024,
        );
        if (result != null) compressed = result;
      }

      // Step 2: Compress more if still too large
      if (compressed.length > 900000) {
        final result = await FlutterImageCompress.compressWithList(
          compressed,
          quality: 50,
          minWidth: 800,
          minHeight: 800,
        );
        if (result != null) compressed = result;
      }

      // Step 3: Convert to base64 (No prefix, just raw base64)
      final base64Image = base64Encode(compressed);

      // Step 4: Build extraction prompt
      final prompt = _buildPrompt(documentType);

      // Step 5: Call Gemini API (FREE, supports images)
      final uri = Uri.parse(
        '${AIConfig.geminiUrl}?key=${AIConfig.geminiApiKey}',
      );

      debugPrint('DocumentAI: Sending request to Gemini for $documentType...');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image,
                  },
                },
                {
                  'text': prompt,
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 1024,
          },
        }),
      ).timeout(const Duration(seconds: 45));

      // Step 6: Parse response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Extract text from Gemini response format
        final text = data['candidates']?[0]['content']['parts']?[0]['text'] as String? ?? '';
        
        debugPrint('Gemini raw response: $text');

        // Find JSON in the response
        final jsonStart = text.indexOf('{');
        final jsonEnd = text.lastIndexOf('}') + 1;
        
        if (jsonStart != -1 && jsonEnd > jsonStart) {
          final jsonStr = text.substring(jsonStart, jsonEnd);
          try {
            final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
            
            // Robust confidence check
            if (parsed['confidence'] == null && parsed['confidence_score'] != null) {
              parsed['confidence'] = parsed['confidence_score'];
            }
            
            debugPrint('Extraction success: $parsed');
            return parsed;
          } catch (e) {
            debugPrint('DocumentAI: JSON parsing error: $e');
            return {'error': 'Invalid JSON in AI response', 'confidence': 0.0};
          }
        }
        
        return {
          'error': 'No JSON found in response',
          'confidence': 0.0,
        };

      } else {
        debugPrint('Gemini Error ${response.statusCode}');
        debugPrint('Gemini Error body: ${response.body}');
        return {
          'error': 'Gemini error ${response.statusCode}',
          'confidence': 0.0,
        };
      }

    } catch (e) {
      debugPrint('Extraction exception: $e');
      return {
        'error': e.toString(),
        'confidence': 0.0,
      };
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // GEMINI PROMPTS
  // ────────────────────────────────────────────────────────────────────────────

  static String _buildPrompt(String documentType) {
    const base = '''
You are reading an Indian government document image.
Extract all visible text fields from this document.
Return ONLY a valid JSON object. No explanation.
No markdown. No code blocks. Just raw JSON.
If a field is not visible write null.
Add a confidence field between 0.0 and 1.0.
Mask sensitive numbers:
  Aadhaar: show only last 4 as XXXX XXXX 1234
  Bank account: show only last 4 as XXXXXXXX1234
''';

    switch (documentType) {
      case 'aadhaar':
        return '$base\nReturn this JSON:\n'
          '{"full_name":"name in English",'
          '"full_name_hindi":"name in Hindi if visible",'
          '"date_of_birth":"DD/MM/YYYY",'
          '"gender":"Male or Female",'
          '"aadhaar_number":"XXXX XXXX 1234",'
          '"address_line1":"house and street",'
          '"address_line2":"area or locality",'
          '"village":"village name or null",'
          '"district":"district name",'
          '"state":"state name",'
          '"pincode":"6 digit pincode",'
          '"confidence":0.95}';

      case 'pan':
        return '$base\nReturn this JSON:\n'
          '{"full_name":"name as on PAN",'
          '"father_name":"father name",'
          '"date_of_birth":"DD/MM/YYYY",'
          '"pan_number":"ABCDE1234F",'
          '"confidence":0.95}';

      case 'passport':
        return '$base\nReturn this JSON:\n'
          '{"full_name":"full name",'
          '"passport_number":"A1234567",'
          '"date_of_birth":"DD/MM/YYYY",'
          '"date_of_expiry":"DD/MM/YYYY",'
          '"place_of_birth":"city",'
          '"father_name":"father name",'
          '"mother_name":"mother name",'
          '"spouse_name":"spouse name or null",'
          '"address_line1":"address",'
          '"pincode":"pincode",'
          '"confidence":0.95}';

      case 'voter_id':
      case 'voterID':
        return '$base\nReturn this JSON:\n'
          '{"full_name":"name",'
          '"father_name":"father or husband name",'
          '"date_of_birth":"DD/MM/YYYY",'
          '"gender":"Male or Alternative",'
          '"voter_id_number":"EPIC number",'
          '"district":"district",'
          '"state":"state",'
          '"confidence":0.95}';

      case 'driving_license':
      case 'drivingLicense':
        return '$base\nReturn this JSON:\n'
          '{"full_name":"name",'
          '"date_of_birth":"DD/MM/YYYY",'
          '"driving_license_number":"DL number",'
          '"blood_group":"blood group or null",'
          '"address_line1":"address",'
          '"state":"state",'
          '"date_of_expiry":"DD/MM/YYYY",'
          '"confidence":0.95}';

      case 'bank_passbook':
      case 'bankPassbook':
        return '$base\nReturn this JSON:\n'
          '{"full_name":"account holder name",'
          '"account_number":"XXXXXXXX1234",'
          '"bank_name":"bank name",'
          '"branch_name":"branch name",'
          '"ifsc_code":"IFSC code",'
          '"confidence":0.95}';

      case 'income_certificate':
      case 'incomeCertificate':
        return '$base\nReturn this JSON:\n'
          '{"full_name":"name",'
          '"father_name":"father name",'
          '"annual_income":"amount in numbers",'
          '"district":"district",'
          '"state":"state",'
          '"certificate_number":"number",'
          '"confidence":0.95}';

      case 'ration_card':
      case 'rationCard':
        return '$base\nReturn this JSON:\n'
          '{"full_name":"head of family name",'
          '"ration_card_number":"number",'
          '"address_line1":"address",'
          '"district":"district",'
          '"state":"state",'
          '"confidence":0.95}';

      default:
        return '$base\nExtract all visible fields '
          'and return as JSON with confidence score.';
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // MERGE EXTRACTED DATA (Keep existing logic for compatibility)
  // ────────────────────────────────────────────────────────────────────────────

  static ExtractedUserData mergeExtractedData(List<CVIDocument> documents) {
    String? pick(String key) {
      for (final doc in documents) {
        final val = doc.extractedData[key];
        if (val != null && val.toString().isNotEmpty && val != 'null') {
          return val.toString();
        }
      }
      return null;
    }

    DateTime? parseDate(String? raw) {
      if (raw == null) return null;
      try {
        final parts = raw.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
        return DateTime.tryParse(raw);
      } catch (_) {
        return DateTime.tryParse(raw);
      }
    }

    final data = ExtractedUserData();
    data.fullName = pick('full_name') ?? pick('fullName');
    data.fatherName = pick('father_name') ?? pick('fatherName');
    data.motherName = pick('mother_name') ?? pick('motherName');
    data.spouseName = pick('spouse_name') ?? pick('spouseName');
    data.dateOfBirth = parseDate(pick('date_of_birth') ?? pick('dateOfBirth'));
    data.gender = pick('gender');
    data.bloodGroup = pick('blood_group') ?? pick('bloodGroup');
    data.aadhaarNumber = pick('aadhaar_number') ?? pick('aadhaarNumber');
    data.panNumber = pick('pan_number') ?? pick('panNumber');
    data.passportNumber = pick('passport_number') ?? pick('passportNumber');
    data.voterIdNumber = pick('voter_id_number') ?? pick('voterIdNumber') ?? pick('voter_id_number');
    data.drivingLicenseNumber =
        pick('driving_license_number') ?? pick('drivingLicenseNumber') ?? pick('driving_license_number');
    data.addressLine1 = pick('address_line1') ?? pick('addressLine1');
    data.addressLine2 = pick('address_line2') ?? pick('addressLine2');
    data.district = pick('district');
    data.state = pick('state');
    data.pincode = pick('pincode');
    return data;
  }
}
