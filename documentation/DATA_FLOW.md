# Data Flow — Civic Voice

## 1. App Startup Flow

```
main() → runZonedGuarded()
  ├── WidgetsFlutterBinding.ensureInitialized()
  ├── [background] CsvSchemeService.init()   — loads CSV scheme data
  ├── [background] PromptLoader.loadPrompts() — loads ai_prompts.md
  ├── await AwsAmplifyService.initialize()
  │     ├── Amplify.addPlugins([AmplifyAuthCognito, AmplifyAPI, AmplifyStorageS3])
  │     └── Amplify.configure(amplifyconfig)
  ├── await NotificationService().init()
  ├── await SharedPreferences.getInstance()
  └── runApp(MultiProvider(..., child: CVIApp()))
        └── AuthProvider()._init()
              ├── Amplify.Auth.fetchAuthSession()
              ├── if signedIn → getCurrentUser() → fetchUserAttributes() → UserModel
              ├── if not → _tryRestoreGuestSession()
              └── _isLoading = false → notifyListeners()
                    └── GoRouter.redirect() triggers
                          ├── if onboarded + authenticated → /dashboard
                          ├── if not onboarded → /onboarding
                          └── else → /auth
```

## 2. User Login Data Flow

```
AuthScreen (UI)
  → user enters email + password
  → AuthProvider.loginWithEmail(email, password)
    → Amplify.Auth.fetchAuthSession() — check existing
    → if exists → Amplify.Auth.signOut(globalSignOut: true)
    → Amplify.Auth.signIn(username: email, password: pw)
    → AuthSignInResult.isSignedIn == true
      → Amplify.Auth.getCurrentUser() → AuthUser { userId, username }
      → Amplify.Auth.fetchUserAttributes() → [name, email, phone]
      → SharedPreferences.getString('cvi_lang_{userId}') → langCode
      → _currentUser = UserModel(id, name, email, mobile, language)
    → notifyListeners()
    → GoRouter.redirect() → /dashboard
```

## 3. Voice Chat Data Flow

```
VoiceScreen (UI)
  → tap AnimatedMicButton
  → VoiceProvider.startListening(localeId: 'hi-IN')
    → Permission.microphone.request()
    → stt.initialize(onError, onStatus)
    → _state = VoiceState.listening → notifyListeners()
    → stt.listen(
        onResult: (result) {
          if (final) _transcribedText = words; _state = processing
          else _partialText = words
          notifyListeners()
        },
        onSoundLevelChange: (level) { if |Δlevel| > 2 → notifyListeners() }
        localeId: 'hi-IN', listenFor: 30s, pauseFor: 3s
      )
  
  → user stops speaking (3s pause)
  → _state = VoiceState.processing
  → VoiceScreen observes processing state → sendMessage()
  → ConversationProvider.sendMessage(transcribedText)
    → MessageModel.fromUser(text) added to session
    → _isLoading = true; notifyListeners()
    → await Future.delayed(600ms)  ← natural feel
    → ReasoningEngine(languageCode: 'hi')
      → SmartIntentParser.parse(text, 'hi')
        → match against schemeSynonyms (pension, ration, kisan...)
        → match against intentKeywords[hi] (पात्र, दस्तावेज, आवेदन...)
        → DetectionResult { intent, schemeId, confidence }
      → _buildSystemInstruction()
        → SchemeKnowledgeBase.schemes → summaries
        → PromptLoader.getPrompt('general_assistant', {...})
      → Build Llama-format prompt string
      → AWSBedrockService.chatWithNovaMicro(prompt)
        → CognitoAuthSession.credentialsResult.value → temp creds
        → AWSSigV4Signer.sign(POST /model/amazon.nova-micro-v1:0/converse)
        → AWSHttpClient.send(signedRequest)
        → Parse response: output.message.content[].text
        → Check/update _responseCache (SHA-256 key)
        → return text
    → MessageModel.fromBot(text) added to session
    → _isLoading = false; notifyListeners()
  → VoiceScreen observes new bot message
  → VoiceProvider.speak(responseText)
    → _sanitizeForSpeech() (strip markdown)
    → FlutterTts.speak(cleanText)
    → _state = VoiceState.speaking → notifyListeners()
    → tts.setCompletionHandler → _state = idle
```

## 4. Document Upload & Extraction Data Flow

```
DocumentVaultScreen / AIDocumentScannerScreen
  → ImagePicker.pickImage(gallery/camera)
  → imageBytes = File.readAsBytes()
  → DocumentVaultProvider.addDocument(imageBytes, documentType)
    → _isExtracting = true; _extractionStatus = 'AI is reading...'
    → DocumentVaultService.uploadDocument(imageBytes, documentType)
      
      [Step 1: S3 Upload]
      → _protectedPath('documents/{name}_{ts}.jpg')
        → Amplify.Auth.fetchAuthSession() as CognitoAuthSession
        → identityId = session.identityIdResult.value
        → return 'protected/{identityId}/documents/{name}_{ts}.jpg'
      → Amplify.Storage.uploadData(
          StorageDataPayload.bytes(imageBytes, contentType: 'image/jpeg'),
          StoragePath.fromString(securePath)
        ).result  → S3 object created
      
      [Step 2: AI Extraction]
      → DocumentAIService.extractFromDocumentBytes(imageBytes, documentType)
        → if size > 1.5MB → FlutterImageCompress.compressWithList(quality:85)
        → _buildSystemPrompt()  — OCR rules prompt
        → _buildUserPrompt(documentType) — type-specific JSON schema
        → AWSBedrockService.extractWithVision(
            systemPrompt, userPrompt, imageBytes, mimeType: 'image/jpeg'
          )
          → encode image as base64
          → SigV4 POST /model/amazon.nova-lite-v1:0/converse
          → Body: { system, messages: [{ content: [{ image: {bytes} }, { text }] }] }
          → Parse JSON from response text
          → return Map<String, dynamic>
        → return extractedData
      
      [Step 3: DynamoDB Metadata]
      → Amplify.API.mutate(GraphQLRequest(createUserDocument mutation, {
          name, category: documentType, size: 'X KB',
          uploadDate: now().toIso8601String(), status: 'Verified',
          filePath: storageKey,
          isVerified: confidence > 0.6,
          extractedText: json.encode(extractedData)
        })).response
      
      → return { success, confidence, extractedData, filePath }
    
    → reload: DocumentVaultService.getUserDocuments() + getUserExtractedData()
    → _isExtracting = false; notifyListeners()
```

