import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../models/citizen_profile_model.dart';

class CitizenProfileService {
  static const String _getModelQuery = r'''
    query GetCitizenProfile($id: ID!) {
      getCitizenProfile(id: $id) {
        id
        full_name
        age
        income
        location
        occupation
        ownsLand
        linked_documents
        applied_schemes
      }
    }
  ''';

  static const String _updateModelMutation = r'''
    mutation UpdateCitizenProfile($input: UpdateCitizenProfileInput!) {
      updateCitizenProfile(input: $input) {
        id
      }
    }
  ''';

  static const String _createModelMutation = r'''
    mutation CreateCitizenProfile($input: CreateCitizenProfileInput!) {
      createCitizenProfile(input: $input) {
        id
      }
    }
  ''';

  Future<CitizenProfileModel?> fetchProfile(String userId) async {
    try {
      final request = GraphQLRequest<String>(
        document: _getModelQuery,
        variables: {'id': userId},
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        final data = json.decode(response.data!);
        final profileData = data['getCitizenProfile'];
        if (profileData != null) {
          return CitizenProfileModel.fromJson(profileData);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching citizen profile: $e');
      return null;
    }
  }

  Future<bool> saveProfile(CitizenProfileModel profile) async {
    try {
      // Try to update first, if fails, create (or check existence first)
      // For DynamoDB, typically we use a sync or get check first
      final input = profile.toJson();

      final updateRequest = GraphQLRequest<String>(
        document: _updateModelMutation,
        variables: {'input': input},
      );

      final response =
          await Amplify.API.mutate(request: updateRequest).response;

      if (response.errors.isNotEmpty) {
        // If update failed because it doesn't exist, create it
        final createRequest = GraphQLRequest<String>(
          document: _createModelMutation,
          variables: {'input': input},
        );
        await Amplify.API.mutate(request: createRequest).response;
      }
      return true;
    } catch (e) {
      debugPrint('Error saving citizen profile: $e');
      return false;
    }
  }
}
