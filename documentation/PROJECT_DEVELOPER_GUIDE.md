# Developer Guide — Civic Voice

## 1. Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| Flutter SDK | ≥3.0.0 | App framework |
| Dart | ≥3.0.0 | Language |
| Android Studio / VS Code | Latest | IDE |
| Android SDK | API 21+ | Build target |
| AWS CLI | Latest | Amplify management |
| Amplify CLI | Latest | Backend management |
| Java | 17 | Android build |

---

## 2. Project Setup

```powershell
# Clone / open project
cd "c:\Users\MADHAV\Desktop\civic voice\civic_voice"

# Install dependencies
flutter pub get

# Verify setup
flutter doctor
flutter analyze
```

---

## 3. AWS Amplify Configuration

The project already has Amplify configured. The runtime config is in `lib/amplifyconfiguration.dart`. **Do not commit** actual credentials or secret tokens.

```powershell
# Check Amplify status (from project root)
amplify status

# Push schema changes (if you modify schema.graphql)
amplify push

# Pull latest backend config
amplify pull
```

The `src/amplifyconfiguration.json` contains public-facing AWS identifiers (pool IDs, endpoint URLs) — these are safe to commit.

---

## 4. Running the App

```powershell
# Run in debug mode on connected Android device
flutter run

# Run with specific device
flutter devices
flutter run -d <device-id>

# Run with verbose logging
flutter run --verbose

# Build release APK
flutter build apk --release

# Build and deploy APK to S3 (hackathon gate)
aws s3 cp build\app\outputs\flutter-apk\app-release.apk s3://civicvoicestorage71deb-dev/public/civicvoice.apk --acl public-read
```

---

## 5. Project Structure Quick Navigation

```
lib/
├── main.dart            ← Bootstrap: providers, AWS init, app launch
├── app.dart             ← CVIApp: theme, locale, router
├── amplifyconfiguration.dart  ← AWS config (public IDs)
│
├── core/
│   ├── config/ai_config.dart         ← Bedrock model IDs & region
│   ├── router/app_router.dart        ← ALL routes defined here
│   ├── services/
│   │   ├── aws_amplify_service.dart  ← Amplify init singleton
│   │   ├── aws_bedrock_service.dart  ← ALL Bedrock API calls
│   │   ├── document_ai_service.dart  ← Document OCR via Nova Lite
│   │   ├── document_vault_service.dart ← S3 + DynamoDB CRUD
│   │   ├── reasoning_engine.dart     ← AI orchestrator + intent parser
│   │   └── prompt_loader.dart        ← Load ai_prompts.md
│   └── theme/app_theme.dart          ← Dark theme config
│
├── providers/           ← All ChangeNotifier state managers
├── models/              ← Data classes
│
├── features/
│   ├── auth/            ← Login / register screens
│   ├── auto_form/       ← Smart form auto-fill (PRIMARY FEATURE)
│   │   ├── providers/auto_form_provider.dart  ← Form fill state
│   │   ├── services/form_template_service.dart ← JSON loader
│   │   ├── models/auto_form_model.dart        ← SmartFormTemplate etc.
│   │   └── screens/                           ← Form UI screens
│   ├── dashboard/       ← Main dashboard
│   ├── documents/       ← AI scanner + vault screens
│   ├── forms/           ← Legacy form screens
│   ├── voice/           ← Voice chat screen
│   └── services/        ← Government service catalog
│
├── widgets/             ← Reusable UI components
└── services/            ← Legacy service files (root-level, prefer core/)

assets/
├── forms/               ← JSON form templates (5 implemented)
├── prompts/ai_prompts.md ← AI system prompt templates
├── data/                ← CSV scheme datasets
└── lottie/              ← Animation files
```

---

## 6. Key Architecture Patterns

### Provider Pattern
All state is managed via `ChangeNotifier` providers. To read state:
```dart
// In build():
final vp = context.watch<VoiceProvider>();  // rebuilds on change
// Outside build:
final vp = context.read<VoiceProvider>();   // one-time read
```

### Service Layer
Services are static classes (no instantiation needed):
```dart
final result = await DocumentVaultService.uploadDocument(imageBytes: bytes, documentType: 'aadhaar');
final text = await AWSBedrockService.chatWithNovaMicro(prompt);
```

### Routing
Always use `Routes` constants and `context.push()` / `context.go()`:
```dart
context.push(Routes.documentVault);
context.push(Routes.smartFormPath(serviceId), extra: serviceModel);
```

---

## 7. Adding a New Form Template

1. Create `assets/forms/{service_id}.json` following the template schema.
2. Register in `FormTemplateService._templateFiles`:
   ```dart
   'my_service': 'assets/forms/my_service.json',
   ```
3. Declare in `pubspec.yaml` assets (already covered by `assets/forms/` directory declaration).
4. The form will automatically be available at `/smart-form/my_service`.

**dataKey mapping**: The `dataKey` in each field must match a key in `ExtractedUserData.toJson()` or the profile data map for auto-fill to work.

