import 'package:flutter/foundation.dart';
import '../core/constants/profile_constants.dart';
import '../core/services/dynamodb_scheme_discovery_service.dart';
import '../models/citizen_profile_model.dart';
import '../models/scheme_discovery_model.dart';

class SchemeDiscoveryProvider with ChangeNotifier {
  List<SchemeDiscoveryModel> _allSchemes = [];
  List<SchemeDiscoveryModel> _filteredSchemes = [];

  List<SchemeDiscoveryModel> get allSchemes => _allSchemes;
  List<SchemeDiscoveryModel> get filteredSchemes => _filteredSchemes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _currentCategoryFilter = 'All';
  String get currentCategoryFilter => _currentCategoryFilter;

  String _currentSearchQuery = '';
  String get currentSearchQuery => _currentSearchQuery;

  String _selectedState = 'All States';
  String get selectedState => _selectedState;

  String _selectedLevel = 'All';
  String get selectedLevel => _selectedLevel;

  String _selectedIncomeRange = 'All';
  String get selectedIncomeRange => _selectedIncomeRange;

  int? _selectedAge;
  int? get selectedAge => _selectedAge;

  String _selectedGender = 'All';
  String get selectedGender => _selectedGender;

  String _selectedCaste = 'All';
  String get selectedCaste => _selectedCaste;

  String _selectedOccupation = 'All';
  String get selectedOccupation => _selectedOccupation;

  bool _onlyForDisabled = false;
  bool get onlyForDisabled => _onlyForDisabled;

  bool _matchMyProfile = false;
  bool get matchMyProfile => _matchMyProfile;

  List<String> _categories = [
    'All',
    'Agriculture, Rural & Environment',
    'Banking, Financial Services and Insurance',
    'Business & Entrepreneurship',
    'Education & Learning',
    'Health & Wellness',
    'Housing & Shelter',
    'Science, IT & Communications',
    'Skills & Employment',
    'Social welfare & Empowerment',
    'Sports & Culture',
    'Utility & Sanitation',
    'Women and Child',
  ];

  List<String> get categories => _categories;

  int get totalCount => _allSchemes.length;

  int get activeFilterCount {
    int count = 0;
    if (_selectedState != 'All States') count++;
    if (_selectedLevel != 'All') count++;
    if (_selectedIncomeRange != 'All') count++;
    if (_selectedAge != null && _selectedAge! > 0) count++;
    if (_selectedGender != 'All') count++;
    if (_selectedCaste != 'All') count++;
    if (_selectedOccupation != 'All') count++;
    if (_onlyForDisabled) count++;
    return count;
  }

  SchemeDiscoveryProvider() {
    loadSchemes();
  }

