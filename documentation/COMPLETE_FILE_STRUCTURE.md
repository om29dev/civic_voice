# Complete File Structure — Civic Voice

> **Total files scanned**: ~185 Dart files + config/asset files
> **Note**: Files prefixed with `(DUPLICATE)` are legacy versions superseded by newer implementations.

---

## Root Level

| File | Purpose |
|---|---|
| `pubspec.yaml` | Package manifest — dependencies, assets, SDK constraints |
| `analysis_options.yaml` | Dart linter rules |
| `devtools_options.yaml` | Flutter DevTools settings |
| `design.md` | High-level product design notes |
| `requirements.md` | Feature requirements document |
| `README.md` | Project introduction |
| `AGENTS.md` | Hackathon ops guide (AWS endpoints, Amplify IDs) |

---

## `lib/` — Application Source

### `lib/main.dart`
Bootstrap file. Runs `AwsAmplifyService.initialize()`, starts `CsvSchemeService` and `PromptLoader` in background, then mounts all 18 providers in a `MultiProvider` tree before launching `CVIApp`.

### `lib/app.dart`
`CVIApp` — root `MaterialApp.router`. Configures dark theme, `LanguageProvider`-driven locale (en/hi/mr/ta), `AccessibilityProvider`-driven color filter & text scale, and `AppRouter`.

---

## `lib/core/`

### `lib/core/config/`
| File | Purpose |
|---|---|
| `ai_config.dart` | Bedrock model IDs & region constants (`nova-micro-v1:0`, `nova-lite-v1:0`, `llama3-8b`, `llama3-2-11b`). Region: `us-east-1`. |

### `lib/core/constants/`
| File | Purpose |
|---|---|
| `app_assets.dart` | Asset path string constants |
| `app_colors.dart` | Brand color palette constants |
| `app_language.dart` | Language code constants and locale mapping |
| `app_strings.dart` | Static UI strings |

### `lib/core/engine/`
| File | Purpose |
|---|---|
| `reasoning_engine.dart` | Duplicate of `lib/core/services/reasoning_engine.dart` (legacy) |

### `lib/core/router/`
| File | Purpose |
|---|---|
| `app_router.dart` | GoRouter configuration, `Routes` constants, auth redirect logic, `_AppShell` (bottom nav), all 30+ route definitions |

### `lib/core/services/`
| File | Purpose |
|---|---|
| `aws_amplify_service.dart` | Singleton Amplify initializer — adds Auth, API, Storage plugins, configures from `amplifyconfiguration.dart` |
| `aws_bedrock_service.dart` | **Core AI service** — SigV4-signed Bedrock REST calls, `chatWithNovaMicro()`, `extractWithVision()` (Nova Lite), in-memory 30-min cache, Zero-Trust auth check |
| `document_ai_service.dart` | **Document OCR** — compresses image, calls `AWSBedrockService.extractWithVision()` with document-type-specific JSON prompts, `mergeExtractedData()` |
| `document_inference_service.dart` | Alternative/additional inference logic (supporting service) |
| `document_vault_service.dart` | **Document CRUD** — S3 upload (protected paths), GraphQL mutations/queries for DynamoDB metadata, signed URL generation, download, delete |
| `citizen_profile_service.dart` | CRUD for citizen profile data (SharedPreferences or Amplify) |
| `csv_scheme_service.dart` | Loads `assets/data/` CSV scheme data at startup |
| `emergency_service.dart` | Emergency contact and resource helpers |
| `form_filler_service.dart` | Supporting service for form field filling logic |
| `notification_service.dart` | Initializes `flutter_local_notifications`, schedules local alerts |
| `offline_mode_service.dart` | Offline guidance content serving |
| `prompt_loader.dart` | Loads `assets/prompts/ai_prompts.md` markdown into named prompt templates with `{placeholder}` substitution |
| `queue_service.dart` | Virtual queue token generation and management |
| `reasoning_engine.dart` | **Main AI orchestrator** — `ReasoningEngine`, `SmartIntentParser`, calls Bedrock via `chatWithNovaMicro()`/`chatWithLlama3()` |
| `reminder_service.dart` | Application/document reminder scheduling |
| `scheme_knowledge_base.dart` | In-memory hardcoded scheme data (eligibility rules, document lists, names in all 4 languages) |
| `translation_service.dart` | Text translation via Bedrock Nova Micro |

