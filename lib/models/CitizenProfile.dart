/*
* Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
*  http://aws.amazon.com/apache2.0
*
* or in the "license" file accompanying this file. This file is distributed
* on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
* express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

// NOTE: This file is generated and may not follow lint rules defined in your app
// Generated files can be excluded from analysis in analysis_options.yaml
// For more info, see: https://dart.dev/guides/language/analysis-options#excluding-code-from-analysis

// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, override_on_non_overriding_member, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'ModelProvider.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;
import 'package:collection/collection.dart';


/** This is an auto generated class representing the CitizenProfile type in your schema. */
class CitizenProfile extends amplify_core.Model {
  static const classType = const _CitizenProfileModelType();
  final String id;
  final String? _full_name;
  final String? _mobile;
  final String? _email;
  final String? _state;
  final String? _district;
  final String? _pincode;
  final String? _date_of_birth;
  final String? _gender;
  final String? _marital_status;
  final String? _occupation;
  final String? _annual_income_range;
  final String? _caste_category;
  final int? _age;
  final double? _income;
  final bool? _is_kyc_verified;
  final List<String>? _linked_documents;
  final List<String>? _applied_schemes;
  final String? _aadhaar_last_four;
  final String? _pan_masked;
  final String? _ration_card_number;
  final bool? _is_disabled;
  final String? _disability_type;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  CitizenProfileModelIdentifier get modelIdentifier {
      return CitizenProfileModelIdentifier(
        id: id
      );
  }
  