## 5. Form Auto-Fill Data Flow

```
ServiceDetailScreenV2
  → user taps "Auto-Fill Form"
  → context.push('/smart-form/{serviceId}', extra: service)

SmartFormScreen.initState()
  → AutoFormProvider.loadTemplate(serviceId)
    → FormTemplateService.loadTemplate(serviceId)
      → check _cache[serviceId]
      → rootBundle.loadString('assets/forms/{serviceId}.json')
      → SmartFormTemplate.fromJson(jsonMap)
      → _cache[serviceId] = template
    → _totalCount = template.fields.length
    → _filledValues = { for each field: null }
    → notifyListeners()
  
  → AutoFormProvider.autoFillFromVault()
    → DocumentVaultService.getUserExtractedData()
      → getUserDocuments() → list of docs with extractedText
      → map to CVIDocument list
      → DocumentAIService.mergeExtractedData(cviDocs)
        → for each field key: pick first non-null value across docs
        → return ExtractedUserData
      → ExtractedUserData.toJson() → Map<String, dynamic>
    → _mapExtractedDataToFields(userData)
      → for each SmartFormField in template:
          val = userData[field.dataKey]  ← match by dataKey
          if val != null:
            format if date field
            _filledValues[field.id] = val
            _dataSources[field.id] = _sourceLabels[field.sourceDocument]
          else: _emptyFieldIds.add(field.id)
    → notifyListeners()
  
  → AutoFormProvider.autoFillFromProfile(userProvider, citizenProvider)
    → build profileData from UserModel + CitizenProfileModel
    → for each empty field: fill from profileData[field.dataKey]
    → _dataSources[field.id] = 'Your Profile'
    → notifyListeners()
  
  → AutoFormProvider.startAnimatedFill(delayMs: 250)
    → save values; clear all → notifyListeners()
    → for i in 0..fields.length:
        _animatedFieldIndex = i
        restore _filledValues[field.id]
        notifyListeners()  ← UI animates field highlight
        await Future.delayed(250ms)
    → restore all; _isAnimating = false; notifyListeners()
  
  [Optional: Voice Explanation]
  → AutoFormProvider.startVoiceExplanation(langCode, voiceProvider)
    → setLanguage(langCode)
    → speakAndWait(intro)
    → speakAndWait(customIntro from template)
    → speakAndWait(required fields list)
    → for each field: speakAndWait(field.voiceExplanation[langCode])
  
  [User manually edits]
  → AutoFormProvider.updateField(fieldId, value)
    → _filledValues[fieldId] = value
    → _dataSources[fieldId] = 'Manual Input'
    → _recalculateStats()
  
  [Review]
  → context.push('/form-review', extra: service)
  → FormReviewScreen reads from AutoFormProvider.filledValues
  
  [Submit]
  → context.push('/guided-submit', extra: {
      url: template.officialUrl,
      title: template.formTitle[langCode],
      formData: AutoFormProvider.getFilledDataByDataKey(),
      submitSteps: template.submitSteps,
      portalName: template.portalName
    })
  → GuidedSubmissionScreen: user follows steps, copies values
  → context.push('/smart-browser', extra: { url, formData, ... })
  → SmartBrowserScreen: WebView loads portal
  → User manually fills and submits on portal
```

## 6. Language Switch Data Flow

```
User selects language (LanguageProvider or AuthProvider)
  → LanguageProvider.setLanguage('hi')
    → _currentLocale = Locale('hi', 'IN')
    → SharedPreferences.setString('cvi_language', 'hi')
    → notifyListeners()
  → CVIApp re-reads locale → MaterialApp locale changes
  → TText widget re-renders with new language
  → VoiceProvider.setLanguage('hi') → FlutterTts.setLanguage('hi-IN')
  → ConversationProvider.setLanguage('hi')
  → AutoFormProvider (via template): getTitle('hi'), getLabel('hi'), getExplanation('hi')
```

## 7. Scheme Discovery Data Flow

```
SchemeDiscoveryScreen
  → SchemeDiscoveryProvider (loaded at startup)
    → _loadMockSchemes() [🔷 MOCK]
      → await 800ms delay
      → _allSchemes = [5 hardcoded SchemeDiscoveryModel]
      → _filteredSchemes = _allSchemes
  → user types in search box
  → SchemeDiscoveryProvider.searchSchemes(query)
    → filter by title/description contains query
    → filter by current category
    → notifyListeners()
  → user taps category chip
  → SchemeDiscoveryProvider.filterByCategory(category)
    → filter _allSchemes by category
    → notifyListeners()
```

## 8. Application Tracker Data Flow

```
ApplicationDashboardScreen
  → ApplicationTrackerProvider (loaded at startup)
    → _fetchMockTrackerData() [🔷 MOCK]
      → await 1 second delay
      → _applications = [3 hardcoded AppTrackerModel]
      → notifyListeners()
  → MyApplicationsScreen reads _applications list
  → No real government portal API calls
  → refreshData() → same mock fetch
```

