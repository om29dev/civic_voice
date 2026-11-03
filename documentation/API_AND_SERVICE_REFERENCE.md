# API & Service Reference — Civic Voice

## External APIs

### 1. Amazon Bedrock Runtime API

**Base URL**: `https://bedrock-runtime.us-east-1.amazonaws.com`  
**Auth**: AWS SigV4 (Cognito temporary credentials)  
**SDK wrapper**: `lib/core/services/aws_bedrock_service.dart`

| Endpoint | Method | Purpose |
|---|---|---|
| `/model/amazon.nova-micro-v1:0/converse` | POST | Text generation (chat, guidance) |
| `/model/amazon.nova-lite-v1:0/converse` | POST | Multimodal (document OCR) |

**Request headers** (applied by SigV4 signer):
- `Content-Type: application/json`
- `Accept: application/json`
- `X-Amz-Content-Sha256: {sha256_of_body}`
- `Authorization: AWS4-HMAC-SHA256 ...`
- `X-Amz-Security-Token: {session_token}`

**Converse API body** (Nova Micro text):
```json
{
  "system": [{ "text": "system_prompt" }],
  "messages": [
    { "role": "user", "content": [{ "text": "user_message" }] }
  ],
  "inferenceConfig": { "maxTokens": 512, "temperature": 0.5, "topP": 0.9 }
}
```

**Converse API body** (Nova Lite multimodal):
```json
{
  "system": [{ "text": "ocr_system_prompt" }],
  "messages": [{
    "role": "user",
    "content": [
      { "image": { "format": "jpeg", "source": { "bytes": "<base64>" } } },
      { "text": "extract_schema_prompt" }
    ]
  }],
  "inferenceConfig": { "maxTokens": 2048, "temperature": 0.0, "topP": 0.9 }
}
```

**Response parsing**:
```dart
result['output']['message']['content'][n]['text']  // find item where containsKey('text')
```

**Error handling**:
- `AuthRequiredException` — user not authenticated
- `Exception('Bedrock Error {status}: {body}')` — non-200 response
- General `Exception` — rethrown, caught by `ReasoningEngine`

---

### 2. AWS AppSync GraphQL API

**Endpoint**: `https://672nmbmz2zgntmteqh7tpew4i4.appsync-api.ap-south-1.amazonaws.com/graphql`  
**Auth**: Cognito User Pool JWT (managed by `amplify_api`)  
**SDK wrapper**: `lib/core/services/document_vault_service.dart`

| Operation | Type | Description |
|---|---|---|
| `listUserDocuments` | Query | Fetch all documents for current user |
| `createUserDocument` | Mutation | Save new document metadata to DynamoDB |
| `deleteUserDocument` | Mutation | Remove document record from DynamoDB |

**SDK usage**:
```dart
final operation = Amplify.API.query(
  request: GraphQLRequest<String>(document: listQuery),
);
final response = await operation.response;
if (response.hasErrors) { /* handle */ }
final data = json.decode(response.data!);
```

---

### 3. Amazon S3 API

**Bucket**: `civicvoicestorage71deb-dev`  
**Region**: `ap-south-1`  
**Auth**: Cognito Identity Pool (IAM role `amplify-civicvoice-dev-71deb-unauthRole` / authRole)  
**SDK**: `amplify_storage_s3` ^2.10.0

| Operation | Method | Description |
|---|---|---|
| Upload | `Amplify.Storage.uploadData(data, path).result` | Upload image bytes to S3 |
| Download | `Amplify.Storage.downloadFile(path, localFile).result` | Download to local file |
| Delete | `Amplify.Storage.remove(path).result` | Remove object from S3 |
| Get URL | `Amplify.Storage.getUrl(path, options).result.url` | Get 1-hour signed URL |

---

### 4. Amazon Cognito APIs

**User Pool**: `ap-south-1_jXuQiKf9L`  
**Identity Pool**: `ap-south-1:b2b7786b-f8e2-47b9-b246-e87480016a8d`  
**SDK**: `amplify_auth_cognito` ^2.10.0

| Method | Purpose | Returns |
|---|---|---|
| `Amplify.Auth.signUp(username, password, options)` | Register new user | `SignUpResult` |
| `Amplify.Auth.confirmSignUp(username, code)` | Confirm email OTP | `SignUpResult` |
| `Amplify.Auth.signIn(username, password)` | Login | `SignInResult` |
| `Amplify.Auth.confirmSignIn(code)` | OTP MFA confirm | `SignInResult` |
| `Amplify.Auth.fetchAuthSession()` | Get session + credentials | `CognitoAuthSession` |
| `Amplify.Auth.getCurrentUser()` | Get auth user | `AuthUser` |
| `Amplify.Auth.fetchUserAttributes()` | Get profile attrs | `List<AuthUserAttribute>` |
| `Amplify.Auth.signOut(options)` | Sign out | void |
| `Amplify.Auth.resetPassword(username)` | Send reset email | void |

---

### 5. Google Maps Flutter

**Package**: `google_maps_flutter` ^2.6.1  
**API Key**: Configured in `AndroidManifest.xml` (META-DATA tag, not inspected for value)  
**Used in**: `OfficeLocatorScreen`

---

## Internal Services

