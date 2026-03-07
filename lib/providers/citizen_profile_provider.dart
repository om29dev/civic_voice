import 'package:flutter/foundation.dart';
import '../models/citizen_profile_model.dart';

// Future AWS Integration Point: Amazon Cognito for user authentication and federation with Digilocker/ePramaan.

class CitizenProfileProvider with ChangeNotifier {
  CitizenProfileModel? _profile;
  CitizenProfileModel? get profile => _profile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  CitizenProfileProvider() {
    _fetchMockProfile();
  }

  Future<void> _fetchMockProfile() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1)); // Mock Network Call

    _profile = CitizenProfileModel(
      id: 'USR-89102-MOCK',
      fullName: 'Vikram Singh',
      mobile: '+91 9876543210',
      email: 'vikram.singh@example.com',
      state: 'Maharashtra',
      district: 'Pune',
      age: 32,
      income: 450000.0,
      isKycVerified: true,
      linkedDocuments: ['Aadhaar Card', 'PAN Card', 'Driving License'],
      appliedSchemes: ['PM Kisan', 'Ayushman Bharat'],
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile({int? age, double? income}) async {
    if (_profile == null) return;
    
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _profile = CitizenProfileModel(
      id: _profile!.id,
      fullName: _profile!.fullName,
      mobile: _profile!.mobile,
      email: _profile!.email,
      state: _profile!.state,
      district: _profile!.district,
      age: age ?? _profile!.age,
      income: income ?? _profile!.income,
      isKycVerified: _profile!.isKycVerified,
      linkedDocuments: _profile!.linkedDocuments,
      appliedSchemes: _profile!.appliedSchemes,
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> linkNewDocument(String docName) async {
    if (_profile == null) return;
    
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final docs = List<String>.from(_profile!.linkedDocuments)..add(docName);
    _profile = CitizenProfileModel(
      id: _profile!.id,
      fullName: _profile!.fullName,
      mobile: _profile!.mobile,
      email: _profile!.email,
      state: _profile!.state,
      district: _profile!.district,
      age: _profile!.age,
      income: _profile!.income,
      isKycVerified: _profile!.isKycVerified,
      linkedDocuments: docs,
      appliedSchemes: _profile!.appliedSchemes,
    );

    _isLoading = false;
    notifyListeners();
  }
}
