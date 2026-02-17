// ZAFTO Air Sampling Screen
// Pre/post remediation air samples, chain of custody, lab results
// Sprint REST2 — Mold remediation dedicated tools

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/zafto_colors.dart';
import '../../models/mold_assessment.dart';

class AirSamplingScreen extends ConsumerStatefulWidget {
  final String moldAssessmentId;
  final String companyId;

  const AirSamplingScreen({
    super.key,
    required this.moldAssessmentId,
    required this.companyId,
  });

  @override
  ConsumerState<AirSamplingScreen> createState() => _AirSamplingScreenState();
}

class _AirSamplingScreenState extends ConsumerState<AirSamplingScreen> {
  List<Map<String, dynamic>> _samples = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSamples();
  }

  Future<void> _loadSamples() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('mold_chain_of_custody')
          .select()
          .eq('mold_assessment_id', widget.moldAssessmentId)
          .order('created_at', ascending: false);

      _samples = (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addSample() async {
    SampleType sampleType = SampleType.air;
    final locationCtrl = TextEditingController();
    final labCtrl = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(ctx).extension<ZaftoColors>()!;
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Collect Sample'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<SampleType>(
                    value: sampleType,
                    decoration: const InputDecoration(labelText: 'Sample Type', isDense: true),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    dropdownColor: colors.bgInset,
                    items: SampleType.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => sampleType = v!),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: locationCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Sample Location', hintText: 'e.g., Master bedroom, center', isDense: true),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: labCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Lab Name', hintText: 'e.g., EMSL Analytical', isDense: true),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  if (locationCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx, {
                    'sample_type': sampleType.dbValue,
                    'location': locationCtrl.text.trim(),
                    'lab': labCtrl.text.trim(),
                  });
                },
                child: const Text('Collect'),
              ),
            ],
          );
        });
      },
    );

    if (result == null) return;

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      await supabase.from('mold_chain_of_custody').insert({
        'company_id': widget.companyId,
        'mold_assessment_id': widget.moldAssessmentId,
        'sample_type': result['sample_type'],
        'sample_location': result['location'],
        'lab_name': result['lab'],
        'collected_by': user?.email ?? 'Unknown',
        'collected_at': DateTime.now().toUtc().toIso8601String(),
      });

      await _loadSamples();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _updateSampleStatus(String sampleId, String field) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('mold_chain_of_custody').update({
        field: DateTime.now().toUtc().toIso8601String(),
      }).eq('id', sampleId);

      await _loadSamples();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    final preSamples = _samples.where((s) => s['pass_fail'] == null || s['pass_fail'] == '').toList();
    final completed = _samples.where((s) => s['pass_fail'] != null && s['pass_fail'] != '').toList();

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('Air Sampling')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSample,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.alertCircle, size: 48, color: colors.textTertiary),
                      const SizedBox(height: 8),
                      Text(_error!, style: TextStyle(color: colors.textSecondary)),
                      TextButton(onPressed: _loadSamples, child: const Text('Retry')),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Protocol reference
                    _sectionHeader(colors, 'SAMPLING PROTOCOL'),
                    const SizedBox(height: 8),
                    _infoCard(colors, LucideIcons.info, 'Minimum: 3 indoor + 1 outdoor baseline. Spore trap cassette at 15 LPM for 5 minutes. Maintain chain of custody.'),

                    // Stats
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.bgInset,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statCol(colors, '${_samples.length}', 'Total'),
                          _statCol(colors, '${preSamples.length}', 'Pending'),
                          _statCol(colors, '${completed.length}', 'Results'),
                        ],
                      ),
                    ),

                    // Samples
                    const SizedBox(height: 24),
                    _sectionHeader(colors, 'COLLECTED SAMPLES'),
                    const SizedBox(height: 8),

                    if (_samples.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(LucideIcons.testTubes, size: 40, color: colors.textTertiary),
                              const SizedBox(height: 8),
                              Text('No samples collected', style: TextStyle(color: colors.textSecondary)),
                              const SizedBox(height: 4),
                              Text('Tap + to collect a sample', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._samples.map((s) => _buildSampleCard(colors, s)),

                    const SizedBox(height: 80),
                  ],
                ),
    );
  }

  Widget _buildSampleCard(ZaftoColors colors, Map<String, dynamic> sample) {
    final sampleType = SampleType.fromString(sample['sample_type'] as String?);
    final hasResult = sample['pass_fail'] != null && (sample['pass_fail'] as String).isNotEmpty;
    final pass = sample['pass_fail'] == 'pass';

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
                Icon(LucideIcons.testTubes, size: 16, color: colors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(sampleType.label,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.textPrimary)),
                ),
                if (hasResult)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (pass ? Colors.green : Colors.red).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      pass ? 'PASS' : 'FAIL',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: pass ? Colors.green : Colors.red),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(sample['sample_location'] as String? ?? '',
                style: TextStyle(fontSize: 12, color: colors.textSecondary)),
            const SizedBox(height: 4),

            // Chain of custody timeline
            _timelineRow(colors, 'Collected', sample['collected_at'] as String?),
            _timelineRow(colors, 'Shipped to lab', sample['shipped_to_lab_at'] as String?),
            _timelineRow(colors, 'Lab received', sample['lab_received_at'] as String?),
            _timelineRow(colors, 'Results', sample['results_available_at'] as String?),

            // Action buttons
            if (!hasResult) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (sample['shipped_to_lab_at'] == null)
                    TextButton(
                      onPressed: () => _updateSampleStatus(sample['id'] as String, 'shipped_to_lab_at'),
                      child: const Text('Mark Shipped'),
                    ),
                  if (sample['shipped_to_lab_at'] != null && sample['lab_received_at'] == null)
                    TextButton(
                      onPressed: () => _updateSampleStatus(sample['id'] as String, 'lab_received_at'),
                      child: const Text('Mark Received'),
                    ),
                  if (sample['lab_received_at'] != null && sample['results_available_at'] == null)
                    TextButton(
                      onPressed: () => _updateSampleStatus(sample['id'] as String, 'results_available_at'),
                      child: const Text('Results In'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _timelineRow(ZaftoColors colors, String label, String? dateStr) {
    final done = dateStr != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 12,
            color: done ? Colors.green : colors.textTertiary,
          ),
          const SizedBox(width: 6),
          Text('$label: ',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: colors.textSecondary)),
          Text(
            done ? _formatDate(dateStr!) : 'Pending',
            style: TextStyle(fontSize: 10, color: done ? colors.textPrimary : colors.textTertiary),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _statCol(ZaftoColors colors, String value, String label) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: colors.textPrimary)),
        Text(label, style: TextStyle(fontSize: 11, color: colors.textTertiary)),
      ],
    );
  }

  Widget _infoCard(ZaftoColors colors, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.borderSubtle)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: colors.textSecondary))),
        ],
      ),
    );
  }

  Widget _sectionHeader(ZaftoColors colors, String label) {
    return Text(label,
        style: TextStyle(fontFamily: 'SF Pro Text', fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: colors.textTertiary));
  }
}