### ReasoningEngine
**File**: `lib/core/services/reasoning_engine.dart`  
**Methods**:

| Method | Input | Output | Description |
|---|---|---|---|
| `generateAIResponse(userInput, history)` | String, List<Map> | Future<String> | General voice chat with intent detection |
| `generateFormGuidance(userInput, formContext, userProfile)` | String, Map, Map | Future<String> | Form field help AI response |
| `generateSchemeGuidance(userInput, schemeContext, userProfile, documents, history)` | Multiple | Future<String> | Scheme-specific AI guidance |
| `translateText(text, sourceLang)` | String, String | Future<String> | Bedrock-based translation |
| `verifyDocumentImage(base64Image)` | String | Future<Map> | Document authenticity verification |

---

### AWSBedrockService (Static)
**File**: `lib/core/services/aws_bedrock_service.dart`  

| Method | Description |
|---|---|
| `invokeModel(modelId, body, api)` | Low-level SigV4 Bedrock call |
| `chatWithNovaMicro(prompt, temperature, systemPrompt)` | Nova Micro text generation |
| `chatWithLlama3(prompt, temperature)` | Alias → routes to `chatWithNovaMicro()` |
| `extractWithVision(prompt, imageBytes, systemPrompt, modelId, mimeType)` | Nova Lite multimodal |

---

### DocumentVaultService (Static)
**File**: `lib/core/services/document_vault_service.dart`

| Method | Description |
|---|---|
| `uploadDocument(imageBytes, documentType, customName)` | S3 upload + AI extract + DynamoDB save |
| `getUserDocuments()` | GraphQL list query → List<Map> |
| `getUserExtractedData()` | getUserDocuments + merge → unified map |
| `getDocumentSignedUrl(storageKey)` | S3 signed URL (1hr) |
| `downloadDocument(storageKey, fileName)` | Download to device |
| `deleteDocument(documentId, storageKey)` | Delete from S3 + DynamoDB |
| `saveFormFillHistory(...)` | [STUB] Not implemented |

---

### DocumentAIService (Static)
**File**: `lib/core/services/document_ai_service.dart`

| Method | Description |
|---|---|
| `extractFromDocumentBytes(imageBytes, documentType)` | Main OCR entry point → Bedrock Nova Lite |
| `mergeExtractedData(List<CVIDocument>)` | Merge all doc extractions → ExtractedUserData |
| `_buildSystemPrompt()` | OCR rules system prompt |
| `_buildUserPrompt(documentType)` | Type-specific JSON schema prompt |

---

### FormTemplateService (Static)
**File**: `lib/features/auto_form/services/form_template_service.dart`

| Method | Description |
|---|---|
| `loadTemplate(serviceId)` | Load JSON from assets, parse, cache, return SmartFormTemplate? |
| `availableTemplateIds` | List<String> of registered template IDs |
| `hasTemplate(serviceId)` | bool check |
| `clearCache()` | Clear in-memory template cache |

**Registered templates**:
```dart
'pan_card'              → assets/forms/pan_card.json
'passport'              → assets/forms/passport.json
'driving_license'       → assets/forms/driving_license.json
'ration_card'           → assets/forms/ration_card.json
'senior_citizen_pension'→ assets/forms/senior_citizen_pension.json
'bpl_certificate'       → assets/forms/bpl_certificate.json  [FILE MISSING]
'caste_certificate'     → assets/forms/caste_certificate.json [FILE MISSING]
```

---

### NotificationService
**File**: `lib/core/services/notification_service.dart`  
**Package**: `flutter_local_notifications` ^21.0.0

| Method | Description |
|---|---|
| `init()` | Initialize notification channels (Android: high_importance_channel) |
| (schedule) | Schedule local notifications (timezone-aware via `timezone` package) |

---

### PromptLoader (Static)
**File**: `lib/core/services/prompt_loader.dart`

| Method | Description |
|---|---|
| `loadPrompts()` | Load `assets/prompts/ai_prompts.md` at startup |
| `getPrompt(name, substitutions)` | Get named prompt section with `{placeholder}` substituted |

---

### CsvSchemeService (Static)
**File**: `lib/core/services/csv_scheme_service.dart`

| Method | Description |
|---|---|
| `init()` | Parse CSV files from `assets/data/` at startup |
| (query methods) | Search/filter schemes from CSV data |

---

### AwsAmplifyService (Static)
**File**: `lib/core/services/aws_amplify_service.dart`

| Method | Description |
|---|---|
| `initialize()` | Add Cognito+API+S3 plugins, configure from `amplifyconfiguration.dart`. Thread-safe via `Completer`. |
| `isInitialized` | `Amplify.isConfigured` check |

---

## Government Portal URLs (from JSON Templates)

| Service | Portal | URL |
|---|---|---|
| PAN Card | NSDL / Protean | https://onlineservices.proteantech.in/paam/endUserRegisterContact.html |
| Passport | Passport Seva | (in passport.json) |
| Driving License | Parivahan | (in driving_license.json) |
| Ration Card | State PDS | (in ration_card.json) |
| Senior Citizen Pension | State Pension Portal | (in senior_citizen_pension.json) |
| Fallback | India Portal | https://india.gov.in |

