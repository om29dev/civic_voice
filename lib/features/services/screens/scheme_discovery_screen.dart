import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/scheme_discovery_model.dart';
import '../../../../providers/scheme_discovery_provider.dart';
import '../../../../providers/voice_provider.dart';
import '../../../../widgets/glass_card.dart';

class SchemeDiscoveryScreen extends StatefulWidget {
  const SchemeDiscoveryScreen({super.key});

  @override
  State<SchemeDiscoveryScreen> createState() => _SchemeDiscoveryScreenState();
}

class _SchemeDiscoveryScreenState extends State<SchemeDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Searching for: "$text"'),
              backgroundColor: AppColors.gold,
            ),
          );
        }
      },
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
            maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                    child: Text(
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      scheme.category,
                      style: GoogleFonts.spaceMono(
                        color: AppColors.accentBlue,
                        fontSize: 12,
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
                      child: Text(
                        '${scheme.level} Scheme',
                        style: GoogleFonts.spaceMono(
                          color: AppColors.saffron,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (scheme.beneficiaryState.isNotEmpty &&
                      scheme.beneficiaryState.toLowerCase() != 'all')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        scheme.beneficiaryState,
                        style: GoogleFonts.spaceMono(
                          color: AppColors.emerald,
                          fontSize: 12,
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
                      Text(
                        'Overview',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        scheme.description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      if (scheme.nodalMinistry.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Nodal Ministry',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          scheme.nodalMinistry,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (scheme.eligibilityCriteria.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
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
                                const Icon(Icons.check_circle_outline,
                                    size: 16, color: AppColors.emerald),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
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
                      if (scheme.applicationProcess.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Application Process',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          scheme.applicationProcess,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (scheme.tags.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
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
                              child: Text(
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
                      const SizedBox(height: 24),
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
    return Consumer<SchemeDiscoveryProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: AppColors.bgDeep,
          appBar: AppBar(
            backgroundColor: AppColors.bgDeep,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            title: Text(
              'Scheme Discovery',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.saffron,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                            decoration: const InputDecoration(
                              hintText: 'Search schemes by keyword...',
                              hintStyle: TextStyle(color: AppColors.textMuted),
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search,
                                  color: AppColors.accentBlue),
                            ),
                            onChanged: (v) => _onSearch(provider, v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                      )
                    ],
                  ),
                ),

                // Category Filters
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              horizontal: 16, vertical: 8),
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
                          child: Text(
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

                // Results count
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '${provider.filteredSchemes.length} schemes found',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 12,
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
                              child: Text('No schemes found.',
                                  style: GoogleFonts.poppins(
                                      color: AppColors.textMuted)))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
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
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 3),
                                                      decoration:
                                                          BoxDecoration(
                                                        color: AppColors
                                                            .accentBlue
                                                            .withValues(alpha: 0.2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      child: Text(
                                                        scheme.category,
                                                        style: GoogleFonts
                                                            .spaceMono(
                                                          color: AppColors
                                                              .accentBlue,
                                                          fontSize: 11,
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
                                                        child: Text(
                                                          scheme.level,
                                                          style: GoogleFonts
                                                              .spaceMono(
                                                            color: AppColors
                                                                .saffron,
                                                            fontSize: 11,
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
                                          Text(
                                            scheme.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                GoogleFonts.playfairDisplay(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
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
                                                color:
                                                    AppColors.surfaceBorder),
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
                                                  child: Text(
                                                    'Eligibility: ${scheme.eligibilityCriteria.join(', ')}',
                                                    maxLines: 2,
                                                    overflow: TextOverflow
                                                        .ellipsis,
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
}
