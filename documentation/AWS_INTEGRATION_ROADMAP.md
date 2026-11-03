# AWS Integration Roadmap — Civic Voice

## Current AWS Integration Status

> **IMPORTANT**: Only services with ✅ are live and tested. Services marked 🔷 are planned/configured in AGENTS.md but not yet implemented in Flutter code.

| AWS Service | Status | Flutter File | Notes |
|---|---|---|---|
| Amazon Cognito | ✅ Live | `auth_provider.dart`, `aws_amplify_service.dart` | Full auth flow |
| Amazon S3 | ✅ Live | `document_vault_service.dart` | Protected document storage |
| AWS AppSync + DynamoDB | ✅ Live | `document_vault_service.dart` | Document metadata CRUD |
| Amazon Bedrock Nova Micro | ✅ Live | `aws_bedrock_service.dart` | Text AI |
| Amazon Bedrock Nova Lite | ✅ Live | `document_ai_service.dart` | Multimodal OCR |
| AWS Lambda | 🔷 Planned | — | No Lambda functions exist yet |
| Amazon API Gateway | 🔷 Planned | — | Only AppSync currently |
| Amazon Translate | 🔷 Planned | — | Using Bedrock for translation now |
| Amazon Polly | 🔷 Planned | — | Using device TTS now |
| Amazon Transcribe | 🔷 Planned | — | Using device STT now |
| Amazon SNS | 🔷 Planned | — | Using local notifications now |
| Amazon Textract | 🔷 Planned | — | Using Nova Lite for OCR now |

---

## AWS Integration Roadmap (Per Service)

### 1. Amazon Cognito ✅ Already Integrated

| Attribute | Detail |
|---|---|
| Existing File | `lib/core/services/aws_amplify_service.dart`, `lib/providers/auth_provider.dart` |
| Required Changes | Wire `loginWithGoogle()` Hosted UI; add Lambda triggers for Custom Auth OTP flows |
| New Files Needed | None for core auth; Lambda trigger files in `amplify/backend/function/` |
| Difficulty | Low — already working |

**Next step**: Enable Cognito Hosted UI for social login (Google/Facebook) via `Amplify.Auth.signInWithWebUI()`.

---

### 2. Amazon S3 ✅ Already Integrated

| Attribute | Detail |
|---|---|
| Existing File | `lib/core/services/document_vault_service.dart` |
| Required Changes | Add lifecycle rules for document expiry; enable S3 Transfer Acceleration for rural users |
| New Files Needed | S3 lifecycle policy (in Amplify backend config) |
| Difficulty | Low — already working |

**Security already implemented**: Protected paths ensure users can only access their own documents.

---

### 3. AWS AppSync + DynamoDB ✅ Already Integrated

| Attribute | Detail |
|---|---|
| Existing File | `lib/core/services/document_vault_service.dart` |
| Required Changes | Add `FormFillHistory` table; add `ApplicationTracker` table with real status fields; add `FamilyMember` table |
| New Files Needed | `amplify/backend/api/civicvoiceapi/schema.graphql` updates |
| Difficulty | Medium — schema changes need `amplify push` |

**Pending GraphQL tables**:
```graphql
type FormFillHistory @model @auth(rules: [{allow: owner}]) {
  id: ID!
  serviceId: String!
  serviceName: String!
  fieldsTotal: Int!
  fieldsAutoFilled: Int!
  filledData: AWSJSON!
  status: String!
  createdAt: AWSDateTime!
}

type ApplicationTracker @model @auth(rules: [{allow: owner}]) {
  id: ID!
  applicationId: String!
  schemeName: String!
  status: String!
  department: String!
  submittedDate: AWSDateTime!
  lastUpdated: AWSDateTime!
}
```

---

### 4. Amazon Bedrock — Nova Micro ✅ Already Integrated

| Attribute | Detail |
|---|---|
| Existing File | `lib/core/services/aws_bedrock_service.dart`, `lib/core/services/reasoning_engine.dart` |
| Required Changes | Add conversation history trimming to manage token costs; add streaming support for faster UX |
| New Files Needed | None |
| Difficulty | Low — already working |

**Cost optimization already implemented**: In-memory 30-minute response cache.

---

