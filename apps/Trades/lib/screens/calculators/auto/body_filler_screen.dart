import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Body Filler (Bondo) Calculator
class BodyFillerScreen extends ConsumerStatefulWidget {
  const BodyFillerScreen({super.key});
  @override
  ConsumerState<BodyFillerScreen> createState() => _BodyFillerScreenState();
}

class _BodyFillerScreenState extends ConsumerState<BodyFillerScreen> {
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _depthController = TextEditingController(text: '0.125');

  double? _fillerNeeded;
  double? _hardenerNeeded;
  String? _recommendation;

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final depth = double.tryParse(_depthController.text);

    if (length == null || width == null || depth == null ||
        length <= 0 || width <= 0 || depth <= 0) {
      setState(() { _fillerNeeded = null; });
      return;
    }

    // Calculate volume in cubic inches
    final volumeCuIn = length * width * depth;

    // Body filler: ~1.5 oz per cubic inch
    final fillerOz = volumeCuIn * 1.5;

    // Hardener: 2% of filler by weight (golf ball size per fist of filler)
    final hardenerOz = fillerOz * 0.02;

    String recommendation;
    if (depth > 0.25) {
      recommendation = 'Deep fills: Apply in layers no thicker than 1/4"';
    } else if (depth < 0.0625) {
      recommendation = 'Thin fills: Consider glazing putty instead';
    } else {
      recommendation = 'Mix only what you can use in 3-5 minutes';
    }

    setState(() {
      _fillerNeeded = fillerOz;
      _hardenerNeeded = hardenerOz;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _lengthController.clear();
    _widthController.clear();
    _depthController.text = '0.125';
    setState(() { _fillerNeeded = null; });
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _depthController.dispose();
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
        title: Text('Body Filler', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Repair Length', unit: 'in', hint: 'Area length', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Repair Width', unit: 'in', hint: 'Area width', controller: _widthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Depth', unit: 'in', hint: 'Max 1/4"', controller: _depthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_fillerNeeded != null) _buildResultsCard(colors),
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
        Text('Volume = L × W × D', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Max single layer: 1/4" (0.25")', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Filler Needed', '${_fillerNeeded!.toStringAsFixed(1)} oz', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Hardener (2%)', '${_hardenerNeeded!.toStringAsFixed(2)} oz'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
        const SizedBox(height: 12),
        Text('Working time: 3-5 minutes at 70F', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
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
