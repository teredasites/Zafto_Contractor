import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Wainscoting Calculator - Wall paneling estimation
class WainscotingScreen extends ConsumerStatefulWidget {
  const WainscotingScreen({super.key});
  @override
  ConsumerState<WainscotingScreen> createState() => _WainscotingScreenState();
}

class _WainscotingScreenState extends ConsumerState<WainscotingScreen> {
  final _perimeterController = TextEditingController(text: '60');
  final _heightController = TextEditingController(text: '36');
  final _panelWidthController = TextEditingController(text: '16');

  String _style = 'raised';

  double? _wallSqft;
  int? _panels;
  double? _railLF;
  double? _stileLF;

  @override
  void dispose() { _perimeterController.dispose(); _heightController.dispose(); _panelWidthController.dispose(); super.dispose(); }

  void _calculate() {
    final perimeter = double.tryParse(_perimeterController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 36;
    final panelWidth = double.tryParse(_panelWidthController.text) ?? 16;

    final heightFt = height / 12;
    final wallSqft = perimeter * heightFt;

    // Number of panels (perimeter / panel width)
    final panelWidthFt = panelWidth / 12;
    final panels = (perimeter / panelWidthFt).ceil();

    // Rails: top rail + bottom rail + cap (if raised panel)
    final railLF = perimeter * 3 * 1.10; // 3 horizontal pieces, 10% waste

    // Stiles: vertical dividers between panels
    final stileLF = (panels + 1) * heightFt * 1.10;

    setState(() { _wallSqft = wallSqft; _panels = panels; _railLF = railLF; _stileLF = stileLF; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _perimeterController.text = '60'; _heightController.text = '36'; _panelWidthController.text = '16'; setState(() => _style = 'raised'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Wainscoting', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Room Perimeter', unit: 'feet', controller: _perimeterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Wainscot Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Panel Width', unit: 'inches', controller: _panelWidthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_wallSqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('WALL COVERAGE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_wallSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Panel Count', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~$_panels', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Rails (horizontal)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_railLF!.toStringAsFixed(0)} lf', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Stiles (vertical)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_stileLF!.toStringAsFixed(0)} lf', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Standard height 32-36\". Add cap rail at top. Beadboard is easiest DIY option.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildStyleTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['beadboard', 'raised', 'flat', 'board'];
    final labels = {'beadboard': 'Beadboard', 'raised': 'Raised Panel', 'flat': 'Flat Panel', 'board': 'Board & Batten'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('STYLE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _style == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _style = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildStyleTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('WAINSCOTING STYLES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Beadboard', 'Easiest, panels or planks'),
        _buildTableRow(colors, 'Raised panel', 'Traditional, most detail'),
        _buildTableRow(colors, 'Flat panel', 'Modern, clean lines'),
        _buildTableRow(colors, 'Board & batten', 'Vertical boards, battens'),
        _buildTableRow(colors, 'Picture frame', 'Applied molding boxes'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12), textAlign: TextAlign.right)),
      ]),
    );
  }
}
