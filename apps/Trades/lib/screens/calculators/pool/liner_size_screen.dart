import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Vinyl Liner Size Calculator
class LinerSizeScreen extends ConsumerStatefulWidget {
  const LinerSizeScreen({super.key});
  @override
  ConsumerState<LinerSizeScreen> createState() => _LinerSizeScreenState();
}

class _LinerSizeScreenState extends ConsumerState<LinerSizeScreen> {
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _shallowController = TextEditingController(text: '3.5');
  final _deepController = TextEditingController(text: '8');

  double? _linerLength;
  double? _linerWidth;
  double? _estimatedCost;

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final shallow = double.tryParse(_shallowController.text);
    final deep = double.tryParse(_deepController.text);

    if (length == null || width == null || shallow == null || deep == null ||
        length <= 0 || width <= 0 || shallow <= 0 || deep <= 0) {
      setState(() { _linerLength = null; });
      return;
    }

    // Liner size calculation
    // Length = pool length + (2 × max depth) + overlap (2 ft each end)
    // Width = pool width + (2 × max depth) + overlap (2 ft each end)
    final maxDepth = deep > shallow ? deep : shallow;
    final linerLength = length + (2 * maxDepth) + 4;
    final linerWidth = width + (2 * maxDepth) + 4;

    // Liner cost: ~$1-2 per sq ft for material, plus installation
    final sqFt = linerLength * linerWidth;
    final cost = sqFt * 1.5; // Material only

    setState(() {
      _linerLength = linerLength;
      _linerWidth = linerWidth;
      _estimatedCost = cost;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _lengthController.clear();
    _widthController.clear();
    _shallowController.text = '3.5';
    _deepController.text = '8';
    setState(() { _linerLength = null; });
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _shallowController.dispose();
    _deepController.dispose();
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
        title: Text('Vinyl Liner Size', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Pool Length', unit: 'ft', hint: 'Inside length', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Pool Width', unit: 'ft', hint: 'Inside width', controller: _widthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Shallow End', unit: 'ft', hint: 'Shallow depth', controller: _shallowController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Deep End', unit: 'ft', hint: 'Deep depth', controller: _deepController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_linerLength != null) _buildResultsCard(colors),
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
        Text('Liner = Dim + (2 × Depth) + Overlap', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Includes 2 ft overlap on each side', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Liner Length', '${_linerLength!.toStringAsFixed(0)} ft', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Liner Width', '${_linerWidth!.toStringAsFixed(0)} ft'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Total Size', '${_linerLength!.toStringAsFixed(0)} × ${_linerWidth!.toStringAsFixed(0)} ft'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Est. Material', '\$${_estimatedCost!.toStringAsFixed(0)}'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Custom liners are measured precisely by installer. This is for budgeting.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
