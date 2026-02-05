import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool Heater BTU Calculator
class HeaterBtuScreen extends ConsumerStatefulWidget {
  const HeaterBtuScreen({super.key});
  @override
  ConsumerState<HeaterBtuScreen> createState() => _HeaterBtuScreenState();
}

class _HeaterBtuScreenState extends ConsumerState<HeaterBtuScreen> {
  final _volumeController = TextEditingController();
  final _currentTempController = TextEditingController();
  final _targetTempController = TextEditingController(text: '82');
  final _hoursController = TextEditingController(text: '24');

  double? _btuRequired;
  double? _heaterSize;
  double? _hoursToHeat;

  void _calculate() {
    final volume = double.tryParse(_volumeController.text);
    final currentTemp = double.tryParse(_currentTempController.text);
    final targetTemp = double.tryParse(_targetTempController.text);
    final hours = double.tryParse(_hoursController.text);

    if (volume == null || currentTemp == null || targetTemp == null || hours == null ||
        volume <= 0 || targetTemp <= currentTemp || hours <= 0) {
      setState(() { _btuRequired = null; });
      return;
    }

    final tempRise = targetTemp - currentTemp;
    // BTU to heat water = gallons × 8.34 (lbs/gal) × temp rise
    final totalBtu = volume * 8.34 * tempRise;

    // BTU/hr needed to achieve in desired hours
    // Add 30% for heat loss during heating
    final btuPerHour = (totalBtu / hours) * 1.3;

    // Standard heater sizes
    double heaterSize;
    if (btuPerHour <= 200000) heaterSize = 200000;
    else if (btuPerHour <= 266000) heaterSize = 266000;
    else if (btuPerHour <= 300000) heaterSize = 300000;
    else if (btuPerHour <= 400000) heaterSize = 400000;
    else heaterSize = 500000;

    final actualHours = totalBtu * 1.3 / heaterSize;

    setState(() {
      _btuRequired = btuPerHour;
      _heaterSize = heaterSize;
      _hoursToHeat = actualHours;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _volumeController.clear();
    _currentTempController.clear();
    _targetTempController.text = '82';
    _hoursController.text = '24';
    setState(() { _btuRequired = null; });
  }

  @override
  void dispose() {
    _volumeController.dispose();
    _currentTempController.dispose();
    _targetTempController.dispose();
    _hoursController.dispose();
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
        title: Text('Heater BTU', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
            ZaftoInputField(label: 'Current Temp', unit: 'F', hint: 'Water temp now', controller: _currentTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Target Temp', unit: 'F', hint: '78-82 typical', controller: _targetTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Desired Heatup', unit: 'hrs', hint: 'Hours to reach temp', controller: _hoursController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_btuRequired != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('BTU = Gal × 8.34 × Temp Rise', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Add 30% for heat loss during heating', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final sizeK = (_heaterSize! / 1000).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'BTU/hr Needed', '${(_btuRequired! / 1000).toStringAsFixed(0)}K BTU', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Heater Size', '${sizeK}K BTU'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Heat Time', '${_hoursToHeat!.toStringAsFixed(1)} hrs'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Use a pool cover to reduce heat loss by up to 70%', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
