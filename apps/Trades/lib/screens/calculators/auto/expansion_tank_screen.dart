import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Expansion Tank Sizing Calculator
class ExpansionTankScreen extends ConsumerStatefulWidget {
  const ExpansionTankScreen({super.key});
  @override
  ConsumerState<ExpansionTankScreen> createState() => _ExpansionTankScreenState();
}

class _ExpansionTankScreenState extends ConsumerState<ExpansionTankScreen> {
  final _systemCapacityController = TextEditingController();
  final _coldTempController = TextEditingController(text: '70');
  final _hotTempController = TextEditingController(text: '220');
  final _pressureCapController = TextEditingController(text: '16');

  double? _expansionVolume;
  double? _minTankSize;
  double? _recommendedSize;
  double? _expansionPercent;

  void _calculate() {
    final capacity = double.tryParse(_systemCapacityController.text);
    final coldTemp = double.tryParse(_coldTempController.text);
    final hotTemp = double.tryParse(_hotTempController.text);
    final pressureCap = double.tryParse(_pressureCapController.text);

    if (capacity == null || coldTemp == null || hotTemp == null) {
      setState(() { _expansionVolume = null; });
      return;
    }

    // Coolant expansion calculation
    // Water/coolant expands approximately 4-5% from cold to hot
    // More precisely: ~0.04% per degree F above 32°F
    final deltaT = hotTemp - coldTemp;

    // Expansion coefficient for 50/50 coolant mix
    // Approximately 0.00045 per degree F (slightly higher than pure water)
    final expansionCoeff = 0.00045;
    final expansionPercent = deltaT * expansionCoeff * 100;
    final expansionVol = capacity * (deltaT * expansionCoeff);

    // Minimum tank size should handle full expansion plus 25% reserve
    final minSize = expansionVol * 1.25;

    // Recommended size includes extra capacity for overfill and air
    final recSize = expansionVol * 1.5;

    setState(() {
      _expansionVolume = expansionVol;
      _minTankSize = minSize;
      _recommendedSize = recSize;
      _expansionPercent = expansionPercent;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _systemCapacityController.clear();
    _coldTempController.text = '70';
    _hotTempController.text = '220';
    _pressureCapController.text = '16';
    setState(() { _expansionVolume = null; });
  }

  @override
  void dispose() {
    _systemCapacityController.dispose();
    _coldTempController.dispose();
    _hotTempController.dispose();
    _pressureCapController.dispose();
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
        title: Text('Expansion Tank', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'System Capacity', unit: 'qts', hint: 'Total coolant volume', controller: _systemCapacityController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Cold Temperature', unit: 'F', hint: 'Ambient/cold fill temp', controller: _coldTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Max Operating Temp', unit: 'F', hint: 'Maximum coolant temp', controller: _hotTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Pressure Cap Rating', unit: 'PSI', hint: 'Radiator cap pressure', controller: _pressureCapController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_expansionVolume != null) _buildResultsCard(colors),
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
        Text('Expansion = Capacity x 0.00045 x Delta T', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Coolant expands ~4-6% from cold to operating temp', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Expansion Volume', '${_expansionVolume!.toStringAsFixed(2)} qts', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Expansion Percent', '${_expansionPercent!.toStringAsFixed(1)}%'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Min Tank Size', '${_minTankSize!.toStringAsFixed(2)} qts'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Recommended Size', '${_recommendedSize!.toStringAsFixed(2)} qts'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(LucideIcons.info, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 8),
              Text('Tank Guidelines', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            Text('Fill tank to "Cold" line when engine is cold', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
            const SizedBox(height: 4),
            Text('Level should rise to "Hot" line at operating temp', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
            const SizedBox(height: 4),
            Text('Never open cap when hot - system is pressurized', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          ]),
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
