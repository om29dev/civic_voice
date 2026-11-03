# Database & Storage — Civic Voice

## Storage Architecture Overview

```
┌──────────────────────────────────────────────────────────────┐
│                    Data Storage Layers                        │
├───────────────────────┬──────────────────────────────────────┤
│ Layer                 │ Technology                           │
├───────────────────────┼──────────────────────────────────────┤
│ Document Files        │ Amazon S3 (amplify_storage_s3)       │
│ Document Metadata     │ Amazon DynamoDB via AppSync GraphQL  │
│ User Session / Auth   │ Amazon Cognito (tokens)              │
│ Preferences / Settings│ SharedPreferences (local)            │
│ Form Templates        │ Flutter assets (JSON files)          │
│ Scheme Knowledge      │ In-memory Dart (SchemeKnowledgeBase) │
│ Offline Content       │ Local assets + SharedPreferences     │
│ AI Response Cache     │ In-memory Map (30-min TTL)           │
└───────────────────────┴──────────────────────────────────────┘
```

---

## 1. Amazon S3 — Document Files

**Bucket**: `civicvoicestorage71deb-dev`  
**Region**: `ap-south-1`  
**SDK**: `amplify_storage_s3` ^2.10.0

### Storage Path Structure
```
protected/
  {cognito-identity-id}/
    documents/
      aadhaar_1730000000000.jpg
      pan_1730000001000.jpg
      passport_1730000002000.jpg
```

`protected/` prefix enforces Cognito Identity-based access. Files under `protected/{identityId}/` are only accessible by the authenticated user with that identity ID.

### Operations

| Operation | Method | Auth Required |
|---|---|---|
| Upload | `Amplify.Storage.uploadData(StorageDataPayload.bytes, StoragePath.fromString)` | ✅ Yes |
| Download | `Amplify.Storage.downloadFile(path, localFile)` | ✅ Yes |
| Delete | `Amplify.Storage.remove(path)` | ✅ Yes |
| Signed URL | `Amplify.Storage.getUrl(path, expiresIn: 1hr)` | ✅ Yes |

### Access Control
```dart
static Future<String> _protectedPath(String storageKey) async {
  final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
  if (!session.isSignedIn) throw StateError('Authentication required');
  final identityId = session.identityIdResult.value;
  return 'protected/$identityId/$storageKey';
}
```

---

## 2. Amazon DynamoDB — Document Metadata (via AppSync)

**AppSync Endpoint**: `https://672nmbmz2zgntmteqh7tpew4i4.appsync-api.ap-south-1.amazonaws.com/graphql`  
**SDK**: `amplify_api` ^2.10.0  

### UserDocument Schema (inferred from GraphQL operations)

```
UserDocument {
  id              : String (DynamoDB primary key, auto-generated)
  name            : String (display name / filename)
  category        : String (document type: aadhaar, pan, passport, etc.)
  size            : String ("123.4 KB")
  uploadDate      : AWSDateTime (ISO 8601 UTC)
  status          : String ("Verified" | "Pending")
  filePath        : String (S3 storage key, relative to protected/{id}/)
  isVerified      : Boolean (confidence > 0.6)
  extractedText   : String (JSON stringified extracted data map)
  owner           : String (Cognito user identity — auto-applied by AppSync auth)
}
```

### GraphQL Operations

**Create:**
```graphql
mutation CreateUserDocument($input: CreateUserDocumentInput!) {
  createUserDocument(input: $input) { id name category size uploadDate status filePath isVerified extractedText }
}
```

**List:**
```graphql
query ListUserDocuments {
  listUserDocuments {
    items { id name category size uploadDate status filePath isVerified extractedText }
  }
}
```

**Delete:**
```graphql
mutation DeleteUserDocument($input: DeleteUserDocumentInput!) {
  deleteUserDocument(input: $input) { id }
}
```

### DynamoDB Access Pattern
AppSync automatically scopes `listUserDocuments` to the authenticated user via `@auth` directive (owner-based authorization). Users cannot query other users' documents.

---

## 3. Amazon Cognito — Auth & Credential Storage

**User Pool**: `ap-south-1_jXuQiKf9L`  
**Identity Pool**: `ap-south-1:b2b7786b-f8e2-47b9-b246-e87480016a8d`

### Data Stored in Cognito
- User credentials (hashed passwords by Cognito — never visible)
- User attributes: `name`, `email`, `phone_number`
- User Pool ID (`userId` / `username`)

### Temporary Credentials
Cognito Identity Pool issues short-lived AWS credentials for:
- Bedrock API access
- S3 protected-path access
- AppSync API calls

---

## 4. SharedPreferences — Local Key-Value Storage

Used for lightweight persistent state.

| Key | Value | Purpose |
|---|---|---|
| `cvi_onboarded` | bool | Whether first-launch onboarding was completed |
| `cvi_user_session/guest_id` | String | Guest user UUID |
| `cvi_user_session/lang` | String | Guest user language code |
| `cvi_lang_{userId}` | String | Authenticated user language preference |
| `cvi_language` | String | Current app language (LanguageProvider) |

