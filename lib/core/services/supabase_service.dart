import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static SupabaseClient? _client;
  static SupabaseClient get client => Supabase.instance.client;
  
  static GoTrueClient get auth => client.auth;
  
  static bool get isInitialized => _client != null;
  
  static Future<void> initialize() async {
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    
    if (url == null || anonKey == null) {
      throw Exception('Supabase credentials not found in .env file');
    }
    
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    
    _client = Supabase.instance.client;
  }
  
  // Auth helpers
  static User? get currentUser => auth.currentUser;
  static bool get isLoggedIn => currentUser != null;
  static String? get userId => currentUser?.id;
  
  // Database helpers
  static SupabaseQueryBuilder from(String table) => client.from(table);
  
  // Sign up with email
  static Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await auth.signUp(email: email, password: password);
  }
  
  // Sign in with email
  static Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await auth.signInWithPassword(email: email, password: password);
  }
  
  // Sign in with OTP (phone)
  static Future<void> signInWithOtp(String phone) async {
    await auth.signInWithOtp(phone: phone);
  }
  
  // Verify OTP
  static Future<AuthResponse> verifyOtp(String phone, String token) async {
    return await auth.verifyOTP(phone: phone, token: token, type: OtpType.sms);
  }
  
  // Sign out
  static Future<void> signOut() async {
    await auth.signOut();
  }
  
  // Listen to auth state changes
  static Stream<AuthState> get onAuthStateChange => auth.onAuthStateChange;
}
