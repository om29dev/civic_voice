import 'package:flutter/material.dart';
import '../models/citizen_profile_model.dart';
import '../core/services/citizen_profile_service.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class CitizenProfileProvider with ChangeNotifier {
  final _service = CitizenProfileService();
  CitizenProfileModel? _profile;
  bool _isLoading = false;

  CitizenProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;

  Future<void> fetchProfile() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final user = await Amplify.Auth.getCurrentUser();
      var fetched = await _service.fetchProfile(user.userId);

      if (fetched == null) {
        debugPrint(
            '[CitizenProfileProvider] Profile null, bootstrapping from Cognito...');
        // Use ACTUAL data from Cognito attributes
        final authAttributes = await Amplify.Auth.fetchUserAttributes();

        String email = '';
        String name = 'Citizen';
        String mobile = '';

        for (final attr in authAttributes) {
          if (attr.userAttributeKey == AuthUserAttributeKey.email)
            email = attr.value;
          if (attr.userAttributeKey == AuthUserAttributeKey.name)
            name = attr.value;
          if (attr.userAttributeKey == AuthUserAttributeKey.phoneNumber)
            mobile = attr.value;
          // Support for given_name/family_name fallback
          if (name == 'Citizen' &&
              attr.userAttributeKey == AuthUserAttributeKey.givenName)
            name = attr.value;
        }

        fetched = CitizenProfileModel(
          id: user.userId,
          fullName: name,
          email: email,
          mobile: mobile,
          state: 'Not Set',
          district: 'Not Set',
          isKycVerified: false,
          linkedDocuments: [],
          appliedSchemes: [],
          age: 0,
          income: 0.0,
        );

        // Persist the actual initial data to DynamoDB
        await _service.saveProfile(fetched);
        debugPrint(
            '[CitizenProfileProvider] Auto-initialized profile for ${user.userId}');
      }

      _profile = fetched;
    } catch (e) {
      debugPrint('Error fetching citizen profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(CitizenProfileModel newProfile) async {
    _profile = newProfile;
    notifyListeners();
    await _service.saveProfile(newProfile);
  }

  Future<void> linkNewDocument(String docName) async {
    if (_profile == null) return;

    final docs = List<String>.from(_profile!.linkedDocuments)..add(docName);
    final updated = CitizenProfileModel(
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

    await updateProfile(updated);
  }
}
