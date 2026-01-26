import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'providers/voice_provider.dart';
import 'providers/conversation_provider.dart';
import 'providers/language_provider.dart';
import 'providers/user_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/authentication_screen.dart';
import 'features/navigation/screens/main_navigation_screen.dart';
import 'features/voice_interface/screens/voice_dashboard_screen.dart';
import 'providers/accessibility_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/gamification_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/community_provider.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Error loading .env: $e");
    // Proceed even if .env fails to load, the engine will handle missing keys
  }
  runApp(const CivicVoiceApp());
}

class CivicVoiceApp extends StatelessWidget {
  const CivicVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
        ChangeNotifierProvider(create: (_) => ConversationProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
      ],
      child: Consumer2<LanguageProvider, AccessibilityProvider>(
        builder: (context, langProvider, accProvider, child) {
          // Link providers
          final voiceProvider = Provider.of<VoiceProvider>(context, listen: false);
          final convoProvider = Provider.of<ConversationProvider>(context, listen: false);
          final notesProvider = Provider.of<NotesProvider>(context, listen: false);
          
          convoProvider.updateVoiceProvider(voiceProvider);
          convoProvider.updateNotesProvider(notesProvider);
          
          return MaterialApp(
            title: 'Civic Voice Interface',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getTheme(accProvider.isHighContrast).copyWith(
              scaffoldBackgroundColor: accProvider.isHighContrast 
                  ? Colors.black 
                  : AppColors.background,
            ),
            builder: (context, child) {
              // Apply Accessibility Overrides
              final data = MediaQuery.of(context);
              final scale = accProvider.textScaleFactor;
              final filter = accProvider.colorFilter;

              return MediaQuery(
                data: data.copyWith(textScaleFactor: scale),
                child: filter != null 
                  ? ColorFiltered(colorFilter: filter, child: child!)
                  : child!,
              );
            },
            initialRoute: '/login', // Start with login screen
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/otp-auth': (context) => const AuthenticationScreen(), // OTP screen
              '/dashboard': (context) => const MainNavigationScreen(), // Multi-section with navbar
              '/voice': (context) => const VoiceDashboardScreen(),
            },
          );
        },
      ),
    );
  }
}
