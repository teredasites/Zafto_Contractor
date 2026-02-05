import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Bolt Pattern Calculator - Measure and convert lug patterns
class BoltPatternScreen extends ConsumerStatefulWidget {
  const BoltPatternScreen({super.key});
  @override
  ConsumerState<BoltPatternScreen> createState() => _BoltPatternScreenState();
}

class _BoltPatternScreenState extends ConsumerState<BoltPatternScreen> {
  final _lugCountController = TextEditingController(text: '5');
  final _measurementController = TextEditingController();
  String _measureType = 'adjacent'; // adjacent or across

  double? _boltCircle;
  String? _boltCircleMm;

  void _calculate() {
    final lugCount = int.tryParse(_lugCountController.text);
    final measurement = double.tryParse(_measurementController.text);

    if (lugCount == null || measurement == null || lugCount < 3) {
      setState(() { _boltCircle = null; });
      return;
    }

    double bcd;
    if (_measureType == 'across' && lugCount % 2 == 0) {
      // Even number of lugs - measured across is the BCD
      bcd = measurement;
    } else if (_measureType == 'adjacent') {
      // Calculate BCD from adjacent lug measurement
      final angle = 360.0 / lugCount;
      final radians = angle * math.pi / 180;
      bcd = measurement / math.sin(radians / 2);
    } else {
      // Odd number of lugs - need to calculate from across measurement
      final angle = 180.0 - (180.0 / lugCount);
      final radians = angle * math.pi / 180;
      bcd = measurement / math.sin(radians / 2) / 2;
    }

    setState(() {
      _boltCircle = bcd;
      _boltCircleMm = (bcd * 25.4).toStringAsFixed(0);
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _lugCountController.text = '5';
    _measurementController.clear();
    setState(() { _boltCircle = null; });
  }

  @override
  void dispose() {
    _lugCountController.dispose();
    _measurementController.dispose();
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
        title: Text('Bolt Pattern', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Number of Lugs', unit: 'lugs', hint: '4, 5, 6, 8', controller: _lugCountController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            _buildMeasureTypeSelector(colors),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Measurement', unit: 'in', hint: 'Lug center to center', controller: _measurementController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_boltCircle != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildCommonPatternsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildMeasureTypeSelector(ZaftoColors colors) {
    return Row(children: [
      Expanded(child: GestureDetector(
        onTap: () { setState(() { _measureType = 'adjacent'; }); _calculate(); },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _measureType == 'adjacent' ? colors.accentPrimary : colors.bgElevated,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
          ),
          child: Text('Adjacent Lugs', textAlign: TextAlign.center, style: TextStyle(color: _measureType == 'adjacent' ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600)),
        ),
      )),
      Expanded(child: GestureDetector(
        onTap: () { setState(() { _measureType = 'across'; }); _calculate(); },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _measureType == 'across' ? colors.accentPrimary : colors.bgElevated,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
          ),
          child: Text('Across (Even)', textAlign: TextAlign.center, style: TextStyle(color: _measureType == 'across' ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600)),
        ),
      )),
    ]);
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('BCD = Measurement / sin(angle/2)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Determine bolt circle diameter from measurements', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final lugCount = int.tryParse(_lugCountController.text) ?? 5;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Bolt Pattern', '${lugCount}x${_boltCircle!.toStringAsFixed(2)}"', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Metric', '${lugCount}x$_boltCircleMm mm'),
      ]),
    );
  }

  Widget _buildCommonPatternsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON PATTERNS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildPatternRow(colors, '4x100', 'Honda, Toyota, VW, Mini'),
        _buildPatternRow(colors, '5x100', 'Subaru, Toyota, VW'),
        _buildPatternRow(colors, '5x114.3', 'Honda, Nissan, Toyota, Ford'),
        _buildPatternRow(colors, '5x120', 'BMW, Honda, Chevy Camaro'),
        _buildPatternRow(colors, '6x139.7', 'Toyota trucks, GM trucks'),
      ]),
    );
  }

  Widget _buildPatternRow(ZaftoColors colors, String pattern, String vehicles) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(pattern, style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        Expanded(child: Text(vehicles, textAlign: TextAlign.right, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
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
