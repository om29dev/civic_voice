// ═══════════════════════════════════════════════════════════════════════════════
// CVI DOCUMENT MODEL — AI Auto Form Filler System
// ═══════════════════════════════════════════════════════════════════════════════

/// Types of Indian government documents supported by CVI.
enum DocumentType {
  aadhaar,
  pan,
  passport,
  voterID,
  drivingLicense,
  birthCertificate,
  incomeCertificate,
  casteCertificate,
  rationCard,
  bankPassbook,
  photo,
  signature,
  landRecord,
  marksheet,
  other,
}

extension DocumentTypeEx on DocumentType {
  String get label => switch (this) {
        DocumentType.aadhaar => 'Aadhaar Card',
        DocumentType.pan => 'PAN Card',
        DocumentType.passport => 'Passport',
        DocumentType.voterID => 'Voter ID',
        DocumentType.drivingLicense => 'Driving License',
        DocumentType.birthCertificate => 'Birth Certificate',
        DocumentType.incomeCertificate => 'Income Certificate',
        DocumentType.casteCertificate => 'Caste Certificate',
        DocumentType.rationCard => 'Ration Card',
        DocumentType.bankPassbook => 'Bank Passbook',
        DocumentType.photo => 'Passport Photo',
        DocumentType.signature => 'Signature',
        DocumentType.landRecord => 'Land Record',
        DocumentType.marksheet => 'Marksheet',
        DocumentType.other => 'Other',
      };

  String get labelHindi => switch (this) {
        DocumentType.aadhaar => 'आधार कार्ड',
        DocumentType.pan => 'पैन कार्ड',
        DocumentType.passport => 'पासपोर्ट',
        DocumentType.voterID => 'मतदाता पहचान पत्र',
        DocumentType.drivingLicense => 'ड्राइविंग लाइसेंस',
        DocumentType.birthCertificate => 'जन्म प्रमाणपत्र',
        DocumentType.incomeCertificate => 'आय प्रमाणपत्र',
        DocumentType.casteCertificate => 'जाति प्रमाणपत्र',
        DocumentType.rationCard => 'राशन कार्ड',
        DocumentType.bankPassbook => 'बैंक पासबुक',
        DocumentType.photo => 'पासपोर्ट फोटो',
        DocumentType.signature => 'हस्ताक्षर',
        DocumentType.landRecord => 'भूमि अभिलेख',
        DocumentType.marksheet => 'अंक पत्र',
        DocumentType.other => 'अन्य',
      };

  String get emoji => switch (this) {
        DocumentType.aadhaar => '🪪',
        DocumentType.pan => '💳',
        DocumentType.passport => '📘',
        DocumentType.voterID => '🗳️',
        DocumentType.drivingLicense => '🚗',
        DocumentType.birthCertificate => '📜',
        DocumentType.incomeCertificate => '💰',
        DocumentType.casteCertificate => '📋',
        DocumentType.rationCard => '🍚',
        DocumentType.bankPassbook => '🏦',
        DocumentType.photo => '📷',
        DocumentType.signature => '✍️',
        DocumentType.landRecord => '🏡',
        DocumentType.marksheet => '📝',
        DocumentType.other => '📄',
      };
}

/// A single uploaded document with AI-extracted data.
class CVIDocument {
  final String id;
  final DocumentType type;
  final String fileName;
  final String localPath;
  final DateTime uploadedAt;
  final bool isVerified;
  final Map<String, dynamic> extractedData;
  final double confidenceScore;
  final String? thumbnailPath;

  const CVIDocument({
    required this.id,
    required this.type,
    required this.fileName,
    required this.localPath,
    required this.uploadedAt,
    this.isVerified = false,
    this.extractedData = const {},
    this.confidenceScore = 0.0,
    this.thumbnailPath,
  });

  CVIDocument copyWith({
    String? id,
    DocumentType? type,
    String? fileName,
    String? localPath,
    DateTime? uploadedAt,
    bool? isVerified,
    Map<String, dynamic>? extractedData,
    double? confidenceScore,
    String? thumbnailPath,
  }) =>
      CVIDocument(
        id: id ?? this.id,
        type: type ?? this.type,
        fileName: fileName ?? this.fileName,
        localPath: localPath ?? this.localPath,
        uploadedAt: uploadedAt ?? this.uploadedAt,
        isVerified: isVerified ?? this.isVerified,
        extractedData: extractedData ?? this.extractedData,
        confidenceScore: confidenceScore ?? this.confidenceScore,
        thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'fileName': fileName,
        'localPath': localPath,
        'uploadedAt': uploadedAt.toIso8601String(),
        'isVerified': isVerified,
        'extractedData': extractedData,
        'confidenceScore': confidenceScore,
        'thumbnailPath': thumbnailPath,
      };

