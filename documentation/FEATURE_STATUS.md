# Feature Status — Civic Voice

> Classification:
> - ✅ **Fully Implemented** — Real code, live backend, working end-to-end
> - ⚠️ **Partially Implemented** — Core works but incomplete edge cases, stubs, or UI gaps
> - 🔷 **Mock/Demo** — UI complete, backend is hardcoded or simulated
> - ❌ **Not Implemented** — Mentioned in plans/code but no working code

---

## Core Features

| Feature | Status | Evidence |
|---|---|---|
| AWS Amplify Initialization | ✅ | `AwsAmplifyService.initialize()` in `main.dart` |
| Amazon Cognito Authentication | ✅ | `auth_provider.dart` — full signIn/signUp/signOut/OTP flows |
| Guest / Demo Mode | ✅ | `AuthProvider.continueAsGuest()` — guest UUID, SharedPreferences session |
| Session Persistence | ✅ | `Amplify.Auth.fetchAuthSession()` on startup + guest restore |
| Google Sign-In | 🔷 | `loginWithGoogle()` exists but returns error — Hosted UI not configured |
| GoRouter Navigation | ✅ | 30+ routes, auth redirect, ShellRoute bottom nav |
| Multilingual Support (en/hi/mr/ta) | ✅ | `LanguageProvider`, `VoiceProvider.setLanguage()`, all JSON templates |
| Dark Theme | ✅ | `AppTheme.darkTheme` app-wide |
| Accessibility (text scale + color filter) | ✅ | `AccessibilityProvider` wired to `MaterialApp.builder` |

---

## AI Voice Assistant

| Feature | Status | Evidence |
|---|---|---|
| Microphone permission request | ✅ | `VoiceProvider.requestMicPermission()` |
| Speech-to-Text (on-device) | ✅ | `speech_to_text` 7.3.0, lazy init, 30s listen, partial results |
| Text-to-Speech (on-device) | ✅ | `flutter_tts` ^4.2.5, 4 Indian locales |
| TTS markdown sanitization | ✅ | `_sanitizeForSpeech()` strips **, ##, ``` etc. |
| `speakAndWait()` sequential TTS | ✅ | Completer-based, used for field-by-field explanation |
| AI chat via Amazon Bedrock Nova Micro | ✅ | `ReasoningEngine.generateAIResponse()` → SigV4 API call |
| Scheme intent detection | ✅ | `SmartIntentParser` — keyword/synonym scoring, 4 languages |
| Ambiguity handling | ✅ | Returns clarification question when 2 schemes equally match |
| Scheme-specific Q&A mode | ✅ | `ConversationProvider.setSchemeGuidanceContext()` → `generateSchemeGuidance()` |
| Conversation history | ✅ | `ConversationSession.messages` passed as history to Bedrock |
| Guest AI access blocked | ✅ | `AuthRequiredException` in `AWSBedrockService` — fallback message shown |
| Voice complaint filing | ⚠️ | `VoiceComplaintScreen` UI exists, recording works, submission backend stub |

---

## Document Vault

| Feature | Status | Evidence |
|---|---|---|
| Image selection (gallery/camera) | ✅ | `image_picker` in `AIDocumentScannerScreen` |
| Image compression | ✅ | `flutter_image_compress` — >1.5MB compressed to 85% quality |
| S3 upload (protected path) | ✅ | `DocumentVaultService.uploadDocument()` |
| Amazon Nova Lite OCR extraction | ✅ | `DocumentAIService._extractFromImage()` → Bedrock |
| DynamoDB metadata save | ✅ | GraphQL `createUserDocument` mutation |
| Document list retrieval | ✅ | GraphQL `listUserDocuments` query |
| Document deletion (S3 + DynamoDB) | ✅ | `deleteDocument()` — both layers |
| S3 signed URL viewing | ✅ | `getDocumentSignedUrl()` — 1hr expiry |
| Document download to device | ✅ | `downloadDocument()` → Downloads folder |
| Extracted data merge | ✅ | `DocumentAIService.mergeExtractedData()` |
| Biometric vault protection | ❌ | `local_auth` in pubspec but NOT wired to vault screen |
| Core document completion tracker | ✅ | `DocumentVaultProvider.coreUploaded` / `completionPercent` |

**Supported document types**: aadhaar, pan, passport, voterID, drivingLicense, bankPassbook, photo, incomeCertificate, rationCard, detect/automatic

---

## Smart AI Form Auto-Fill

