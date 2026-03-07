import re

router_path = r'c:\Users\MADHAV\Downloads\Civic Voice\civic_voice\lib\core\router\app_router.dart'

with open(router_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Remove the accidentally inserted imports from inside the GoRoute
bad_imports = """
import '../../features/eligibility/screens/ai_eligibility_flow_screen.dart';
import '../../features/voice/screens/voice_complaint_screen.dart';
import '../../features/documents/screens/ai_document_scanner_screen.dart';
import '../../features/services/screens/scheme_discovery_screen.dart';
import '../../features/dashboard/screens/application_dashboard_screen.dart';
import '../../features/services/screens/offline_guidance_screen.dart';
import '../../features/profile/screens/citizen_profile_dashboard.dart';"""

content = content.replace(bad_imports, "")

# 2. Insert the imports correctly at the top of the file
# Find the first empty line after the imports
match = re.search(r'import(.*?;)\n\n', content, re.DOTALL)
if match:
    insert_pos = match.end() - 1
    content = content[:insert_pos] + bad_imports + "\n" + content[insert_pos:]
else:
    # Fallback, just put at top
    content = bad_imports + "\n" + content

with open(router_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed imports in app_router.dart")
