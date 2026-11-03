import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../models/scheme_discovery_model.dart';
import 'aws_amplify_service.dart';

class DynamoDbSchemeDiscoveryService {
  static List<SchemeDiscoveryModel> _cachedSchemes = [];

  static List<SchemeDiscoveryModel> get cachedSchemes => _cachedSchemes;

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

    if (AwsAmplifyService.isInitialized) {
      try {
        debugPrint('DynamoDbSchemeDiscoveryService: Querying DynamoDB via AppSync...');
        final operation = Amplify.API.query(
          request: GraphQLRequest<String>(
            document: _listSchemesQuery,
            variables: {'limit': 100},
          ),
        );

        final response = await operation.response;
        if (response.data != null && response.data!.isNotEmpty) {
          final decoded = json.decode(response.data!) as Map<String, dynamic>;
          final listData = decoded['listCivicSchemes'];
          if (listData != null && listData['items'] != null) {
            final items = listData['items'] as List<dynamic>;
            if (items.isNotEmpty) {
              _cachedSchemes = items
                  .where((item) => item != null)
                  .map((item) => SchemeDiscoveryModel(
                        id: item['id']?.toString() ?? '',
                        title: item['title']?.toString() ?? '',
                        shortTitle: item['shortTitle']?.toString() ?? '',
                        description: item['description']?.toString() ?? '',
                        category: item['category']?.toString() ?? 'General',
                        level: item['level']?.toString() ?? '',
                        schemeFor: item['schemeFor']?.toString() ?? '',
                        beneficiaryState:
                            item['beneficiaryState']?.toString() ?? '',
                        nodalMinistry: item['nodalMinistry']?.toString() ?? '',
                        tags: (item['tags'] as List<dynamic>?)
                                ?.map((e) => e.toString())
                                .toList() ??
                            const [],
                        eligibilityCriteria: (item['eligibilityCriteria']
                                    as List<dynamic>?)
                                ?.map((e) => e.toString())
                                .toList() ??
                            const [],
                        applicationProcess:
                            item['applicationProcess']?.toString() ?? '',
                      ))
                  .toList();

              debugPrint(
                  'DynamoDbSchemeDiscoveryService: Retrieved ${_cachedSchemes.length} schemes from DynamoDB');
              return _cachedSchemes;
            }
          }
        }
      } catch (e) {
        debugPrint('DynamoDbSchemeDiscoveryService query note: $e');
      }
    }

    if (_cachedSchemes.isEmpty) {
      _cachedSchemes = _fallbackInitialSchemes();
    }

    return _cachedSchemes;
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

