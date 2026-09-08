import 'package:flutter/services.dart';

/// Loads and caches AI prompts from the Markdown asset (`assets/prompts/ai_prompts.md`).
class PromptLoader {
  PromptLoader._();

  static final Map<String, String> _promptCache = {};
  static bool _isLoaded = false;

  /// Loads all markdown prompts into memory if not already loaded.
  static Future<void> loadPrompts() async {
    if (_isLoaded) return;
    try {
      final raw = await rootBundle.loadString('assets/prompts/ai_prompts.md');
      _parseMarkdown(raw);
      _isLoaded = true;
    } catch (_) {
      // Fallback empty if asset loader fails
    }
  }

  static void _parseMarkdown(String md) {
    final regex = RegExp(r'```prompt:(\w+)\s*([\s\S]*?)```');
    for (final match in regex.allMatches(md)) {
      final key = match.group(1);
      final promptText = match.group(2);
      if (key != null && promptText != null) {
        _promptCache[key] = promptText.trim();
      }
    }
  }

  /// Retrieves a prompt by its key and replaces template variables `{{var}}`.
  static Future<String> getPrompt(String key, [Map<String, String> variables = const {}]) async {
    await loadPrompts();
    String template = _promptCache[key] ?? '';
    variables.forEach((k, v) {
      template = template.replaceAll('{{$k}}', v);
    });
    return template;
  }
}
