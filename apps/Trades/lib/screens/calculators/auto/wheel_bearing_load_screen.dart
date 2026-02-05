import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Wheel Bearing Load Calculator
class WheelBearingLoadScreen extends ConsumerStatefulWidget {
  const WheelBearingLoadScreen({super.key});
  @override
  ConsumerState<WheelBearingLoadScreen> createState() => _WheelBearingLoadScreenState();
}

class _WheelBearingLoadScreenState extends ConsumerState<WheelBearingLoadScreen> {
  final _cornerWeightController = TextEditingController();
  final _gForceController = TextEditingController();
  final _wheelDiameterController = TextEditingController();
  final _tireWidthController = TextEditingController();
  String _bearingType = 'tapered';

  double? _staticLoad;
  double? _dynamicLoad;
  double? _combinedLoad;
  String? _status;

  void _calculate() {
    final cornerWeight = double.tryParse(_cornerWeightController.text);
    final gForce = double.tryParse(_gForceController.text) ?? 1.0;
    final wheelDiameter = double.tryParse(_wheelDiameterController.text);
    final tireWidth = double.tryParse(_tireWidthController.text);

    if (cornerWeight == null) {
      setState(() { _staticLoad = null; });
      return;
    }

    // Static radial load = corner weight
    final staticRadial = cornerWeight;

    // Dynamic load multiplier based on g-forces (cornering, braking)
    // Radial increases with vertical g, axial from lateral g
    final radialLoad = cornerWeight * gForce;

    // Estimate axial thrust from cornering (lateral g creates thrust load)
    // Simplified: lateral thrust ≈ radial * lateral_g * tan(camber + scrub)
    // Using typical factor of 0.3-0.5 for axial component
    final axialLoad = cornerWeight * (gForce - 1) * 0.4;

    // Combined equivalent load for bearing life (ISO formula simplified)
    // P = X*Fr + Y*Fa where X and Y are factors
    double xFactor, yFactor;
    switch (_bearingType) {
      case 'ball':
        xFactor = 0.56;
        yFactor = 1.2;
        break;
      case 'tapered':
        xFactor = 0.4;
        yFactor = 1.5;
        break;
      case 'hub_unit':
        xFactor = 0.5;
        yFactor = 1.3;
        break;
      default:
        xFactor = 0.5;
        yFactor = 1.4;
    }

    final combinedEquiv = (xFactor * radialLoad) + (yFactor * axialLoad.abs());
    final finalCombined = math.max(combinedEquiv, radialLoad);

    String statusMsg;
    // Typical bearing ratings: light car 800-1200kg, heavy car/truck 1500-2500kg
    if (finalCombined < 500) {
      statusMsg = 'Light load - Standard bearing adequate';
    } else if (finalCombined < 1000) {
      statusMsg = 'Moderate load - Ensure proper preload';
    } else if (finalCombined < 1800) {
      statusMsg = 'Heavy load - Quality bearing recommended';
    } else {
      statusMsg = 'Very heavy - HD/racing bearing required';
    }

    setState(() {
      _staticLoad = staticRadial;
      _dynamicLoad = radialLoad;
      _combinedLoad = finalCombined;
      _status = statusMsg;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _cornerWeightController.clear();
    _gForceController.clear();
    _wheelDiameterController.clear();
    _tireWidthController.clear();
    setState(() { _staticLoad = null; _bearingType = 'tapered'; });
  }

  @override
  void dispose() {
    _cornerWeightController.dispose();
    _gForceController.dispose();
    _wheelDiameterController.dispose();
    _tireWidthController.dispose();
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
        title: Text('Wheel Bearing Load', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildBearingTypeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Corner Weight', unit: 'lbs', hint: 'Weight on this corner', controller: _cornerWeightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'G-Force (Peak)', unit: 'g', hint: 'Max cornering g (default 1)', controller: _gForceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Wheel Diameter', unit: 'in', hint: 'Optional - for reference', controller: _wheelDiameterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Tire Width', unit: 'mm', hint: 'Optional - for reference', controller: _tireWidthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_staticLoad != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildBearingTypeSelector(ZaftoColors colors) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('BEARING TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      Row(children: [
        _buildOption(colors, 'Tapered', 'tapered'),
        const SizedBox(width: 8),
        _buildOption(colors, 'Ball', 'ball'),
        const SizedBox(width: 8),
        _buildOption(colors, 'Hub Unit', 'hub_unit'),
      ]),
    ]);
  }

  Widget _buildOption(ZaftoColors colors, String label, String value) {
    final selected = _bearingType == value;
    return Expanded(child: GestureDetector(
      onTap: () { setState(() => _bearingType = value); _calculate(); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colors.accentPrimary : colors.bgElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Text(label, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))),
      ),
    ));
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('P = X*Fr + Y*Fa', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Combined equivalent load from radial and axial forces', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Static Load', '${_staticLoad!.toStringAsFixed(0)} lbs'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Dynamic Radial Load', '${_dynamicLoad!.toStringAsFixed(0)} lbs'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Combined Equiv. Load', '${_combinedLoad!.toStringAsFixed(0)} lbs', isPrimary: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(LucideIcons.info, color: colors.accentInfo, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(_status!, style: TextStyle(color: colors.accentInfo, fontSize: 13, fontWeight: FontWeight.w500))),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Bearing life varies with load cubed. 2x load = 1/8 life. Always check manufacturer ratings for dynamic capacity (C).', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
