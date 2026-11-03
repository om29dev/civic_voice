class SchemeDiscoveryModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final List<String> eligibilityCriteria;
  final String applicationProcess;
  final String shortTitle;
  final String level;
  final String schemeFor;
  final String beneficiaryState;
  final String nodalMinistry;
  final List<String> tags;

  SchemeDiscoveryModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.eligibilityCriteria,
    required this.applicationProcess,
    this.shortTitle = '',
    this.level = '',
    this.schemeFor = '',
    this.beneficiaryState = '',
    this.nodalMinistry = '',
    this.tags = const [],
  });

  factory SchemeDiscoveryModel.fromJson(Map<String, dynamic> json) {
    return SchemeDiscoveryModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'General',
      eligibilityCriteria:
          List<String>.from(json['eligibility_criteria'] ?? []),
      applicationProcess: json['application_process'] ?? '',
      shortTitle: json['short_title'] ?? '',
      level: json['level'] ?? '',
      schemeFor: json['scheme_for'] ?? '',
      beneficiaryState: json['beneficiary_state'] ?? '',
      nodalMinistry: json['nodal_ministry'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'eligibility_criteria': eligibilityCriteria,
      'application_process': applicationProcess,
      'short_title': shortTitle,
      'level': level,
      'scheme_for': schemeFor,
      'beneficiary_state': beneficiaryState,
      'nodal_ministry': nodalMinistry,
      'tags': tags,
    };
  }
}
