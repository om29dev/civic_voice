import 'package:amplify_flutter/amplify_flutter.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../models/application_model.dart';
import '../models/family_member_model.dart';
import '../models/citizen_profile_model.dart';
import '../core/services/citizen_profile_service.dart';

enum UserType { guest, registered, premium }

class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final UserType userType;
  final bool isVerified;
  final int applicationsCount;
  final int completedCount;
  final int pendingCount;
  final DateTime? joinDate;
  final List<UserDocument> documents;
  final List<UserApplication> applications;
  final List<FamilyMember> familyMembers;

  // Personalized demographic fields synced with CitizenProfileModel
  final int? age;
  final double? annualIncome;
  final String? annualIncomeRange;
  final String? occupation;
  final String? location;
  final String? gender;
  final String? casteCategory;
  final bool ownsLand;
  final Map<String, dynamic> preferences;

  UserProfile({
    required this.name,
    required this.email,
    this.phone = '',
    this.avatarUrl = '',
    required this.userType,
    this.isVerified = false,
    this.applicationsCount = 0,
    this.completedCount = 0,
    this.pendingCount = 0,
    this.joinDate,
    this.documents = const [],
    this.applications = const [],
    this.familyMembers = const [],
    this.age,
    this.annualIncome,
    this.annualIncomeRange,
    this.occupation,
    this.location,
    this.gender,
    this.casteCategory,
    this.ownsLand = false,
    this.preferences = const {'theme_mode': 'system', 'language': 'en'},
  });

  factory UserProfile.guest() {
    return UserProfile(
      name: 'Guest User',
      email: 'guest@civic.app',
      userType: UserType.guest,
      isVerified: false,
    );
  }

  factory UserProfile.registered({
    required String name,
    required String email,
    String phone = '',
    String avatarUrl = '',
    bool isVerified = false,
    int applicationsCount = 0,
    int completedCount = 0,
    int pendingCount = 0,
    List<UserDocument>? documents,
    List<UserApplication>? applications,
    List<FamilyMember>? familyMembers,
    int? age,
    double? annualIncome,
    String? annualIncomeRange,
    String? occupation,
    String? location,
    String? gender,
    String? casteCategory,
    bool ownsLand = false,
  }) {
    return UserProfile(
      name: name,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
      userType: UserType.registered,
      isVerified: isVerified,
      applicationsCount: applicationsCount,
      completedCount: completedCount,
      pendingCount: pendingCount,
      joinDate: DateTime.now(),
      documents: documents ?? [],
      applications: applications ?? [],
      familyMembers: familyMembers ?? [],
      age: age,
      annualIncome: annualIncome,
      annualIncomeRange: annualIncomeRange,
      occupation: occupation,
      location: location,
      gender: gender,
      casteCategory: casteCategory,
      ownsLand: ownsLand,
    );
  }

  bool get isGuest => userType == UserType.guest;
  bool get isRegistered =>
      userType == UserType.registered || userType == UserType.premium;

  bool get isProfileComplete =>
      age != null && annualIncome != null && location != null;

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    UserType? userType,
    bool? isVerified,
    List<UserDocument>? documents,
    List<UserApplication>? applications,
    List<FamilyMember>? familyMembers,
    int? age,
    double? annualIncome,
    String? annualIncomeRange,
    String? occupation,
    String? location,
    String? gender,
    String? casteCategory,
    bool? ownsLand,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      userType: userType ?? this.userType,
      isVerified: isVerified ?? this.isVerified,
      applicationsCount: applications?.length ?? applicationsCount,
      completedCount: applications
              ?.where((a) => a.status == ApplicationStatus.approved)
              .length ??
          completedCount,
      pendingCount: applications
              ?.where((a) =>
                  a.status == ApplicationStatus.submitted ||
                  a.status == ApplicationStatus.verified)
              .length ??
          pendingCount,
      joinDate: joinDate,
      documents: documents ?? this.documents,
      applications: applications ?? this.applications,
      familyMembers: familyMembers ?? this.familyMembers,
      age: age ?? this.age,
      annualIncome: annualIncome ?? this.annualIncome,
      annualIncomeRange: annualIncomeRange ?? this.annualIncomeRange,
      occupation: occupation ?? this.occupation,
      location: location ?? this.location,
      gender: gender ?? this.gender,
      casteCategory: casteCategory ?? this.casteCategory,
      ownsLand: ownsLand ?? this.ownsLand,
      preferences: preferences ?? this.preferences,
    );
  }
}

