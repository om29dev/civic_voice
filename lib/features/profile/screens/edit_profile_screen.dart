import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/profile_constants.dart';
import '../../../providers/citizen_profile_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../widgets/cvi_button.dart';
import '../../../widgets/decorative/jali_pattern.dart';
import '../../../widgets/indian_card.dart';
import '../../../widgets/t_text.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _pincodeCtrl;
  late final TextEditingController _aadhaarCtrl;
  late final TextEditingController _panCtrl;
  late final TextEditingController _rationCtrl;
  late final TextEditingController _disabilityCtrl;

  DateTime? _dob;
  String? _gender;
  String? _maritalStatus;
  String? _occupation;
  String? _incomeRange;
  String? _casteCategory;
  String? _state;
  bool _isDisabled = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<CitizenProfileProvider>().profile;
    _nameCtrl = TextEditingController(text: p?.fullName ?? '');
    final initialAge = p?.computedAge ?? p?.age ?? 25;
    _ageCtrl = TextEditingController(
      text: initialAge > 0 ? initialAge.toString() : '',
    );
    _districtCtrl = TextEditingController(text: p?.district ?? '');
    _pincodeCtrl = TextEditingController(text: p?.pincode ?? '');
    _aadhaarCtrl = TextEditingController(text: p?.aadhaarLastFour ?? '');
    _panCtrl = TextEditingController(text: p?.panMasked ?? '');
    _rationCtrl = TextEditingController(text: p?.rationCardNumber ?? '');
    _disabilityCtrl = TextEditingController(text: p?.disabilityType ?? '');
    _dob = p?.dateOfBirth;
    _gender = ProfileConstants.normalizeGender(p?.gender);
    _maritalStatus = ProfileConstants.normalizeMaritalStatus(p?.maritalStatus);
    _occupation = ProfileConstants.normalizeOccupation(p?.occupation);
    _incomeRange = ProfileConstants.normalizeIncomeRange(
      p?.effectiveIncomeRange,
    );
    _casteCategory = ProfileConstants.normalizeCasteCategory(p?.casteCategory);
    _state = (p?.state.isNotEmpty == true)
        ? ProfileConstants.normalizeState(p!.state)
        : 'Maharashtra';
    _isDisabled = p?.isDisabled ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _districtCtrl.dispose();
    _pincodeCtrl.dispose();
    _aadhaarCtrl.dispose();
    _panCtrl.dispose();
    _rationCtrl.dispose();
    _disabilityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final provider = context.read<CitizenProfileProvider>();
    final userProvider = context.read<UserProvider>();
    final current = provider.profile;
    if (current == null) {
      setState(() => _isSaving = false);
      return;
    }

    final parsedAge = int.tryParse(_ageCtrl.text.trim()) ?? current.computedAge;
    final effectiveDob = _dob ??
        DateTime(
          DateTime.now().year - parsedAge.clamp(1, 110),
          current.dateOfBirth?.month ?? 1,
          current.dateOfBirth?.day ?? 1,
        );
    final selectedRange =
        _incomeRange ?? current.effectiveIncomeRange;
    final syncedIncome = ProfileConstants.incomeValueFromRange(selectedRange);

    final updated = current.copyWith(
      fullName: _nameCtrl.text.trim(),
      state: _state ?? current.state,
      district:
          _districtCtrl.text.trim().isEmpty ? null : _districtCtrl.text.trim(),
      pincode:
          _pincodeCtrl.text.trim().isEmpty ? null : _pincodeCtrl.text.trim(),
      dateOfBirth: effectiveDob,
      age: parsedAge,
      gender: _gender,
      maritalStatus: _maritalStatus,
      occupation: _occupation,
      annualIncomeRange: selectedRange,
      income: syncedIncome,
      casteCategory: _casteCategory,
      aadhaarLastFour:
          _aadhaarCtrl.text.trim().isEmpty ? null : _aadhaarCtrl.text.trim(),
      panMasked: _panCtrl.text.trim().isEmpty
          ? null
          : _panCtrl.text.trim().toUpperCase(),
      rationCardNumber:
          _rationCtrl.text.trim().isEmpty ? null : _rationCtrl.text.trim(),
      isDisabled: _isDisabled,
      disabilityType: _isDisabled && _disabilityCtrl.text.trim().isNotEmpty
          ? _disabilityCtrl.text.trim()
          : null,
    );

    final ok = await provider.updateProfile(updated);
    userProvider.syncFromCitizenProfile(updated);

    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.emerald,
            content: TText(
              'Profile saved successfully!',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.semanticError,
            content: TText(
              'Failed to save. Please try again.',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now.subtract(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.saffron,
            surface: AppColors.bgMid,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final today = DateTime.now();
      int age = today.year - picked.year;
      if (today.month < picked.month ||
          (today.month == picked.month && today.day < picked.day)) {
        age--;
      }
      setState(() {
        _dob = picked;
        _ageCtrl.text = age.clamp(1, 120).toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          const Positioned.fill(child: JaliPattern(opacity: 0.03)),
          Form(
            key: _formKey,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  backgroundColor: AppColors.bgDeep.withValues(alpha: 0.95),
                  elevation: 0,
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  title: TText(
                    'Edit Profile',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFF6B1A),
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: AppColors.saffron,
                                strokeWidth: 2,
                              ),
                            )
                          : TextButton(
                              onPressed: _save,
                              child: TText(
                                'Save',
                                style: GoogleFonts.poppins(
                                  color: AppColors.saffron,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _sectionHeader(
                        'Personal Information',
                        Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 12),
                      IndianCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _textField(
                              lang: lang,
                              controller: _nameCtrl,
                              label: 'Full Name',
                              icon: Icons.person_outline_rounded,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Name is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: GestureDetector(
                                    onTap: _pickDob,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.surfaceBorder,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.cake_outlined,
                                            color: AppColors.textMuted,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _dob != null
                                                  ? '${_dob!.day}/${_dob!.month}/${_dob!.year}'
                                                  : lang.translateSync(
                                                      'Date of Birth',
                                                    ),
                                              style: GoogleFonts.inter(
                                                color: _dob != null
                                                    ? AppColors.textPrimary
                                                    : AppColors.textMuted,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.calendar_today_outlined,
                                            color: AppColors.textMuted,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: _textField(
                                    lang: lang,
                                    controller: _ageCtrl,
                                    label: 'Age (Years)',
                                    icon: Icons.timelapse_rounded,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    onChanged: (val) {
                                      final parsed = int.tryParse(val);
                                      if (parsed != null &&
                                          parsed > 0 &&
                                          parsed <= 120) {
                                        final now = DateTime.now();
                                        setState(() {
                                          _dob = DateTime(
                                            now.year - parsed,
                                            _dob?.month ?? 1,
                                            _dob?.day ?? 1,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _dropdown(
                              lang: lang,
                              label: 'Gender',
                              icon: Icons.wc_rounded,
                              value: _gender,
                              items: ProfileConstants.genders,
                              onChanged: (v) => setState(() => _gender = v),
                            ),
                            const SizedBox(height: 16),
                            _dropdown(
                              lang: lang,
                              label: 'Marital Status',
                              icon: Icons.favorite_border_rounded,
                              value: _maritalStatus,
                              items: ProfileConstants.maritalStatuses,
                              onChanged: (v) =>
                                  setState(() => _maritalStatus = v),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 50.ms),
                      const SizedBox(height: 24),
                      _sectionHeader('Location', Icons.location_on_outlined),
                      const SizedBox(height: 12),
                      IndianCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _stateDropdown(lang),
                            const SizedBox(height: 16),
                            _textField(
                              lang: lang,
                              controller: _districtCtrl,
                              label: 'District',
                              icon: Icons.location_city_outlined,
                            ),
                            const SizedBox(height: 16),
                            _textField(
                              lang: lang,
                              controller: _pincodeCtrl,
                              label: 'Pincode',
                              icon: Icons.pin_drop_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              validator: (v) {
                                if (v == null || v.isEmpty) return null;
                                if (v.length != 6) {
                                  return 'Enter a valid 6-digit pincode';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 24),
                      _sectionHeader(
                        'Financial & Social',
                        Icons.account_balance_wallet_outlined,
                      ),
                      const SizedBox(height: 12),
                      IndianCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _dropdown(
                              lang: lang,
                              label: 'Occupation',
                              icon: Icons.work_outline_rounded,
                              value: _occupation,
                              items: ProfileConstants.occupations,
                              onChanged: (v) => setState(() => _occupation = v),
                            ),
                            const SizedBox(height: 16),
                            _dropdown(
                              lang: lang,
                              label: 'Annual Income Range',
                              icon: Icons.currency_rupee_rounded,
                              value: _incomeRange,
                              items: ProfileConstants.incomeRanges,
                              onChanged: (v) =>
                                  setState(() => _incomeRange = v),
                            ),
                            const SizedBox(height: 16),
                            _dropdown(
                              lang: lang,
                              label: 'Caste Category',
                              icon: Icons.groups_outlined,
                              value: _casteCategory,
                              items: ProfileConstants.casteCategories,
                              onChanged: (v) =>
                                  setState(() => _casteCategory = v),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 24),
                      _sectionHeader('Document IDs', Icons.badge_outlined),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TText(
                          'Only the last 4 digits of Aadhaar are stored. PAN is stored in masked form.',
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IndianCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _textField(
                              lang: lang,
                              controller: _aadhaarCtrl,
                              label: 'Aadhaar Last 4 Digits',
                              icon: Icons.fingerprint_rounded,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              validator: (v) {
                                if (v == null || v.isEmpty) return null;
                                if (v.length != 4) {
                                  return 'Enter exactly 4 digits';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _textField(
                              lang: lang,
                              controller: _panCtrl,
                              label: 'PAN (e.g. ABCDE1234F)',
                              icon: Icons.credit_card_rounded,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(10),
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Za-z0-9]'),
                                ),
                              ],
                              validator: (v) {
                                if (v == null || v.isEmpty) return null;
                                if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$')
                                    .hasMatch(v.toUpperCase())) {
                                  return 'Enter a valid PAN format';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _textField(
                              lang: lang,
                              controller: _rationCtrl,
                              label: 'Ration Card Number',
                              icon: Icons.article_outlined,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 24),
                      _sectionHeader('Disability', Icons.accessible_rounded),
                      const SizedBox(height: 12),
                      IndianCard(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 4,
                              ),
                              title: TText(
                                'Person with Disability',
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: _isDisabled,
                              activeThumbColor: AppColors.saffron,
                              activeTrackColor:
                                  AppColors.saffron.withValues(alpha: 0.3),
                              inactiveTrackColor: AppColors.bgDeep,
                              onChanged: (v) => setState(() => _isDisabled = v),
                            ),
                            if (_isDisabled) ...[
                              const Divider(
                                color: AppColors.surfaceBorder,
                                height: 1,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 12, 20, 12),
                                child: _textField(
                                  lang: lang,
                                  controller: _disabilityCtrl,
                                  label: 'Disability Type',
                                  icon: Icons.accessible_rounded,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ).animate().fadeIn(delay: 250.ms),
                      const SizedBox(height: 32),
                      CviButton(
                        text: _isSaving ? 'Saving...' : 'Save Profile',
                        variant: CviButtonVariant.gold,
                        onPressed: _isSaving ? null : _save,
                      ).animate().fadeIn(delay: 300.ms),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.saffron,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: AppColors.saffron, size: 20),
        const SizedBox(width: 8),
        TText(
          title,
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _textField({
    required LanguageProvider lang,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      validator: validator != null
          ? (v) {
              final err = validator(v);
              return err != null ? lang.translateSync(err) : null;
            }
          : null,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: lang.translateSync(label),
        labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.saffron, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.semanticError, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _dropdown({
    required LanguageProvider lang,
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final safeValue = (value != null && items.contains(value)) ? value : null;
    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      onChanged: onChanged,
      dropdownColor: AppColors.bgMid,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: lang.translateSync(label),
        labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.saffron, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                lang.translateSync(e),
                style: GoogleFonts.inter(color: AppColors.textPrimary),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _stateDropdown(LanguageProvider lang) {
    final states = ProfileConstants.statesAndUTs;
    final safeState =
        (_state != null && states.contains(_state)) ? _state : 'Maharashtra';
    return DropdownButtonFormField<String>(
      initialValue: safeState,
      onChanged: (v) => setState(() => _state = v),
      dropdownColor: AppColors.bgMid,
      isExpanded: true,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: lang.translateSync('State / UT'),
        labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
        prefixIcon: const Icon(
          Icons.map_outlined,
          color: AppColors.textMuted,
          size: 20,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.saffron, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: states
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(
                lang.translateSync(s),
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
