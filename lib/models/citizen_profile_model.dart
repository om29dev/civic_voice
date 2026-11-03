import 'package:flutter/foundation.dart';
import '../core/constants/profile_constants.dart';

/// Comprehensive citizen profile model - the single source of truth
/// for all user demographic and identity data, persisted to DynamoDB and local storage.
@immutable
class CitizenProfileModel {
  final String id;
  final String fullName;
  final String mobile;
  final String email;
  final String state;

  // Location
  final String? district;
  final String? pincode;

  // Demographics
  final DateTime? dateOfBirth;
  final String? gender;
  final String? maritalStatus;

  // Financial & Social
  final String? occupation;
  final String? annualIncomeRange;
  final String? casteCategory;

  // Numeric fields kept in sync with dateOfBirth and annualIncomeRange
  final double income;
  final int age;
  final bool isKycVerified;
  final List<String> linkedDocuments;
  final List<String> appliedSchemes;

  // Document IDs (masked)
  final String? aadhaarLastFour;
  final String? panMasked;
  final String? rationCardNumber;

  // Disability
  final bool isDisabled;
  final String? disabilityType;

  CitizenProfileModel({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.state,
    this.district,
    this.pincode,
    this.dateOfBirth,
    this.gender,
    this.maritalStatus,
    this.occupation,
    String? annualIncomeRange,
    this.casteCategory,
    int age = 0,
    double income = 0.0,
    this.isKycVerified = false,
    this.linkedDocuments = const [],
    this.appliedSchemes = const [],
    this.aadhaarLastFour,
    this.panMasked,
    this.rationCardNumber,
    this.isDisabled = false,
    this.disabilityType,
  })  : age = _resolveAge(dateOfBirth, age),
        annualIncomeRange = _resolveIncomeRange(annualIncomeRange, income),
        income = _resolveIncomeValue(annualIncomeRange, income);

