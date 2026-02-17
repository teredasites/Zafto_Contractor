// ZAFTO Odor Treatment Screen
// Treatment method tracking: thermal fogging, ozone, hydroxyl, air scrubbing
// Sprint REST1 — Fire restoration dedicated tools

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/zafto_colors.dart';
import '../../models/fire_assessment.dart';

class OdorTreatmentScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String fireAssessmentId;

  const OdorTreatmentScreen({
    super.key,
    required this.jobId,
    required this.fireAssessmentId,
  });

  @override
  ConsumerState<OdorTreatmentScreen> createState() =>
      _OdorTreatmentScreenState();
}

class _OdorTreatmentScreenState extends ConsumerState<OdorTreatmentScreen> {
  List<OdorTreatment> _treatments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTreatments();
  }

  Future<void> _loadTreatments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('fire_assessments')
          .select('odor_treatments')
          .eq('id', widget.fireAssessmentId)
          .single();

      final raw = data['odor_treatments'] as List? ?? [];
      _treatments = raw
          .whereType<Map<String, dynamic>>()
          .map((m) => OdorTreatment.fromJson(m))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addTreatment() async {
    final result = await _showAddDialog();
    if (result == null) return;

    final newTreatment = OdorTreatment(
      method: result['method'] as OdorTreatmentMethod,
      room: result['room'] as String,
      startTime: DateTime.now(),
    );

    _treatments.add(newTreatment);
    await _saveTreatments();
  }

  Future<void> _completeTreatment(int index) async {
    final t = _treatments[index];
    _treatments[index] = OdorTreatment(
      method: t.method,
      room: t.room,
      startTime: t.startTime,
      endTime: DateTime.now(),
      equipmentId: t.equipmentId,
      preReading: t.preReading,
      postReading: t.postReading,
      notes: t.notes,
    );
    await _saveTreatments();
  }

  Future<void> _saveTreatments() async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('fire_assessments').update({
        'odor_treatments': _treatments.map((t) => t.toJson()).toList(),
      }).eq('id', widget.fireAssessmentId);

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<Map<String, dynamic>?> _showAddDialog() {
    OdorTreatmentMethod method = OdorTreatmentMethod.thermalFog;
    final roomCtrl = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(ctx).extension<ZaftoColors>()!;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Add Odor Treatment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<OdorTreatmentMethod>(
                    value: method,
                    decoration: const InputDecoration(
                        labelText: 'Treatment Method', isDense: true),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    dropdownColor: colors.bgInset,
                    items: OdorTreatmentMethod.values
                        .map((m) => DropdownMenuItem(
                            value: m, child: Text(m.label)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => method = v!),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: roomCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Room/Area', isDense: true),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.alertTriangle,
                            size: 16, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(method.safetyNote,
                              style: TextStyle(
                                  fontSize: 11, color: colors.textSecondary)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    if (roomCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx, {
                      'method': method,
                      'room': roomCtrl.text.trim(),
                    });
                  },
                  child: const Text('Start Treatment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    final active = _treatments.where((t) => !t.isComplete).toList();
    final completed = _treatments.where((t) => t.isComplete).toList();

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('Odor Treatment')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTreatment,
        child: const Icon(Icons.add),
      ),
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
                          onPressed: _loadTreatments,
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : _treatments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.wind,
                              size: 48, color: colors.textTertiary),
                          const SizedBox(height: 8),
                          Text('No treatments yet',
                              style: TextStyle(color: colors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Tap + to start an odor treatment',
                              style: TextStyle(
                                  fontSize: 12, color: colors.textTertiary)),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Method reference
                        _sectionHeader(colors, 'TREATMENT METHODS'),
                        const SizedBox(height: 8),
                        ...OdorTreatmentMethod.values.map(
                            (m) => _buildMethodRef(colors, m)),

                        if (active.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _sectionHeader(colors, 'ACTIVE TREATMENTS'),
                          const SizedBox(height: 8),
                          ...active.asMap().entries.map((e) =>
                              _buildTreatmentCard(colors, e.value,
                                  _treatments.indexOf(e.value), true)),
                        ],

                        if (completed.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _sectionHeader(colors, 'COMPLETED'),
                          const SizedBox(height: 8),
                          ...completed.map((t) => _buildTreatmentCard(
                              colors, t, _treatments.indexOf(t), false)),
                        ],

                        const SizedBox(height: 80),
                      ],
                    ),
    );
  }

  Widget _buildMethodRef(ZaftoColors colors, OdorTreatmentMethod method) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _methodColor(method),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${method.label}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary)),
          ),
          Text(
            method == OdorTreatmentMethod.ozone ? 'VACANT ONLY' : 'OK occupied',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: method == OdorTreatmentMethod.ozone
                    ? Colors.red
                    : Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentCard(
      ZaftoColors colors, OdorTreatment treatment, int index, bool isActive) {
    return Card(
      color: colors.bgInset,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : colors.textTertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(treatment.method.label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colors.textPrimary)),
                ),
                if (isActive)
                  TextButton(
                    onPressed: () => _completeTreatment(index),
                    child: const Text('Complete'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(LucideIcons.mapPin, size: 13, color: colors.textTertiary),
                const SizedBox(width: 4),
                Text(treatment.room,
                    style:
                        TextStyle(fontSize: 12, color: colors.textSecondary)),
                if (treatment.startTime != null) ...[
                  const SizedBox(width: 12),
                  Icon(LucideIcons.clock, size: 13, color: colors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    'Started ${_formatTime(treatment.startTime!)}',
                    style:
                        TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ],
            ),
            if (treatment.duration != null) ...[
              const SizedBox(height: 4),
              Text(
                'Duration: ${treatment.duration!.inHours}h ${treatment.duration!.inMinutes % 60}m',
                style: TextStyle(fontSize: 12, color: colors.textTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _methodColor(OdorTreatmentMethod method) {
    switch (method) {
      case OdorTreatmentMethod.thermalFog:
        return Colors.orange;
      case OdorTreatmentMethod.ozone:
        return Colors.red;
      case OdorTreatmentMethod.hydroxyl:
        return Colors.green;
      case OdorTreatmentMethod.airScrub:
        return Colors.blue;
      case OdorTreatmentMethod.sealer:
        return Colors.purple;
    }
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