### `lib/core/theme/` and `lib/core/themes/`
| File | Purpose |
|---|---|
| `app_theme.dart` (×2, duplicate paths) | Dark theme definition with Rajdhani font via `google_fonts` |

### `lib/core/utils/`
| File | Purpose |
|---|---|
| `app_initializer.dart` | Additional initialization helpers |
| `helpers.dart` | General utility functions |
| `intent_engine.dart` | Legacy intent parsing (superseded by `SmartIntentParser`) |
| `response_generator.dart` | Legacy response formatting utilities |

---

## `lib/providers/`

| Provider | State Managed |
|---|---|
| `auth_provider.dart` | Cognito session, `UserModel`, guest mode, onboarding flag |
| `voice_provider.dart` | STT state, TTS engine, `VoiceState` enum (idle/listening/processing/speaking) |
| `conversation_provider.dart` | Chat session, message list, `ReasoningEngine` invocation |
| `language_provider.dart` | Active language code + `Locale`, persisted in SharedPreferences |
| `user_provider.dart` | User profile data (name, age, income, location) |
| `citizen_profile_provider.dart` | Detailed `CitizenProfileModel` (full citizen data) |
| `document_vault_provider.dart` | Document list from S3/DynamoDB, extracted data map, upload/delete state |
| `document_scanner_provider.dart` | Standalone scanner state (image selection, extraction result) |
| `application_tracker_provider.dart` | **MOCK** application list (hardcoded demo data, no real portal API) |
| `scheme_discovery_provider.dart` | **MOCK** scheme list with category filter and search |
| `eligibility_checker_provider.dart` | **MOCK** eligibility chat — keyword-based demo matching |
| `complaint_provider.dart` | Voice complaint recording/submission state |
| `offline_guidance_provider.dart` | Offline guide content loading |
| `notification_provider.dart` | Local notification list state |
| `analytics_provider.dart` | Usage analytics tracking (local) |
| `accessibility_provider.dart` | Text scale, color filter (accessibility settings) |
| `services_provider.dart` | Government service list loading |
| `achievement_provider.dart` | Gamification achievement tracking |
| `gamification_provider.dart` | Points, badges, streaks |
| `community_provider.dart` | Community verification features |
| `notes_provider.dart` | User notes (personal notepad) |
| `theme_provider.dart` | Theme toggle (currently dark-only) |
| `features/auto_form/providers/auto_form_provider.dart` | **Full auto-fill lifecycle** — template loading, vault data mapping, profile mapping, animated sequential fill, voice TTS explanation, field readout |

---

## `lib/models/`

