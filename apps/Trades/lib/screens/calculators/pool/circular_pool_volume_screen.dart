import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Circular Pool Volume Calculator
class CircularPoolVolumeScreen extends ConsumerStatefulWidget {
  const CircularPoolVolumeScreen({super.key});
  @override
  ConsumerState<CircularPoolVolumeScreen> createState() => _CircularPoolVolumeScreenState();
}

class _CircularPoolVolumeScreenState extends ConsumerState<CircularPoolVolumeScreen> {
  final _diameterController = TextEditingController();
  final _depthController = TextEditingController();

  double? _gallons;
  double? _liters;
  double? _cubicFeet;

  void _calculate() {
    final diameter = double.tryParse(_diameterController.text);
    final depth = double.tryParse(_depthController.text);

    if (diameter == null || depth == null || diameter <= 0 || depth <= 0) {
      setState(() { _gallons = null; });
      return;
    }

    // Volume = π × r² × D (cubic feet)
    final radius = diameter / 2;
    final cubicFeet = math.pi * radius * radius * depth;
    final gallons = cubicFeet * 7.48;
    final liters = gallons * 3.785;

    setState(() {
      _cubicFeet = cubicFeet;
      _gallons = gallons;
      _liters = liters;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _diameterController.clear();
    _depthController.clear();
    setState(() { _gallons = null; });
  }

  @override
  void dispose() {
    _diameterController.dispose();
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
        title: Text('Circular Pool Volume', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Diameter', unit: 'ft', hint: 'Pool diameter', controller: _diameterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Average Depth', unit: 'ft', hint: 'Average depth', controller: _depthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_gallons != null) _buildResultsCard(colors),
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
        Text('V = π × r² × D × 7.48', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Round/circular pool calculation', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Pool Volume', '${_gallons!.toStringAsFixed(0)} gal', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Liters', '${_liters!.toStringAsFixed(0)} L'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Cubic Feet', '${_cubicFeet!.toStringAsFixed(1)} cu ft'),
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
