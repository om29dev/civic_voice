import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/profile_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/dynamodb_scheme_discovery_service.dart';
import '../../../models/citizen_profile_model.dart';
import '../../../models/scheme_discovery_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/citizen_profile_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/t_text.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final _ageController = TextEditingController(text: '30');

  String _selectedState = 'Maharashtra';
  String _selectedIncomeRange = ProfileConstants.incomeRanges[1];
  String _selectedGender = ProfileConstants.genders.first;
  String _selectedCaste = ProfileConstants.casteCategories.first;
  String _selectedOccupation = ProfileConstants.occupations.first;
  bool _isDisabled = false;

  bool _isMatching = false;
  bool _showResults = false;
  List<SchemeDiscoveryModel> _matchedSchemes = [];
  String _selectedCategory = 'All';

  final List<String> _categories = const [
    'All',
    'Agriculture',
    'Health',
    'Education',
    'Finance',
    'Business',
    'Housing',
    'Women & Child',
    'Skills & Employment',
    'Social Welfare',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateFromProfile();
    });
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _hydrateFromProfile() async {
    final profileProv = context.read<CitizenProfileProvider>();
    if (profileProv.profile == null) {
      await profileProv.fetchProfile();
    }
    if (!mounted) return;
    final profile = profileProv.profile;
    if (profile != null) {
      setState(() {
        final age = profile.computedAge > 0 ? profile.computedAge : 30;
        _ageController.text = age.toString();
        _selectedState = ProfileConstants.normalizeState(profile.state);
        _selectedIncomeRange =
            ProfileConstants.normalizeIncomeRange(profile.effectiveIncomeRange);
        _selectedGender = ProfileConstants.normalizeGender(profile.gender);
        _selectedCaste =
            ProfileConstants.normalizeCasteCategory(profile.casteCategory);
        _selectedOccupation =
            ProfileConstants.normalizeOccupation(profile.occupation);
        _isDisabled = profile.isDisabled;
      });
    }
  }

  Future<void> _findMatches() async {
    final age = int.tryParse(_ageController.text.trim()) ?? 30;
    final maxEligibleIncome =
        ProfileConstants.maxEligibleIncomeForRange(_selectedIncomeRange);
    final representativeIncome =
        ProfileConstants.incomeValueFromRange(_selectedIncomeRange);

    setState(() {
      _isMatching = true;
      _showResults = false;
    });

    // Sync updated demographic criteria back to CitizenProfileProvider & UserProvider
    final profileProv = context.read<CitizenProfileProvider>();
    final userProv = context.read<UserProvider>();
    final authProv = context.read<AuthProvider>();

    final existing = profileProv.profile;
    final updatedProfile = (existing ??
            CitizenProfileModel(
              id: authProv.currentUser?.id ?? 'local_citizen',
              fullName: authProv.currentUser?.name ?? 'Citizen',
              gender: _selectedGender,
              maritalStatus: 'Single',
              mobile: authProv.currentUser?.mobile ?? '',
              email: authProv.currentUser?.email ?? '',
              district: '',
              state: _selectedState,
              pincode: '',
              occupation: _selectedOccupation,
              annualIncomeRange: _selectedIncomeRange,
              casteCategory: _selectedCaste,
              isDisabled: _isDisabled,
              age: age,
              income: representativeIncome,
            ))
        .copyWith(
      state: _selectedState,
      age: age,
      annualIncomeRange: _selectedIncomeRange,
      income: representativeIncome,
      gender: _selectedGender,
      casteCategory: _selectedCaste,
      occupation: _selectedOccupation,
      isDisabled: _isDisabled,
    );

    await profileProv.updateProfile(updatedProfile);
    userProv.syncFromCitizenProfile(updatedProfile);

    await DynamoDbSchemeDiscoveryService.loadSchemes();
    await Future.delayed(600.ms);

    if (!mounted) return;
    final matches = DynamoDbSchemeDiscoveryService.findDiscoveryMatches(
      age: age,
      income: maxEligibleIncome,
      state: _selectedState,
      gender: _selectedGender,
      casteCategory: _selectedCaste,
      occupation: _selectedOccupation,
      isDisabled: _isDisabled,
      limit: 150,
    );

    setState(() {
      _matchedSchemes = matches;
      _isMatching = false;
      _showResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              AppColors.saffron.withValues(alpha: 0.05),
              AppColors.bgDeep,
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: 400.ms,
            child: _isMatching
                ? _buildMatchingView()
                : (_showResults ? _buildResultsView() : _buildFormView()),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    final lang = context.watch<LanguageProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TText(
                  'Smart Eligibility Matcher',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => context.push(Routes.schemeDiscovery),
                icon: const Icon(Icons.travel_explore_rounded,
                    color: AppColors.saffron, size: 18),
                label: TText(
                  'Full Directory',
                  style: GoogleFonts.poppins(
                    color: AppColors.saffron,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn().slideX(begin: -0.05),
          const SizedBox(height: 8),
          TText(
            'Match your demographic profile against 3,400+ Central and State welfare schemes.',
            style:
                GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 13),
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDropdownField(
                  label: 'State / Union Territory',
                  icon: Icons.location_on_outlined,
                  value: _selectedState,
                  items: ProfileConstants.statesAndUTs,
                  lang: lang,
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedState = v);
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildInputField(
                        label: 'Current Age',
                        controller: _ageController,
                        icon: Icons.cake_outlined,
                        hint: 'e.g. 28',
                        keyboard: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _buildDropdownField(
                        label: 'Gender',
                        icon: Icons.person_outline,
                        value: _selectedGender,
                        items: ProfileConstants.genders,
                        lang: lang,
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedGender = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildDropdownField(
                  label: 'Annual Family Income',
                  icon: Icons.currency_rupee_rounded,
                  value: _selectedIncomeRange,
                  items: ProfileConstants.incomeRanges,
                  lang: lang,
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedIncomeRange = v);
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Caste Category',
                        icon: Icons.groups_outlined,
                        value: _selectedCaste,
                        items: ProfileConstants.casteCategories,
                        lang: lang,
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedCaste = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Occupation',
                        icon: Icons.work_outline,
                        value: _selectedOccupation,
                        items: ProfileConstants.occupations,
                        lang: lang,
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedOccupation = v);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: TText(
                    'Person with Disability (PwD / Divyangjan)',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  value: _isDisabled,
                  activeThumbColor: AppColors.saffron,
                  onChanged: (v) => setState(() => _isDisabled = v),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.saffron,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: AppColors.saffron.withValues(alpha: 0.5),
                    ),
                    onPressed: _findMatches,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.white),
                        const SizedBox(width: 10),
                        TText(
                          'Find Eligible Schemes',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          _buildInfoNote(),
        ],
      ),
    );
  }

  Widget _buildMatchingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.saffron, width: 2),
            ),
            child: const Center(
              child: Icon(Icons.search, size: 56, color: AppColors.saffron),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                  begin: const Offset(0.85, 0.85),
                  end: const Offset(1.15, 1.15),
                  duration: 900.ms,
                  curve: Curves.easeInOut)
              .fadeOut(delay: 700.ms),
          const SizedBox(height: 36),
          TText(
            'Analyzing Bharat Scheme Knowledge Base...',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          TText(
            'Matching your profile with 3,400+ Central and State schemes',
            style:
                GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    final lang = context.watch<LanguageProvider>();

    final filtered = _matchedSchemes.where((s) {
      if (_selectedCategory == 'All') return true;
      final cat = s.category.toLowerCase();
      final filter = _selectedCategory.toLowerCase();
      if (filter == 'women & child') return cat.contains('women');
      if (filter == 'skills & employment') {
        return cat.contains('skill') || cat.contains('employ');
      }
      if (filter == 'social welfare') return cat.contains('social');
      if (filter == 'finance') {
        return cat.contains('bank') || cat.contains('financ');
      }
      return cat.contains(filter);
    }).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 100,
          floating: false,
          pinned: true,
          backgroundColor: AppColors.bgDeep,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => setState(() => _showResults = false),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => context.push(Routes.schemeDiscovery),
              icon: const Icon(Icons.list_alt_rounded,
                  color: AppColors.gold, size: 18),
              label: TText(
                'Browse All',
                style: GoogleFonts.poppins(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: TText(
              'Matched Schemes (${filtered.length})',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_outlined,
                          color: AppColors.emeraldLight, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TText(
                          '$_selectedState | ${_ageController.text} yrs | $_selectedGender | $_selectedCaste | $_selectedOccupation',
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary, fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _showResults = false),
                        child: TText(
                          'Edit Criteria',
                          style: GoogleFonts.poppins(
                            color: AppColors.saffron,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.bgMid,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      dropdownColor: AppColors.bgMid,
                      icon: const Icon(Icons.filter_list,
                          color: AppColors.saffron),
                      isExpanded: true,
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 14),
                      items: _categories.map((String cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(lang.translateSync(cat)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (filtered.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sentiment_dissatisfied,
                      size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  TText(
                    'No schemes found for "$_selectedCategory".',
                    style: GoogleFonts.poppins(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      if (_selectedCategory != 'All') {
                        setState(() => _selectedCategory = 'All');
                      } else {
                        setState(() => _showResults = false);
                      }
                    },
                    child: const TText('Show All Matched Categories'),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _RecommendationCard(
                  scheme: filtered[index],
                  index: index,
                  selectedState: _selectedState,
                ),
                childCount: filtered.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TText(
          label,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboard,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              prefixIcon: Icon(icon, color: AppColors.saffron, size: 18),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required LanguageProvider lang,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = items.contains(value) ? value : items.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TText(
          label,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeValue,
              dropdownColor: AppColors.bgMid,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: AppColors.saffron, size: 18),
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
              items: items
                  .map((item) => DropdownMenuItem<String>(
                        value: item,
                        child: Row(
                          children: [
                            Icon(icon, color: AppColors.saffron, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lang.translateSync(item),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.accentBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TText(
              'Your criteria are saved to your Citizen Profile and matched locally against 3,400+ verified Central and State schemes.',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }
}

class _RecommendationCard extends StatelessWidget {
  final SchemeDiscoveryModel scheme;
  final int index;
  final String selectedState;

  const _RecommendationCard({
    required this.scheme,
    required this.index,
    required this.selectedState,
  });

  @override
  Widget build(BuildContext context) {
    final isStateSpecific = scheme.beneficiaryState.toLowerCase() ==
        selectedState.toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.bgMid,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: InkWell(
        onTap: () => context.push(
          Routes.serviceDetailPath(scheme.id),
          extra: scheme.toServiceModel(),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.saffron.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.saffron.withValues(alpha: 0.3)),
                      ),
                      child: TText(
                        scheme.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.saffron,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isStateSpecific
                          ? AppColors.emerald.withValues(alpha: 0.15)
                          : AppColors.accentBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TText(
                      isStateSpecific
                          ? scheme.beneficiaryState
                          : '${scheme.level} Scheme',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isStateSpecific
                            ? AppColors.emeraldLight
                            : AppColors.accentBlue,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.verified,
                      color: AppColors.emerald, size: 18),
                ],
              ),
              const SizedBox(height: 12),
              TText(
                scheme.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              TText(
                scheme.benefits.isNotEmpty
                    ? scheme.benefits
                    : scheme.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppColors.gold, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TText(
                      scheme.eligibilityCriteria.isNotEmpty
                          ? scheme.eligibilityCriteria.first
                          : 'Verified Match',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TText(
                    'View Guide',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.saffron,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: (index % 8) * 60))
        .slideY(begin: 0.08, end: 0);
  }
}
