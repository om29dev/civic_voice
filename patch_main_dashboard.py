import re

file_path = r'c:\Users\MADHAV\Downloads\Civic Voice\civic_voice\lib\features\dashboard\screens\main_dashboard_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Insert the function call in the build method
target_insertion = """                _buildQuickActions(),
                const SizedBox(height: 32),
                _buildPopularServices(),"""

new_section = """                _buildQuickActions(),
                const SizedBox(height: 32),
                _buildSmartFeatures(),
                const SizedBox(height: 32),
                _buildPopularServices(),"""

content = content.replace(target_insertion, new_section)

# 2. Add the _buildSmartFeatures function
smart_features_code = """
  // ─── Section 3.5: Smart Features ──────────────────────────────────────────────
  Widget _buildSmartFeatures() {
    final features = [
      ('Voice Complaint', 'शिकायत दर्ज', Icons.record_voice_over_rounded, AppColors.accentBlue, Routes.voiceComplaint),
      ('AI Scanner', 'दस्तावेज़ स्कैन', Icons.document_scanner_rounded, AppColors.accentTeal, Routes.documentScanner),
      ('Scheme Finder', 'योजना खोजें', Icons.search_rounded, AppColors.gold, Routes.schemeDiscovery),
      ('App Tracker', 'स्थिति', Icons.track_changes_rounded, AppColors.emeraldLight, Routes.appTracker),
      ('Offline Guide', 'ऑफ़लाइन', Icons.download_done_rounded, AppColors.accentPurple, Routes.offlineGuidance),
      ('Profile Recs', 'प्रोफाइल', Icons.person_search_rounded, AppColors.accentAmber, Routes.citizenProfile),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: _SectionHeading('Smart Features & AI'),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final f = features[index];
            return GestureDetector(
              onTap: () => context.push(f.$5),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1814),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: f.$4.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: f.$4.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(f.$3, color: f.$4, size: 24),
                    ),
                    const SizedBox(height: 8),
                    TText(
                      f.$1,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      f.$2,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: GoogleFonts.notoSansDevanagari(
                        fontSize: 8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 200 + index * 50)).scale(delay: Duration(milliseconds: 200 + index * 50));
          },
        ),
      ],
    );
  }

  // ─── Section 4: Popular Services Grid ───────────────────────────────────────"""

content = content.replace("  // ─── Section 4: Popular Services Grid ───────────────────────────────────────", smart_features_code)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated main_dashboard_screen.dart")
