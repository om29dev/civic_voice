import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/citizen_profile_model.dart';
import '../core/services/citizen_profile_service.dart';
import '../core/constants/profile_constants.dart';

class CitizenProfileProvider with ChangeNotifier {
  static const String _localCachePrefix = 'cvi_citizen_profile_v2_';
  static const String _lastProfileKey = 'cvi_citizen_profile_last';

  final _service = CitizenProfileService();
  CitizenProfileModel? _profile;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  CitizenProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  int get completionPercent => _profile?.profileCompletionPercent ?? 0;
  bool get isProfileIncomplete => _profile?.isProfileIncomplete ?? true;

  CitizenProfileProvider() {
    _loadCachedProfile();
  }

  Future<void> _loadCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_lastProfileKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _profile = CitizenProfileModel.fromJson(decoded);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<CitizenProfileModel?> _loadLocalForUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_localCachePrefix$userId');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return CitizenProfileModel.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveLocal(CitizenProfileModel model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(model.toJson());
      if (model.id.isNotEmpty) {
        await prefs.setString('$_localCachePrefix${model.id}', encoded);
      }
      if (model.mobile.isNotEmpty) {
        final digits = model.mobile.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length >= 10) {
          final last10 = digits.substring(digits.length - 10);
          await prefs.setString('${_localCachePrefix}mob_$last10', encoded);
        }
      }
      if (model.email.isNotEmpty) {
        await prefs.setString(
          '${_localCachePrefix}email_${model.email.toLowerCase()}',
          encoded,
        );
      }
      await prefs.setString(_lastProfileKey, encoded);
    } catch (_) {}
  }

  // Fetch

  Future<void> fetchProfile({
    String? fallbackId,
    String? fallbackName,
    String? fallbackEmail,
    String? fallbackMobile,
    String? fallbackState,
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String userId = fallbackId ?? '';
      String email = fallbackEmail ?? '';
      String name = fallbackName ?? '';
      String mobile = fallbackMobile ?? '';

      try {
        final user = await Amplify.Auth.getCurrentUser();
        userId = user.userId;
        final authAttributes = await Amplify.Auth.fetchUserAttributes();
        for (final attr in authAttributes) {
          if (attr.userAttributeKey == AuthUserAttributeKey.email &&
              email.isEmpty) {
            email = attr.value;
          }
          if (attr.userAttributeKey == AuthUserAttributeKey.name &&
              name.isEmpty) {
            name = attr.value;
          }
          if (attr.userAttributeKey == AuthUserAttributeKey.phoneNumber &&
              mobile.isEmpty) {
            mobile = attr.value;
          }
          if (name.isEmpty &&
              attr.userAttributeKey == AuthUserAttributeKey.givenName) {
            name = attr.value;
          }
        }
      } catch (_) {
        // Fallback when signed in via Mobile OTP, Google account sheet, or guest
        if (userId.isEmpty) {
          final prefs = await SharedPreferences.getInstance();
          userId = prefs.getString('userId') ?? _profile?.id ?? 'citizen_local';
          if (name.isEmpty) {
            name = prefs.getString('userName') ?? _profile?.fullName ?? 'Citizen';
          }
          if (email.isEmpty) {
            email = prefs.getString('userEmail') ?? _profile?.email ?? '';
          }
          if (mobile.isEmpty) {
            mobile = prefs.getString('userMobile') ?? _profile?.mobile ?? '';
          }
        }
      }

      CitizenProfileModel? fetched;
      if (userId.isNotEmpty && !userId.startsWith('guest_')) {
        fetched = await _service.fetchProfile(userId);
      }

      final localCached = await _loadLocalForUser(userId);
      if (fetched == null && localCached != null) {
        fetched = localCached;
      } else if (fetched != null && localCached != null) {
        // Merge any richer local demographic fields if cloud record was empty
        fetched = fetched.copyWith(
          fullName: fetched.fullName.isNotEmpty && fetched.fullName != 'Citizen'
              ? fetched.fullName
              : localCached.fullName,
          mobile: fetched.mobile.isNotEmpty ? fetched.mobile : localCached.mobile,
          email: fetched.email.isNotEmpty ? fetched.email : localCached.email,
          state: fetched.state.isNotEmpty ? fetched.state : localCached.state,
          district: fetched.district ?? localCached.district,
          pincode: fetched.pincode ?? localCached.pincode,
          dateOfBirth: fetched.dateOfBirth ?? localCached.dateOfBirth,
          gender: fetched.gender ?? localCached.gender,
          maritalStatus: fetched.maritalStatus ?? localCached.maritalStatus,
          occupation: fetched.occupation ?? localCached.occupation,
          annualIncomeRange:
              fetched.annualIncomeRange ?? localCached.annualIncomeRange,
          casteCategory: fetched.casteCategory ?? localCached.casteCategory,
          age: fetched.computedAge > 0
              ? fetched.computedAge
              : localCached.computedAge,
          income: fetched.income > 0 ? fetched.income : localCached.income,
          aadhaarLastFour:
              fetched.aadhaarLastFour ?? localCached.aadhaarLastFour,
          panMasked: fetched.panMasked ?? localCached.panMasked,
          rationCardNumber:
              fetched.rationCardNumber ?? localCached.rationCardNumber,
          isDisabled: fetched.isDisabled || localCached.isDisabled,
          disabilityType: fetched.disabilityType ?? localCached.disabilityType,
        );
      }

      if (fetched == null) {
        final prefs = await SharedPreferences.getInstance();
        final savedState = fallbackState ??
            prefs.getString('userState') ??
            _profile?.state ??
            'Maharashtra';

        fetched = CitizenProfileModel(
          id: userId.isNotEmpty ? userId : 'citizen_local',
          fullName: name.isNotEmpty ? name : 'Citizen',
          email: email,
          mobile: mobile,
          state: ProfileConstants.normalizeState(savedState),
          age: 28,
          annualIncomeRange: '₹1L - ₹2.5L',
          gender: 'Male',
          maritalStatus: 'Single',
          occupation: 'Salaried',
          casteCategory: 'General',
          isKycVerified: false,
          linkedDocuments: const [],
          appliedSchemes: const [],
        );

        await _saveLocal(fetched);
        await _service.saveProfile(fetched);
      } else {
        // Fill in any missing identity fields from auth session
        fetched = fetched.copyWith(
          fullName:
              (fetched.fullName.isEmpty || fetched.fullName == 'Citizen') &&
                      name.isNotEmpty
                  ? name
                  : fetched.fullName,
          email: fetched.email.isEmpty && email.isNotEmpty
              ? email
              : fetched.email,
          mobile: fetched.mobile.isEmpty && mobile.isNotEmpty
              ? mobile
              : fetched.mobile,
          state: fetched.state.isEmpty
              ? ProfileConstants.normalizeState(fallbackState)
              : ProfileConstants.normalizeState(fetched.state),
        );
        await _saveLocal(fetched);
      }

      _profile = fetched;
    } catch (e) {
      debugPrint('[CitizenProfileProvider] fetchProfile error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Bootstrap or merge profile immediately after registration, Google login, or Mobile OTP login.
  Future<void> bootstrapFromAuth({
    required String id,
    required String fullName,
    required String email,
    required String mobile,
    String? state,
  }) async {
    final existing = await _loadLocalForUser(id) ?? _profile;
    final resolvedState = ProfileConstants.normalizeState(
      state ?? existing?.state ?? 'Maharashtra',
    );

    final updated = (existing ??
            CitizenProfileModel(
              id: id,
              fullName: fullName.isNotEmpty ? fullName : 'Citizen',
              mobile: mobile,
              email: email,
              state: resolvedState,
              age: 28,
              annualIncomeRange: '₹1L - ₹2.5L',
              gender: 'Male',
              maritalStatus: 'Single',
              occupation: 'Salaried',
              casteCategory: 'General',
            ))
        .copyWith(
      id: id,
      fullName: fullName.isNotEmpty ? fullName : existing?.fullName,
      email: email.isNotEmpty ? email : existing?.email,
      mobile: mobile.isNotEmpty ? mobile : existing?.mobile,
      state: resolvedState,
    );

    _profile = updated;
    notifyListeners();
    await _saveLocal(updated);
    await _service.saveProfile(updated);
  }

  // Update

  /// Updates the profile in-memory and local storage, then syncs to DynamoDB.
  Future<bool> updateProfile(CitizenProfileModel newProfile) async {
    _profile = newProfile;
    _isSaving = true;
    _error = null;
    notifyListeners();

    await _saveLocal(newProfile);

    try {
      await _service.saveProfile(newProfile);
      return true;
    } catch (e) {
      debugPrint('[CitizenProfileProvider] DynamoDB sync warning: $e');
      return true;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Partial update - merges only specified fields and saves.
  Future<bool> patchProfile({
    String? fullName,
    String? mobile,
    String? email,
    String? state,
    String? district,
    String? pincode,
    DateTime? dateOfBirth,
    String? gender,
    String? maritalStatus,
    String? occupation,
    String? annualIncomeRange,
    String? casteCategory,
    int? age,
    double? income,
    String? aadhaarLastFour,
    String? panMasked,
    String? rationCardNumber,
    bool? isDisabled,
    String? disabilityType,
  }) async {
    final base = _profile ??
        CitizenProfileModel(
          id: 'citizen_local',
          fullName: fullName ?? 'Citizen',
          mobile: mobile ?? '',
          email: email ?? '',
          state: ProfileConstants.normalizeState(state),
        );
    final updated = base.copyWith(
      fullName: fullName,
      mobile: mobile,
      email: email,
      state: state,
      district: district,
      pincode: pincode,
      dateOfBirth: dateOfBirth,
      gender: gender,
      maritalStatus: maritalStatus,
      occupation: occupation,
      annualIncomeRange: annualIncomeRange,
      casteCategory: casteCategory,
      age: age,
      income: income,
      aadhaarLastFour: aadhaarLastFour,
      panMasked: panMasked,
      rationCardNumber: rationCardNumber,
      isDisabled: isDisabled,
      disabilityType: disabilityType,
    );
    return updateProfile(updated);
  }

  Future<void> linkNewDocument(String docName) async {
    if (_profile == null) return;
    final docs = List<String>.from(_profile!.linkedDocuments)..add(docName);
    await updateProfile(_profile!.copyWith(linkedDocuments: docs));
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
