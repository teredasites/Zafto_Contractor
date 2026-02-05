import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Wheel Bearing Preload Calculator
class BearingPreloadScreen extends ConsumerStatefulWidget {
  const BearingPreloadScreen({super.key});
  @override
  ConsumerState<BearingPreloadScreen> createState() => _BearingPreloadScreenState();
}

class _BearingPreloadScreenState extends ConsumerState<BearingPreloadScreen> {
  final _measuredPreloadController = TextEditingController();
  String _bearingType = 'Tapered Roller';
  String _application = 'Front Wheel';

  String? _spec;
  String? _result;
  String? _recommendation;

  // Preload specs in inch-lbs for new bearings
  static const Map<String, Map<String, List<int>>> _preloadSpecs = {
    'Tapered Roller': {
      'Front Wheel': [15, 25], // 15-25 inch-lbs
      'Rear Wheel': [10, 20],
      'Differential': [15, 30],
    },
    'Angular Contact': {
      'Front Wheel': [10, 20],
      'Rear Wheel': [10, 20],
      'Differential': [10, 25],
    },
  };

  void _calculate() {
    final measured = double.tryParse(_measuredPreloadController.text);
    final specs = _preloadSpecs[_bearingType]?[_application];

    if (specs == null) {
      setState(() { _spec = null; });
      return;
    }

    final minSpec = specs[0];
    final maxSpec = specs[1];
    final specStr = '$minSpec-$maxSpec in-lbs';

    String result;
    String recommendation;

    if (measured == null) {
      result = 'Enter measured preload';
      recommendation = 'Use inch-lb torque wrench to measure turning effort';
    } else if (measured < minSpec) {
      result = 'TOO LOOSE - Tighten adjustment';
      recommendation = 'Insufficient preload causes wheel wobble and premature wear';
    } else if (measured > maxSpec) {
      result = 'TOO TIGHT - Loosen adjustment';
      recommendation = 'Excessive preload causes overheating and bearing failure';
    } else {
      result = 'WITHIN SPEC - Good';
      recommendation = 'Install cotter pin or lock nut. Recheck after 100 miles.';
    }

    setState(() {
      _spec = specStr;
      _result = result;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _measuredPreloadController.clear();
    setState(() { _spec = null; });
  }

  @override
  void dispose() {
    _measuredPreloadController.dispose();
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
        title: Text('Bearing Preload', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('BEARING TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildBearingSelector(colors),
            const SizedBox(height: 16),
            Text('APPLICATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildApplicationSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Measured Preload', unit: 'in-lbs', hint: 'Turning torque', controller: _measuredPreloadController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_spec != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildBearingSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _preloadSpecs.keys.map((type) => ChoiceChip(
        label: Text(type, style: const TextStyle(fontSize: 11)),
        selected: _bearingType == type,
        onSelected: (_) => setState(() { _bearingType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildApplicationSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['Front Wheel', 'Rear Wheel', 'Differential'].map((app) => ChoiceChip(
        label: Text(app, style: const TextStyle(fontSize: 11)),
        selected: _application == app,
        onSelected: (_) => setState(() { _application = app; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Preload = Turning Resistance', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Measure with inch-lb torque wrench', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isBad = _result?.contains('TOO') ?? false;
    final isGood = _result?.contains('WITHIN') ?? false;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: isBad ? Colors.red.withValues(alpha: 0.5) : colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Spec Range', _spec!, isPrimary: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: isBad ? Colors.red.withValues(alpha: 0.1) : (isGood ? Colors.green.withValues(alpha: 0.1) : colors.bgBase), borderRadius: BorderRadius.circular(8)),
          child: Text(_result!, style: TextStyle(color: isBad ? Colors.red : (isGood ? Colors.green : colors.textPrimary), fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),
        Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
