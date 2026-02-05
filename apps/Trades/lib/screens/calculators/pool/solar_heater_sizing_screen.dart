import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Solar Pool Heater Sizing Calculator
class SolarHeaterSizingScreen extends ConsumerStatefulWidget {
  const SolarHeaterSizingScreen({super.key});
  @override
  ConsumerState<SolarHeaterSizingScreen> createState() => _SolarHeaterSizingScreenState();
}

class _SolarHeaterSizingScreenState extends ConsumerState<SolarHeaterSizingScreen> {
  final _poolAreaController = TextEditingController();
  String _climate = 'Moderate';
  String _roofOrientation = 'South';

  double? _collectorArea;
  double? _panelCount;
  String? _recommendation;

  // Climate multiplier (% of pool surface area needed)
  static const Map<String, double> _climateFactors = {
    'Warm (FL, AZ)': 0.5,
    'Moderate': 0.75,
    'Cool (Northern)': 1.0,
    'Cold': 1.25,
  };

  // Roof orientation adjustment
  static const Map<String, double> _orientationFactors = {
    'South': 1.0,
    'Southeast/Southwest': 1.1,
    'East/West': 1.25,
  };

  void _calculate() {
    final poolArea = double.tryParse(_poolAreaController.text);

    if (poolArea == null || poolArea <= 0) {
      setState(() { _collectorArea = null; });
      return;
    }

    final climateFactor = _climateFactors[_climate] ?? 0.75;
    final orientationFactor = _orientationFactors[_roofOrientation] ?? 1.0;

    final collectorArea = poolArea * climateFactor * orientationFactor;
    // Standard 4'x12' panels = 48 sq ft each
    final panels = collectorArea / 48;

    String recommendation;
    if (panels <= 2) {
      recommendation = '2 panels (4\'×12\' each)';
    } else if (panels <= 4) {
      recommendation = '${panels.ceil()} panels (4\'×12\' each)';
    } else if (panels <= 8) {
      recommendation = '${panels.ceil()} panels - may need 2 manifolds';
    } else {
      recommendation = '${panels.ceil()} panels - commercial system';
    }

    setState(() {
      _collectorArea = collectorArea;
      _panelCount = panels;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _poolAreaController.clear();
    setState(() { _collectorArea = null; });
  }

  @override
  void dispose() {
    _poolAreaController.dispose();
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
        title: Text('Solar Heater Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('CLIMATE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildClimateSelector(colors),
            const SizedBox(height: 16),
            Text('ROOF ORIENTATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildOrientationSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Pool Surface Area', unit: 'sq ft', hint: 'L × W', controller: _poolAreaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_collectorArea != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildClimateSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _climateFactors.keys.map((climate) => ChoiceChip(
        label: Text(climate, style: const TextStyle(fontSize: 11)),
        selected: _climate == climate,
        onSelected: (_) => setState(() { _climate = climate; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildOrientationSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: _orientationFactors.keys.map((orient) => ChoiceChip(
        label: Text(orient, style: const TextStyle(fontSize: 11)),
        selected: _roofOrientation == orient,
        onSelected: (_) => setState(() { _roofOrientation = orient; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Collector = Pool Area × Factor', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('50-100% of pool area based on climate', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Collector Area', '${_collectorArea!.toStringAsFixed(0)} sq ft', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Panels (4\'×12\')', '${_panelCount!.toStringAsFixed(1)} panels'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_recommendation!, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),
        Text('Solar adds 8-12F in warm climates, 5-8F in cooler', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
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
