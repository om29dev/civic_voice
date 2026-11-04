import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Uses the Google Translate endpoint to translate UI strings reliably.
/// Chunks requests into small batches and verifies output length so keys
/// never shift or map to the wrong translation.
class TranslationService {
  TranslationService._();

  static const _baseUrl = 'https://translate.googleapis.com/translate_a/single';
  static const _sep = '\n||||\n';
  static const int _chunkSize = 12;

  /// In-memory cache: langCode -> {key -> translatedString}
  static final Map<String, Map<String, String>> _memCache = {};

  static String _cacheKey(String langCode) => 'cvi_translations_v2_$langCode';

  /// Load cached translations for [langCode] from SharedPreferences.
  static Future<Map<String, String>?> loadCache(String langCode) async {
    if (_memCache.containsKey(langCode)) {
      return Map<String, String>.from(_memCache[langCode]!);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey(langCode));
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final result = decoded.map((k, v) => MapEntry(k, v.toString()));
      _memCache[langCode] = Map<String, String>.from(result);
      return result;
    } catch (_) {
      return null;
    }
  }

  /// Persist [translations] for [langCode] to SharedPreferences.
  static Future<void> saveCache(
    String langCode,
    Map<String, String> translations,
  ) async {
    try {
      final merged = <String, String>{
        if (_memCache[langCode] != null) ..._memCache[langCode]!,
        ...translations,
      };
      _memCache[langCode] = merged;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey(langCode), jsonEncode(merged));
    } catch (_) {}
  }

  /// Translate a single string safely.
  static Future<String> _translateSingle(
    String text,
    String targetLang,
  ) async {
    if (targetLang == 'en' || text.trim().isEmpty) return text;
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'client': 'gtx',
        'sl': 'en',
        'tl': targetLang,
        'dt': 't',
        'q': text,
      });

      final response = await http
          .get(uri, headers: {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return text;
      final json = jsonDecode(response.body) as List<dynamic>;
      final chunks = json[0] as List<dynamic>;
      final translated = chunks
          .map((c) => (c as List<dynamic>)[0]?.toString() ?? '')
          .join('')
          .trim();
      return translated.isEmpty ? text : translated;
    } catch (_) {
      return text;
    }
  }

  /// Translate a small chunk of single-line entries, falling back to
  /// individual translation if the delimiter count does not match.
  static Future<Map<String, String>> _translateChunk(
    List<MapEntry<String, String>> entries,
    String targetLang,
  ) async {
    if (entries.isEmpty) return {};
    if (entries.length == 1) {
      final single = await _translateSingle(entries.first.value, targetLang);
      return {entries.first.key: single};
    }

    final keys = entries.map((e) => e.key).toList();
    final texts = entries.map((e) => e.value).toList();
    final joined = texts.join(_sep);

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'client': 'gtx',
        'sl': 'en',
        'tl': targetLang,
        'dt': 't',
        'q': joined,
      });

      final response = await http
          .get(uri, headers: {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List<dynamic>;
        final chunks = json[0] as List<dynamic>;
        final rawTranslated = chunks
            .map((c) => (c as List<dynamic>)[0]?.toString() ?? '')
            .join('');

        final parts = rawTranslated
            .split(RegExp(r'\n?\s*\|\|\|\|\s*\n?'))
            .map((s) => s.trim())
            .toList();

        if (parts.length == entries.length) {
          final result = <String, String>{};
          for (var i = 0; i < entries.length; i++) {
            result[keys[i]] = parts[i].isNotEmpty ? parts[i] : texts[i];
          }
          return result;
        }
      }
    } catch (_) {}

    // Fallback: translate each item in this chunk individually to prevent index shift
    final individualResults = await Future.wait(
      entries.map((e) async {
        final t = await _translateSingle(e.value, targetLang);
        return MapEntry(e.key, t);
      }),
    );
    return Map.fromEntries(individualResults);
  }

  /// Translate a [batch] of {key -> englishText} pairs to [targetLang].
  static Future<Map<String, String>> translateBatch(
    Map<String, String> batch,
    String targetLang,
  ) async {
    if (targetLang == 'en' || batch.isEmpty) {
      return Map.from(batch);
    }

    final result = <String, String>{};
    final singleLineEntries = <MapEntry<String, String>>[];
    final multiLineEntries = <MapEntry<String, String>>[];

    for (final entry in batch.entries) {
      if (entry.value.contains('\n') || entry.value.contains('|')) {
        multiLineEntries.add(entry);
      } else {
        singleLineEntries.add(entry);
      }
    }

    // Process single-line entries in chunks
    final chunks = <List<MapEntry<String, String>>>[];
    for (var i = 0; i < singleLineEntries.length; i += _chunkSize) {
      final end = (i + _chunkSize < singleLineEntries.length)
          ? i + _chunkSize
          : singleLineEntries.length;
      chunks.add(singleLineEntries.sublist(i, end));
    }

    // Run up to 3 chunks concurrently to balance speed and rate limits
    for (var i = 0; i < chunks.length; i += 3) {
      final slice = chunks.sublist(
        i,
        (i + 3 < chunks.length) ? i + 3 : chunks.length,
      );
      final chunkMaps = await Future.wait(
        slice.map((c) => _translateChunk(c, targetLang)),
      );
      for (final m in chunkMaps) {
        result.addAll(m);
      }
    }

    // Process multi-line entries individually in small parallel groups
    for (var i = 0; i < multiLineEntries.length; i += 4) {
      final slice = multiLineEntries.sublist(
        i,
        (i + 4 < multiLineEntries.length) ? i + 4 : multiLineEntries.length,
      );
      final pairs = await Future.wait(
        slice.map((e) async {
          final translated = await _translateSingle(e.value, targetLang);
          return MapEntry(e.key, translated);
        }),
      );
      result.addAll(Map.fromEntries(pairs));
    }

    return result;
  }

  /// Translate all [englishStrings] to [targetLang].
  /// Checks in-memory and SharedPreferences cache first.
  static Future<Map<String, String>> translateAll(
    Map<String, String> englishStrings,
    String targetLang,
  ) async {
    if (targetLang == 'en') {
      return Map.from(englishStrings);
    }

    final cached = await loadCache(targetLang);
    if (cached != null && cached.isNotEmpty) {
      final missingKeys = englishStrings.keys
          .where((k) => !cached.containsKey(k) || (cached[k]?.isEmpty ?? true))
          .toList();
      if (missingKeys.isEmpty) return cached;

      final missingBatch = {
        for (final k in missingKeys) k: englishStrings[k]!,
      };
      final newTranslations = await translateBatch(missingBatch, targetLang);
      final merged = {...cached, ...newTranslations};
      await saveCache(targetLang, merged);
      return merged;
    }

    final translations = await translateBatch(englishStrings, targetLang);
    await saveCache(targetLang, translations);
    return translations;
  }

  /// Clear all cached translations.
  static Future<void> clearCache() async {
    _memCache.clear();
    final prefs = await SharedPreferences.getInstance();
    for (final lang in ['hi', 'mr', 'ta']) {
      await prefs.remove(_cacheKey(lang));
    }
  }
}
