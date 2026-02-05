import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Accent Wall Calculator - Feature wall estimation
class AccentWallScreen extends ConsumerStatefulWidget {
  const AccentWallScreen({super.key});
  @override
  ConsumerState<AccentWallScreen> createState() => _AccentWallScreenState();
}

class _AccentWallScreenState extends ConsumerState<AccentWallScreen> {
  final _widthController = TextEditingController(text: '12');
  final _heightController = TextEditingController(text: '8');
  final _doorsController = TextEditingController(text: '0');
  final _windowsController = TextEditingController(text: '1');

  String _material = 'paint';

  double? _wallSqft;
  double? _paintQts;
  int? _planks;
  double? _boardFeet;

  @override
  void dispose() { _widthController.dispose(); _heightController.dispose(); _doorsController.dispose(); _windowsController.dispose(); super.dispose(); }

  void _calculate() {
    final width = double.tryParse(_widthController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 8;
    final doors = int.tryParse(_doorsController.text) ?? 0;
    final windows = int.tryParse(_windowsController.text) ?? 0;

    var wallSqft = width * height;
    wallSqft -= (doors * 21) + (windows * 15);
    if (wallSqft < 0) wallSqft = 0;

    // Paint: 1 quart covers ~100 sqft, need 2-3 coats for accent
    final paintQts = (wallSqft / 100) * 2.5;

    // Shiplap/planks: 6" planks, add 10% waste
    final plankSqft = wallSqft * 1.10;
    final planks = (plankSqft / 0.5).ceil(); // Each 6" plank = 0.5 sqft per lf

    // Board feet for dimensional lumber
    final boardFeet = wallSqft * 1.15;

    setState(() { _wallSqft = wallSqft; _paintQts = paintQts; _planks = (plankSqft * 2).ceil(); _boardFeet = boardFeet; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _widthController.text = '12'; _heightController.text = '8'; _doorsController.text = '0'; _windowsController.text = '1'; setState(() => _material = 'paint'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Accent Wall', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Wall Width', unit: 'feet', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Wall Height', unit: 'feet', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Doors', unit: 'qty', controller: _doorsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Windows', unit: 'qty', controller: _windowsController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_wallSqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('WALL AREA', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_wallSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                if (_material == 'paint') ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Paint (2-3 coats)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_paintQts!.toStringAsFixed(1)} qts', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                if (_material == 'shiplap' || _material == 'plank') ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Planks (lf)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~$_planks', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                if (_material == 'wood') ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Board Feet', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_boardFeet!.toStringAsFixed(0)} bf', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                if (_material == 'stone') ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Stone Veneer', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_wallSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Accent walls work best on the wall your eye goes to first. Avoid walls with too many doors/windows.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildIdeasTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['paint', 'shiplap', 'wood', 'stone'];
    final labels = {'paint': 'Bold Paint', 'shiplap': 'Shiplap', 'wood': 'Reclaimed', 'stone': 'Stone'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('MATERIAL', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _material == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _material = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildIdeasTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ACCENT WALL IDEAS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Bold paint', 'Quickest, cheapest'),
        _buildTableRow(colors, 'Shiplap', 'Farmhouse, coastal'),
        _buildTableRow(colors, 'Board & batten', 'Classic, texture'),
        _buildTableRow(colors, 'Reclaimed wood', 'Rustic, unique'),
        _buildTableRow(colors, 'Stone veneer', 'Dramatic, fireplace'),
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
