import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool Deck Area Calculator
class DeckAreaScreen extends ConsumerStatefulWidget {
  const DeckAreaScreen({super.key});
  @override
  ConsumerState<DeckAreaScreen> createState() => _DeckAreaScreenState();
}

class _DeckAreaScreenState extends ConsumerState<DeckAreaScreen> {
  final _poolLengthController = TextEditingController();
  final _poolWidthController = TextEditingController();
  final _deckWidthController = TextEditingController(text: '4');
  String _surfaceType = 'Brushed Concrete';

  double? _deckSqFt;
  double? _estimatedCost;
  String? _recommendation;

  static const Map<String, double> _surfaceCosts = {
    'Brushed Concrete': 8,
    'Stamped Concrete': 15,
    'Pavers': 20,
    'Travertine': 30,
    'Kool Deck': 12,
  };

  void _calculate() {
    final poolLength = double.tryParse(_poolLengthController.text);
    final poolWidth = double.tryParse(_poolWidthController.text);
    final deckWidth = double.tryParse(_deckWidthController.text);

    if (poolLength == null || poolWidth == null || deckWidth == null ||
        poolLength <= 0 || poolWidth <= 0 || deckWidth <= 0) {
      setState(() { _deckSqFt = null; });
      return;
    }

    // Total area including pool minus pool area
    final totalLength = poolLength + (2 * deckWidth);
    final totalWidth = poolWidth + (2 * deckWidth);
    final totalArea = totalLength * totalWidth;
    final poolArea = poolLength * poolWidth;
    final deckArea = totalArea - poolArea;

    final costPerSqFt = _surfaceCosts[_surfaceType] ?? 10;
    final cost = deckArea * costPerSqFt;

    String recommendation;
    if (deckWidth < 4) {
      recommendation = 'Deck may be too narrow - 4 ft min recommended';
    } else if (deckWidth > 8) {
      recommendation = 'Wide deck - consider multiple zones';
    } else {
      recommendation = 'Good deck width for pool access';
    }

    setState(() {
      _deckSqFt = deckArea;
      _estimatedCost = cost;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _poolLengthController.clear();
    _poolWidthController.clear();
    _deckWidthController.text = '4';
    setState(() { _deckSqFt = null; });
  }

  @override
  void dispose() {
    _poolLengthController.dispose();
    _poolWidthController.dispose();
    _deckWidthController.dispose();
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
        title: Text('Pool Deck Area', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('SURFACE TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildSurfaceSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Pool Length', unit: 'ft', hint: 'Inside length', controller: _poolLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Pool Width', unit: 'ft', hint: 'Inside width', controller: _poolWidthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Deck Width', unit: 'ft', hint: '4-6 ft typical', controller: _deckWidthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_deckSqFt != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSurfaceSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _surfaceCosts.keys.map((type) => ChoiceChip(
        label: Text(type, style: const TextStyle(fontSize: 11)),
        selected: _surfaceType == type,
        onSelected: (_) => setState(() { _surfaceType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Deck = Total Area - Pool Area', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Minimum 4 ft deck width recommended', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Deck Area', '${_deckSqFt!.toStringAsFixed(0)} sq ft', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Est. Cost', '\$${_estimatedCost!.toStringAsFixed(0)}'),
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
