import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/profile_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../models/scheme_discovery_model.dart';
import '../../../../providers/citizen_profile_provider.dart';
import '../../../../providers/language_provider.dart';
import '../../../../providers/scheme_discovery_provider.dart';
import '../../../../providers/voice_provider.dart';
import '../../../../widgets/glass_card.dart';
import '../../../../widgets/t_text.dart';

class SchemeDiscoveryScreen extends StatefulWidget {
  const SchemeDiscoveryScreen({super.key});

  @override
  State<SchemeDiscoveryScreen> createState() => _SchemeDiscoveryScreenState();
}

class _SchemeDiscoveryScreenState extends State<SchemeDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProv = context.read<CitizenProfileProvider>();
      if (profileProv.profile == null) {
        profileProv.fetchProfile();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(SchemeDiscoveryProvider provider, String val) {
    provider.searchSchemes(val);
  }

  void _voiceSearch(SchemeDiscoveryProvider provider) {
    final voice = context.read<VoiceProvider>();

    if (voice.isListening) {
      voice.stopListening();
      return;
    }

    voice.startListening(
      onFinalResult: (text) {
        if (text.isNotEmpty) {
          _searchController.text = text;
          provider.searchSchemes(text);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: TText('Searching for: "$text"'),
                backgroundColor: AppColors.gold,
              ),
            );
          }
        }
      },
    );
  }

  void _showFilterBottomSheet(
    BuildContext context,
    SchemeDiscoveryProvider provider,
  ) {
    String tempState = provider.selectedState;
    String tempLevel = provider.selectedLevel;
    String tempIncomeRange = provider.selectedIncomeRange;
    final ageCtrl = TextEditingController(
      text: provider.selectedAge != null ? provider.selectedAge.toString() : '',
    );
    String tempGender = provider.selectedGender;
    String tempCaste = provider.selectedCaste;
    String tempOccupation = provider.selectedOccupation;
    bool tempDisabled = provider.onlyForDisabled;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final lang = ctx.watch<LanguageProvider>();
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: const BoxDecoration(
                color: AppColors.bgDeep,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: AppColors.surfaceBorder),
                  left: BorderSide(color: AppColors.surfaceBorder),
                  right: BorderSide(color: AppColors.surfaceBorder),
                ),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TText(
                        'Filter Schemes',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempState = 'All States';
                            tempLevel = 'All';
                            tempIncomeRange = 'All';
                            ageCtrl.clear();
                            tempGender = 'All';
                            tempCaste = 'All';
                            tempOccupation = 'All';
                            tempDisabled = false;
                          });
                        },
                        child: TText(
                          'Reset All',
                          style: GoogleFonts.poppins(
                            color: AppColors.saffron,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.surfaceBorder),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFilterLabel('Scheme Level'),
                          const SizedBox(height: 8),
                          Row(
                            children: ['All', 'Central', 'State'].map((lvl) {
                              final selected = tempLevel == lvl;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () =>
                                        setModalState(() => tempLevel = lvl),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppColors.saffron
                                            : AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: selected
                                              ? AppColors.saffron
                                              : AppColors.surfaceBorder,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: TText(
                                        lvl == 'All'
                                            ? 'All Levels'
                                            : '$lvl Schemes',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: selected
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          _buildFilterDropdown(
                            label: 'State / Union Territory',
                            value: tempState,
                            items: [
                              'All States',
                              ...ProfileConstants.statesAndUTs
                            ],
                            lang: lang,
                            onChanged: (v) {
                              if (v != null) {
                                setModalState(() => tempState = v);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFilterLabel('Age (Years)'),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: AppColors.surfaceBorder),
                                      ),
                                      child: TextField(
                                        controller: ageCtrl,
                                        keyboardType: TextInputType.number,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        decoration: InputDecoration(
                                          hintText:
                                              lang.translateSync('Any age'),
                                          hintStyle: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 13,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: _buildFilterDropdown(
                                  label: 'Gender',
                                  value: tempGender,
                                  items: ['All', ...ProfileConstants.genders],
                                  lang: lang,
                                  onChanged: (v) {
                                    if (v != null) {
                                      setModalState(() => tempGender = v);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildFilterDropdown(
                            label: 'Annual Family Income',
                            value: tempIncomeRange,
                            items: ['All', ...ProfileConstants.incomeRanges],
                            lang: lang,
                            onChanged: (v) {
                              if (v != null) {
                                setModalState(() => tempIncomeRange = v);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFilterDropdown(
                                  label: 'Caste Category',
                                  value: tempCaste,
                                  items: [
                                    'All',
                                    ...ProfileConstants.casteCategories
                                  ],
                                  lang: lang,
                                  onChanged: (v) {
                                    if (v != null) {
                                      setModalState(() => tempCaste = v);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildFilterDropdown(
                                  label: 'Occupation',
                                  value: tempOccupation,
                                  items: [
                                    'All',
                                    ...ProfileConstants.occupations
                                  ],
                                  lang: lang,
                                  onChanged: (v) {
                                    if (v != null) {
                                      setModalState(() => tempOccupation = v);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: TText(
                              'Persons with Disability (PwD) Schemes',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: TText(
                              'Prioritize disability support and Divyangjan schemes',
                              style: GoogleFonts.poppins(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            value: tempDisabled,
                            activeThumbColor: AppColors.saffron,
                            onChanged: (v) =>
                                setModalState(() => tempDisabled = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.saffron,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        final parsedAge = int.tryParse(ageCtrl.text.trim());
                        provider.updateFilters(
                          state: tempState,
                          level: tempLevel,
                          incomeRange: tempIncomeRange,
                          age: parsedAge,
                          clearAge: parsedAge == null || parsedAge <= 0,
                          gender: tempGender,
                          caste: tempCaste,
                          occupation: tempOccupation,
                          onlyForDisabled: tempDisabled,
                        );
                        Navigator.pop(ctx);
                      },
                      child: TText(
                        'Apply Filters',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterLabel(String label) {
    return TText(
      label,
      style: GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required LanguageProvider lang,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = items.contains(value) ? value : items.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterLabel(label),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeValue,
              dropdownColor: AppColors.bgMid,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: AppColors.saffron, size: 20),
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
              items: items
                  .map((item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          lang.translateSync(item),
                          overflow: TextOverflow.ellipsis,
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

  void _showSchemeDetail(BuildContext context, SchemeDiscoveryModel scheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.bgDeep,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppColors.surfaceBorder),
              left: BorderSide(color: AppColors.surfaceBorder),
              right: BorderSide(color: AppColors.surfaceBorder),
            ),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TText(
                      scheme.shortTitle.isNotEmpty
                          ? '${scheme.title} (${scheme.shortTitle})'
                          : scheme.title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TText(
                      scheme.category,
                      style: GoogleFonts.spaceMono(
                        color: AppColors.accentBlue,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (scheme.level.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.saffron.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TText(
                        '${scheme.level} Scheme',
                        style: GoogleFonts.spaceMono(
                          color: AppColors.saffron,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  if (scheme.beneficiaryState.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TText(
                        scheme.beneficiaryState,
                        style: GoogleFonts.spaceMono(
                          color: AppColors.emerald,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.surfaceBorder),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TText(
                        'Overview',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TText(
                        scheme.description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      if (scheme.benefits.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        TText(
                          'Key Benefits',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.25),
                            ),
                          ),
                          child: TText(
                            scheme.benefits,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                      if (scheme.eligibilityCriteria.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        TText(
                          'Eligibility & Criteria',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...scheme.eligibilityCriteria.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(Icons.check_circle_outline,
                                      size: 16, color: AppColors.emerald),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TText(
                                    c,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (scheme.requiredDocuments.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        TText(
                          'Required Documents',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...scheme.requiredDocuments.map(
                          (doc) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(Icons.description_outlined,
                                      size: 16, color: AppColors.saffron),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TText(
                                    doc,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (scheme.applicationProcess.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        TText(
                          'Application Process',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TText(
                          scheme.applicationProcess,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                      if (scheme.tags.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        TText(
                          'Tags',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: scheme.tags.map((t) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: AppColors.surfaceBorder),
                              ),
                              child: TText(
                                t,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.saffron,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.push(
                              Routes.serviceDetailPath(scheme.id),
                              extra: scheme.toServiceModel(),
                            );
                          },
                          icon: const Icon(Icons.open_in_new,
                              color: Colors.white, size: 18),
                          label: TText(
                            'Open Full Application Guide',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final profileProv = context.watch<CitizenProfileProvider>();

    return Consumer<SchemeDiscoveryProvider>(
      builder: (context, provider, child) {
        final activeFilters = provider.activeFilterCount;

        return Scaffold(
          backgroundColor: AppColors.bgDeep,
          appBar: AppBar(
            backgroundColor: AppColors.bgDeep,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            title: TText(
              'Scheme Discovery',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.saffron,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: lang.translateSync('Smart Eligibility Matcher'),
                icon: const Icon(Icons.auto_awesome, color: AppColors.gold),
                onPressed: () => context.push(Routes.recommendations),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Search Bar + Voice + Filter Button
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.bgMid,
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: lang.translateSync(
                                  'Search 3,400+ schemes by keyword, state...'),
                              hintStyle:
                                  const TextStyle(color: AppColors.textMuted),
                              border: InputBorder.none,
                              prefixIcon: const Icon(Icons.search,
                                  color: AppColors.accentBlue),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear,
                                          color: AppColors.textMuted, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearch(provider, '');
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (v) {
                              _onSearch(provider, v);
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _voiceSearch(provider),
                        child: Consumer<VoiceProvider>(
                          builder: (context, voice, _) {
                            final isListening = voice.isListening;
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isListening
                                    ? AppColors.gold.withValues(alpha: 0.3)
                                    : AppColors.gold.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isListening
                                      ? Colors.white
                                      : AppColors.gold,
                                  width: isListening ? 2 : 1,
                                ),
                              ),
                              child: Icon(
                                isListening ? Icons.mic : Icons.mic_none,
                                color: isListening
                                    ? Colors.white
                                    : AppColors.gold,
                              ),
                            ).animate(target: isListening ? 1 : 0).shimmer(
                                  duration: 1000.ms,
                                  color: Colors.white24,
                                );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () =>
                            _showFilterBottomSheet(context, provider),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: activeFilters > 0
                                    ? AppColors.saffron.withValues(alpha: 0.2)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: activeFilters > 0
                                      ? AppColors.saffron
                                      : AppColors.surfaceBorder,
                                ),
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                color: activeFilters > 0
                                    ? AppColors.saffron
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if (activeFilters > 0)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: AppColors.saffron,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$activeFilters',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Quick Profile Match + Level Filter Row
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (profileProv.profile == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: TText(
                                    'Complete your Citizen Profile first or use the Filter button.'),
                              ),
                            );
                            return;
                          }
                          provider.toggleMatchMyProfile(profileProv.profile);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: provider.matchMyProfile
                                ? AppColors.emerald.withValues(alpha: 0.25)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: provider.matchMyProfile
                                  ? AppColors.emerald
                                  : AppColors.surfaceBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                provider.matchMyProfile
                                    ? Icons.verified_user
                                    : Icons.person_pin_circle_outlined,
                                size: 15,
                                color: provider.matchMyProfile
                                    ? AppColors.emeraldLight
                                    : AppColors.gold,
                              ),
                              const SizedBox(width: 6),
                              TText(
                                'Match My Profile',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: provider.matchMyProfile
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (provider.selectedState != 'All States')
                        _buildActiveFilterChip(
                          label: provider.selectedState,
                          onClear: () =>
                              provider.updateFilters(state: 'All States'),
                        ),
                      if (provider.selectedLevel != 'All')
                        _buildActiveFilterChip(
                          label: '${provider.selectedLevel} Schemes',
                          onClear: () => provider.updateFilters(level: 'All'),
                        ),
                      if (provider.selectedAge != null)
                        _buildActiveFilterChip(
                          label: 'Age: ${provider.selectedAge} yrs',
                          onClear: () => provider.updateFilters(clearAge: true),
                        ),
                      if (provider.selectedIncomeRange != 'All')
                        _buildActiveFilterChip(
                          label: provider.selectedIncomeRange,
                          onClear: () =>
                              provider.updateFilters(incomeRange: 'All'),
                        ),
                      if (provider.selectedGender != 'All')
                        _buildActiveFilterChip(
                          label: provider.selectedGender,
                          onClear: () => provider.updateFilters(gender: 'All'),
                        ),
                      if (provider.selectedCaste != 'All')
                        _buildActiveFilterChip(
                          label: provider.selectedCaste,
                          onClear: () => provider.updateFilters(caste: 'All'),
                        ),
                      if (provider.selectedOccupation != 'All')
                        _buildActiveFilterChip(
                          label: provider.selectedOccupation,
                          onClear: () =>
                              provider.updateFilters(occupation: 'All'),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Category Filters
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: provider.categories.length,
                    itemBuilder: (context, index) {
                      final cat = provider.categories[index];
                      final isSelected =
                          provider.currentCategoryFilter == cat;
                      return GestureDetector(
                        onTap: () => provider.filterByCategory(cat),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.saffron
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.saffron
                                  : AppColors.surfaceBorder,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: TText(
                            cat,
                            style: GoogleFonts.poppins(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Results count + Clear Filters action
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TText(
                        '${provider.filteredSchemes.length} schemes found',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      if (activeFilters > 0 ||
                          provider.currentCategoryFilter != 'All' ||
                          provider.currentSearchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            provider.clearAllFilters();
                            setState(() {});
                          },
                          child: TText(
                            'Clear Filters',
                            style: GoogleFonts.poppins(
                              color: AppColors.saffron,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Schemes List
                Expanded(
                  child: provider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accentBlue))
                      : provider.filteredSchemes.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.search_off_rounded,
                                      size: 48, color: AppColors.textMuted),
                                  const SizedBox(height: 12),
                                  TText(
                                    'No schemes match the current filters.',
                                    style: GoogleFonts.poppins(
                                        color: AppColors.textMuted),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      provider.clearAllFilters();
                                      setState(() {});
                                    },
                                    child: const TText('Reset All Filters'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              itemCount: provider.filteredSchemes.length,
                              itemBuilder: (context, index) {
                                final scheme =
                                    provider.filteredSchemes[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: GestureDetector(
                                    onTap: () =>
                                        _showSchemeDetail(context, scheme),
                                    child: GlassCard(
                                      padding: const EdgeInsets.all(18),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Wrap(
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .accentBlue
                                                            .withValues(
                                                                alpha: 0.2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      child: TText(
                                                        scheme.category,
                                                        style: GoogleFonts
                                                            .spaceMono(
                                                          color: AppColors
                                                              .accentBlue,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ),
                                                    if (scheme.level.isNotEmpty)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 3),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppColors
                                                              .saffron
                                                              .withValues(
                                                                  alpha: 0.15),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: TText(
                                                          scheme.level,
                                                          style: GoogleFonts
                                                              .spaceMono(
                                                            color: AppColors
                                                                .saffron,
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                      ),
                                                    if (scheme.beneficiaryState
                                                            .isNotEmpty &&
                                                        scheme.beneficiaryState !=
                                                            'All India')
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 3),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppColors
                                                              .emerald
                                                              .withValues(
                                                                  alpha: 0.15),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: TText(
                                                          scheme
                                                              .beneficiaryState,
                                                          style: GoogleFonts
                                                              .spaceMono(
                                                            color: AppColors
                                                                .emeraldLight,
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(
                                                Icons.arrow_forward_ios,
                                                size: 13,
                                                color: AppColors.textMuted,
                                              )
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          TText(
                                            scheme.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.playfairDisplay(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          TText(
                                            scheme.description,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                          if (scheme.eligibilityCriteria
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            const Divider(
                                                color: AppColors.surfaceBorder),
                                            const SizedBox(height: 6),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 2),
                                                  child: Icon(
                                                    Icons.check_circle_outline,
                                                    color: AppColors.emerald,
                                                    size: 14,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: TText(
                                                    'Eligibility: ${scheme.eligibilityCriteria.join(' | ')}',
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.inter(
                                                      color:
                                                          AppColors.textMuted,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required VoidCallback onClear,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.saffron.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.saffron.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TText(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close, size: 14, color: AppColors.saffron),
          ),
        ],
      ),
    );
  }
}
