import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice_interface/core/utils/helpers.dart';

void main() {
  group('Helpers utility tests', () {
    test('getInitials extracts initials correctly', () {
      expect(getInitials('Ramesh Kumar'), equals('RK'));
      expect(getInitials('Priya'), equals('P'));
      expect(getInitials(''), equals('?'));
      expect(getInitials('   '), equals('?'));
      expect(getInitials('  Amit   Sharma  '), equals('AS'));
      expect(getInitials('Sardar Vallabhbhai Patel'), equals('SV'));
    });

    test('maskAadhaar masks all but last 4 digits', () {
      expect(maskAadhaar('123456789012'), equals('XXXX-XXXX-9012'));
      expect(maskAadhaar('9012'), equals('XXXX-XXXX-9012'));
      expect(maskAadhaar('123'), equals('123'));
    });

    test('isValidEmail correctly identifies valid and invalid formats', () {
      expect(isValidEmail('citizen@gov.in'), isTrue);
      expect(isValidEmail('test.user@domain.com'), isTrue);
      expect(isValidEmail('plainaddress'), isFalse);
      expect(isValidEmail('user@.com'), isFalse);
      expect(isValidEmail('@domain.com'), isFalse);
    });

    test('isValidIndianPhone validates 10-digit Indian numbers', () {
      expect(isValidIndianPhone('9876543210'), isTrue);
      expect(isValidIndianPhone('8123456789'), isTrue);
      expect(isValidIndianPhone('7000000000'), isTrue);
      expect(isValidIndianPhone('6123456789'), isTrue);
      expect(isValidIndianPhone('+919876543210'), isTrue);
      expect(isValidIndianPhone('+91 9876543210'), isTrue);

      // Invalid cases
      expect(isValidIndianPhone('1234567890'), isFalse); // Does not start with 6-9
      expect(isValidIndianPhone('98765'), isFalse); // Too short
      expect(isValidIndianPhone('987654321012'), isFalse); // Too long
    });

    test('timeAgo returns expected relative time descriptions', () {
      final now = DateTime.now();
      expect(timeAgo(now), equals('Just now'));
      expect(timeAgo(now.subtract(const Duration(minutes: 5))), equals('5m ago'));
      expect(timeAgo(now.subtract(const Duration(hours: 3))), equals('3h ago'));
      expect(timeAgo(now.subtract(const Duration(days: 2))), equals('2d ago'));

      final pastDate = DateTime(2020, 1, 15);
      expect(timeAgo(pastDate), equals('15/1/2020'));
    });
  });
}

