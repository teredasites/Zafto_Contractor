import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fountain Pump Sizing Calculator
class FountainPumpScreen extends ConsumerStatefulWidget {
  const FountainPumpScreen({super.key});
  @override
  ConsumerState<FountainPumpScreen> createState() => _FountainPumpScreenState();
}

class _FountainPumpScreenState extends ConsumerState<FountainPumpScreen> {
  final _heightController = TextEditingController();
  final _pipeRunController = TextEditingController(text: '20');
  String _fountainType = 'Spray';

  double? _gpmNeeded;
  double? _headRequired;
  String? _pumpRecommendation;

  // GPM multiplier by fountain type
  static const Map<String, double> _gpmFactors = {
    'Spray': 5, // GPM per foot of height
    'Bubbler': 3,
    'Laminar': 8,
    'Cascade': 10,
  };

  void _calculate() {
    final height = double.tryParse(_heightController.text);
    final pipeRun = double.tryParse(_pipeRunController.text);

    if (height == null || pipeRun == null || height <= 0) {
      setState(() { _gpmNeeded = null; });
      return;
    }

    final gpmFactor = _gpmFactors[_fountainType] ?? 5;
    final gpm = height * gpmFactor;

    // Head = spray height + friction (roughly 1 ft head per 10 ft pipe)
    final frictionHead = pipeRun / 10;
    final totalHead = height + frictionHead + 5; // +5 for fittings

    String recommendation;
    if (gpm <= 200 && totalHead <= 15) {
      recommendation = 'Small submersible pump (200-400 GPH)';
    } else if (gpm <= 500 && totalHead <= 20) {
      recommendation = 'Medium submersible pump (500-800 GPH)';
    } else if (gpm <= 1000 && totalHead <= 25) {
      recommendation = 'Large submersible pump (1000-1500 GPH)';
    } else if (gpm <= 2000 && totalHead <= 30) {
      recommendation = 'External pump recommended (2000+ GPH)';
    } else {
      recommendation = 'Commercial pump system needed';
    }

    setState(() {
      _gpmNeeded = gpm;
      _headRequired = totalHead;
      _pumpRecommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _heightController.clear();
    _pipeRunController.text = '20';
    setState(() { _gpmNeeded = null; });
  }

  @override
  void dispose() {
    _heightController.dispose();
    _pipeRunController.dispose();
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
        title: Text('Fountain Pump', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('FOUNTAIN TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildTypeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Spray Height', unit: 'ft', hint: 'Desired height', controller: _heightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Pipe Run', unit: 'ft', hint: 'Distance to pump', controller: _pipeRunController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_gpmNeeded != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: _gpmFactors.keys.map((type) => ChoiceChip(
        label: Text(type),
        selected: _fountainType == type,
        onSelected: (_) => setState(() { _fountainType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('GPM varies by fountain type', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Head = Height + Friction + Fittings', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Flow Needed', '${_gpmNeeded!.toStringAsFixed(0)} GPH', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Head Required', '${_headRequired!.toStringAsFixed(1)} ft'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_pumpRecommendation!, style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
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
