import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Header Primary Size Calculator - Primary tube sizing for headers
class HeaderPrimarySizeScreen extends ConsumerStatefulWidget {
  const HeaderPrimarySizeScreen({super.key});
  @override
  ConsumerState<HeaderPrimarySizeScreen> createState() => _HeaderPrimarySizeScreenState();
}

class _HeaderPrimarySizeScreenState extends ConsumerState<HeaderPrimarySizeScreen> {
  final _displacementController = TextEditingController();
  final _cylindersController = TextEditingController(text: '8');
  final _rpmController = TextEditingController(text: '6500');

  double? _primaryDiameter;
  double? _primaryLength;
  String? _headerType;

  void _calculate() {
    final displacement = double.tryParse(_displacementController.text);
    final cylinders = double.tryParse(_cylindersController.text);
    final rpm = double.tryParse(_rpmController.text);

    if (displacement == null || cylinders == null || rpm == null || cylinders <= 0) {
      setState(() { _primaryDiameter = null; });
      return;
    }

    // Single cylinder displacement in cubic inches
    final singleCyl = displacement / cylinders;

    // Primary diameter formula: D = sqrt(singleCyl / 2.1) * (rpm/6500)^0.25
    // Simplified empirical formula used in header design
    final rpmFactor = _pow(rpm / 6500, 0.25);
    final diameter = _sqrt(singleCyl / 2.1) * rpmFactor;

    // Primary length formula: L = (850 * ED) / RPM - 3
    // ED = effective duration (assume 270 degrees for performance cam)
    final effectiveDuration = 270.0;
    final length = (850 * effectiveDuration) / rpm - 3;

    String type;
    if (rpm < 5000) {
      type = 'Long tube headers - low/mid range torque';
    } else if (rpm < 6500) {
      type = 'Mid-length headers - balanced power';
    } else {
      type = 'Shorty headers - high RPM power';
    }

    setState(() {
      _primaryDiameter = diameter;
      _primaryLength = length > 0 ? length : 12;
      _headerType = type;
    });
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _pow(double base, double exp) {
    if (base <= 0) return 0;
    return _exp(exp * _ln(base));
  }

  double _exp(double x) {
    double sum = 1.0;
    double term = 1.0;
    for (int i = 1; i < 30; i++) {
      term *= x / i;
      sum += term;
    }
    return sum;
  }

  double _ln(double x) {
    if (x <= 0) return 0;
    double y = (x - 1) / (x + 1);
    double sum = 0;
    double term = y;
    for (int i = 1; i < 50; i += 2) {
      sum += term / i;
      term *= y * y;
    }
    return 2 * sum;
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _displacementController.clear();
    _cylindersController.text = '8';
    _rpmController.text = '6500';
    setState(() { _primaryDiameter = null; });
  }

  @override
  void dispose() {
    _displacementController.dispose();
    _cylindersController.dispose();
    _rpmController.dispose();
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
        title: Text('Header Primary Size', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Engine Displacement', unit: 'ci', hint: 'Cubic inches', controller: _displacementController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Number of Cylinders', unit: 'cyl', hint: '4, 6, 8', controller: _cylindersController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Peak Power RPM', unit: 'RPM', hint: 'Target RPM', controller: _rpmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_primaryDiameter != null) _buildResultsCard(colors),
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
        Text('D = sqrt(CID/cyl / 2.1)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 4),
        Text('L = (850 x ED) / RPM - 3', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Primary tube sizing for optimal exhaust velocity', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Primary Tube Diameter', '${_primaryDiameter!.toStringAsFixed(3)}"', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Primary Tube Length', '${_primaryLength!.toStringAsFixed(1)}"'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text(_headerType!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Text('Common sizes: 1.5", 1.625", 1.75", 1.875", 2"', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
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
