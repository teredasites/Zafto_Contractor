// ZAFTO Fire Damage Assessment Screen
// Fire origin/cause documentation, damage zones, structural assessment
// Sprint REST1 — Fire restoration dedicated tools

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/zafto_colors.dart';
import '../../models/fire_assessment.dart';

class FireDamageAssessmentScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String? insuranceClaimId;
  final String? existingAssessmentId;

  const FireDamageAssessmentScreen({
    super.key,
    required this.jobId,
    this.insuranceClaimId,
    this.existingAssessmentId,
  });

  @override
  ConsumerState<FireDamageAssessmentScreen> createState() =>
      _FireDamageAssessmentScreenState();
}

class _FireDamageAssessmentScreenState
    extends ConsumerState<FireDamageAssessmentScreen> {
  // Origin
  final _originRoomController = TextEditingController();
  final _originDescController = TextEditingController();
  final _fdReportController = TextEditingController();
  final _fdNameController = TextEditingController();
  DateTime _lossDate = DateTime.now();

  // Severity
  DamageSeverity _severity = DamageSeverity.moderate;

  // Structural
  bool _structuralCompromise = false;
  bool _roofDamage = false;
  bool _foundationDamage = false;
  bool _loadBearingAffected = false;
  final _structuralNotesController = TextEditingController();

  // Damage zones
  final List<_DamageZoneEntry> _zones = [];

  // Water from suppression
  bool _waterFromSuppression = false;

  // Notes
  final _notesController = TextEditingController();

  bool _isSaving = false;
  bool _isLoading = false;
  FireAssessment? _existing;

  @override
  void initState() {
    super.initState();
    if (widget.existingAssessmentId != null) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('fire_assessments')
          .select()
          .eq('id', widget.existingAssessmentId!)
          .single();

      final a = FireAssessment.fromJson(data);
      _existing = a;
      _originRoomController.text = a.originRoom ?? '';
      _originDescController.text = a.originDescription ?? '';
      _fdReportController.text = a.fireDepartmentReportNumber ?? '';
      _fdNameController.text = a.fireDepartmentName ?? '';
      _lossDate = a.dateOfLoss ?? DateTime.now();
      _severity = a.damageSeverity;
      _structuralCompromise = a.structuralCompromise;
      _roofDamage = a.roofDamage;
      _foundationDamage = a.foundationDamage;
      _loadBearingAffected = a.loadBearingAffected;
      _structuralNotesController.text = a.structuralNotes ?? '';
      _waterFromSuppression = a.waterDamageFromSuppression;
      _notesController.text = a.notes ?? '';

      _zones.clear();
      for (final z in a.damageZones) {
        _zones.add(_DamageZoneEntry(
          room: z.room,
          zoneType: z.zoneType,
          severity: z.severity,
          sootType: z.sootType,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load assessment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _originRoomController.dispose();
    _originDescController.dispose();
    _fdReportController.dispose();
    _fdNameController.dispose();
    _structuralNotesController.dispose();
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

      final zones = _zones
          .map((z) => {
                return {
                  'room': z.room,
                  'zone_type': z.zoneType.dbValue,
                  'severity': z.severity,
                  if (z.sootType != null) 'soot_type': z.sootType!.dbValue,
                  'photos': <String>[],
                };
              })
          .toList();

      final payload = {
        'company_id': companyId,
        'job_id': widget.jobId,
        if (widget.insuranceClaimId != null)
          'insurance_claim_id': widget.insuranceClaimId,
        'created_by_user_id': user.id,
        'origin_room': _originRoomController.text.trim(),
        'origin_description': _originDescController.text.trim(),
        'fire_department_report_number': _fdReportController.text.trim(),
        'fire_department_name': _fdNameController.text.trim(),
        'date_of_loss': _lossDate.toUtc().toIso8601String(),
        'damage_severity': _severity.dbValue,
        'structural_compromise': _structuralCompromise,
        'roof_damage': _roofDamage,
        'foundation_damage': _foundationDamage,
        'load_bearing_affected': _loadBearingAffected,
        'structural_notes': _structuralNotesController.text.trim(),
        'damage_zones': zones,
        'water_damage_from_suppression': _waterFromSuppression,
        'assessment_status': 'in_progress',
        'notes': _notesController.text.trim(),
      };

      if (_existing != null) {
        await supabase
            .from('fire_assessments')
            .update(payload)
            .eq('id', _existing!.id);
      } else {
        await supabase.from('fire_assessments').insert(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fire assessment saved')),
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

  void _addZone() {
    setState(() {
      _zones.add(_DamageZoneEntry());
    });
  }

  void _removeZone(int index) {
    setState(() => _zones.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.bgBase,
        appBar: AppBar(title: const Text('Fire Assessment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: Text(_existing != null ? 'Edit Fire Assessment' : 'New Fire Assessment'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              onPressed: _save,
              icon: const Icon(Icons.check),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // FIRE ORIGIN
          _sectionHeader(colors, 'FIRE ORIGIN & CAUSE'),
          const SizedBox(height: 8),
          _infoCard(colors, LucideIcons.alertTriangle,
              'Document origin for insurance — leave investigation to the fire marshal.'),
          const SizedBox(height: 12),
          _textField(colors, 'Origin Room', _originRoomController, hint: 'e.g., Kitchen'),
          const SizedBox(height: 12),
          _textField(colors, 'Origin Description', _originDescController,
              maxLines: 3, hint: 'Describe the fire origin area'),
          const SizedBox(height: 12),
          _textField(colors, 'Fire Department Report #', _fdReportController),
          const SizedBox(height: 12),
          _textField(colors, 'Fire Department Name', _fdNameController),
          const SizedBox(height: 12),
          _dateField(colors, 'Date of Loss', _lossDate, (d) => setState(() => _lossDate = d)),

          const SizedBox(height: 24),

          // DAMAGE SEVERITY
          _sectionHeader(colors, 'DAMAGE SEVERITY'),
          const SizedBox(height: 8),
          ...DamageSeverity.values.map((s) => RadioListTile<DamageSeverity>(
                title: Text(s.label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
                value: s,
                groupValue: _severity,
                onChanged: (v) => setState(() => _severity = v!),
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),

          const SizedBox(height: 24),

          // STRUCTURAL ASSESSMENT
          _sectionHeader(colors, 'STRUCTURAL ASSESSMENT'),
          const SizedBox(height: 8),
          _switchTile(colors, 'Structural Compromise', _structuralCompromise,
              (v) => setState(() => _structuralCompromise = v)),
          _switchTile(colors, 'Roof Damage', _roofDamage,
              (v) => setState(() => _roofDamage = v)),
          _switchTile(colors, 'Foundation Damage', _foundationDamage,
              (v) => setState(() => _foundationDamage = v)),
          _switchTile(colors, 'Load-Bearing Affected', _loadBearingAffected,
              (v) => setState(() => _loadBearingAffected = v)),
          if (_structuralCompromise || _loadBearingAffected) ...[
            const SizedBox(height: 8),
            _infoCard(colors, LucideIcons.shieldAlert,
                'Structural engineer evaluation recommended before remediation.'),
          ],
          const SizedBox(height: 12),
          _textField(colors, 'Structural Notes', _structuralNotesController, maxLines: 3),

          const SizedBox(height: 24),

          // DAMAGE ZONES
          _sectionHeader(colors, 'DAMAGE ZONES'),
          const SizedBox(height: 8),
          ..._zones.asMap().entries.map((entry) => _buildZoneCard(colors, entry.key, entry.value)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addZone,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Room/Zone'),
          ),

          const SizedBox(height: 24),

          // WATER FROM SUPPRESSION
          _switchTile(colors, 'Water Damage from Fire Suppression', _waterFromSuppression,
              (v) => setState(() => _waterFromSuppression = v)),
          if (_waterFromSuppression)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text(
                'Link to Water Damage Assessment after saving.',
                style: TextStyle(fontSize: 12, color: colors.textTertiary, fontStyle: FontStyle.italic),
              ),
            ),

          const SizedBox(height: 24),

          // NOTES
          _sectionHeader(colors, 'ADDITIONAL NOTES'),
          const SizedBox(height: 8),
          _textField(colors, 'Notes', _notesController, maxLines: 4),

          const SizedBox(height: 32),

          // SAVE
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

  Widget _buildZoneCard(ZaftoColors colors, int index, _DamageZoneEntry zone) {
    return Card(
      color: colors.bgInset,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Zone ${index + 1}',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                          fontSize: 14)),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: colors.textTertiary),
                  onPressed: () => _removeZone(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: zone.room,
              decoration: InputDecoration(
                labelText: 'Room',
                hintText: 'e.g., Kitchen, Bedroom 1',
                labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
                isDense: true,
              ),
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              onChanged: (v) => zone.room = v,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<DamageZoneType>(
              value: zone.zoneType,
              decoration: InputDecoration(
                labelText: 'Zone Type',
                labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
                isDense: true,
              ),
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              dropdownColor: colors.bgInset,
              items: DamageZoneType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) => setState(() => zone.zoneType = v!),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: zone.severity,
              decoration: InputDecoration(
                labelText: 'Severity',
                labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
                isDense: true,
              ),
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              dropdownColor: colors.bgInset,
              items: const [
                DropdownMenuItem(value: 'light', child: Text('Light')),
                DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                DropdownMenuItem(value: 'heavy', child: Text('Heavy')),
              ],
              onChanged: (v) => setState(() => zone.severity = v!),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<SootType?>(
              value: zone.sootType,
              decoration: InputDecoration(
                labelText: 'Soot Type (if applicable)',
                labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
                isDense: true,
              ),
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              dropdownColor: colors.bgInset,
              items: [
                const DropdownMenuItem<SootType?>(value: null, child: Text('None')),
                ...SootType.values.map((t) =>
                    DropdownMenuItem<SootType?>(value: t, child: Text(t.label))),
              ],
              onChanged: (v) => setState(() => zone.sootType = v),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared widgets ──

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

  Widget _textField(ZaftoColors colors, String label,
      TextEditingController controller,
      {int maxLines = 1, String? hint}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
        isDense: true,
      ),
      style: TextStyle(color: colors.textPrimary, fontSize: 14),
    );
  }

  Widget _switchTile(ZaftoColors colors, String title, bool value,
      ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title,
          style: TextStyle(color: colors.textPrimary, fontSize: 14)),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _dateField(ZaftoColors colors, String label, DateTime date,
      ValueChanged<DateTime> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label,
          style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      subtitle: Text(
        '${date.month}/${date.day}/${date.year}',
        style: TextStyle(color: colors.textPrimary, fontSize: 14),
      ),
      trailing: Icon(Icons.calendar_today, size: 18, color: colors.textTertiary),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }

  Widget _infoCard(ZaftoColors colors, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 12, color: colors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _DamageZoneEntry {
  String room;
  DamageZoneType zoneType;
  String severity;
  SootType? sootType;

  _DamageZoneEntry({
    this.room = '',
    this.zoneType = DamageZoneType.smoke,
    this.severity = 'moderate',
    this.sootType,
  });
}