class UserProvider extends ChangeNotifier {
  final CitizenProfileService _citizenProfileService = CitizenProfileService();
  UserProfile _currentUser = UserProfile.guest();

  UserProfile get currentUser => _currentUser;
  bool get isGuest => _currentUser.isGuest;
  bool get isLoggedIn => _currentUser.isRegistered;
  bool get isProfileComplete => _currentUser.isProfileComplete;

  void loginAsGuest() {
    _currentUser = UserProfile.guest();
    notifyListeners();
  }

  void login({
    required String name,
    required String email,
    String phone = '',
    String avatarUrl = '',
    bool isVerified = false,
    int? age,
    double? annualIncome,
    String? annualIncomeRange,
    String? occupation,
    String? location,
    String? gender,
    String? casteCategory,
    bool ownsLand = false,
    Map<String, dynamic>? preferences,
  }) {
    _currentUser = UserProfile.registered(
      name: name,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
      isVerified: isVerified,
      applicationsCount: _currentUser.applicationsCount,
      completedCount: _currentUser.completedCount,
      pendingCount: _currentUser.pendingCount,
      documents: _currentUser.documents,
      applications: _currentUser.applications,
      familyMembers: _currentUser.familyMembers,
      age: age,
      annualIncome: annualIncome,
      annualIncomeRange: annualIncomeRange,
      occupation: occupation,
      location: location,
      gender: gender,
      casteCategory: casteCategory,
      ownsLand: ownsLand,
    );
    if (preferences != null) {
      _currentUser = _currentUser.copyWith(preferences: preferences);
    }
    notifyListeners();
  }

  /// Synchronizes UserProvider state from a CitizenProfileModel instance.
  void syncFromCitizenProfile(CitizenProfileModel profile) {
    _currentUser = _currentUser.copyWith(
      name: profile.fullName.isNotEmpty ? profile.fullName : _currentUser.name,
      email: profile.email.isNotEmpty ? profile.email : _currentUser.email,
      phone: profile.mobile.isNotEmpty ? profile.mobile : _currentUser.phone,
      userType: UserType.registered,
      isVerified: profile.isKycVerified,
      age: profile.computedAge > 0 ? profile.computedAge : _currentUser.age,
      annualIncome:
          profile.income > 0 ? profile.income : _currentUser.annualIncome,
      annualIncomeRange:
          profile.annualIncomeRange ?? _currentUser.annualIncomeRange,
      occupation: profile.occupation ?? _currentUser.occupation,
      location:
          profile.state.isNotEmpty ? profile.state : _currentUser.location,
      gender: profile.gender ?? _currentUser.gender,
      casteCategory: profile.casteCategory ?? _currentUser.casteCategory,
    );
    notifyListeners();
  }