  factory CVIDocument.fromJson(Map<String, dynamic> json) => CVIDocument(
        id: json['id'] as String,
        type: DocumentType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => DocumentType.other,
        ),
        fileName: json['fileName'] as String,
        localPath: json['localPath'] as String,
        uploadedAt: DateTime.parse(json['uploadedAt'] as String),
        isVerified: json['isVerified'] as bool? ?? false,
        extractedData:
            Map<String, dynamic>.from(json['extractedData'] as Map? ?? {}),
        confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
        thumbnailPath: json['thumbnailPath'] as String?,
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// UNIFIED EXTRACTED DATA — All fields from all documents merged
// ═══════════════════════════════════════════════════════════════════════════════

class ExtractedUserData {
  // Personal
  String? fullName;
  String? fatherName;
  String? motherName;
  String? spouseName;
  DateTime? dateOfBirth;
  String? gender;
  String? bloodGroup;

  // Identity Numbers
  String? aadhaarNumber; // Masked: XXXX XXXX 1234
  String? panNumber;
  String? passportNumber;
  String? voterIdNumber;
  String? drivingLicenseNumber;

  // Address
  String? addressLine1;
  String? addressLine2;
  String? village;
  String? tehsil;
  String? district;
  String? state;
  String? pincode;

  // Contact
  String? mobileNumber;
  String? emailAddress;

  // Bank Details (from passbook)
  String? bankName;
  String? accountNumber; // Masked
  String? ifscCode;
  String? branchName;

  // Other
  String? caste;
  String? religion;
  String? nationality;
  String? occupation;
  String? annualIncome;
  String? rationCardNumber;
  String? passportExpiryDate;

  ExtractedUserData();

  /// How many non-null fields are populated.
  int get filledFieldCount {
    final json = toJson();
    return json.values.where((v) => v != null).length;
  }

  /// Total number of trackable fields.
  int get totalFieldCount => toJson().length;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'fatherName': fatherName,
        'motherName': motherName,
        'spouseName': spouseName,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'gender': gender,
        'bloodGroup': bloodGroup,
        'aadhaarNumber': aadhaarNumber,
        'panNumber': panNumber,
        'passportNumber': passportNumber,
        'voterIdNumber': voterIdNumber,
        'drivingLicenseNumber': drivingLicenseNumber,
        'addressLine1': addressLine1,
        'addressLine2': addressLine2,
        'village': village,
        'tehsil': tehsil,
        'district': district,
        'state': state,
        'pincode': pincode,
        'mobileNumber': mobileNumber,
        'emailAddress': emailAddress,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'branchName': branchName,
        'caste': caste,
        'religion': religion,
        'nationality': nationality,
        'occupation': occupation,
        'annualIncome': annualIncome,
        'rationCardNumber': rationCardNumber,
        'passportExpiryDate': passportExpiryDate,
      };

  factory ExtractedUserData.fromJson(Map<String, dynamic> j) {
    final data = ExtractedUserData();
    data.fullName = j['fullName'] as String?;
    data.fatherName = j['fatherName'] as String?;
    data.motherName = j['motherName'] as String?;
    data.spouseName = j['spouseName'] as String?;
    data.dateOfBirth = j['dateOfBirth'] != null
        ? DateTime.tryParse(j['dateOfBirth'] as String)
        : null;
    data.gender = j['gender'] as String?;
    data.bloodGroup = j['bloodGroup'] as String?;
    data.aadhaarNumber = j['aadhaarNumber'] as String?;
    data.panNumber = j['panNumber'] as String?;
    data.passportNumber = j['passportNumber'] as String?;
    data.voterIdNumber = j['voterIdNumber'] as String?;
    data.drivingLicenseNumber = j['drivingLicenseNumber'] as String?;
    data.addressLine1 = j['addressLine1'] as String?;
    data.addressLine2 = j['addressLine2'] as String?;
    data.village = j['village'] as String?;
    data.tehsil = j['tehsil'] as String?;
    data.district = j['district'] as String?;
    data.state = j['state'] as String?;
    data.pincode = j['pincode'] as String?;
    data.mobileNumber = j['mobileNumber'] as String?;
    data.emailAddress = j['emailAddress'] as String?;
    data.bankName = j['bankName'] as String?;
    data.accountNumber = j['accountNumber'] as String?;
    data.ifscCode = j['ifscCode'] as String?;
    data.branchName = j['branchName'] as String?;
    data.caste = j['caste'] as String?;
    data.religion = j['religion'] as String?;
    data.nationality = j['nationality'] as String?;
    data.occupation = j['occupation'] as String?;
    data.annualIncome = j['annualIncome'] as String?;
    data.rationCardNumber = j['rationCardNumber'] as String?;
    data.passportExpiryDate = j['passportExpiryDate'] as String?;
    return data;
  }
}
