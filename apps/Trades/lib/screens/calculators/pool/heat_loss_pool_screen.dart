import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool Heat Loss Calculator
class HeatLossPoolScreen extends ConsumerStatefulWidget {
  const HeatLossPoolScreen({super.key});
  @override
  ConsumerState<HeatLossPoolScreen> createState() => _HeatLossPoolScreenState();
}

class _HeatLossPoolScreenState extends ConsumerState<HeatLossPoolScreen> {
  final _surfaceAreaController = TextEditingController();
  final _waterTempController = TextEditingController(text: '82');
  final _airTempController = TextEditingController(text: '70');
  final _windSpeedController = TextEditingController(text: '5');
  bool _hasCover = false;

  double? _btuLossPerHour;
  double? _btuLossPerDay;
  double? _heaterMinBtu;

  void _calculate() {
    final surfaceArea = double.tryParse(_surfaceAreaController.text);
    final waterTemp = double.tryParse(_waterTempController.text);
    final airTemp = double.tryParse(_airTempController.text);
    final windSpeed = double.tryParse(_windSpeedController.text);

    if (surfaceArea == null || waterTemp == null || airTemp == null || windSpeed == null ||
        surfaceArea <= 0 || waterTemp <= airTemp) {
      setState(() { _btuLossPerHour = null; });
      return;
    }

    final tempDiff = waterTemp - airTemp;

    // Base evaporation heat loss: ~1 BTU per sq ft per degree per hour
    // Wind increases loss significantly
    double windFactor = 1 + (windSpeed * 0.1);
    double baseLoss = surfaceArea * tempDiff * 1.0 * windFactor;

    // Cover reduces loss by ~70-90%
    if (_hasCover) {
      baseLoss *= 0.15; // 85% reduction
    }

    final dailyLoss = baseLoss * 24;
    // Heater needs to exceed heat loss to warm pool
    final minHeater = baseLoss * 1.5;

    setState(() {
      _btuLossPerHour = baseLoss;
      _btuLossPerDay = dailyLoss;
      _heaterMinBtu = minHeater;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _surfaceAreaController.clear();
    _waterTempController.text = '82';
    _airTempController.text = '70';
    _windSpeedController.text = '5';
    setState(() { _btuLossPerHour = null; });
  }

  @override
  void dispose() {
    _surfaceAreaController.dispose();
    _waterTempController.dispose();
    _airTempController.dispose();
    _windSpeedController.dispose();
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
        title: Text('Heat Loss', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Surface Area', unit: 'sq ft', hint: 'Pool surface', controller: _surfaceAreaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Water Temp', unit: 'F', hint: 'Pool temp', controller: _waterTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Air Temp', unit: 'F', hint: 'Average air temp', controller: _airTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Wind Speed', unit: 'mph', hint: 'Average wind', controller: _windSpeedController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            _buildCoverToggle(colors),
            const SizedBox(height: 32),
            if (_btuLossPerHour != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildCoverToggle(ZaftoColors colors) {
    return Row(children: [
      ChoiceChip(label: const Text('No Cover'), selected: !_hasCover, onSelected: (_) => setState(() { _hasCover = false; _calculate(); })),
      const SizedBox(width: 8),
      ChoiceChip(label: const Text('With Cover'), selected: _hasCover, onSelected: (_) => setState(() { _hasCover = true; _calculate(); })),
    ]);
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Loss = Area × Temp Diff × Factors', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Evaporation is biggest heat loss source', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Loss/Hour', '${(_btuLossPerHour! / 1000).toStringAsFixed(0)}K BTU'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Loss/Day', '${(_btuLossPerDay! / 1000).toStringAsFixed(0)}K BTU', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Min Heater', '${(_heaterMinBtu! / 1000).toStringAsFixed(0)}K BTU'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_hasCover
            ? 'Cover dramatically reduces heat loss!'
            : 'A pool cover would reduce this loss by 85%',
            style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
