# AI Models & Integrations — Civic Voice

## Summary of Active AI Integrations

| Service | Model ID | Region | Purpose | SDK |
|---|---|---|---|---|
| Amazon Bedrock — Nova Micro | `amazon.nova-micro-v1:0` | us-east-1 | Text AI: voice chat, scheme guidance, form guidance | SigV4 HTTP |
| Amazon Bedrock — Nova Lite | `amazon.nova-lite-v1:0` | us-east-1 | Multimodal: document image OCR & extraction | SigV4 HTTP |
| Amazon Cognito | N/A | ap-south-1 | Authentication + temporary AWS credentials | `amplify_auth_cognito` |
| AWS AppSync + DynamoDB | N/A | ap-south-1 | GraphQL CRUD for document metadata | `amplify_api` |
| Amazon S3 | N/A | ap-south-1 | Document file storage | `amplify_storage_s3` |
| Device STT | N/A | On-device | Speech-to-text | `speech_to_text` 7.3.0 |
| Device TTS | N/A | On-device | Text-to-speech | `flutter_tts` 4.2.5 |
| Google Maps | N/A | Cloud | Office location map | `google_maps_flutter` |

---

## 1. Amazon Bedrock — Nova Micro (Text AI)

### Configuration
```dart
// lib/core/config/ai_config.dart
static const String bedrockRegion = 'us-east-1';
static const String bedrockNovaMicro = 'amazon.nova-micro-v1:0';
```

### Initialization
- No SDK initialization required. Called directly via SigV4-signed HTTP.
- Credentials obtained at runtime from Cognito Identity Pool via `Amplify.Auth.fetchAuthSession()`.

### Invocation Files
| File | Method | Usage |
|---|---|---|
| `lib/core/services/aws_bedrock_service.dart` | `chatWithNovaMicro(prompt, systemPrompt)` | All text AI calls |
| `lib/core/services/reasoning_engine.dart` | `generateAIResponse()`, `generateFormGuidance()`, `generateSchemeGuidance()` | AI orchestration |

### API Endpoint
```
POST https://bedrock-runtime.us-east-1.amazonaws.com/model/amazon.nova-micro-v1:0/converse
```

### Request Format (Converse API)
```json
{
  "system": [{ "text": "<system_prompt>" }],
  "messages": [{ "role": "user", "content": [{ "text": "<prompt>" }] }],
  "inferenceConfig": { "maxTokens": 512, "temperature": 0.5, "topP": 0.9 }
}
```

### Response Parsing
```dart
result['output']['message']['content'][n]['text']
```

### Use Cases
1. **General Voice Chat** — `ReasoningEngine.generateAIResponse()` with scheme knowledge base context
2. **Scheme Guidance** — `ReasoningEngine.generateSchemeGuidance()` with scheme context + user profile
3. **Form Guidance** — `ReasoningEngine.generateFormGuidance()` with form field context
4. **Translation** — `ReasoningEngine.translateText()` (fallback translation)

### Cost Note
Nova Micro: ~\$0.035/1M input tokens, ~\$0.14/1M output tokens (cheapest Bedrock text model).

### Caching
In-memory SHA-256 cache in `AWSBedrockService._responseCache`. Expires after 30 minutes. Reduces repeated identical API calls.

---

## 2. Amazon Bedrock — Nova Lite (Multimodal Vision)

### Configuration
```dart
static const String bedrockNovaLite = 'amazon.nova-lite-v1:0';
```

### Invocation Files
| File | Method | Usage |
|---|---|---|
| `lib/core/services/aws_bedrock_service.dart` | `extractWithVision(prompt, imageBytes, systemPrompt)` | Image + text inference |
| `lib/core/services/document_ai_service.dart` | `_extractFromImage()` | Document OCR entry point |

### API Endpoint
```
POST https://bedrock-runtime.us-east-1.amazonaws.com/model/amazon.nova-lite-v1:0/converse
```

### Request Format (Multimodal)
```json
{
  "system": [{ "text": "<ocr_system_prompt>" }],
  "messages": [{
    "role": "user",
    "content": [
      { "image": { "format": "jpeg", "source": { "bytes": "<base64_image>" } } },
      { "text": "<json_schema_prompt>" }
    ]
  }],
  "inferenceConfig": { "maxTokens": 2048, "temperature": 0.0, "topP": 0.9 }
}
```

### Input
- `imageBytes`: `Uint8List` (compressed to 1.5MB max before sending)
- `documentType`: string key for selecting the JSON extraction schema
- Supported image formats: `jpeg`, `png`, `gif`, `webp`

### Output
JSON with extracted document fields + `confidence` score (0.0–1.0)

### System Prompt
```
You are a world-class Indian legal document OCR assistant.
Extract data from images into strictly valid raw JSON.
RULES:
1. Return ONLY strictly valid raw JSON.
2. If a field is missing, return null.
3. Dates: Use DD/MM/YYYY format.
4. Confidence: Add a "confidence" field (0.0 to 1.0).
```

---

## 3. SigV4 Authentication for Bedrock

**Why SigV4?** Bedrock does not support API keys from the Flutter client. It uses AWS IAM credentials.

**Flow:**
```
AuthProvider (Cognito session)
  → CognitoAuthSession.credentialsResult.value
  → { accessKeyId, secretAccessKey, sessionToken }
  → AWSSigV4Signer.sign(request, scope: { region: us-east-1, service: bedrock })
  → Signed HTTP request → Bedrock Runtime
```