  static int _resolveAge(DateTime? dob, int fallbackAge) {
    if (dob != null) {
      final now = DateTime.now();
      int a = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        a--;
      }
      return a > 0 ? a : fallbackAge;
    }
    return fallbackAge;
  }

  static String? _resolveIncomeRange(String? range, double numericIncome) {
    if (range != null && range.trim().isNotEmpty) {
      return ProfileConstants.normalizeIncomeRange(
        range,
        fallbackNumeric: numericIncome,
      );
    }
    if (numericIncome > 0) {
      return ProfileConstants.incomeRangeFromValue(numericIncome);
    }
    return range;
  }

  static double _resolveIncomeValue(String? range, double numericIncome) {
    if (numericIncome > 0 && (range == null || range.trim().isEmpty)) {
      return numericIncome;
    }
    if (range != null && range.trim().isNotEmpty) {
      return ProfileConstants.incomeValueFromRange(range);
    }
    return numericIncome;
  }

  // Derived getters

  /// Age derived from dateOfBirth; falls back to stored `age` field.
  int get computedAge => _resolveAge(dateOfBirth, age);

  /// Normalized income range for UI dropdowns and chips.
  String get effectiveIncomeRange => ProfileConstants.normalizeIncomeRange(
        annualIncomeRange,
        fallbackNumeric: income,
      );

  /// Profile completion 0-100 based on 10 key fields.
  int get profileCompletionPercent {
    int filled = 0;
    const total = 10;
    if (fullName.isNotEmpty) filled++;
    if (mobile.isNotEmpty || email.isNotEmpty) filled++;
    if (dateOfBirth != null || age > 0) filled++;
    if (gender != null && gender!.isNotEmpty) filled++;
    if (maritalStatus != null && maritalStatus!.isNotEmpty) filled++;
    if (state.isNotEmpty && state != 'Not Set') filled++;
    if (district != null && district!.isNotEmpty) filled++;
    if (occupation != null && occupation!.isNotEmpty) filled++;
    if ((annualIncomeRange != null && annualIncomeRange!.isNotEmpty) ||
        income > 0) {
      filled++;
    }
    if (aadhaarLastFour != null && aadhaarLastFour!.isNotEmpty) filled++;
    return ((filled / total) * 100).round();
  }

  bool get isProfileIncomplete => profileCompletionPercent < 70;

  // Serialization

  factory CitizenProfileModel.fromJson(Map<String, dynamic> json) {
    final parsedDob = json['date_of_birth'] != null
        ? DateTime.tryParse(json['date_of_birth'].toString())
        : null;
    final parsedAge = (json['age'] as num?)?.toInt() ?? 0;
    final parsedIncome = (json['income'] as num?)?.toDouble() ?? 0.0;
    final parsedRange = json['annual_income_range'] as String?;

    return CitizenProfileModel(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      email: json['email'] as String? ?? '',
      state: json['state'] as String? ?? 'Maharashtra',
      district: json['district'] as String?,
      pincode: json['pincode'] as String?,
      dateOfBirth: parsedDob,
      gender: json['gender'] as String?,
      maritalStatus: json['marital_status'] as String?,
      occupation: json['occupation'] as String?,
      annualIncomeRange: parsedRange,
      casteCategory: json['caste_category'] as String?,
      age: parsedAge,
      income: parsedIncome,
      isKycVerified: json['is_kyc_verified'] as bool? ?? false,
      linkedDocuments:
          List<String>.from(json['linked_documents'] as List? ?? []),
      appliedSchemes: List<String>.from(json['applied_schemes'] as List? ?? []),
      aadhaarLastFour: json['aadhaar_last_four'] as String?,
      panMasked: json['pan_masked'] as String?,
      rationCardNumber: json['ration_card_number'] as String?,
      isDisabled: json['is_disabled'] as bool? ?? false,
      disabilityType: json['disability_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'mobile': mobile,
      'email': email,
      'state': state,
      'district': district,
      'pincode': pincode,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'marital_status': maritalStatus,
      'occupation': occupation,
      'annual_income_range': annualIncomeRange,
      'caste_category': casteCategory,
      'age': computedAge,
      'income': income,
      'is_kyc_verified': isKycVerified,
      'linked_documents': linkedDocuments,
      'applied_schemes': appliedSchemes,
      'aadhaar_last_four': aadhaarLastFour,
      'pan_masked': panMasked,
      'ration_card_number': rationCardNumber,
      'is_disabled': isDisabled,
      'disability_type': disabilityType,
    };
  }

  CitizenProfileModel copyWith({
    String? id,
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
    bool? isKycVerified,
    List<String>? linkedDocuments,
    List<String>? appliedSchemes,
    String? aadhaarLastFour,
    String? panMasked,
    String? rationCardNumber,
    bool? isDisabled,
    String? disabilityType,
  }) {
    final nextDob = dateOfBirth ??
        (age != null && age > 0 && this.dateOfBirth != null
            ? DateTime(
                DateTime.now().year - age,
                this.dateOfBirth!.month,
                this.dateOfBirth!.day,
              )
            : this.dateOfBirth);

    final nextAge = dateOfBirth != null
        ? _resolveAge(dateOfBirth, age ?? this.age)
        : (age ?? this.age);

    final String? nextRange;
    final double nextIncome;
    if (annualIncomeRange != null) {
      nextRange = ProfileConstants.normalizeIncomeRange(annualIncomeRange);
      nextIncome =
          income ?? ProfileConstants.incomeValueFromRange(nextRange);
    } else if (income != null) {
      nextIncome = income;
      nextRange = ProfileConstants.incomeRangeFromValue(income);
    } else {
      nextRange = this.annualIncomeRange;
      nextIncome = this.income;
    }

    return CitizenProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      state: state ?? this.state,
      district: district ?? this.district,
      pincode: pincode ?? this.pincode,
      dateOfBirth: nextDob,
      gender: gender ?? this.gender,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      occupation: occupation ?? this.occupation,
      annualIncomeRange: nextRange,
      casteCategory: casteCategory ?? this.casteCategory,
      age: nextAge,
      income: nextIncome,
      isKycVerified: isKycVerified ?? this.isKycVerified,
      linkedDocuments: linkedDocuments ?? this.linkedDocuments,
      appliedSchemes: appliedSchemes ?? this.appliedSchemes,
      aadhaarLastFour: aadhaarLastFour ?? this.aadhaarLastFour,
      panMasked: panMasked ?? this.panMasked,
      rationCardNumber: rationCardNumber ?? this.rationCardNumber,
      isDisabled: isDisabled ?? this.isDisabled,
      disabilityType: disabilityType ?? this.disabilityType,
    );
  }
}
