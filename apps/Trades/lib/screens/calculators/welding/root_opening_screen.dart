import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Root Opening Calculator - Recommended root gaps
class RootOpeningScreen extends ConsumerStatefulWidget {
  const RootOpeningScreen({super.key});
  @override
  ConsumerState<RootOpeningScreen> createState() => _RootOpeningScreenState();
}

class _RootOpeningScreenState extends ConsumerState<RootOpeningScreen> {
  final _thicknessController = TextEditingController();
  String _jointType = 'V-Groove';
  String _process = 'SMAW';
  bool _withBacking = false;

  double? _minRootOpening;
  double? _maxRootOpening;
  double? _recommendedRootFace;
  String? _notes;

  void _calculate() {
    final thickness = double.tryParse(_thicknessController.text);

    double minRoot, maxRoot, rootFace;
    String notes;

    if (_jointType == 'V-Groove' || _jointType == 'Bevel') {
      if (_withBacking) {
        minRoot = 0.25;
        maxRoot = 0.375;
        rootFace = 0;
        notes = 'With backing - larger root opening, no root face needed';
      } else {
        if (_process == 'GTAW') {
          minRoot = 0.0625;
          maxRoot = 0.125;
          rootFace = 0.0625;
          notes = 'TIG allows tighter root for precise control';
        } else if (_process == 'SMAW') {
          minRoot = 0.125;
          maxRoot = 0.1875;
          rootFace = 0.0625;
          notes = 'Standard SMAW root opening for electrode access';
        } else {
          minRoot = 0.09375;
          maxRoot = 0.15625;
          rootFace = 0.0625;
          notes = 'Standard root opening for ${_process}';
        }
      }
    } else if (_jointType == 'Square') {
      if (thickness != null && thickness <= 0.25) {
        minRoot = 0.0625;
        maxRoot = 0.09375;
        rootFace = thickness;
        notes = 'Square groove for thin material - full penetration';
      } else {
        minRoot = 0.09375;
        maxRoot = 0.125;
        rootFace = thickness ?? 0.25;
        notes = 'Square groove limited to ~1/4" max thickness';
      }
    } else {
      // U or J groove
      minRoot = 0.0625;
      maxRoot = 0.125;
      rootFace = 0.125;
      notes = 'U/J grooves reduce weld volume with good access';
    }

    setState(() {
      _minRootOpening = minRoot;
      _maxRootOpening = maxRoot;
      _recommendedRootFace = rootFace;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _thicknessController.clear();
    setState(() { _minRootOpening = null; });
  }

  @override
  void dispose() {
    _thicknessController.dispose();
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
        title: Text('Root Opening', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Joint Type', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildJointSelector(colors),
            const SizedBox(height: 16),
            Text('Process', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildProcessSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Material Thickness', unit: 'in', hint: 'Optional', controller: _thicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: Text('With Backing Strip/Ring', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
              value: _withBacking,
              onChanged: (v) => setState(() { _withBacking = v ?? false; _calculate(); }),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),
            if (_minRootOpening != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildJointSelector(ZaftoColors colors) {
    final types = ['V-Groove', 'Bevel', 'Square', 'U-Groove', 'J-Groove'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) => ChoiceChip(
        label: Text(t, style: const TextStyle(fontSize: 11)),
        selected: _jointType == t,
        onSelected: (_) => setState(() { _jointType = t; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildProcessSelector(ZaftoColors colors) {
    final processes = ['SMAW', 'GMAW', 'GTAW', 'FCAW'];
    return Wrap(
      spacing: 8,
      children: processes.map((p) => ChoiceChip(
        label: Text(p),
        selected: _process == p,
        onSelected: (_) => setState(() { _process = p; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Root Opening Guidelines', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Per AWS D1.1 prequalified joints', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    String rootDisplay = '${(_minRootOpening! * 16).round()}/16" - ${(_maxRootOpening! * 16).round()}/16"';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Root Opening', rootDisplay, isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Decimal', '${_minRootOpening!.toStringAsFixed(3)}" - ${_maxRootOpening!.toStringAsFixed(3)}"'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Root Face', '${_recommendedRootFace!.toStringAsFixed(3)}"'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_notes!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Flexible(child: Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 20 : 14, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600), textAlign: TextAlign.right)),
    ]);
  }
}
