import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/application_tracker_model.dart';
import '../../../providers/services_provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MY APPLICATIONS SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  static const _prefKey = 'cvi_applications';
  List<ApplicationTracker> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.userId ?? 'guest';
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('${_prefKey}_$userId');
      if (str != null) {
        final List<dynamic> decoded = jsonDecode(str);
        _applications = decoded.map((j) => ApplicationTracker.fromJson(j)).toList();
      } else {
        _applications = [];
      }
    } catch (e) {
      debugPrint('Error loading applications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveApplications() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.userId ?? 'guest';
      final prefs = await SharedPreferences.getInstance();
      final str = jsonEncode(_applications.map((a) => a.toJson()).toList());
      await prefs.setString('${_prefKey}_$userId', str);
    } catch (e) {
      debugPrint('Error saving applications: $e');
    }
  }

  void _addApplication(String serviceId, String serviceName, String number) {
    if (number.isEmpty) return;
    final newApp = ApplicationTracker(
      id: 'app_${DateTime.now().millisecondsSinceEpoch}',
      serviceId: serviceId,
      serviceName: serviceName,
      applicationNumber: number,
      status: ApplicationStatus.submitted,
      submittedDate: DateTime.now(),
      timeline: [
        ApplicationStep(title: 'Application Submitted', description: 'Your application has been received.', isCompleted: true, completedAt: DateTime.now()),
        const ApplicationStep(title: 'Under Processing', description: 'Documents are being verified.', isCurrent: true),
        const ApplicationStep(title: 'Final Approval', description: 'Pending officer signature.'),
      ],
      trackingUrl: 'https://www.india.gov.in',
    );

    setState(() {
      _applications.insert(0, newApp);
    });
    _saveApplications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeep,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'My Applications',
          style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.saffron),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.saffron))
          : _applications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _applications.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _ApplicationCard(application: _applications[index], index: index),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.saffron,
        onPressed: _showAddApplicationSheet,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Track App', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ─── EMPTY STATE ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.saffron.withValues(alpha: 0.05),
              border: Border.all(color: AppColors.saffron.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.assignment_add, color: AppColors.saffron, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            'No Applications Tracked',
            style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Add your government application number to securely track its status right here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Tap the + button to start',
            style: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppColors.saffron, fontWeight: FontWeight.w700),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).slideY(begin: 0, end: 0.2, duration: 1.seconds),
        ],
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }

  // ─── ADD BOTTOM SHEET ───────────────────────────────────────────────────────

  void _showAddApplicationSheet() {
    final numCtrl = TextEditingController();
    String? selectedServiceId;
    String selectedServiceName = '';
    final services = context.read<ServicesProvider>().allServices;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.bgDeep,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                border: Border(top: BorderSide(color: AppColors.saffron, width: 2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Track Application', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 24),
                  
                  // Service Dropdown
                  Text('Select Service', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: AppColors.bgMid, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surfaceBorder)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedServiceId,
                        isExpanded: true,
                        dropdownColor: AppColors.bgDark,
                        hint: Text('Choose a service...', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                        items: services.map((s) {
                          return DropdownMenuItem<String>(
                            value: s.id,
                            child: Text(s.localizedName('en'), style: GoogleFonts.poppins(color: AppColors.textPrimary)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setSheetState(() {
                            selectedServiceId = val;
                            if (val != null) {
                              selectedServiceName = services.firstWhere((s) => s.id == val, orElse: () => services.first).localizedName('en');
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App Number Input
                  Text('Application / Reference Number', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: numCtrl,
                    style: GoogleFonts.poppins(color: AppColors.textPrimary),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'e.g. MH123456789',
                      hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.bgMid,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.surfaceBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.saffron, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.saffron,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        disabledBackgroundColor: AppColors.surfaceBorder,
                      ),
                      onPressed: (selectedServiceId == null || numCtrl.text.isEmpty)
                          ? null
                          : () {
                              _addApplication(selectedServiceId!, selectedServiceName, numCtrl.text);
                              Navigator.pop(ctx);
                            },
                      child: Text('Start Tracking', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── APPLICATION CARD ────────────────────────────────────────────────────────

class _ApplicationCard extends StatelessWidget {
  final ApplicationTracker application;
  final int index;

  const _ApplicationCard({required this.application, required this.index});

  Color _getStatusColor() => switch (application.status) {
        ApplicationStatus.submitted => AppColors.accentBlue,
        ApplicationStatus.processing => AppColors.saffron,
        ApplicationStatus.approved => AppColors.emerald,
        ApplicationStatus.rejected => AppColors.semanticError,
      };

  String _getStatusText() => switch (application.status) {
        ApplicationStatus.submitted => 'Processing Started',
        ApplicationStatus.processing => 'In Progress',
        ApplicationStatus.approved => 'Approved',
        ApplicationStatus.rejected => 'Rejected',
      };

  double _getProgress() {
    if (application.timeline.isEmpty) return 0.0;
    int completed = application.timeline.where((s) => s.isCompleted).length;
    return completed / application.timeline.length;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final progress = _getProgress();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgMid.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Icon(Icons.description_rounded, color: statusColor, size: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(application.serviceName, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Ref: ${application.applicationNumber}', style: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
                        child: Text(_getStatusText(), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tracking Progress', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted)),
                    Text('${(progress * 100).toInt()}%', style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 6,
                  decoration: BoxDecoration(color: AppColors.bgDeep, borderRadius: BorderRadius.circular(3)),
                  child: Row(
                    children: [
                      Expanded(flex: (progress * 100).toInt(), child: Container(decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(3)))),
                      Expanded(flex: 100 - (progress * 100).toInt(), child: const SizedBox()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Bottom Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Updated: ${application.submittedDate.day}/${application.submittedDate.month}/${application.submittedDate.year}',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
                ),
                GestureDetector(
                  onTap: () async {
                    if (application.trackingUrl != null) {
                      final uri = Uri.parse(application.trackingUrl!);
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    }
                  },
                  child: Row(
                    children: [
                      Text('Official Site', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accentBlue)),
                      const SizedBox(width: 4),
                      const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.accentBlue),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.1, end: 0);
  }
}
