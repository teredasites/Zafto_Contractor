import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Compression Ratio Calculator - Static CR from volumes
class CompressionRatioScreen extends ConsumerStatefulWidget {
  const CompressionRatioScreen({super.key});
  @override
  ConsumerState<CompressionRatioScreen> createState() => _CompressionRatioScreenState();
}

class _CompressionRatioScreenState extends ConsumerState<CompressionRatioScreen> {
  final _boreController = TextEditingController();
  final _strokeController = TextEditingController();
  final _chamberController = TextEditingController();
  final _gasketController = TextEditingController(text: '0.040');
  final _gasketBoreController = TextEditingController();
  final _deckController = TextEditingController(text: '0.000');
  final _pistonController = TextEditingController(text: '-5');

  double? _compressionRatio;
  double? _sweptVolume;
  double? _clearanceVolume;

  @override
  void dispose() {
    _boreController.dispose();
    _strokeController.dispose();
    _chamberController.dispose();
    _gasketController.dispose();
    _gasketBoreController.dispose();
    _deckController.dispose();
    _pistonController.dispose();
    super.dispose();
  }

  void _calculate() {
    final bore = double.tryParse(_boreController.text);
    final stroke = double.tryParse(_strokeController.text);
    final chamber = double.tryParse(_chamberController.text);
    final gasketThickness = double.tryParse(_gasketController.text);
    final gasketBore = double.tryParse(_gasketBoreController.text) ?? bore;
    final deckClearance = double.tryParse(_deckController.text) ?? 0;
    final pistonCc = double.tryParse(_pistonController.text) ?? 0;

    if (bore == null || stroke == null || chamber == null || gasketThickness == null) {
      setState(() { _compressionRatio = null; });
      return;
    }

    // Swept volume (one cylinder) in CC
    final swept = (3.14159 / 4) * (bore * bore) * stroke * 16.387;

    // Gasket volume in CC
    final gBore = gasketBore ?? bore;
    final gasketVolume = (3.14159 / 4) * (gBore * gBore) * gasketThickness * 16.387;

    // Deck clearance volume in CC
    final deckVolume = (3.14159 / 4) * (bore * bore) * deckClearance * 16.387;

    // Total clearance volume (chamber + gasket + deck + piston dome/dish)
    final clearance = chamber + gasketVolume + deckVolume + pistonCc;

    // CR = (Swept + Clearance) / Clearance
    final cr = (swept + clearance) / clearance;

    setState(() {
      _sweptVolume = swept;
      _clearanceVolume = clearance;
      _compressionRatio = cr;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _boreController.clear();
    _strokeController.clear();
    _chamberController.clear();
    _gasketController.text = '0.040';
    _gasketBoreController.clear();
    _deckController.text = '0.000';
    _pistonController.text = '-5';
    setState(() { _compressionRatio = null; });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Compression Ratio', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormulaCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CYLINDER DIMENSIONS'),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Bore', unit: 'in', hint: 'Cylinder diameter', controller: _boreController, onChanged: (_) => _calculate()),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Stroke', unit: 'in', hint: 'Piston travel', controller: _strokeController, onChanged: (_) => _calculate()),
              const SizedBox(height: 20),
              _buildSectionHeader(colors, 'CHAMBER VOLUMES'),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Chamber Volume', unit: 'cc', hint: 'Combustion chamber', controller: _chamberController, onChanged: (_) => _calculate()),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Gasket Thickness', unit: 'in', hint: 'Head gasket', controller: _gasketController, onChanged: (_) => _calculate()),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Gasket Bore', unit: 'in', hint: 'Leave blank = bore', controller: _gasketBoreController, onChanged: (_) => _calculate()),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Deck Clearance', unit: 'in', hint: 'Piston to deck', controller: _deckController, onChanged: (_) => _calculate()),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Piston Volume', unit: 'cc', hint: 'Negative=dish, Positive=dome', controller: _pistonController, onChanged: (_) => _calculate()),
              const SizedBox(height: 32),
              if (_compressionRatio != null) _buildResultsCard(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        children: [
          Text('CR = (Swept + Clearance) / Clearance', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
          const SizedBox(height: 8),
          Text('Static compression ratio from all volume components', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(
        children: [
          _buildResultRow(colors, 'Compression Ratio', '${_compressionRatio!.toStringAsFixed(2)}:1', isPrimary: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Swept Volume', '${_sweptVolume!.toStringAsFixed(1)} cc'),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Clearance Volume', '${_clearanceVolume!.toStringAsFixed(1)} cc'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Icon(LucideIcons.info, size: 16, color: colors.accentPrimary),
                const SizedBox(width: 8),
                Expanded(child: Text('9-10.5:1 typical NA, 8-9:1 for boost', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 20 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
      ],
    );
  }
}
