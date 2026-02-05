/// Job Create/Edit Screen - Design System v2.6
/// Quick job entry and editing for field use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/business/job.dart';
import '../../services/job_service.dart';

class JobCreateScreen extends ConsumerStatefulWidget {
  final Job? editJob; // If provided, screen is in edit mode
  
  const JobCreateScreen({super.key, this.editJob});
  
  @override
  ConsumerState<JobCreateScreen> createState() => _JobCreateScreenState();
}

class _JobCreateScreenState extends ConsumerState<JobCreateScreen> {
  final _titleController = TextEditingController();
  final _customerController = TextEditingController();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _scheduledDate;
  bool _isSaving = false;
  
  bool get _isEditMode => widget.editJob != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _populateFields(widget.editJob!);
    }
  }

  void _populateFields(Job job) {
    _titleController.text = job.title;
    _customerController.text = job.customerName ?? '';
    _addressController.text = job.address ?? '';
    _amountController.text = job.estimatedAmount > 0 ? job.estimatedAmount.toString() : '';
    _notesController.text = job.notes ?? '';
    _scheduledDate = job.scheduledDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _customerController.dispose();
    _addressController.dispose();
    _amountController.dispose();
    _notesController.dispose();
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
        title: Text(_isEditMode ? 'Edit Job' : 'New Job', style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveJob,
            child: Text('Save', style: TextStyle(fontWeight: FontWeight.w600, color: _isSaving ? colors.textTertiary : colors.accentPrimary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(colors, 'Job Title *', _titleController, 'e.g. Panel Upgrade, Service Call', LucideIcons.briefcase),
            const SizedBox(height: 16),
            _buildTextField(colors, 'Customer Name', _customerController, 'e.g. John Smith', LucideIcons.user),
            const SizedBox(height: 16),
            _buildTextField(colors, 'Address', _addressController, 'e.g. 123 Main St', LucideIcons.mapPin),
            const SizedBox(height: 16),
            _buildAmountField(colors),
            const SizedBox(height: 16),
            _buildDatePicker(colors),
            const SizedBox(height: 16),
            _buildTextField(colors, 'Notes', _notesController, 'Additional details...', LucideIcons.fileText, maxLines: 3),
            const SizedBox(height: 32),
            _buildSaveButton(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(ZaftoColors colors, String label, TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
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

  Widget _buildAmountField(ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Estimated Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderDefault),
          ),
          child: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: TextStyle(color: colors.textQuaternary),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Text('\$', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: colors.textSecondary)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Scheduled Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickDate(context, colors),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderDefault),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.calendar, size: 20, color: colors.textTertiary),
                const SizedBox(width: 12),
                Text(
                  _scheduledDate != null ? _formatDate(_scheduledDate!) : 'Select date (optional)',
                  style: TextStyle(color: _scheduledDate != null ? colors.textPrimary : colors.textQuaternary),
                ),
                const Spacer(),
                if (_scheduledDate != null)
                  GestureDetector(
                    onTap: () => setState(() => _scheduledDate = null),
                    child: Icon(LucideIcons.x, size: 18, color: colors.textTertiary),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(ZaftoColors colors) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveJob,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accentPrimary,
          foregroundColor: colors.isDark ? Colors.black : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSaving
            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colors.isDark ? Colors.black : Colors.white))
            : Text(_isEditMode ? 'Update Job' : 'Create Job', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, ZaftoColors colors) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(primary: colors.accentPrimary, surface: colors.bgElevated),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _scheduledDate = date);
  }

  Future<void> _saveJob() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a job title')));
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final now = DateTime.now();
    
    if (_isEditMode) {
      // Update existing job
      final updated = widget.editJob!.copyWith(
        title: _titleController.text.trim(),
        customerName: _customerController.text.trim().isNotEmpty ? _customerController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        estimatedAmount: double.tryParse(_amountController.text) ?? 0,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        scheduledDate: _scheduledDate,
        updatedAt: now,
      );
      
      await ref.read(jobsProvider.notifier).updateJob(updated);
      
      if (mounted) {
        Navigator.pop(context, updated); // Return updated job
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Job "${updated.title}" updated'), backgroundColor: ref.read(zaftoColorsProvider).accentSuccess));
      }
    } else {
      // Create new job
      final service = ref.read(jobServiceProvider);
      final job = Job(
        id: service.generateId(),
        title: _titleController.text.trim(),
        customerName: _customerController.text.trim().isNotEmpty ? _customerController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        estimatedAmount: double.tryParse(_amountController.text) ?? 0,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        scheduledDate: _scheduledDate,
        status: _scheduledDate != null ? JobStatus.scheduled : JobStatus.lead,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(jobsProvider.notifier).addJob(job);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Job "${job.title}" created'), backgroundColor: ref.read(zaftoColorsProvider).accentSuccess));
      }
    }
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
}
