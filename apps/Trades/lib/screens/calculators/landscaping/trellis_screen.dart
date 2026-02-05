import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Trellis Calculator - Materials for climbing plants
class TrellisScreen extends ConsumerStatefulWidget {
  const TrellisScreen({super.key});
  @override
  ConsumerState<TrellisScreen> createState() => _TrellisScreenState();
}

class _TrellisScreenState extends ConsumerState<TrellisScreen> {
  final _widthController = TextEditingController(text: '4');
  final _heightController = TextEditingController(text: '6');
  final _spacingController = TextEditingController(text: '6');

  int? _verticals;
  int? _horizontals;
  int? _totalFeet;
  int? _screws;

  @override
  void dispose() { _widthController.dispose(); _heightController.dispose(); _spacingController.dispose(); super.dispose(); }

  void _calculate() {
    final widthFt = double.tryParse(_widthController.text) ?? 4;
    final heightFt = double.tryParse(_heightController.text) ?? 6;
    final spacingIn = double.tryParse(_spacingController.text) ?? 6;

    final spacingFt = spacingIn / 12;

    // Verticals
    final verticals = (widthFt / spacingFt).ceil() + 1;

    // Horizontals
    final horizontals = (heightFt / spacingFt).ceil() + 1;

    // Total linear feet
    final verticalFeet = verticals * heightFt;
    final horizontalFeet = horizontals * widthFt;
    final totalFeet = (verticalFeet + horizontalFeet).ceil();

    // Screws: 2 per intersection
    final intersections = verticals * horizontals;
    final screws = intersections * 2;

    setState(() {
      _verticals = verticals;
      _horizontals = horizontals;
      _totalFeet = totalFeet;
      _screws = screws;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _widthController.text = '4'; _heightController.text = '6'; _spacingController.text = '6'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Trellis Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Height', unit: 'ft', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Grid Spacing', unit: 'inches', controller: _spacingController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_verticals != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('MATERIALS (1×2 or lath)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildResultRow(colors, 'Vertical pieces', '$_verticals'),
                _buildResultRow(colors, 'Horizontal pieces', '$_horizontals'),
                _buildResultRow(colors, 'Total linear feet', "$_totalFeet'"),
                _buildResultRow(colors, 'Screws/staples', '$_screws'),
              ]),
            ),
            const SizedBox(height: 20),
            _buildPlantGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildPlantGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CLIMBING PLANTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Clematis', "6\" spacing"),
        _buildTableRow(colors, 'Morning glory', "4-6\" spacing"),
        _buildTableRow(colors, 'Climbing roses', "8-12\" spacing"),
        _buildTableRow(colors, 'Jasmine', "6\" spacing"),
        _buildTableRow(colors, 'Wisteria', 'Heavy duty frame'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
