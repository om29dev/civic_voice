import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/glass/glass_card.dart';
import '../../../widgets/animated/particle_background.dart';
import '../../../models/service_model_new.dart';
import '../../../models/scheme_model.dart';
import '../../../models/application_model.dart';
import '../../../providers/user_provider.dart';
import '../../../core/services/scheme_knowledge_base.dart';

class ServiceDetailScreen extends StatelessWidget {
  final ServiceModel service;

  const ServiceDetailScreen({super.key, required this.service});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;
    
    final scheme = SchemeKnowledgeBase.getSchemeById(service.id);
    
    // Check eligibility for service
    bool isEligible = scheme?.isEligible(user) ?? false;
    // Fallback for services not in KnowledgeBase yet
    if (scheme == null && user.isProfileComplete) {
      if (service.id == 'pension' && (user.age ?? 0) >= 60) isEligible = true;
      if (service.id == 'ration' && (user.annualIncome ?? 0) <= 100000) isEligible = true;
      if (service.id == 'land' && (user.ownsLand || user.occupation == 'Farmer')) isEligible = true;
      if (service.id == 'driving' && (user.age ?? 0) >= 18) isEligible = true;
      if (service.id == 'aadhaar' || service.id == 'pan' || service.id == 'passport' || service.id == 'birth') isEligible = true;
    }

    return Scaffold(
      backgroundColor: AppTheme.deepSpaceBlue,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.pureWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          service.title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.pureWhite,
          ),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: ParticleBackground(
              numberOfParticles: 40,
              particleColor: AppTheme.electricBlue,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Section
                  _buildHeroSection(isEligible),
                  const SizedBox(height: 32),
                  
                  // Official Website Button
                  _buildOfficialWebsiteButton(),
                  const SizedBox(height: 32),
                  
                  // Description
                  _buildSection(
                    'About',
                    Text(
                      service.description,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppTheme.pureWhite.withOpacity(0.8),
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Processing Time
                  _buildInfoCard(
                    'Processing Time',
                    service.processingTime,
                    Icons.access_time,
                    AppTheme.electricBlue,
                  ),
                  const SizedBox(height: 16),
                  
                  // Online Availability
                  _buildInfoCard(
                    'Online Application',
                    service.isOnlineAvailable ? 'Available' : 'Not Available',
                    Icons.computer,
                    service.isOnlineAvailable ? AppTheme.success : AppTheme.error,
                  ),
                  const SizedBox(height: 32),
                  
                  // Process Map (New Section)
                  if (scheme != null && scheme.steps.isNotEmpty) ...[
                    _buildSection(
                      'Interactive Process Map',
                      _buildProcessMap(context, scheme.steps),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Required Documents
                  _buildSection(
                    'Required Documents',
                    Column(
                      children: service.requiredDocuments
                          .map((doc) => _buildListItem(doc, Icons.description))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Eligibility Criteria
                  _buildSection(
                    'Eligibility Criteria',
                    Column(
                      children: service.eligibilityCriteria
                          .map((criteria) => _buildListItem(criteria, Icons.check_circle))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isEligible) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  service.color.withOpacity(0.3),
                  service.color.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              service.icon,
              size: 48,
              color: service.color,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.title,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.pureWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: service.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        service.category,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: service.color,
                        ),
                      ),
                    ),
                    if (isEligible) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ELIGIBLE',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialWebsiteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _launchURL(service.officialWebsite),
        icon: const Icon(Icons.open_in_new, size: 20),
        label: Text(
          'Visit Official Website',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.electricBlue,
          foregroundColor: AppTheme.deepSpaceBlue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.pureWhite,
          ),
        ),
        const SizedBox(height: 16),
        content,
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.pureWhite.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.pureWhite,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessMap(BuildContext context, List<SchemeStep> steps) {
    return Column(
      children: steps.map((step) {
        final isLast = step == steps.last;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline line
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.electricBlue.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.electricBlue, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '${step.number}',
                        style: GoogleFonts.poppins(
                          color: AppTheme.electricBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppTheme.electricBlue.withOpacity(0.3),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Step Details
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title['en'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.pureWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.instruction['en'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.pureWhite.withOpacity(0.7),
                        ),
                      ),
                      if (step.estimatedTime != null || step.location != null) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (step.estimatedTime != null)
                              _buildStepTag(Icons.timer_outlined, step.estimatedTime!['en']!),
                            if (step.location != null)
                              _buildStepTag(Icons.location_on_outlined, step.location!['en']!),
                            if (step.officeHours != null)
                              _buildStepTag(Icons.access_time, step.officeHours!['en']!),
                          ],
                        ),
                      ],
                      if (step.prerequisites != null && step.prerequisites!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.link, size: 14, color: AppTheme.warning.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Requires: ${step.prerequisites!.join(", ")}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.warning.withOpacity(0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (step.formUrl != null) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _launchURL(step.formUrl!),
                          icon: const Icon(Icons.file_download_outlined, size: 16),
                          label: const Text('Download Official Form'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.neonCyan,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStepTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.electricBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.electricBlue.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.electricBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.electricBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.electricBlue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppTheme.pureWhite.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to application form or external link
              _launchURL(service.officialWebsite);
            },
            icon: const Icon(Icons.assignment, size: 20),
            label: Text(
              'Apply Now',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: service.color,
              foregroundColor: AppTheme.pureWhite,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // Track application or check status
            },
            icon: const Icon(Icons.track_changes, size: 20),
            label: Text(
              'Track Application',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.electricBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppTheme.electricBlue, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