  String get full_name {
    try {
      return _full_name!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get mobile {
    try {
      return _mobile!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get email {
    try {
      return _email!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get state {
    try {
      return _state!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get district {
    return _district;
  }
  
  String? get pincode {
    return _pincode;
  }
  
  String? get date_of_birth {
    return _date_of_birth;
  }
  
  String? get gender {
    return _gender;
  }
  
  String? get marital_status {
    return _marital_status;
  }
  
  String? get occupation {
    return _occupation;
  }
  
  String? get annual_income_range {
    return _annual_income_range;
  }
  
  String? get caste_category {
    return _caste_category;
  }
  
  int? get age {
    return _age;
  }
  
  double? get income {
    return _income;
  }
  
  bool? get is_kyc_verified {
    return _is_kyc_verified;
  }
  
  List<String>? get linked_documents {
    return _linked_documents;
  }
  
  List<String>? get applied_schemes {
    return _applied_schemes;
  }
  
  String? get aadhaar_last_four {
    return _aadhaar_last_four;
  }
  
  String? get pan_masked {
    return _pan_masked;
  }
  
  String? get ration_card_number {
    return _ration_card_number;
  }
  
  bool? get is_disabled {
    return _is_disabled;
  }
  
  String? get disability_type {
    return _disability_type;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const CitizenProfile._internal({required this.id, required full_name, required mobile, required email, required state, district, pincode, date_of_birth, gender, marital_status, occupation, annual_income_range, caste_category, age, income, is_kyc_verified, linked_documents, applied_schemes, aadhaar_last_four, pan_masked, ration_card_number, is_disabled, disability_type, createdAt, updatedAt}): _full_name = full_name, _mobile = mobile, _email = email, _state = state, _district = district, _pincode = pincode, _date_of_birth = date_of_birth, _gender = gender, _marital_status = marital_status, _occupation = occupation, _annual_income_range = annual_income_range, _caste_category = caste_category, _age = age, _income = income, _is_kyc_verified = is_kyc_verified, _linked_documents = linked_documents, _applied_schemes = applied_schemes, _aadhaar_last_four = aadhaar_last_four, _pan_masked = pan_masked, _ration_card_number = ration_card_number, _is_disabled = is_disabled, _disability_type = disability_type, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory CitizenProfile({String? id, required String full_name, required String mobile, required String email, required String state, String? district, String? pincode, String? date_of_birth, String? gender, String? marital_status, String? occupation, String? annual_income_range, String? caste_category, int? age, double? income, bool? is_kyc_verified, List<String>? linked_documents, List<String>? applied_schemes, String? aadhaar_last_four, String? pan_masked, String? ration_card_number, bool? is_disabled, String? disability_type}) {
    return CitizenProfile._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      full_name: full_name,
      mobile: mobile,
      email: email,
      state: state,
      district: district,
      pincode: pincode,
      date_of_birth: date_of_birth,
      gender: gender,
      marital_status: marital_status,
      occupation: occupation,
      annual_income_range: annual_income_range,
      caste_category: caste_category,
      age: age,
      income: income,
      is_kyc_verified: is_kyc_verified,
      linked_documents: linked_documents != null ? List<String>.unmodifiable(linked_documents) : linked_documents,
      applied_schemes: applied_schemes != null ? List<String>.unmodifiable(applied_schemes) : applied_schemes,
      aadhaar_last_four: aadhaar_last_four,
      pan_masked: pan_masked,
      ration_card_number: ration_card_number,
      is_disabled: is_disabled,
      disability_type: disability_type);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CitizenProfile &&
      id == other.id &&
      _full_name == other._full_name &&
      _mobile == other._mobile &&
      _email == other._email &&
      _state == other._state &&
      _district == other._district &&
      _pincode == other._pincode &&
      _date_of_birth == other._date_of_birth &&
      _gender == other._gender &&
      _marital_status == other._marital_status &&
      _occupation == other._occupation &&
      _annual_income_range == other._annual_income_range &&
      _caste_category == other._caste_category &&
      _age == other._age &&
      _income == other._income &&
      _is_kyc_verified == other._is_kyc_verified &&
      DeepCollectionEquality().equals(_linked_documents, other._linked_documents) &&
      DeepCollectionEquality().equals(_applied_schemes, other._applied_schemes) &&
      _aadhaar_last_four == other._aadhaar_last_four &&
      _pan_masked == other._pan_masked &&
      _ration_card_number == other._ration_card_number &&
      _is_disabled == other._is_disabled &&
      _disability_type == other._disability_type;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("CitizenProfile {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("full_name=" + "$_full_name" + ", ");
    buffer.write("mobile=" + "$_mobile" + ", ");
    buffer.write("email=" + "$_email" + ", ");
    buffer.write("state=" + "$_state" + ", ");
    buffer.write("district=" + "$_district" + ", ");
    buffer.write("pincode=" + "$_pincode" + ", ");
    buffer.write("date_of_birth=" + "$_date_of_birth" + ", ");
    buffer.write("gender=" + "$_gender" + ", ");
    buffer.write("marital_status=" + "$_marital_status" + ", ");
    buffer.write("occupation=" + "$_occupation" + ", ");
    buffer.write("annual_income_range=" + "$_annual_income_range" + ", ");
    buffer.write("caste_category=" + "$_caste_category" + ", ");
    buffer.write("age=" + (_age != null ? _age!.toString() : "null") + ", ");
    buffer.write("income=" + (_income != null ? _income!.toString() : "null") + ", ");
    buffer.write("is_kyc_verified=" + (_is_kyc_verified != null ? _is_kyc_verified!.toString() : "null") + ", ");
    buffer.write("linked_documents=" + (_linked_documents != null ? _linked_documents!.toString() : "null") + ", ");
    buffer.write("applied_schemes=" + (_applied_schemes != null ? _applied_schemes!.toString() : "null") + ", ");
    buffer.write("aadhaar_last_four=" + "$_aadhaar_last_four" + ", ");
    buffer.write("pan_masked=" + "$_pan_masked" + ", ");
    buffer.write("ration_card_number=" + "$_ration_card_number" + ", ");
    buffer.write("is_disabled=" + (_is_disabled != null ? _is_disabled!.toString() : "null") + ", ");
    buffer.write("disability_type=" + "$_disability_type" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  CitizenProfile copyWith({String? full_name, String? mobile, String? email, String? state, String? district, String? pincode, String? date_of_birth, String? gender, String? marital_status, String? occupation, String? annual_income_range, String? caste_category, int? age, double? income, bool? is_kyc_verified, List<String>? linked_documents, List<String>? applied_schemes, String? aadhaar_last_four, String? pan_masked, String? ration_card_number, bool? is_disabled, String? disability_type}) {
    return CitizenProfile._internal(
      id: id,
      full_name: full_name ?? this.full_name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      state: state ?? this.state,
      district: district ?? this.district,
      pincode: pincode ?? this.pincode,
      date_of_birth: date_of_birth ?? this.date_of_birth,
      gender: gender ?? this.gender,
      marital_status: marital_status ?? this.marital_status,
      occupation: occupation ?? this.occupation,
      annual_income_range: annual_income_range ?? this.annual_income_range,
      caste_category: caste_category ?? this.caste_category,
      age: age ?? this.age,
      income: income ?? this.income,
      is_kyc_verified: is_kyc_verified ?? this.is_kyc_verified,
      linked_documents: linked_documents ?? this.linked_documents,
      applied_schemes: applied_schemes ?? this.applied_schemes,
      aadhaar_last_four: aadhaar_last_four ?? this.aadhaar_last_four,
      pan_masked: pan_masked ?? this.pan_masked,
      ration_card_number: ration_card_number ?? this.ration_card_number,
      is_disabled: is_disabled ?? this.is_disabled,
      disability_type: disability_type ?? this.disability_type);
  }
  
  CitizenProfile copyWithModelFieldValues({
    ModelFieldValue<String>? full_name,
    ModelFieldValue<String>? mobile,
    ModelFieldValue<String>? email,
    ModelFieldValue<String>? state,
    ModelFieldValue<String?>? district,
    ModelFieldValue<String?>? pincode,
    ModelFieldValue<String?>? date_of_birth,
    ModelFieldValue<String?>? gender,
    ModelFieldValue<String?>? marital_status,
    ModelFieldValue<String?>? occupation,
    ModelFieldValue<String?>? annual_income_range,
    ModelFieldValue<String?>? caste_category,
    ModelFieldValue<int?>? age,
    ModelFieldValue<double?>? income,
    ModelFieldValue<bool?>? is_kyc_verified,
    ModelFieldValue<List<String>?>? linked_documents,
    ModelFieldValue<List<String>?>? applied_schemes,
    ModelFieldValue<String?>? aadhaar_last_four,
    ModelFieldValue<String?>? pan_masked,
    ModelFieldValue<String?>? ration_card_number,
    ModelFieldValue<bool?>? is_disabled,
    ModelFieldValue<String?>? disability_type
  }) {
    return CitizenProfile._internal(
      id: id,
      full_name: full_name == null ? this.full_name : full_name.value,
      mobile: mobile == null ? this.mobile : mobile.value,
      email: email == null ? this.email : email.value,
      state: state == null ? this.state : state.value,
      district: district == null ? this.district : district.value,
      pincode: pincode == null ? this.pincode : pincode.value,
      date_of_birth: date_of_birth == null ? this.date_of_birth : date_of_birth.value,
      gender: gender == null ? this.gender : gender.value,
      marital_status: marital_status == null ? this.marital_status : marital_status.value,
      occupation: occupation == null ? this.occupation : occupation.value,
      annual_income_range: annual_income_range == null ? this.annual_income_range : annual_income_range.value,
      caste_category: caste_category == null ? this.caste_category : caste_category.value,
      age: age == null ? this.age : age.value,
      income: income == null ? this.income : income.value,
      is_kyc_verified: is_kyc_verified == null ? this.is_kyc_verified : is_kyc_verified.value,
      linked_documents: linked_documents == null ? this.linked_documents : linked_documents.value,
      applied_schemes: applied_schemes == null ? this.applied_schemes : applied_schemes.value,
      aadhaar_last_four: aadhaar_last_four == null ? this.aadhaar_last_four : aadhaar_last_four.value,
      pan_masked: pan_masked == null ? this.pan_masked : pan_masked.value,
      ration_card_number: ration_card_number == null ? this.ration_card_number : ration_card_number.value,
      is_disabled: is_disabled == null ? this.is_disabled : is_disabled.value,
      disability_type: disability_type == null ? this.disability_type : disability_type.value
    );
  }
  
  CitizenProfile.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _full_name = json['full_name'],
      _mobile = json['mobile'],
      _email = json['email'],
      _state = json['state'],
      _district = json['district'],
      _pincode = json['pincode'],
      _date_of_birth = json['date_of_birth'],
      _gender = json['gender'],
      _marital_status = json['marital_status'],
      _occupation = json['occupation'],
      _annual_income_range = json['annual_income_range'],
      _caste_category = json['caste_category'],
      _age = (json['age'] as num?)?.toInt(),
      _income = (json['income'] as num?)?.toDouble(),
      _is_kyc_verified = json['is_kyc_verified'],
      _linked_documents = json['linked_documents']?.cast<String>(),
      _applied_schemes = json['applied_schemes']?.cast<String>(),
      _aadhaar_last_four = json['aadhaar_last_four'],
      _pan_masked = json['pan_masked'],
      _ration_card_number = json['ration_card_number'],
      _is_disabled = json['is_disabled'],
      _disability_type = json['disability_type'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'full_name': _full_name, 'mobile': _mobile, 'email': _email, 'state': _state, 'district': _district, 'pincode': _pincode, 'date_of_birth': _date_of_birth, 'gender': _gender, 'marital_status': _marital_status, 'occupation': _occupation, 'annual_income_range': _annual_income_range, 'caste_category': _caste_category, 'age': _age, 'income': _income, 'is_kyc_verified': _is_kyc_verified, 'linked_documents': _linked_documents, 'applied_schemes': _applied_schemes, 'aadhaar_last_four': _aadhaar_last_four, 'pan_masked': _pan_masked, 'ration_card_number': _ration_card_number, 'is_disabled': _is_disabled, 'disability_type': _disability_type, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'full_name': _full_name,
    'mobile': _mobile,
    'email': _email,
    'state': _state,
    'district': _district,
    'pincode': _pincode,
    'date_of_birth': _date_of_birth,
    'gender': _gender,
    'marital_status': _marital_status,
    'occupation': _occupation,
    'annual_income_range': _annual_income_range,
    'caste_category': _caste_category,
    'age': _age,
    'income': _income,
    'is_kyc_verified': _is_kyc_verified,
    'linked_documents': _linked_documents,
    'applied_schemes': _applied_schemes,
    'aadhaar_last_four': _aadhaar_last_four,
    'pan_masked': _pan_masked,
    'ration_card_number': _ration_card_number,
    'is_disabled': _is_disabled,
    'disability_type': _disability_type,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<CitizenProfileModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<CitizenProfileModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final FULL_NAME = amplify_core.QueryField(fieldName: "full_name");
  static final MOBILE = amplify_core.QueryField(fieldName: "mobile");
  static final EMAIL = amplify_core.QueryField(fieldName: "email");
  static final STATE = amplify_core.QueryField(fieldName: "state");
  static final DISTRICT = amplify_core.QueryField(fieldName: "district");
  static final PINCODE = amplify_core.QueryField(fieldName: "pincode");
  static final DATE_OF_BIRTH = amplify_core.QueryField(fieldName: "date_of_birth");
  static final GENDER = amplify_core.QueryField(fieldName: "gender");
  static final MARITAL_STATUS = amplify_core.QueryField(fieldName: "marital_status");
  static final OCCUPATION = amplify_core.QueryField(fieldName: "occupation");
  static final ANNUAL_INCOME_RANGE = amplify_core.QueryField(fieldName: "annual_income_range");
  static final CASTE_CATEGORY = amplify_core.QueryField(fieldName: "caste_category");
  static final AGE = amplify_core.QueryField(fieldName: "age");
  static final INCOME = amplify_core.QueryField(fieldName: "income");
  static final IS_KYC_VERIFIED = amplify_core.QueryField(fieldName: "is_kyc_verified");
  static final LINKED_DOCUMENTS = amplify_core.QueryField(fieldName: "linked_documents");
  static final APPLIED_SCHEMES = amplify_core.QueryField(fieldName: "applied_schemes");
  static final AADHAAR_LAST_FOUR = amplify_core.QueryField(fieldName: "aadhaar_last_four");
  static final PAN_MASKED = amplify_core.QueryField(fieldName: "pan_masked");
  static final RATION_CARD_NUMBER = amplify_core.QueryField(fieldName: "ration_card_number");
  static final IS_DISABLED = amplify_core.QueryField(fieldName: "is_disabled");
  static final DISABILITY_TYPE = amplify_core.QueryField(fieldName: "disability_type");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "CitizenProfile";
    modelSchemaDefinition.pluralName = "CitizenProfiles";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.OWNER,
        ownerField: "owner",
        identityClaim: "cognito:username",
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CitizenProfile.FULL_NAME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CitizenProfile.MOBILE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CitizenProfile.EMAIL,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CitizenProfile.STATE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CitizenProfile.DISTRICT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CitizenProfile.PINCODE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CitizenProfile.DATE_OF_BIRTH,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CitizenProfile.GENDER,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CitizenProfile.MARITAL_STATUS,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CitizenProfile.OCCUPATION,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CitizenProfile.ANNUAL_INCOME_RANGE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CitizenProfile.CASTE_CATEGORY,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CitizenProfile.AGE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CitizenProfile.INCOME,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.double)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CitizenProfile.IS_KYC_VERIFIED,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CitizenProfile.LINKED_DOCUMENTS,
      isRequired: false,
      isArray: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.collection, ofModelName: amplify_core.ModelFieldTypeEnum.string.name)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CitizenProfile.APPLIED_SCHEMES,
      isRequired: false,
      isArray: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.collection, ofModelName: amplify_core.ModelFieldTypeEnum.string.name)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CitizenProfile.AADHAAR_LAST_FOUR,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CitizenProfile.PAN_MASKED,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CitizenProfile.RATION_CARD_NUMBER,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CitizenProfile.IS_DISABLED,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CitizenProfile.DISABILITY_TYPE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'createdAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'updatedAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _CitizenProfileModelType extends amplify_core.ModelType<CitizenProfile> {
  const _CitizenProfileModelType();
  
  @override
  CitizenProfile fromJson(Map<String, dynamic> jsonData) {
    return CitizenProfile.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'CitizenProfile';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [CitizenProfile] in your schema.
 */
class CitizenProfileModelIdentifier implements amplify_core.ModelIdentifier<CitizenProfile> {
  final String id;

  /** Create an instance of CitizenProfileModelIdentifier using [id] the primary key. */
  const CitizenProfileModelIdentifier({
    required this.id});
  
  @override
  Map<String, dynamic> serializeAsMap() => (<String, dynamic>{
    'id': id
  });
  
  @override
  List<Map<String, dynamic>> serializeAsList() => serializeAsMap()
    .entries
    .map((entry) => (<String, dynamic>{ entry.key: entry.value }))
    .toList();
  
  @override
  String serializeAsString() => serializeAsMap().values.join('#');
  
  @override
  String toString() => 'CitizenProfileModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is CitizenProfileModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}