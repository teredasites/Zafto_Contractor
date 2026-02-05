import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Closet System Calculator - Closet organization estimation
class ClosetSystemScreen extends ConsumerStatefulWidget {
  const ClosetSystemScreen({super.key});
  @override
  ConsumerState<ClosetSystemScreen> createState() => _ClosetSystemScreenState();
}

class _ClosetSystemScreenState extends ConsumerState<ClosetSystemScreen> {
  final _widthController = TextEditingController(text: '8');
  final _heightController = TextEditingController(text: '8');
  final _depthController = TextEditingController(text: '24');

  String _type = 'reachin';

  double? _shelvingLF;
  double? _rodLF;
  int? _drawers;
  double? _totalSqft;

  @override
  void dispose() { _widthController.dispose(); _heightController.dispose(); _depthController.dispose(); super.dispose(); }

  void _calculate() {
    final width = double.tryParse(_widthController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 8;
    final depth = double.tryParse(_depthController.text) ?? 24;

    final depthFt = depth / 12;

    // Shelving: depends on type
    double shelvingLF;
    double rodLF;
    int drawers;

    switch (_type) {
      case 'reachin':
        // Standard reach-in: 1 rod, 2-3 shelves
        rodLF = width;
        shelvingLF = width * 3; // 3 shelves
        drawers = 0;
        break;
      case 'walkin':
        // Walk-in: 3 walls, double rod on 2
        rodLF = width * 2 + (width * 0.5); // Double + single
        shelvingLF = width * 5; // More shelves
        drawers = 4;
        break;
      case 'custom':
        // Custom: max components
        rodLF = width * 2;
        shelvingLF = width * 6;
        drawers = 6;
        break;
      default:
        rodLF = width;
        shelvingLF = width * 3;
        drawers = 0;
    }

    final totalSqft = width * height;

    setState(() { _shelvingLF = shelvingLF; _rodLF = rodLF; _drawers = drawers; _totalSqft = totalSqft; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _widthController.text = '8'; _heightController.text = '8'; _depthController.text = '24'; setState(() => _type = 'reachin'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Closet System', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Closet Width', unit: 'feet', controller: _widthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Closet Height', unit: 'feet', controller: _heightController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Shelf Depth', unit: 'inches', controller: _depthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalSqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('WALL AREA', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Shelving', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_shelvingLF!.toStringAsFixed(0)} lf', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Hanging Rod', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_rodLF!.toStringAsFixed(0)} lf', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Drawer Units', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_drawers', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Standard rod height: 66-72\" for long, 42\" for double. Shelf depth 12-14\" typical.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildHeightTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['reachin', 'walkin', 'custom'];
    final labels = {'reachin': 'Reach-In', 'walkin': 'Walk-In', 'custom': 'Custom'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('CLOSET TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _type == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _type = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildHeightTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ROD HEIGHTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Long hanging', '66-72\"'),
        _buildTableRow(colors, 'Double rod upper', '80-84\"'),
        _buildTableRow(colors, 'Double rod lower', '40-42\"'),
        _buildTableRow(colors, 'Shirts/blouses', '40-42\"'),
        _buildTableRow(colors, 'Pants folded', '40-42\"'),
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
