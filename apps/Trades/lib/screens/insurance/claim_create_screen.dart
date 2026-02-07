// ZAFTO Claim Create Screen — Create an insurance claim linked to an insurance_claim job.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/insurance_claim.dart';
import '../../models/job.dart';
import '../../services/insurance_claim_service.dart';
import '../../services/job_service.dart';
import 'claim_detail_screen.dart';

class ClaimCreateScreen extends ConsumerStatefulWidget {
  final String? jobId; // Pre-selected job

  const ClaimCreateScreen({super.key, this.jobId});

  @override
  ConsumerState<ClaimCreateScreen> createState() => _ClaimCreateScreenState();
}

class _ClaimCreateScreenState extends ConsumerState<ClaimCreateScreen> {
  final _insuranceCompanyController = TextEditingController();
  final _claimNumberController = TextEditingController();
  final _policyNumberController = TextEditingController();
  final _adjusterNameController = TextEditingController();
  final _adjusterPhoneController = TextEditingController();
  final _adjusterEmailController = TextEditingController();
  final _adjusterCompanyController = TextEditingController();
  final _deductibleController = TextEditingController(text: '0');
  final _coverageLimitController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _dateOfLoss = DateTime.now();
  LossType _lossType = LossType.unknown;
  ClaimCategory _claimCategory = ClaimCategory.restoration;
  String? _selectedJobId;
  bool _saving = false;

  // Storm-specific
  String _stormSeverity = 'moderate';
  String? _weatherEventType;
  bool _emergencyTarped = false;
  bool _aerialAssessmentNeeded = false;
  final _temporaryRepairsController = TextEditingController();

  // Reconstruction-specific
  int? _expectedDurationMonths;
  bool _permitsRequired = false;
  bool _multiContractor = false;

