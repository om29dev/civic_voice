# Security Audit — Civic Voice

## Executive Summary

| Category | Status | Risk |
|---|---|---|
| Authentication | ✅ Strong | Low |
| API Credential Management | ✅ Strong | Low |
| Document Access Control | ✅ Strong | Low |
| WebView Security | ⚠️ Partial | Medium |
| Local Data Security | ⚠️ Partial | Medium |
| Input Validation | ⚠️ Partial | Medium |
| Sensitive Data in Logs | ⚠️ Needs Review | Medium |
| Biometric Lock | 🔷 Not Implemented | High |
| API Error Information Leakage | ✅ Handled | Low |

---

## 1. Authentication Security ✅

### Strengths
- **Amazon Cognito** handles password storage (PBKDF2 hashing) — app never sees raw passwords
- **Global sign-out** option (`globalSignOut: true`) invalidates all sessions across devices
- **Session check before login** — proactive session detection prevents "User already signed in" crashes
- **Onboarding flag** (`cvi_onboarded`) cached in SharedPreferences — not a security gate, just UI flow

### Guest Mode
```dart
// Guest model — no personal data, uses anonymous UUID
UserModel.guest() → id: UUID, name: 'Guest', isGuest: true
```
Guest sessions persist in SharedPreferences but cannot access Bedrock (Zero-Trust check).

### Vulnerabilities
- `loginWithGoogle()` is currently a stub that returns an error — Google OAuth is NOT configured. The method exists but fails gracefully. No security issue.
- `sendOTP()` comment notes it requires Cognito Custom Auth Lambda triggers to truly work.

---

## 2. API Credential Security ✅

### Zero-Trust Architecture
```dart
// AWSBedrockService.invokeModel()
final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
if (!session.isSignedIn) {
  throw AuthRequiredException('Authentication required...');
}
// Only then use temporary credentials
final creds = session.credentialsResult.value;
// creds are: accessKeyId, secretAccessKey, sessionToken
// These are SHORT-LIVED (Cognito Identity Pool default: 1 hour)
```

### What Is NOT Exposed
- ❌ No hardcoded AWS Access Keys in Flutter source
- ❌ No API keys in pubspec.yaml or any asset file
- ❌ No `.env` files with secrets
- ❌ No secrets in `lib/amplifyconfiguration.dart` (contains only public identifiers: pool IDs, endpoint URLs)

### Public Identifiers (Not Secrets)
The `amplifyconfiguration.dart` file contains public-facing configuration IDs (User Pool ID, AppSync endpoint, S3 bucket name). These are safe to include in the client binary as they require authenticated Cognito credentials to use.

---

## 3. Document Access Control ✅

### S3 Protected Paths
```
protected/{cognito-identity-id}/documents/
```
S3 bucket IAM policy (set by Amplify) allows:
- Authenticated users: read/write their own `protected/{id}/` prefix only
- No cross-user access

### AppSync Authorization
DynamoDB document records use `@auth(rules: [{allow: owner}])` in the GraphQL schema, ensuring AppSync automatically filters queries to the authenticated user's documents only.

### Signed URLs
Document viewing URLs expire after **1 hour**:
```dart
S3GetUrlPluginOptions(expiresIn: Duration(hours: 1))
```

---

## 4. WebView Security ⚠️ Partial

### SmartBrowserScreen Issues
The WebView loads government portal URLs. Current security:

| Check | Status | Notes |
|---|---|---|
| URL validation | ⚠️ Weak | No strict allowlist — any URL from `formData` is loaded |
| Navigation intercept | ⚠️ Partial | No `onNavigationRequest` callback in current code |
| JavaScript injection | ✅ Not present | App does NOT inject JS into portal pages |
| External link handling | ⚠️ Unknown | WebView may follow redirects to non-gov domains |

### Recommended Fix
```dart
WebViewWidget(controller: _controller
  ..setNavigationDelegate(NavigationDelegate(
    onNavigationRequest: (NavigationRequest req) {
      final allowedDomains = ['gov.in', 'india.gov.in', 'nsdl.co.in', 'passportindia.gov.in'];
      final uri = Uri.parse(req.url);
      if (allowedDomains.any((d) => uri.host.endsWith(d))) {
        return NavigationDecision.navigate;
      }
      return NavigationDecision.prevent;
    }
  ))
)
```

---

## 5. Local Data Security ⚠️ Partial

### SharedPreferences (Unencrypted)
```
cvi_onboarded: bool     → not sensitive
cvi_user_session/guest_id → guest UUID (low risk)
cvi_user_session/lang  → language code (not sensitive)
cvi_lang_{userId}      → language preference (not sensitive)
```
**Risk**: Low — no PII stored in SharedPreferences.

