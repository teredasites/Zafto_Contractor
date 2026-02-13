// ZAFTO Psychrometric Log Entry Screen
// Indoor/outdoor temp+RH → auto-calculate GPP & dew point
// Dehumidifier inlet/outlet tracking, equipment counts
// Phase T3b — Sprint T3: Water Damage Assessment + Moisture

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/zafto_colors.dart';

class PsychrometricLogScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String? tpaAssignmentId;
  final String? waterDamageAssessmentId;

  const PsychrometricLogScreen({
    super.key,
    required this.jobId,
    this.tpaAssignmentId,
    this.waterDamageAssessmentId,
  });

  @override
  ConsumerState<PsychrometricLogScreen> createState() =>
      _PsychrometricLogScreenState();
}

class _PsychrometricLogScreenState
    extends ConsumerState<PsychrometricLogScreen> {
  // Indoor
  final _indoorTempController = TextEditingController();
  final _indoorRhController = TextEditingController();
  // Outdoor
  final _outdoorTempController = TextEditingController();
  final _outdoorRhController = TextEditingController();
  // Dehu inlet/outlet
  final _dehuInletTempController = TextEditingController();
  final _dehuInletRhController = TextEditingController();
  final _dehuOutletTempController = TextEditingController();
  final _dehuOutletRhController = TextEditingController();
  // Equipment counts
  int _dehuCount = 0;
  int _airMoverCount = 0;
  int _scrubberCount = 0;
  int _heaterCount = 0;
  // Room & notes
  final _roomController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _indoorTempController.dispose();
    _indoorRhController.dispose();
    _outdoorTempController.dispose();
    _outdoorRhController.dispose();
    _dehuInletTempController.dispose();
    _dehuInletRhController.dispose();
    _dehuOutletTempController.dispose();
    _dehuOutletRhController.dispose();
    _roomController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Calculate Grains Per Pound from temp (°F) and RH (%)
  static double? _calculateGpp(String tempStr, String rhStr) {
    final tempF = double.tryParse(tempStr);
    final rh = double.tryParse(rhStr);
    if (tempF == null || rh == null) return null;
    final tempC = (tempF - 32) * 5 / 9;
    final es = 6.112 * exp((17.67 * tempC) / (tempC + 243.5));
    final e = (rh / 100) * es;
    final w = 621.97 * (e / (1013.25 - e));
    return (w * 7 * 100).roundToDouble() / 100; // grains/lb
  }

  /// Calculate dew point (°F) from temp (°F) and RH (%)
  static double? _calculateDewPoint(String tempStr, String rhStr) {
    final tempF = double.tryParse(tempStr);
    final rh = double.tryParse(rhStr);
    if (tempF == null || rh == null || rh <= 0) return null;
    final tempC = (tempF - 32) * 5 / 9;
    const a = 17.67;
    const b = 243.5;
    final alpha = (a * tempC) / (b + tempC) + log(rh / 100);
    final dewC = (b * alpha) / (a - alpha);
    return ((dewC * 9 / 5 + 32) * 10).roundToDouble() / 10;
  }

  Future<void> _save() async {
    final indoorTemp = double.tryParse(_indoorTempController.text);
    final indoorRh = double.tryParse(_indoorRhController.text);
    if (indoorTemp == null || indoorRh == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indoor temp and RH are required')),
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

      final indoorGpp = _calculateGpp(
          _indoorTempController.text, _indoorRhController.text);
      final indoorDew = _calculateDewPoint(
          _indoorTempController.text, _indoorRhController.text);
      final outdoorGpp = _calculateGpp(
          _outdoorTempController.text, _outdoorRhController.text);
      final outdoorDew = _calculateDewPoint(
          _outdoorTempController.text, _outdoorRhController.text);
      final dehuInGpp = _calculateGpp(
          _dehuInletTempController.text, _dehuInletRhController.text);
      final dehuOutGpp = _calculateGpp(
          _dehuOutletTempController.text, _dehuOutletRhController.text);

      await supabase.from('psychrometric_logs').insert({
        'company_id': companyId,
        'job_id': widget.jobId,
        'tpa_assignment_id': widget.tpaAssignmentId,
        'water_damage_assessment_id': widget.waterDamageAssessmentId,
        'recorded_by_user_id': user.id,
        'indoor_temp_f': indoorTemp,
        'indoor_rh': indoorRh,
        'indoor_gpp': indoorGpp,
        'indoor_dew_point_f': indoorDew,
        'outdoor_temp_f': double.tryParse(_outdoorTempController.text),
        'outdoor_rh': double.tryParse(_outdoorRhController.text),
        'outdoor_gpp': outdoorGpp,
        'outdoor_dew_point_f': outdoorDew,
        'dehu_inlet_temp_f':
            double.tryParse(_dehuInletTempController.text),
        'dehu_inlet_rh': double.tryParse(_dehuInletRhController.text),
        'dehu_inlet_gpp': dehuInGpp,
        'dehu_outlet_temp_f':
            double.tryParse(_dehuOutletTempController.text),
        'dehu_outlet_rh':
            double.tryParse(_dehuOutletRhController.text),
        'dehu_outlet_gpp': dehuOutGpp,
        'dehumidifiers_running': _dehuCount,
        'air_movers_running': _airMoverCount,
        'air_scrubbers_running': _scrubberCount,
        'heaters_running': _heaterCount,
        'room_name': _roomController.text.isNotEmpty
            ? _roomController.text
            : null,
        'notes':
            _notesController.text.isNotEmpty ? _notesController.text : null,
        'recorded_at': DateTime.now().toUtc().toIso8601String(),
      }).select().single();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Psychrometric log saved'),
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

    final indoorGpp = _calculateGpp(
        _indoorTempController.text, _indoorRhController.text);
    final indoorDew = _calculateDewPoint(
        _indoorTempController.text, _indoorRhController.text);
    final outdoorGpp = _calculateGpp(
        _outdoorTempController.text, _outdoorRhController.text);

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
          'Psychrometric Log',
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
            // Room
            TextField(
              controller: _roomController,
              style: TextStyle(color: colors.textPrimary),
              decoration: _inputDeco('Room Name', colors),
            ),
            const SizedBox(height: 20),

            // Indoor Conditions
            _sectionCard(
              'Indoor Conditions',
              LucideIcons.home,
              Colors.blue,
              colors,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _indoorTempController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: TextStyle(color: colors.textPrimary),
                        decoration: _inputDeco('Temp (°F) *', colors),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _indoorRhController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: TextStyle(color: colors.textPrimary),
                        decoration: _inputDeco('RH (%) *', colors),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                if (indoorGpp != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _calcValue('GPP', indoorGpp.toStringAsFixed(1),
                            Colors.blue, colors),
                        _calcValue(
                            'Dew Point',
                            '${indoorDew?.toStringAsFixed(1) ?? "--"}°F',
                            Colors.blue,
                            colors),
                        if (outdoorGpp != null)
                          _calcValue(
                            'GPP Diff',
                            (indoorGpp - outdoorGpp).toStringAsFixed(1),
                            (indoorGpp - outdoorGpp) > 0
                                ? Colors.amber
                                : Colors.green,
                            colors,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Outdoor Conditions
            _sectionCard(
              'Outdoor Conditions',
              LucideIcons.cloud,
              Colors.grey,
              colors,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _outdoorTempController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: TextStyle(color: colors.textPrimary),
                        decoration: _inputDeco('Temp (°F)', colors),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _outdoorRhController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: TextStyle(color: colors.textPrimary),
                        decoration: _inputDeco('RH (%)', colors),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dehumidifier Performance
            _sectionCard(
              'Dehumidifier Performance',
              LucideIcons.wind,
              Colors.purple,
              colors,
              children: [
                Text(
                  'Inlet (intake air)',
                  style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _dehuInletTempController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: TextStyle(color: colors.textPrimary),
                        decoration: _inputDeco('Temp (°F)', colors),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _dehuInletRhController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: TextStyle(color: colors.textPrimary),
                        decoration: _inputDeco('RH (%)', colors),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Outlet (exhaust air)',
                  style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _dehuOutletTempController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: TextStyle(color: colors.textPrimary),
                        decoration: _inputDeco('Temp (°F)', colors),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _dehuOutletRhController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: TextStyle(color: colors.textPrimary),
                        decoration: _inputDeco('RH (%)', colors),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Equipment Counts
            _sectionCard(
              'Equipment Running',
              LucideIcons.settings,
              Colors.teal,
              colors,
              children: [
                _counterRow('Dehumidifiers', _dehuCount, (v) {
                  setState(() => _dehuCount = v);
                }, colors),
                _counterRow('Air Movers', _airMoverCount, (v) {
                  setState(() => _airMoverCount = v);
                }, colors),
                _counterRow('Air Scrubbers', _scrubberCount, (v) {
                  setState(() => _scrubberCount = v);
                }, colors),
                _counterRow('Heaters', _heaterCount, (v) {
                  setState(() => _heaterCount = v);
                }, colors),
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

  Widget _sectionCard(
    String title,
    IconData icon,
    Color accent,
    ZaftoColors colors, {
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _calcValue(
      String label, String value, Color color, ZaftoColors colors) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  Widget _counterRow(
      String label, int value, ValueChanged<int> onChanged, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
            ),
          ),
          IconButton(
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: Icon(LucideIcons.minus, size: 18, color: colors.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            onPressed: () => onChanged(value + 1),
            icon: Icon(LucideIcons.plus, size: 18, color: colors.accentPrimary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
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
