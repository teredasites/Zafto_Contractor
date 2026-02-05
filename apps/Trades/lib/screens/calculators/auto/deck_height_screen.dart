import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Deck Height Calculator - Block deck to piston relationship
class DeckHeightScreen extends ConsumerStatefulWidget {
  const DeckHeightScreen({super.key});
  @override
  ConsumerState<DeckHeightScreen> createState() => _DeckHeightScreenState();
}

class _DeckHeightScreenState extends ConsumerState<DeckHeightScreen> {
  final _blockDeckController = TextEditingController();
  final _strokeController = TextEditingController();
  final _rodLengthController = TextEditingController();
  final _pinHeightController = TextEditingController();

  double? _deckClearance;
  double? _pistonPosition;

  void _calculate() {
    final blockDeck = double.tryParse(_blockDeckController.text);
    final stroke = double.tryParse(_strokeController.text);
    final rodLength = double.tryParse(_rodLengthController.text);
    final pinHeight = double.tryParse(_pinHeightController.text);

    if (blockDeck == null || stroke == null || rodLength == null || pinHeight == null) {
      setState(() { _deckClearance = null; });
      return;
    }

    // Piston at TDC = Rod Length + Pin Height + Half Stroke
    final pistonAtTdc = rodLength + pinHeight + (stroke / 2);
    final deckClearance = blockDeck - pistonAtTdc;

    setState(() {
      _pistonPosition = pistonAtTdc;
      _deckClearance = deckClearance;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _blockDeckController.clear();
    _strokeController.clear();
    _rodLengthController.clear();
    _pinHeightController.clear();
    setState(() { _deckClearance = null; });
  }

  @override
  void dispose() {
    _blockDeckController.dispose();
    _strokeController.dispose();
    _rodLengthController.dispose();
    _pinHeightController.dispose();
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
        title: Text('Deck Height', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Block Deck Height', unit: 'in', hint: 'Crank centerline to deck', controller: _blockDeckController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Stroke', unit: 'in', hint: 'Crankshaft stroke', controller: _strokeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Rod Length', unit: 'in', hint: 'Center to center', controller: _rodLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Piston Pin Height', unit: 'in', hint: 'Compression height', controller: _pinHeightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_deckClearance != null) _buildResultsCard(colors),
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
        Text('Deck = Block - (Rod + Pin + Stroke/2)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Piston to deck surface clearance at TDC', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    String analysis;
    if (_deckClearance! < 0) {
      analysis = 'Piston protrudes above deck! Requires machining or different components.';
    } else if (_deckClearance! < 0.005) {
      analysis = 'Zero deck - maximum quench, verify head gasket thickness.';
    } else if (_deckClearance! < 0.020) {
      analysis = 'Optimal for performance - good quench effect.';
    } else if (_deckClearance! < 0.040) {
      analysis = 'Stock clearance range - safe for boost applications.';
    } else {
      analysis = 'Large clearance - may need thinner gasket or deck machining.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Deck Clearance', '${_deckClearance!.toStringAsFixed(4)}"', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Piston @ TDC', '${_pistonPosition!.toStringAsFixed(4)}"'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _deckClearance! < 0 ? colors.error.withValues(alpha: 0.1) : colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(analysis, style: TextStyle(color: _deckClearance! < 0 ? colors.error : colors.textSecondary, fontSize: 13)),
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