  Future<void> loadSchemes({bool forceReload = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final schemes = await DynamoDbSchemeDiscoveryService.loadSchemes(
        forceReload: forceReload,
      );

      _allSchemes = schemes;

      if (_allSchemes.isNotEmpty) {
        final uniqueCats = <String>{};
        for (final s in _allSchemes) {
          if (s.category.trim().isNotEmpty && s.category != 'General') {
            uniqueCats.add(s.category.trim());
          }
        }

        if (uniqueCats.isNotEmpty) {
          final sorted = uniqueCats.toList()..sort();
          _categories = ['All', ...sorted];
        }
      }

      _applyFilters();
    } catch (e) {
      debugPrint('SchemeDiscoveryProvider load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchSchemes(String query) {
    _currentSearchQuery = query.trim().toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void filterByCategory(String category) {
    _currentCategoryFilter = category;
    _applyFilters();
    notifyListeners();
  }

  void toggleMatchMyProfile(CitizenProfileModel? profile) {
    if (_matchMyProfile || profile == null) {
      _matchMyProfile = false;
      clearAdvancedFilters();
      return;
    }

    _matchMyProfile = true;
    _selectedState = profile.state.trim().isNotEmpty
        ? ProfileConstants.normalizeState(profile.state)
        : 'All States';
    _selectedAge = profile.computedAge > 0 ? profile.computedAge : null;
    _selectedIncomeRange = profile.effectiveIncomeRange.isNotEmpty
        ? ProfileConstants.normalizeIncomeRange(profile.effectiveIncomeRange)
        : 'All';
    _selectedGender = (profile.gender?.trim().isNotEmpty ?? false)
        ? ProfileConstants.normalizeGender(profile.gender)
        : 'All';
    _selectedCaste = (profile.casteCategory?.trim().isNotEmpty ?? false)
        ? ProfileConstants.normalizeCasteCategory(profile.casteCategory)
        : 'All';
    _selectedOccupation = (profile.occupation?.trim().isNotEmpty ?? false)
        ? ProfileConstants.normalizeOccupation(profile.occupation)
        : 'All';
    _onlyForDisabled = profile.isDisabled;

    _applyFilters();
    notifyListeners();
  }

  void updateFilters({
    String? state,
    String? level,
    String? incomeRange,
    int? age,
    bool clearAge = false,
    String? gender,
    String? caste,
    String? occupation,
    bool? onlyForDisabled,
  }) {
    _matchMyProfile = false;
    if (state != null) _selectedState = state;
    if (level != null) _selectedLevel = level;
    if (incomeRange != null) _selectedIncomeRange = incomeRange;
    if (clearAge) {
      _selectedAge = null;
    } else if (age != null) {
      _selectedAge = age > 0 ? age : null;
    }
    if (gender != null) _selectedGender = gender;
    if (caste != null) _selectedCaste = caste;
    if (occupation != null) _selectedOccupation = occupation;
    if (onlyForDisabled != null) _onlyForDisabled = onlyForDisabled;

    _applyFilters();
    notifyListeners();
  }

  void clearAdvancedFilters() {
    _matchMyProfile = false;
    _selectedState = 'All States';
    _selectedLevel = 'All';
    _selectedIncomeRange = 'All';
    _selectedAge = null;
    _selectedGender = 'All';
    _selectedCaste = 'All';
    _selectedOccupation = 'All';
    _onlyForDisabled = false;
    _applyFilters();
    notifyListeners();
  }

  void clearAllFilters() {
    _currentCategoryFilter = 'All';
    _currentSearchQuery = '';
    clearAdvancedFilters();
  }

  void _applyFilters() {
    Iterable<SchemeDiscoveryModel> iter = _allSchemes;

    // 1. Category filter
    if (_currentCategoryFilter != 'All') {
      final targetCat = _currentCategoryFilter.toLowerCase();
      iter = iter.where((s) {
        final schemeCat = s.category.toLowerCase();
        return schemeCat == targetCat ||
            schemeCat.contains(targetCat) ||
            targetCat.contains(schemeCat);
      });
    }

    // 2. Level filter (All / Central / State)
    if (_selectedLevel != 'All') {
      final targetLevel = _selectedLevel.toLowerCase();
      iter = iter.where((s) => s.level.toLowerCase() == targetLevel);
    }

    // 3. Demographic & State filters
    final numericIncome = _selectedIncomeRange != 'All'
        ? ProfileConstants.maxEligibleIncomeForRange(_selectedIncomeRange)
        : null;

    if (activeFilterCount > 0) {
      iter = iter.where((s) {
        if (_onlyForDisabled && !s.forDisabledOnly) {
          // When explicitly filtering "Persons with Disability Only", show schemes tailored for PwD or general health/welfare
          final text = '${s.title} ${s.description}'.toLowerCase();
          if (!s.forDisabledOnly &&
              !text.contains('disab') &&
              !text.contains('divyang') &&
              !text.contains('pension')) {
            return false;
          }
        }
        return s.matchesDemographics(
          state: _selectedState == 'All States' ? null : _selectedState,
          age: _selectedAge,
          income: numericIncome,
          gender: _selectedGender == 'All' ? null : _selectedGender,
          casteCategory: _selectedCaste == 'All' ? null : _selectedCaste,
          occupation:
              _selectedOccupation == 'All' ? null : _selectedOccupation,
          isDisabled: _onlyForDisabled ? true : null,
        );
      });
    }

    // 4. Keyword search filter
    if (_currentSearchQuery.isNotEmpty) {
      final q = _currentSearchQuery;
      iter = iter.where((s) {
        if (s.title.toLowerCase().contains(q)) return true;
        if (s.shortTitle.toLowerCase().contains(q)) return true;
        if (s.description.toLowerCase().contains(q)) return true;
        if (s.benefits.toLowerCase().contains(q)) return true;
        if (s.category.toLowerCase().contains(q)) return true;
        if (s.nodalMinistry.toLowerCase().contains(q)) return true;
        if (s.schemeFor.toLowerCase().contains(q)) return true;
        if (s.beneficiaryState.toLowerCase().contains(q)) return true;
        if (s.tags.any((t) => t.toLowerCase().contains(q))) return true;
        return false;
      });
    }

    final list = iter.toList();

    // Sort by relevance when demographic/state filters are active
    if (activeFilterCount > 0) {
      list.sort((a, b) {
        final scoreB = b.computeRelevanceScore(
          state: _selectedState == 'All States' ? null : _selectedState,
          age: _selectedAge,
          income: numericIncome,
          gender: _selectedGender == 'All' ? null : _selectedGender,
          casteCategory: _selectedCaste == 'All' ? null : _selectedCaste,
          occupation:
              _selectedOccupation == 'All' ? null : _selectedOccupation,
          isDisabled: _onlyForDisabled,
        );
        final scoreA = a.computeRelevanceScore(
          state: _selectedState == 'All States' ? null : _selectedState,
          age: _selectedAge,
          income: numericIncome,
          gender: _selectedGender == 'All' ? null : _selectedGender,
          casteCategory: _selectedCaste == 'All' ? null : _selectedCaste,
          occupation:
              _selectedOccupation == 'All' ? null : _selectedOccupation,
          isDisabled: _onlyForDisabled,
        );
        return scoreB.compareTo(scoreA);
      });
    }

    _filteredSchemes = list;
  }
}
