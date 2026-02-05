import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/zafto/zafto_widgets.dart';

/// Lighting / Lumen Calculator - Design System v2.6
class LumenScreen extends ConsumerStatefulWidget {
  const LumenScreen({super.key});
  @override
  ConsumerState<LumenScreen> createState() => _LumenScreenState();
}

class _LumenScreenState extends ConsumerState<LumenScreen> {
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController(text: '9');
  String _spaceType = 'Office';
  final _lumensPerFixtureController = TextEditingController(text: '3000');
  Map<String, dynamic>? _results;

  static const Map<String, int> _footCandles = {'Office': 50, 'Classroom': 50, 'Retail': 50, 'Warehouse': 20, 'Workshop': 75, 'Hospital': 100, 'Restaurant': 20, 'Lobby': 20, 'Corridor': 10, 'Parking': 5, 'Outdoor': 2, 'Assembly': 30, 'Kitchen': 75};
  static const double _llf = 0.70;
  static const double _cu = 0.65;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _heightController.dispose(); _lumensPerFixtureController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Lighting Calc', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildSectionHeader(colors, 'ROOM DIMENSIONS'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'ft', controller: _lengthController)),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'ft', controller: _widthController)),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Ceiling Height', unit: 'ft', controller: _heightController),
            const SizedBox(height: 24),
            _buildSectionHeader(colors, 'LIGHTING REQUIREMENTS'),
            const SizedBox(height: 12),
            _buildSpaceTypeSelector(colors),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Lumens/Fixture', unit: 'lm', controller: _lumensPerFixtureController),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _calculate, style: ElevatedButton.styleFrom(backgroundColor: colors.accentPrimary, foregroundColor: colors.isDark ? Colors.black : Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('CALCULATE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1))),
            const SizedBox(height: 24),
            if (_results != null) _buildResults(colors),
            const SizedBox(height: 24),
            _buildFootCandlesCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.lightbulb, color: colors.accentWarning, size: 20), const SizedBox(width: 8), Text('Lumen Method', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('Lumens = (FC × Area) / (CU × LLF)', style: TextStyle(color: colors.textSecondary, fontFamily: 'monospace', fontSize: 13)),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildSpaceTypeSelector(ZaftoColors colors) {
    final types = ['Office', 'Classroom', 'Retail', 'Warehouse', 'Workshop', 'Hospital', 'Restaurant', 'Lobby', 'Corridor', 'Kitchen'];
    final fc = _footCandles[_spaceType] ?? 50;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [
        Expanded(child: DropdownButton<String>(value: _spaceType, isExpanded: true, dropdownColor: colors.bgElevated, underline: const SizedBox(), style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500), items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _spaceType = v!))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text('$fc fc', style: TextStyle(color: colors.accentWarning, fontSize: 12, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _buildResults(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3))),
      child: Column(children: [
        Icon(LucideIcons.lightbulb, color: colors.accentWarning, size: 32),
        const SizedBox(height: 12),
        Text('${_results!['fixtures']}', style: TextStyle(color: colors.accentWarning, fontSize: 56, fontWeight: FontWeight.w700)),
        Text('FIXTURES REQUIRED', style: TextStyle(color: colors.textTertiary, letterSpacing: 1)),
        const SizedBox(height: 20),
        _buildResultRow(colors, label: 'Room Area', value: '${(_results!['area'] as double).toStringAsFixed(0)} sq ft'),
        const SizedBox(height: 8),
        _buildResultRow(colors, label: 'Target', value: '${_footCandles[_spaceType]} foot-candles'),
        const SizedBox(height: 8),
        _buildResultRow(colors, label: 'Required Lumens', value: '${(_results!['lumens'] as double).toStringAsFixed(0)} lm'),
        const SizedBox(height: 8),
        _buildResultRow(colors, label: 'Room Cavity Ratio', value: (_results!['rcr'] as double).toStringAsFixed(2)),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Row(children: [
          Icon(LucideIcons.info, color: colors.accentPrimary, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text('Using CU=${_cu.toStringAsFixed(2)}, LLF=${_llf.toStringAsFixed(2)}', style: TextStyle(color: colors.accentPrimary, fontSize: 12))),
        ])),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, {required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildFootCandlesCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('RECOMMENDED FOOT-CANDLES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _buildFCChip(colors, 'Office', 50), _buildFCChip(colors, 'Retail', 50), _buildFCChip(colors, 'Warehouse', 20),
          _buildFCChip(colors, 'Workshop', 75), _buildFCChip(colors, 'Hospital', 100), _buildFCChip(colors, 'Kitchen', 75),
        ]),
      ]),
    );
  }

  Widget _buildFCChip(ZaftoColors colors, String label, int fc) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(6)), child: Text('$label: $fc fc', style: TextStyle(color: colors.textSecondary, fontSize: 11)));

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final height = double.tryParse(_heightController.text);
    final lumensPerFixture = double.tryParse(_lumensPerFixtureController.text);
    if (length == null || width == null || height == null || lumensPerFixture == null) { _showError('Enter all dimensions'); return; }
    final area = length * width;
    const workPlane = 2.5;
    final cavityHeight = height - workPlane;
    final rcr = (5 * cavityHeight * (length + width)) / area;
    final fc = _footCandles[_spaceType] ?? 50;
    final requiredLumens = (fc * area) / (_cu * _llf);
    final fixtures = (requiredLumens / lumensPerFixture).ceil();
    setState(() => _results = {'area': area, 'rcr': rcr, 'lumens': requiredLumens, 'fixtures': fixtures});
  }

  void _showError(String msg) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: ref.read(zaftoColorsProvider).accentError)); }
  void _reset() { _lengthController.clear(); _widthController.clear(); _heightController.text = '9'; _lumensPerFixtureController.text = '3000'; setState(() { _spaceType = 'Office'; _results = null; }); }
}
