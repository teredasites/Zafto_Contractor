import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Wiper Blade Size Calculator
class WiperBladeSizeScreen extends ConsumerStatefulWidget {
  const WiperBladeSizeScreen({super.key});
  @override
  ConsumerState<WiperBladeSizeScreen> createState() => _WiperBladeSizeScreenState();
}

class _WiperBladeSizeScreenState extends ConsumerState<WiperBladeSizeScreen> {
  final _windshieldWidthController = TextEditingController();
  String _wiperConfig = 'Standard';

  int? _driverSize;
  int? _passengerSize;
  String? _recommendation;

  void _calculate() {
    final width = double.tryParse(_windshieldWidthController.text);

    if (width == null || width <= 0) {
      setState(() { _driverSize = null; });
      return;
    }

    int driverSize;
    int passengerSize;

    // General sizing based on windshield width
    if (width <= 45) {
      driverSize = 18;
      passengerSize = 16;
    } else if (width <= 50) {
      driverSize = 20;
      passengerSize = 18;
    } else if (width <= 55) {
      driverSize = 22;
      passengerSize = 20;
    } else if (width <= 60) {
      driverSize = 24;
      passengerSize = 20;
    } else {
      driverSize = 26;
      passengerSize = 22;
    }

    // Adjust for configuration
    if (_wiperConfig == 'Equal Length') {
      passengerSize = driverSize - 2;
    } else if (_wiperConfig == 'Single Large') {
      driverSize += 2;
      passengerSize = 0; // No passenger wiper
    }

    String recommendation = _wiperConfig == 'Single Large'
        ? 'Single wiper system: Use beam-style blade'
        : 'Verify blades don\'t overlap when parked';

    setState(() {
      _driverSize = driverSize;
      _passengerSize = passengerSize;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _windshieldWidthController.clear();
    setState(() { _driverSize = null; });
  }

  @override
  void dispose() {
    _windshieldWidthController.dispose();
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
        title: Text('Wiper Blade Size', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('WIPER CONFIGURATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildConfigSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Windshield Width', unit: 'in', hint: 'At wiper level', controller: _windshieldWidthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_driverSize != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildConfigSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['Standard', 'Equal Length', 'Single Large'].map((config) => ChoiceChip(
        label: Text(config, style: const TextStyle(fontSize: 11)),
        selected: _wiperConfig == config,
        onSelected: (_) => setState(() { _wiperConfig = config; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Driver blade typically larger', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Based on windshield width estimate', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Driver Side', '$_driverSize"', isPrimary: true),
        if (_passengerSize! > 0) ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Passenger Side', '$_passengerSize"'),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
