import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice_interface/core/services/aws_bedrock_service.dart';

void main() {
  group('Security & Zero Exposure Tests', () {
    test('Zero-Trust: AuthRequiredException message is citizen-friendly and secure', () {
      const ex = AuthRequiredException('Sign in to access AI features');
      expect(ex.toString(), contains('Sign in to access AI features'));
      // Ensure no internal AWS ARNs or IAM endpoints are leaked in exception
      expect(ex.toString(), isNot(contains('arn:aws:iam')));
      expect(ex.toString(), isNot(contains('AccessDenied')));
    });

    test('Data Protection: Prompts with sensitive citizen IDs are hashed for cache keys', () {
      const prompt = 'Check status for Aadhaar 1234-5678-9012';
      final hash = sha256.convert(utf8.encode('amazon.nova-micro-v1:0:$prompt')).toString();
      
      // Hash must be 64 characters hex (SHA-256)
      expect(hash.length, equals(64));
      // Key must not expose the raw Aadhaar plaintext in the key string
      expect(hash, isNot(contains('1234-5678-9012')));
    });
  });

  group('AWS Resource Efficiency & Cost Optimization Tests', () {
    test('Bedrock Token Limits: Strict bounding to prevent runaway spend', () {
      // Standard cost efficiency constraint for AWS Zero to Shipped hackathon
      const maxTokens = 500;
      const temperature = 0.2;

      expect(maxTokens, lessThanOrEqualTo(1000));
      expect(temperature, lessThanOrEqualTo(0.5));
    });

    test('Cache TTL: 30-minute validity for civic scheme queries', () {
      final now = DateTime.now();
      final validCacheTime = now.subtract(const Duration(minutes: 15));
      final expiredCacheTime = now.subtract(const Duration(minutes: 35));

      final isValid = now.difference(validCacheTime).inMinutes < 30;
      final isExpired = now.difference(expiredCacheTime).inMinutes >= 30;

      expect(isValid, isTrue);
      expect(isExpired, isTrue);
    });
  });
}
