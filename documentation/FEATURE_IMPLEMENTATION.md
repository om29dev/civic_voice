# Feature Implementation Status — Civic Voice

## Legend
- ✅ **Fully Implemented** — Real code, real backend integration, working in production
- ⚠️ **Partially Implemented** — Core flow works but edge cases, error paths, or integrations incomplete
- 🔷 **Mock/Demo** — UI and flow exist but backend is hardcoded/simulated
- ❌ **Not Implemented** — Referenced in code or plans but no working implementation

---

## A. Authentication System ✅ Fully Implemented

**Backend**: Amazon Cognito (via `amplify_auth_cognito`)

### Implemented Flows
| Flow | Method | Status |
|---|---|---|
| Email + Password Login | `AuthProvider.loginWithEmail()` | ✅ |
| Email Registration | `AuthProvider.signup()` | ✅ |
| Email Confirmation (OTP) | `AuthProvider.confirmSignUp()` | ✅ |
| OTP Sign-In (Phone/Custom Auth) | `AuthProvider.sendOTP()` / `verifyOTP()` | ⚠️ Requires Cognito Custom Auth triggers in Lambda |
| Guest/Demo Mode | `AuthProvider.continueAsGuest()` | ✅ |
| Session Persistence | `Amplify.Auth.fetchAuthSession()` on startup | ✅ |
| Sign Out | `AuthProvider.logout()` with global sign-out | ✅ |
| Password Reset | `AuthProvider.resetPassword()` | ✅ |
| Google Sign-In | `AuthProvider.loginWithGoogle()` | 🔷 Stub — returns error message |

### Session Management
- On startup, `AuthProvider._init()` calls `Amplify.Auth.fetchAuthSession()`.
- If signed in: fetches user attributes → builds `UserModel`.
- If not: tries to restore guest session from `SharedPreferences` (`cvi_user_session/guest_id`).
- `seenOnboard` flag cached synchronously for `GoRouter` redirect (avoids async race).
- Language preference stored per user: `cvi_lang_{userId}`.

### Router Integration
`AppRouter` listens to `AuthProvider` as a `refreshListenable`. The synchronous `redirect` function:
1. Forces splash screen on first session.
2. Unauthenticated → `/auth` or `/onboarding`.
3. Authenticated on auth/splash/onboarding → `/dashboard`.

---

## B. AI Voice Assistant ✅ Fully Implemented (Real-time AI)

**STT**: `speech_to_text` 7.3.0 (on-device)  
**TTS**: `flutter_tts` 4.2.5 (on-device)  
**AI**: Amazon Bedrock Nova Micro via `AWSBedrockService`

### Complete Voice Pipeline

```
User presses mic button
  → VoiceProvider.startListening(localeId)
  → Permission.microphone.request()
  → stt.SpeechToText.initialize()
  → stt.listen(partialResults: true, listenFor: 30s, pauseFor: 3s)
  → onResult callback → _partialText (streaming) → _transcribedText (final)
  → VoiceState.processing
  → ConversationProvider.sendMessage(text)
    → ReasoningEngine(languageCode).generateAIResponse(text, history)
      → SmartIntentParser.parse(text) — keyword/synonym intent detection
      → AWSBedrockService.chatWithNovaMicro(prompt)
        → SigV4 signed POST to bedrock-runtime.us-east-1.amazonaws.com
        → /model/amazon.nova-micro-v1:0/converse
      → Response string
    → MessageModel added to ConversationSession
  → VoiceProvider.speak(response)
  → FlutterTts.speak(sanitizedText)
  → VoiceState.speaking → VoiceState.idle
```

### VoiceState Enum
`idle | listening | processing | speaking | responding | error | permissionDenied | unavailable`

### Language Switching
`VoiceProvider.setLanguage(langCode)` maps:
- `hi` → `hi-IN`
- `mr` → `mr-IN`
- `ta` → `ta-IN`
- else → `en-IN`