**Libraries used:** `aws_signature_v4`, `aws_common`, `crypto`, `convert`

**Zero-Trust enforcement:**
```dart
if (!session.isSignedIn) {
  throw AuthRequiredException('Authentication required...');
}
```
Guest users cannot access Bedrock. They get an offline fallback message.

---

## 4. Amazon Cognito

### Configuration
- **User Pool**: `ap-south-1_jXuQiKf9L`
- **Identity Pool**: `ap-south-1:b2b7786b-f8e2-47b9-b246-e87480016a8d`
- **SDK**: `amplify_auth_cognito` ^2.10.0
- **Config file**: `lib/amplifyconfiguration.dart`

### Methods Used
| Method | Purpose |
|---|---|
| `Amplify.Auth.signIn()` | Email + password login |
| `Amplify.Auth.signUp()` | New user registration |
| `Amplify.Auth.confirmSignUp()` | Email OTP confirmation |
| `Amplify.Auth.confirmSignIn()` | OTP verification (Custom Auth) |
| `Amplify.Auth.fetchAuthSession()` | Session check + credential retrieval |
| `Amplify.Auth.getCurrentUser()` | Get authenticated user ID |
| `Amplify.Auth.fetchUserAttributes()` | Get name, email, phone |
| `Amplify.Auth.signOut()` | Sign out (with global option) |
| `Amplify.Auth.resetPassword()` | Password reset email |

---

## 5. AWS S3 — Document Storage

- **Bucket**: `civicvoicestorage71deb-dev`
- **SDK**: `amplify_storage_s3` ^2.10.0
- **Path pattern**: `protected/{identityId}/documents/{name}_{timestamp}.jpg`

| Operation | Code |
|---|---|
| Upload | `Amplify.Storage.uploadData(data, path)` |
| Download | `Amplify.Storage.downloadFile(path, localFile)` |
| Delete | `Amplify.Storage.remove(path)` |
| Signed URL | `Amplify.Storage.getUrl(path, expiresIn: 1hr)` |

---

## 6. AWS AppSync + DynamoDB

- **Endpoint**: `https://672nmbmz2zgntmteqh7tpew4i4.appsync-api.ap-south-1.amazonaws.com/graphql`
- **SDK**: `amplify_api` ^2.10.0

### GraphQL Operations
```graphql
# List all user documents
query ListUserDocuments { listUserDocuments { items { id name category size uploadDate status filePath isVerified extractedText } } }

# Create document metadata
mutation CreateUserDocument($input: CreateUserDocumentInput!) { createUserDocument(input: $input) { id ... } }

# Delete document
mutation DeleteUserDocument($input: DeleteUserDocumentInput!) { deleteUserDocument(input: $input) { id } }
```

---

## 7. Device Speech-to-Text (`speech_to_text`)

- **Package**: `speech_to_text` 7.3.0
- **Type**: On-device (Android STT engine — Google Speech Services)
- **No network call** — all STT processing is local
- **Initialization**: Lazy (`_ensureSTTInitialized()`) with 5-second timeout
- **Configuration**:
  - `listenFor`: 30 seconds max
  - `pauseFor`: 3 seconds silence detection
  - `partialResults`: true (real-time streaming text)
  - `listenMode`: confirmation mode
  - `cancelOnError`: true

---

## 8. Device Text-to-Speech (`flutter_tts`)

- **Package**: `flutter_tts` ^4.2.5
- **Type**: On-device (Android TTS engine — Google Text-to-Speech)
- **Language Support**: `en-IN`, `hi-IN`, `mr-IN`, `ta-IN`
- **Default settings**: `speechRate: 0.5`, `volume: 1.0`, `pitch: 1.0`
- **Voice gender selection**: Searches available voices by name for `male`/`female` preference

### Key Methods
```dart
_tts.setLanguage('hi-IN')
_tts.setSpeechRate(0.5)
_tts.speak(text)       // fire-and-forget
_tts.stop()
// speakAndWait() wraps speak() in a Completer resolved by setCompletionHandler
```

---

## 9. Prompt Engineering (PromptLoader)

Prompts are stored in `assets/prompts/ai_prompts.md` and loaded at startup via `PromptLoader.loadPrompts()`.

**Named prompts:**
- `general_assistant` — main voice chat system prompt with scheme knowledge base injected
- `form_guidance` — form field help system prompt
- `scheme_guidance` — scheme-specific Q&A system prompt  
- `document_verification` — document authenticity check prompt

**Template substitution:**
```dart
PromptLoader.getPrompt('general_assistant', {
  'schemesSummary': schemesSummary,
  'languageCode': languageCode,
})
```
Replaces `{schemesSummary}` and `{languageCode}` placeholders in the markdown template.

---

## 10. Model IDs Configured (Not All Active)

```dart
// lib/core/config/ai_config.dart
static const String bedrockNovaMicro = 'amazon.nova-micro-v1:0';  // ✅ ACTIVE
static const String bedrockNovaLite  = 'amazon.nova-lite-v1:0';   // ✅ ACTIVE
static const String bedrockLlama3    = 'meta.llama3-8b-instruct-v1:0';  // 🔷 Referenced, routes to Nova Micro
static const String bedrockLlama3Vision = 'meta.llama3-2-11b-instruct-v1:0'; // ❌ Not actively called
```

> **Note**: `chatWithLlama3()` in `AWSBedrockService` is an alias that routes to `chatWithNovaMicro()`. Llama 3 is no longer directly called despite the method name.