  static List<SchemeDiscoveryModel> _fallbackInitialSchemes() {
    return [
      SchemeDiscoveryModel(
        id: 'pm-kisan-samman-nidhi',
        title: 'PM Kisan Samman Nidhi',
        shortTitle: 'PM-KISAN',
        category: 'Agriculture, Rural & Environment',
        description:
            'Direct income support of INR 6000 per year transferred in three equal installments to eligible farmer families.',
        level: 'Central',
        schemeFor: 'Farmer',
        beneficiaryState: 'All',
        nodalMinistry: 'Ministry Of Agriculture and Farmers Welfare',
        tags: ['Agriculture', 'Direct Benefit Transfer', 'Farmers'],
        eligibilityCriteria: [
          'Target: Small and Marginal Farmers',
          'Level: Central',
          'Landholding farmer families with cultivable land'
        ],
        applicationProcess:
            'Apply online via pmkisan.gov.in or visit the nearest CSC centre.',
      ),
      SchemeDiscoveryModel(
        id: 'ayushman-bharat-pmjay',
        title: 'Ayushman Bharat - Pradhan Mantri Jan Arogya Yojana',
        shortTitle: 'PM-JAY',
        category: 'Health & Wellness',
        description:
            'World largest health assurance scheme providing health cover of up to INR 5 lakhs per family per year for secondary and tertiary care hospitalization.',
        level: 'Central',
        schemeFor: 'Individual',
        beneficiaryState: 'All',
        nodalMinistry: 'Ministry Of Health and Family Welfare',
        tags: ['Health', 'Insurance', 'Hospitalization'],
        eligibilityCriteria: [
          'Target: Low-income families identified in SECC 2011',
          'Level: Central',
          'Deprived rural families and occupational categories of urban workers'
        ],
        applicationProcess:
            'Check eligibility on mera.pmjay.gov.in and generate Ayushman Card at any empanelled hospital.',
      ),
      SchemeDiscoveryModel(
        id: 'pm-awas-yojana-rural',
        title: 'Pradhan Mantri Awaas Yojana - Gramin',
        shortTitle: 'PMAY-G',
        category: 'Housing & Shelter',
        description:
            'Financial assistance to homeless and households living in kutcha or dilapidated houses in rural areas for construction of pucca houses.',
        level: 'Central',
        schemeFor: 'Individual',
        beneficiaryState: 'All',
        nodalMinistry: 'Ministry Of Rural Development',
        tags: ['Housing', 'Rural', 'Infrastructure'],
        eligibilityCriteria: [
          'Target: Houseless families or families with kutcha houses',
          'Level: Central',
          'Verified through Gram Sabha and Socio-Economic Caste Census'
        ],
        applicationProcess:
            'Registration is completed through the local Gram Panchayat or Block Development Office.',
      ),
      SchemeDiscoveryModel(
        id: 'mudra-yojana',
        title: 'Pradhan Mantri MUDRA Yojana',
        shortTitle: 'PMMY',
        category: 'Business & Entrepreneurship',
        description:
            'Refinance support and collateral-free microloans up to INR 10 Lakhs to non-corporate, non-farm small and micro enterprises across Shishu, Kishore, and Tarun categories.',
        level: 'Central',
        schemeFor: 'Individual',
        beneficiaryState: 'All',
        nodalMinistry: 'Ministry Of Finance',
        tags: ['Loan', 'MSME', 'Entrepreneurship'],
        eligibilityCriteria: [
          'Target: Micro-enterprises and non-farm small businesses',
          'Level: Central',
          'Indian citizens having viable business proposal'
        ],
        applicationProcess:
            'Apply online via udyamimitra.in or submit business proposal to any commercial bank or NBFC.',
      ),
      SchemeDiscoveryModel(
        id: 'national-scholarship-portal',
        title: 'Post Matric Scholarship Scheme',
        shortTitle: 'PMS',
        category: 'Education & Learning',
        description:
            'Financial assistance to students belonging to underserved communities pursuing post-matriculation or post-secondary courses.',
        level: 'Central',
        schemeFor: 'Student',
        beneficiaryState: 'All',
        nodalMinistry: 'Ministry Of Social Justice and Empowerment',
        tags: ['Scholarship', 'Education', 'Students'],
        eligibilityCriteria: [
          'Target: Students enrolled in recognized post-matric courses',
          'Level: Central',
          'Family income threshold criteria apply'
        ],
        applicationProcess:
            'Apply directly through the National Scholarship Portal (scholarships.gov.in).',
      ),
      SchemeDiscoveryModel(
        id: 'sukanya-samriddhi-yojana',
        title: 'Sukanya Samriddhi Yojana',
        shortTitle: 'SSY',
        category: 'Women and Child',
        description:
            'Small savings scheme targeted at building a fund for the education and marriage expenses of the girl child with high government-backed interest rates.',
        level: 'Central',
        schemeFor: 'Individual',
        beneficiaryState: 'All',
        nodalMinistry: 'Ministry Of Finance',
        tags: ['Savings', 'Girl Child', 'Investment'],
        eligibilityCriteria: [
          'Target: Girl child aged below 10 years',
          'Level: Central',
          'Account opened by parents or legal guardian'
        ],
        applicationProcess:
            'Open account at any Post Office or authorized commercial bank branch.',
      ),
      SchemeDiscoveryModel(
        id: 'atal-pension-yojana',
        title: 'Atal Pension Yojana',
        shortTitle: 'APY',
        category: 'Banking, Financial Services and Insurance',
        description:
            'Guaranteed monthly pension ranging from INR 1000 to INR 5000 after 60 years of age for citizens working in unorganized sectors.',
        level: 'Central',
        schemeFor: 'Individual',
        beneficiaryState: 'All',
        nodalMinistry: 'Ministry Of Finance',
        tags: ['Pension', 'Retirement', 'Social Security'],
        eligibilityCriteria: [
          'Target: Unorganized sector workers',
          'Age: 18 to 40 years',
          'Must hold a valid savings bank account'
        ],
        applicationProcess:
            'Subscribe through your bank branch, mobile banking, or net banking facility.',
      ),
      SchemeDiscoveryModel(
        id: 'pm-kushal-vikas-yojana',
        title: 'Pradhan Mantri Kaushal Vikas Yojana',
        shortTitle: 'PMKVY',
        category: 'Skills & Employment',
        description:
            'Skill certification and industry-relevant vocational training initiative to help youth take up training to secure a better livelihood.',
        level: 'Central',
        schemeFor: 'Student',
        beneficiaryState: 'All',
        nodalMinistry: 'Ministry Of Skill Development and Entrepreneurship',
        tags: ['Skills', 'Vocational Training', 'Employment'],
        eligibilityCriteria: [
          'Target: Indian youth seeking industry-relevant skill training',
          'Level: Central',
          'Candidates with basic educational qualifications per course'
        ],
        applicationProcess:
            'Register on skillindia.gov.in and select a nearby accredited training centre.',
      ),
    ];
  }
}
