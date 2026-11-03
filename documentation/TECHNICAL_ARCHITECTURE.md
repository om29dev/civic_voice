# Technical Architecture — Civic Voice

## 1. Overall Architecture

Civic Voice follows a **layered Flutter architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter UI Layer                      │
│  Screens → Widgets → CVIBottomNav → GoRouter Shell       │
├─────────────────────────────────────────────────────────┤
│              Provider State Management Layer             │
│  AuthProvider │ VoiceProvider │ AutoFormProvider │ ...   │
├─────────────────────────────────────────────────────────┤
│                    Service Layer                         │
│  AWSBedrockService │ DocumentVaultService │ ReasoningEngine │
├─────────────────────────────────────────────────────────┤
│                    Data / Model Layer                    │
│  UserModel │ CVIDocument │ SmartFormTemplate │ ...       │
├─────────────────────────────────────────────────────────┤
│                  AWS Cloud Backend                       │
│  Cognito │ Bedrock │ S3 │ DynamoDB(AppSync) │ Amplify   │
└─────────────────────────────────────────────────────────┘
```

## 2. System Architecture Diagram

```mermaid
flowchart TD
    User["👤 Citizen User"]

    subgraph FlutterApp["Flutter App (Android)"]
        UI["UI Layer\n(Screens + Widgets)"]
        Router["GoRouter\nAppRouter"]
        Providers["Provider Layer\n18 ChangeNotifiers"]
        Services["Service Layer\nAWS + Local"]
        Models["Model Layer\nDart Classes"]
    end

    subgraph AWS["AWS Cloud (ap-south-1 + us-east-1)"]
        Cognito["Amazon Cognito\nUser Pool + Identity Pool"]
        Bedrock["Amazon Bedrock\nNova Micro + Nova Lite"]
        S3["Amazon S3\nDocument Vault"]
        AppSync["AWS AppSync\nGraphQL API"]
        DDB["Amazon DynamoDB\nDocument Metadata"]
    end

    subgraph DeviceAPIs["Device APIs"]
        STT["speech_to_text\n(On-device STT)"]
        TTS["flutter_tts\n(On-device TTS)"]
        Maps["Google Maps\n(Office Locator)"]
        Notif["flutter_local_notifications"]
    end

    User --> UI
    UI --> Router
    Router --> Providers
    Providers --> Services
    Services --> Models

    Services --> Cognito
    Services --> Bedrock
    Services --> S3
    Services --> AppSync
    AppSync --> DDB

    Providers --> STT
    Providers --> TTS
    UI --> Maps
    Services --> Notif
```

## 3. Authentication Flow

```mermaid
sequenceDiagram
    participant U as User
    participant UI as AuthScreen
    participant AP as AuthProvider
    participant Amp as AWS Amplify
    participant CP as Cognito User Pool
    participant IP as Cognito Identity Pool
    participant R as GoRouter

    U->>UI: Enter email + password
    UI->>AP: loginWithEmail(email, pw)
    AP->>Amp: fetchAuthSession()
    Amp->>CP: Check existing session
    CP-->>Amp: session status
    AP->>Amp: signIn(username, password)
    Amp->>CP: Authenticate
    CP-->>Amp: AuthSignInResult (isSignedIn)
    AP->>Amp: getCurrentUser()
    AP->>Amp: fetchUserAttributes()
    AP->>AP: _fetchUserModel() → UserModel
    AP->>R: notifyListeners()
    R->>R: redirect() → /dashboard
    R-->>U: Navigate to Dashboard

    Note over AP,IP: Background: Cognito Identity Pool\ngrants temporary AWS credentials\nfor Bedrock + S3 access
```

## 4. Voice Assistant Pipeline

```mermaid
sequenceDiagram
    participant U as User
    participant VP as VoiceProvider
    participant CP as ConversationProvider
    participant RE as ReasoningEngine
    participant BS as AWSBedrockService
    participant BD as Amazon Bedrock

    U->>VP: Tap mic button
    VP->>VP: requestMicPermission()
    VP->>VP: _ensureSTTInitialized()
    VP->>VP: stt.listen(localeId, 30s)
    U-->>VP: Speaks query
    VP->>VP: onResult callback → _transcribedText
    VP->>CP: (state: processing)
    CP->>CP: sendMessage(text)
    CP->>RE: generateAIResponse(text, history)
    RE->>RE: SmartIntentParser.parse(text) → DetectionResult
    RE->>RE: _buildSystemInstruction() (scheme data + prompts)
    RE->>BS: chatWithNovaMicro(prompt)
    BS->>BS: SigV4 sign request (Cognito credentials)
    BS->>BD: POST /model/amazon.nova-micro-v1:0/converse
    BD-->>BS: { output: { message: { content: [{ text }] } } }
    BS-->>RE: response text
    RE-->>CP: response string
    CP->>CP: MessageModel.fromBot → session
    CP->>VP: (trigger speak)
    VP->>VP: speak(sanitizedText)
    VP->>VP: FlutterTts.speak()
    VP-->>U: Audio response