  // Commercial-specific
  String? _propertyType;
  final _businessNameController = TextEditingController();
  final _tenantNameController = TextEditingController();
  final _tenantContactController = TextEditingController();
  final _emergencyAuthAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedJobId = widget.jobId;
  }

  @override
  void dispose() {
    _insuranceCompanyController.dispose();
    _claimNumberController.dispose();
    _policyNumberController.dispose();
    _adjusterNameController.dispose();
    _adjusterPhoneController.dispose();
    _adjusterEmailController.dispose();
    _adjusterCompanyController.dispose();
    _deductibleController.dispose();
    _coverageLimitController.dispose();
    _notesController.dispose();
    _temporaryRepairsController.dispose();
    _businessNameController.dispose();
    _tenantNameController.dispose();
    _tenantContactController.dispose();
    _emergencyAuthAmountController.dispose();
    super.dispose();
  }

  Future<void> _saveClaim() async {
    if (_selectedJobId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a job')),
      );
      return;
    }
    if (_insuranceCompanyController.text.trim().isEmpty || _claimNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insurance company and claim number are required')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final service = ref.read(insuranceClaimServiceProvider);
      final claim = await service.createClaim(
        jobId: _selectedJobId!,
        insuranceCompany: _insuranceCompanyController.text.trim(),
        claimNumber: _claimNumberController.text.trim(),
        policyNumber: _policyNumberController.text.trim().isNotEmpty ? _policyNumberController.text.trim() : null,
        dateOfLoss: _dateOfLoss,
        lossType: _lossType,
        claimCategory: _claimCategory,
        adjusterName: _adjusterNameController.text.trim().isNotEmpty ? _adjusterNameController.text.trim() : null,
        adjusterPhone: _adjusterPhoneController.text.trim().isNotEmpty ? _adjusterPhoneController.text.trim() : null,
        adjusterEmail: _adjusterEmailController.text.trim().isNotEmpty ? _adjusterEmailController.text.trim() : null,
        adjusterCompany: _adjusterCompanyController.text.trim().isNotEmpty ? _adjusterCompanyController.text.trim() : null,
        deductible: double.tryParse(_deductibleController.text) ?? 0,
        coverageLimit: double.tryParse(_coverageLimitController.text),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        data: _buildCategoryData(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ClaimDetailScreen(claimId: claim.id)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white38 : Colors.black38;
    final labelColor = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('New Insurance Claim', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveClaim,
            child: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Selector
            _buildSectionTitle('Job', labelColor),
            const SizedBox(height: 8),
            _buildJobSelector(bgColor, borderColor, textColor, hintColor, isDark),
            const SizedBox(height: 20),

            // Claim Category
            _buildSectionTitle('Claim Category', labelColor),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ClaimCategory.values.map((cat) {
                final isSelected = _claimCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _claimCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF59E0B) : bgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? const Color(0xFFF59E0B) : borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : textColor)),
                        const SizedBox(height: 2),
                        Text(cat.description, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : hintColor)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Category-specific fields
            if (_claimCategory != ClaimCategory.restoration) ...[
              _buildCategoryFields(bgColor, borderColor, textColor, hintColor, labelColor, isDark),
              const SizedBox(height: 20),
            ],

            // Carrier Info
            _buildSectionTitle('Carrier Information', labelColor),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  _buildField('Insurance Company *', _insuranceCompanyController, 'e.g. State Farm', bgColor, borderColor, textColor, hintColor),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildField('Claim Number *', _claimNumberController, 'CLM-12345', bgColor, borderColor, textColor, hintColor)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('Policy Number', _policyNumberController, 'Optional', bgColor, borderColor, textColor, hintColor)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Loss Details
            _buildSectionTitle('Loss Details', labelColor),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Loss Type
                  Text('Loss Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: labelColor)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: LossType.values.where((t) => t != LossType.unknown).map((type) {
                      final isSelected = _lossType == type;
                      return GestureDetector(
                        onTap: () => setState(() => _lossType = type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFF59E0B) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? const Color(0xFFF59E0B) : borderColor),
                          ),
                          child: Text(type.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : textColor)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  // Date of Loss
                  _buildDatePicker('Date of Loss *', _dateOfLoss, bgColor, borderColor, textColor, labelColor),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Adjuster
            _buildSectionTitle('Adjuster (optional)', labelColor),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildField('Name', _adjusterNameController, 'John Smith', bgColor, borderColor, textColor, hintColor)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('Company', _adjusterCompanyController, 'Company', bgColor, borderColor, textColor, hintColor)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildField('Phone', _adjusterPhoneController, '(555) 123-4567', bgColor, borderColor, textColor, hintColor)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('Email', _adjusterEmailController, 'email@example.com', bgColor, borderColor, textColor, hintColor)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Financials
            _buildSectionTitle('Financials', labelColor),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
              child: Row(
                children: [
                  Expanded(child: _buildField('Deductible', _deductibleController, '0.00', bgColor, borderColor, textColor, hintColor, isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField('Coverage Limit', _coverageLimitController, 'Optional', bgColor, borderColor, textColor, hintColor, isNumber: true)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Notes
            _buildSectionTitle('Notes', labelColor),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
              child: TextField(
                controller: _notesController,
                maxLines: 3,
                style: TextStyle(fontSize: 14, color: textColor),
                decoration: InputDecoration(
                  hintText: 'Additional notes...',
                  hintStyle: TextStyle(color: hintColor, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color));
  }

  Widget _buildField(String label, TextEditingController controller, String hint,
      Color bgColor, Color borderColor, Color textColor, Color hintColor, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor.withValues(alpha: 0.6))),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: TextStyle(fontSize: 14, color: textColor),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: hintColor, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime date, Color bgColor, Color borderColor, Color textColor, Color labelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: labelColor)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _dateOfLoss = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.calendar, size: 14, color: textColor.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Text(
                  '${date.month}/${date.day}/${date.year}',
                  style: TextStyle(fontSize: 14, color: textColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _buildCategoryData() {
    switch (_claimCategory) {
      case ClaimCategory.storm:
        return StormData(
          stormSeverity: _stormSeverity,
          weatherEventType: _weatherEventType,
          emergencyTarped: _emergencyTarped,
          aerialAssessmentNeeded: _aerialAssessmentNeeded,
          temporaryRepairs: _temporaryRepairsController.text.trim().isNotEmpty
              ? _temporaryRepairsController.text.trim()
              : null,
        ).toJson();
      case ClaimCategory.reconstruction:
        return ReconstructionData(
          expectedDurationMonths: _expectedDurationMonths,
          permitsRequired: _permitsRequired,
          multiContractor: _multiContractor,
        ).toJson();
      case ClaimCategory.commercial:
        return CommercialData(
          propertyType: _propertyType,
          businessName: _businessNameController.text.trim().isNotEmpty
              ? _businessNameController.text.trim()
              : null,
          tenantName: _tenantNameController.text.trim().isNotEmpty
              ? _tenantNameController.text.trim()
              : null,
          tenantContact: _tenantContactController.text.trim().isNotEmpty
              ? _tenantContactController.text.trim()
              : null,
          emergencyAuthAmount:
              double.tryParse(_emergencyAuthAmountController.text),
        ).toJson();
      case ClaimCategory.restoration:
        return {};
    }
  }

  Widget _buildCategoryFields(Color bgColor, Color borderColor, Color textColor,
      Color hintColor, Color labelColor, bool isDark) {
    switch (_claimCategory) {
      case ClaimCategory.storm:
        return _buildStormFields(
            bgColor, borderColor, textColor, hintColor, labelColor);
      case ClaimCategory.reconstruction:
        return _buildReconstructionFields(
            bgColor, borderColor, textColor, hintColor, labelColor);
      case ClaimCategory.commercial:
        return _buildCommercialFields(
            bgColor, borderColor, textColor, hintColor, labelColor);
      case ClaimCategory.restoration:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStormFields(Color bgColor, Color borderColor, Color textColor,
      Color hintColor, Color labelColor) {
    const severities = ['minor', 'moderate', 'severe', 'catastrophic'];
    const eventTypes = [
      'hurricane',
      'tornado',
      'hailstorm',
      'thunderstorm',
      'ice_storm',
      'flood'
    ];
    const eventLabels = [
      'Hurricane',
      'Tornado',
      'Hailstorm',
      'Thunderstorm',
      'Ice Storm',
      'Flood'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Storm Details', labelColor),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Severity',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: labelColor)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: severities.map((s) {
                  final isSelected = _stormSeverity == s;
                  return GestureDetector(
                    onTap: () => setState(() => _stormSeverity = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF8B5CF6)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isSelected
                                ? const Color(0xFF8B5CF6)
                                : borderColor),
                      ),
                      child: Text(
                        s[0].toUpperCase() + s.substring(1),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : textColor),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Text('Weather Event',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: labelColor)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(eventTypes.length, (i) {
                  final isSelected = _weatherEventType == eventTypes[i];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _weatherEventType = eventTypes[i]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF8B5CF6)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isSelected
                                ? const Color(0xFF8B5CF6)
                                : borderColor),
                      ),
                      child: Text(eventLabels[i],
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : textColor)),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              _buildToggleRow('Emergency tarped', _emergencyTarped, (v) {
                setState(() => _emergencyTarped = v);
              }, textColor),
              _buildToggleRow(
                  'Aerial assessment needed', _aerialAssessmentNeeded, (v) {
                setState(() => _aerialAssessmentNeeded = v);
              }, textColor),
              const SizedBox(height: 10),
              _buildField('Temporary repairs done', _temporaryRepairsController,
                  'Describe any emergency repairs', bgColor, borderColor, textColor, hintColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReconstructionFields(Color bgColor, Color borderColor,
      Color textColor, Color hintColor, Color labelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Reconstruction Details', labelColor),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFFF97316).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Expected Duration',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: labelColor)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [1, 3, 6, 9, 12, 18].map((m) {
                  final isSelected = _expectedDurationMonths == m;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _expectedDurationMonths = m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF97316)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isSelected
                                ? const Color(0xFFF97316)
                                : borderColor),
                      ),
                      child: Text('${m}mo',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : textColor)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              _buildToggleRow('Permits required', _permitsRequired, (v) {
                setState(() => _permitsRequired = v);
              }, textColor),
              _buildToggleRow('Multi-contractor project', _multiContractor,
                  (v) {
                setState(() => _multiContractor = v);
              }, textColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommercialFields(Color bgColor, Color borderColor,
      Color textColor, Color hintColor, Color labelColor) {
    const propertyTypes = [
      'office',
      'retail',
      'warehouse',
      'restaurant',
      'industrial',
      'multi_unit',
      'hotel',
      'other'
    ];
    const propertyLabels = [
      'Office',
      'Retail',
      'Warehouse',
      'Restaurant',
      'Industrial',
      'Multi-Unit',
      'Hotel',
      'Other'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Commercial Details', labelColor),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Property Type',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: labelColor)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(propertyTypes.length, (i) {
                  final isSelected = _propertyType == propertyTypes[i];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _propertyType = propertyTypes[i]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF10B981)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isSelected
                                ? const Color(0xFF10B981)
                                : borderColor),
                      ),
                      child: Text(propertyLabels[i],
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : textColor)),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              _buildField('Business Name', _businessNameController,
                  'e.g. Acme Corp', bgColor, borderColor, textColor, hintColor),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildField('Tenant Name', _tenantNameController,
                        'If applicable', bgColor, borderColor, textColor, hintColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField('Tenant Contact', _tenantContactController,
                        'Phone or email', bgColor, borderColor, textColor, hintColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildField(
                  'Emergency Auth Amount',
                  _emergencyAuthAmountController,
                  'Pre-approved emergency limit',
                  bgColor,
                  borderColor,
                  textColor,
                  hintColor,
                  isNumber: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleRow(
      String label, bool value, ValueChanged<bool> onChanged, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: textColor)),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildJobSelector(Color bgColor, Color borderColor, Color textColor, Color hintColor, bool isDark) {
    // Fetch insurance_claim jobs to pick from
    final jobsAsync = ref.watch(jobsProvider);
    return jobsAsync.when(
      loading: () => Container(
        height: 48,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
        child: const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (_, __) => const Text('Error loading jobs'),
      data: (jobs) {
        final insuranceJobs = jobs.where((j) => j.jobType == JobType.insuranceClaim).toList();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Text('Select an insurance job', style: TextStyle(fontSize: 14, color: hintColor)),
              value: _selectedJobId,
              items: insuranceJobs.map((job) => DropdownMenuItem(
                value: job.id,
                child: Text((job.title ?? '').isNotEmpty ? job.title! : 'Untitled Job', style: TextStyle(fontSize: 14, color: textColor)),
              )).toList(),
              onChanged: (v) => setState(() => _selectedJobId = v),
              dropdownColor: bgColor,
            ),
          ),
        );
      },
    );
  }
}
