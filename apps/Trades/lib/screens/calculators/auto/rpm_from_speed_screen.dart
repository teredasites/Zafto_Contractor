import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// RPM from Speed Calculator - Engine RPM at given speed
class RpmFromSpeedScreen extends ConsumerStatefulWidget {
  const RpmFromSpeedScreen({super.key});
  @override
  ConsumerState<RpmFromSpeedScreen> createState() => _RpmFromSpeedScreenState();
}

class _RpmFromSpeedScreenState extends ConsumerState<RpmFromSpeedScreen> {
  final _speedController = TextEditingController();
  final _transRatioController = TextEditingController();
  final _diffRatioController = TextEditingController();
  final _tireDiameterController = TextEditingController();

  double? _rpm;

  void _calculate() {
    final speed = double.tryParse(_speedController.text);
    final transRatio = double.tryParse(_transRatioController.text);
    final diffRatio = double.tryParse(_diffRatioController.text);
    final tireDiameter = double.tryParse(_tireDiameterController.text);

    if (speed == null || transRatio == null || diffRatio == null || tireDiameter == null || tireDiameter <= 0) {
      setState(() { _rpm = null; });
      return;
    }

    // RPM = (Speed × Gear Ratio × 336) / Tire Diameter
    // 336 = conversion factor (mph to in/min) / (2π)
    final overallRatio = transRatio * diffRatio;
    final rpm = (speed * overallRatio * 336) / tireDiameter;

    setState(() {
      _rpm = rpm;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _speedController.clear();
    _transRatioController.clear();
    _diffRatioController.clear();
    _tireDiameterController.clear();
    setState(() { _rpm = null; });
  }

  @override
  void dispose() {
    _speedController.dispose();
    _transRatioController.dispose();
    _diffRatioController.dispose();
    _tireDiameterController.dispose();
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
        title: Text('RPM from Speed', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Vehicle Speed', unit: 'mph', hint: 'Target speed', controller: _speedController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Transmission Ratio', unit: ':1', hint: 'Current gear', controller: _transRatioController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Differential Ratio', unit: ':1', hint: 'Final drive', controller: _diffRatioController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Tire Diameter', unit: 'in', hint: 'Overall height', controller: _tireDiameterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_rpm != null) _buildResultsCard(colors),
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
        Text('RPM = (Speed × Ratio × 336) / Tire', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Calculate engine RPM at any speed and gear', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    String analysis;
    if (_rpm! > 6500) {
      analysis = 'High RPM - near or past redline for most engines';
    } else if (_rpm! > 4500) {
      analysis = 'Performance range - good power band';
    } else if (_rpm! > 2500) {
      analysis = 'Cruising range - efficient operation';
    } else if (_rpm! > 1500) {
      analysis = 'Economy range - low stress, good fuel mileage';
    } else {
      analysis = 'Lugging - may need to downshift';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Engine RPM', '${_rpm!.toStringAsFixed(0)} rpm', isPrimary: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(analysis, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
