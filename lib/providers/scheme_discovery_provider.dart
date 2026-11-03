import 'package:flutter/foundation.dart';
import '../models/scheme_discovery_model.dart';
import '../core/services/dynamodb_scheme_discovery_service.dart';

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

  List<String> _categories = [
    'All',
    'Agriculture, Rural & Environment',
    'Banking, Financial Services and Insurance',
    'Business & Entrepreneurship',
    'Education & Learning',
    'Health & Wellness',
    'Housing & Shelter',
    'Public Safety, Law & Justice',
    'Science, IT & Communications',
    'Skills & Employment',
    'Social welfare & Empowerment',
    'Sports & Culture',
    'Transport & Infrastructure',
    'Travel & Tourism',
    'Utility & Sanitation',
    'Women and Child',
  ];

  List<String> get categories => _categories;

  int get totalCount => _allSchemes.length;

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

  void _applyFilters() {
    List<SchemeDiscoveryModel> list = _allSchemes;

    // Category filter
    if (_currentCategoryFilter != 'All') {
      final targetCat = _currentCategoryFilter.toLowerCase();
      list = list.where((s) {
        final schemeCat = s.category.toLowerCase();
        return schemeCat == targetCat ||
            schemeCat.contains(targetCat) ||
            targetCat.contains(schemeCat);
      }).toList();
    }

    // Keyword search filter
    if (_currentSearchQuery.isNotEmpty) {
      final q = _currentSearchQuery;
      list = list.where((s) {
        if (s.title.toLowerCase().contains(q)) return true;
        if (s.shortTitle.toLowerCase().contains(q)) return true;
        if (s.description.toLowerCase().contains(q)) return true;
        if (s.category.toLowerCase().contains(q)) return true;
        if (s.nodalMinistry.toLowerCase().contains(q)) return true;
        if (s.schemeFor.toLowerCase().contains(q)) return true;
        if (s.beneficiaryState.toLowerCase().contains(q)) return true;
        if (s.tags.any((t) => t.toLowerCase().contains(q))) return true;
        return false;
      }).toList();
    }

    _filteredSchemes = list;
  }
}