---

## 8. Adding a New AI Prompt

1. Open `assets/prompts/ai_prompts.md`.
2. Add a new named section:
   ```markdown
   ## my_new_prompt
   You are a helpful assistant for {topic}.
   Language: {languageCode}
   ```
3. Use in code:
   ```dart
   final prompt = await PromptLoader.getPrompt('my_new_prompt', {
     'topic': 'government forms',
     'languageCode': 'hi',
   });
   ```

---

## 9. Adding a New Provider

```dart
// lib/providers/my_feature_provider.dart
import 'package:flutter/foundation.dart';

class MyFeatureProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> doSomething() async {
    _isLoading = true;
    notifyListeners();
    // ... work
    _isLoading = false;
    notifyListeners();
  }
}
```

Register in `lib/main.dart`:
```dart
ChangeNotifierProvider(create: (_) => MyFeatureProvider()),
```

---

## 10. Adding a New Route

In `lib/core/router/app_router.dart`:
```dart
// 1. Add constant
abstract class Routes {
  static const myFeature = '/my-feature';
}

// 2. Add GoRoute
GoRoute(
  path: Routes.myFeature,
  name: 'myFeature',
  pageBuilder: (context, state) => _buildPage(state, const MyFeatureScreen()),
),
```

Navigate:
```dart
context.push(Routes.myFeature);
context.go(Routes.myFeature);
```

---

## 11. Debugging Tips

### Amplify Issues
```dart
// Check initialization in console:
// !!! [CVI_BOOT] Initializing AWS Amplify...
// [AwsAmplifyService] initialize: Successfully configured AWS Amplify

// If you see "AmplifyAlreadyConfiguredException" — app initialized twice (handled gracefully)
```

### Bedrock Call Issues
```dart
// Watch for:
// "Authentication required" → user is not signed in (guest mode)
// "Bedrock Error 403" → Cognito Identity Pool permissions issue
// "Bedrock Error 429" → Rate limit — response caching helps
```

### STT Not Working
- Ensure microphone permission in `AndroidManifest.xml`
- Ensure device has Google Speech Services installed
- STT has 5-second initialization timeout — check logs for `[VoiceProvider] STT initialized: false`

### Document Extraction Low Confidence
- Ensure document image is well-lit and not blurry
- `confidence < 0.6` triggers a warning, but data is still saved
- Check `Extraction success: {map}` log for raw extracted values

---

## 12. Common Development Tasks

### Test Auth Flow Without Real Cognito
Use guest mode: `AuthProvider.continueAsGuest()` — sets `isAuthenticated = true`, `isGuest = true`.

Guest users:
- Can use all UI screens ✅
- **Cannot** call Bedrock AI (blocked by `AuthRequiredException`) ❌
- **Cannot** access Document Vault (requires Cognito session) ❌

### Mock Scheme Data
`SchemeDiscoveryProvider._loadMockSchemes()` provides 5 hardcoded schemes. To add more:
```dart
_allSchemes.add(SchemeDiscoveryModel(
  id: 'new_scheme',
  title: 'New Scheme',
  category: 'Healthcare',
  description: '...',
  eligibilityCriteria: ['Must be below poverty line'],
  applicationProcess: 'Apply online at ...',
));
```

### Run Tests
```powershell
flutter test test/widget_test.dart
flutter test test/security_and_efficiency_test.dart
```

---

## 13. Environment & Secrets Management

**DO NOT** add secrets to:
- `pubspec.yaml`
- Any asset file
- `lib/amplifyconfiguration.dart` (use only public IDs)
- Source control

**Safe to commit**:
- `src/amplifyconfiguration.json` — Cognito Pool IDs, AppSync endpoint, S3 bucket name (these are public identifiers, not secrets)
- `amplify/team-provider-info.json` — public team config

**Managed by AWS**:
- IAM roles, S3 bucket policies — managed via Amplify CLI, not in Flutter code
- Bedrock access — granted via Cognito Identity Pool roles

---

## 14. Known Issues & TODOs

| Issue | Location | Priority |
|---|---|---|
| `bpl_certificate.json` and `caste_certificate.json` assets missing | `assets/forms/` | 🟡 Medium |
| `local_auth` biometric not wired | `DocumentVaultScreen` | 🔴 High |
| `saveFormFillHistory()` is a stub | `DocumentVaultService` | 🟡 Medium |
| `form_fill_history` table not in GraphQL schema | `amplify/backend/api/civicvoiceapi/schema.graphql` | 🟡 Medium |
| Google Sign-In not configured | `AuthProvider.loginWithGoogle()` | 🟡 Medium |
| Duplicate `app_theme.dart` at two paths | `lib/core/theme/` and `lib/core/themes/` | 🟢 Low |
| Root-level duplicate service files | `lib/services/` vs `lib/core/services/` | 🟢 Low |
| AR guidance screen minimal | `ARGuidanceScreen` | 🟢 Low |
| WebView no domain allowlist | `SmartBrowserScreen` | 🟡 Medium |

