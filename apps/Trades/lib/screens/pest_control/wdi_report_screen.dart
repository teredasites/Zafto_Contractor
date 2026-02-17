// ZAFTO WDI Report Screen — NPMA-33 Wood Destroying Insect Inspection
// Findings per area, evidence types, recommendations
// Sprint NICHE1 — Pest control module

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/zafto_colors.dart';
import '../../models/wdi_report.dart';

class WdiReportScreen extends ConsumerStatefulWidget {
  final String? jobId;
  final String? existingReportId;

  const WdiReportScreen({super.key, this.jobId, this.existingReportId});

  @override
  ConsumerState<WdiReportScreen> createState() => _WdiReportScreenState();
}

class _WdiReportScreenState extends ConsumerState<WdiReportScreen> {
  WdiReportType _reportType = WdiReportType.npma33;
  final _addressCtrl = TextEditingController();
  final _inspectorCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  bool _infestationFound = false;
  bool _damageFound = false;
  bool _treatmentRecommended = false;
  bool _liveInsects = false;
  bool _deadInsects = false;
  bool _damageVisible = false;
  bool _frass = false;
  bool _shelterTubes = false;
  bool _exitHoles = false;
  bool _moisture = false;
  final _recommendationsCtrl = TextEditingController();
  bool _isSaving = false;
  bool _isLoading = false;

  static const _commonInsects = [
    'Subterranean Termites',
    'Drywood Termites',
    'Dampwood Termites',
    'Carpenter Ants',
    'Carpenter Bees',
    'Powder Post Beetles',
    'Old House Borers',
    'Wood Boring Beetles',
    'Bark Beetles',
  ];

  final List<String> _selectedInsects = [];

