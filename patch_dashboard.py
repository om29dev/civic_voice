import re

file_path = r'c:\Users\MADHAV\Downloads\Civic Voice\civic_voice\lib\features\dashboard\dashboard_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Insert the new section in the CustomScrollView before Popular Services
target_insertion = """                const SizedBox(height: 28),

                // Popular Services"""

new_section = """                const SizedBox(height: 28),

                // Smart AI Features
                const _SectionHeader(
                  hindi: 'स्मार्ट सुविधाएं',
                  english: 'Smart Features',
                ),
                const SizedBox(height: 14),
                const _SmartFeaturesGrid()
                    .animate()
                    .fadeIn(delay: 250.ms)
                    .slideY(begin: 0.08, end: 0, delay: 250.ms),

                const SizedBox(height: 28),

                // Popular Services"""

content = content.replace(target_insertion, new_section)

# 2. Add the _SmartFeaturesGrid widget at the end of the file
smart_features_code = """
// ═══════════════════════════════════════════════════════════════════════════════
// SMART FEATURES GRID
// ═══════════════════════════════════════════════════════════════════════════════

class _SmartFeaturesGrid extends StatelessWidget {
  const _SmartFeaturesGrid();

  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureData('💬', 'Voice Complaint', 'शिकायत दर्ज करें', AppColors.accentBlue, Routes.voiceComplaint),
      _FeatureData('📄', 'AI Scanner', 'दस्तावेज़ स्कैन', AppColors.accentTeal, Routes.documentScanner),
      _FeatureData('🔍', 'Scheme Finder', 'योजना खोजें', AppColors.gold, Routes.schemeDiscovery),
      _FeatureData('📊', 'App Tracker', 'आवेदन स्थिति', AppColors.emeraldLight, Routes.appTracker),
      _FeatureData('📶', 'Offline Guide', 'ऑफ़लाइन मदद', AppColors.accentPurple, Routes.offlineGuidance),
      _FeatureData('👤', 'Citizen Profile', 'नागरिक प्रोफाइल', AppColors.accentAmber, Routes.citizenProfile),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: features.length,
      itemBuilder: (context, i) {
        final f = features[i];
        return GestureDetector(
          onTap: () => context.push(f.route),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: f.color.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: f.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    f.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  f.english,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  f.hindi,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 8,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 200 + i * 50))
        .scale(begin: const Offset(0.9, 0.9), delay: Duration(milliseconds: 200 + i * 50));
      },
    );
  }
}

class _FeatureData {
  final String emoji, english, hindi, route;
  final Color color;
  const _FeatureData(this.emoji, this.english, this.hindi, this.color, this.route);
}
"""

content += smart_features_code

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated dashboard_screen.dart")
