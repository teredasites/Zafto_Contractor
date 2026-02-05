import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/zafto/zafto_widgets.dart';

/// Conduit Bending Calculator - Design System v2.6
enum BendType { offset('Offset'), kick90('90° Stub'), saddle('Saddle'), threePointSaddle('3-Pt Saddle'); const BendType(this.label); final String label; }

class ConduitBendingScreen extends ConsumerStatefulWidget {
  const ConduitBendingScreen({super.key});
  @override
  ConsumerState<ConduitBendingScreen> createState() => _ConduitBendingScreenState();
}

class _ConduitBendingScreenState extends ConsumerState<ConduitBendingScreen> {
  BendType _bendType = BendType.offset;
  final _offsetHeightController = TextEditingController();
  int _offsetAngle = 30;
  final _stubHeightController = TextEditingController();
  String _conduitSize = '1/2"';
  final _saddleHeightController = TextEditingController();
  final _obstacleWidthController = TextEditingController();
  Map<String, double>? _results;

  static const Map<String, double> _takeUpValues = {'1/2"': 5.0, '3/4"': 6.0, '1"': 8.0, '1-1/4"': 11.0, '1-1/2"': 13.0, '2"': 15.0};
  static const Map<int, double> _multipliers = {10: 6.0, 15: 3.9, 22: 2.6, 30: 2.0, 45: 1.4, 60: 1.2};
  static const Map<int, double> _shrinkPerInch = {10: 1/16, 15: 1/8, 22: 3/16, 30: 1/4, 45: 3/8, 60: 1/2};

