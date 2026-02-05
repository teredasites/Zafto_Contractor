import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Shelving Calculator - Shelf material estimation
class ShelvingScreen extends ConsumerStatefulWidget {
  const ShelvingScreen({super.key});
  @override
  ConsumerState<ShelvingScreen> createState() => _ShelvingScreenState();
}

class _ShelvingScreenState extends ConsumerState<ShelvingScreen> {
  final _shelvesController = TextEditingController(text: '5');
  final _widthController = TextEditingController(text: '36');
  final _depthController = TextEditingController(text: '12');

  String _material = 'melamine';

  double? _totalLF;
  double? _totalSqft;
  int? _brackets;
  int? _supports;

  @override
  void dispose() { _shelvesController.dispose(); _widthController.dispose(); _depthController.dispose(); super.dispose(); }

  void _calculate() {
    final shelves = int.tryParse(_shelvesController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 36;
    final depth = double.tryParse(_depthController.text) ?? 12;

    final widthFt = width / 12;
    final depthFt = depth / 12;

    final totalLF = widthFt * shelves;
    final totalSqft = widthFt * depthFt * shelves;

    // Brackets: 2 per shelf minimum, add 1 for every 32" of span
    final bracketsPerShelf = 2 + ((width - 1) / 32).floor();
    final brackets = bracketsPerShelf * shelves;

    // Mid supports needed if span > 36"
    final supports = width > 36 ? shelves : 0;

    setState(() { _totalLF = totalLF; _totalSqft = totalSqft; _brackets = brackets; _supports = supports; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _shelvesController.text = '5'; _widthController.text = '36'; _depthController.text = '12'; setState(() => _material = 'melamine'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Shelving', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Number of Shelves', unit: 'qty', controller: _shelvesController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Shelf Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Shelf Depth', unit: 'inches', controller: _depthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalLF != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL SHELVING', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalLF!.toStringAsFixed(1)} lf', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Board Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalSqft!.toStringAsFixed(1)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Brackets Needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_brackets', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_supports! > 0) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Mid Supports', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_supports', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Max span without sag: 3/4\" MDF 24\", 3/4\" plywood 32\", 1\" solid wood 36\".', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSpanTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['melamine', 'plywood', 'solid', 'wire'];
    final labels = {'melamine': 'Melamine', 'plywood': 'Plywood', 'solid': 'Solid Wood', 'wire': 'Wire'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('MATERIAL', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _material == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _material = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildSpanTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MAX SPAN (LIGHT LOAD)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '3/4\" particleboard', '24\"'),
        _buildTableRow(colors, '3/4\" MDF', '28\"'),
        _buildTableRow(colors, '3/4\" plywood', '32\"'),
        _buildTableRow(colors, '1\" solid wood', '36\"'),
        _buildTableRow(colors, 'Wire shelf', '36\"'),
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
