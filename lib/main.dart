import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_assets.dart';
import 'core/constants/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'providers/voice_provider.dart';
import 'providers/conversation_provider.dart';
import 'providers/user_provider.dart';
import 'providers/services_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/accessibility_provider.dart';
import 'providers/document_vault_provider.dart';
import 'providers/eligibility_checker_provider.dart';
import 'providers/complaint_provider.dart';
import 'providers/document_scanner_provider.dart';
import 'providers/scheme_discovery_provider.dart';
import 'providers/application_tracker_provider.dart';
import 'providers/offline_guidance_provider.dart';
import 'providers/citizen_profile_provider.dart';
import 'features/auto_form/providers/auto_form_provider.dart';
import 'core/services/csv_scheme_service.dart';
import 'app.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('!!! [CVI_BOOT] Primary initialization start');
    
    await dotenv.load(fileName: AppAssets.envFile);
    unawaited(CsvSchemeService.init());
    await SharedPreferences.getInstance();
    
    await Supabase.initialize(
      url:  dotenv.env['SUPABASE_URL']      ?? 'https://placeholder.supabase.co',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'placeholder-anon-key',
      debug: false,
    );

    debugPrint('!!! [CVI_BOOT] Initialization complete, launching app');
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => VoiceProvider()),
          ChangeNotifierProvider(create: (_) => ConversationProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => ServicesProvider()),
          ChangeNotifierProvider(create: (_) => EligibilityCheckerProvider()),
          ChangeNotifierProvider(create: (_) => ComplaintProvider()),
          ChangeNotifierProvider(create: (_) => DocumentScannerProvider()),
          ChangeNotifierProvider(create: (_) => SchemeDiscoveryProvider()),
          ChangeNotifierProvider(create: (_) => ApplicationTrackerProvider()),
          ChangeNotifierProvider(create: (_) => OfflineGuidanceProvider()),
          ChangeNotifierProvider(create: (_) => CitizenProfileProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
          ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
          ChangeNotifierProvider(create: (_) => DocumentVaultProvider()..loadDocuments()),
          ChangeNotifierProvider(create: (_) => AutoFormProvider()),
        ],
        child: const CVIApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('!!! [CVI_CRASH] Global Error: $error');
    debugPrint(stack.toString());
  });
}
