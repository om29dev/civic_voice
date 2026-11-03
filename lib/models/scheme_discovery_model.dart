import '../core/constants/profile_constants.dart';
import 'service_model.dart';

class SchemeDiscoveryModel {
  final String id;
  final String title;
  final String description;
  final String benefits;
  final String category;
  final List<String> eligibilityCriteria;
  final String applicationProcess;
  final List<String> requiredDocuments;
  final String shortTitle;
  final String level;
  final String schemeFor;
  final String beneficiaryState;
  final String nodalMinistry;
  final List<String> tags;
  final int? minAge;
  final int? maxAge;
  final double? maxIncome;
  final List<String> targetGenders;
  final List<String> targetCastes;
  final List<String> targetOccupations;
  final bool forDisabledOnly;

  SchemeDiscoveryModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.eligibilityCriteria,
    required this.applicationProcess,
    this.benefits = '',
    this.requiredDocuments = const [],
    this.shortTitle = '',
    this.level = '',
    this.schemeFor = '',
    this.beneficiaryState = 'All India',
    this.nodalMinistry = '',
    this.tags = const [],
    this.minAge,
    this.maxAge,
    this.maxIncome,
    this.targetGenders = const [],
    this.targetCastes = const [],
    this.targetOccupations = const [],
    this.forDisabledOnly = false,
  });

  factory SchemeDiscoveryModel.fromJson(Map<String, dynamic> json) {
    return SchemeDiscoveryModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      benefits: json['benefits']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      eligibilityCriteria:
          List<String>.from(json['eligibility_criteria'] ?? const []),
      applicationProcess: json['application_process']?.toString() ?? '',
      requiredDocuments:
          List<String>.from(json['required_documents'] ?? const []),
      shortTitle: json['short_title']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      schemeFor: json['scheme_for']?.toString() ?? '',
      beneficiaryState: json['beneficiary_state']?.toString() ?? 'All India',
      nodalMinistry: json['nodal_ministry']?.toString() ?? '',
      tags: List<String>.from(json['tags'] ?? const []),
      minAge: json['min_age'] as int?,
      maxAge: json['max_age'] as int?,
      maxIncome: (json['max_income'] as num?)?.toDouble(),
      targetGenders: List<String>.from(json['target_genders'] ?? const []),
      targetCastes: List<String>.from(json['target_castes'] ?? const []),
      targetOccupations:
          List<String>.from(json['target_occupations'] ?? const []),
      forDisabledOnly: json['for_disabled_only'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'benefits': benefits,
      'category': category,
      'eligibility_criteria': eligibilityCriteria,
      'application_process': applicationProcess,
      'required_documents': requiredDocuments,
      'short_title': shortTitle,
      'level': level,
      'scheme_for': schemeFor,
      'beneficiary_state': beneficiaryState,
      'nodal_ministry': nodalMinistry,
      'tags': tags,
      'min_age': minAge,
      'max_age': maxAge,
      'max_income': maxIncome,
      'target_genders': targetGenders,
      'target_castes': targetCastes,
      'target_occupations': targetOccupations,
      'for_disabled_only': forDisabledOnly,
    };
  }

  bool matchesState(String? selectedState) {
    if (selectedState == null ||
        selectedState.isEmpty ||
        selectedState == 'All States' ||
        selectedState == 'All India' ||
        selectedState == 'All') {
      return true;
    }
    final normSelected =
        ProfileConstants.normalizeState(selectedState).toLowerCase();
    final normSchemeState = beneficiaryState.trim().toLowerCase();
    if (level.toLowerCase() == 'central' ||
        normSchemeState.isEmpty ||
        normSchemeState == 'all' ||
        normSchemeState == 'all india') {
      return true;
    }
    return normSchemeState == normSelected ||
        normSchemeState.contains(normSelected) ||
        normSelected.contains(normSchemeState);
  }

  bool matchesDemographics({
    String? state,
    int? age,
    double? income,
    String? gender,
    String? casteCategory,
    String? occupation,
    bool? isDisabled,
  }) {
    // 1. State check (includes Central schemes + matching State schemes)
    if (!matchesState(state)) return false;

    // 2. Age check
    if (age != null && age > 0) {
      if (minAge != null && age < minAge!) return false;
      if (maxAge != null && age > maxAge!) return false;
    }

    // 3. Income check
    if (income != null && income > 0) {
      if (maxIncome != null && income > maxIncome!) return false;
    }

    // 4. Gender check
    if (gender != null &&
        gender.isNotEmpty &&
        gender != 'All' &&
        targetGenders.isNotEmpty) {
      final normGender = ProfileConstants.normalizeGender(gender);
      if (!targetGenders.contains(normGender)) return false;
    }

    // 5. Caste Category check
    if (casteCategory != null &&
        casteCategory.isNotEmpty &&
        casteCategory != 'All' &&
        targetCastes.isNotEmpty) {
      final normCaste = ProfileConstants.normalizeCasteCategory(casteCategory);
      if (!targetCastes.contains(normCaste)) return false;
    }

    // 6. Occupation check
    if (occupation != null &&
        occupation.isNotEmpty &&
        occupation != 'All' &&
        targetOccupations.isNotEmpty) {
      final normOcc = ProfileConstants.normalizeOccupation(occupation);
      if (!targetOccupations.contains(normOcc)) return false;
    }

    // 7. Disability check
    if (isDisabled == false && forDisabledOnly) {
      return false;
    }

    return true;
  }

  int computeRelevanceScore({
    String? state,
    int? age,
    double? income,
    String? gender,
    String? casteCategory,
    String? occupation,
    bool? isDisabled,
  }) {
    int score = 10;

    if (state != null &&
        state.isNotEmpty &&
        state != 'All States' &&
        state != 'All India') {
      final normSelected =
          ProfileConstants.normalizeState(state).toLowerCase();
      final normScheme = beneficiaryState.toLowerCase();
      if (normScheme == normSelected) {
        score += 35;
      } else if (level.toLowerCase() == 'central' ||
          normScheme == 'all india' ||
          normScheme == 'all') {
        score += 15;
      }
    }

    if (age != null && age > 0) {
      if (minAge != null || maxAge != null) {
        final minOk = minAge == null || age >= minAge!;
        final maxOk = maxAge == null || age <= maxAge!;
        if (minOk && maxOk) score += 25;
      }
    }

    if (income != null && income >= 0) {
      if (maxIncome != null && income <= maxIncome!) {
        score += 25;
      }
    }

    if (gender != null && gender.isNotEmpty && gender != 'All') {
      final normGender = ProfileConstants.normalizeGender(gender);
      if (targetGenders.contains(normGender)) {
        score += 25;
      }
    }

    if (casteCategory != null &&
        casteCategory.isNotEmpty &&
        casteCategory != 'All') {
      final normCaste = ProfileConstants.normalizeCasteCategory(casteCategory);
      if (targetCastes.contains(normCaste)) {
        score += 30;
      }
    }

    if (occupation != null && occupation.isNotEmpty && occupation != 'All') {
      final normOcc = ProfileConstants.normalizeOccupation(occupation);
      if (targetOccupations.contains(normOcc)) {
        score += 35;
      }
    }

    if (isDisabled == true && forDisabledOnly) {
      score += 40;
    }

    return score;
  }

  ServiceModel toServiceModel() {
    final docItems = requiredDocuments.isNotEmpty
        ? requiredDocuments
            .map((d) => DocumentItem(name: d, description: 'Required document'))
            .toList()
        : [
            const DocumentItem(
                name: 'Aadhaar Card',
                description: 'Identity and residence proof'),
            const DocumentItem(
                name: 'Bank Passbook',
                description: 'For Direct Benefit Transfer (DBT)'),
          ];

    final stepParts = applicationProcess
        .split(RegExp(r'(?=Step\s*\d+|STEP\s*\d+|\n)'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final stepItems = <StepItem>[];
    for (var i = 0; i < stepParts.length && i < 8; i++) {
      stepItems.add(StepItem(
        number: i + 1,
        title: 'Step ${i + 1}',
        description: stepParts[i],
      ));
    }
    if (stepItems.isEmpty && applicationProcess.isNotEmpty) {
      stepItems.add(StepItem(
        number: 1,
        title: 'Application Process',
        description: applicationProcess,
      ));
    }

    return ServiceModel(
      id: id,
      name: {'en': title, 'hi': title},
      description: {
        'en': benefits.isNotEmpty ? '$description\n\nBenefits:\n$benefits' : description,
        'hi': description,
      },
      eligibilityCriteria: eligibilityCriteria,
      requiredDocuments: docItems,
      steps: stepItems,
      estimatedTimeline: '15 - 30 Days',
      fees: 'Free',
      officialLink: 'https://www.myscheme.gov.in/schemes/$id',
      helplineNumber: '1967',
      category: _mapServiceCategory(category),
      iconEmoji: 'GOV',
      isAvailable: true,
      isPopular: level.toLowerCase() == 'central',
    );
  }

  static ServiceCategory _mapServiceCategory(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('agricultur') || lower.contains('rural')) {
      return ServiceCategory.agriculture;
    }
    if (lower.contains('health')) return ServiceCategory.health;
    if (lower.contains('educat') || lower.contains('learning')) {
      return ServiceCategory.education;
    }
    if (lower.contains('bank') || lower.contains('financ')) {
      return ServiceCategory.finance;
    }
    if (lower.contains('business') || lower.contains('entrepreneur')) {
      return ServiceCategory.business;
    }
    if (lower.contains('skill') || lower.contains('employ')) {
      return ServiceCategory.employment;
    }
    if (lower.contains('hous') || lower.contains('property')) {
      return ServiceCategory.property;
    }
    if (lower.contains('transport')) return ServiceCategory.transport;
    return ServiceCategory.welfare;
  }
}