  /// Fetch user profile from AppSync GraphQL (querying valid schema fields on User and CitizenProfile).
  Future<void> fetchUserProfile(String userId) async {
    try {
      const query = r'''
        query GetUser($id: ID!) {
          getUser(id: $id) {
            id
            name
            email
            mobile
            language
            isGuest
          }
        }
      ''';

      final operation = Amplify.API.query(
        request: GraphQLRequest<String>(
          document: query,
          variables: {'id': userId},
          authorizationMode: APIAuthorizationType.userPools,
        ),
      );

      final response = await operation.response;
      Map<String, dynamic>? user;
      if (response.data != null) {
        final data = json.decode(response.data!) as Map<String, dynamic>;
        user = data['getUser'] as Map<String, dynamic>?;
      }

      final citizenProfile = await _citizenProfileService.fetchProfile(userId);

      if (citizenProfile != null) {
        login(
          name: citizenProfile.fullName.isNotEmpty
              ? citizenProfile.fullName
              : (user?['name'] as String? ?? 'Citizen'),
          email: citizenProfile.email.isNotEmpty
              ? citizenProfile.email
              : (user?['email'] as String? ?? ''),
          phone: citizenProfile.mobile.isNotEmpty
              ? citizenProfile.mobile
              : (user?['mobile'] as String? ?? ''),
          isVerified: citizenProfile.isKycVerified,
          age: citizenProfile.computedAge,
          annualIncome: citizenProfile.income,
          annualIncomeRange: citizenProfile.annualIncomeRange,
          location: citizenProfile.state,
          occupation: citizenProfile.occupation,
          gender: citizenProfile.gender,
          casteCategory: citizenProfile.casteCategory,
        );
      } else if (user != null) {
        login(
          name: user['name'] as String? ?? 'Citizen',
          email: user['email'] as String? ?? '',
          phone: user['mobile'] as String? ?? '',
          isVerified: !(user['isGuest'] as bool? ?? false),
        );
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  void addApplication(UserApplication app) {
    final List<UserApplication> updatedApps =
        List.from(_currentUser.applications)..add(app);
    _currentUser = _currentUser.copyWith(applications: updatedApps);
    notifyListeners();
  }

  void updateApplicationStatus(String id, ApplicationStatus status,
      {String? currentStep, String? nextStep, ApplicationEvent? newEvent}) {
    final List<UserApplication> updatedApps =
        _currentUser.applications.map((app) {
      if (app.id == id) {
        final List<ApplicationEvent> updatedTimeline = List.from(app.timeline);
        if (newEvent != null) updatedTimeline.add(newEvent);

        return UserApplication(
          id: app.id,
          schemeId: app.schemeId,
          schemeName: app.schemeName,
          status: status,
          submissionDate: app.submissionDate,
          currentStep: currentStep ?? app.currentStep,
          nextStep: nextStep ?? app.nextStep,
          timeline: updatedTimeline,
        );
      }
      return app;
    }).toList();

    _currentUser = _currentUser.copyWith(applications: updatedApps);
    notifyListeners();
  }

  void updateProfile({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    int? age,
    double? annualIncome,
    String? annualIncomeRange,
    String? occupation,
    String? location,
    String? gender,
    String? casteCategory,
    bool? ownsLand,
  }) {
    _currentUser = _currentUser.copyWith(
      name: name,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
      age: age,
      annualIncome: annualIncome,
      annualIncomeRange: annualIncomeRange,
      occupation: occupation,
      location: location,
      gender: gender,
      casteCategory: casteCategory,
      ownsLand: ownsLand,
    );
    notifyListeners();
    _syncToAws();
  }

  Future<void> _syncToAws() async {
    try {
      final authUser = await Amplify.Auth.getCurrentUser();
      const mutation = r'''
        mutation UpdateUser($input: UpdateUserInput!) {
          updateUser(input: $input) {
            id
          }
        }
      ''';

      final input = {
        'id': authUser.userId,
        'name': _currentUser.name,
        'email': _currentUser.email,
        'mobile': _currentUser.phone,
        'language': _currentUser.preferences['language'] ?? 'en',
        'isGuest': _currentUser.isGuest,
      };

      await Amplify.API
          .mutate(
            request: GraphQLRequest<String>(
              document: mutation,
              variables: {'input': input},
              authorizationMode: APIAuthorizationType.userPools,
            ),
          )
          .response;
    } catch (e) {
      debugPrint('Error syncing profile: $e');
    }
  }

  void updatePreference(String key, dynamic value) {
    final Map<String, dynamic> updatedPrefs = Map.from(_currentUser.preferences)
      ..[key] = value;
    _currentUser = _currentUser.copyWith(preferences: updatedPrefs);
    notifyListeners();
    _syncToAws();
  }

  void addDocument(UserDocument document) {
    final List<UserDocument> updatedDocs = List.from(_currentUser.documents)
      ..add(document);
    _currentUser = _currentUser.copyWith(documents: updatedDocs);
    notifyListeners();
  }

  void removeDocument(String id) {
    final List<UserDocument> updatedDocs =
        _currentUser.documents.where((doc) => doc.id != id).toList();
    _currentUser = _currentUser.copyWith(documents: updatedDocs);
    notifyListeners();
  }

  void logout() {
    _currentUser = UserProfile.guest();
    notifyListeners();
  }

  void addFamilyMember(FamilyMember member) {
    final List<FamilyMember> updatedMembers =
        List.from(_currentUser.familyMembers)..add(member);
    _currentUser = _currentUser.copyWith(familyMembers: updatedMembers);
    notifyListeners();
  }

  void removeFamilyMember(String id) {
    final List<FamilyMember> updatedMembers =
        _currentUser.familyMembers.where((m) => m.id != id).toList();
    _currentUser = _currentUser.copyWith(familyMembers: updatedMembers);
    notifyListeners();
  }

  void verifyUser() {
    if (_currentUser.isRegistered) {
      _currentUser = _currentUser.copyWith(isVerified: true);
      notifyListeners();
    }
  }
}
