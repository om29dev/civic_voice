import os
import re

allowed_files = [
    'splash_screen.dart',
    'main_dashboard_screen.dart',
    'voice_interface_screen.dart',
    'voice_screen.dart',
    'voice_dashboard_screen.dart'
]

lib_dir = 'c:\\CIVIC VOICE AI FOR BHARAT\\civic_voice\\lib'

def process_file(path, file_name):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # If it's the auth screen, it has a private class _ParticleBackground, and we also need to remove Positioned.fill(child: _ParticleBackground())
    if file_name == 'auth_screen.dart':
        content = re.sub(r'const Positioned\.fill\(child:\s*_ParticleBackground\(\)\),', '', content)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Removed from {file_name}")
        return

    # Regular removal for others
    # Search for Positioned.fill(child: ParticleBackground(...)),
    pattern = r'const Positioned\.fill\(\s*child:\s*ParticleBackground\([^)]*\),\s*\),'

    if re.search(pattern, content):
        content = re.sub(pattern, '', content)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Removed from {file_name}")

    # Search without Positioned.fill like `body: ParticleBackground(...)` - actually if Body is ParticleBackground wait we can just remove it and put a Container? No, some were `Positioned.fill` inside a `Stack`.
    # Let's target `child: ParticleBackground(...)` inside `Stack` or `body:`
    
    # Just look for the specific lines in those files. I'll just manually replace files that were listed.
    pass

# We will just do a specific replacement for the files we know.
files_to_clean = {
    'c:\\CIVIC VOICE AI FOR BHARAT\\civic_voice\\lib\\features\\onboarding\\screens\\first_launch_screen.dart',
    'c:\\CIVIC VOICE AI FOR BHARAT\\civic_voice\\lib\\features\\profile\\screens\\complete_profile_screen.dart',
    'c:\\CIVIC VOICE AI FOR BHARAT\\civic_voice\\lib\\features\\services\\screens\\service_detail_screen_new.dart',
    'c:\\CIVIC VOICE AI FOR BHARAT\\civic_voice\\lib\\features\\profile\\screens\\user_profile_screen.dart',
    'c:\\CIVIC VOICE AI FOR BHARAT\\civic_voice\\lib\\features\\documents\\screens\\documents_screen.dart',
    'c:\\CIVIC VOICE AI FOR BHARAT\\civic_voice\\lib\\features\\auth\\screens\\authentication_screen.dart',
    'c:\\CIVIC VOICE AI FOR BHARAT\\civic_voice\\lib\\features\\auth\\screens\\login_screen.dart',
    'c:\\CIVIC VOICE AI FOR BHARAT\\civic_voice\\lib\\features\\auth\\screens\\register_screen.dart',
    'c:\\CIVIC VOICE AI FOR BHARAT\\civic_voice\\lib\\features\\auth\\screens\\auth_screen.dart',
}

for path in files_to_clean:
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Remove import
        content = re.sub(r"import '[^']+particle_background\.dart';\n", '', content)
        
        # Remove Positioned.fill
        content = re.sub(r'const\s+Positioned\.fill\(\s*child:\s*ParticleBackground\([^)]*\),\s*\),', '', content)
        
        # Remove just child 
        content = re.sub(r'const\s+Positioned\.fill\(child:\s*_ParticleBackground\(\)\),', '', content)

        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Cleaned {path}")
