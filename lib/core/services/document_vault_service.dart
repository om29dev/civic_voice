// ═══════════════════════════════════════════════════════════════════════════════
// DOCUMENT VAULT SERVICE — Supabase-backed document storage + AI extraction
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'document_ai_service.dart';

class DocumentVaultService {
  static final _supabase = Supabase.instance.client;
  static const _bucketName = 'user-documents';

  // ────────────────────────────────────────────────────────────────────────────
  // UPLOAD DOCUMENT — compress → upload to storage → AI extract → save metadata
  // ────────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> uploadDocument({
    required Uint8List imageBytes,
    required String documentType,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      // Step 1: Image usage (already compressed by provider or handled by AI service)
      // We'll keep a basic compression here just for Supabase storage size if needed,
      // but the user's Step 3 handles it in the AI service too.
      // Let's ensure it's under 1MB for storage.

      // Step 2: Upload to Supabase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${documentType}_$timestamp.jpg';
      final filePath = '$userId/$fileName';

      await _supabase.storage.from(_bucketName).uploadBinary(
            filePath,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // Step 3: AI extraction via Gemini
      final extractedData = await DocumentAIService.extractFromDocumentBytes(
        imageBytes: imageBytes,
        documentType: documentType,
      );

      final confidence =
          (extractedData['confidence'] as num?)?.toDouble() ?? 0.0;

      // Step 4: Save document metadata to user_documents table
      await _supabase.from('user_documents').insert({
        'user_id': userId,
        'document_type': documentType,
        'file_name': fileName,
        'file_path': filePath,
        'file_size': imageBytes.length,
        'is_verified': confidence > 0.6,
        'confidence_score': confidence,
        'extracted_fields': extractedData,
      });

      // Step 5: Merge extracted data into user_extracted_data
      await _mergeExtractedData(
        userId: userId,
        extractedData: extractedData,
      );

      return {
        'success': true,
        'confidence': confidence,
        'extractedData': extractedData,
        'filePath': filePath,
      };
    } catch (e) {
      debugPrint('DocumentVault: Upload error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // MERGE EXTRACTED DATA INTO user_extracted_data (upsert, only fill nulls)
  // ────────────────────────────────────────────────────────────────────────────

  static Future<void> _mergeExtractedData({
    required String userId,
    required Map<String, dynamic> extractedData,
  }) async {
    // Fetch existing row for this user
    final existing = await _supabase
        .from('user_extracted_data')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    final Map<String, dynamic> updateData = {
      'user_id': userId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Map extracted JSON keys to database column names
    const fieldMapping = {
      'full_name': 'full_name',
      'full_name_hindi': 'full_name_hindi',
      'father_name': 'father_name',
      'mother_name': 'mother_name',
      'spouse_name': 'spouse_name',
      'date_of_birth': 'date_of_birth',
      'gender': 'gender',
      'blood_group': 'blood_group',
      'aadhaar_number': 'aadhaar_number',
      'pan_number': 'pan_number',
      'passport_number': 'passport_number',
      'voter_id_number': 'voter_id_number',
      'driving_license_number': 'driving_license_number',
      'address_line1': 'address_line1',
      'address_line2': 'address_line2',
      'village': 'village',
      'tehsil': 'tehsil',
      'district': 'district',
      'state': 'state',
      'pincode': 'pincode',
      'mobile_number': 'mobile_number',
      'email_address': 'email_address',
      'bank_name': 'bank_name',
      'account_number': 'account_number',
      'ifsc_code': 'ifsc_code',
      'branch_name': 'branch_name',
      'caste': 'caste',
      'religion': 'religion',
      'annual_income': 'annual_income',
      'ration_card_number': 'ration_card_number',
    };

    for (final entry in fieldMapping.entries) {
      final extractedValue = extractedData[entry.key];
      if (extractedValue == null || extractedValue.toString().isEmpty) continue;
      if (extractedValue.toString() == 'null') continue;

      // Only update if existing field is null/empty (don't overwrite)
      final existingValue = existing?[entry.value];
      if (existingValue == null ||
          existingValue.toString().isEmpty ||
          existingValue.toString() == 'null') {
        updateData[entry.value] = extractedValue.toString();
      }
    }

    // Upsert (insert or update)
    await _supabase
        .from('user_extracted_data')
        .upsert(updateData, onConflict: 'user_id');
  }

  // ────────────────────────────────────────────────────────────────────────────
  // FETCH USER DOCUMENTS from Supabase
  // ────────────────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getUserDocuments() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('user_documents')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('DocumentVault: Fetch error: $e');
      return [];
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // FETCH EXTRACTED DATA for form auto-fill
  // ────────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getUserExtractedData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('user_extracted_data')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('DocumentVault: Extracted data fetch error: $e');
      return null;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // GET SIGNED URL for private document images
  // ────────────────────────────────────────────────────────────────────────────

  static Future<String?> getDocumentSignedUrl(String filePath) async {
    try {
      final url = await _supabase.storage
          .from(_bucketName)
          .createSignedUrl(filePath, 3600); // 1hr expiry
      return url;
    } catch (e) {
      debugPrint('DocumentVault: Signed URL error: $e');
      return null;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // DELETE DOCUMENT from storage + table
  // ────────────────────────────────────────────────────────────────────────────

  static Future<bool> deleteDocument(String documentId, String filePath) async {
    try {
      await _supabase.storage.from(_bucketName).remove([filePath]);
      await _supabase.from('user_documents').delete().eq('id', documentId);
      return true;
    } catch (e) {
      debugPrint('DocumentVault: Delete error: $e');
      return false;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // SAVE FORM FILL HISTORY
  // ────────────────────────────────────────────────────────────────────────────

  static Future<void> saveFormFillHistory({
    required String serviceId,
    required String serviceName,
    required int fieldsTotal,
    required int fieldsAutoFilled,
    required Map<String, dynamic> filledData,
    String status = 'draft',
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('form_fill_history').insert({
        'user_id': userId,
        'service_id': serviceId,
        'service_name': serviceName,
        'fields_total': fieldsTotal,
        'fields_auto_filled': fieldsAutoFilled,
        'status': status,
        'filled_data': filledData,
      });
    } catch (e) {
      debugPrint('DocumentVault: Form history save error: $e');
    }
  }
}