### 5. Amazon Bedrock — Nova Lite ✅ Already Integrated

| Attribute | Detail |
|---|---|
| Existing File | `lib/core/services/document_ai_service.dart` |
| Required Changes | Add retry logic on rate limit errors; add Textract fallback for low-confidence extractions |
| New Files Needed | None |
| Difficulty | Low — already working |

---

### 6. AWS Lambda 🔷 Not Implemented

**Integration Points Needed:**

| Use Case | Trigger | Proposed Lambda |
|---|---|---|
| Custom Auth OTP | Cognito Custom Auth Challenge | `cvi-send-otp-lambda` (SNS/SMS) |
| Government portal API proxy | API Gateway | `cvi-gov-portal-proxy` |
| Application status polling | EventBridge scheduled | `cvi-status-poller` |
| Document AI post-processing | S3 event | `cvi-document-processor` |

**Security requirement**: Lambda must use IAM roles, never embed credentials. Flutter should call Lambda via API Gateway with Cognito JWT authorization, not direct invocation.

**New Files Needed:**
```
amplify/backend/function/cviSendOtp/
  src/index.js
  amplify.state
amplify/backend/function/cviGovProxy/
  src/index.js
```

**Flutter Integration Point:**
```dart
// New: lib/core/services/lambda_service.dart
class LambdaService {
  static Future<Map<String, dynamic>> invoke(String functionPath, Map body) async {
    final url = 'https://{api-gateway-id}.execute-api.ap-south-1.amazonaws.com/dev$functionPath';
    // Add Cognito JWT Authorization header
    final token = await _getCognitoToken();
    final response = await http.post(Uri.parse(url),
      headers: { 'Authorization': 'Bearer $token' },
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }
}
```

---

### 7. Amazon API Gateway 🔷 Not Implemented

**Current situation**: Direct Bedrock calls via SigV4. No API Gateway layer.

**Why add API Gateway?**
- Hides Bedrock endpoint from client
- Rate limiting per user
- Request/response transformation
- Centralized logging (CloudWatch)

**Proposed routes:**
```
POST /ai/chat           → Lambda → Bedrock Nova Micro
POST /ai/extract        → Lambda → Bedrock Nova Lite
GET  /schemes/eligible  → Lambda → Bedrock/DynamoDB
GET  /status/{appId}    → Lambda → Gov Portal (scraped)
```

**Flutter Changes Needed:**
- Replace direct `AWSBedrockService` SigV4 calls with `http.post` to API Gateway URLs
- Add Cognito JWT to Authorization header (via `Amplify.Auth.fetchAuthSession().tokens.idToken`)
- New: `lib/core/services/api_gateway_service.dart`

---

### 8. Amazon Translate 🔷 Not Implemented (Using Bedrock)

**Current**: `ReasoningEngine.translateText()` calls `AWSBedrockService.chatWithNovaMicro()` for translation.

**Proposed replacement**: Amazon Translate for batch/high-volume translation (cheaper than Bedrock for simple translations).

**Integration Difficulty**: Medium

**New Files Needed:**
```dart
// lib/core/services/translate_service.dart
class AWSTranslateService {
  static Future<String> translate(String text, String sourceLang, String targetLang) async {
    // SigV4 POST to translate.us-east-1.amazonaws.com
    // Body: { Text, SourceLanguageCode, TargetLanguageCode }
  }
}
```

**Existing Flutter file to modify**: `lib/core/services/translation_service.dart`, `lib/services/translation_service.dart`

**Supported language codes**: en, hi (Hindi), mr (Marathi) — Note: Amazon Translate supports Marathi as `mr`, Tamil as `ta`.

---

### 9. Amazon Polly 🔷 Not Implemented (Using flutter_tts)

**Current**: `flutter_tts` (device TTS engine — quality varies by device, no premium voice).

**Why Polly?** Neural voices (Aditi for Hindi/en-IN, Kajal for Hindi) — consistent, high-quality across all devices.

**Integration Difficulty**: High (requires audio streaming/caching architecture)

**Proposed Architecture:**
```
VoiceProvider.speak(text)
  → Check language + length
  → Short (<50 chars): flutter_tts (low latency)
  → Long (>50 chars): AWSPollyService.synthesize()
    → SigV4 POST polly.us-east-1.amazonaws.com/v1/speech
    → Stream MP3 → audioplayers.AudioPlayer
```