---

## 5. Flutter Assets — Form Templates (JSON)

Form templates are bundled in the APK as asset files. No network call needed to load templates.

**Format**: JSON  
**Location**: `assets/forms/`  
**Loader**: `FormTemplateService.loadTemplate()` via `rootBundle.loadString()`  
**Cache**: In-memory `Map<String, SmartFormTemplate>` (cleared on hot reload)

### Template Schema Reference
```json
{
  "serviceId": "string",
  "formTitle": { "en": "...", "hi": "...", "mr": "...", "ta": "..." },
  "portalName": "string",
  "officialUrl": "https://...",
  "introExplanation": { "en": "...", "hi": "...", "mr": "...", "ta": "..." },
  "requiredDocuments": ["aadhaar", "pan"],
  "optionalDocuments": ["photo"],
  "submitSteps": [
    { "step": 1, "instruction": { "en": "...", "hi": "..." } }
  ],
  "fields": [
    {
      "id": "full_name",
      "label": { "en": "Full Name", "hi": "पूरा नाम", "mr": "पूर्ण नाव", "ta": "முழு பெயர்" },
      "dataKey": "full_name",
      "fieldType": "text|date|dropdown",
      "required": true,
      "options": ["Male", "Female"],
      "validationPattern": "^\\d{6}$",
      "sourceDocument": "aadhaar|pan|profile|manual",
      "voiceExplanation": { "en": "...", "hi": "...", "mr": "...", "ta": "..." },
      "sensitive": false
    }
  ]
}
```

---

## 6. In-Memory — Scheme Knowledge Base

`lib/core/services/scheme_knowledge_base.dart` holds hardcoded scheme data.

### Structure
```dart
class KnownScheme {
  final String id;
  final Map<String, String> names;       // { 'en': ..., 'hi': ..., 'ta': ... }
  final String description;
  final List<EligibilityRule> eligibilityRules;
  final List<RequiredDocument> requiredDocuments;
}

class EligibilityRule {
  final String parameter;  // e.g. 'age'
  final String operator;   // e.g. '>='
  final String value;      // e.g. '60'
}
```

Used by `ReasoningEngine._buildSystemInstruction()` to construct the AI system prompt with scheme summaries. This is NOT a live government database — it is curated static data.

---

## 7. In-Memory — AI Response Cache

`AWSBedrockService._responseCache`: `Map<String, _CachedResponse>`

- Key: SHA-256 hash of `"{modelId}:{jsonBody}"`
- Value: `_CachedResponse { data, timestamp }`
- TTL: 30 minutes
- Scope: app session only (cleared on app restart)

This prevents repeated identical Bedrock calls (cost and latency optimization).

---

## 8. Data Models Reference

### UserModel
```dart
class UserModel {
  final String id;           // Cognito userId
  final String name;
  final String email;
  final String mobile;
  final String language;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isGuest;
  final int? age;
  final double? annualIncome;
  final String? occupation;
  final String? location;
}
```

### CitizenProfileModel
```dart
class CitizenProfileModel {
  final String fullName;
  final String mobile;
  final String email;
  final String state;
  final String? district;
  final int age;
  final double income;
  final String? caste;
  // + additional demographic fields
}
```

### CVIDocument
```dart
class CVIDocument {
  final String id;
  final DocumentType type;  // enum: aadhaar, pan, passport, voterID, drivingLicense, bankPassbook, photo, incomeCertificate, rationCard, other
  final String fileName;
  final String localPath;   // S3 storage key
  final DateTime uploadedAt;
  final bool isVerified;
  final Map<String, dynamic> extractedData;
}
```

### ExtractedUserData
Unified merged extracted data from all user documents:
```dart
class ExtractedUserData {
  String? fullName, fatherName, motherName, spouseName;
  DateTime? dateOfBirth;
  String? gender, bloodGroup;
  String? aadhaarNumber, panNumber, passportNumber, voterIdNumber, drivingLicenseNumber;
  String? addressLine1, addressLine2, district, state, pincode;
  // toJson() → Map<String, dynamic> for form field mapping
}
```

### AppTrackerModel
```dart
class AppTrackerModel {
  final String id;
  final String schemeName;
  final String status;      // 'Pending' | 'In Progress' | 'Completed' | 'Rejected'
  final String department;
  final DateTime submittedDate;
  final DateTime? estimatedCompletion;
}
```

---

## 9. Stubbed / Incomplete Data Operations

| Operation | File | Status | Notes |
|---|---|---|---|
| Form fill history save | `DocumentVaultService.saveFormFillHistory()` | 🔷 Stub | `form_fill_history` table not yet added to schema.graphql |
| Extracted data merge into UserExtractedData table | `DocumentVaultService.uploadDocument()` | 🔷 Commented | `_mergeExtractedData()` commented out, needs separate table |
| Family member data persistence | `FamilyDashboardScreen` | ⚠️ Partial | No backend table defined |
| Notes persistence | `NotesProvider` | ⚠️ Partial | Needs verification of backend |

