// ZAFTO Enhanced Moisture Reading Entry Screen
// Numbered location grid, material type, reference standard, drying goal
// Color coding: red/yellow/green based on target
// Phase T3b — Sprint T3: Water Damage Assessment + Moisture

import 'package:flutter/material.dart' hide MaterialType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/moisture_reading.dart';
import '../../theme/zafto_colors.dart';

class MoistureReadingEntryScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String? claimId;
  final String? tpaAssignmentId;
  final String? waterDamageAssessmentId;

  const MoistureReadingEntryScreen({
    super.key,
    required this.jobId,
    this.claimId,
    this.tpaAssignmentId,
    this.waterDamageAssessmentId,
  });

  @override
  ConsumerState<MoistureReadingEntryScreen> createState() =>
      _MoistureReadingEntryScreenState();
}

class _MoistureReadingEntryScreenState
    extends ConsumerState<MoistureReadingEntryScreen> {
  final _areaController = TextEditingController();
  final _floorController = TextEditingController();
  final _readingController = TextEditingController();
  final _targetController = TextEditingController();
  final _meterTypeController = TextEditingController();
  final _meterModelController = TextEditingController();
  final _tempController = TextEditingController();
  final _humidityController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationNumberController = TextEditingController();

  MaterialType _materialType = MaterialType.drywall;
  ReadingUnit _readingUnit = ReadingUnit.percent;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill target from material default
    _targetController.text = _materialType.defaultTarget.toString();
  }

  @override
  void dispose() {
    _areaController.dispose();
    _floorController.dispose();
    _readingController.dispose();
    _targetController.dispose();
    _meterTypeController.dispose();
    _meterModelController.dispose();
    _tempController.dispose();
    _humidityController.dispose();
    _notesController.dispose();
    _locationNumberController.dispose();
    super.dispose();
  }

  void _onMaterialChanged(MaterialType? type) {
    if (type == null) return;
    setState(() {
      _materialType = type;
      _targetController.text = type.defaultTarget.toString();
    });
  }

  Color _getReadingColor(ZaftoColors colors) {
    final reading = double.tryParse(_readingController.text);
    final target = double.tryParse(_targetController.text);
    if (reading == null || target == null) return colors.textPrimary;
    if (reading <= target) return colors.success;
    if (reading <= target * 1.2) return colors.warning;
    return colors.error;
  }

  String _getReadingStatus() {
    final reading = double.tryParse(_readingController.text);
    final target = double.tryParse(_targetController.text);
    if (reading == null || target == null) return '';
    if (reading <= target) return 'AT TARGET — DRY';
    if (reading <= target * 1.2) return 'NEAR TARGET';
    return 'ABOVE TARGET — WET';
  }

  Future<void> _save() async {
    if (_areaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Area name is required')),
      );
      return;
    }
    final readingValue = double.tryParse(_readingController.text);
    if (readingValue == null || readingValue < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valid reading value required')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');
      final companyId = user.appMetadata['company_id'] as String?;
      if (companyId == null) throw Exception('No company');

      final target = double.tryParse(_targetController.text);
      final isDry = target != null && readingValue <= target;

      await supabase.from('moisture_readings').insert({
        'company_id': companyId,
        'job_id': widget.jobId,
        'claim_id': widget.claimId,
        'tpa_assignment_id': widget.tpaAssignmentId,
        'water_damage_assessment_id': widget.waterDamageAssessmentId,
        'area_name': _areaController.text.trim(),
        'floor_level': _floorController.text.isNotEmpty
            ? _floorController.text
            : null,
        'location_number': int.tryParse(_locationNumberController.text),
        'material_type': _materialType.dbValue,
        'reading_value': readingValue,
        'reading_unit': _readingUnit.dbValue,
        'target_value': target,
        'reference_standard': _materialType.defaultTarget,
        'drying_goal_mc': target,
        'meter_type': _meterTypeController.text.isNotEmpty
            ? _meterTypeController.text
            : null,
        'meter_model': _meterModelController.text.isNotEmpty
            ? _meterModelController.text
            : null,
        'ambient_temp_f': double.tryParse(_tempController.text),
        'ambient_humidity': double.tryParse(_humidityController.text),
        'is_dry': isDry,
        'notes': _notesController.text.isNotEmpty
            ? _notesController.text
            : null,
        'recorded_by_user_id': user.id,
        'recorded_at': DateTime.now().toUtc().toIso8601String(),
      }).select().single();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isDry
                ? 'Reading saved — AT TARGET'
                : 'Reading saved — ABOVE TARGET'),
            backgroundColor: isDry ? Colors.green : Colors.orange,
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
          'Moisture Reading',
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
            // Location Info
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _areaController,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: _inputDeco('Area Name *', colors),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _locationNumberController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: _inputDeco('Loc #', colors),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _floorController,
              style: TextStyle(color: colors.textPrimary),
              decoration: _inputDeco('Floor Level (e.g., 1st Floor)', colors),
            ),
            const SizedBox(height: 16),

            // Material Type
            Text(
              'Material',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MaterialType.values.map((mt) {
                final isSelected = _materialType == mt;
                return GestureDetector(
                  onTap: () => _onMaterialChanged(mt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.accentPrimary
                          : colors.bgInset,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? colors.accentPrimary
                            : colors.borderDefault,
                      ),
                    ),
                    child: Text(
                      mt.label,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : colors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              'IICRC Reference Standard: ${_materialType.defaultTarget}%',
              style: TextStyle(
                  color: colors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Reading Value + Unit
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _readingController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      color: _getReadingColor(colors),
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                    decoration: _inputDeco('Reading *', colors),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _targetController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: colors.textPrimary),
                    decoration: _inputDeco('Target', colors),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (_getReadingStatus().isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getReadingColor(colors).withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getReadingStatus(),
                  style: TextStyle(
                    color: _getReadingColor(colors),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Reading Unit chips
            Text(
              'Unit',
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ReadingUnit.values.map((unit) {
                final isSelected = _readingUnit == unit;
                return GestureDetector(
                  onTap: () => setState(() => _readingUnit = unit),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.accentPrimary
                          : colors.bgInset,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      unit.label,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : colors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Meter Info
            Text(
              'Meter Info',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _meterTypeController,
                    style: TextStyle(color: colors.textPrimary),
                    decoration:
                        _inputDeco('Meter Type (Pin/Pinless)', colors),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _meterModelController,
                    style: TextStyle(color: colors.textPrimary),
                    decoration:
                        _inputDeco('Meter Model', colors),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ambient Conditions
            Text(
              'Ambient Conditions',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tempController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: colors.textPrimary),
                    decoration: _inputDeco('Temp (°F)', colors),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _humidityController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: colors.textPrimary),
                    decoration: _inputDeco('Humidity (%)', colors),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              style: TextStyle(color: colors.textPrimary),
              decoration: _inputDeco('Notes', colors),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, ZaftoColors colors) {
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
