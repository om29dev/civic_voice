import 'dart:io';

void main() {
  final dir = Directory('lib');
  int count = 0;
  
  for (final file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      var content = file.readAsStringSync();
      
      final regex = RegExp(r'\.withOpacity\(([^)]+)\)');
      final newContent = content.replaceAllMapped(regex, (match) {
        return '.withValues(alpha: ${match.group(1)})';
      });
      
      if (content != newContent) {
        file.writeAsStringSync(newContent);
        final matches = regex.allMatches(content).length;
        count += matches;
        print('Updated ${file.path} ($matches replacements)');
      }
    }
  }
  
  print('Total replacements: $count');
}
