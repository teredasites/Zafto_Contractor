// ZAFTO Remediation Protocol Screen
// IICRC S520 step-by-step work plan, material removal, equipment, PPE, antimicrobial
// Sprint REST2 — Mold remediation dedicated tools

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/zafto_colors.dart';
import '../../models/mold_assessment.dart';

class RemediationProtocolScreen extends ConsumerStatefulWidget {
  final String moldAssessmentId;

  const RemediationProtocolScreen({
    super.key,
    required this.moldAssessmentId,
  });

  @override
  ConsumerState<RemediationProtocolScreen> createState() =>
      _RemediationProtocolScreenState();
}

class _RemediationProtocolScreenState
    extends ConsumerState<RemediationProtocolScreen> {
  MoldAssessment? _assessment;
  bool _isLoading = true;
  String? _error;

  // Protocol steps by IICRC level
  static const _level1Steps = [
    'Establish work area isolation (mini containment if needed)',
    'Don PPE: N95 respirator, goggles, gloves',
    'Mist affected area to suppress spores',
    'Remove affected porous materials (drywall, insulation)',
    'HEPA vacuum all surfaces in work area',
    'Clean non-porous surfaces with antimicrobial solution',
    'Apply antimicrobial treatment to framing/studs',
    'Dry area to <60% RH within 24-48 hours',
    'Visual inspection — no visible mold remaining',
    'Document with photos before/after',
  ];

  static const _level2Steps = [
    'Establish limited or full containment with poly sheeting',
    'Install negative air machine (exhaust outside)',
    'Don PPE: half-face P100 respirator, goggles, Tyvek suit, gloves',
    'Pre-remediation air sampling (minimum 3 indoor + 1 outdoor)',
    'Mist affected area to suppress spore dispersal',
    'Remove and bag all affected porous materials (double-bag)',
    'HEPA vacuum all surfaces inside containment — walls, ceiling, floor',
    'Wire brush or sand non-porous surfaces showing staining',
    'Clean all non-porous surfaces with antimicrobial solution',
    'Apply antimicrobial sealant/encapsulant to framing and studs',
    'HEPA vacuum entire containment area (second pass)',
    'Verify negative pressure maintained throughout',
    'Allow antimicrobial to cure per manufacturer specs',
    'Post-remediation air sampling (same locations as pre)',
    'Await lab results — compare to outdoor baseline',
    'Third-party clearance inspection if required',
    'Remove containment only after clearance',
    'Document all work with dated photos',
  ];

  static const _level3Steps = [
    'Notify building occupants — area OFF LIMITS during remediation',
    'Establish FULL containment with double-layer 6-mil poly',
    'Install decontamination chamber at containment entry',
    'Install negative air machines — maintain -0.02" WC minimum',
    'Position HEPA air scrubbers inside containment',
    'Don PPE: full-face P100 respirator, goggles, full Tyvek, boot covers, gloves',
    'Seal all HVAC registers, electrical outlets, and penetrations',
    'Pre-remediation air sampling (minimum 5 indoor + 2 outdoor)',
    'Heavy mist affected area to suppress spore dispersal',
    'Remove and double-bag ALL affected porous materials',
    'Remove affected drywall minimum 2 feet beyond visible mold',
    'HEPA vacuum all surfaces — walls, ceiling, floor, framing',
    'Wire brush or sand all non-porous surfaces with staining',
    'Clean all surfaces with antimicrobial solution (EPA registered)',
    'Apply antimicrobial sealant/encapsulant — all exposed framing',
    'Second HEPA vacuum pass — entire containment',
    'Third HEPA vacuum pass after 24-hour settling period',
    'Verify containment integrity daily — log pressure readings',
    'Allow antimicrobial to fully cure (24-72 hours per product)',
    'Post-remediation air sampling (same locations as pre)',
    'Submit samples to AIHA-accredited laboratory',
    'MANDATORY third-party clearance inspection',
    'Clearance inspector verifies: no visible mold, normal moisture, acceptable air quality',
    'Remove containment ONLY after written clearance received',
    'Final documentation package: photos, air results, clearance letter',
  ];

  static const _materialTypes = [
    'Drywall / Sheetrock',
    'Insulation (fiberglass batt)',
    'Insulation (blown-in)',
    'Insulation (spray foam)',
    'Carpet and pad',
    'Hardwood flooring',
    'Vinyl / LVP flooring',
    'Ceiling tiles',
    'Baseboards / trim',
    'Cabinets',
    'Framing lumber (if structurally compromised)',
    'HVAC ductwork / flex duct',
    'Wallpaper / wall covering',
    'Clothing / textiles',
    'Furniture / upholstery',
  ];

  static const _equipmentTypes = [
    'HEPA air scrubber',
    'Negative air machine',
    'Dehumidifier (LGR)',
    'Dehumidifier (conventional)',
    'Air mover / fan',
    'Moisture meter (pin)',
    'Moisture meter (pinless)',
    'Thermo-hygrometer',
    'Manometer (pressure differential)',
    'HEPA vacuum',
    'Pump sprayer (antimicrobial)',
    'Fogger (ULV)',
    'Thermal fogger',
    'Hydroxyl generator',
    'Ozone generator',
    'Air sampling pump',
    'Spore trap cassettes',
    'PPE kit (respirators, Tyvek, gloves)',
    'Poly sheeting (6-mil)',
    'Decon chamber materials',
  ];

  @override
  void initState() {
    super.initState();
    _loadAssessment();
  }

  Future<void> _loadAssessment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('mold_assessments')
          .select()
          .eq('id', widget.moldAssessmentId)
          .single();

      _assessment = MoldAssessment.fromJson(data);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> _stepsForLevel(IicrcLevel level) {
    switch (level) {
      case IicrcLevel.level1:
        return _level1Steps;
      case IicrcLevel.level2:
        return _level2Steps;
      case IicrcLevel.level3:
        return _level3Steps;
    }
  }

  Future<void> _toggleProtocolStep(int index, bool completed) async {
    if (_assessment == null) return;

    final steps = List<Map<String, dynamic>>.from(_assessment!.protocolSteps);

    // Find or create step entry
    final existing = steps.indexWhere((s) => s['step_index'] == index);
    if (existing >= 0) {
      steps[existing] = {
        ...steps[existing],
        'completed': completed,
        'completed_at':
            completed ? DateTime.now().toUtc().toIso8601String() : null,
      };
    } else {
      steps.add({
        'step_index': index,
        'completed': completed,
        'completed_at':
            completed ? DateTime.now().toUtc().toIso8601String() : null,
        'completed_by':
            Supabase.instance.client.auth.currentUser?.email ?? 'Unknown',
      });
    }

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('mold_assessments').update({
        'protocol_steps': steps,
      }).eq('id', widget.moldAssessmentId);

      await _loadAssessment();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _addMaterialRemoval(String material) async {
    if (_assessment == null) return;

    final materials =
        List<Map<String, dynamic>>.from(_assessment!.materialRemoval);
    materials.add({
      'material': material,
      'removed_at': DateTime.now().toUtc().toIso8601String(),
      'removed_by':
          Supabase.instance.client.auth.currentUser?.email ?? 'Unknown',
    });

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('mold_assessments').update({
        'material_removal': materials,
      }).eq('id', widget.moldAssessmentId);

      await _loadAssessment();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _addEquipment(String equipment) async {
    if (_assessment == null) return;

    final equipmentList =
        List<Map<String, dynamic>>.from(_assessment!.equipmentDeployed);
    equipmentList.add({
      'equipment': equipment,
      'deployed_at': DateTime.now().toUtc().toIso8601String(),
      'deployed_by':
          Supabase.instance.client.auth.currentUser?.email ?? 'Unknown',
    });

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('mold_assessments').update({
        'equipment_deployed': equipmentList,
      }).eq('id', widget.moldAssessmentId);

      await _loadAssessment();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showAddMaterialDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(ctx).extension<ZaftoColors>()!;
        return AlertDialog(
          title: const Text('Add Material Removed'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _materialTypes.length,
              itemBuilder: (ctx, i) {
                return ListTile(
                  dense: true,
                  title: Text(_materialTypes[i],
                      style:
                          TextStyle(fontSize: 13, color: colors.textPrimary)),
                  onTap: () => Navigator.pop(ctx, _materialTypes[i]),
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
          ],
        );
      },
    );

    if (result != null) await _addMaterialRemoval(result);
  }

  Future<void> _showAddEquipmentDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(ctx).extension<ZaftoColors>()!;
        return AlertDialog(
          title: const Text('Add Equipment Deployed'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _equipmentTypes.length,
              itemBuilder: (ctx, i) {
                return ListTile(
                  dense: true,
                  title: Text(_equipmentTypes[i],
                      style:
                          TextStyle(fontSize: 13, color: colors.textPrimary)),
                  onTap: () => Navigator.pop(ctx, _equipmentTypes[i]),
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
          ],
        );
      },
    );

    if (result != null) await _addEquipment(result);
  }

  bool _isStepCompleted(int index) {
    if (_assessment == null) return false;
    final step = _assessment!.protocolSteps
        .where((s) => s['step_index'] == index)
        .firstOrNull;
    return step != null && step['completed'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('Remediation Protocol')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.alertCircle,
                          size: 48, color: colors.textTertiary),
                      const SizedBox(height: 8),
                      Text(_error!,
                          style: TextStyle(color: colors.textSecondary)),
                      TextButton(
                          onPressed: _loadAssessment,
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : _assessment == null
                  ? Center(
                      child: Text('Assessment not found',
                          style: TextStyle(color: colors.textSecondary)))
                  : _buildContent(colors),
    );
  }

  Widget _buildContent(ZaftoColors colors) {
    final level = _assessment!.iicrcLevel;
    final steps = _stepsForLevel(level);
    final completedCount =
        steps.asMap().entries.where((e) => _isStepCompleted(e.key)).length;
    final progress = steps.isEmpty ? 0.0 : completedCount / steps.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Level + progress header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgInset,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.shield, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(level.label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colors.textPrimary)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: colors.borderSubtle,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$completedCount of ${steps.length} steps complete (${(progress * 100).toInt()}%)',
                style: TextStyle(fontSize: 11, color: colors.textTertiary),
              ),
            ],
          ),
        ),

        // Protocol steps
        const SizedBox(height: 20),
        _sectionHeader(colors, 'PROTOCOL STEPS'),
        const SizedBox(height: 8),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final completed = _isStepCompleted(index);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: completed,
                    onChanged: (v) =>
                        _toggleProtocolStep(index, v ?? false),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    activeColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${index + 1}. $step',
                      style: TextStyle(
                        fontSize: 13,
                        color: completed
                            ? colors.textTertiary
                            : colors.textPrimary,
                        decoration:
                            completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        // Material removal
        const SizedBox(height: 24),
        _sectionHeader(colors, 'MATERIALS REMOVED'),
        const SizedBox(height: 8),

        if (_assessment!.materialRemoval.isEmpty)
          _emptyState(
              colors, LucideIcons.trash2, 'No materials logged yet')
        else
          ..._assessment!.materialRemoval.map((m) => Card(
                color: colors.bgInset,
                margin: const EdgeInsets.only(bottom: 6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(LucideIcons.trash2,
                          size: 14, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(m['material'] as String? ?? '',
                            style: TextStyle(
                                fontSize: 13, color: colors.textPrimary)),
                      ),
                      Text(
                        _formatDate(m['removed_at'] as String?),
                        style: TextStyle(
                            fontSize: 10, color: colors.textTertiary),
                      ),
                    ],
                  ),
                ),
              )),

        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _showAddMaterialDialog,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Log Material Removed'),
        ),

        // Equipment deployed
        const SizedBox(height: 24),
        _sectionHeader(colors, 'EQUIPMENT DEPLOYED'),
        const SizedBox(height: 8),

        if (_assessment!.equipmentDeployed.isEmpty)
          _emptyState(
              colors, LucideIcons.wrench, 'No equipment logged yet')
        else
          ..._assessment!.equipmentDeployed.map((eq) => Card(
                color: colors.bgInset,
                margin: const EdgeInsets.only(bottom: 6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(LucideIcons.wrench,
                          size: 14, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(eq['equipment'] as String? ?? '',
                            style: TextStyle(
                                fontSize: 13, color: colors.textPrimary)),
                      ),
                      Text(
                        _formatDate(eq['deployed_at'] as String?),
                        style: TextStyle(
                            fontSize: 10, color: colors.textTertiary),
                      ),
                    ],
                  ),
                ),
              )),

        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _showAddEquipmentDialog,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Log Equipment Deployed'),
        ),

        // PPE reference
        const SizedBox(height: 24),
        _sectionHeader(colors, 'PPE REQUIREMENTS'),
        const SizedBox(height: 8),
        _infoCard(colors, LucideIcons.hardHat, level.ppeRequired),

        // Antimicrobial reference
        const SizedBox(height: 16),
        _sectionHeader(colors, 'ANTIMICROBIAL REFERENCE'),
        const SizedBox(height: 8),
        _infoCard(colors, LucideIcons.droplets,
            'Use EPA-registered antimicrobial products only. Apply per manufacturer specs. '
            'Common products: Benefect Decon 30, Concrobium, Sporicidin. '
            'Allow full contact time before encapsulation.'),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _emptyState(ZaftoColors colors, IconData icon, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: colors.textTertiary),
            const SizedBox(height: 6),
            Text(text,
                style: TextStyle(fontSize: 12, color: colors.textSecondary)),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style:
                      TextStyle(fontSize: 12, color: colors.textSecondary))),
        ],
      ),
    );
  }

  Widget _sectionHeader(ZaftoColors colors, String label) {
    return Text(label,
        style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: colors.textTertiary));
  }
}
