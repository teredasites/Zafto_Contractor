/// Add Employee Screen — Sprint U11a (P0 Blocker)
/// Invites a new team member via invite-team-member Edge Function.
/// Fields: name, email, phone, address, employment type, trade specialties,
/// certification level, pay rate, role, emergency contact, date of hire.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

// ====================== CONSTANTS ======================

const _employmentTypes = ['full_time', 'part_time', 'contract', 'seasonal'];
const _employmentLabels = {
  'full_time': 'Full-Time',
  'part_time': 'Part-Time',
  'contract': 'Contract',
  'seasonal': 'Seasonal',
};

const _certLevels = ['apprentice', 'journeyman', 'master'];
const _certLabels = {
  'apprentice': 'Apprentice',
  'journeyman': 'Journeyman',
  'master': 'Master',
};

const _roles = ['technician', 'apprentice', 'office_manager', 'admin'];
const _roleLabels = {
  'technician': 'Technician',
  'apprentice': 'Apprentice',
  'office_manager': 'Office Manager',
  'admin': 'Admin',
};

const _tradeOptions = [
  'electrical', 'plumbing', 'hvac', 'roofing', 'painting',
  'general_contracting', 'carpentry', 'drywall', 'flooring', 'landscaping',
  'concrete', 'masonry', 'siding', 'insulation', 'solar',
  'fire_protection', 'low_voltage', 'demolition', 'excavation',
];

const _tradeLabels = {
  'electrical': 'Electrical',
  'plumbing': 'Plumbing',
  'hvac': 'HVAC',
  'roofing': 'Roofing',
  'painting': 'Painting',
  'general_contracting': 'General Contracting',
  'carpentry': 'Carpentry',
  'drywall': 'Drywall',
  'flooring': 'Flooring',
  'landscaping': 'Landscaping',
  'concrete': 'Concrete',
  'masonry': 'Masonry',
  'siding': 'Siding',
  'insulation': 'Insulation',
  'solar': 'Solar',
  'fire_protection': 'Fire Protection',
  'low_voltage': 'Low Voltage',
  'demolition': 'Demolition',
  'excavation': 'Excavation',
};

// ====================== SCREEN ======================

class AddEmployeeScreen extends ConsumerStatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  ConsumerState<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends ConsumerState<AddEmployeeScreen> {
  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _titleController = TextEditingController();
  final _payRateController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();

  // State
  String _employmentType = 'full_time';
  String _certLevel = 'journeyman';
  String _role = 'technician';
  String _payType = 'hourly';
  DateTime _dateOfHire = DateTime.now();
  final Set<String> _selectedTrades = {};
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _titleController.dispose();
    _payRateController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Add Team Member', style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _inviteEmployee,
            child: Text('Send Invite', style: TextStyle(fontWeight: FontWeight.w600, color: _isSaving ? colors.textTertiary : colors.accentPrimary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) _buildErrorBanner(colors),

            // SECTION: Basic Info
            _buildSectionHeader(colors, 'Basic Information'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTextField(colors, 'First Name *', _firstNameController, 'John', LucideIcons.user)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(colors, 'Last Name *', _lastNameController, 'Smith', LucideIcons.user)),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(colors, 'Email *', _emailController, 'employee@email.com', LucideIcons.mail, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildTextField(colors, 'Phone', _phoneController, '(555) 123-4567', LucideIcons.phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildTextField(colors, 'Job Title', _titleController, 'e.g. Journeyman Electrician', LucideIcons.briefcase),

            const SizedBox(height: 28),

            // SECTION: Employment Details
            _buildSectionHeader(colors, 'Employment Details'),
            const SizedBox(height: 12),
            _buildDropdown(colors, 'Role *', _role, _roles, _roleLabels, LucideIcons.shield, (v) => setState(() => _role = v)),
            const SizedBox(height: 16),
            _buildDropdown(colors, 'Employment Type', _employmentType, _employmentTypes, _employmentLabels, LucideIcons.clock, (v) => setState(() => _employmentType = v)),
            const SizedBox(height: 16),
            _buildDropdown(colors, 'Certification Level', _certLevel, _certLevels, _certLabels, LucideIcons.award, (v) => setState(() => _certLevel = v)),
            const SizedBox(height: 16),
            _buildDatePicker(colors, 'Date of Hire', _dateOfHire, LucideIcons.calendar),

            const SizedBox(height: 28),

            // SECTION: Trade Specialties
            _buildSectionHeader(colors, 'Trade Specialties'),
            const SizedBox(height: 12),
            _buildTradeChips(colors),

            const SizedBox(height: 28),

            // SECTION: Compensation
            _buildSectionHeader(colors, 'Compensation'),
            const SizedBox(height: 12),
            _buildPayTypeToggle(colors),
            const SizedBox(height: 16),
            _buildTextField(colors, _payType == 'hourly' ? 'Hourly Rate (\$)' : 'Annual Salary (\$)', _payRateController, _payType == 'hourly' ? '35.00' : '72000', LucideIcons.dollarSign, keyboardType: const TextInputType.numberWithOptions(decimal: true)),

            const SizedBox(height: 28),

            // SECTION: Emergency Contact
            _buildSectionHeader(colors, 'Emergency Contact'),
            const SizedBox(height: 12),
            _buildTextField(colors, 'Contact Name', _emergencyNameController, 'Jane Smith', LucideIcons.userPlus),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField(colors, 'Contact Phone', _emergencyPhoneController, '(555) 987-6543', LucideIcons.phone, keyboardType: TextInputType.phone)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(colors, 'Relation', _emergencyRelationController, 'Spouse', LucideIcons.heart)),
              ],
            ),