  @override
  void dispose() { _offsetHeightController.dispose(); _stubHeightController.dispose(); _saddleHeightController.dispose(); _obstacleWidthController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Conduit Bending', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildBendTypeSelector(colors),
            const SizedBox(height: 24),
            _buildInputSection(colors),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _calculate, style: ElevatedButton.styleFrom(backgroundColor: colors.accentPrimary, foregroundColor: colors.isDark ? Colors.black : Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('CALCULATE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1))),
            const SizedBox(height: 24),
            if (_results != null) _buildResults(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildBendTypeSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Row(children: BendType.values.map((type) {
        final isSelected = type == _bendType;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() { _bendType = type; _results = null; }); },
          child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Text(type.label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400))),
        ));
      }).toList()),
    );
  }

  Widget _buildInputSection(ZaftoColors colors) {
    switch (_bendType) {
      case BendType.offset: return _buildOffsetInputs(colors);
      case BendType.kick90: return _buildKickInputs(colors);
      case BendType.saddle: return _buildSaddleInputs(colors);
      case BendType.threePointSaddle: return _buildThreePointSaddleInputs(colors);
    }
  }

  Widget _buildOffsetInputs(ZaftoColors colors) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('OFFSET PARAMETERS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      ZaftoInputField(label: 'Offset Height', unit: 'in', hint: 'Depth of offset', controller: _offsetHeightController),
      const SizedBox(height: 12),
      ZaftoInputFieldDropdown<int>(label: 'Bend Angle', value: _offsetAngle, items: const [10, 15, 22, 30, 45, 60], itemLabel: (a) => '$a°', onChanged: (v) => setState(() => _offsetAngle = v)),
      const SizedBox(height: 16),
      _buildOffsetDiagram(colors),
    ]);
  }

  Widget _buildKickInputs(ZaftoColors colors) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('90° STUB-UP PARAMETERS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      ZaftoInputField(label: 'Stub Height', unit: 'in', hint: 'Height from floor', controller: _stubHeightController),
      const SizedBox(height: 12),
      ZaftoInputFieldDropdown<String>(label: 'Conduit Size', value: _conduitSize, items: _takeUpValues.keys.toList(), itemLabel: (s) => s, onChanged: (v) => setState(() => _conduitSize = v)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.borderSubtle)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TAKE-UP & DEDUCT VALUES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 8),
          ..._takeUpValues.entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key, style: TextStyle(color: colors.textSecondary)), Text('${e.value}"', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500))]))),
        ]),
      ),
    ]);
  }

  Widget _buildSaddleInputs(ZaftoColors colors) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('SADDLE PARAMETERS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      ZaftoInputField(label: 'Saddle Height', unit: 'in', hint: 'Height over obstacle', controller: _saddleHeightController),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
        child: Row(children: [Icon(LucideIcons.info, color: colors.accentPrimary, size: 20), const SizedBox(width: 8), Expanded(child: Text('Standard saddle uses 45° center bend with two 22.5° return bends.', style: TextStyle(color: colors.accentPrimary, fontSize: 12)))]),
      ),
    ]);
  }

  Widget _buildThreePointSaddleInputs(ZaftoColors colors) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('3-POINT SADDLE PARAMETERS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      ZaftoInputField(label: 'Saddle Height', unit: 'in', hint: 'Height over obstacle', controller: _saddleHeightController),
      const SizedBox(height: 12),
      ZaftoInputField(label: 'Obstacle Width', unit: 'in', hint: 'Width of obstacle', controller: _obstacleWidthController),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
        child: Row(children: [Icon(LucideIcons.info, color: colors.accentPrimary, size: 20), const SizedBox(width: 8), Expanded(child: Text('3-point saddle: Center 45° bend, outer 22.5° bends. Used for wider obstacles.', style: TextStyle(color: colors.accentPrimary, fontSize: 12)))]),
      ),
    ]);
  }

  Widget _buildOffsetDiagram(ZaftoColors colors) {
    return Container(
      height: 100,
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: CustomPaint(painter: _OffsetPainter(angle: _offsetAngle, accentColor: colors.accentPrimary, warnColor: colors.accentWarning, textColor: colors.textTertiary), size: const Size(double.infinity, 100)),
    );
  }

  Widget _buildResults(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 20), const SizedBox(width: 8), Text('BEND MARKS', style: TextStyle(color: colors.accentSuccess, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1))]),
        const SizedBox(height: 16),
        ..._results!.entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(e.key, style: TextStyle(color: colors.textSecondary)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)), child: Text(_formatMeasurement(e.value), style: TextStyle(color: colors.accentSuccess, fontSize: 18, fontWeight: FontWeight.w700))),
          ]),
        )),
        if (_bendType == BendType.offset) ...[
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          Text('Shrink: ${_formatMeasurement(_results!["Shrink"] ?? 0)}', style: TextStyle(color: colors.accentWarning, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('Add shrink to total measured length', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
        ],
      ]),
    );
  }

  String _formatMeasurement(double inches) {
    final wholeInches = inches.floor();
    final fraction = inches - wholeInches;
    if (fraction < 0.0625) return '$wholeInches"';
    final sixteenths = (fraction * 16).round();
    if (sixteenths == 0) return '$wholeInches"';
    if (sixteenths == 16) return '${wholeInches + 1}"';
    int num = sixteenths, den = 16;
    while (num % 2 == 0 && den % 2 == 0) { num ~/= 2; den ~/= 2; }
    if (wholeInches == 0) return '$num/$den"';
    return '$wholeInches-$num/$den"';
  }

  void _calculate() {
    final colors = ref.read(zaftoColorsProvider);
    switch (_bendType) {
      case BendType.offset:
        final height = double.tryParse(_offsetHeightController.text);
        if (height == null || height <= 0) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Enter valid offset height'), backgroundColor: colors.accentError)); return; }
        final multiplier = _multipliers[_offsetAngle] ?? 2.0;
        final shrinkPerInch = _shrinkPerInch[_offsetAngle] ?? 0.25;
        setState(() { _results = {'First Mark': (height * multiplier) / 2, 'Distance Between Bends': height * multiplier, 'Shrink': height * shrinkPerInch}; });
        break;
      case BendType.kick90:
        final stub = double.tryParse(_stubHeightController.text);
        if (stub == null || stub <= 0) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Enter valid stub height'), backgroundColor: colors.accentError)); return; }
        final deduct = _takeUpValues[_conduitSize] ?? 5.0;
        setState(() { _results = {'Mark from End': stub - deduct, 'Deduct Used': deduct}; });
        break;
      case BendType.saddle:
        final height = double.tryParse(_saddleHeightController.text);
        if (height == null || height <= 0) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Enter valid saddle height'), backgroundColor: colors.accentError)); return; }
        setState(() { _results = {'Center Bend': 0, 'Outer Bends (from center)': height * 2.5, 'Total Shrink': height * 3/16 * 2}; });
        break;
      case BendType.threePointSaddle:
        final height = double.tryParse(_saddleHeightController.text);
        final width = double.tryParse(_obstacleWidthController.text);
        if (height == null || height <= 0) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Enter valid saddle height'), backgroundColor: colors.accentError)); return; }
        final outerDistance = height * 2.6;
        final minOuterDistance = (width ?? 0) / 2 + 2;
        setState(() { _results = {'Center Mark (45°)': 0, 'Outer Marks from Center': math.max(outerDistance, minOuterDistance), 'Total Shrink': height * 3/8}; });
        break;
    }
  }

  void _reset() { _offsetHeightController.clear(); _stubHeightController.clear(); _saddleHeightController.clear(); _obstacleWidthController.clear(); setState(() { _offsetAngle = 30; _conduitSize = '1/2"'; _results = null; }); }
}

class _OffsetPainter extends CustomPainter {
  final int angle;
  final Color accentColor;
  final Color warnColor;
  final Color textColor;
  _OffsetPainter({required this.angle, required this.accentColor, required this.warnColor, required this.textColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = accentColor..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final angleRad = angle * math.pi / 180;
    final startY = size.height * 0.7;
    final endY = size.height * 0.3;
    final offsetHeight = startY - endY;
    final offsetRun = offsetHeight / math.tan(angleRad);
    final path = Path()..moveTo(20, startY)..lineTo(size.width * 0.3, startY)..lineTo(size.width * 0.3 + offsetRun, endY)..lineTo(size.width - 20, endY);
    canvas.drawPath(path, paint);
    final dimPaint = Paint()..color = textColor.withValues(alpha: 0.5)..strokeWidth = 1..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width * 0.15, startY), Offset(size.width * 0.15, endY), dimPaint);
    final textPainter = TextPainter(text: TextSpan(text: '$angle°', style: TextStyle(color: warnColor, fontSize: 12)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.35, startY - 15));
  }

  @override
  bool shouldRepaint(covariant _OffsetPainter oldDelegate) => angle != oldDelegate.angle;
}
