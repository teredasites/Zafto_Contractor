// Job Create/Edit Screen - Design System v2.6
// Quick job entry and editing for field use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/job.dart';
import '../../services/job_service.dart';
import '../../core/draft_recovery_mixin.dart';

class JobCreateScreen extends ConsumerStatefulWidget {
  final Job? editJob; // If provided, screen is in edit mode
  
  const JobCreateScreen({super.key, this.editJob});
  
  @override
  ConsumerState<JobCreateScreen> createState() => _JobCreateScreenState();
}

class _JobCreateScreenState extends ConsumerState<JobCreateScreen>
    with DraftRecoveryMixin {
  @override
  String get draftFeature => 'job';
  @override
  String get draftKey => widget.editJob?.id ?? 'new';
  @override
  String get draftScreenRoute => '/jobs/${widget.editJob?.id ?? "new"}';

  @override
  Map<String, dynamic> serializeDraftState() => {
        'title': _titleController.text,
        'customer': _customerController.text,
        'address': _addressController.text,
        'amount': _amountController.text,
        'notes': _notesController.text,
        'internalNotes': _internalNotesController.text,
        'poNumber': _poNumberController.text,
        'scope': _scopeController.text,
        'specialRequirements': _specialRequirementsController.text,
        'estimatedHours': _estimatedHoursController.text,
        'scheduledDate': _scheduledDate?.toIso8601String(),
        'jobType': _jobType.name,
        'source': _source,
        'priority': _priority.name,
        'tradeType': _tradeType,
      };

  @override
  void restoreDraftState(Map<String, dynamic> state) {
    setState(() {
      _titleController.text = state['title'] as String? ?? '';
      _customerController.text = state['customer'] as String? ?? '';
      _addressController.text = state['address'] as String? ?? '';
      _amountController.text = state['amount'] as String? ?? '';
      _notesController.text = state['notes'] as String? ?? '';
      _internalNotesController.text =
          state['internalNotes'] as String? ?? '';
      _poNumberController.text = state['poNumber'] as String? ?? '';
      _scopeController.text = state['scope'] as String? ?? '';
      _specialRequirementsController.text =
          state['specialRequirements'] as String? ?? '';
      _estimatedHoursController.text =
          state['estimatedHours'] as String? ?? '';
      final dateStr = state['scheduledDate'] as String?;
      if (dateStr != null) _scheduledDate = DateTime.tryParse(dateStr);
      final jt = state['jobType'] as String?;
      if (jt != null) {
        _jobType = JobType.values.firstWhere(
            (e) => e.name == jt,
            orElse: () => JobType.standard);
      }
      _source = state['source'] as String? ?? 'direct';
      final pr = state['priority'] as String?;
      if (pr != null) {
        _priority = JobPriority.values.firstWhere(
            (e) => e.name == pr,
            orElse: () => JobPriority.normal);
      }
      _tradeType = state['tradeType'] as String? ?? 'electrical';
    });
  }

  final _titleController = TextEditingController();
  final _customerController = TextEditingController();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _internalNotesController = TextEditingController();
  final _poNumberController = TextEditingController();
  final _scopeController = TextEditingController();
  final _specialRequirementsController = TextEditingController();
  final _estimatedHoursController = TextEditingController();
  DateTime? _scheduledDate;
  bool _isSaving = false;
  JobType _jobType = JobType.standard;
  String _source = 'direct';
  JobPriority _priority = JobPriority.normal;
  String _tradeType = 'electrical';

  // Insurance metadata controllers
  final _insuranceCompanyController = TextEditingController();
  final _claimNumberController = TextEditingController();
  final _adjusterNameController = TextEditingController();
  final _adjusterPhoneController = TextEditingController();
  final _deductibleController = TextEditingController();
  DateTime? _dateOfLoss;
  String _claimCategory = 'restoration';
  final _stormEventController = TextEditingController();

  // Warranty metadata controllers
  final _warrantyCompanyController = TextEditingController();
  final _dispatchNumberController = TextEditingController();
  final _authLimitController = TextEditingController();
  final _serviceFeeController = TextEditingController();
  
  bool get _isEditMode => widget.editJob != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _populateFields(widget.editJob!);
    }
    for (final c in [
      _titleController, _customerController, _addressController,
      _amountController, _notesController, _internalNotesController,
      _poNumberController, _scopeController,
      _specialRequirementsController, _estimatedHoursController,
    ]) {
      c.addListener(markDraftDirty);
    }
  }

  void _populateFields(Job job) {
    _titleController.text = job.title ?? '';
    _customerController.text = job.customerName;
    _addressController.text = job.address;
    _amountController.text = job.estimatedAmount > 0 ? job.estimatedAmount.toString() : '';
    _notesController.text = job.description ?? '';
    _internalNotesController.text = job.internalNotes ?? '';
    _estimatedHoursController.text = job.estimatedDuration != null ? (job.estimatedDuration! / 60).toStringAsFixed(1) : '';
    _scheduledDate = job.scheduledStart;
    _jobType = job.jobType;
    _source = job.source;
    _priority = job.priority;
    _tradeType = job.tradeType;
    if (job.isInsuranceClaim) {
      _insuranceCompanyController.text = job.typeMetadata['insuranceCompany'] as String? ?? '';
      _claimNumberController.text = job.typeMetadata['claimNumber'] as String? ?? '';
      _adjusterNameController.text = job.typeMetadata['adjusterName'] as String? ?? '';
      _adjusterPhoneController.text = job.typeMetadata['adjusterPhone'] as String? ?? '';
      _deductibleController.text = (job.typeMetadata['deductible'] as num?)?.toString() ?? '';
      final dol = job.typeMetadata['dateOfLoss'] as String?;
      if (dol != null) _dateOfLoss = DateTime.tryParse(dol);
      _claimCategory = job.typeMetadata['claimCategory'] as String? ?? 'restoration';
      _stormEventController.text = job.typeMetadata['stormEvent'] as String? ?? '';
    } else if (job.isWarrantyDispatch) {
      _warrantyCompanyController.text = job.typeMetadata['warrantyCompany'] as String? ?? '';
      _dispatchNumberController.text = job.typeMetadata['dispatchNumber'] as String? ?? '';
      _authLimitController.text = (job.typeMetadata['authorizationLimit'] as num?)?.toString() ?? '';
      _serviceFeeController.text = (job.typeMetadata['serviceFee'] as num?)?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _customerController.dispose();
    _addressController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _insuranceCompanyController.dispose();
    _claimNumberController.dispose();
    _adjusterNameController.dispose();
    _adjusterPhoneController.dispose();
    _deductibleController.dispose();
    _stormEventController.dispose();
    _internalNotesController.dispose();
    _poNumberController.dispose();
    _scopeController.dispose();
    _specialRequirementsController.dispose();
    _estimatedHoursController.dispose();
    _warrantyCompanyController.dispose();
    _dispatchNumberController.dispose();
    _authLimitController.dispose();
    _serviceFeeController.dispose();
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
            _buildJobTypeSelector(colors),
            const SizedBox(height: 16),
            _buildPrioritySelector(colors),
            const SizedBox(height: 16),
            _buildTradeTypeSelector(colors),
            const SizedBox(height: 16),
            if (_jobType == JobType.insuranceClaim) ...[
              _buildInsuranceFields(colors),
              const SizedBox(height: 16),
            ],
            if (_jobType == JobType.warrantyDispatch) ...[
              _buildWarrantyFields(colors),
              const SizedBox(height: 16),
            ],
            _buildSourceSelector(colors),
            const SizedBox(height: 16),
            _buildTextField(colors, 'Customer Name', _customerController, 'e.g. John Smith', LucideIcons.user),
            const SizedBox(height: 16),
            _buildTextField(colors, 'Address', _addressController, 'e.g. 123 Main St', LucideIcons.mapPin),
            const SizedBox(height: 16),
            _buildTextField(colors, 'PO Number', _poNumberController, 'Purchase order #', LucideIcons.hash),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildAmountField(colors)),
                const SizedBox(width: 12),
                Expanded(child: _buildEstimatedDurationField(colors)),
              ],
            ),
            const SizedBox(height: 16),
            _buildDatePicker(colors),
            const SizedBox(height: 16),
            _buildTextField(colors, 'Scope of Work', _scopeController, 'Detailed scope description...', LucideIcons.clipboardList, maxLines: 3),
            const SizedBox(height: 16),
            _buildTextField(colors, 'Notes (visible to customer)', _notesController, 'Additional details...', LucideIcons.fileText, maxLines: 3),
            const SizedBox(height: 16),
            _buildTextField(colors, 'Internal Notes (team only)', _internalNotesController, 'Private notes for your team...', LucideIcons.lock, maxLines: 2),
            const SizedBox(height: 16),
            _buildTextField(colors, 'Special Requirements', _specialRequirementsController, 'Permits, hazards, accessibility...', LucideIcons.alertTriangle, maxLines: 2),
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
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

  Widget _buildJobTypeSelector(ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Job Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<JobType>(
            segments: [
              ButtonSegment(value: JobType.standard, label: const Text('Standard'), icon: const Icon(LucideIcons.briefcase, size: 16)),
              ButtonSegment(value: JobType.insuranceClaim, label: const Text('Insurance'), icon: const Icon(LucideIcons.shield, size: 16)),
              ButtonSegment(value: JobType.warrantyDispatch, label: const Text('Warranty'), icon: const Icon(LucideIcons.fileCheck, size: 16)),
            ],
            selected: {_jobType},
            onSelectionChanged: (values) => setState(() => _jobType = values.first),
            style: SegmentedButton.styleFrom(
              backgroundColor: colors.bgElevated,
              foregroundColor: colors.textSecondary,
              selectedForegroundColor: colors.isDark ? Colors.black : Colors.white,
              selectedBackgroundColor: colors.accentPrimary,
              side: BorderSide(color: colors.borderDefault),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsuranceFields(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.shield, size: 16, color: const Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              Text('Insurance Claim Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          _buildClaimCategorySelector(colors),
          const SizedBox(height: 10),
          _buildCompactField(colors, 'Insurance Company *', _insuranceCompanyController, 'e.g. State Farm'),
          const SizedBox(height: 10),
          _buildCompactField(colors, 'Claim Number *', _claimNumberController, 'e.g. CLM-12345'),
          const SizedBox(height: 10),
          _buildDateOfLossPicker(colors),
          if (_claimCategory == 'storm') ...[
            const SizedBox(height: 10),
            _buildCompactField(colors, 'Storm Event Name', _stormEventController, 'e.g. Hurricane Milton 2026'),
          ],
          const SizedBox(height: 10),
          _buildCompactField(colors, 'Adjuster Name', _adjusterNameController, 'Optional'),
          const SizedBox(height: 10),
          _buildCompactField(colors, 'Adjuster Phone', _adjusterPhoneController, 'Optional'),
          const SizedBox(height: 10),
          _buildCompactField(colors, 'Deductible', _deductibleController, '0.00', isNumber: true),
        ],
      ),
    );
  }

  Widget _buildClaimCategorySelector(ZaftoColors colors) {
    const categories = [
      ('restoration', 'Restoration'),
      ('storm', 'Storm'),
      ('reconstruction', 'Reconstruction'),
      ('commercial', 'Commercial'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Claim Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textSecondary)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: categories.map((cat) {
            final isSelected = _claimCategory == cat.$1;
            return ChoiceChip(
              label: Text(cat.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary)),
              selected: isSelected,
              onSelected: (_) => setState(() => _claimCategory = cat.$1),
              selectedColor: colors.accentPrimary,
              backgroundColor: colors.bgBase,
              side: BorderSide(color: isSelected ? colors.accentPrimary : colors.borderDefault),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector(ZaftoColors colors) {
    const priorities = [
      (JobPriority.low, 'Low', LucideIcons.arrowDown),
      (JobPriority.normal, 'Normal', LucideIcons.minus),
      (JobPriority.high, 'High', LucideIcons.arrowUp),
      (JobPriority.urgent, 'Urgent', LucideIcons.alertTriangle),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Priority', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: priorities.map((p) {
            final isSelected = _priority == p.$1;
            final isUrgent = p.$1 == JobPriority.urgent;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _priority = p.$1);
                },
                child: Container(
                  margin: EdgeInsets.only(right: p.$1 != JobPriority.urgent ? 6 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isUrgent ? const Color(0xFFEF4444).withValues(alpha: 0.15) : colors.accentPrimary.withValues(alpha: 0.15))
                        : colors.bgElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? (isUrgent ? const Color(0xFFEF4444) : colors.accentPrimary) : colors.borderDefault),
                  ),
                  child: Column(
                    children: [
                      Icon(p.$3, size: 16, color: isSelected ? (isUrgent ? const Color(0xFFEF4444) : colors.accentPrimary) : colors.textTertiary),
                      const SizedBox(height: 4),
                      Text(p.$2, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? (isUrgent ? const Color(0xFFEF4444) : colors.accentPrimary) : colors.textSecondary)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTradeTypeSelector(ZaftoColors colors) {
    const trades = [
      ('electrical', 'Electrical'), ('plumbing', 'Plumbing'), ('hvac', 'HVAC'),
      ('roofing', 'Roofing'), ('painting', 'Painting'), ('general', 'General'),
      ('carpentry', 'Carpentry'), ('drywall', 'Drywall'), ('flooring', 'Flooring'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Trade Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary)),
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
              Icon(LucideIcons.wrench, size: 20, color: colors.textTertiary),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _tradeType,
                    isExpanded: true,
                    dropdownColor: colors.bgElevated,
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    items: trades.map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2))).toList(),
                    onChanged: (v) { if (v != null) setState(() => _tradeType = v); },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEstimatedDurationField(ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Est. Duration (hrs)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderDefault),
          ),
          child: TextField(
            controller: _estimatedHoursController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: '2.0',
              hintStyle: TextStyle(color: colors.textQuaternary),
              prefixIcon: Icon(LucideIcons.clock, size: 20, color: colors.textTertiary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSourceSelector(ZaftoColors colors) {
    const sources = [
      ('direct', 'Direct'),
      ('referral', 'Referral'),
      ('canvass', 'Canvass'),
      ('website', 'Website'),
      ('phone', 'Phone'),
      ('other', 'Other'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lead Source', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: sources.map((src) {
            final isSelected = _source == src.$1;
            return ChoiceChip(
              label: Text(src.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary)),
              selected: isSelected,
              onSelected: (_) => setState(() => _source = src.$1),
              selectedColor: colors.accentPrimary,
              backgroundColor: colors.bgBase,
              side: BorderSide(color: isSelected ? colors.accentPrimary : colors.borderDefault),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWarrantyFields(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.fileCheck, size: 16, color: const Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              Text('Warranty Dispatch Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          _buildCompactField(colors, 'Warranty Company *', _warrantyCompanyController, 'e.g. AHS, Choice, Fidelity'),
          const SizedBox(height: 10),
          _buildCompactField(colors, 'Dispatch Number *', _dispatchNumberController, 'e.g. DSP-00123'),
          const SizedBox(height: 10),
          _buildCompactField(colors, 'Authorization Limit', _authLimitController, '0.00', isNumber: true),
          const SizedBox(height: 10),
          _buildCompactField(colors, 'Service Fee', _serviceFeeController, '0.00', isNumber: true),
        ],
      ),
    );
  }

  Widget _buildCompactField(ZaftoColors colors, String label, TextEditingController controller, String hint, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textSecondary)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: colors.bgBase,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.borderDefault),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: TextStyle(fontSize: 14, color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: colors.textQuaternary, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateOfLossPicker(ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date of Loss *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textSecondary)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _dateOfLoss ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.dark(primary: colors.accentPrimary, surface: colors.bgElevated),
                ),
                child: child!,
              ),
            );
            if (date != null) setState(() => _dateOfLoss = date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.borderDefault),
            ),
            child: Row(
              children: [
                Text(
                  _dateOfLoss != null ? _formatDate(_dateOfLoss!) : 'Select date',
                  style: TextStyle(fontSize: 14, color: _dateOfLoss != null ? colors.textPrimary : colors.textQuaternary),
                ),
                const Spacer(),
                Icon(LucideIcons.calendar, size: 16, color: colors.textTertiary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<String> _buildTags() {
    final tags = <String>[];
    if (_jobType == JobType.insuranceClaim && _claimCategory == 'storm' && _stormEventController.text.trim().isNotEmpty) {
      tags.add('storm:${_stormEventController.text.trim()}');
    }
    return tags;
  }

  Map<String, dynamic> _buildTypeMetadata() {
    if (_jobType == JobType.insuranceClaim) {
      final meta = <String, dynamic>{
        'insuranceCompany': _insuranceCompanyController.text.trim(),
        'claimNumber': _claimNumberController.text.trim(),
        'claimCategory': _claimCategory,
        'dateOfLoss': _dateOfLoss?.toIso8601String(),
        'adjusterName': _adjusterNameController.text.trim().isNotEmpty ? _adjusterNameController.text.trim() : null,
        'adjusterPhone': _adjusterPhoneController.text.trim().isNotEmpty ? _adjusterPhoneController.text.trim() : null,
        'deductible': double.tryParse(_deductibleController.text),
        'approvalStatus': 'pending',
      };
      if (_claimCategory == 'storm' && _stormEventController.text.trim().isNotEmpty) {
        meta['stormEvent'] = _stormEventController.text.trim();
      }
      return meta;
    } else if (_jobType == JobType.warrantyDispatch) {
      return {
        'warrantyCompany': _warrantyCompanyController.text.trim(),
        'dispatchNumber': _dispatchNumberController.text.trim(),
        'authorizationLimit': double.tryParse(_authLimitController.text),
        'serviceFee': double.tryParse(_serviceFeeController.text),
        'warrantyType': 'home_warranty',
      };
    }
    return {};
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
      final estHours = double.tryParse(_estimatedHoursController.text);
      final updated = widget.editJob!.copyWith(
        title: _titleController.text.trim(),
        customerName: _customerController.text.trim().isNotEmpty ? _customerController.text.trim() : '',
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : '',
        estimatedAmount: double.tryParse(_amountController.text) ?? 0,
        estimatedDuration: estHours != null ? (estHours * 60).round() : null,
        description: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        internalNotes: _internalNotesController.text.trim().isNotEmpty ? _internalNotesController.text.trim() : null,
        scheduledStart: _scheduledDate,
        jobType: _jobType,
        priority: _priority,
        tradeType: _tradeType,
        typeMetadata: _buildTypeMetadata(),
        source: _source,
        tags: _buildTags(),
        updatedAt: now,
      );
      
      await ref.read(jobsProvider.notifier).updateJob(updated);
      await discardDraft();

      if (mounted) {
        Navigator.pop(context, updated); // Return updated job
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Job "${updated.displayTitle}" updated'), backgroundColor: ref.read(zaftoColorsProvider).accentSuccess));
      }
    } else {
      // Create new job
      final service = ref.read(jobServiceProvider);
      final estHrs = double.tryParse(_estimatedHoursController.text);
      final job = Job(
        id: service.generateId(),
        title: _titleController.text.trim(),
        customerName: _customerController.text.trim().isNotEmpty ? _customerController.text.trim() : '',
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : '',
        estimatedAmount: double.tryParse(_amountController.text) ?? 0,
        estimatedDuration: estHrs != null ? (estHrs * 60).round() : null,
        description: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        internalNotes: _internalNotesController.text.trim().isNotEmpty ? _internalNotesController.text.trim() : null,
        scheduledStart: _scheduledDate,
        status: _scheduledDate != null ? JobStatus.scheduled : JobStatus.draft,
        jobType: _jobType,
        priority: _priority,
        tradeType: _tradeType,
        typeMetadata: _buildTypeMetadata(),
        source: _source,
        tags: _buildTags(),
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(jobsProvider.notifier).addJob(job);
      await discardDraft();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Job "${job.title}" created'), backgroundColor: ref.read(zaftoColorsProvider).accentSuccess));
      }
    }
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
}
