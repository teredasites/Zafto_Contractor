import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Purge Volume Calculator - Gas volume for pipe purging
class PurgeVolumeScreen extends ConsumerStatefulWidget {
  const PurgeVolumeScreen({super.key});
  @override
  ConsumerState<PurgeVolumeScreen> createState() => _PurgeVolumeScreenState();
}

class _PurgeVolumeScreenState extends ConsumerState<PurgeVolumeScreen> {
  final _pipeDiameterController = TextEditingController();
  final _purgeLengthController = TextEditingController(text: '24');
  String _material = 'Stainless';
  String _pipeSchedule = 'Sch 40';

  double? _pipeVolume;
  double? _purgeVolume;
  double? _gasRequired;
  String? _notes;

  // Wall thickness for common schedules (for 4" pipe as reference)
  static const Map<String, double> _wallThickness = {
    'Sch 10': 0.120,
    'Sch 40': 0.237,
    'Sch 80': 0.337,
    'Sch 160': 0.531,
  };

  // Volume exchanges needed
  static const Map<String, int> _volumeExchanges = {
    'Stainless': 5,
    'Titanium': 7,
    'Chrome-Moly': 5,
    'Nickel Alloy': 6,
    'Aluminum': 4,
  };

  void _calculate() {
    final diameter = double.tryParse(_pipeDiameterController.text);
    final purgeLength = double.tryParse(_purgeLengthController.text) ?? 24;

    if (diameter == null || diameter <= 0) {
      setState(() { _pipeVolume = null; });
      return;
    }

    // Calculate ID from wall thickness (simplified)
    final wallThickness = _wallThickness[_pipeSchedule] ?? 0.237;
    final scaleFactor = diameter / 4; // Scale from 4" reference
    final actualWall = wallThickness * scaleFactor;
    final insideDiameter = diameter - (2 * actualWall);

    // Calculate volume in cubic feet
    final radius = (insideDiameter / 2) / 12; // Convert to feet
    final lengthFt = purgeLength / 12;
    final pipeVolume = math.pi * radius * radius * lengthFt;

    // Get volume exchanges
    final exchanges = _volumeExchanges[_material] ?? 5;
    final purgeVolume = pipeVolume * exchanges;

    // Add 20% for leakage/safety
    final gasRequired = purgeVolume * 1.2;

    String notes;
    if (_material == 'Titanium') {
      notes = 'Titanium requires high purity argon (<50 ppm O2)';
    } else if (_material == 'Stainless') {
      notes = 'Target <0.5% O2 before starting root pass';
    } else {
      notes = '$exchanges volume exchanges for $_material';
    }

    setState(() {
      _pipeVolume = pipeVolume;
      _purgeVolume = purgeVolume;
      _gasRequired = gasRequired;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _pipeDiameterController.clear();
    _purgeLengthController.text = '24';
    setState(() { _pipeVolume = null; });
  }

  @override
  void dispose() {
    _pipeDiameterController.dispose();
    _purgeLengthController.dispose();
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
        title: Text('Purge Volume', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Material', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildMaterialSelector(colors),
            const SizedBox(height: 16),
            Text('Pipe Schedule', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildScheduleSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Pipe OD', unit: 'in', hint: 'Outside diameter', controller: _pipeDiameterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Purge Length', unit: 'in', hint: 'Dam to dam distance', controller: _purgeLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_pipeVolume != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildMaterialSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _volumeExchanges.keys.map((m) => ChoiceChip(
        label: Text(m, style: const TextStyle(fontSize: 11)),
        selected: _material == m,
        onSelected: (_) => setState(() { _material = m; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildScheduleSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: _wallThickness.keys.map((s) => ChoiceChip(
        label: Text(s),
        selected: _pipeSchedule == s,
        onSelected: (_) => setState(() { _pipeSchedule = s; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Purge = \u03C0r\u00B2 x L x Exchanges', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Inert gas required for proper purge', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Gas Required', '${_gasRequired!.toStringAsFixed(1)} cf', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Purge Volume', '${_purgeVolume!.toStringAsFixed(2)} cf'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Pipe Volume', '${_pipeVolume!.toStringAsFixed(3)} cf'),
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
