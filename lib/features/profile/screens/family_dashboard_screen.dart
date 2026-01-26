import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/glass/glass_card.dart';
import '../../../providers/user_provider.dart';
import '../../../models/family_member_model.dart';

class FamilyDashboardScreen extends StatefulWidget {
  const FamilyDashboardScreen({super.key});

  @override
  State<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final members = userProvider.currentUser.familyMembers;

    return Scaffold(
      backgroundColor: AppTheme.deepSpaceBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.pureWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Family Dashboard',
          style: GoogleFonts.poppins(
            color: AppTheme.pureWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.electricBlue),
            onPressed: () => _showAddMemberDialog(context, userProvider),
          ),
        ],
      ),
      body: members.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final member = members[index];
                return _buildMemberCard(context, userProvider, member);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.family_restroom, size: 64, color: AppTheme.pureWhite.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No family members yet',
            style: GoogleFonts.poppins(
              color: AppTheme.pureWhite.withOpacity(0.5),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add members to find schemes for them',
            style: GoogleFonts.inter(
              color: AppTheme.pureWhite.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, UserProvider provider, FamilyMember member) {
    return Dismissible(
      key: Key(member.id),
      onDismissed: (_) => provider.removeFamilyMember(member.id),
      background: Container(
        color: AppTheme.error.withOpacity(0.8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.electricBlue.withOpacity(0.2),
              child: Text(
                member.name[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  color: AppTheme.electricBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: GoogleFonts.poppins(
                      color: AppTheme.pureWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${member.relation} • ${member.age} yrs',
                    style: GoogleFonts.inter(
                      color: AppTheme.pureWhite.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (member.isDependent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Dependent',
                  style: GoogleFonts.inter(
                    color: AppTheme.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, UserProvider provider) {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    String relation = 'Spouse';
    bool isDependent = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.deepSpaceBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Add Member',
            style: GoogleFonts.poppins(color: AppTheme.pureWhite),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(nameController, 'Name'),
                const SizedBox(height: 12),
                _buildTextField(ageController, 'Age', isNumber: true),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: relation,
                  dropdownColor: AppTheme.deepSpaceBlue,
                  style: GoogleFonts.inter(color: AppTheme.pureWhite),
                  decoration: InputDecoration(
                    labelText: 'Relation',
                    filled: true,
                    fillColor: AppTheme.glassBackground,
                  ),
                  items: ['Spouse', 'Child', 'Father', 'Mother', 'Sibling']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) => setState(() => relation = val!),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text('Dependent?', style: GoogleFonts.inter(color: AppTheme.pureWhite)),
                  value: isDependent,
                  activeColor: AppTheme.electricBlue,
                  onChanged: (val) => setState(() => isDependent = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && ageController.text.isNotEmpty) {
                  provider.addFamilyMember(FamilyMember(
                    id: DateTime.now().toIso8601String(),
                    name: nameController.text,
                    relation: relation,
                    age: int.parse(ageController.text),
                    occupation: 'Not specified',
                    isDependent: isDependent,
                  ));
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.electricBlue),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.inter(color: AppTheme.pureWhite),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppTheme.glassBackground,
        labelStyle: TextStyle(color: AppTheme.pureWhite.withOpacity(0.6)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
