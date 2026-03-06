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
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env variables
  await dotenv.load(fileName: AppAssets.envFile);

  // Initialize SharedPreferences (warm up cache)
  await SharedPreferences.getInstance();

  // Initialize Supabase
  await Supabase.initialize(
    url:  dotenv.env['SUPABASE_URL']      ?? 'https://placeholder.supabase.co',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'placeholder-anon-key',
    debug: false,
  );

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // System chrome styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
        ChangeNotifierProvider(create: (_) => ConversationProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ServicesProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
        ChangeNotifierProvider(create: (_) => DocumentVaultProvider()..loadDocuments()),
      ],
      child: const CVIApp(),
    ),
  );
}