| Model | Data Structure |
|---|---|
| `user_model.dart` | `UserModel` — id, name, email, mobile, language, age, income, occupation, location, isGuest |
| `citizen_profile_model.dart` | `CitizenProfileModel` — fullName, mobile, email, state, district, age, income, caste, etc. |
| `CitizenProfile.dart` | Legacy alias/duplicate of CitizenProfileModel |
| `User.dart` | Legacy User class |
| `conversation_model.dart` | `ConversationSession`, `MessageModel` (text, isUser, timestamp, serviceTag, isServiceCard, confidence) |
| `cvi_document_model.dart` | `CVIDocument` (id, type, fileName, localPath, uploadedAt, isVerified, extractedData), `DocumentType` enum, `ExtractedUserData` |
| `document_model.dart` | Legacy document model |
| `UserDocument.dart` | Legacy user document |
| `service_model.dart` | `ServiceModel` — id, names (multilingual), description, eligibility, category, icon, portal URL, required docs |
| `service_model_new.dart` | Newer version of ServiceModel |
| `scheme_model.dart` | Scheme data with eligibility rules |
| `scheme_discovery_model.dart` | `SchemeDiscoveryModel` — id, title, category, description, eligibility, process |
| `application_model.dart` | Application submission model |
| `app_tracker_model.dart` | `AppTrackerModel` — id, schemeName, status, department, submittedDate, estimatedCompletion |
| `application_tracker_model.dart` | Extended tracker model |
| `eligibility_model.dart` | Eligibility check result |
| `complaint_model.dart` | Voice complaint data |
| `family_member_model.dart` | Family member profile |
| `government_service.dart` | Government service definition |
| `offline_guide_model.dart` | Offline guidance content |
| `process_step.dart` | Step-by-step process definition |
| `queue_token_model.dart` | Virtual queue token |
| `models.dart` | Barrel export |
| `ModelProvider.dart` | Amplify DataStore model provider (generated) |

---

## `lib/features/`

### `auth/`
| File | Purpose |
|---|---|
| `auth_screen.dart` | Entry-point auth screen (legacy root) |
| `screens/auth_screen.dart` | Auth tab container |
| `screens/authentication_screen.dart` | Combined login/register screen |
| `screens/login_screen.dart` | Email/password login UI |
| `screens/register_screen.dart` | Registration UI |

### `auto_form/` ← **Core Feature**
| File | Purpose |
|---|---|
| `models/auto_form_model.dart` | `SmartFormField`, `SmartFormTemplate`, `SubmitStep`, `AutoFillResult` |
| `providers/auto_form_provider.dart` | Full auto-fill state manager |
| `screens/smart_form_screen.dart` | Main auto-fill UI (route: `/smart-form/:serviceId`) |
| `screens/form_review_screen.dart` | Review completed form before submission |
| `screens/guided_submission_screen.dart` | Step-by-step manual guided submission screen |
| `services/form_template_service.dart` | JSON template loader with in-memory cache |

### `dashboard/`
| File | Purpose |
|---|---|
| `dashboard_screen.dart` | Legacy root |
| `screens/main_dashboard_screen.dart` | **Primary dashboard** — user greeting, quick stats, service shortcuts, scheme highlights |
| `screens/application_dashboard_screen.dart` | Application tracker dashboard |
| `screens/premium_dashboard_screen.dart` | Premium/advanced dashboard view |
| `widgets/analytics_panel.dart` | Analytics charts panel (fl_chart) |
| `widgets/citizen_profile_modal.dart` | Bottom sheet citizen profile |
| `widgets/horizontal_process_timeline.dart` | Horizontal timeline widget |

### `documents/`
| File | Purpose |
|---|---|
| `screens/ai_document_scanner_screen.dart` | Camera/gallery → Bedrock Nova Lite OCR screen |
| `screens/document_vault_screen.dart` | **Document Vault** — list, upload, delete, view extraction |
| `screens/documents_screen.dart` | Document hub (scanner + vault entry points) |
| `screens/ar_guidance_screen.dart` | AR document guidance (partially implemented) |
| `widgets/document_upload_flow.dart` | Multi-step upload UI |
| `widgets/vault_document_picker.dart` | Document type picker widget |

### `forms/`
| File | Purpose |
|---|---|
| `screens/auto_fill_form_screen.dart` | Older auto-fill screen (legacy, superceded by `auto_form/`) |
| `screens/smart_browser_screen.dart` | **Smart Browser** — WebView + copy-assist panel |

### `voice/` and `voice_interface/`
| File | Purpose |
|---|---|
| `voice_screen.dart` | **AI Voice Chat** — mic button, waveform, conversation bubbles |
| `screens/voice_complaint_screen.dart` | Voice-based complaint filing |
| `widgets/ai_visualizer.dart` | AI response animation |
| `widgets/form_help_fab.dart` | Floating action button for voice form help |
| `voice_interface/screens/conversation_interface_screen.dart` | Conversation UI |
| `voice_interface/screens/voice_dashboard_screen.dart` | Voice capability dashboard |
| `voice_interface/screens/voice_interface_screen.dart` | Main voice interface |

