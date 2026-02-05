import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Time to Heat Pool Calculator
class TimeToHeatScreen extends ConsumerStatefulWidget {
  const TimeToHeatScreen({super.key});
  @override
  ConsumerState<TimeToHeatScreen> createState() => _TimeToHeatScreenState();
}

class _TimeToHeatScreenState extends ConsumerState<TimeToHeatScreen> {
  final _volumeController = TextEditingController();
  final _heaterBtuController = TextEditingController();
  final _currentTempController = TextEditingController();
  final _targetTempController = TextEditingController(text: '82');
  bool _hasCover = true;

  double? _hoursToHeat;
  double? _daysToHeat;
  String? _recommendation;

  void _calculate() {
    final volume = double.tryParse(_volumeController.text);
    final heaterBtu = double.tryParse(_heaterBtuController.text);
    final currentTemp = double.tryParse(_currentTempController.text);
    final targetTemp = double.tryParse(_targetTempController.text);

    if (volume == null || heaterBtu == null || currentTemp == null || targetTemp == null ||
        volume <= 0 || heaterBtu <= 0 || targetTemp <= currentTemp) {
      setState(() { _hoursToHeat = null; });
      return;
    }

    final tempRise = targetTemp - currentTemp;
    // BTU to heat = gallons × 8.34 × temp rise
    final totalBtu = volume * 8.34 * tempRise;

    // Heat loss factor (without cover: 50% efficient, with cover: 80% efficient)
    final efficiency = _hasCover ? 0.8 : 0.5;
    final hours = totalBtu / (heaterBtu * efficiency);
    final days = hours / 24;

    String recommendation;
    if (hours < 8) {
      recommendation = 'Quick heat-up - heater well matched to pool';
    } else if (hours < 24) {
      recommendation = 'Normal heat-up time for residential pool';
    } else if (hours < 48) {
      recommendation = 'Extended heat-up - consider larger heater for future';
    } else {
      recommendation = 'Very long heat-up - heater may be undersized';
    }

    setState(() {
      _hoursToHeat = hours;
      _daysToHeat = days;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _volumeController.clear();
    _heaterBtuController.clear();
    _currentTempController.clear();
    _targetTempController.text = '82';
    setState(() { _hoursToHeat = null; });
  }

  @override
  void dispose() {
    _volumeController.dispose();
    _heaterBtuController.dispose();
    _currentTempController.dispose();
    _targetTempController.dispose();
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
        title: Text('Time to Heat', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Pool Volume', unit: 'gal', hint: 'Total gallons', controller: _volumeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Heater Size', unit: 'BTU/hr', hint: 'e.g. 400000', controller: _heaterBtuController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Current Temp', unit: 'F', hint: 'Water temp now', controller: _currentTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Target Temp', unit: 'F', hint: '78-82 typical', controller: _targetTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            _buildCoverToggle(colors),
            const SizedBox(height: 32),
            if (_hoursToHeat != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildCoverToggle(ZaftoColors colors) {
    return Row(children: [
      ChoiceChip(label: const Text('With Cover'), selected: _hasCover, onSelected: (_) => setState(() { _hasCover = true; _calculate(); })),
      const SizedBox(width: 8),
      ChoiceChip(label: const Text('No Cover'), selected: !_hasCover, onSelected: (_) => setState(() { _hasCover = false; _calculate(); })),
    ]);
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Hours = BTU needed / Heater output', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Cover reduces heat loss by 50-70%', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Heat Time', '${_hoursToHeat!.toStringAsFixed(1)} hrs', isPrimary: true),
        if (_daysToHeat! > 1)
          ...[const SizedBox(height: 12), _buildResultRow(colors, 'Days', '${_daysToHeat!.toStringAsFixed(1)} days')],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
