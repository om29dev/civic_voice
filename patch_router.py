import re

router_path = r'c:\Users\MADHAV\Downloads\Civic Voice\civic_voice\lib\core\router\app_router.dart'

with open(router_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add imports for the 7 screens
imports = """
import '../../features/eligibility/screens/ai_eligibility_flow_screen.dart';
import '../../features/voice/screens/voice_complaint_screen.dart';
import '../../features/documents/screens/ai_document_scanner_screen.dart';
import '../../features/services/screens/scheme_discovery_screen.dart';
import '../../features/dashboard/screens/application_dashboard_screen.dart';
import '../../features/services/screens/offline_guidance_screen.dart';
import '../../features/profile/screens/citizen_profile_dashboard.dart';
"""

# Find the last import
last_import_index = content.rfind('import')
end_of_last_import = content.find('\n', last_import_index) + 1
content = content[:end_of_last_import] + imports + content[end_of_last_import:]

# Add Routes constants
routes_additions = """
  static const voiceComplaint  = '/voice-complaint';
  static const documentScanner = '/document-scanner';
  static const schemeDiscovery = '/scheme-discovery';
  static const appTracker      = '/app-tracker';
  static const offlineGuidance = '/offline-guidance';
  static const citizenProfile  = '/citizen-profile';
"""

content = content.replace('static const officeLocator   = \'/office-locator\';', 'static const officeLocator   = \'/office-locator\';' + routes_additions)

# Replace Route: eligibility
eligibility_commented = """        GoRoute(
          path: Routes.eligibility,
          name: 'eligibility',
          pageBuilder: (context, state) {
            // final service = state.extra as ServiceModel;
            // TODO: import EligibilityCheckerScreen
            // return _buildPage(state, EligibilityCheckerScreen(service: service));
            return _buildPage(state, const Scaffold(body: Center(child: Text('Eligibility Screen')))); // Temp
          },
        ),"""

eligibility_actual = """        GoRoute(
          path: Routes.eligibility,
          name: 'eligibility',
          pageBuilder: (context, state) {
            final service = state.extra as ServiceModel;
            return _buildPage(state, AiEligibilityFlowScreen(service: service));
          },
        ),"""

content = content.replace(eligibility_commented, eligibility_actual)

# Add remaining 6 routes
new_routes = """
        GoRoute(
          path: Routes.voiceComplaint,
          name: 'voiceComplaint',
          pageBuilder: (context, state) => _buildPage(state, const VoiceComplaintScreen()),
        ),
        GoRoute(
          path: Routes.documentScanner,
          name: 'documentScanner',
          pageBuilder: (context, state) => _buildPage(state, const AiDocumentScannerScreen()),
        ),
        GoRoute(
          path: Routes.schemeDiscovery,
          name: 'schemeDiscovery',
          pageBuilder: (context, state) => _buildPage(state, const SchemeDiscoveryScreen()),
        ),
        GoRoute(
          path: Routes.appTracker,
          name: 'appTracker',
          pageBuilder: (context, state) => _buildPage(state, const ApplicationDashboardScreen()),
        ),
        GoRoute(
          path: Routes.offlineGuidance,
          name: 'offlineGuidance',
          pageBuilder: (context, state) => _buildPage(state, const OfflineGuidanceScreen()),
        ),
        GoRoute(
          path: Routes.citizenProfile,
          name: 'citizenProfile',
          pageBuilder: (context, state) => _buildPage(state, const CitizenProfileDashboard()),
        ),
"""

routes_anchor = """        GoRoute(
          path: Routes.officeLocator,
          name: 'officeLocator',
          pageBuilder: (context, state) => _buildPage(
            state,
            const Scaffold(body: Center(child: Text('Office Locator Screen'))), // Temp
          ),
        ),"""

content = content.replace(routes_anchor, routes_anchor + new_routes)

with open(router_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated app_router.dart")
