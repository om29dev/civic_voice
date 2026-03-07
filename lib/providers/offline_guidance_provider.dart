import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/offline_guide_model.dart';
// Future AWS Integration Point: Amplify DataStore / DynamoDB Offline Sync to sync guides when internet is available.

class OfflineGuidanceProvider with ChangeNotifier {
  List<OfflineGuideModel> _guides = [];
  List<OfflineGuideModel> get guides => _guides;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  OfflineGuidanceProvider() {
    _loadGuides();
  }

  Future<void> _loadGuides() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final String? cachedGuides = prefs.getString('offline_guides_cache');

    if (cachedGuides != null) {
      final List<dynamic> decoded = jsonDecode(cachedGuides);
      _guides = decoded.map((e) => OfflineGuideModel.fromJson(e)).toList();
    } else {
      // Load hardcoded fallback data if cache is empty
      _guides = [
        OfflineGuideModel(
          id: 'G1',
          title: 'How to apply for Ration Card',
          category: 'Food Security',
          steps: [
            'Visit local Panchayat/Ward office',
            'Submit Form 1 with family details',
            'Attach required documents',
            'Take acknowledgment slip'
          ],
          requiredDocuments: ['Aadhaar Card', 'Income Certificate', 'Passport Photos'],
          tip: 'Ensure all names match exactly with Aadhaar details.',
        ),
        OfflineGuideModel(
          id: 'G2',
          title: 'Opening a Jan Dhan Account',
          category: 'Finance',
          steps: [
            'Go to the nearest recognized Bank branch or Bank Mitra',
            'Fill account opening form',
            'Submit zero balance application',
            'Receive RuPay Debit Card within 7 days'
          ],
          requiredDocuments: ['Aadhaar Card or Voter ID'],
          tip: 'No minimum balance required for this account.',
        ),
      ];

      // Cache it for future offline use
      final encoded = jsonEncode(_guides.map((e) => e.toJson()).toList());
      await prefs.setString('offline_guides_cache', encoded);
    }

    _isLoading = false;
    notifyListeners();
  }
}
