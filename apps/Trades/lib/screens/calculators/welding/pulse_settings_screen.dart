import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pulse Settings Calculator - Pulse MIG/TIG parameters
class PulseSettingsScreen extends ConsumerStatefulWidget {
  const PulseSettingsScreen({super.key});
  @override
  ConsumerState<PulseSettingsScreen> createState() => _PulseSettingsScreenState();
}

class _PulseSettingsScreenState extends ConsumerState<PulseSettingsScreen> {
  final _thicknessController = TextEditingController();
  final _travelSpeedController = TextEditingController(text: '10');
  String _process = 'Pulse MIG';
  String _material = 'Steel';

  double? _peakAmps;
  double? _backgroundAmps;
  double? _pulseFrequency;
  double? _peakTime;
  String? _notes;

  void _calculate() {
    final thickness = double.tryParse(_thicknessController.text);
    final travelSpeed = double.tryParse(_travelSpeedController.text) ?? 10;

    if (thickness == null || thickness <= 0) {
      setState(() { _peakAmps = null; });
      return;
    }

    // Base amperage from thickness
    double baseAmps = thickness * 1000; // 1 amp per 0.001"

    // Material adjustments
    if (_material == 'Aluminum') {
      baseAmps *= 1.3;
    } else if (_material == 'Stainless') {
      baseAmps *= 0.9;
    }

    double peakAmps, backgroundAmps, pulseFrequency, peakTime;
    String notes;

    if (_process == 'Pulse MIG') {
      // Pulse MIG typical settings
      peakAmps = baseAmps * 1.5;
      backgroundAmps = baseAmps * 0.3;
      pulseFrequency = 100 + (travelSpeed * 5); // Hz
      peakTime = 1.5 + (thickness * 2); // ms
      notes = 'One drop per pulse, adjust frequency for travel speed';
    } else {
      // Pulse TIG
      peakAmps = baseAmps * 1.8;
      backgroundAmps = baseAmps * 0.25;
      pulseFrequency = 0.5 + (1 / thickness).clamp(0.5, 10); // PPS for TIG
      peakTime = 50; // % on time
      notes = 'Peak time as % duty cycle, lower frequency for thicker material';
    }

    setState(() {
      _peakAmps = peakAmps;
      _backgroundAmps = backgroundAmps;
      _pulseFrequency = pulseFrequency;
      _peakTime = peakTime;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _thicknessController.clear();
    _travelSpeedController.text = '10';
    setState(() { _peakAmps = null; });
  }

  @override
  void dispose() {
    _thicknessController.dispose();
    _travelSpeedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Pulse Settings', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildProcessSelector(colors),
            const SizedBox(height: 12),
            _buildMaterialSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Material Thickness', unit: 'in', hint: 'Base metal thickness', controller: _thicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Travel Speed', unit: 'IPM', hint: 'Inches per minute', controller: _travelSpeedController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_peakAmps != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildProcessSelector(ZaftoColors colors) {
    final processes = ['Pulse MIG', 'Pulse TIG'];
    return Wrap(
      spacing: 8,
      children: processes.map((p) => ChoiceChip(
        label: Text(p),
        selected: _process == p,
        onSelected: (_) => setState(() { _process = p; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildMaterialSelector(ZaftoColors colors) {
    final materials = ['Steel', 'Stainless', 'Aluminum'];
    return Wrap(
      spacing: 8,
      children: materials.map((m) => ChoiceChip(
        label: Text(m),
        selected: _material == m,
        onSelected: (_) => setState(() { _material = m; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Pulse Welding Parameters', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Starting point for pulse MIG/TIG setup', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Peak Amps', '${_peakAmps!.toStringAsFixed(0)} A', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Background', '${_backgroundAmps!.toStringAsFixed(0)} A'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Frequency', _process == 'Pulse MIG'
            ? '${_pulseFrequency!.toStringAsFixed(0)} Hz'
            : '${_pulseFrequency!.toStringAsFixed(1)} PPS'),
        const SizedBox(height: 12),
        _buildResultRow(colors, _process == 'Pulse MIG' ? 'Peak Time' : 'Peak %',
            _process == 'Pulse MIG'
            ? '${_peakTime!.toStringAsFixed(1)} ms'
            : '${_peakTime!.toStringAsFixed(0)}%'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_notes!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
