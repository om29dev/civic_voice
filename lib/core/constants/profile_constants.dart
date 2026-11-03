/// Canonical demographic constants and conversion utilities shared across
/// Registration, Citizen Profile, Eligibility Checker, Scheme Discovery,
/// and Smart Recommendations.
class ProfileConstants {
  ProfileConstants._();

  static const List<String> statesAndUTs = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  static const List<String> incomeRanges = [
    'Below ₹1 Lakh',
    '₹1L - ₹2.5L',
    '₹2.5L - ₹5L',
    '₹5L - ₹10L',
    'Above ₹10 Lakh',
  ];

  static const List<String> casteCategories = [
    'General',
    'OBC',
    'SC',
    'ST',
    'EWS',
  ];

  static const List<String> genders = [
    'Male',
    'Female',
    'Other',
  ];

  static const List<String> maritalStatuses = [
    'Single',
    'Married',
    'Widowed',
    'Divorced',
  ];

  static const List<String> occupations = [
    'Farmer',
    'Student',
    'Self-Employed',
    'Salaried',
    'Unemployed / Homemaker',
    'Construction / Daily Wage Worker',
    'Senior Citizen / Retired',
    'Business / Entrepreneur',
  ];

  static String normalizeState(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Maharashtra';
    final trimmed = raw.trim();
    for (final s in statesAndUTs) {
      if (s.toLowerCase() == trimmed.toLowerCase()) return s;
    }
    if (trimmed.toLowerCase().contains('delhi') ||
        trimmed.toLowerCase() == 'ncr') {
      return 'Delhi';
    }
    if (trimmed.toLowerCase().contains('pondicherry')) {
      return 'Puducherry';
    }
    if (trimmed.toLowerCase().contains('orissa')) {
      return 'Odisha';
    }
    return statesAndUTs.contains(trimmed) ? trimmed : 'Maharashtra';
  }

  static String normalizeGender(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Male';
    final lower = raw.trim().toLowerCase();
    if (lower.startsWith('f') || lower == 'woman' || lower == 'women') {
      return 'Female';
    }
    if (lower.startsWith('m') || lower == 'man' || lower == 'men') {
      return 'Male';
    }
    return 'Other';
  }

  static String normalizeMaritalStatus(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Single';
    for (final m in maritalStatuses) {
      if (m.toLowerCase() == raw.trim().toLowerCase()) return m;
    }
    return 'Single';
  }

  static String normalizeCasteCategory(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'General';
    final upper = raw.trim().toUpperCase();
    if (upper == 'OBC') return 'OBC';
    if (upper == 'SC' || upper.contains('SCHEDULED CASTE')) return 'SC';
    if (upper == 'ST' || upper.contains('SCHEDULED TRIBE')) return 'ST';
    if (upper == 'EWS') return 'EWS';
    return 'General';
  }

  static String normalizeOccupation(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Salaried';
    final lower = raw.trim().toLowerCase();
    for (final o in occupations) {
      if (o.toLowerCase() == lower) return o;
    }
    if (lower.contains('farm') || lower.contains('agri')) return 'Farmer';
    if (lower.contains('stud')) return 'Student';
    if (lower.contains('self')) return 'Self-Employed';
    if (lower.contains('unemploy') || lower.contains('home')) {
      return 'Unemployed / Homemaker';
    }
    if (lower.contains('construct') ||
        lower.contains('labor') ||
        lower.contains('labour') ||
        lower.contains('wage')) {
      return 'Construction / Daily Wage Worker';
    }
    if (lower.contains('senior') ||
        lower.contains('retir') ||
        lower.contains('pension')) {
      return 'Senior Citizen / Retired';
    }
    if (lower.contains('busi') ||
        lower.contains('msme') ||
        lower.contains('entrepreneur')) {
      return 'Business / Entrepreneur';
    }
    return 'Salaried';
  }

  static String normalizeIncomeRange(String? raw, {double? fallbackNumeric}) {
    if (raw != null && raw.trim().isNotEmpty) {
      final trimmed = raw.trim();
      if (incomeRanges.contains(trimmed)) return trimmed;
      final lower = trimmed.toLowerCase();
      if (lower.contains('below') && lower.contains('1')) {
        return 'Below ₹1 Lakh';
      }
      if (lower.contains('1l - ₹3l') ||
          lower.contains('1l - 2.5l') ||
          lower.contains('below ₹2.5l')) {
        return '₹1L - ₹2.5L';
      }
      if (lower.contains('3l - ₹5l') || lower.contains('2.5l - ₹5l')) {
        return '₹2.5L - ₹5L';
      }
      if (lower.contains('5l - ₹10l')) {
        return '₹5L - ₹10L';
      }
      if (lower.contains('above')) {
        return 'Above ₹10 Lakh';
      }
    }
    if (fallbackNumeric != null && fallbackNumeric > 0) {
      return incomeRangeFromValue(fallbackNumeric);
    }
    return '₹1L - ₹2.5L';
  }

  static double incomeValueFromRange(String? range) {
    final normalized = normalizeIncomeRange(range);
    switch (normalized) {
      case 'Below ₹1 Lakh':
        return 80000.0;
      case '₹1L - ₹2.5L':
        return 180000.0;
      case '₹2.5L - ₹5L':
        return 350000.0;
      case '₹5L - ₹10L':
        return 750000.0;
      case 'Above ₹10 Lakh':
        return 1200000.0;
      default:
        return 180000.0;
    }
  }

  static double maxEligibleIncomeForRange(String? range) {
    final normalized = normalizeIncomeRange(range);
    switch (normalized) {
      case 'Below ₹1 Lakh':
        return 100000.0;
      case '₹1L - ₹2.5L':
        return 250000.0;
      case '₹2.5L - ₹5L':
        return 500000.0;
      case '₹5L - ₹10L':
        return 1000000.0;
      case 'Above ₹10 Lakh':
        return 50000000.0;
      default:
        return 250000.0;
    }
  }

  static String incomeRangeFromValue(double? income) {
    final val = income ?? 0.0;
    if (val <= 0) return '₹1L - ₹2.5L';
    if (val <= 100000) return 'Below ₹1 Lakh';
    if (val <= 250000) return '₹1L - ₹2.5L';
    if (val <= 500000) return '₹2.5L - ₹5L';
    if (val <= 1000000) return '₹5L - ₹10L';
    return 'Above ₹10 Lakh';
  }

  static String inferStateFromText(String text, {String level = ''}) {
    if (level.trim().toLowerCase() == 'central') {
      return 'All India';
    }
    final lower = text.toLowerCase();
    for (final state in statesAndUTs) {
      final sLower = state.toLowerCase();
      if (lower.contains(sLower)) {
        return state;
      }
    }
    if (lower.contains('pondicherry')) return 'Puducherry';
    if (lower.contains('orissa')) return 'Odisha';
    if (lower.contains('m.p.') || lower.contains('mpbocwwb')) {
      return 'Madhya Pradesh';
    }
    if (lower.contains('u.p.')) return 'Uttar Pradesh';
    return level.trim().toLowerCase() == 'state' ? 'State Specific' : 'All India';
  }
}

