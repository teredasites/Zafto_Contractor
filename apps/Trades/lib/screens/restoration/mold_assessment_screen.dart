// ZAFTO Mold Assessment Screen
// IICRC S520 compliant: level classification, affected area, moisture source
// Sprint REST2 — Mold remediation dedicated tools

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/zafto_colors.dart';
import '../../models/mold_assessment.dart';

class MoldAssessmentScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String? insuranceClaimId;
  final String? existingAssessmentId;

  const MoldAssessmentScreen({
    super.key,
    required this.jobId,
    this.insuranceClaimId,
    this.existingAssessmentId,
  });

  @override
  ConsumerState<MoldAssessmentScreen> createState() =>
      _MoldAssessmentScreenState();
}

class _MoldAssessmentScreenState extends ConsumerState<MoldAssessmentScreen> {
  IicrcLevel _iicrcLevel = IicrcLevel.level2;
  final _sqftController = TextEditingController();
  final _moldTypeController = TextEditingController();
  final _moistureSourceController = TextEditingController();
  ContainmentType _containmentType = ContainmentType.none;
  bool _negativePressure = false;
  bool _airSamplingRequired = false;
  final _notesController = TextEditingController();
  bool _isSaving = false;
  bool _isLoading = false;

  static const _commonMoldTypes = [
    'Aspergillus', 'Cladosporium', 'Penicillium', 'Stachybotrys (Black Mold)',
    'Alternaria', 'Chaetomium', 'Fusarium', 'Trichoderma', 'Unknown — Lab Recommended',
  ];

  static const _commonMoistureSources = [
    'Roof leak', 'Plumbing leak', 'Condensation', 'Flooding',
    'Poor ventilation', 'HVAC issue', 'Foundation seepage',
    'Window leak', 'Ice dam', 'Unknown',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingAssessmentId != null) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('mold_assessments')
          .select()
          .eq('id', widget.existingAssessmentId!)
          .single();

      final a = MoldAssessment.fromJson(data);
      _iicrcLevel = a.iicrcLevel;
      _sqftController.text = a.affectedAreaSqft?.toString() ?? '';
      _moldTypeController.text = a.moldType ?? '';
      _moistureSourceController.text = a.moistureSource ?? '';
      _containmentType = a.containmentType;
      _negativePressure = a.negativePressure;
      _airSamplingRequired = a.airSamplingRequired;
      _notesController.text = a.notes ?? '';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _sqftController.dispose();
    _moldTypeController.dispose();
    _moistureSourceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');
      final companyId = user.appMetadata['company_id'] as String?;
      if (companyId == null) throw Exception('No company');

      final payload = {
        'company_id': companyId,
        'job_id': widget.jobId,
        if (widget.insuranceClaimId != null)
          'insurance_claim_id': widget.insuranceClaimId,
        'created_by_user_id': user.id,
        'iicrc_level': _iicrcLevel.value,
        'affected_area_sqft': double.tryParse(_sqftController.text),
        'mold_type': _moldTypeController.text.trim(),
        'moisture_source': _moistureSourceController.text.trim(),
        'containment_type': _containmentType.name,
        'negative_pressure': _negativePressure,
        'air_sampling_required': _airSamplingRequired,
        'assessment_status': 'in_progress',
        'notes': _notesController.text.trim(),
      };

