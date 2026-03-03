import os
import re

lib_dir = r"c:\CIVIC VOICE AI FOR BHARAT\civic_voice\lib"

count = 0
for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart"):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
            
            # Sub .withOpacity(value) with .withValues(alpha: value)
            new_content, num_replacements = re.subn(r'\.withOpacity\(([^)]+)\)', r'.withValues(alpha: \1)', content)
            
            if num_replacements > 0:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                count += num_replacements
                print(f"Updated {path} ({num_replacements} replacements)")

print(f"Total replacements: {count}")