### `services/`
| File | Purpose |
|---|---|
| `screens/services_screen.dart` | Government services catalog |
| `screens/service_detail_screen_v2.dart` | Service detail with AI guidance, auto-fill button |
| `screens/eligibility_checker_screen.dart` | Eligibility Q&A screen (mock) |
| `screens/scheme_discovery_screen.dart` | Searchable scheme browser |
| `screens/scheme_detail_screen.dart` | Individual scheme detail |
| `screens/my_applications_screen.dart` | User's tracked applications |
| `screens/track_application_screen.dart` | Track a specific application |
| `screens/offline_guidance_screen.dart` | Offline content guide |
| `screens/emergency_screen.dart` | Emergency contacts/resources |
| `screens/virtual_queue_screen.dart` | Virtual queue management |
| `screens/all_services_screen.dart` | Full services list |
| `screens/service_navigation_screen.dart` | Navigation helper |
| `widgets/process_navigator.dart` | Process step navigator widget |

### `profile/`
| File | Purpose |
|---|---|
| `profile_screen.dart` | Profile hub |
| `screens/citizen_profile_dashboard.dart` | Detailed citizen profile |
| `screens/citizen_profile_screen.dart` | Profile view |
| `screens/complete_profile_screen.dart` | Profile completion wizard |
| `screens/edit_profile_screen.dart` | Edit user profile |
| `screens/family_dashboard_screen.dart` | Family members management |
| `screens/notes_screen.dart` | Personal notes |
| `screens/personal_information_screen.dart` | Personal info form |
| `screens/user_onboarding_screen.dart` | Initial onboarding data collection |

### Other Features
| Path | Purpose |
|---|---|
| `gamification/screens/gamification_screen.dart` | Points, badges, achievements |
| `gamification/widgets/achievement_badge.dart` | Badge display widget |
| `eligibility/screens/ai_eligibility_flow_screen.dart` | AI-driven eligibility flow |
| `eligibility/widgets/civic_confidence_gauge.dart` | Confidence gauge widget |
| `location/screens/office_locator_screen.dart` | Google Maps office finder |
| `location/screens/office_finder_screen.dart` | Office search |
| `notifications/screens/notifications_screen_v2.dart` | Notification list |
| `onboarding/screens/first_launch_screen.dart` | First-time user onboarding (sets `cvi_onboarded` flag) |
| `onboarding/screens/welcome_screen.dart` | Welcome slides |
| `recommendations/screens/recommendations_screen.dart` | Scheme recommendations |
| `community/screens/community_verification_screen.dart` | Community verification |
| `settings/screens/settings_screen.dart` | App settings |
| `splash/splash_screen.dart` | Animated splash screen |
| `navigation/screens/main_navigation_screen.dart` | Alternative navigation wrapper |
| `service_detail/service_detail_screen.dart` | Service detail (legacy) |

---

## `lib/widgets/`