### TTS Sanitization
`_sanitizeForSpeech()` strips markdown (`**`, `##`, `` ` ``, `[text](url)`, bullets) before passing to TTS engine, ensuring natural speech output.

### `speakAndWait()` vs `speak()`
- `speak()` — fire-and-forget.
- `speakAndWait()` — uses a `Completer` that resolves on TTS completion handler. Critical for sequential field-by-field explanation in `AutoFormProvider`.

### Scheme-Context Mode
When `ConversationProvider.setSchemeGuidanceContext()` is called (from ServiceDetailScreenV2), conversation switches to `generateSchemeGuidance()` which loads the `scheme_guidance` prompt template with scheme eligibility, required documents, and user profile context.

---

## C. AI Document Scanner ✅ Fully Implemented

**AI Model**: Amazon Bedrock Nova Lite (`amazon.nova-lite-v1:0`) — multimodal vision  
**Entry Points**: `AIDocumentScannerScreen`, `DocumentVaultProvider.addDocument()`

### Document Extraction Pipeline

```
User picks image (ImagePicker gallery/camera)
  → DocumentAIService.extractFromDocumentBytes(imageBytes, documentType)
    → Compress if > 1.5MB (FlutterImageCompress, quality=85, 1500px min)
    → Build systemPrompt (_buildSystemPrompt)
    → Build userPrompt (_buildUserPrompt(documentType)) — type-specific JSON schema
    → AWSBedrockService.extractWithVision(prompt, imageBytes, systemPrompt)
      → SigV4 POST /model/amazon.nova-lite-v1:0/converse
      → Body: { system, messages: [{ content: [{ image: {format, source: {bytes: base64}} }, { text: prompt }] }] }
    → Parse JSON from response text (finds { ... } substring)
    → Normalize numeric fields (confidence)
    → Return Map<String, dynamic>
```

### Supported Document Types & Extracted Fields

| Type | Key Fields Extracted |
|---|---|
| `aadhaar` | full_name, full_name_hindi, date_of_birth, gender, aadhaar_number (masked), address_line1, district, state, pincode |
| `pan` | full_name, father_name, date_of_birth, pan_number |
| `passport` | full_name, passport_number, date_of_birth, date_of_expiry, place_of_birth, father_name, mother_name, spouse_name, address_line1, pincode |
| `voter_id` | full_name, father_name, date_of_birth, gender, voter_id_number, district, state |
| `driving_license` | full_name, date_of_birth, driving_license_number, blood_group, address_line1, state, date_of_expiry |
| `bank_passbook` | full_name, account_number (masked), bank_name, branch_name, ifsc_code |
| `income_certificate` | full_name, father_name, annual_income, district, state, certificate_number |
| `ration_card` | full_name, ration_card_number, address_line1, district, state |
| `detect` / `automatic` | Auto-identifies document type + all relevant fields |

### Data Merge
`DocumentAIService.mergeExtractedData(List<CVIDocument>)` iterates all uploaded documents and picks the first non-null value for each field to build a unified `ExtractedUserData` object.

---

## D. Secure Document Vault ✅ Fully Implemented

**Storage**: AWS S3 (protected identity paths)  
**Metadata**: Amazon DynamoDB via AppSync GraphQL  
**Access Control**: Cognito Identity Pool — `protected/{identityId}/documents/` path

### Storage Path Format
```
protected/{cognito-identity-id}/documents/{docType}_{timestamp}.jpg
```
This path is isolated per Cognito Identity — other users cannot access it without explicit share grants.

### Upload Flow
```
DocumentVaultProvider.addDocument(imageBytes, documentType)
  → DocumentVaultService.uploadDocument()
    → _protectedPath() — validates Cognito session, gets identityId
    → Amplify.Storage.uploadData(bytes, path: protected/{id}/documents/...)
    → DocumentAIService.extractFromDocumentBytes() — AI extraction
    → GraphQL mutation: createUserDocument (saves to DynamoDB via AppSync)
    → Returns { success, confidence, extractedData, filePath }
```

### Retrieval (loadDocuments)
```
DocumentVaultService.getUserDocuments()
  → GraphQL query: listUserDocuments
  → Returns List<Map> with metadata + extractedText (JSON string)
DocumentVaultService.getUserExtractedData()
  → getUserDocuments() → map to CVIDocument → mergeExtractedData()
  → Returns unified extracted data map for form auto-fill
```

### Deletion
`deleteDocument(documentId, storageKey)`:
1. `Amplify.Storage.remove(path)` — removes from S3.
2. GraphQL `deleteUserDocument` mutation — removes from DynamoDB.

### Signed URLs
`getDocumentSignedUrl(storageKey)` generates 1-hour expiring S3 pre-signed URLs for in-app viewing.

### Security Notes
- **Biometric** protection: `local_auth` is in `pubspec.yaml` but NOT currently wired to the vault UI (planned).
- `flutter_secure_storage` is in dependencies but not currently used for document vault (documents live on S3).
- Documents are accessible only to the authenticated identity (S3 IAM policy enforced via Cognito Identity Pool unauthRole/authRole).

---

## E. Smart AI Government Form Auto-Fill ✅ Fully Implemented

**Files**: `auto_form_provider.dart`, `form_template_service.dart`, `auto_form_model.dart`, JSON templates

### Complete Auto-Fill Pipeline

**Step 1 — Template Load**
```
AutoFormProvider.loadTemplate(serviceId)
  → FormTemplateService.loadTemplate(serviceId)
    → Check in-memory cache
    → Load from assets/forms/{serviceId}.json via rootBundle
    → SmartFormTemplate.fromJson() → cached
    → Initialize _filledValues = {for each field: null}
```

**Step 2 — Data from Vault**
```
AutoFormProvider.autoFillFromVault()
  → DocumentVaultService.getUserExtractedData()
    → listUserDocuments (GraphQL) → mergeExtractedData()
  → _mapExtractedDataToFields(userData)
    → For each SmartFormField:
        rawValue = userData[field.dataKey]  ← matches by dataKey
        format dates (DD/MM/YYYY)
        _filledValues[field.id] = value
        _dataSources[field.id] = sourceLabel
```

**Step 3 — Data from Profile**
```
AutoFormProvider.autoFillFromProfile(userProvider, citizenProvider)
  → Build profileData map from UserModel + CitizenProfileModel
  → For each unfilled field: profileData[field.dataKey]
  → Fill remaining empty fields
```

**Step 4 — Animated Fill**
```
AutoFormProvider.startAnimatedFill(delayMs: 250)
  → Save current values, clear all
  → For each field (index 0 to N):
      _animatedFieldIndex = i
      Restore _filledValues[field.id]
      notifyListeners()  ← triggers field highlight animation in UI
      await Future.delayed(250ms)
  → Restore all values
  → _isAnimating = false
```

**Step 5 — Voice Explanation**
```
AutoFormProvider.startVoiceExplanation(langCode, voiceProvider)
  → voiceProvider.setLanguage(langCode)
  → speakAndWait("This is {formName} form.")
  → speakAndWait(introExplanation[langCode])
  → speakAndWait("For filling this form, you need: {requiredFields}")
  → For each field:
      _currentExplainIndex = i
      speakAndWait(field.voiceExplanation[langCode])
```

**Step 6 — Manual Edit**
```
AutoFormProvider.updateField(fieldId, value)
  → _filledValues[fieldId] = value
  → _dataSources[fieldId] = 'Manual Input'
  → _recalculateStats()
```

**Step 7 — Form Review**
`FormReviewScreen` — displays all filled values by label, shows data source badges.

**Step 8 — Guided Submission**
`GuidedSubmissionScreen` — step-by-step instructions with copy-to-clipboard for each field value. Then opens `SmartBrowserScreen` with the official portal URL.

### JSON Template Structure (pan_card.json example)
```json
{
  "serviceId": "pan_card",
  "formTitle": { "en": "PAN Card Application", "hi": "...", "mr": "...", "ta": "..." },
  "portalName": "NSDL / Protean",
  "officialUrl": "https://onlineservices.proteantech.in/...",
  "introExplanation": { "en": "...", "hi": "...", "mr": "...", "ta": "..." },
  "requiredDocuments": ["aadhaar"],
  "submitSteps": [{ "step": 1, "instruction": { "en": "...", "hi": "..." } }],
  "fields": [{
    "id": "full_name",
    "dataKey": "full_name",        // matches extracted data key
    "fieldType": "text|date|dropdown",
    "required": true,
    "sourceDocument": "aadhaar",   // hint for UI badge
    "voiceExplanation": { "en": "...", "hi": "...", "mr": "...", "ta": "..." },
    "sensitive": false,             // if true: mask in TTS readout
    "validationPattern": "regex",
    "options": ["Male", "Female"]  // for dropdowns
  }]
}
```

---

## F. Voice-Assisted Form Explanation ✅ Fully Implemented

Implemented entirely in `AutoFormProvider.startVoiceExplanation()` and `speakFilledData()`.

### What is spoken:
1. **Form name** — e.g. "This is PAN Card Application form."
2. **Custom intro** — from `template.introExplanation[langCode]`
3. **Required fields list** — "For filling this form, you will need: Full Name, Aadhaar Number..."
4. **Per-field explanation** — each `field.voiceExplanation[langCode]`
5. **Filled data readout** (separate `speakFilledData()`) — "Full Name: Vikram Singh, filled from Aadhaar Card"
6. **Summary** — "X out of Y fields filled. Z fields need manual input."

**Stop/Replay**: `stopVoiceExplanation(voiceProvider)` sets `_isExplaining = false` and calls `voiceProvider.stopSpeaking()`. Replay restarts from the beginning.

**Language Support**: All 4 languages fully supported via per-field `voiceExplanation` maps in JSON + provider language maps.

**Sensitive field masking**: If `field.sensitive == true`, TTS reads "ending in {last 4 digits}" instead of the full value.

---

## G. Smart Browser & Guided Submission ⚠️ Partially Implemented

> **IMPORTANT**: The app does NOT automatically fill form fields on government portals. This is a **guided copy-assist** system.

### SmartBrowserScreen (`/smart-browser`)
- Loads official portal URL in a `WebView` (webview_flutter).
- Shows a floating panel with pre-filled form data.
- User can **copy each field value** to clipboard and paste into the web form manually.
- "Translate page" toggle: loads `translate.google.com/translate?u={url}` for vernacular users.
- Navigation restricted to the initial domain (basic URL check, not strict CSP).
- Does NOT inject JavaScript into the portal.

### GuidedSubmissionScreen (`/guided-submit`)
- Shows numbered step-by-step instructions from `template.submitSteps`.
- Each step has a "Copy" button for the relevant field value.
- After completion, navigates to `SmartBrowserScreen`.

### What is NOT implemented:
- Automatic form field injection via JavaScript into government portals.
- Automatic form submission.
- Portal session management.

---

## H. Government Services ⚠️ Partially Implemented

| Service | JSON Template | AI Chat | Mock Data |
|---|---|---|---|
| PAN Card | ✅ | ✅ | — |
| Passport | ✅ | ✅ | — |
| Driving License | ✅ | ✅ | — |
| Ration Card | ✅ | ✅ | — |
| Senior Citizen Pension | ✅ | ✅ | — |
| BPL Certificate | 🔷 (file missing, fallback) | ✅ | — |
| Caste Certificate | 🔷 (file missing, fallback) | ✅ | — |
| PM Kisan | ❌ No template | ✅ (via Bedrock) | 🔷 |
| Ayushman Bharat | ❌ No template | ✅ (via Bedrock) | 🔷 |
| PMAY | ❌ No template | ✅ (via Bedrock) | 🔷 |

Service list data comes from `lib/data/mock/services_data.dart` (hardcoded), not a live government API.

---

## I. Application Tracker 🔷 Mock/Demo

**Status**: Fully mocked. `ApplicationTrackerProvider._fetchMockTrackerData()` returns 3 hardcoded applications with simulated 1-second delay.

**Not implemented**: Connection to any government portal API, real application status polling, push notification for status changes.

**Future integration point**: AWS AppSync → Lambda → Government API gateway (commented in code).

---

## J. Government Scheme Recommendation Engine ⚠️ Partially Implemented

Two layers:
1. **SchemeDiscoveryProvider** — 🔷 Mock: 5 hardcoded schemes with category filter and text search.
2. **ReasoningEngine + SchemeKnowledgeBase** — ✅ Real: `SchemeKnowledgeBase.schemes` contains structured scheme data with eligibility rules. `SmartIntentParser` uses keyword/synonym matching. `ReasoningEngine.generateAIResponse()` sends scheme summaries + user query to Bedrock Nova Micro.

**Eligibility type**: The `EligibilityCheckerProvider` is 🔷 Mock (keyword-based, hardcoded matches). The voice assistant AI response for eligibility is ✅ AI-generated (Bedrock) but not verified against real government databases.

**RecommendationsScreen** (`/recommendations`) — partially implemented, uses scheme knowledge base but UI completeness uncertain from code inspection.

---

## K. Additional Features

| Feature | Status | Notes |
|---|---|---|
| Citizen Profile | ✅ | `CitizenProfileProvider`, multi-screen edit flow |
| Family Dashboard | ⚠️ | `FamilyDashboardScreen` exists, data model defined, persistence partial |
| Office Locator | ⚠️ | `OfficeLocatorScreen` with Google Maps — map renders, but office data is placeholder |
| Notifications | ⚠️ | `flutter_local_notifications` initialized, `NotificationProvider` exists, no real push |
| Gamification | ⚠️ | `GamificationScreen`, `AchievementProvider`, badge widget — UI complete, backend stub |
| Community Verification | 🔷 | `CommunityVerificationScreen` exists, no backend |
| Emergency Assistance | ⚠️ | `EmergencyScreen` + `EmergencyService` — basic emergency contacts |
| Offline Guidance | ✅ | `OfflineGuidanceProvider` + `OfflineGuidanceScreen` with local content |
| Analytics Dashboard | ⚠️ | `AnalyticsProvider` + `AnalyticsPanel` with fl_chart — local data only |
| Voice Complaints | ⚠️ | `VoiceComplaintScreen` — recording UI complete, submission backend stub |
| Virtual Queue | 🔷 | `VirtualQueueScreen` + `QueueService` — UI exists, no real queue backend |
| AR Document Guidance | 🔷 | `ARGuidanceScreen` exists — minimal implementation |
| Notes | ✅ | `NotesScreen` + `NotesProvider` — local storage |
| Dark Theme | ✅ | App-wide dark theme only |
| Accessibility | ✅ | Text scale + color filter via `AccessibilityProvider` |