      if (widget.existingAssessmentId != null) {
        await supabase
            .from('mold_assessments')
            .update(payload)
            .eq('id', widget.existingAssessmentId!);
      } else {
        await supabase.from('mold_assessments').insert(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mold assessment saved')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.bgBase,
        appBar: AppBar(title: const Text('Mold Assessment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: Text(widget.existingAssessmentId != null
            ? 'Edit Mold Assessment'
            : 'New Mold Assessment'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // IICRC LEVEL
          _sectionHeader(colors, 'IICRC S520 LEVEL'),
          const SizedBox(height: 8),
          ...IicrcLevel.values.map((level) => _buildLevelCard(colors, level)),

          const SizedBox(height: 16),

          // Affected area
          TextFormField(
            controller: _sqftController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Affected Area (sq ft)',
              labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
              isDense: true,
            ),
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
          ),

          const SizedBox(height: 24),

          // MOLD TYPE
          _sectionHeader(colors, 'MOLD TYPE (VISUAL)'),
          const SizedBox(height: 4),
          Text(
            'Visual identification only — always recommend lab confirmation.',
            style: TextStyle(fontSize: 11, color: colors.textTertiary, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _commonMoldTypes.map((type) {
              final selected = _moldTypeController.text == type;
              return GestureDetector(
                onTap: () => setState(() => _moldTypeController.text = type),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? Colors.green.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? Colors.green : colors.borderSubtle,
                    ),
                  ),
                  child: Text(type,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? Colors.green : colors.textSecondary)),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // MOISTURE SOURCE
          _sectionHeader(colors, 'MOISTURE SOURCE'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _commonMoistureSources.map((src) {
              final selected = _moistureSourceController.text == src;
              return GestureDetector(
                onTap: () => setState(() => _moistureSourceController.text = src),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? Colors.blue.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? Colors.blue : colors.borderSubtle,
                    ),
                  ),
                  child: Text(src,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? Colors.blue : colors.textSecondary)),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // CONTAINMENT
          _sectionHeader(colors, 'CONTAINMENT'),
          const SizedBox(height: 8),
          DropdownButtonFormField<ContainmentType>(
            value: _containmentType,
            decoration: InputDecoration(
              labelText: 'Containment Type',
              labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
              isDense: true,
            ),
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
            dropdownColor: colors.bgInset,
            items: ContainmentType.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                .toList(),
            onChanged: (v) => setState(() => _containmentType = v!),
          ),
          SwitchListTile(
            title: Text('Negative Pressure',
                style: TextStyle(color: colors.textPrimary, fontSize: 14)),
            value: _negativePressure,
            onChanged: (v) => setState(() => _negativePressure = v),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          SwitchListTile(
            title: Text('Air Sampling Required',
                style: TextStyle(color: colors.textPrimary, fontSize: 14)),
            value: _airSamplingRequired,
            onChanged: (v) => setState(() => _airSamplingRequired = v),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),

          const SizedBox(height: 24),

          // NOTES
          _sectionHeader(colors, 'NOTES'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Additional notes',
              labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
              isDense: true,
            ),
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              child: Text(_isSaving ? 'Saving...' : 'Save Assessment'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLevelCard(ZaftoColors colors, IicrcLevel level) {
    final selected = _iicrcLevel == level;
    return GestureDetector(
      onTap: () => setState(() {
        _iicrcLevel = level;
        // Auto-set recommendations
        if (level == IicrcLevel.level3) {
          _containmentType = ContainmentType.full;
          _negativePressure = true;
          _airSamplingRequired = true;
        } else if (level == IicrcLevel.level2) {
          _containmentType = ContainmentType.limited;
          _airSamplingRequired = true;
        }
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? colors.bgInset : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.green : colors.borderSubtle,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: 20,
                  color: selected ? Colors.green : colors.textTertiary,
                ),
                const SizedBox(width: 10),
                Text(level.label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colors.textPrimary)),
              ],
            ),
            if (selected) ...[
              const SizedBox(height: 8),
              _infoRow(colors, 'Containment:', level.containmentRequired),
              _infoRow(colors, 'PPE:', level.ppeRequired),
              _infoRow(colors, 'Air Sampling:', level.airSampling),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 30, top: 2),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
                text: '$label ',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary)),
            TextSpan(
                text: value,
                style: TextStyle(fontSize: 11, color: colors.textTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(ZaftoColors colors, String label) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'SF Pro Text',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: colors.textTertiary,
      ),
    );
  }
}