            const SizedBox(height: 32),
            _buildInviteButton(colors),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ====================== WIDGETS ======================

  Widget _buildErrorBanner(ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.accentError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.accentError.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertTriangle, size: 18, color: colors.accentError),
          const SizedBox(width: 10),
          Expanded(child: Text(_errorMessage!, style: TextStyle(fontSize: 13, color: colors.accentError))),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: Icon(LucideIcons.x, size: 16, color: colors.accentError),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary));
  }

  Widget _buildTextField(ZaftoColors colors, String label, TextEditingController controller, String hint, IconData icon, {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderDefault),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: colors.textQuaternary),
              prefixIcon: Icon(icon, size: 20, color: colors.textTertiary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(ZaftoColors colors, String label, String value, List<String> options, Map<String, String> labels, IconData icon, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderDefault),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colors.textTertiary),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    dropdownColor: colors.bgElevated,
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    items: options.map((o) => DropdownMenuItem(value: o, child: Text(labels[o] ?? o))).toList(),
                    onChanged: (v) { if (v != null) onChanged(v); },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(ZaftoColors colors, String label, DateTime date, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dateOfHire,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: ColorScheme.dark(primary: colors.accentPrimary, surface: colors.bgElevated),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _dateOfHire = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderDefault),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: colors.textTertiary),
                const SizedBox(width: 12),
                Text(
                  '${date.month}/${date.day}/${date.year}',
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                ),
                const Spacer(),
                Icon(LucideIcons.chevronDown, size: 16, color: colors.textTertiary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTradeChips(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tradeOptions.map((trade) {
        final selected = _selectedTrades.contains(trade);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (selected) {
                _selectedTrades.remove(trade);
              } else {
                _selectedTrades.add(trade);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? colors.accentPrimary.withValues(alpha: 0.15) : colors.bgElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
            ),
            child: Text(
              _tradeLabels[trade] ?? trade,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? colors.accentPrimary : colors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPayTypeToggle(ZaftoColors colors) {
    return Row(
      children: [
        _buildToggleOption(colors, 'Hourly', 'hourly', LucideIcons.clock),
        const SizedBox(width: 12),
        _buildToggleOption(colors, 'Salary', 'salary', LucideIcons.banknote),
      ],
    );
  }

  Widget _buildToggleOption(ZaftoColors colors, String label, String value, IconData icon) {
    final selected = _payType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _payType = value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? colors.accentPrimary.withValues(alpha: 0.15) : colors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? colors.accentPrimary : colors.textTertiary),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? colors.accentPrimary : colors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInviteButton(ZaftoColors colors) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _inviteEmployee,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accentPrimary,
          foregroundColor: colors.isDark ? Colors.black : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSaving
            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colors.isDark ? Colors.black : Colors.white))
            : const Text('Send Invitation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ====================== ACTIONS ======================

  Future<void> _inviteEmployee() async {
    // Validate required fields
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();

    if (firstName.isEmpty) {
      setState(() => _errorMessage = 'First name is required');
      return;
    }
    if (lastName.isEmpty) {
      setState(() => _errorMessage = 'Last name is required');
      return;
    }
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Email is required');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    HapticFeedback.mediumImpact();

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.functions.invoke(
        'invite-team-member',
        body: {
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
          'role': _role,
          'tradeSpecialties': _selectedTrades.toList(),
          'title': _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
          'employmentType': _employmentType,
          'certificationLevel': _certLevel,
          'payType': _payType,
          'payRate': double.tryParse(_payRateController.text.trim()) ?? 0,
          'dateOfHire': _dateOfHire.toIso8601String().split('T').first,
          'emergencyContactName': _emergencyNameController.text.trim().isNotEmpty ? _emergencyNameController.text.trim() : null,
          'emergencyContactPhone': _emergencyPhoneController.text.trim().isNotEmpty ? _emergencyPhoneController.text.trim() : null,
          'emergencyContactRelation': _emergencyRelationController.text.trim().isNotEmpty ? _emergencyRelationController.text.trim() : null,
        },
      );

      // Parse response
      final data = response.data;
      if (data is Map && data['error'] != null) {
        throw Exception(data['error']);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation sent to $firstName $lastName'),
            backgroundColor: ref.read(zaftoColorsProvider).accentSuccess,
          ),
        );
      }
    } catch (e) {
      final msg = e is FunctionException
          ? (e.details is Map ? (e.details as Map)['error']?.toString() : null) ?? e.reasonPhrase ?? 'Failed to send invitation'
          : e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _errorMessage = msg;
        _isSaving = false;
      });
    }
  }
}
