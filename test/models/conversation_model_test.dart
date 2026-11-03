import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice_interface/models/conversation_model.dart';

void main() {
  group('Conversation and Message model tests', () {
    test('MessageModel.fromUser sets user flag and generates message ID', () {
      final msg = MessageModel.fromUser(
        text: 'How can I get PM-Kisan installment?',
        serviceTag: 'pm-kisan',
      );

      expect(msg.isUser, isTrue);
      expect(msg.text, equals('How can I get PM-Kisan installment?'));
      expect(msg.serviceTag, equals('pm-kisan'));
      expect(msg.id.startsWith('msg_'), isTrue);
    });

    test('MessageModel.fromBot sets bot flag and optional confidence', () {
      final msg = MessageModel.fromBot(
        text: 'You are eligible for Rs. 2,000 every 4 months.',
        serviceTag: 'pm-kisan',
        confidence: 0.95,
      );

      expect(msg.isUser, isFalse);
      expect(msg.confidence, equals(0.95));
      expect(msg.id.contains('_bot'), isTrue);
    });

    test('MessageModel serialization roundtrip preserves attributes', () {
      final original = MessageModel(
        id: 'msg_test_1',
        text: 'Test content',
        isUser: true,
        timestamp: DateTime(2026, 3, 1, 10, 30),
        serviceTag: 'ration',
        isServiceCard: false,
        confidence: 0.88,
      );

      final json = original.toJson();
      final restored = MessageModel.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.text, equals(original.text));
      expect(restored.isUser, equals(original.isUser));
      expect(restored.serviceTag, equals(original.serviceTag));
      expect(restored.confidence, equals(original.confidence));
    });

    test('ConversationSession tracks messages and updates title', () {
      var session = ConversationSession.create(language: 'hi');
      expect(session.isEmpty, isTrue);
      expect(session.messageCount, equals(0));
      expect(session.language, equals('hi'));

      final userMsg = MessageModel.fromUser(text: 'Pension information request');
      session = session.withMessage(userMsg);

      expect(session.isEmpty, isFalse);
      expect(session.messageCount, equals(1));
      expect(session.lastMessage?.text, equals('Pension information request'));
      expect(session.title, equals('Pension information request'));
    });
  });
}

