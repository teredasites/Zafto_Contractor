import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Spa/Hot Tub Volume Calculator
class SpaVolumeScreen extends ConsumerStatefulWidget {
  const SpaVolumeScreen({super.key});
  @override
  ConsumerState<SpaVolumeScreen> createState() => _SpaVolumeScreenState();
}

class _SpaVolumeScreenState extends ConsumerState<SpaVolumeScreen> {
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _depthController = TextEditingController(text: '3.5');
  String _shape = 'Rectangular';

  double? _gallons;
  double? _liters;
  String? _turnoverGpm;

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final depth = double.tryParse(_depthController.text);

    if (length == null || width == null || depth == null || length <= 0 || width <= 0 || depth <= 0) {
      setState(() { _gallons = null; });
      return;
    }

    double cubicFeet;
    if (_shape == 'Circular') {
      // Use length as diameter
      final radius = length / 2;
      cubicFeet = 3.14159 * radius * radius * depth;
    } else if (_shape == 'Oval') {
      cubicFeet = 0.785 * length * width * depth;
    } else {
      cubicFeet = length * width * depth;
    }

    final gallons = cubicFeet * 7.48;
    final liters = gallons * 3.785;
    // Spa requires 30-minute turnover per health codes
    final turnoverGpm = gallons / 30;

    setState(() {
      _gallons = gallons;
      _liters = liters;
      _turnoverGpm = turnoverGpm.toStringAsFixed(1);
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _lengthController.clear();
    _widthController.clear();
    _depthController.text = '3.5';
    setState(() { _gallons = null; });
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
        title: Text('Spa/Hot Tub Volume', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('SPA SHAPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildShapeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: _shape == 'Circular' ? 'Diameter' : 'Length', unit: 'ft', hint: 'Spa dimension', controller: _lengthController, onChanged: (_) => _calculate()),
            if (_shape != 'Circular') ...[
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Width', unit: 'ft', hint: 'Spa width', controller: _widthController, onChanged: (_) => _calculate()),
            ],
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Depth', unit: 'ft', hint: 'Water depth', controller: _depthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_gallons != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildShapeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: ['Rectangular', 'Circular', 'Oval'].map((shape) => ChoiceChip(
        label: Text(shape),
        selected: _shape == shape,
        onSelected: (_) => setState(() { _shape = shape; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Spa Turnover = Volume / 30 min', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Health code requires 30-min turnover for spas', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Spa Volume', '${_gallons!.toStringAsFixed(0)} gal', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Liters', '${_liters!.toStringAsFixed(0)} L'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Min Pump Flow', '$_turnoverGpm GPM'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(LucideIcons.info, size: 16, color: colors.accentPrimary),
            const SizedBox(width: 8),
            Expanded(child: Text('Spas require 30-minute turnover rate per health codes', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
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