```

## 5. Document Scanning & Extraction

```mermaid
sequenceDiagram
    participant U as User
    participant SC as AIDocumentScannerScreen
    participant DVP as DocumentVaultProvider
    participant DVS as DocumentVaultService
    participant DAS as DocumentAIService
    participant BS as AWSBedrockService
    participant S3 as Amazon S3
    participant GQL as AppSync GraphQL

    U->>SC: Pick image (gallery/camera)
    SC->>DVP: addDocument(imageBytes, documentType)
    DVP->>DVS: uploadDocument(imageBytes, documentType)
    DVS->>DVS: _protectedPath() → verify Cognito session
    DVS->>S3: Storage.uploadData(bytes, "protected/{id}/documents/...")
    S3-->>DVS: upload success
    DVS->>DAS: extractFromDocumentBytes(imageBytes, documentType)
    DAS->>DAS: compress if >1.5MB (FlutterImageCompress)
    DAS->>DAS: _buildSystemPrompt() + _buildUserPrompt(type)
    DAS->>BS: extractWithVision(prompt, imageBytes)
    BS->>BS: SigV4 sign (image as base64 in body)
    BS->>BD: POST /model/amazon.nova-lite-v1:0/converse
    BD-->>BS: JSON response with extracted fields
    BS-->>DAS: Map<String, dynamic>
    DAS-->>DVS: extractedData
    DVS->>GQL: mutation createUserDocument (metadata + extractedText)
    GQL-->>DVS: { id, name, category, filePath, extractedText }
    DVS-->>DVP: { success, confidence, extractedData }
    DVP->>DVP: reload documents + extractedData
    DVP-->>SC: notifyListeners() → UI update
```

## 6. Smart Form Auto-Fill Pipeline

```mermaid
sequenceDiagram
    participant U as User
    participant SFS as SmartFormScreen
    participant AFP as AutoFormProvider
    participant FTS as FormTemplateService
    participant DVS as DocumentVaultService
    participant UP as UserProvider
    participant CPP as CitizenProfileProvider
    participant VP as VoiceProvider

    U->>SFS: Navigate to /smart-form/{serviceId}
    SFS->>AFP: loadTemplate(serviceId)
    AFP->>FTS: loadTemplate(serviceId)
    FTS->>FTS: rootBundle.loadString("assets/forms/{id}.json")
    FTS-->>AFP: SmartFormTemplate
    AFP->>DVS: getUserExtractedData()
    DVS-->>AFP: merged extracted data map
    AFP->>AFP: _mapExtractedDataToFields() - by dataKey
    AFP->>UP: autoFillFromProfile(userProvider, citizenProvider)
    UP-->>AFP: profile data (name, age, email, phone, state)
    AFP->>AFP: Fill remaining empty fields from profile
    SFS->>AFP: startAnimatedFill(delayMs: 250)
    AFP->>AFP: Sequential field-by-field animation loop
    AFP-->>SFS: notifyListeners() on each field
    U->>AFP: startVoiceExplanation(langCode, voiceProvider)
    AFP->>VP: setLanguage(langCode)
    AFP->>VP: speakAndWait("This is {formName} form")
    AFP->>VP: speakAndWait(introExplanation)
    AFP->>VP: speakAndWait("You need: {requiredFields}")
    loop Each field
        AFP->>VP: speakAndWait(field.voiceExplanation)
    end
    U->>SFS: Tap "Review Form"
    SFS-->>U: Navigate to FormReviewScreen
    U->>SFS: Tap "Proceed to Submit"
    SFS-->>U: Navigate to GuidedSubmissionScreen
    U->>SFS: Tap "Open Portal"
    SFS-->>U: Navigate to SmartBrowserScreen (WebView)
