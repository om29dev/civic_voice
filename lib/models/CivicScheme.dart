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


/** This is an auto generated class representing the CivicScheme type in your schema. */
class CivicScheme extends amplify_core.Model {
  static const classType = const _CivicSchemeModelType();
  final String id;
  final String? _title;
  final String? _shortTitle;
  final String? _description;
  final String? _category;
  final String? _level;
  final String? _schemeFor;
  final String? _beneficiaryState;
  final String? _nodalMinistry;
  final List<String>? _tags;
  final List<String>? _eligibilityCriteria;
  final String? _applicationProcess;
  final String? _closeDate;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  CivicSchemeModelIdentifier get modelIdentifier {
      return CivicSchemeModelIdentifier(
        id: id
      );
  }
  
  String get title {
    try {
      return _title!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get shortTitle {
    return _shortTitle;
  }
  
  String get description {
    try {
      return _description!;
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
  
  String? get level {
    return _level;
  }
  
  String? get schemeFor {
    return _schemeFor;
  }
  
  String? get beneficiaryState {
    return _beneficiaryState;
  }
  
  String? get nodalMinistry {
    return _nodalMinistry;
  }
  
  List<String>? get tags {
    return _tags;
  }
  
  List<String>? get eligibilityCriteria {
    return _eligibilityCriteria;
  }
  
  String? get applicationProcess {
    return _applicationProcess;
  }
  
  String? get closeDate {
    return _closeDate;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const CivicScheme._internal({required this.id, required title, shortTitle, required description, required category, level, schemeFor, beneficiaryState, nodalMinistry, tags, eligibilityCriteria, applicationProcess, closeDate, createdAt, updatedAt}): _title = title, _shortTitle = shortTitle, _description = description, _category = category, _level = level, _schemeFor = schemeFor, _beneficiaryState = beneficiaryState, _nodalMinistry = nodalMinistry, _tags = tags, _eligibilityCriteria = eligibilityCriteria, _applicationProcess = applicationProcess, _closeDate = closeDate, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory CivicScheme({String? id, required String title, String? shortTitle, required String description, required String category, String? level, String? schemeFor, String? beneficiaryState, String? nodalMinistry, List<String>? tags, List<String>? eligibilityCriteria, String? applicationProcess, String? closeDate}) {
    return CivicScheme._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      title: title,
      shortTitle: shortTitle,
      description: description,
      category: category,
      level: level,
      schemeFor: schemeFor,
      beneficiaryState: beneficiaryState,
      nodalMinistry: nodalMinistry,
      tags: tags != null ? List<String>.unmodifiable(tags) : tags,
      eligibilityCriteria: eligibilityCriteria != null ? List<String>.unmodifiable(eligibilityCriteria) : eligibilityCriteria,
      applicationProcess: applicationProcess,
      closeDate: closeDate);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CivicScheme &&
      id == other.id &&
      _title == other._title &&
      _shortTitle == other._shortTitle &&
      _description == other._description &&
      _category == other._category &&
      _level == other._level &&
      _schemeFor == other._schemeFor &&
      _beneficiaryState == other._beneficiaryState &&
      _nodalMinistry == other._nodalMinistry &&
      DeepCollectionEquality().equals(_tags, other._tags) &&
      DeepCollectionEquality().equals(_eligibilityCriteria, other._eligibilityCriteria) &&
      _applicationProcess == other._applicationProcess &&
      _closeDate == other._closeDate;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("CivicScheme {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("title=" + "$_title" + ", ");
    buffer.write("shortTitle=" + "$_shortTitle" + ", ");
    buffer.write("description=" + "$_description" + ", ");
    buffer.write("category=" + "$_category" + ", ");
    buffer.write("level=" + "$_level" + ", ");
    buffer.write("schemeFor=" + "$_schemeFor" + ", ");
    buffer.write("beneficiaryState=" + "$_beneficiaryState" + ", ");
    buffer.write("nodalMinistry=" + "$_nodalMinistry" + ", ");
    buffer.write("tags=" + (_tags != null ? _tags!.toString() : "null") + ", ");
    buffer.write("eligibilityCriteria=" + (_eligibilityCriteria != null ? _eligibilityCriteria!.toString() : "null") + ", ");
    buffer.write("applicationProcess=" + "$_applicationProcess" + ", ");
    buffer.write("closeDate=" + "$_closeDate" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  CivicScheme copyWith({String? title, String? shortTitle, String? description, String? category, String? level, String? schemeFor, String? beneficiaryState, String? nodalMinistry, List<String>? tags, List<String>? eligibilityCriteria, String? applicationProcess, String? closeDate}) {
    return CivicScheme._internal(
      id: id,
      title: title ?? this.title,
      shortTitle: shortTitle ?? this.shortTitle,
      description: description ?? this.description,
      category: category ?? this.category,
      level: level ?? this.level,
      schemeFor: schemeFor ?? this.schemeFor,
      beneficiaryState: beneficiaryState ?? this.beneficiaryState,
      nodalMinistry: nodalMinistry ?? this.nodalMinistry,
      tags: tags ?? this.tags,
      eligibilityCriteria: eligibilityCriteria ?? this.eligibilityCriteria,
      applicationProcess: applicationProcess ?? this.applicationProcess,
      closeDate: closeDate ?? this.closeDate);
  }
  
  CivicScheme copyWithModelFieldValues({
    ModelFieldValue<String>? title,
    ModelFieldValue<String?>? shortTitle,
    ModelFieldValue<String>? description,
    ModelFieldValue<String>? category,
    ModelFieldValue<String?>? level,
    ModelFieldValue<String?>? schemeFor,
    ModelFieldValue<String?>? beneficiaryState,
    ModelFieldValue<String?>? nodalMinistry,
    ModelFieldValue<List<String>?>? tags,
    ModelFieldValue<List<String>?>? eligibilityCriteria,
    ModelFieldValue<String?>? applicationProcess,
    ModelFieldValue<String?>? closeDate
  }) {
    return CivicScheme._internal(
      id: id,
      title: title == null ? this.title : title.value,
      shortTitle: shortTitle == null ? this.shortTitle : shortTitle.value,
      description: description == null ? this.description : description.value,
      category: category == null ? this.category : category.value,
      level: level == null ? this.level : level.value,
      schemeFor: schemeFor == null ? this.schemeFor : schemeFor.value,
      beneficiaryState: beneficiaryState == null ? this.beneficiaryState : beneficiaryState.value,
      nodalMinistry: nodalMinistry == null ? this.nodalMinistry : nodalMinistry.value,
      tags: tags == null ? this.tags : tags.value,
      eligibilityCriteria: eligibilityCriteria == null ? this.eligibilityCriteria : eligibilityCriteria.value,
      applicationProcess: applicationProcess == null ? this.applicationProcess : applicationProcess.value,
      closeDate: closeDate == null ? this.closeDate : closeDate.value
    );
  }
  
  CivicScheme.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _title = json['title'],
      _shortTitle = json['shortTitle'],
      _description = json['description'],
      _category = json['category'],
      _level = json['level'],
      _schemeFor = json['schemeFor'],
      _beneficiaryState = json['beneficiaryState'],
      _nodalMinistry = json['nodalMinistry'],
      _tags = json['tags']?.cast<String>(),
      _eligibilityCriteria = json['eligibilityCriteria']?.cast<String>(),
      _applicationProcess = json['applicationProcess'],
      _closeDate = json['closeDate'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'title': _title, 'shortTitle': _shortTitle, 'description': _description, 'category': _category, 'level': _level, 'schemeFor': _schemeFor, 'beneficiaryState': _beneficiaryState, 'nodalMinistry': _nodalMinistry, 'tags': _tags, 'eligibilityCriteria': _eligibilityCriteria, 'applicationProcess': _applicationProcess, 'closeDate': _closeDate, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'title': _title,
    'shortTitle': _shortTitle,
    'description': _description,
    'category': _category,
    'level': _level,
    'schemeFor': _schemeFor,
    'beneficiaryState': _beneficiaryState,
    'nodalMinistry': _nodalMinistry,
    'tags': _tags,
    'eligibilityCriteria': _eligibilityCriteria,
    'applicationProcess': _applicationProcess,
    'closeDate': _closeDate,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<CivicSchemeModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<CivicSchemeModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final TITLE = amplify_core.QueryField(fieldName: "title");
  static final SHORTTITLE = amplify_core.QueryField(fieldName: "shortTitle");
  static final DESCRIPTION = amplify_core.QueryField(fieldName: "description");
  static final CATEGORY = amplify_core.QueryField(fieldName: "category");
  static final LEVEL = amplify_core.QueryField(fieldName: "level");
  static final SCHEMEFOR = amplify_core.QueryField(fieldName: "schemeFor");
  static final BENEFICIARYSTATE = amplify_core.QueryField(fieldName: "beneficiaryState");
  static final NODALMINISTRY = amplify_core.QueryField(fieldName: "nodalMinistry");
  static final TAGS = amplify_core.QueryField(fieldName: "tags");
  static final ELIGIBILITYCRITERIA = amplify_core.QueryField(fieldName: "eligibilityCriteria");
  static final APPLICATIONPROCESS = amplify_core.QueryField(fieldName: "applicationProcess");
  static final CLOSEDATE = amplify_core.QueryField(fieldName: "closeDate");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "CivicScheme";
    modelSchemaDefinition.pluralName = "CivicSchemes";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PRIVATE,
        operations: const [
          amplify_core.ModelOperation.READ,
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE
        ])
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CivicScheme.TITLE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CivicScheme.SHORTTITLE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CivicScheme.DESCRIPTION,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CivicScheme.CATEGORY,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CivicScheme.LEVEL,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CivicScheme.SCHEMEFOR,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CivicScheme.BENEFICIARYSTATE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CivicScheme.NODALMINISTRY,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CivicScheme.TAGS,
      isRequired: false,
      isArray: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.collection, ofModelName: amplify_core.ModelFieldTypeEnum.string.name)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CivicScheme.ELIGIBILITYCRITERIA,
      isRequired: false,
      isArray: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.collection, ofModelName: amplify_core.ModelFieldTypeEnum.string.name)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CivicScheme.APPLICATIONPROCESS,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: CivicScheme.CLOSEDATE,
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

class _CivicSchemeModelType extends amplify_core.ModelType<CivicScheme> {
  const _CivicSchemeModelType();
  
  @override
  CivicScheme fromJson(Map<String, dynamic> jsonData) {
    return CivicScheme.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'CivicScheme';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [CivicScheme] in your schema.
 */
class CivicSchemeModelIdentifier implements amplify_core.ModelIdentifier<CivicScheme> {
  final String id;

  /** Create an instance of CivicSchemeModelIdentifier using [id] the primary key. */
  const CivicSchemeModelIdentifier({
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
  String toString() => 'CivicSchemeModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is CivicSchemeModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}