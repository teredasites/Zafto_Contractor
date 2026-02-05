import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Collector Size Calculator - Collector diameter calculation
class CollectorSizeScreen extends ConsumerStatefulWidget {
  const CollectorSizeScreen({super.key});
  @override
  ConsumerState<CollectorSizeScreen> createState() => _CollectorSizeScreenState();
}

class _CollectorSizeScreenState extends ConsumerState<CollectorSizeScreen> {
  final _primaryDiameterController = TextEditingController();
  final _primariesController = TextEditingController(text: '4');
  final _rpmController = TextEditingController(text: '6500');

  double? _collectorDiameter;
  double? _collectorLength;
  double? _areaRatio;
  String? _recommendation;

  void _calculate() {
    final primaryD = double.tryParse(_primaryDiameterController.text);
    final primaries = double.tryParse(_primariesController.text);
    final rpm = double.tryParse(_rpmController.text);

    if (primaryD == null || primaries == null || rpm == null || primaries <= 0) {
      setState(() { _collectorDiameter = null; });
      return;
    }

    // Primary area = pi * (D/2)^2 * number of primaries
    final primaryArea = 3.14159 * (primaryD / 2) * (primaryD / 2) * primaries;

    // Collector area should be 85-100% of combined primary area
    // Using 90% as optimal for most applications
    final collectorArea = primaryArea * 0.90;

    // Collector diameter from area
    final collectorD = 2 * _sqrt(collectorArea / 3.14159);

    // Collector length: shorter for high RPM, longer for low RPM
    // Rule of thumb: 8-12" for street, 3-6" for race
    final length = rpm < 5500 ? 10.0 : (rpm < 7000 ? 7.0 : 4.0);

    final ratio = collectorArea / primaryArea;

    String rec;
    if (collectorD < 2.5) {
      rec = '2.5" collector - mild street application';
    } else if (collectorD < 3.0) {
      rec = '3.0" collector - street/strip use';
    } else if (collectorD < 3.5) {
      rec = '3.5" collector - performance build';
    } else {
      rec = '4.0"+ collector - race application';
    }

    setState(() {
      _collectorDiameter = collectorD;
      _collectorLength = length;
      _areaRatio = ratio * 100;
      _recommendation = rec;
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

  void _clearAll() {
    HapticFeedback.lightImpact();
    _primaryDiameterController.clear();
    _primariesController.text = '4';
    _rpmController.text = '6500';
    setState(() { _collectorDiameter = null; });
  }

  @override
  void dispose() {
    _primaryDiameterController.dispose();
    _primariesController.dispose();
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
        title: Text('Collector Size', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Primary Tube Diameter', unit: 'in', hint: '1.5, 1.75, 2.0', controller: _primaryDiameterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Number of Primaries', unit: 'tubes', hint: '4 for 4-1, 8 for V8', controller: _primariesController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Peak Power RPM', unit: 'RPM', hint: 'Target RPM range', controller: _rpmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_collectorDiameter != null) _buildResultsCard(colors),
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
        Text('Ac = (n x Ap) x 0.90', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 4),
        Text('Dc = 2 x sqrt(Ac / pi)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Collector should be 85-100% of combined primary area', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Collector Diameter', '${_collectorDiameter!.toStringAsFixed(2)}"', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Suggested Length', '${_collectorLength!.toStringAsFixed(0)}"'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Area Ratio', '${_areaRatio!.toStringAsFixed(0)}%'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Text('Merge collectors improve scavenging', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
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