### flutter_secure_storage
Package is in `pubspec.yaml` but **not currently used** in the vault or auth flow. Cognito tokens are managed by the Amplify SDK (which handles secure storage internally on Android via EncryptedSharedPreferences).

### Biometric Lock (Not Implemented)
`local_auth` package is in pubspec.yaml but is **not wired** to the DocumentVaultScreen or any screen. Documents are accessible to anyone with the app open.

**Risk**: High for shared devices. Any family member who opens the app while the user is still logged in can view documents.

**Recommended fix**: Add biometric check on `DocumentVaultScreen` init:
```dart
final LocalAuthentication auth = LocalAuthentication();
final bool authenticated = await auth.authenticate(
  localizedReason: 'Authenticate to view your documents',
  options: const AuthenticationOptions(biometricOnly: false),
);
```

---

## 6. Sensitive Data in Logs ⚠️ Needs Review

### Found in Code
```dart
debugPrint('Bedrock Response Status: ${response.statusCode}');
debugPrint('Bedrock Success Result: $responseBody');  // ← Full AI response in logs
debugPrint('Extraction success: $parsed');             // ← Extracted document data in logs
```

**Risk**: In debug builds, extracted document data (including partially masked Aadhaar numbers) may appear in Android logcat. In release builds, `debugPrint` is suppressed by Flutter's `--release` flag.

**Action**: Replace `debugPrint` with a custom `Logger` class that's completely silent in release builds and redacts sensitive fields (aadhaar_number, pan_number, account_number).

### Sensitive Field Masking in TTS (Implemented)
```dart
// AutoFormProvider.speakFilledData()
final displayValue = field.sensitive && value.length > 4
    ? 'ending in ${value.substring(value.length - 4)}'
    : value;
```
Sensitive fields (marked `"sensitive": true` in JSON templates) are masked in TTS readout. ✅

---

## 7. Input Validation ⚠️ Partial

### Form Field Validation
`SmartFormField.validationPattern` stores regex patterns (e.g., `"^\\d{6}$"` for pincode). However, there is no evidence that these patterns are applied server-side — they are UI hints only.

### Bedrock Prompt Injection Risk
User voice input is passed to Bedrock:
```dart
ReasoningEngine.generateAIResponse(userInput, history)
  → ... promptBuffer.write(userInput)
  → AWSBedrockService.chatWithNovaMicro(prompt)
```
No sanitization of user input before including in the AI prompt. A malicious user could attempt prompt injection (jailbreak). **Risk**: Low for a citizen app, but consider adding a content filter before Bedrock calls.

---

## 8. Document Upload Validation ⚠️

### File Type Validation
- Only image files are accepted (ImagePicker returns images, not arbitrary files).
- `file_picker` is also available but document vault only uses ImagePicker.

### File Size
- Compressed to 1.5MB before sending to Bedrock — limits payload size.
- No explicit maximum upload size check beyond the compression.

### MIME Type
- Sent as `image/jpeg` regardless of original format.

---

## 9. API Error Handling ✅

`AWSBedrockService` catches all exceptions and:
- Logs to debugPrint
- Rethrows for the calling service to handle
- `ReasoningEngine` catches and returns user-friendly error messages:
  - Auth required → "Please sign in to enable live AI"
  - Network error → "Check your connection"
- No raw stack traces or AWS error codes are shown to users

---

## 10. Data Minimization

| Data | Stored Where | Retention |
|---|---|---|
| Document images | S3 protected path | Until user deletes |
| Extracted text (PII) | DynamoDB (extractedText field as JSON) | Until user deletes document |
| User attributes | Cognito User Pool | Until account deletion |
| Language preference | SharedPreferences | Indefinite (local) |
| AI response cache | In-memory only | 30 min or app restart |
| Guest session | SharedPreferences | Until user logs in or clears |

**Concern**: Extracted PII (name, Aadhaar number, DOB) stored as plain JSON in DynamoDB. Consider encrypting `extractedText` field at application level before storing.

---

## Security Improvement Priority

| Priority | Issue | Recommended Fix |
|---|---|---|
| 🔴 High | Biometric not enforced on vault | Wire `local_auth` to `DocumentVaultScreen.initState()` |
| 🔴 High | Extracted PII in logs | Custom Logger class, redact sensitive keys |
| 🟡 Medium | WebView no URL allowlist | Add `onNavigationRequest` domain whitelist |
| 🟡 Medium | PII stored as plain JSON in DynamoDB | Client-side field encryption before storing |
| 🟢 Low | Guest can see document vault UI | Guard vault routes with `auth.isRealUser` check |
| 🟢 Low | AI prompt injection | Add basic input sanitization/length limit |

