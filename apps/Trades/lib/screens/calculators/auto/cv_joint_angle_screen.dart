import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// CV Joint Operating Angle Calculator
class CvJointAngleScreen extends ConsumerStatefulWidget {
  const CvJointAngleScreen({super.key});
  @override
  ConsumerState<CvJointAngleScreen> createState() => _CvJointAngleScreenState();
}

class _CvJointAngleScreenState extends ConsumerState<CvJointAngleScreen> {
  final _staticAngleController = TextEditingController();
  final _steeringAngleController = TextEditingController();
  final _suspTravelController = TextEditingController();
  String _jointType = 'rzeppa';

  double? _operatingAngle;
  double? _maxAngle;
  String? _status;
  double? _lifeReduction;

  void _calculate() {
    final staticAngle = double.tryParse(_staticAngleController.text);
    final steeringAngle = double.tryParse(_steeringAngleController.text) ?? 0;
    final suspTravel = double.tryParse(_suspTravelController.text) ?? 0;

    if (staticAngle == null) {
      setState(() { _operatingAngle = null; });
      return;
    }

    // Combined angle considering steering and suspension
    // Simplified: sqrt(static^2 + steering^2) + suspension contribution
    final combinedAngle = math.sqrt(math.pow(staticAngle, 2) + math.pow(steeringAngle * 0.5, 2)) + (suspTravel * 0.1);

    double maxAllowed;
    switch (_jointType) {
      case 'rzeppa':
        maxAllowed = 47; // Rzeppa joints up to 47°
        break;
      case 'tripod':
        maxAllowed = 25; // Tripod/plunge joints ~25°
        break;
      case 'cross_groove':
        maxAllowed = 22; // Cross-groove ~22°
        break;
      default:
        maxAllowed = 45;
    }

    String status;
    double lifeRedux;
    final utilization = combinedAngle / maxAllowed;

    if (utilization <= 0.5) {
      status = 'Excellent - Long service life expected';
      lifeRedux = 0;
    } else if (utilization <= 0.7) {
      status = 'Good - Normal wear expected';
      lifeRedux = 10;
    } else if (utilization <= 0.85) {
      status = 'Moderate - Increased wear rate';
      lifeRedux = 30;
    } else if (utilization <= 1.0) {
      status = 'High - Near maximum, reduced life';
      lifeRedux = 50;
    } else {
      status = 'Exceeded - Joint damage likely';
      lifeRedux = 75;
    }

    setState(() {
      _operatingAngle = combinedAngle;
      _maxAngle = maxAllowed;
      _status = status;
      _lifeReduction = lifeRedux;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _staticAngleController.clear();
    _steeringAngleController.clear();
    _suspTravelController.clear();
    setState(() { _operatingAngle = null; _jointType = 'rzeppa'; });
  }

  @override
  void dispose() {
    _staticAngleController.dispose();
    _steeringAngleController.dispose();
    _suspTravelController.dispose();
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
        title: Text('CV Joint Angle', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildJointTypeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Static Angle', unit: 'deg', hint: 'At ride height', controller: _staticAngleController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Max Steering Angle', unit: 'deg', hint: 'Full lock (optional)', controller: _steeringAngleController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Suspension Travel', unit: 'in', hint: 'From ride height (optional)', controller: _suspTravelController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_operatingAngle != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildJointTypeSelector(ZaftoColors colors) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('CV JOINT TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      Row(children: [
        _buildOption(colors, 'Rzeppa', 'rzeppa', '47°'),
        const SizedBox(width: 8),
        _buildOption(colors, 'Tripod', 'tripod', '25°'),
        const SizedBox(width: 8),
        _buildOption(colors, 'Cross', 'cross_groove', '22°'),
      ]),
    ]);
  }

  Widget _buildOption(ZaftoColors colors, String label, String value, String maxAngle) {
    final selected = _jointType == value;
    return Expanded(child: GestureDetector(
      onTap: () { setState(() => _jointType = value); _calculate(); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colors.accentPrimary : colors.bgElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(children: [
          Text(label, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          Text('Max $maxAngle', style: TextStyle(color: selected ? Colors.white.withValues(alpha: 0.8) : colors.textTertiary, fontSize: 10)),
        ]),
      ),
    ));
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Operating Angle vs Max Rating', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Combines static, steering, and suspension angles', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final utilization = _operatingAngle! / _maxAngle!;
    final isGood = utilization <= 0.85;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Operating Angle', '${_operatingAngle!.toStringAsFixed(1)}°', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Max Rated Angle', '${_maxAngle!.toStringAsFixed(0)}°'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Utilization', '${(utilization * 100).toStringAsFixed(0)}%'),
        if (_lifeReduction! > 0) ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Est. Life Reduction', '~${_lifeReduction!.toStringAsFixed(0)}%'),
        ],
        const SizedBox(height: 16),
        _buildProgressBar(colors, utilization),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: isGood ? colors.accentSuccess.withValues(alpha: 0.1) : colors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(isGood ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: isGood ? colors.accentSuccess : colors.warning, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(_status!, style: TextStyle(color: isGood ? colors.accentSuccess : colors.warning, fontSize: 13, fontWeight: FontWeight.w500))),
          ]),
        ),
      ]),
    );
  }

  Widget _buildProgressBar(ZaftoColors colors, double utilization) {
    final clampedUtil = utilization.clamp(0.0, 1.2);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Angle Utilization', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('${(utilization * 100).toStringAsFixed(0)}%', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 8),
      Container(
        height: 8,
        decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(4)),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: clampedUtil.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: utilization <= 0.7 ? colors.accentSuccess : utilization <= 1.0 ? colors.warning : colors.error,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