```

## 7. Government Portal Submission Flow

```mermaid
flowchart TD
    A["User taps 'Submit on Portal'"] --> B["GuidedSubmissionScreen\n(Step-by-step instructions)"]
    B --> C["User reads instructions\nCopies field values to clipboard"]
    C --> D["SmartBrowserScreen\n(WebView with official URL)"]
    D --> E["User manually pastes values\ninto government web form"]
    E --> F["User submits on portal\n(standard web flow)"]
    F --> G["Portal confirmation"]

    note1["⚠️ No automatic form\ninjection or submission.\nThis is guided copy-assist only."]
    D --- note1
```

## 8. Application Tracking Flow

```mermaid
flowchart TD
    A["ApplicationTrackerProvider constructor"] --> B["_fetchMockTrackerData()"]
    B --> C["await Future.delayed(1 second)"]
    C --> D["Hardcoded List of AppTrackerModel\n(3 demo applications)"]
    D --> E["notifyListeners()"]
    E --> F["ApplicationDashboardScreen renders list"]

    note["🔷 MOCK: No real portal API.\nData is hardcoded demo data."]
    B --- note
```

## 9. Scheme Recommendation Flow

```mermaid
flowchart TD
    A["User sends query in VoiceScreen"] --> B["ConversationProvider.sendMessage()"]
    B --> C["ReasoningEngine.generateAIResponse()"]
    C --> D["SmartIntentParser.parse(text, lang)"]
    D --> E{Intent detected?}
    E -->|Scheme found| F["Load SchemeKnowledgeBase data"]
    E -->|Ambiguous| G["Ask clarification\n'Did you mean X or Y?'"]
    E -->|Discovery| H["General guidance response"]
    F --> I["Build Llama-format prompt\nwith scheme details + user query"]
    I --> J["AWSBedrockService.chatWithNovaMicro()"]
    J --> K["Amazon Bedrock Nova Micro\n(us-east-1)"]
    K --> L["AI response with scheme info,\neligibility, documents needed"]
    L --> M["Display in chat + TTS speak"]
```

## 10. Provider Architecture Map

```mermaid
graph TD
    MP["MultiProvider root (main.dart)"]
    
    MP --> AuthP["AuthProvider\n(Cognito session)"]
    MP --> VP["VoiceProvider\n(STT + TTS)"]
    MP --> ConvP["ConversationProvider\n(Chat + AI)"]
    MP --> LP["LanguageProvider\n(en/hi/mr/ta)"]
    MP --> UP["UserProvider\n(user profile data)"]
    MP --> SP["ServicesProvider\n(gov service catalog)"]
    MP --> DVP["DocumentVaultProvider\n(S3 + DynamoDB)"]
    MP --> AFP["AutoFormProvider\n(form auto-fill)"]
    MP --> ATP["ApplicationTrackerProvider\n(mock apps)"]
    MP --> SDP["SchemeDiscoveryProvider\n(mock schemes)"]
    MP --> ECP["EligibilityCheckerProvider\n(mock eligibility)"]
    MP --> CPP["CitizenProfileProvider\n(detailed citizen data)"]
    MP --> DSP["DocumentScannerProvider\n(scanner state)"]
    MP --> NP["NotificationProvider\n(local notifications)"]
    MP --> AP["AnalyticsProvider\n(local analytics)"]
    MP --> AcP["AccessibilityProvider\n(text scale + color)"]
    MP --> OGP["OfflineGuidanceProvider\n(offline content)"]
    MP --> CompP["ComplaintProvider\n(voice complaints)"]
    
    ConvP --> VP
    AFP --> DVP
    AFP --> UP
    AFP --> CPP
    AFP --> VP
    AuthP --> LP
```

## 11. Routing Architecture

**Router**: GoRouter ^17.1.0  
**Shell**: `_AppShell` wraps Dashboard/Services/Recommendations/Profile tabs with `CVIBottomNav`

### Route Map
```
/ (splash)
/onboarding
/auth
/dashboard          ← Shell tab 0
/services           ← Shell tab 1
/recommendations    ← Shell tab 3
/profile            ← Shell tab 4
/voice              ← push (tab 2 is shortcut)
/service/:id
/service/:id/eligibility
/notifications
/my-applications
/documents
/document-vault
/auto-fill/:serviceId
/smart-form/:serviceId    ← NEW auto_form module
/form-review
/guided-submit
/smart-browser
/office-locator
/voice-complaint
/document-scanner
/scheme-discovery
/app-tracker
/offline-guidance
/citizen-profile
/settings
/profile-edit
```

### Auth Redirect Logic (synchronous)
1. If splash not shown → force `/`
2. Not authenticated: on auth/onboard → stay; else → `/auth`
3. Not seen onboarding → `/onboarding`
4. Authenticated on auth/splash/onboard → `/dashboard`