**New Files Needed:**
```dart
// lib/core/services/aws_polly_service.dart
class AWSPollyService {
  static Future<Uint8List> synthesize(String text, String langCode) async { ... }
}
```

**Existing file to modify**: `lib/providers/voice_provider.dart` — add Polly path in `speak()`

---

### 10. Amazon Transcribe 🔷 Not Implemented (Using speech_to_text)

**Current**: `speech_to_text` (device STT — dependent on Google Speech Services, may not work on devices without Google Play).

**Why Transcribe?** Works on all Android devices; better accuracy for Indian accents; medical/domain-specific vocabulary possible.

**Integration Difficulty**: High (requires real-time audio streaming)

**Proposed Architecture:**
```
User speaks
  → record package captures audio (PCM/WAV)
  → Stream to AWS Transcribe via WebSocket (aws_transcribe_streaming)
  → Transcribe returns partial + final results
  → VoiceProvider._transcribedText updated
```

**New Files Needed:**
```dart
// lib/core/services/aws_transcribe_service.dart
```

**Existing file to modify**: `lib/providers/voice_provider.dart` — add Transcribe path alongside `_stt`

---

### 11. Amazon SNS 🔷 Not Implemented

**Current**: `flutter_local_notifications` (local only — no server-side push).

**Why SNS?** Server-triggered push notifications for:
- Application status updates
- Scheme deadline reminders
- Document expiry alerts

**Integration Difficulty**: Medium

**Architecture:**
```
Lambda (EventBridge/Gov Status Poller)
  → SNS.publish(topicArn, message, targetArn: deviceEndpoint)
  → FCM (Firebase) → Android device
  → Flutter app receives FCM notification
```

**New Files Needed:**
```dart
// lib/core/services/push_notification_service.dart
// Backend: amplify/backend/function/cviNotifier/
```

**Existing file to modify**: `lib/core/services/notification_service.dart`

---

### 12. Amazon Textract 🔷 Not Implemented

**Current**: Bedrock Nova Lite for document OCR (works well for image-based docs).

**Why Textract?** Better for PDF documents, structured forms, tables, handwritten text.

**When to use**: Scanned PDFs, typed government form extractions, bank statements with tables.

**Integration Difficulty**: Medium

**New Files Needed:**
```dart
// lib/core/services/aws_textract_service.dart
class AWSTextractService {
  static Future<Map<String, dynamic>> analyzeDocument(Uint8List bytes) async {
    // POST textract.us-east-1.amazonaws.com with SigV4
    // Action: AnalyzeDocument, FeatureTypes: [FORMS, TABLES]
  }
}
```

**Existing file to modify**: `lib/core/services/document_ai_service.dart` — add Textract as a fallback when `confidence < 0.6`.

---

## Security: Avoiding AWS Credential Exposure

The existing implementation already follows best practices:

✅ **No hardcoded credentials** — zero API keys, access keys, or secrets in Flutter source  
✅ **Cognito Identity Pool** — issues short-lived, scoped credentials at runtime  
✅ **Zero-Trust enforcement** — `AWSBedrockService` throws `AuthRequiredException` for unauthenticated requests  
✅ **Protected S3 paths** — user data isolated by identity ID  
✅ **SigV4 signing** — requests are cryptographically signed with temporary credentials  

**For Lambda/API Gateway integration**, use Cognito User Pool JWT tokens in the `Authorization` header rather than passing SigV4 credentials from the Flutter client to API Gateway.

---

## Cost Minimization Strategy

| Technique | Implementation |
|---|---|
| Bedrock response caching | ✅ 30-min in-memory SHA-256 cache |
| Image compression before Bedrock | ✅ 1.5MB limit, 85% quality |
| Nova Micro for text (cheapest) | ✅ ~$0.035/1M tokens |
| Device STT/TTS (free) | ✅ No Transcribe/Polly cost currently |
| S3 lifecycle rules | 🔷 Not yet configured |
| Lambda ARM64 (cheaper) | 🔷 Planned |
| DynamoDB on-demand (no idle cost) | ✅ Already (Amplify default) |

