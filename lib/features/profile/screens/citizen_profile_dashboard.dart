import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/profile_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../models/citizen_profile_model.dart';
import '../../../../providers/citizen_profile_provider.dart';
import '../../../../providers/language_provider.dart';
import '../../../../providers/user_provider.dart';
import '../../../../widgets/glass_card.dart';
import '../../../../widgets/t_text.dart';

class CitizenProfileDashboard extends StatefulWidget {
  const CitizenProfileDashboard({super.key});

  @override
  State<CitizenProfileDashboard> createState() =>
      _CitizenProfileDashboardState();
}

class _CitizenProfileDashboardState extends State<CitizenProfileDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<CitizenProfileProvider>().profile == null) {
        context.read<CitizenProfileProvider>().fetchProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CitizenProfileProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: TText(
          'Citizen Digital Profile',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.saffron,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.saffron),
            tooltip: 'Full Edit Profile',
            onPressed: () => context.push(Routes.profileEdit),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.saffron),
            onPressed: () => provider.fetchProfile(),
          ),
        ],
        centerTitle: true,
      ),
      body: SafeArea(
        child: provider.isLoading && provider.profile == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.saffron),
              )
            : provider.profile == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const TText(
                          'Profile data not found.',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.fetchProfile(),
                          child: const TText('Retry Fetch'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderCard(context, provider.profile!),
                        const SizedBox(height: 32),
                        TText(
                          'Digital Identity',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildIdentitySection(context, provider),
                        const SizedBox(height: 32),
                        TText(
                          'History Highlights',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildHistorySection(provider.profile!),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, CitizenProfileModel profile) {
    final initial = profile.fullName.trim().isNotEmpty
        ? profile.fullName.trim().substring(0, 1).toUpperCase()
        : 'C';
    final locationParts = [
      if (profile.district != null && profile.district!.trim().isNotEmpty)
        profile.district!.trim(),
      if (profile.state.trim().isNotEmpty) profile.state.trim(),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.saffron, AppColors.gold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TText(
                      locationParts.isEmpty
                          ? 'India'
                          : locationParts.join(', '),
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _tag('${profile.computedAge} Years'),
                        _tag(profile.effectiveIncomeRange),
                        if (profile.gender != null &&
                            profile.gender!.isNotEmpty)
                          _tag(profile.gender!),
                        if (profile.casteCategory != null &&
                            profile.casteCategory!.isNotEmpty)
                          _tag(profile.casteCategory!),
                        if (profile.occupation != null &&
                            profile.occupation!.isNotEmpty)
                          _tag(profile.occupation!),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: profile.isKycVerified
                            ? AppColors.emeraldLight.withValues(alpha: 0.1)
                            : AppColors.semanticError.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: profile.isKycVerified
                              ? AppColors.emeraldLight
                              : AppColors.semanticError,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            profile.isKycVerified
                                ? Icons.verified
                                : Icons.warning,
                            color: profile.isKycVerified
                                ? AppColors.emeraldLight
                                : AppColors.semanticError,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          TText(
                            profile.isKycVerified
                                ? 'KYC Verified'
                                : 'KYC Pending',
                            style: GoogleFonts.inter(
                              color: profile.isKycVerified
                                  ? AppColors.emeraldLight
                                  : AppColors.semanticError,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.surfaceBorder),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _showEditDialog(
                  context,
                  context.read<CitizenProfileProvider>(),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.tune_rounded,
                      color: AppColors.gold,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    TText(
                      'Quick Edit Criteria',
                      style: GoogleFonts.inter(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push(Routes.profileEdit),
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_note,
                      color: AppColors.saffron,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    TText(
                      'Edit Full Profile',
                      style: GoogleFonts.inter(
                        color: AppColors.saffron,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              if (profile.mobile.isNotEmpty)
                _contactInfo(Icons.phone, profile.mobile),
              if (profile.email.isNotEmpty)
                _contactInfo(Icons.email, profile.email),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 0.1, end: 0);
  }

  void _showEditDialog(BuildContext context, CitizenProfileProvider provider) {
    final current = provider.profile!;
    final ageCtrl = TextEditingController(
      text: current.computedAge.toString(),
    );
    String selectedState = ProfileConstants.normalizeState(current.state);
    String selectedIncomeRange = current.effectiveIncomeRange;
    String selectedCaste =
        ProfileConstants.normalizeCasteCategory(current.casteCategory);
    String selectedOccupation =
        ProfileConstants.normalizeOccupation(current.occupation);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final lang = ctx.watch<LanguageProvider>();
          return AlertDialog(
            backgroundColor: AppColors.bgMid,
            title: TText(
              'Update Profile Criteria',
              style: GoogleFonts.playfairDisplay(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ageCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: lang.translateSync('Age (Years)'),
                      labelStyle: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedState,
                    isExpanded: true,
                    dropdownColor: AppColors.bgMid,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: lang.translateSync('State / UT'),
                      labelStyle: const TextStyle(color: AppColors.textMuted),
                    ),
                    items: ProfileConstants.statesAndUTs
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(lang.translateSync(s)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedState = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedIncomeRange,
                    isExpanded: true,
                    dropdownColor: AppColors.bgMid,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: lang.translateSync('Annual Income Range'),
                      labelStyle: const TextStyle(color: AppColors.textMuted),
                    ),
                    items: ProfileConstants.incomeRanges
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(lang.translateSync(r)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedIncomeRange = v);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCaste,
                    isExpanded: true,
                    dropdownColor: AppColors.bgMid,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: lang.translateSync('Caste Category'),
                      labelStyle: const TextStyle(color: AppColors.textMuted),
                    ),
                    items: ProfileConstants.casteCategories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(lang.translateSync(c)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedCaste = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedOccupation,
                    isExpanded: true,
                    dropdownColor: AppColors.bgMid,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: lang.translateSync('Occupation'),
                      labelStyle: const TextStyle(color: AppColors.textMuted),
                    ),
                    items: ProfileConstants.occupations
                        .map(
                          (o) => DropdownMenuItem(
                            value: o,
                            child: Text(lang.translateSync(o)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedOccupation = v);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const TText('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final parsedAge =
                      int.tryParse(ageCtrl.text.trim()) ?? current.computedAge;
                  final syncedIncome = ProfileConstants.incomeValueFromRange(
                    selectedIncomeRange,
                  );
                  final updated = current.copyWith(
                    age: parsedAge,
                    dateOfBirth: DateTime(
                      DateTime.now().year - parsedAge.clamp(1, 110),
                      current.dateOfBirth?.month ?? 1,
                      current.dateOfBirth?.day ?? 1,
                    ),
                    state: selectedState,
                    annualIncomeRange: selectedIncomeRange,
                    income: syncedIncome,
                    casteCategory: selectedCaste,
                    occupation: selectedOccupation,
                  );
                  await provider.updateProfile(updated);
                  if (context.mounted) {
                    context
                        .read<UserProvider>()
                        .syncFromCitizenProfile(updated);
                  }
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                child: const TText('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.bgMid,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: TText(
        label,
        style: GoogleFonts.inter(
          color: AppColors.gold,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _contactInfo(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.accentBlue),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildIdentitySection(
    BuildContext context,
    CitizenProfileProvider provider,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          ...provider.profile!.linkedDocuments.map(
            (doc) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const Icon(Icons.credit_card, color: AppColors.textMuted),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TText(
                      doc,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.emeraldLight,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: AppColors.surfaceBorder),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push(Routes.documentVault),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: AppColors.saffron, size: 20),
                const SizedBox(width: 8),
                TText(
                  'Open Secure Document Vault',
                  style: GoogleFonts.poppins(
                    color: AppColors.saffron,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildHistorySection(CitizenProfileModel profile) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: AppColors.accentBlue),
              const SizedBox(width: 12),
              TText(
                'Previously Applied Schemes',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: profile.appliedSchemes
                .map<Widget>(
                  (scheme) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgDeep,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: TText(
                      scheme,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}
