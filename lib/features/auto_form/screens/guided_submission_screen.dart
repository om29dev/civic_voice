// ═══════════════════════════════════════════════════════════════════════════════
// GUIDED SUBMISSION SCREEN — WebView with step-by-step guided portal assistant
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../models/auto_form_model.dart';

// Future AWS Translate integration for portal page translation

class GuidedSubmissionScreen extends StatefulWidget {
  final String url;
  final String title;
  final Map<String, String> formData;
  final List<SubmitStep> submitSteps;
  final String portalName;

  const GuidedSubmissionScreen({
    super.key,
    required this.url,
    required this.title,
    required this.formData,
    this.submitSteps = const [],
    this.portalName = '',
  });

  @override
  State<GuidedSubmissionScreen> createState() =>
      _GuidedSubmissionScreenState();
}

class _GuidedSubmissionScreenState extends State<GuidedSubmissionScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isPanelExpanded = true;
  int _currentStep = 0;
  bool _showDataPanel = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            // DEMO MODE Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.saffron.withValues(alpha: 0.15),
                    AppColors.gold.withValues(alpha: 0.10),
                  ],
                ),
                border: const Border(
                  bottom: BorderSide(color: AppColors.surfaceBorder),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.emeraldLight,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emeraldLight.withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                      .fade(begin: 0.5, end: 1.0, duration: 1000.ms),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'DEMO MODE IS ACTIVE',
                      style: GoogleFonts.poppins(
                        color: AppColors.saffron,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (_isPanelExpanded) _buildGuidedPanel(),
            if (_showDataPanel) _buildDataPanel(),
            // Loading indicator
            if (_isLoading)
              LinearProgressIndicator(
                color: AppColors.saffron,
                backgroundColor: AppColors.bgDark,
                minHeight: 3,
              ),
            // WebView
            Expanded(
              child: WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Top Bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.portalName,
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Guided Submission Assistant',
                  style: GoogleFonts.poppins(
                    color: AppColors.gold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Toggle guide panel
          IconButton(
            icon: Icon(
              _isPanelExpanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Toggle Guide',
            onPressed: () =>
                setState(() => _isPanelExpanded = !_isPanelExpanded),
          ),
          // Toggle data panel
          IconButton(
            icon: Icon(
              Icons.content_copy_rounded,
              color: _showDataPanel ? AppColors.saffron : AppColors.textSecondary,
              size: 20,
            ),
            tooltip: 'Your Data',
            onPressed: () =>
                setState(() => _showDataPanel = !_showDataPanel),
          ),
        ],
      ),
    );
  }

  // ─── Guided Steps Panel ─────────────────────────────────────────────────────

  Widget _buildGuidedPanel() {
    if (widget.submitSteps.isEmpty) return const SizedBox();

    return Container(
      constraints: const BoxConstraints(maxHeight: 160),
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.assistant_rounded,
                  color: AppColors.gold, size: 16),
              const SizedBox(width: 6),
              Text(
                'Step ${_currentStep + 1} of ${widget.submitSteps.length}',
                style: GoogleFonts.poppins(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.submitSteps[_currentStep].getInstruction('en'),
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          // Step navigation
          Row(
            children: [
              if (_currentStep > 0)
                _StepButton(
                  label: '← Previous',
                  onTap: () =>
                      setState(() => _currentStep--),
                ),
              const Spacer(),
              if (_currentStep < widget.submitSteps.length - 1)
                _StepButton(
                  label: 'Next Step →',
                  isPrimary: true,
                  onTap: () =>
                      setState(() => _currentStep++),
                ),
              if (_currentStep == widget.submitSteps.length - 1)
                _StepButton(
                  label: '✓ Done',
                  isPrimary: true,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '🎉 Submission process complete!',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        backgroundColor: AppColors.emeraldLight,
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: -0.3, duration: 300.ms, curve: Curves.easeOut);
  }

  // ─── Data Panel with Copy Buttons ───────────────────────────────────────────

  Widget _buildDataPanel() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                Icon(Icons.data_object_rounded,
                    color: AppColors.saffron, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Your Pre-filled Data',
                  style: GoogleFonts.poppins(
                    color: AppColors.saffron,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  'Tap to copy',
                  style: GoogleFonts.poppins(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              shrinkWrap: true,
              itemCount: widget.formData.entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final entry =
                    widget.formData.entries.elementAt(index);
                return _CopyableDataRow(
                  label: _humanizeKey(entry.key),
                  value: entry.value,
                );
              },
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    ).animate().slideY(begin: -0.3, duration: 300.ms, curve: Curves.easeOut);
  }

  /// Turn data_key_name into "Data Key Name"
  String _humanizeKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1)}'
            : '')
        .join(' ');
  }
}

// ── Step Button ─────────────────────────────────────────────────────────────

class _StepButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _StepButton({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.saffron
              : AppColors.bgMid,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isPrimary ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ── Copyable Data Row ─────────────────────────────────────────────────────

class _CopyableDataRow extends StatefulWidget {
  final String label;
  final String value;

  const _CopyableDataRow({required this.label, required this.value});

  @override
  State<_CopyableDataRow> createState() => _CopyableDataRowState();
}

class _CopyableDataRowState extends State<_CopyableDataRow> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: widget.value));
        setState(() => _copied = true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _copied = false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _copied
              ? AppColors.emeraldLight.withValues(alpha: 0.08)
              : AppColors.bgMid,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _copied
                ? AppColors.emeraldLight.withValues(alpha: 0.3)
                : AppColors.surfaceBorder,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: GoogleFonts.poppins(
                        color: AppColors.textMuted, fontSize: 10),
                  ),
                  Text(
                    widget.value,
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              _copied
                  ? Icons.check_circle_rounded
                  : Icons.copy_rounded,
              color: _copied ? AppColors.emeraldLight : AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