| Feature | Status | Evidence |
|---|---|---|
| JSON form template loading | ✅ | `FormTemplateService.loadTemplate()` via `rootBundle` |
| Template in-memory caching | ✅ | `FormTemplateService._cache` |
| Data mapping from vault (by dataKey) | ✅ | `AutoFormProvider._mapExtractedDataToFields()` |
| Data mapping from user profile | ✅ | `AutoFormProvider.autoFillFromProfile()` |
| Animated field-by-field fill | ✅ | `startAnimatedFill()` — 250ms staggered delays |
| Skip animation button | ✅ | `AutoFormProvider.skipAnimation()` |
| Manual field editing | ✅ | `AutoFormProvider.updateField()` |
| Voice form explanation (TTS) | ✅ | `startVoiceExplanation()` — 4 languages |
| Voice filled data readout | ✅ | `speakFilledData()` |
| Stop/restart voice explanation | ✅ | `stopVoiceExplanation()` |
| Sensitive field masking in TTS | ✅ | `field.sensitive` → "ending in XXXX" |
| Form review screen | ✅ | `FormReviewScreen` |
| Data source badges | ✅ | `AutoFormProvider.getSourceLabel()` → "Aadhaar Card", "Your Profile" |
| Multilingual form labels | ✅ | All JSON templates have en/hi/mr/ta labels |
| Form fill history save | 🔷 | `saveFormFillHistory()` is a stub |

**Available templates**: pan_card, passport, driving_license, ration_card, senior_citizen_pension  
**Missing templates** (referenced but file absent): bpl_certificate, caste_certificate

---

## Government Portal Submission

| Feature | Status | Evidence |
|---|---|---|
| Guided submission steps (copy-assist) | ✅ | `GuidedSubmissionScreen` with step list |
| Copy field value to clipboard | ✅ | `ClipboardData` in `GuidedSubmissionScreen` |
| WebView loading of official portal | ✅ | `SmartBrowserScreen` with webview_flutter |
| Page translation toggle (Google Translate) | ✅ | `translate.google.com/translate?u=...` |
| Floating copy-assist panel | ✅ | Form data panel overlay in `SmartBrowserScreen` |
| Automatic form field injection | ❌ | NOT implemented — guided copy only |
| Automatic form submission | ❌ | NOT implemented |
| Portal session management | ❌ | NOT implemented |
| WebView domain allowlist | ❌ | Not implemented — any URL accepted |

---

## Government Services

| Feature | Status | Evidence |
|---|---|---|
| Service catalog | 🔷 | `lib/data/mock/services_data.dart` — hardcoded list |
| Service detail screen | ✅ | `ServiceDetailScreenV2` — description, eligibility, docs, AI chat |
| AI chat on service detail | ✅ | `ConversationProvider.setSchemeGuidanceContext()` |
| Eligibility checker | 🔷 | `EligibilityCheckerProvider` — keyword-based mock |

---

## Application Tracker

| Feature | Status | Evidence |
|---|---|---|
| Application list display | 🔷 | `ApplicationTrackerProvider._fetchMockTrackerData()` — hardcoded |
| Status history | 🔷 | Hardcoded status values (In Progress / Pending / Completed) |
| Real government API status | ❌ | Not implemented |
| Push notification on status change | ❌ | Not implemented |

---

## Scheme Recommendation

| Feature | Status | Evidence |
|---|---|---|
| Scheme discovery (browsing) | 🔷 | `SchemeDiscoveryProvider` — 5 hardcoded schemes |
| Category filtering | ✅ | `SchemeDiscoveryProvider.filterByCategory()` |
| Text search | ✅ | `SchemeDiscoveryProvider.searchSchemes()` |
| AI voice scheme guidance | ✅ | `ReasoningEngine.generateSchemeGuidance()` via Bedrock |
| Rule-based eligibility check | 🔷 | `EligibilityCheckerProvider` — demo keyword matching |
| Real government scheme database | ❌ | `SchemeKnowledgeBase` is curated static data |
| CSV scheme data | ⚠️ | `CsvSchemeService` loaded, usage extent unknown |

---

## Additional Features

| Feature | Status | Evidence |
|---|---|---|
| Citizen Profile (detailed) | ✅ | `CitizenProfileProvider`, multi-screen edit |
| Family Dashboard | ⚠️ | `FamilyDashboardScreen` exists, backend persistence partial |
| Notes (personal) | ⚠️ | `NotesScreen` + `NotesProvider`, local storage |
| Office Locator | ⚠️ | `OfficeLocatorScreen` + Google Maps — map works, data placeholder |
| Offline Guidance | ✅ | `OfflineGuidanceProvider` + `OfflineGuidanceScreen` |
| Local Notifications | ⚠️ | `NotificationService` initialized, no server push |
| Gamification (points/badges) | ⚠️ | UI complete (`GamificationScreen`), backend stub |
| Community Verification | 🔷 | `CommunityVerificationScreen` — UI only, no backend |
| Emergency Assistance | ⚠️ | `EmergencyScreen` + `EmergencyService` — basic contacts |
| Virtual Queue | 🔷 | `VirtualQueueScreen` — UI only |
| Analytics Dashboard | ⚠️ | `AnalyticsProvider` + `AnalyticsPanel` — local data, fl_chart |
| AR Document Guidance | 🔷 | `ARGuidanceScreen` — minimal |
| Settings Screen | ✅ | `SettingsScreen` |
| Onboarding Flow | ✅ | `FirstLaunchScreen` — sets `cvi_onboarded` flag |

