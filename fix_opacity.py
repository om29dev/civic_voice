import os
import re

def process_directory(directory):
    count = 0
    # Pattern to match .withOpacity(value)
    # Allows spaces and various number formats (e.g., .withOpacity(0.5), .withOpacity( 1.0 ))
    pattern = re.compile(r'\.withOpacity\(\s*([^)]+)\s*\)')
    
    for root, dirs, files in os.walk(directory):
        for filename in files:
            if filename.endswith(".dart"):
                filepath = os.path.join(root, filename)
                try:
                    with open(filepath, 'r', encoding='utf-8') as file:
                        content = file.read()
                    
                    if '.withOpacity' in content:
                        # Replace .withOpacity(x) with .withValues(alpha: x)
                        new_content = pattern.sub(r'.withValues(alpha: \1)', content)
                        
                        if content != new_content:
                            with open(filepath, 'w', encoding='utf-8') as file:
                                file.write(new_content)
                            print(f"Updated: {filepath}")
                            count += 1
                except Exception as e:
                    print(f"Error processing {filepath}: {e}")
                    
    print(f"Total files updated: {count}")

if __name__ == "__main__":
    process_directory(r"c:\CIVIC VOICE AI FOR BHARAT\civic_voice\lib")
