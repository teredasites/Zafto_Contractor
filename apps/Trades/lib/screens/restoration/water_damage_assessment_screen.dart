// ZAFTO Water Damage Assessment Screen
// IICRC S500 compliant: Category 1-3, Class 1-4, source identification
// Phase T3b — Sprint T3: Water Damage Assessment + Moisture

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/zafto_colors.dart';

class WaterDamageAssessmentScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String? tpaAssignmentId;

  const WaterDamageAssessmentScreen({
    super.key,
    required this.jobId,
    this.tpaAssignmentId,
  });

  @override
  ConsumerState<WaterDamageAssessmentScreen> createState() =>
      _WaterDamageAssessmentScreenState();
}

class _WaterDamageAssessmentScreenState
    extends ConsumerState<WaterDamageAssessmentScreen> {
  int _waterCategory = 1;
  int _waterClass = 1;
  String _sourceType = 'unknown';
  final _sourceDescController = TextEditingController();
  final _sourceRoomController = TextEditingController();
  bool _sourceStopped = false;
  DateTime _lossDate = DateTime.now();
  final _sqftController = TextEditingController();
  final _dryingDaysController = TextEditingController();
  bool _emergencyRequired = false;
  bool _containmentRequired = false;
  bool _asbestosSuspect = false;
  bool _leadPaintSuspect = false;
  bool _preExistingMold = false;
  final _preExistingController = TextEditingController();
  bool _isSaving = false;

  static const _categoryDescriptions = {
    1: 'Clean Water — supply lines, rain, melting ice, condensation',
    2: 'Gray Water — dishwasher, washing machine, toilet overflow (urine only)',
    3: 'Black Water — sewage, rising flood, toilet (fecal), standing water >72hr',
  };

  static const _classDescriptions = {
    1: 'Least — part of room, low-porosity materials',
    2: 'Significant — whole room, carpet/cushion wet, <24" wall wicking',
    3: 'Greatest — saturated ceiling, walls, insulation, subfloor',
    4: 'Specialty — deep pockets: hardwood, plaster, concrete, stone',
  };

  static const _sourceTypes = {
    'supply_line': 'Supply Line',
    'drain_line': 'Drain Line',
    'appliance': 'Appliance',
    'toilet': 'Toilet',
    'sewage': 'Sewage',
    'roof_leak': 'Roof Leak',
    'window_leak': 'Window Leak',
    'foundation': 'Foundation',
    'storm': 'Storm',
    'flood': 'Flood',
    'fire_suppression': 'Fire Suppression',
    'hvac': 'HVAC',
    'ice_dam': 'Ice Dam',
    'unknown': 'Unknown',
    'other': 'Other',
  };

  @override
  void dispose() {
    _sourceDescController.dispose();
    _sourceRoomController.dispose();
    _sqftController.dispose();
    _dryingDaysController.dispose();
    _preExistingController.dispose();
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

      await supabase.from('water_damage_assessments').insert({
        'company_id': companyId,
        'job_id': widget.jobId,
        'tpa_assignment_id': widget.tpaAssignmentId,
        'created_by_user_id': user.id,
        'water_category': _waterCategory,
        'water_class': _waterClass,
        'source_type': _sourceType,
        'source_description': _sourceDescController.text.isNotEmpty
            ? _sourceDescController.text
            : null,
        'source_location_room': _sourceRoomController.text.isNotEmpty
            ? _sourceRoomController.text
            : null,
        'source_stopped': _sourceStopped,
        'loss_date': _lossDate.toUtc().toIso8601String(),
        'total_sqft_affected':
            double.tryParse(_sqftController.text) ?? 0,
        'estimated_drying_days':
            int.tryParse(_dryingDaysController.text),
        'emergency_services_required': _emergencyRequired,
        'containment_required': _containmentRequired,
        'asbestos_suspect': _asbestosSuspect,
        'lead_paint_suspect': _leadPaintSuspect,
        'pre_existing_mold': _preExistingMold,
        'pre_existing_damage': _preExistingController.text.isNotEmpty
            ? _preExistingController.text
            : null,
      }).select().single();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assessment saved'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Water Damage Assessment',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.accentPrimary,
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: colors.accentPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IICRC S500 Classification Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderDefault),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.alertTriangle,
                      color: colors.warning, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'IICRC S500 Standard — Water Damage Classification',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Water Category (1-3)
            _sectionLabel('Water Category', colors),
            const SizedBox(height: 8),
            ...List.generate(3, (i) {
              final cat = i + 1;
              final isSelected = _waterCategory == cat;
              final catColor = cat == 1
                  ? Colors.blue
                  : cat == 2
                      ? Colors.amber
                      : Colors.red;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _waterCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? catColor.withAlpha(25)
                          : colors.bgInset,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isSelected ? catColor : colors.borderDefault,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color:
                                isSelected ? catColor : colors.bgInset,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$cat',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : colors.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Category $cat',
                                style: TextStyle(
                                  color: catColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _categoryDescriptions[cat]!,
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // Water Class (1-4)
            _sectionLabel('Water Class', colors),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(4, (i) {
                final cls = i + 1;
                final isSelected = _waterClass == cls;
                return GestureDetector(
                  onTap: () => setState(() => _waterClass = cls),
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 56) / 2,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.accentPrimary.withAlpha(25)
                          : colors.bgInset,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? colors.accentPrimary
                            : colors.borderDefault,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Class $cls',
                          style: TextStyle(
                            color: isSelected
                                ? colors.accentPrimary
                                : colors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _classDescriptions[cls]!,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Source Type
            _sectionLabel('Water Source', colors),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _sourceType,
              dropdownColor: colors.bgElevated,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: _inputDecoration('Source Type', colors),
              items: _sourceTypes.entries
                  .map((e) => DropdownMenuItem(
                      value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _sourceType = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sourceDescController,
              style: TextStyle(color: colors.textPrimary),
              decoration: _inputDecoration('Source Description', colors),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sourceRoomController,
              style: TextStyle(color: colors.textPrimary),
              decoration:
                  _inputDecoration('Source Location Room', colors),
            ),
            const SizedBox(height: 12),
            _toggleRow('Source Stopped?', _sourceStopped,
                (v) => setState(() => _sourceStopped = v), colors),
            const SizedBox(height: 20),

            // Loss Date
            _sectionLabel('Loss Information', colors),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _lossDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _lossDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: colors.bgInset,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.calendar,
                        size: 18, color: colors.textSecondary),
                    const SizedBox(width: 12),
                    Text(
                      '${_lossDate.month}/${_lossDate.day}/${_lossDate.year}',
                      style: TextStyle(
                          color: colors.textPrimary, fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      'Loss Date',
                      style: TextStyle(
                          color: colors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sqftController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: _inputDecoration(
                        'Total Sq Ft Affected', colors),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _dryingDaysController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: _inputDecoration(
                        'Est. Drying Days', colors),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Hazard Flags
            _sectionLabel('Hazard Flags', colors),
            const SizedBox(height: 8),
            _toggleRow('Emergency Services Required', _emergencyRequired,
                (v) => setState(() => _emergencyRequired = v), colors),
            _toggleRow(
                'Containment Required',
                _containmentRequired,
                (v) => setState(() => _containmentRequired = v),
                colors),
            _toggleRow('Asbestos Suspect', _asbestosSuspect,
                (v) => setState(() => _asbestosSuspect = v), colors),
            _toggleRow('Lead Paint Suspect', _leadPaintSuspect,
                (v) => setState(() => _leadPaintSuspect = v), colors),
            _toggleRow('Pre-Existing Mold', _preExistingMold,
                (v) => setState(() => _preExistingMold = v), colors),
            const SizedBox(height: 12),
            TextField(
              controller: _preExistingController,
              style: TextStyle(color: colors.textPrimary),
              decoration: _inputDecoration(
                  'Pre-Existing Damage Notes', colors),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, ZaftoColors colors) {
    return Text(
      label,
      style: TextStyle(
        color: colors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged,
      ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                  color: colors.textPrimary, fontSize: 14),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: colors.accentPrimary,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, ZaftoColors colors) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colors.textSecondary),
      filled: true,
      fillColor: colors.bgInset,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}
