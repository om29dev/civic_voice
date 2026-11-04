import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/profile_constants.dart';
import '../../models/scheme_discovery_model.dart';
import '../../models/service_model.dart';
import 'aws_amplify_service.dart';

class DynamoDbSchemeDiscoveryService {
  static const String _cachePrefsKey = 'cvi_dynamodb_schemes_cache_v2';
  static List<SchemeDiscoveryModel> _cachedSchemes = [];
  static int _totalDynamoDbItemsCount = 0;

  static List<SchemeDiscoveryModel> get cachedSchemes => _cachedSchemes;
  static int get totalDynamoDbItemsCount => _totalDynamoDbItemsCount;

  static const String _listSchemesQuery = '''
    query ListCivicSchemes(\$limit: Int, \$nextToken: String) {
      listCivicSchemes(limit: \$limit, nextToken: \$nextToken) {
        items {
          id
          title
          shortTitle
          description
          category
          level
          schemeFor
          beneficiaryState
          nodalMinistry
          tags
          eligibilityCriteria
          applicationProcess
          closeDate
        }
        nextToken
      }
    }
  ''';

  static Future<List<SchemeDiscoveryModel>> loadSchemes({
    bool forceReload = false,
  }) async {
    if (!forceReload && _cachedSchemes.isNotEmpty) {
      return _cachedSchemes;
    }

    final mergedByTitleKey = <String, SchemeDiscoveryModel>{};

    // Seed flagship national and state schemes as baseline
    for (final flagship in _flagshipNationalSchemes()) {
      final key = _normalizeKey(flagship.title);
      mergedByTitleKey[key] = flagship;
    }

    // Load cached DynamoDB schemes from SharedPreferences if available
    if (!forceReload) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final rawCache = prefs.getString(_cachePrefsKey);
        if (rawCache != null && rawCache.isNotEmpty) {
          final decodedList = json.decode(rawCache) as List<dynamic>;
          for (final item in decodedList) {
            if (item is Map<String, dynamic>) {
              final model = SchemeDiscoveryModel.fromJson(item);
              if (model.title.isNotEmpty) {
                mergedByTitleKey[_normalizeKey(model.title)] = model;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('DynamoDbSchemeDiscoveryService cache read note: $e');
      }
    }

    // Query live schemes from AWS AppSync / DynamoDB with pagination
    if (AwsAmplifyService.isInitialized) {
      try {
        String? nextToken;
        int pagesFetched = 0;
        int rawItemsFetched = 0;
        const int maxPages = 40;

        do {
          final variables = <String, dynamic>{
            'limit': 1000,
            if (nextToken != null) 'nextToken': nextToken,
          };

          final operation = Amplify.API.query(
            request: GraphQLRequest<String>(
              document: _listSchemesQuery,
              variables: variables,
            ),
          );

          final response = await operation.response;
          if (response.data == null || response.data!.isEmpty) break;

          final decoded = json.decode(response.data!) as Map<String, dynamic>;
          final listData = decoded['listCivicSchemes'];
          if (listData == null || listData['items'] == null) break;

          final items = listData['items'] as List<dynamic>;
          for (final rawItem in items) {
            if (rawItem is! Map<String, dynamic>) continue;
            rawItemsFetched++;
            final enriched = enrichDynamoItem(rawItem);
            if (enriched == null) continue;

            final key = _normalizeKey(enriched.title);
            final existing = mergedByTitleKey[key];
            if (existing == null) {
              mergedByTitleKey[key] = enriched;
            } else {
              // Merge tags and eligibility criteria across multi-row tag items
              final mergedTags = <String>{
                ...existing.tags,
                ...enriched.tags,
              }.toList();
              mergedByTitleKey[key] = SchemeDiscoveryModel(
                id: existing.id,
                title: existing.title,
                shortTitle: existing.shortTitle.isNotEmpty
                    ? existing.shortTitle
                    : enriched.shortTitle,
                description: existing.description.length >=
                        enriched.description.length
                    ? existing.description
                    : enriched.description,
                benefits: existing.benefits.isNotEmpty
                    ? existing.benefits
                    : enriched.benefits,
                category: existing.category,
                level: existing.level,
                schemeFor: existing.schemeFor,
                beneficiaryState: existing.beneficiaryState != 'All India'
                    ? existing.beneficiaryState
                    : enriched.beneficiaryState,
                nodalMinistry: existing.nodalMinistry.isNotEmpty
                    ? existing.nodalMinistry
                    : enriched.nodalMinistry,
                tags: mergedTags,
                eligibilityCriteria: existing.eligibilityCriteria.isNotEmpty
                    ? existing.eligibilityCriteria
                    : enriched.eligibilityCriteria,
                requiredDocuments: existing.requiredDocuments.isNotEmpty
                    ? existing.requiredDocuments
                    : enriched.requiredDocuments,
                applicationProcess: existing.applicationProcess.isNotEmpty
                    ? existing.applicationProcess
                    : enriched.applicationProcess,
                minAge: existing.minAge ?? enriched.minAge,
                maxAge: existing.maxAge ?? enriched.maxAge,
                maxIncome: existing.maxIncome ?? enriched.maxIncome,
                targetGenders: existing.targetGenders.isNotEmpty
                    ? existing.targetGenders
                    : enriched.targetGenders,
                targetCastes: existing.targetCastes.isNotEmpty
                    ? existing.targetCastes
                    : enriched.targetCastes,
                targetOccupations: existing.targetOccupations.isNotEmpty
                    ? existing.targetOccupations
                    : enriched.targetOccupations,
                forDisabledOnly:
                    existing.forDisabledOnly || enriched.forDisabledOnly,
              );
            }
          }

          nextToken = listData['nextToken']?.toString();
          pagesFetched++;
        } while (nextToken != null &&
            nextToken.isNotEmpty &&
            pagesFetched < maxPages);

        if (rawItemsFetched > 0) {
          _totalDynamoDbItemsCount = rawItemsFetched;
          await _persistCache(mergedByTitleKey.values.toList());
        }
      } catch (e) {
        debugPrint('DynamoDbSchemeDiscoveryService query note: $e');
      }
    }

    _cachedSchemes = mergedByTitleKey.values.toList();
    debugPrint(
      'DynamoDbSchemeDiscoveryService: Loaded ${_cachedSchemes.length} unique schemes (DynamoDB raw items: $_totalDynamoDbItemsCount)',
    );
    return _cachedSchemes;
  }

  static Future<List<ServiceModel>> loadServiceModels({
    bool forceReload = false,
  }) async {
    final schemes = await loadSchemes(forceReload: forceReload);
    return schemes.map((s) => s.toServiceModel()).toList();
  }

  static List<SchemeDiscoveryModel> findDiscoveryMatches({
    int? age,
    double? income,
    String? state,
    String? gender,
    String? casteCategory,
    String? occupation,
    bool? isDisabled,
    int limit = 150,
  }) {
    if (_cachedSchemes.isEmpty) {
      _cachedSchemes = _flagshipNationalSchemes();
    }

    final normState =
        state != null ? ProfileConstants.normalizeState(state) : null;
    final normGender =
        gender != null ? ProfileConstants.normalizeGender(gender) : null;
    final normCaste = casteCategory != null
        ? ProfileConstants.normalizeCasteCategory(casteCategory)
        : null;
    final normOcc = occupation != null
        ? ProfileConstants.normalizeOccupation(occupation)
        : null;

    final matched = _cachedSchemes.where((scheme) {
      return scheme.matchesDemographics(
        state: normState,
        age: age,
        income: income,
        gender: normGender,
        casteCategory: normCaste,
        occupation: normOcc,
        isDisabled: isDisabled,
      );
    }).toList();

    matched.sort((a, b) {
      final scoreA = a.computeRelevanceScore(
        state: normState,
        age: age,
        income: income,
        gender: normGender,
        casteCategory: normCaste,
        occupation: normOcc,
        isDisabled: isDisabled,
      );
      final scoreB = b.computeRelevanceScore(
        state: normState,
        age: age,
        income: income,
        gender: normGender,
        casteCategory: normCaste,
        occupation: normOcc,
        isDisabled: isDisabled,
      );
      return scoreB.compareTo(scoreA);
    });

    return matched.take(limit).toList();
  }

  static Future<void> _persistCache(List<SchemeDiscoveryModel> schemes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toSave = schemes.take(1500).map((s) => s.toJson()).toList();
      await prefs.setString(_cachePrefsKey, json.encode(toSave));
    } catch (e) {
      debugPrint('DynamoDbSchemeDiscoveryService cache write note: $e');
    }
  }

  static String _normalizeKey(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  static SchemeDiscoveryModel? enrichDynamoItem(Map<String, dynamic> item) {
    final id = item['id']?.toString().trim() ?? '';
    final title = item['title']?.toString().trim() ?? '';
    if (id.isEmpty || title.isEmpty) return null;

    final shortTitle = item['shortTitle']?.toString().trim() ?? '';
    final description = item['description']?.toString().trim() ?? '';
    final rawCategory = item['category']?.toString().trim() ?? 'General';
    final category = _normalizeCategory(rawCategory);
    final level = item['level']?.toString().trim() ?? 'Central';
    final schemeFor = item['schemeFor']?.toString().trim() ?? 'Individual';
    final rawState = item['beneficiaryState']?.toString().trim() ?? '';
    final beneficiaryState =
        (rawState.isEmpty ||
                rawState.toLowerCase() == 'all' ||
                rawState.toLowerCase() == 'all india' ||
                level.toLowerCase() == 'central')
            ? 'All India'
            : ProfileConstants.normalizeState(rawState);
    final nodalMinistry = item['nodalMinistry']?.toString().trim() ?? '';

    final tags = (item['tags'] as List<dynamic>?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];

    final corpus =
        '$title $description $category $schemeFor ${tags.join(' ')}'
            .toLowerCase();

    final ageBounds = _inferAgeBounds(corpus);
    final maxIncome = _inferMaxIncome(corpus);
    final targetGenders = _inferGenders(corpus);
    final targetCastes = _inferCastes(corpus);
    final targetOccupations = _inferOccupations(corpus, category);
    final forDisabledOnly = _inferDisabledOnly(corpus);

    final rawEligibility = (item['eligibilityCriteria'] as List<dynamic>?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];

    final eligibilityCriteria = rawEligibility.isNotEmpty
        ? rawEligibility
        : _buildEligibilityBullets(
            beneficiaryState: beneficiaryState,
            level: level,
            minAge: ageBounds.$1,
            maxAge: ageBounds.$2,
            maxIncome: maxIncome,
            genders: targetGenders,
            castes: targetCastes,
            occupations: targetOccupations,
            forDisabled: forDisabledOnly,
          );

    final rawAppProcess = item['applicationProcess']?.toString().trim() ?? '';
    final applicationProcess = rawAppProcess.isNotEmpty
        ? rawAppProcess
        : 'Step 1: Visit the official MyScheme portal (myscheme.gov.in) or respective state portal.\n'
            'Step 2: Complete Aadhaar e-KYC and fill the online application form for $title.\n'
            'Step 3: Upload required supporting documents and submit for verification.';

    final requiredDocs = _inferDocuments(
      category: category,
      castes: targetCastes,
      occupations: targetOccupations,
      forDisabled: forDisabledOnly,
      maxIncome: maxIncome,
    );

    return SchemeDiscoveryModel(
      id: id,
      title: title,
      shortTitle: shortTitle,
      description: description,
      benefits: description,
      category: category,
      level: level,
      schemeFor: schemeFor,
      beneficiaryState: beneficiaryState,
      nodalMinistry: nodalMinistry,
      tags: tags,
      eligibilityCriteria: eligibilityCriteria,
      requiredDocuments: requiredDocs,
      applicationProcess: applicationProcess,
      minAge: ageBounds.$1,
      maxAge: ageBounds.$2,
      maxIncome: maxIncome,
      targetGenders: targetGenders,
      targetCastes: targetCastes,
      targetOccupations: targetOccupations,
      forDisabledOnly: forDisabledOnly,
    );
  }

  static String _normalizeCategory(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('agricultur') || lower.contains('rural')) {
      return 'Agriculture, Rural & Environment';
    }
    if (lower.contains('educat') || lower.contains('learning')) {
      return 'Education & Learning';
    }
    if (lower.contains('health') || lower.contains('medical')) {
      return 'Health & Wellness';
    }
    if (lower.contains('women') || lower.contains('child')) {
      return 'Women and Child';
    }
    if (lower.contains('business') || lower.contains('entrepreneur')) {
      return 'Business & Entrepreneurship';
    }
    if (lower.contains('skill') || lower.contains('employ')) {
      return 'Skills & Employment';
    }
    if (lower.contains('hous') || lower.contains('shelter')) {
      return 'Housing & Shelter';
    }
    if (lower.contains('bank') ||
        lower.contains('financ') ||
        lower.contains('insur')) {
      return 'Banking, Financial Services and Insurance';
    }
    if (lower.contains('social welfare') || lower.contains('empowerment')) {
      return 'Social Welfare & Empowerment';
    }
    return raw.isEmpty ? 'Social Welfare & Empowerment' : raw;
  }

  static (int?, int?) _inferAgeBounds(String corpus) {
    final rangeMatch = RegExp(
      r'age\s*(?:group|between|limit|of)?\s*(\d{1,2})\s*(?:to|-|and)\s*(\d{1,2})\s*years',
    ).firstMatch(corpus);
    if (rangeMatch != null) {
      final minA = int.tryParse(rangeMatch.group(1)!);
      final maxA = int.tryParse(rangeMatch.group(2)!);
      if (minA != null && maxA != null && minA < maxA) {
        return (minA, maxA);
      }
    }

    if (corpus.contains('senior citizen') ||
        corpus.contains('old age pension') ||
        corpus.contains('vridha') ||
        corpus.contains('above 60 years') ||
        corpus.contains('60 years and above')) {
      return (60, 100);
    }
    if (corpus.contains('girl child') ||
        corpus.contains('balika') ||
        corpus.contains('kanya') ||
        corpus.contains('pre-matric')) {
      return (0, 21);
    }
    if (corpus.contains('post-matric') ||
        corpus.contains('scholarship') ||
        corpus.contains('fellowship') ||
        corpus.contains('higher education') ||
        corpus.contains('college student')) {
      return (14, 35);
    }
    if (corpus.contains('youth') || corpus.contains('yuva')) {
      return (15, 35);
    }
    if (corpus.contains('maternity') ||
        corpus.contains('pregnant') ||
        corpus.contains('lactating') ||
        corpus.contains('matru')) {
      return (18, 45);
    }
    if (corpus.contains('widow') ||
        corpus.contains('vidhwa') ||
        corpus.contains('farmer') ||
        corpus.contains('kisan') ||
        corpus.contains('entrepreneur') ||
        corpus.contains('msme')) {
      return (18, 75);
    }
    return (null, null);
  }

  static double? _inferMaxIncome(String corpus) {
    if (corpus.contains('bpl') ||
        corpus.contains('below poverty line') ||
        corpus.contains('antyodaya') ||
        corpus.contains('destitute')) {
      return 150000;
    }
    if (corpus.contains('ews') ||
        corpus.contains('economically weaker') ||
        corpus.contains('low income')) {
      return 300000;
    }
    if (corpus.contains('post-matric') || corpus.contains('scholarship')) {
      return 250000;
    }
    return null;
  }

  static List<String> _inferGenders(String corpus) {
    final isFemaleSpecific = corpus.contains('women') ||
        corpus.contains('woman') ||
        corpus.contains('girl') ||
        corpus.contains('mahila') ||
        corpus.contains('widow') ||
        corpus.contains('vidhwa') ||
        corpus.contains('maternity') ||
        corpus.contains('pregnant') ||
        corpus.contains('lactating') ||
        corpus.contains('kanya') ||
        corpus.contains('balika') ||
        corpus.contains('sukanya') ||
        corpus.contains('ladli') ||
        corpus.contains('stree');

    if (isFemaleSpecific && !corpus.contains('men and women')) {
      return const ['Female'];
    }
    if (corpus.contains('transgender') || corpus.contains('kinnar')) {
      return const ['Other'];
    }
    return const [];
  }

  static List<String> _inferCastes(String corpus) {
    final castes = <String>{};
    if (RegExp(r'\b(scheduled caste|sc\b|sc/st|dalit|harijan|adi dravidar)')
        .hasMatch(corpus)) {
      castes.add('SC');
    }
    if (RegExp(r'\b(scheduled tribe|st\b|sc/st|tribal|adivasi|vanbandhu)')
        .hasMatch(corpus)) {
      castes.add('ST');
    }
    if (RegExp(r'\b(other backward|obc\b|backward class|bc/mbc|ebc\b|sebc\b)')
        .hasMatch(corpus)) {
      castes.add('OBC');
    }
    if (RegExp(r'\b(economically weaker|ews\b)').hasMatch(corpus)) {
      castes.add('EWS');
    }
    return castes.toList();
  }

  static List<String> _inferOccupations(String corpus, String category) {
    final occupations = <String>{};
    final catLower = category.toLowerCase();

    if (catLower.contains('agricultur') ||
        RegExp(
          r'\b(farmer|farmers|kisan|krishi|cultivator|horticulture|fisherman|fisheries|dairy|cattle|poultry|sericulture)\b',
        ).hasMatch(corpus)) {
      occupations.add('Farmer');
    }

    if (catLower.contains('education') ||
        RegExp(
          r'\b(student|students|scholarship|fellowship|school|college|matric|university|phd|researcher|hostel)\b',
        ).hasMatch(corpus)) {
      occupations.add('Student');
    }

    if (catLower.contains('business') ||
        RegExp(
          r'\b(entrepreneur|msme|startup|self-employed|self employed|artisan|weaver|handloom|khadi|vendor|svanidhi|mudra|trader|shopkeeper)\b',
        ).hasMatch(corpus)) {
      occupations.add('Self-Employed / Business');
    }

    if (RegExp(
      r'\b(unemployed|jobless|job seeker|rozgar|employment allowance|yuva nidhi|berojgari)\b',
    ).hasMatch(corpus)) {
      occupations.add('Unemployed');
    }

    if (RegExp(
      r'\b(construction worker|building worker|labour|laborer|shramik|mgnrega|unorganized worker|factory worker|epfo)\b',
    ).hasMatch(corpus)) {
      occupations.add('Salaried / Private');
    }

    if (RegExp(
      r'\b(senior citizen|old age pension|retired|pensioner|vridha)\b',
    ).hasMatch(corpus)) {
      occupations.add('Retired');
    }

    if (RegExp(r'\b(homemaker|housewife|griha lakshmi)\b').hasMatch(corpus)) {
      occupations.add('Homemaker');
    }

    return occupations.toList();
  }

  static bool _inferDisabledOnly(String corpus) {
    return RegExp(
      r'\b(disabled|disability|differently abled|divyang|divyangjan|handicapped|blind|locomotor|cerebral palsy|autism)\b',
    ).hasMatch(corpus);
  }

  static List<String> _buildEligibilityBullets({
    required String beneficiaryState,
    required String level,
    int? minAge,
    int? maxAge,
    double? maxIncome,
    required List<String> genders,
    required List<String> castes,
    required List<String> occupations,
    required bool forDisabled,
  }) {
    final bullets = <String>[];
    if (level.toLowerCase() == 'central' || beneficiaryState == 'All India') {
      bullets.add('Coverage: All India (Central Scheme)');
    } else {
      bullets.add('Resident of $beneficiaryState');
    }

    if (minAge != null && maxAge != null) {
      bullets.add('Age Group: $minAge to $maxAge years');
    } else if (minAge != null) {
      bullets.add('Minimum Age: $minAge+ years');
    }

    if (genders.isNotEmpty) {
      bullets.add('Eligible Gender: ${genders.join(", ")}');
    }

    if (castes.isNotEmpty) {
      bullets.add('Social Category: ${castes.join(", ")}');
    }

    if (occupations.isNotEmpty) {
      bullets.add('Target Group: ${occupations.join(", ")}');
    }

    if (maxIncome != null) {
      bullets.add(
        'Annual Family Income up to INR ${(maxIncome / 100000).toStringAsFixed(1)} Lakh',
      );
    }

    if (forDisabled) {
      bullets.add('Person with Benchmark Disability (PwD / Divyangjan)');
    }

    return bullets;
  }

  static List<String> _inferDocuments({
    required String category,
    required List<String> castes,
    required List<String> occupations,
    required bool forDisabled,
    double? maxIncome,
  }) {
    final docs = <String>[
      'Aadhaar Card',
      'Bank Account Passbook (Aadhaar-linked for DBT)',
    ];
    if (castes.isNotEmpty) {
      docs.add('Caste / Community Certificate');
    }
    if (maxIncome != null) {
      docs.add('Income Certificate / Ration Card');
    }
    if (occupations.contains('Farmer')) {
      docs.add('Land Holding / 7/12 Extract / Kisan Credit Card');
    }
    if (occupations.contains('Student')) {
      docs.add('Previous Academic Marksheet & Bonafide Certificate');
    }
    if (occupations.contains('Self-Employed / Business')) {
      docs.add('Udyam Registration / Business Proof');
    }
    if (forDisabled) {
      docs.add('UDID / Disability Certificate');
    }
    return docs;
  }

  static Future<bool> saveSchemeToDynamoDb(SchemeDiscoveryModel model) async {
    if (!AwsAmplifyService.isInitialized) return false;

    try {
      const mutation = '''
        mutation CreateCivicScheme(\$input: CreateCivicSchemeInput!) {
          createCivicScheme(input: \$input) {
            id
            title
            category
          }
        }
      ''';

      final input = {
        'id': model.id,
        'title': model.title,
        'shortTitle': model.shortTitle,
        'description': model.description,
        'category': model.category,
        'level': model.level,
        'schemeFor': model.schemeFor,
        'beneficiaryState': model.beneficiaryState,
        'nodalMinistry': model.nodalMinistry,
        'tags': model.tags,
        'eligibilityCriteria': model.eligibilityCriteria,
        'applicationProcess': model.applicationProcess,
      };

      final operation = Amplify.API.mutate(
        request: GraphQLRequest<String>(
          document: mutation,
          variables: {'input': input},
        ),
      );

      final response = await operation.response;
      return response.data != null;
    } catch (e) {
      debugPrint('Error writing to DynamoDB: $e');
      return false;
    }
  }

  static List<SchemeDiscoveryModel> _flagshipNationalSchemes() {
    return [
      SchemeDiscoveryModel(
        id: 'pm-kisan-samman-nidhi',
        title: 'PM Kisan Samman Nidhi',
        shortTitle: 'PM-KISAN',
        category: 'Agriculture, Rural & Environment',
        description:
            'Direct income support of INR 6,000 per year transferred in three equal installments to eligible farmer families across India.',
        benefits:
            'INR 6,000 per year in 3 installments of INR 2,000 each via Direct Benefit Transfer (DBT).',
        level: 'Central',
        schemeFor: 'Farmer',
        beneficiaryState: 'All India',
        nodalMinistry: 'Ministry of Agriculture and Farmers Welfare',
        tags: const ['Agriculture', 'Direct Benefit Transfer', 'Farmers'],
        eligibilityCriteria: const [
          'Coverage: All India (Central Scheme)',
          'Small and marginal farmer families with cultivable landholding',
          'Valid Aadhaar seeded bank account required',
        ],
        requiredDocuments: const [
          'Aadhaar Card',
          'Land Holding / Khasra Khatauni Documents',
          'Savings Bank Account Passbook',
        ],
        applicationProcess:
            'Step 1: Visit pmkisan.gov.in and select New Farmer Registration. Step 2: Enter Aadhaar number, mobile number, and state. Step 3: Fill landholding details and upload supporting documents. Step 4: Submit form and track status online.',
        minAge: 18,
        targetOccupations: const ['Farmer'],
      ),
      SchemeDiscoveryModel(
        id: 'ayushman-bharat-pmjay',
        title: 'Ayushman Bharat - Pradhan Mantri Jan Arogya Yojana',
        shortTitle: 'PM-JAY',
        category: 'Health & Wellness',
        description:
            'National health assurance scheme providing cashless health cover of up to INR 5 Lakhs per family per year for secondary and tertiary hospitalization.',
        benefits:
            'Cashless hospitalization coverage up to INR 5,00,000 per family per year at empanelled public and private hospitals.',
        level: 'Central',
        schemeFor: 'Citizen',
        beneficiaryState: 'All India',
        nodalMinistry: 'Ministry of Health and Family Welfare',
        tags: const ['Health', 'Insurance', 'Hospitalization'],
        eligibilityCriteria: const [
          'Coverage: All India (Central Scheme)',
          'Low-income families and senior citizens aged 70+ years',
          'No restriction on family size, age, or gender',
        ],
        requiredDocuments: const [
          'Aadhaar Card',
          'Ration Card / Family ID',
          'Mobile Number linked with Aadhaar',
        ],
        applicationProcess:
            'Step 1: Check eligibility on beneficiary.nha.gov.in or Ayushman App. Step 2: Complete Aadhaar e-KYC verification. Step 3: Download your Ayushman Card or visit any empanelled hospital / CSC.',
        maxIncome: 500000,
      ),
      SchemeDiscoveryModel(
        id: 'pm-awas-yojana-rural',
        title: 'Pradhan Mantri Awaas Yojana - Gramin & Urban',
        shortTitle: 'PMAY',
        category: 'Housing & Shelter',
        description:
            'Financial assistance and interest subsidy to eligible rural and urban families for construction or purchase of a pucca house with basic amenities.',
        benefits:
            'Direct grant of INR 1.20 Lakh to INR 2.50 Lakh or interest subsidy on home loans for EWS/LIG families.',
        level: 'Central',
        schemeFor: 'Citizen',
        beneficiaryState: 'All India',
        nodalMinistry:
            'Ministry of Housing and Urban Affairs / Rural Development',
        tags: const ['Housing', 'Rural', 'Urban', 'Subsidy'],
        eligibilityCriteria: const [
          'Coverage: All India (Central Scheme)',
          'Family must not own a pucca house anywhere in India',
          'EWS (up to INR 3 Lakh) and LIG (up to INR 6 Lakh) households',
        ],
        requiredDocuments: const [
          'Aadhaar Card of all family members',
          'Income Certificate',
          'Bank Account Details',
          'Affidavit of not owning a pucca house',
        ],
        applicationProcess:
            'Step 1: Apply online via pmaymis.gov.in or through your local Gram Panchayat / CSC. Step 2: Complete Aadhaar authentication and fill household income and housing details. Step 3: Submit application for verification.',
        minAge: 18,
        maxIncome: 600000,
      ),
      SchemeDiscoveryModel(
        id: 'mudra-yojana',
        title: 'Pradhan Mantri MUDRA Yojana',
        shortTitle: 'PMMY',
        category: 'Business & Entrepreneurship',
        description:
            'Collateral-free microloans up to INR 10 Lakhs for non-corporate, non-farm small and micro enterprises under Shishu, Kishore, and Tarun categories.',
        benefits:
            'Collateral-free business loans: Shishu (up to INR 50,000), Kishore (INR 50,000 to 5 Lakhs), and Tarun (INR 5 Lakhs to 10 Lakhs).',
        level: 'Central',
        schemeFor: 'Self-Employed / Business',
        beneficiaryState: 'All India',
        nodalMinistry: 'Ministry of Finance',
        tags: const ['Loan', 'MSME', 'Entrepreneurship', 'Business'],
        eligibilityCriteria: const [
          'Coverage: All India (Central Scheme)',
          'Age Group: 18 to 65 years',
          'Indian citizens with a viable non-farm business plan or MSME',
        ],
        requiredDocuments: const [
          'Aadhaar Card and PAN Card',
          'Business Address and Registration Proof',
          'Bank Statement (last 6 months)',
          'Project Report / Quotation for machinery',
        ],
        applicationProcess:
            'Step 1: Visit JanSamarth Portal (jansamarth.in) or mudra.org.in. Step 2: Choose business loan category (Shishu, Kishore, or Tarun). Step 3: Submit application online or at any commercial bank branch.',
        minAge: 18,
        maxAge: 65,
        targetOccupations: const ['Self-Employed / Business', 'Unemployed'],
      ),
      SchemeDiscoveryModel(
        id: 'national-scholarship-portal',
        title: 'National Post-Matric Scholarship Scheme',
        shortTitle: 'NSP-PMS',
        category: 'Education & Learning',
        description:
            'Financial assistance for students belonging to SC, ST, OBC, and EWS communities pursuing post-matriculation or higher education courses.',
        benefits:
            'Full tuition fee reimbursement plus annual maintenance allowance transferred via DBT.',
        level: 'Central',
        schemeFor: 'Student',
        beneficiaryState: 'All India',
        nodalMinistry: 'Ministry of Social Justice and Empowerment',
        tags: const ['Scholarship', 'Education', 'Students'],
        eligibilityCriteria: const [
          'Coverage: All India (Central Scheme)',
          'Students enrolled in recognized Class 11, 12, UG, PG, or Diploma courses',
          'Annual family income below INR 2,50,000',
        ],
        requiredDocuments: const [
          'Aadhaar Card',
          'Caste / EWS Certificate',
          'Family Income Certificate',
          'Previous Year Marksheet and Bonafide Certificate',
          'Student Bank Passbook',
        ],
        applicationProcess:
            'Step 1: Register on National Scholarship Portal (scholarships.gov.in) for One-Time Registration (OTR). Step 2: Complete Aadhaar face authentication. Step 3: Select Post-Matric Scholarship and upload documents.',
        minAge: 14,
        maxAge: 35,
        maxIncome: 250000,
        targetCastes: const ['SC', 'ST', 'OBC', 'EWS'],
        targetOccupations: const ['Student'],
      ),
      SchemeDiscoveryModel(
        id: 'sukanya-samriddhi-yojana',
        title: 'Sukanya Samriddhi Yojana',
        shortTitle: 'SSY',
        category: 'Women and Child',
        description:
            'Government-backed small savings scheme for the girl child offering high tax-free interest rates for higher education and marriage expenses.',
        benefits:
            '8.2% p.a. tax-free compounded interest and Section 80C tax deduction up to INR 1.50 Lakh per year.',
        level: 'Central',
        schemeFor: 'Female',
        beneficiaryState: 'All India',
        nodalMinistry: 'Ministry of Finance / Women and Child Development',
        tags: const ['Savings', 'Girl Child', 'Women', 'Education'],
        eligibilityCriteria: const [
          'Coverage: All India (Central Scheme)',
          'Girl child aged 10 years or below (or parents/legal guardians of girl child)',
          'Maximum 2 accounts per family',
        ],
        requiredDocuments: const [
          'Birth Certificate of Girl Child',
          'Aadhaar Card and PAN Card of Parent / Guardian',
          'Passport-size Photographs',
        ],
        applicationProcess:
            'Step 1: Visit any India Post Office or authorized bank branch. Step 2: Fill SSY Account Opening Form (Form-1). Step 3: Attach birth certificate and guardian ID proof with initial deposit (minimum INR 250).',
        targetGenders: const ['Female'],
      ),
      SchemeDiscoveryModel(
        id: 'atal-pension-yojana',
        title: 'Atal Pension Yojana',
        shortTitle: 'APY',
        category: 'Banking, Financial Services and Insurance',
        description:
            'Guaranteed monthly pension ranging from INR 1,000 to INR 5,000 after age 60 for citizens working in the unorganized sector.',
        benefits:
            'Guaranteed lifelong monthly pension of INR 1,000, 2,000, 3,000, 4,000, or 5,000 from age 60.',
        level: 'Central',
        schemeFor: 'Citizen',
        beneficiaryState: 'All India',
        nodalMinistry: 'Ministry of Finance (PFRDA)',
        tags: const ['Pension', 'Retirement', 'Social Security'],
        eligibilityCriteria: const [
          'Coverage: All India (Central Scheme)',
          'Age Group: 18 to 40 years',
          'Must hold a savings bank account or post office savings account',
        ],
        requiredDocuments: const [
          'Aadhaar Card',
          'Active Savings Bank Account with Auto-Debit mandate',
          'Mobile Number',
        ],
        applicationProcess:
            'Step 1: Log in to your bank net banking / mobile app or visit enps.nsdl.com. Step 2: Select Atal Pension Yojana and choose pension slab (INR 1,000 to 5,000). Step 3: Authorize monthly auto-debit.',
        minAge: 18,
        maxAge: 40,
      ),
      SchemeDiscoveryModel(
        id: 'pm-kaushal-vikas-yojana',
        title: 'Pradhan Mantri Kaushal Vikas Yojana 4.0',
        shortTitle: 'PMKVY',
        category: 'Skills & Employment',
        description:
            'Free industry-relevant skill training, assessment, and government certification for youth across AI, drone technology, manufacturing, and services.',
        benefits:
            '100% free skill training, National Skill Qualification Framework (NSQF) certificate, and placement assistance.',
        level: 'Central',
        schemeFor: 'Student',
        beneficiaryState: 'All India',
        nodalMinistry: 'Ministry of Skill Development and Entrepreneurship',
        tags: const ['Skills', 'Vocational Training', 'Employment', 'Youth'],
        eligibilityCriteria: const [
          'Coverage: All India (Central Scheme)',
          'Age Group: 15 to 45 years',
          'Unemployed youth, students, or school/college dropouts',
        ],
        requiredDocuments: const [
          'Aadhaar Card',
          'Educational Qualification Marksheet',
          'Bank Account Passbook',
        ],
        applicationProcess:
            'Step 1: Visit Skill India Digital Hub (skillindiadigital.gov.in). Step 2: Register with mobile number and complete Aadhaar e-KYC. Step 3: Choose an online course or nearby PMKVY Training Centre.',
        minAge: 15,
        maxAge: 45,
        targetOccupations: const ['Student', 'Unemployed'],
      ),
      SchemeDiscoveryModel(
        id: 'majhi-ladki-bahin-maharashtra',
        title: 'Mukhyamantri Majhi Ladki Bahin Yojana',
        shortTitle: 'MMLBY',
        category: 'Women and Child',
        description:
            'Direct financial assistance of INR 1,500 per month to eligible women residents of Maharashtra to promote economic independence, health, and nutrition.',
        benefits:
            'INR 1,500 per month (INR 18,000 per year) credited directly to Aadhaar-linked bank account.',
        level: 'State',
        schemeFor: 'Female',
        beneficiaryState: 'Maharashtra',
        nodalMinistry: 'Women and Child Development Department, Maharashtra',
        tags: const ['Women', 'Financial Assistance', 'DBT', 'Maharashtra'],
        eligibilityCriteria: const [
          'Resident of Maharashtra',
          'Age Group: 21 to 65 years',
          'Eligible Gender: Female',
          'Annual Family Income up to INR 2.5 Lakh',
        ],
        requiredDocuments: const [
          'Aadhaar Card',
          'Domicile / Ration Card / Voter ID of Maharashtra',
          'Income Certificate or Yellow/Orange Ration Card',
          'Aadhaar-linked Bank Account Passbook',
        ],
        applicationProcess:
            'Step 1: Visit ladakibahin.maharashtra.gov.in or Nari Shakti Doot App. Step 2: Complete Aadhaar e-KYC and fill applicant details. Step 3: Upload domicile and income proof and submit.',
        minAge: 21,
        maxAge: 65,
        maxIncome: 250000,
        targetGenders: const ['Female'],
      ),
      SchemeDiscoveryModel(
        id: 'mahatma-jyotirao-phule-jan-arogya-mh',
        title: 'Mahatma Jyotirao Phule Jan Arogya Yojana',
        shortTitle: 'MJPJAY',
        category: 'Health & Wellness',
        description:
            'Flagship health insurance scheme of Government of Maharashtra providing cashless medical and surgical treatment up to INR 5 Lakhs per family per year.',
        benefits:
            'Cashless medical coverage up to INR 5,00,000 per family per year across network hospitals in Maharashtra.',
        level: 'State',
        schemeFor: 'Citizen',
        beneficiaryState: 'Maharashtra',
        nodalMinistry: 'Public Health Department, Maharashtra',
        tags: const ['Health', 'Insurance', 'Hospitalization', 'Maharashtra'],
        eligibilityCriteria: const [
          'Resident of Maharashtra',
          'Holders of Ration Card / Domicile Certificate in Maharashtra',
        ],
        requiredDocuments: const [
          'Aadhaar Card',
          'Maharashtra Ration Card / Domicile Certificate',
        ],
        applicationProcess:
            'Step 1: Visit any network hospital in Maharashtra and approach the Arogyamitra desk. Step 2: Present Aadhaar Card and Ration Card for instant e-card verification.',
      ),
      SchemeDiscoveryModel(
        id: 'yuva-nidhi-karnataka',
        title: 'Yuva Nidhi Scheme Karnataka',
        shortTitle: 'Yuva Nidhi',
        category: 'Skills & Employment',
        description:
            'Monthly unemployment allowance of INR 3,000 for unemployed degree graduates and INR 1,500 for diploma holders in Karnataka.',
        benefits:
            'INR 3,000/month for graduates and INR 1,500/month for diploma holders for up to 2 years alongside skill training.',
        level: 'State',
        schemeFor: 'Unemployed',
        beneficiaryState: 'Karnataka',
        nodalMinistry:
            'Department of Skill Development, Entrepreneurship and Livelihood, Karnataka',
        tags: const ['Youth', 'Unemployment Allowance', 'Skills', 'Karnataka'],
        eligibilityCriteria: const [
          'Resident of Karnataka',
          'Unemployed degree or diploma graduate',
          'Target Group: Unemployed, Student',
        ],
        requiredDocuments: const [
          'Aadhaar Card',
          'Degree / Diploma Provisional Certificate',
          'Domicile Proof of Karnataka',
          'Bank Account Passbook',
        ],
        applicationProcess:
            'Step 1: Log in to Seva Sindhu portal (sevasindhuservices.karnataka.gov.in). Step 2: Select Yuva Nidhi application and verify University registration number. Step 3: Submit self-declaration.',
        minAge: 18,
        maxAge: 35,
        targetOccupations: const ['Unemployed', 'Student'],
      ),
      SchemeDiscoveryModel(
        id: 'kalia-odisha-farmer',
        title: 'Krushak Assistance for Livelihood and Income Augmentation (KALIA)',
        shortTitle: 'KALIA',
        category: 'Agriculture, Rural & Environment',
        description:
            'Financial assistance for cultivation, livelihood support for landless agricultural households, and life insurance support for farmers in Odisha.',
        benefits:
            'Financial assistance of INR 4,000 per cropping season for small and marginal farmers and INR 12,500 for landless agricultural households.',
        level: 'State',
        schemeFor: 'Farmer',
        beneficiaryState: 'Odisha',
        nodalMinistry: 'Department of Agriculture and Farmers Empowerment, Odisha',
        tags: const ['Agriculture', 'Farmers', 'Livelihood', 'Odisha'],
        eligibilityCriteria: const [
          'Resident of Odisha',
          'Target Group: Farmer',
          'Small and marginal farmers or landless agricultural labourers',
        ],
        requiredDocuments: const [
          'Aadhaar Card',
          'Land Record / Cultivation Proof',
          'Bank Account Passbook',
        ],
        applicationProcess:
            'Step 1: Visit kalia.odisha.gov.in. Step 2: Complete Aadhaar authentication and verify land details. Step 3: Submit online application.',
        minAge: 18,
        targetOccupations: const ['Farmer'],
      ),
      SchemeDiscoveryModel(
        id: 'rythu-bharosa-telangana',
        title: 'Rythu Bharosa Farmer Investment Support Scheme',
        shortTitle: 'Rythu Bharosa',
        category: 'Agriculture, Rural & Environment',
        description:
            'Agricultural investment support of INR 15,000 per acre per year for farmers and tenant farmers in Telangana.',
        benefits:
            'INR 15,000 per acre per year for farmers and INR 12,000 per year for agricultural workers.',
        level: 'State',
        schemeFor: 'Farmer',
        beneficiaryState: 'Telangana',
        nodalMinistry: 'Department of Agriculture, Telangana',
        tags: const ['Agriculture', 'Farmers', 'Telangana', 'DBT'],
        eligibilityCriteria: const [
          'Resident of Telangana',
          'Target Group: Farmer',
        ],
        requiredDocuments: const [
          'Aadhaar Card',
          'Pattadar Passbook / Land Records',
          'Bank Passbook',
        ],
        applicationProcess:
            'Step 1: Apply through the Mandal Agriculture Officer (MAO) or Praja Palana Gram Sabha with land passbook and Aadhaar.',
        minAge: 18,
        targetOccupations: const ['Farmer'],
      ),
      SchemeDiscoveryModel(
        id: 'pudhumai-penn-tamil-nadu',
        title: 'Moovalur Ramamirtham Ammaiyar Pudhumai Penn Scheme',
        shortTitle: 'Pudhumai Penn',
        category: 'Education & Learning',
        description:
            'Monthly financial assistance of INR 1,000 for girl students in Tamil Nadu who studied in government schools from Class 6 to 12 and are pursuing higher education.',
        benefits:
            'INR 1,000 per month directly transferred to the student bank account until completion of undergraduate degree, diploma, or ITI course.',
        level: 'State',
        schemeFor: 'Student',
        beneficiaryState: 'Tamil Nadu',
        nodalMinistry:
            'Social Welfare and Women Empowerment Department, Tamil Nadu',
        tags: const ['Education', 'Girl Child', 'Scholarship', 'Tamil Nadu'],
        eligibilityCriteria: const [
          'Resident of Tamil Nadu',
          'Eligible Gender: Female',
          'Target Group: Student',
          'Studied in Government school from Class 6 to 12',
        ],
        requiredDocuments: const [
          'Aadhaar Card',
          'EMIS ID & School Transfer Certificate',
          'College Bonafide Certificate',
          'Bank Passbook',
        ],
        applicationProcess:
            'Step 1: Register via penkalvi.tn.gov.in through your college nodal officer. Step 2: Verify EMIS ID and Aadhaar-seeded bank account.',
        minAge: 16,
        maxAge: 28,
        targetGenders: const ['Female'],
        targetOccupations: const ['Student'],
      ),
      SchemeDiscoveryModel(
        id: 'mukhyamantri-kanya-sumangala-up',
        title: 'Mukhyamantri Kanya Sumangala Yojana',
        shortTitle: 'MKSY',
        category: 'Women and Child',
        description:
            'Conditional cash transfer of INR 25,000 in 6 stages from birth to graduation for the health and education of the girl child in Uttar Pradesh.',
        benefits:
            'INR 25,000 total grant disbursed across 6 developmental milestones from birth to degree/diploma admission.',
        level: 'State',
        schemeFor: 'Female',
        beneficiaryState: 'Uttar Pradesh',
        nodalMinistry: 'Department of Women and Child Development, Uttar Pradesh',
        tags: const ['Girl Child', 'Women', 'Education', 'Uttar Pradesh'],
        eligibilityCriteria: const [
          'Resident of Uttar Pradesh',
          'Eligible Gender: Female',
          'Annual Family Income up to INR 3.0 Lakh',
        ],
        requiredDocuments: const [
          'Aadhaar Card of Parents and Child',
          'Birth Certificate / School Enrollment Certificate',
          'Domicile Certificate of Uttar Pradesh',
          'Bank Passbook',
        ],
        applicationProcess:
            'Step 1: Visit mksy.up.gov.in. Step 2: Register citizen profile and select stage of application. Step 3: Upload birth/immunization/school certificate and submit.',
        minAge: 0,
        maxAge: 25,
        maxIncome: 300000,
        targetGenders: const ['Female'],
      ),
      SchemeDiscoveryModel(
        id: 'sugamya-bharat-divyang-scholarship',
        title: 'National Scholarship for Persons with Disabilities (Divyangjan)',
        shortTitle: 'DEPwD Scholarship',
        category: 'Social Welfare & Empowerment',
        description:
            'Pre-matric, post-matric, and top-class education scholarships along with assistive device grants for students and citizens with benchmark disabilities.',
        benefits:
            'Full tuition reimbursement, maintenance allowance, book grant, and reader/assistive allowance via DBT.',
        level: 'Central',
        schemeFor: 'Divyangjan',
        beneficiaryState: 'All India',
        nodalMinistry:
            'Department of Empowerment of Persons with Disabilities (DEPwD)',
        tags: const ['Disability', 'Divyangjan', 'Scholarship', 'Assistive'],
        eligibilityCriteria: const [
          'Coverage: All India (Central Scheme)',
          'Person with Benchmark Disability (PwD / Divyangjan)',
          'Minimum 40% disability certified by UDID',
          'Annual Family Income up to INR 2.5 Lakh',
        ],
        requiredDocuments: const [
          'Aadhaar Card',
          'UDID / Disability Certificate (40% or above)',
          'Income Certificate',
          'Bank Account Passbook',
        ],
        applicationProcess:
            'Step 1: Apply on National Scholarship Portal (scholarships.gov.in) or swavlambancard.gov.in. Step 2: Enter UDID number and upload academic and income documents.',
        maxIncome: 250000,
        forDisabledOnly: true,
      ),
    ];
  }
}
