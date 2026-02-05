import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Window Well Calculator - Egress window well sizing
class WindowWellScreen extends ConsumerStatefulWidget {
  const WindowWellScreen({super.key});
  @override
  ConsumerState<WindowWellScreen> createState() => _WindowWellScreenState();
}

class _WindowWellScreenState extends ConsumerState<WindowWellScreen> {
  final _windowWidthController = TextEditingController(text: '36');
  final _windowHeightController = TextEditingController(text: '48');
  final _depthController = TextEditingController(text: '48');

  String _type = 'steel';
  bool _egressRequired = true;

  double? _wellWidth;
  double? _wellProjection;
  double? _gravelCuFt;
  bool? _meetsEgress;

  @override
  void dispose() { _windowWidthController.dispose(); _windowHeightController.dispose(); _depthController.dispose(); super.dispose(); }

  void _calculate() {
    final windowWidth = double.tryParse(_windowWidthController.text) ?? 36;
    final windowHeight = double.tryParse(_windowHeightController.text) ?? 48;
    final depth = double.tryParse(_depthController.text) ?? 48;

    // Well must be wider than window + 6" each side minimum
    final wellWidth = windowWidth + 12;

    // Projection: window height + 6" minimum, 36" for egress
    double wellProjection;
    if (_egressRequired) {
      wellProjection = 36; // Egress minimum
    } else {
      wellProjection = windowHeight / 2 + 6;
    }

    // Gravel: 4" depth for drainage
    final wellSqft = (wellWidth / 12) * (wellProjection / 12);
    final gravelCuFt = wellSqft * (4 / 12);

    // Check egress requirements: 9 sqft area, 36" projection min
    final sqftArea = (wellWidth / 12) * (wellProjection / 12);
    final meetsEgress = sqftArea >= 9 && wellProjection >= 36;

    setState(() { _wellWidth = wellWidth; _wellProjection = wellProjection; _gravelCuFt = gravelCuFt; _meetsEgress = meetsEgress; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _windowWidthController.text = '36'; _windowHeightController.text = '48'; _depthController.text = '48'; setState(() { _type = 'steel'; _egressRequired = true; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Window Well', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 16),
            _buildToggle(colors, 'Egress Window (Bedroom)', _egressRequired, (v) { setState(() => _egressRequired = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Window Width', unit: 'inches', controller: _windowWidthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Window Height', unit: 'inches', controller: _windowHeightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Well Depth', unit: 'inches', controller: _depthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_wellWidth != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('WELL SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_wellWidth!.toStringAsFixed(0)}\" x ${_wellProjection!.toStringAsFixed(0)}\"', style: TextStyle(color: colors.accentPrimary, fontSize: 20, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Min Well Width', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_wellWidth!.toStringAsFixed(0)}\"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Min Projection', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_wellProjection!.toStringAsFixed(0)}\"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Gravel (4\" base)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gravelCuFt!.toStringAsFixed(1)} cu ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_egressRequired) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Meets Egress', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_meetsEgress! ? 'Yes' : 'No - check code', style: TextStyle(color: _meetsEgress! ? colors.accentSuccess : colors.accentError, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Egress code: 9 sqft min area, 36\" min projection. Wells >44\" deep need ladder/steps.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildCodeTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['steel', 'plastic', 'concrete'];
    final labels = {'steel': 'Steel', 'plastic': 'Plastic', 'concrete': 'Concrete'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('WELL TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
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

  Widget _buildToggle(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onChanged(!value); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(color: value ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: value ? colors.accentPrimary : colors.borderSubtle)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14))),
          Icon(value ? LucideIcons.checkSquare : LucideIcons.square, size: 20, color: value ? colors.accentPrimary : colors.textTertiary),
        ]),
      ),
    );
  }

  Widget _buildCodeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('EGRESS REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Well area', '9 sq ft minimum'),
        _buildTableRow(colors, 'Projection', '36\" minimum'),
        _buildTableRow(colors, 'Ladder required', 'Wells > 44\" deep'),
        _buildTableRow(colors, 'Cover', 'Max 50 lbs to open'),
        _buildTableRow(colors, 'Drainage', '4\" gravel + drain'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
