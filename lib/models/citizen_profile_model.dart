class CitizenProfileModel {
  final String id;
  final String fullName;
  final String mobile;
  final String email;
  final String state;
  final String district;
  final int age;
  final double income;
  final bool isKycVerified;
  final List<String> linkedDocuments;
  final List<String> appliedSchemes;

  CitizenProfileModel({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.state,
    required this.district,
    required this.isKycVerified,
    required this.linkedDocuments,
    required this.appliedSchemes,
    this.age = 0,
    this.income = 0.0,
  });

  factory CitizenProfileModel.fromJson(Map<String, dynamic> json) {
    return CitizenProfileModel(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      age: json['age'] ?? 0,
      income: (json['income'] ?? 0.0).toDouble(),
      isKycVerified: json['is_kyc_verified'] ?? false,
      linkedDocuments: List<String>.from(json['linked_documents'] ?? []),
      appliedSchemes: List<String>.from(json['applied_schemes'] ?? []),
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
      'age': age,
      'income': income,
      'is_kyc_verified': isKycVerified,
      'linked_documents': linkedDocuments,
      'applied_schemes': appliedSchemes,
    };
  }
}
