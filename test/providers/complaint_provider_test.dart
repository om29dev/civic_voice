import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice_interface/providers/complaint_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ComplaintProvider tests', () {
    test('initializes with empty complaints and no draft', () {
      final provider = ComplaintProvider();
      expect(provider.complaints, isEmpty);
      expect(provider.draftComplaint, isNull);
      expect(provider.isProcessing, isFalse);
    });

    test('attachImage does not throw when no draft exists', () {
      final provider = ComplaintProvider();
      expect(() => provider.attachImage('sample_base64'), returnsNormally);
      expect(provider.draftComplaint, isNull);
    });

    test('discardDraft clears draft complaint and notifies listeners', () {
      final provider = ComplaintProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.discardDraft();

      expect(provider.draftComplaint, isNull);
      expect(notifyCount, equals(1));
    });

    test('submitComplaint is safe to call when draft is null', () async {
      final provider = ComplaintProvider();
      await provider.submitComplaint();
      expect(provider.complaints, isEmpty);
    });
  });
}
