import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/glass/glass_card.dart';
import '../../../widgets/animated/particle_background.dart';
import '../../../providers/user_provider.dart';
import '../../../models/document_model.dart';
import '../../../core/services/document_inference_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  final DocumentInferenceService _inferenceService = DocumentInferenceService();
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'All',
    'Identity',
    'Property',
    'Finance',
    'Education',
    'Medical',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inferenceService.dispose();
    super.dispose();
  }

  Future<void> _scanDocument(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (image != null) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        // Show processing indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.pureWhite),
                ),
                SizedBox(width: 16),
                Text('AI scanning in progress...'),
              ],
            ),
            backgroundColor: AppTheme.electricBlue,
            duration: Duration(seconds: 2),
          ),
        );

        final result = await _inferenceService.verifyDocument(image.path);
        final file = File(image.path);
        final sizeInMb = await file.length() / (1024 * 1024);
        
        final newDoc = UserDocument(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Scan_${DateFormat('HHmmss').format(DateTime.now())}.jpg',
          category: 'Identity',
          size: '${sizeInMb.toStringAsFixed(1)} MB',
          uploadDate: DateTime.now(),
          icon: Icons.camera_alt,
          color: result.isValid ? AppTheme.success : AppTheme.warning,
          filePath: image.path,
          status: result.isValid ? 'Verified' : 'Invalid',
          isVerified: result.isValid,
          verificationMessage: result.message,
          expiryDate: result.expiryDate,
          extractedText: result.extractedText,
        );

        userProvider.addDocument(newDoc);

        // Show result feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.isValid ? AppTheme.success : AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );

        _tabController.animateTo(0);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanning failed: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _pickAndUploadFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        final platformFile = result.files.single;
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        // Format size
        final sizeInMb = platformFile.size / (1024 * 1024);
        final sizeStr = '${sizeInMb.toStringAsFixed(1)} MB';
        
        // Determine icon based on extension
        IconData icon = Icons.description;
        Color color = AppTheme.electricBlue;
        
        final ext = platformFile.extension?.toLowerCase();
        if (ext == 'pdf') {
          icon = Icons.picture_as_pdf;
          color = AppTheme.error;
        } else if (ext == 'jpg' || ext == 'png') {
          icon = Icons.image;
          color = AppTheme.success;
        }

        final newDoc = UserDocument(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: platformFile.name,
          category: 'Identity', // Default category
          size: sizeStr,
          uploadDate: DateTime.now(),
          icon: icon,
          color: color,
          filePath: platformFile.path,
        );

        userProvider.addDocument(newDoc);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document "${platformFile.name}" uploaded successfully!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        _tabController.animateTo(0);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepSpaceBlue,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AnimatedGradientBackground(),
          ),
          const Positioned.fill(
            child: ParticleBackground(
              numberOfParticles: 40,
              particleColor: AppTheme.electricBlue,
            ),
          ),
          SafeArea(
            child: Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final documents = userProvider.currentUser.documents;
                
                return Column(
                  children: [
                    _buildHeader(documents.length),
                    _buildTabBar(),
                    _buildCategoryFilter(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildDocumentsList(documents),
                          _buildUploadSection(context),
                          _buildArchivedList(),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildUploadFAB(),
    );
  }

  Widget _buildHeader(int docCount) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.electricBlue.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.folder_rounded,
              color: AppTheme.pureWhite,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Documents',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.pureWhite,
                  ),
                ),
                Text(
                  '$docCount documents stored',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.pureWhite.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: AppTheme.electricBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppTheme.accentGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        labelColor: AppTheme.pureWhite,
        unselectedLabelColor: AppTheme.pureWhite.withOpacity(0.5),
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'All Documents'),
          Tab(text: 'Upload'),
          Tab(text: 'Archived'),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.accentGradient : null,
                  color: isSelected ? null : AppTheme.glassBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.electricBlue : AppTheme.glassBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: AppTheme.pureWhite,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentsList(List<UserDocument> documents) {
    final filteredDocs = _selectedCategory == 'All'
        ? documents
        : documents.where((doc) => doc.category == _selectedCategory).toList();

    if (filteredDocs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: AppTheme.pureWhite.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No documents found',
              style: GoogleFonts.poppins(color: AppTheme.pureWhite.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: filteredDocs.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _DocumentCard(document: filteredDocs[index]),
        );
      },
    );
  }

  Widget _buildUploadSection(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GlassCard(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.electricBlue.withOpacity(0.2),
                        AppTheme.neonCyan.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.cloud_upload_rounded,
                    size: 80,
                    color: AppTheme.electricBlue,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Upload Documents',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.pureWhite,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Upload your certificates, identity proof,\nor property documents securely.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.pureWhite.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => _scanDocument(context),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Scan with AI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricBlue,
                    foregroundColor: AppTheme.deepSpaceBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 10,
                    shadowColor: AppTheme.electricBlue.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _pickAndUploadFile(context),
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Choose Files'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.pureWhite,
                    side: BorderSide(color: AppTheme.glassBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSupportedFormats(),
        ],
      ),
    );
  }

  Widget _buildSupportedFormats() {
    final formats = ['PDF', 'JPG', 'PNG', 'DOC', 'DOCX'];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Supported Formats',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.pureWhite,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: formats.map((format) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.electricBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.electricBlue),
                ),
                child: Text(
                  format,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.electricBlue,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildArchivedList() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.archive_outlined,
                size: 80,
                color: AppTheme.pureWhite.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No Archived Documents',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.pureWhite,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Archived documents will appear here',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.pureWhite.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadFAB() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricBlue.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => _tabController.animateTo(1),
        backgroundColor: AppTheme.electricBlue,
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final UserDocument document;

  const _DocumentCard({required this.document});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy').format(document.uploadDate);
    
    return GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: document.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              document.icon,
              color: document.color,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.pureWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${document.size} • $dateStr',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.pureWhite.withOpacity(0.6),
                  ),
                ),
                if (document.verificationMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    document.verificationMessage!,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: document.isVerified ? AppTheme.success : AppTheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: document.isVerified
                  ? AppTheme.success.withOpacity(0.2)
                  : (document.status == 'Scan Required' 
                      ? AppTheme.glassBackground 
                      : AppTheme.error.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              document.status,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: document.isVerified
                    ? AppTheme.success
                    : (document.status == 'Scan Required' 
                        ? AppTheme.pureWhite.withOpacity(0.5) 
                        : AppTheme.error),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.pureWhite),
            color: AppTheme.deepSpaceBlue,
            onSelected: (value) {
              if (value == 'delete') {
                Provider.of<UserProvider>(context, listen: false).removeDocument(document.id);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view',
                child: Text('View', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: AppTheme.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
