import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice_interface/models/citizen_profile_model.dart';

void main() {
  group('CitizenProfileModel tests', () {
    test('computedAge calculates age correctly from dateOfBirth', () {
      final now = DateTime.now();
      final dob = DateTime(now.year - 30, now.month, now.day);
      final profile = CitizenProfileModel(
        id: 'user_1',
        fullName: 'Ramesh Patel',
        mobile: '9876543210',
        email: 'ramesh@example.com',
        state: 'Maharashtra',
        dateOfBirth: dob,
      );

      expect(profile.computedAge, equals(30));
    });

    test('computedAge falls back to stored age when dateOfBirth is null', () {
      const profile = CitizenProfileModel(
        id: 'user_2',
        fullName: 'Priya Sharma',
        mobile: '9876543211',
        email: 'priya@example.com',
        state: 'Delhi',
        age: 45,
      );

      expect(profile.computedAge, equals(45));
    });

    test('profileCompletionPercent calculates completion score accurately', () {
      final incompleteProfile = CitizenProfileModel(
        id: 'user_3',
        fullName: 'Aarav Gupta',
        mobile: '9876543212',
        email: '',
        state: 'Not Set',
      );

      // Only fullName (1) and mobile (1) are filled -> 2/10 = 20%
      expect(incompleteProfile.profileCompletionPercent, equals(20));
      expect(incompleteProfile.isProfileIncomplete, isTrue);

      final completeProfile = CitizenProfileModel(
        id: 'user_4',
        fullName: 'Kavita Devi',
        mobile: '9876543213',
        email: 'kavita@example.com',
        state: 'Uttar Pradesh',
        district: 'Lucknow',
        dateOfBirth: DateTime(1985, 5, 20),
        gender: 'Female',
        maritalStatus: 'Married',
        occupation: 'Farmer',
        annualIncomeRange: '1L-3L',
        aadhaarLastFour: '4321',
      );

      expect(completeProfile.profileCompletionPercent, equals(100));
      expect(completeProfile.isProfileIncomplete, isFalse);
    });

    test('serialization roundtrip produces equivalent profile', () {
      final original = CitizenProfileModel(
        id: 'user_5',
        fullName: 'Sunil Rao',
        mobile: '9876543214',
        email: 'sunil@example.com',
        state: 'Karnataka',
        district: 'Bengaluru',
        pincode: '560001',
        dateOfBirth: DateTime(1992, 10, 15),
        gender: 'Male',
        maritalStatus: 'Single',
        occupation: 'Self-Employed',
        annualIncomeRange: '3L-5L',
        casteCategory: 'General',
        aadhaarLastFour: '7890',
        panMasked: 'ABCDE****G',
        isDisabled: false,
      );

      final json = original.toJson();
      final restored = CitizenProfileModel.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.fullName, equals(original.fullName));
      expect(restored.mobile, equals(original.mobile));
      expect(restored.state, equals(original.state));
      expect(restored.district, equals(original.district));
      expect(restored.aadhaarLastFour, equals(original.aadhaarLastFour));
      expect(restored.occupation, equals(original.occupation));
    });

    test('copyWith creates modified clone while keeping original fields intact', () {
      const original = CitizenProfileModel(
        id: 'user_6',
        fullName: 'Original Name',
        mobile: '9876543215',
        email: 'original@example.com',
        state: 'Punjab',
      );

      final updated = original.copyWith(
        fullName: 'Updated Name',
        state: 'Haryana',
      );

      expect(updated.id, equals(original.id));
      expect(updated.fullName, equals('Updated Name'));
      expect(updated.state, equals('Haryana'));
      expect(updated.mobile, equals(original.mobile));
      expect(updated.email, equals(original.email));
    });
  });
}

