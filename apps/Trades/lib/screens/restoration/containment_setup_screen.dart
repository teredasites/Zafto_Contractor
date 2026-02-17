// ZAFTO Containment Setup Screen
// Containment type documentation, negative air, HEPA zones, integrity checks
// Sprint REST2 — Mold remediation dedicated tools

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/zafto_colors.dart';

class ContainmentSetupScreen extends ConsumerStatefulWidget {
  final String moldAssessmentId;

  const ContainmentSetupScreen({
    super.key,
    required this.moldAssessmentId,
  });

  @override
  ConsumerState<ContainmentSetupScreen> createState() =>
      _ContainmentSetupScreenState();
}

class _ContainmentSetupScreenState extends ConsumerState<ContainmentSetupScreen> {
  List<Map<String, dynamic>> _checks = [];
  bool _isLoading = true;
  String? _error;

  static const _checklistItems = [
    'Poly sheeting installed (6-mil minimum)',
    'All seams taped with poly tape',
    'Zippered entry door installed',
    'Decontamination chamber set up',
    'Negative air machine running',
    'HEPA air scrubber positioned',
    'Air pressure differential confirmed (-0.02" WC minimum)',
    'Warning signs posted at containment entry',
    'PPE staging area established outside containment',
    'Critical barriers sealed (HVAC registers, electrical outlets)',
    'Floor protection installed (poly + tape)',
    'Waste disposal bags staged inside containment',
  ];

  @override
  void initState() {
    super.initState();
    _loadChecks();
  }

  Future<void> _loadChecks() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('mold_assessments')
          .select('containment_checks')
          .eq('id', widget.moldAssessmentId)
          .single();

      _checks = ((data['containment_checks'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addIntegrityCheck() async {
    final user = Supabase.instance.client.auth.currentUser;
    final check = {
      'date': DateTime.now().toUtc().toIso8601String(),
      'inspector': user?.email ?? 'Unknown',
      'pressure_reading': '-0.02',
      'integrity_pass': true,
      'notes': '',
    };

    _checks.add(check);
    await _saveChecks();
  }

  Future<void> _saveChecks() async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('mold_assessments').update({
        'containment_checks': _checks,
      }).eq('id', widget.moldAssessmentId);

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('Containment Setup')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: colors.textSecondary)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _sectionHeader(colors, 'SETUP CHECKLIST'),
                    const SizedBox(height: 8),
                    ..._checklistItems.map((item) => _buildCheckItem(colors, item)),

                    const SizedBox(height: 24),

                    _sectionHeader(colors, 'DAILY INTEGRITY CHECKS'),
                    const SizedBox(height: 8),
                    _infoCard(colors, LucideIcons.alertTriangle,
                        'Containment integrity must be verified daily. Record pressure readings and visual inspection.'),
                    const SizedBox(height: 12),

                    if (_checks.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(LucideIcons.clipboardCheck,
                                  size: 40, color: colors.textTertiary),
                              const SizedBox(height: 8),
                              Text('No integrity checks recorded',
                                  style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._checks.asMap().entries.map((entry) {
                        final check = entry.value;
                        final pass = check['integrity_pass'] as bool? ?? true;
                        return Card(
                          color: colors.bgInset,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  pass ? LucideIcons.checkCircle : LucideIcons.xCircle,
                                  size: 20,
                                  color: pass ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Check ${entry.key + 1}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: colors.textPrimary),
                                      ),
                                      Text(
                                        'Pressure: ${check['pressure_reading'] ?? 'N/A'}" WC | '
                                        '${pass ? 'PASS' : 'FAIL'}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: colors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatDate(check['date'] as String?),
                                  style: TextStyle(fontSize: 10, color: colors.textTertiary),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _addIntegrityCheck,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Record Integrity Check'),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
    );
  }

  Widget _buildCheckItem(ZaftoColors colors, String item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: false,
              onChanged: (_) {},
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(item,
                style: TextStyle(fontSize: 13, color: colors.textPrimary)),
          ),
        ],
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
        children: [
          Icon(icon, size: 18, color: Colors.amber),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: colors.textSecondary))),
        ],
      ),
    );
  }

  Widget _sectionHeader(ZaftoColors colors, String label) {
    return Text(label,
        style: TextStyle(
            fontFamily: 'SF Pro Text', fontSize: 11, fontWeight: FontWeight.w600,
            letterSpacing: 0.5, color: colors.textTertiary));
  }
}
