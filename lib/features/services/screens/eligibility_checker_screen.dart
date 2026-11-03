import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/profile_constants.dart';
import '../../../../models/service_model.dart';
import '../../../../providers/citizen_profile_provider.dart';
import '../../../../providers/language_provider.dart';
import '../../../../providers/user_provider.dart';
import '../../../../widgets/glass_card.dart';
import '../../../../widgets/t_text.dart';

class EligibilityCheckerScreen extends StatefulWidget {
  final ServiceModel service;

  const EligibilityCheckerScreen({super.key, required this.service});

  @override
  State<EligibilityCheckerScreen> createState() =>
      _EligibilityCheckerScreenState();
}

class _EligibilityCheckerScreenState extends State<EligibilityCheckerScreen> {
  final PageController _pageController = PageController();
  late final TextEditingController _ageCtrl;
  int _currentStep = 0;
  final int _totalSteps = 5;

  int? _age;
  String? _state;
  String? _income;
  String? _category;
  final List<String> _documents = [];

  @override
  void initState() {
    super.initState();
    final profile = context.read<CitizenProfileProvider>().profile;
    _age = profile?.computedAge ?? 25;
    _ageCtrl = TextEditingController(text: (_age != null && _age! > 0) ? '$_age' : '');
    _state = ProfileConstants.normalizeState(profile?.state);
    _income = ProfileConstants.normalizeIncomeRange(
      profile?.effectiveIncomeRange,
    );
    _category =
        ProfileConstants.normalizeCasteCategory(profile?.casteCategory);
    if (profile != null) {
      if (profile.aadhaarLastFour != null ||
          profile.linkedDocuments.any(
            (d) => d.toLowerCase().contains('aadhaar'),
          )) {
        _documents.add('Aadhaar Card');
      }
      if (profile.panMasked != null ||
          profile.linkedDocuments.any((d) => d.toLowerCase().contains('pan'))) {
        _documents.add('PAN Card');
      }
      if (profile.rationCardNumber != null) {
        _documents.add('Ration Card');
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _showResult();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _showResult() async {
    final profileProvider = context.read<CitizenProfileProvider>();
    final userProvider = context.read<UserProvider>();
    final current = profileProvider.profile;
    if (current != null) {
      final selectedRange = _income ?? current.effectiveIncomeRange;
      final updated = current.copyWith(
        age: _age ?? current.computedAge,
        state: _state ?? current.state,
        annualIncomeRange: selectedRange,
        income: ProfileConstants.incomeValueFromRange(selectedRange),
        casteCategory: _category ?? current.casteCategory,
      );
      await profileProvider.updateProfile(updated);
      userProvider.syncFromCitizenProfile(updated);
    }
    if (!mounted) return;
    setState(() {
      _currentStep = _totalSteps;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == _totalSteps) {
      return _buildResultScreen();
    }

    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            if (_currentStep > 0) {
              _prevStep();
            } else {
              context.pop();
            }
          },
        ),
        title: TText(
          'Eligibility Check',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.saffron,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  backgroundColor: AppColors.bgMid,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.saffron),
                  minHeight: 8,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TText(
                    'Step ${_currentStep + 1} of $_totalSteps',
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Flexible(
                    child: TText(
                      widget.service.localizedName(lang.languageCode),
                      style: GoogleFonts.poppins(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  _buildAgeStep(lang),
                  _buildStateStep(lang),
                  _buildIncomeStep(),
                  _buildCategoryStep(),
                  _buildDocumentsStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _prevStep,
                      child: TText(
                        'Back',
                        style: GoogleFonts.poppins(
                          color: AppColors.textMuted,
                          fontSize: 16,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.saffron,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: TText(
                      _currentStep == _totalSteps - 1
                          ? 'Check Eligibility'
                          : 'Next',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeStep(LanguageProvider lang) {
    return _StepContent(
      title: 'What is your age?',
      subtitle: 'Some services and schemes have age eligibility criteria.',
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          controller: _ageCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 24),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: lang.translateSync('Enter age e.g. 25'),
            hintStyle: const TextStyle(color: AppColors.textMuted),
          ),
          onChanged: (val) => _age = int.tryParse(val),
        ),
      ),
    );
  }

  Widget _buildStateStep(LanguageProvider lang) {
    final states = ProfileConstants.statesAndUTs;
    final currentState = (_state != null && states.contains(_state))
        ? _state!
        : 'Maharashtra';
    return _StepContent(
      title: 'Which State or UT do you reside in?',
      subtitle: 'Central and State welfare schemes vary by domicile.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bgMid,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentBlue, width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentState,
                isExpanded: true,
                dropdownColor: AppColors.bgMid,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.saffron,
                ),
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                items: states
                    .map(
                      (s) => DropdownMenuItem<String>(
                        value: s,
                        child: Text(lang.translateSync(s)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _state = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          TText(
            'Popular States',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...[
            'Maharashtra',
            'Delhi',
            'Uttar Pradesh',
            'Karnataka',
            'Tamil Nadu',
            'Gujarat',
            'Rajasthan',
            'West Bengal',
          ].map(
            (s) => _ChoiceTile(
              title: s,
              isSelected: _state == s,
              onTap: () => setState(() => _state = s),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeStep() {
    final brackets = ProfileConstants.incomeRanges;
    return _StepContent(
      title: 'Annual Family Income?',
      subtitle: 'Required for financial aid, subsidies, and EWS/BPL benefits.',
      child: Column(
        children: brackets
            .map(
              (b) => _ChoiceTile(
                title: b,
                isSelected: _income == b,
                onTap: () => setState(() => _income = b),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCategoryStep() {
    final categories = ProfileConstants.casteCategories;
    return _StepContent(
      title: 'Select your Category',
      subtitle: 'Reservation and targeted welfare benefits apply by category.',
      child: Column(
        children: categories
            .map(
              (c) => _ChoiceTile(
                title: c,
                isSelected: _category == c,
                onTap: () => setState(() => _category = c),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDocumentsStep() {
    final docs = [
      'Aadhaar Card',
      'PAN Card',
      'Income Certificate',
      'Caste Certificate',
      'Ration Card',
      'Domicile Certificate',
    ];
    return _StepContent(
      title: 'Which documents do you have?',
      subtitle: 'Select all supporting documents you currently possess.',
      child: Column(
        children: docs.map((d) {
          final isSelected = _documents.contains(d);
          return _ChoiceTile(
            title: d,
            isSelected: isSelected,
            isMulti: true,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _documents.remove(d);
                } else {
                  _documents.add(d);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultScreen() {
    final lang = context.watch<LanguageProvider>();
    final ageVal = _age ?? int.tryParse(_ageCtrl.text.trim()) ?? 25;
    final isEligible = ageVal >= 18;
    final serviceName = widget.service.localizedName(lang.languageCode);

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isEligible
                      ? AppColors.emeraldLight.withValues(alpha: 0.1)
                      : AppColors.semanticError.withValues(alpha: 0.1),
                ),
                child: Icon(
                  isEligible
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: isEligible
                      ? AppColors.emeraldLight
                      : AppColors.semanticError,
                  size: 64,
                ),
              ).animate().scale(curve: Curves.easeOutBack, duration: 600.ms),
              const SizedBox(height: 24),
              TText(
                isEligible ? 'You are Eligible!' : 'Not Eligible',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: isEligible
                      ? AppColors.emeraldLight
                      : AppColors.semanticError,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              TText(
                isEligible
                    ? 'Based on the details provided ($_state, $_income, $_category), you meet the criteria to apply for $serviceName.'
                    : 'Your profile does not meet the minimum age requirement (18+) for $serviceName.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 48),
              if (isEligible)
                ElevatedButton(
                  onPressed: () {
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: TText('Eligibility saved to your profile.'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.saffron,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: TText(
                    'Continue to Application',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms)
              else
                OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.saffron),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: TText(
                    'Explore Alternatives',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.saffron,
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepContent extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _StepContent({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TText(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TText(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          child,
        ],
      ).animate().fadeIn().slideX(begin: 0.1, end: 0, duration: 300.ms),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isMulti;

  const _ChoiceTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.isMulti = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentBlue.withValues(alpha: 0.1)
              : AppColors.bgMid.withValues(alpha: 0.5),
          border: Border.all(
            color: isSelected ? AppColors.accentBlue : AppColors.surfaceBorder,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isMulti
                  ? (isSelected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded)
                  : (isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded),
              color: isSelected ? AppColors.accentBlue : AppColors.textMuted,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TText(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
