import re

router_path = r'c:\Users\MADHAV\Downloads\Civic Voice\civic_voice\lib\core\router\app_router.dart'

with open(router_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Remove 'const ' from the specific screen constructors
replacements = [
    ("const VoiceComplaintScreen()", "VoiceComplaintScreen()"),
    ("const AiDocumentScannerScreen()", "AiDocumentScannerScreen()"),
    ("const SchemeDiscoveryScreen()", "SchemeDiscoveryScreen()"),
    ("const ApplicationDashboardScreen()", "ApplicationDashboardScreen()"),
    ("const OfflineGuidanceScreen()", "OfflineGuidanceScreen()"),
    ("const CitizenProfileDashboard()", "CitizenProfileDashboard()"),
]

for old, new in replacements:
    content = content.replace(old, new)

with open(router_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Removed const keywords from app_router.dart")
