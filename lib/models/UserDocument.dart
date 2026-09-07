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


/** This is an auto generated class representing the UserDocument type in your schema. */
class UserDocument extends amplify_core.Model {
  static const classType = const _UserDocumentModelType();
  final String id;
  final String? _name;
  final String? _category;
  final String? _size;
  final amplify_core.TemporalDateTime? _uploadDate;
  final String? _status;
  final String? _filePath;
  final bool? _isVerified;
  final String? _verificationMessage;
  final amplify_core.TemporalDateTime? _expiryDate;
  final String? _extractedText;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  UserDocumentModelIdentifier get modelIdentifier {
      return UserDocumentModelIdentifier(
        id: id
      );
  }
  
  String get name {
    try {
      return _name!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get category {
    try {
      return _category!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get size {
    try {
      return _size!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  amplify_core.TemporalDateTime get uploadDate {
    try {
      return _uploadDate!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get status {
    try {
      return _status!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get filePath {
    return _filePath;
  }
  
  bool get isVerified {
    try {
      return _isVerified!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get verificationMessage {
    return _verificationMessage;
  }
  
  amplify_core.TemporalDateTime? get expiryDate {
    return _expiryDate;
  }
  
  String? get extractedText {
    return _extractedText;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const UserDocument._internal({required this.id, required name, required category, required size, required uploadDate, required status, filePath, required isVerified, verificationMessage, expiryDate, extractedText, createdAt, updatedAt}): _name = name, _category = category, _size = size, _uploadDate = uploadDate, _status = status, _filePath = filePath, _isVerified = isVerified, _verificationMessage = verificationMessage, _expiryDate = expiryDate, _extractedText = extractedText, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory UserDocument({String? id, required String name, required String category, required String size, required amplify_core.TemporalDateTime uploadDate, required String status, String? filePath, required bool isVerified, String? verificationMessage, amplify_core.TemporalDateTime? expiryDate, String? extractedText}) {
    return UserDocument._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      name: name,
      category: category,
      size: size,
      uploadDate: uploadDate,
      status: status,
      filePath: filePath,
      isVerified: isVerified,
      verificationMessage: verificationMessage,
      expiryDate: expiryDate,
      extractedText: extractedText);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserDocument &&
      id == other.id &&
      _name == other._name &&
      _category == other._category &&
      _size == other._size &&
      _uploadDate == other._uploadDate &&
      _status == other._status &&
      _filePath == other._filePath &&
      _isVerified == other._isVerified &&
      _verificationMessage == other._verificationMessage &&
      _expiryDate == other._expiryDate &&
      _extractedText == other._extractedText;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("UserDocument {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("name=" + "$_name" + ", ");
    buffer.write("category=" + "$_category" + ", ");
    buffer.write("size=" + "$_size" + ", ");
    buffer.write("uploadDate=" + (_uploadDate != null ? _uploadDate!.format() : "null") + ", ");
    buffer.write("status=" + "$_status" + ", ");
    buffer.write("filePath=" + "$_filePath" + ", ");
    buffer.write("isVerified=" + (_isVerified != null ? _isVerified!.toString() : "null") + ", ");
    buffer.write("verificationMessage=" + "$_verificationMessage" + ", ");
    buffer.write("expiryDate=" + (_expiryDate != null ? _expiryDate!.format() : "null") + ", ");
    buffer.write("extractedText=" + "$_extractedText" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  UserDocument copyWith({String? name, String? category, String? size, amplify_core.TemporalDateTime? uploadDate, String? status, String? filePath, bool? isVerified, String? verificationMessage, amplify_core.TemporalDateTime? expiryDate, String? extractedText}) {
    return UserDocument._internal(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      size: size ?? this.size,
      uploadDate: uploadDate ?? this.uploadDate,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      isVerified: isVerified ?? this.isVerified,
      verificationMessage: verificationMessage ?? this.verificationMessage,
      expiryDate: expiryDate ?? this.expiryDate,
      extractedText: extractedText ?? this.extractedText);
  }
  
  UserDocument copyWithModelFieldValues({
    ModelFieldValue<String>? name,
    ModelFieldValue<String>? category,
    ModelFieldValue<String>? size,
    ModelFieldValue<amplify_core.TemporalDateTime>? uploadDate,
    ModelFieldValue<String>? status,
    ModelFieldValue<String?>? filePath,
    ModelFieldValue<bool>? isVerified,
    ModelFieldValue<String?>? verificationMessage,
    ModelFieldValue<amplify_core.TemporalDateTime?>? expiryDate,
    ModelFieldValue<String?>? extractedText
  }) {
    return UserDocument._internal(
      id: id,
      name: name == null ? this.name : name.value,
      category: category == null ? this.category : category.value,
      size: size == null ? this.size : size.value,
      uploadDate: uploadDate == null ? this.uploadDate : uploadDate.value,
      status: status == null ? this.status : status.value,
      filePath: filePath == null ? this.filePath : filePath.value,
      isVerified: isVerified == null ? this.isVerified : isVerified.value,
      verificationMessage: verificationMessage == null ? this.verificationMessage : verificationMessage.value,
      expiryDate: expiryDate == null ? this.expiryDate : expiryDate.value,
      extractedText: extractedText == null ? this.extractedText : extractedText.value
    );
  }
  
  UserDocument.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _name = json['name'],
      _category = json['category'],
      _size = json['size'],
      _uploadDate = json['uploadDate'] != null ? amplify_core.TemporalDateTime.fromString(json['uploadDate']) : null,
      _status = json['status'],
      _filePath = json['filePath'],
      _isVerified = json['isVerified'],
      _verificationMessage = json['verificationMessage'],
      _expiryDate = json['expiryDate'] != null ? amplify_core.TemporalDateTime.fromString(json['expiryDate']) : null,
      _extractedText = json['extractedText'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'name': _name, 'category': _category, 'size': _size, 'uploadDate': _uploadDate?.format(), 'status': _status, 'filePath': _filePath, 'isVerified': _isVerified, 'verificationMessage': _verificationMessage, 'expiryDate': _expiryDate?.format(), 'extractedText': _extractedText, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'name': _name,
    'category': _category,
    'size': _size,
    'uploadDate': _uploadDate,
    'status': _status,
    'filePath': _filePath,
    'isVerified': _isVerified,
    'verificationMessage': _verificationMessage,
    'expiryDate': _expiryDate,
    'extractedText': _extractedText,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<UserDocumentModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<UserDocumentModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final NAME = amplify_core.QueryField(fieldName: "name");
  static final CATEGORY = amplify_core.QueryField(fieldName: "category");
  static final SIZE = amplify_core.QueryField(fieldName: "size");
  static final UPLOADDATE = amplify_core.QueryField(fieldName: "uploadDate");
  static final STATUS = amplify_core.QueryField(fieldName: "status");
  static final FILEPATH = amplify_core.QueryField(fieldName: "filePath");
  static final ISVERIFIED = amplify_core.QueryField(fieldName: "isVerified");
  static final VERIFICATIONMESSAGE = amplify_core.QueryField(fieldName: "verificationMessage");
  static final EXPIRYDATE = amplify_core.QueryField(fieldName: "expiryDate");
  static final EXTRACTEDTEXT = amplify_core.QueryField(fieldName: "extractedText");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "UserDocument";
    modelSchemaDefinition.pluralName = "UserDocuments";
    
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
      key: UserDocument.NAME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserDocument.CATEGORY,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserDocument.SIZE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserDocument.UPLOADDATE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserDocument.STATUS,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserDocument.FILEPATH,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserDocument.ISVERIFIED,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserDocument.VERIFICATIONMESSAGE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserDocument.EXPIRYDATE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserDocument.EXTRACTEDTEXT,
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

class _UserDocumentModelType extends amplify_core.ModelType<UserDocument> {
  const _UserDocumentModelType();
  
  @override
  UserDocument fromJson(Map<String, dynamic> jsonData) {
    return UserDocument.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'UserDocument';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [UserDocument] in your schema.
 */
class UserDocumentModelIdentifier implements amplify_core.ModelIdentifier<UserDocument> {
  final String id;

  /** Create an instance of UserDocumentModelIdentifier using [id] the primary key. */
  const UserDocumentModelIdentifier({
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
  String toString() => 'UserDocumentModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is UserDocumentModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}