| Widget | Purpose |
|---|---|
| `animated/animated_hero_greeting.dart` | Animated greeting text |
| `animated/flip_card.dart` | 3D flip card animation |
| `animated/particle_background.dart` | Particle effect background |
| `animated/progress_indicators.dart` | Custom progress widgets |
| `animated/voice_waveform.dart` | Voice waveform animation |
| `animated/waveform_painter.dart` | Custom painter for waveform |
| `buttons/animated_mic_button.dart` | Animated microphone button |
| `cards/message_bubble.dart` | Chat message bubble |
| `cards/quick_stats_card.dart` | Stats summary card |
| `cards/service_card.dart` | Government service card |
| `containers/glass_card.dart` | Glassmorphism card container |
| `decorative/chakra_painter.dart` | Ashoka Chakra custom painter |
| `decorative/jali_pattern.dart` | Indian jali pattern painter |
| `decorative/tricolor_bar.dart` | Indian tricolor stripe |
| `flag/waving_flag_widget.dart` | Animated waving flag (WebView HTML) |
| `glass/glass_card.dart` | Alternative glass card |
| `glass_card.dart` | Root-level legacy glass card |
| `navigation/cvi_bottom_nav.dart` | Custom bottom navigation bar (5 tabs) |
| `bilingual_label.dart` | Displays text in two languages |
| `cvi_button.dart` | Branded CVI action button |
| `indian_card.dart` | Indian-themed card widget |
| `loading_overlay.dart` | Full-screen loading overlay |
| `neon_button.dart` | Neon-glow button |
| `particle_background.dart` | Root-level particle widget |
| `service_icon_tile.dart` | Service icon tile |
| `t_text.dart` | Translatable text widget |
| `widgets.dart` | Barrel export |

---

## `lib/services/` (root-level, legacy)

| File | Purpose |
|---|---|
| `nlp_handler.dart` | Legacy NLP handler (superseded by `ReasoningEngine`) |
| `translation_service.dart` | Legacy translation service (superseded by `core/services/translation_service.dart`) |

---

## `lib/data/`

| File | Purpose |
|---|---|
| `csv_schemes_loader.dart` | CSV file parsing utilities for scheme data |
| `mock/services_data.dart` | Hardcoded mock government service data |

---

## `assets/`

| Path | Purpose |
|---|---|
| `assets/forms/pan_card.json` | PAN Card form template (9 fields, 4 languages, NSDL portal) |
| `assets/forms/passport.json` | Passport form template |
| `assets/forms/driving_license.json` | Driving License form template |
| `assets/forms/ration_card.json` | Ration Card form template |
| `assets/forms/senior_citizen_pension.json` | Senior Citizen Pension form template |
| `assets/prompts/ai_prompts.md` | Markdown prompt templates (general_assistant, form_guidance, scheme_guidance, document_verification) |
| `assets/data/` | CSV scheme datasets |
| `assets/lottie/` | Lottie animation files |
| `assets/images/` | App images |
| `assets/icons/` | App icon assets |
| `assets/flag/flag.html` | Waving flag HTML for WebView widget |

---

## `amplify/` — AWS Amplify Backend Config

| File | Purpose |
|---|---|
| `amplify/backend/api/civicvoiceapi/` | AppSync GraphQL API definition |
| `amplify/backend/auth/civicvoice53cd2ba4/cli-inputs.json` | Cognito User Pool + Identity Pool configuration |
| `amplify/backend/storage/s363cedb16/cli-inputs.json` | S3 bucket configuration |
| `amplify/backend/backend-config.json` | Backend resource registry |
| `amplify/team-provider-info.json` | Environment provider info |
| `src/amplifyconfiguration.json` | Runtime Amplify config (UserPool IDs, AppSync endpoint, S3 bucket) |
| `lib/amplifyconfiguration.dart` | Dart wrapper around `src/amplifyconfiguration.json` |

---

## `android/`

| File | Purpose |
|---|---|
| `android/app/build.gradle` | Android build config (minSdk, compileSdk, Kotlin version) |
| `android/app/src/main/AndroidManifest.xml` | Permissions (INTERNET, MICROPHONE, CAMERA, STORAGE, LOCATION), activity config |

---

## `docs/` — Existing Architecture Docs

| File | Purpose |
|---|---|
| `docs/core_architecture.md` | Core architecture documentation |
| `docs/data_architecture.md` | Data layer documentation |
| `docs/features_architecture.md` | Feature implementation documentation |
| `docs/models_architecture.md` | Model layer documentation |
| `docs/providers_architecture.md` | Provider layer documentation |
| `docs/root_architecture.md` | Root-level architecture |
| `docs/services_architecture.md` | Service layer documentation |
| `docs/widgets_architecture.md` | Widget documentation |