  static const _inspectionAreas = [
    'Exterior — Foundation',
    'Exterior — Siding',
    'Exterior — Roof / Eaves',
    'Exterior — Deck / Porch',
    'Exterior — Fence',
    'Crawlspace',
    'Basement',
    'Garage',
    'Attic',
    'Kitchen',
    'Bathrooms',
    'Living Areas',
    'Bedrooms',
    'Utility / Laundry',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingReportId != null) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('wdi_reports')
          .select()
          .eq('id', widget.existingReportId!)
          .single();
      final r = WdiReport.fromJson(data);
      _reportType = r.reportType;
      _addressCtrl.text = r.fullAddress;
      _inspectorCtrl.text = r.inspectorName ?? '';
      _licenseCtrl.text = r.inspectorLicense ?? '';
      _infestationFound = r.infestationFound;
      _damageFound = r.damageFound;
      _treatmentRecommended = r.treatmentRecommended;
      _liveInsects = r.liveInsectsFound;
      _deadInsects = r.deadInsectsFound;
      _damageVisible = r.damageVisible;
      _frass = r.frassFound;
      _shelterTubes = r.shelterTubesFound;
      _exitHoles = r.exitHolesFound;
      _moisture = r.moistureDamage;
      _selectedInsects.addAll(r.insectsIdentified);
      _recommendationsCtrl.text = r.recommendations ?? '';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _inspectorCtrl.dispose();
    _licenseCtrl.dispose();
    _recommendationsCtrl.dispose();
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
        if (widget.jobId != null) 'job_id': widget.jobId,
        'report_type': _reportType.dbValue,
        'inspector_name': _inspectorCtrl.text.trim(),
        'inspector_license': _licenseCtrl.text.trim(),
        'inspection_date': DateTime.now().toIso8601String().split('T')[0],
        'infestation_found': _infestationFound,
        'damage_found': _damageFound,
        'treatment_recommended': _treatmentRecommended,
        'live_insects_found': _liveInsects,
        'dead_insects_found': _deadInsects,
        'damage_visible': _damageVisible,
        'frass_found': _frass,
        'shelter_tubes_found': _shelterTubes,
        'exit_holes_found': _exitHoles,
        'moisture_damage': _moisture,
        'insects_identified': _selectedInsects,
        'recommendations': _recommendationsCtrl.text.trim(),
        'report_status': 'complete',
      };

      if (widget.existingReportId != null) {
        await supabase.from('wdi_reports').update(payload).eq('id', widget.existingReportId!);
      } else {
        await supabase.from('wdi_reports').insert(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WDI report saved')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        appBar: AppBar(title: const Text('WDI Report')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: const Text('WDI / NPMA-33 Report'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Report type
          _sectionHeader(colors, 'REPORT TYPE'),
          const SizedBox(height: 8),
          DropdownButtonFormField<WdiReportType>(
            value: _reportType,
            decoration: const InputDecoration(labelText: 'Report Form', isDense: true),
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
            dropdownColor: colors.bgInset,
            items: WdiReportType.values
                .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                .toList(),
            onChanged: (v) => setState(() => _reportType = v!),
          ),

          const SizedBox(height: 20),
          _sectionHeader(colors, 'INSPECTOR'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _inspectorCtrl,
            decoration: const InputDecoration(labelText: 'Inspector Name', isDense: true),
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _licenseCtrl,
            decoration: const InputDecoration(labelText: 'License Number', isDense: true),
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
          ),

          // Evidence
          const SizedBox(height: 20),
          _sectionHeader(colors, 'EVIDENCE FOUND'),
          const SizedBox(height: 8),
          _evidenceToggle(colors, 'Live insects', _liveInsects, (v) => setState(() => _liveInsects = v)),
          _evidenceToggle(colors, 'Dead insects', _deadInsects, (v) => setState(() => _deadInsects = v)),
          _evidenceToggle(colors, 'Visible damage', _damageVisible, (v) => setState(() => _damageVisible = v)),
          _evidenceToggle(colors, 'Frass (insect droppings)', _frass, (v) => setState(() => _frass = v)),
          _evidenceToggle(colors, 'Shelter tubes', _shelterTubes, (v) => setState(() => _shelterTubes = v)),
          _evidenceToggle(colors, 'Exit holes', _exitHoles, (v) => setState(() => _exitHoles = v)),
          _evidenceToggle(colors, 'Moisture damage', _moisture, (v) => setState(() => _moisture = v)),

          // Determination
          const SizedBox(height: 20),
          _sectionHeader(colors, 'DETERMINATION'),
          const SizedBox(height: 8),
          _evidenceToggle(colors, 'Infestation found', _infestationFound, (v) => setState(() => _infestationFound = v)),
          _evidenceToggle(colors, 'Damage found', _damageFound, (v) => setState(() => _damageFound = v)),
          _evidenceToggle(colors, 'Treatment recommended', _treatmentRecommended, (v) => setState(() => _treatmentRecommended = v)),

          // Insects identified
          const SizedBox(height: 20),
          _sectionHeader(colors, 'INSECTS IDENTIFIED'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _commonInsects.map((insect) {
              final selected = _selectedInsects.contains(insect);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) {
                    _selectedInsects.remove(insect);
                  } else {
                    _selectedInsects.add(insect);
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? Colors.red.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: selected ? Colors.red : colors.borderSubtle),
                  ),
                  child: Text(insect,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? Colors.red : colors.textSecondary,
                      )),
                ),
              );
            }).toList(),
          ),

          // Recommendations
          const SizedBox(height: 20),
          _sectionHeader(colors, 'RECOMMENDATIONS'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _recommendationsCtrl,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Recommendations', isDense: true),
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
          ),

          // Inspection areas reference
          const SizedBox(height: 20),
          _sectionHeader(colors, 'INSPECTION AREAS'),
          const SizedBox(height: 8),
          ..._inspectionAreas.map((area) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(LucideIcons.checkSquare, size: 14, color: colors.textTertiary),
                    const SizedBox(width: 8),
                    Text(area, style: TextStyle(fontSize: 13, color: colors.textPrimary)),
                  ],
                ),
              )),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              child: Text(_isSaving ? 'Saving...' : 'Save WDI Report'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _evidenceToggle(ZaftoColors colors, String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _sectionHeader(ZaftoColors colors, String label) {
    return Text(label,
        style: TextStyle(
            fontFamily: 'SF Pro Text', fontSize: 11, fontWeight: FontWeight.w600,
            letterSpacing: 0.5, color: colors.textTertiary));
  }
}
