# Civic Voice (CVI) — Project Overview

## 1. What Is Civic Voice?

**Civic Voice** (package name: `civic_voice_interface`) is a Flutter-based, AI-powered citizen governance platform designed for India. Its mission is to reduce friction between ordinary citizens and government services — specifically targeting digitally-underserved communities across Bharat who speak Hindi, Marathi, Tamil, or English.

The app provides:
- A **voice-first AI assistant** backed by Amazon Bedrock (Nova Micro) for government scheme guidance.
- A **smart document vault** that uses Amazon Nova Lite multimodal vision to scan and extract data from Indian ID documents.
- An **AI form auto-fill engine** that reads extracted document data and fills government form templates automatically, field-by-field, with animated TTS narration.
- **Guided government portal submission** via an embedded WebView with copy-to-clipboard helpers (NOT automatic form injection).
- **Scheme discovery and eligibility** (partially mock/demo).
- **Application tracking** (demo data only, no real portal APIs).
- **Government office locator** via Google Maps.
- **Offline guidance** for citizens without internet.
- **Multilingual TTS/STT** in English (en-IN), Hindi (hi-IN), Marathi (mr-IN), and Tamil (ta-IN).

## 2. Hackathon Context

- **Event**: AWS Zero to Shipped Hackathon (Sep 18 – Oct 2, 2026)
- **Target Category**: `#social-good` — digital equity, health & education schemes for underserved citizens in Bharat
- **Target Lane**: `#community` — civic empowerment, open welfare discovery
- **AWS Account ID**: 742435394268 (all IDs stored only in backend config — not in app binary)
- **Amplify App ID**: `d2o5i1x3ygcmoz`
- **Live URL**: https://main.d2o5i1x3ygcmoz.amplifyapp.com

## 3. Platform & Stack

| Layer | Technology |
|---|---|
| Mobile Framework | Flutter 3.x (Dart ≥3.0, Android-only target for hackathon) |
| State Management | `provider` ^6.1.2 (ChangeNotifier pattern) |
| Routing | `go_router` ^17.1.0 with declarative auth redirect |
| Authentication | AWS Amplify + Amazon Cognito (email/password + OTP) |
| AI / Conversational | Amazon Bedrock — Nova Micro (text), Nova Lite (vision) |
| Document Storage | AWS S3 via `amplify_storage_s3` (protected identity paths) |
| Database (metadata) | Amazon DynamoDB via AppSync GraphQL (`amplify_api`) |
| Speech-to-Text | `speech_to_text` 7.3.0 (on-device, device STT engine) |
| Text-to-Speech | `flutter_tts` ^4.2.5 (on-device, device TTS engine) |
| Maps | Google Maps Flutter ^2.6.1 |
| Notifications | `flutter_local_notifications` ^21.0.0 |
| Image Compression | `flutter_image_compress` ^2.1.0 |
| HTTP | `http` ^1.1.0 + SigV4 signing via `aws_signature_v4` |

## 4. Key AWS Services Currently Integrated (LIVE)

| AWS Service | SDK | Purpose | Status |
|---|---|---|---|
| Amazon Cognito | `amplify_auth_cognito` | User auth (email + OTP) | ✅ Live |
| Amazon S3 | `amplify_storage_s3` | Document file storage (protected paths) | ✅ Live |
| AWS AppSync (GraphQL) | `amplify_api` | Document metadata (DynamoDB via AppSync) | ✅ Live |
| Amazon Bedrock — Nova Micro | SigV4 HTTP | AI chat, form guidance, scheme Q&A | ✅ Live |
| Amazon Bedrock — Nova Lite | SigV4 HTTP | Multimodal document OCR & extraction | ✅ Live |

## 5. Supported Languages

| Language | Code | STT Locale | TTS Locale |
|---|---|---|---|
| English | `en` | `en-IN` | `en-IN` |
| Hindi | `hi` | `hi-IN` | `hi-IN` |
| Marathi | `mr` | `mr-IN` | `mr-IN` |
| Tamil | `ta` | `ta-IN` | `ta-IN` |

## 6. Supported Government Services (with JSON Templates)

| Service | Template File | Portal |
|---|---|---|
| PAN Card | `assets/forms/pan_card.json` | NSDL / Protean |
| Passport | `assets/forms/passport.json` | Passport Seva |
| Driving License | `assets/forms/driving_license.json` | Parivahan |
| Ration Card | `assets/forms/ration_card.json` | State PDS portal |
| Senior Citizen Pension | `assets/forms/senior_citizen_pension.json` | State pension portal |
| BPL Certificate | Referenced in `FormTemplateService` (file missing in assets) | — |
| Caste Certificate | Referenced in `FormTemplateService` (file missing in assets) | — |

## 7. Architecture Philosophy

```
User Voice Input
      │
      ▼
STT (device) ──► VoiceProvider ──► ConversationProvider
                                         │
                                         ▼
                               ReasoningEngine
                                  │
                     ┌────────────┴──────────────────┐
                     ▼                               ▼
             AWSBedrockService               SmartIntentParser
             (Nova Micro/Lite)               (keyword/synonym)
                     │
                     ▼
                AI Response
                     │
                     ▼
             TTS (device) ──► VoiceProvider.speak()
```

The app follows a strict **Provider → Service → AWS** layered architecture. No secrets are stored in the Flutter binary. AWS credentials are obtained at runtime via Cognito Identity Pool temporary credentials (Zero-Trust pattern).

