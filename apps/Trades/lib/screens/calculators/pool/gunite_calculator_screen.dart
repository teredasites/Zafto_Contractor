import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Gunite/Shotcrete Calculator
class GuniteCalculatorScreen extends ConsumerStatefulWidget {
  const GuniteCalculatorScreen({super.key});
  @override
  ConsumerState<GuniteCalculatorScreen> createState() => _GuniteCalculatorScreenState();
}

class _GuniteCalculatorScreenState extends ConsumerState<GuniteCalculatorScreen> {
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _avgDepthController = TextEditingController();
  final _thicknessController = TextEditingController(text: '9');

  double? _surfaceArea;
  double? _cubicYards;
  double? _estimatedCost;

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final avgDepth = double.tryParse(_avgDepthController.text);
    final thickness = double.tryParse(_thicknessController.text);

    if (length == null || width == null || avgDepth == null || thickness == null ||
        length <= 0 || width <= 0 || avgDepth <= 0 || thickness <= 0) {
      setState(() { _surfaceArea = null; });
      return;
    }

    // Approximate surface area calculation for rectangular pool
    // Floor area + 2 long walls + 2 short walls
    final floorArea = length * width;
    final longWalls = 2 * length * avgDepth;
    final shortWalls = 2 * width * avgDepth;
    final totalSurfaceArea = floorArea + longWalls + shortWalls;

    // Convert thickness to feet, then calculate cubic feet
    final thicknessFt = thickness / 12;
    final cubicFeet = totalSurfaceArea * thicknessFt;
    final cubicYards = cubicFeet / 27;

    // Rough cost estimate: $8-12 per sq ft installed
    final cost = totalSurfaceArea * 10;

    setState(() {
      _surfaceArea = totalSurfaceArea;
      _cubicYards = cubicYards;
      _estimatedCost = cost;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _lengthController.clear();
    _widthController.clear();
    _avgDepthController.clear();
    _thicknessController.text = '9';
    setState(() { _surfaceArea = null; });
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _avgDepthController.dispose();
    _thicknessController.dispose();
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
        title: Text('Gunite/Shotcrete', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Pool Length', unit: 'ft', hint: 'Inside length', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Pool Width', unit: 'ft', hint: 'Inside width', controller: _widthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Average Depth', unit: 'ft', hint: 'Average depth', controller: _avgDepthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Shell Thickness', unit: 'in', hint: '8-10" typical', controller: _thicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_surfaceArea != null) _buildResultsCard(colors),
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
        Text('CY = Surface Area × Thickness / 27', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Standard thickness: 8-10" for residential', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Surface Area', '${_surfaceArea!.toStringAsFixed(0)} sq ft'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Gunite Volume', '${_cubicYards!.toStringAsFixed(1)} cu yd', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Est. Shell Cost', '\$${_estimatedCost!.toStringAsFixed(0)}'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Add 10-15% for overspray and waste. Cost varies by region.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
