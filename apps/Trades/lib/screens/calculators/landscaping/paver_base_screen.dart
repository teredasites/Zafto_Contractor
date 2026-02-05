import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Paver Base Calculator - Gravel and sand for paver base
class PaverBaseScreen extends ConsumerStatefulWidget {
  const PaverBaseScreen({super.key});
  @override
  ConsumerState<PaverBaseScreen> createState() => _PaverBaseScreenState();
}

class _PaverBaseScreenState extends ConsumerState<PaverBaseScreen> {
  final _areaController = TextEditingController(text: '200');

  String _useType = 'patio';

  double? _gravelTons;
  double? _sandTons;
  double? _gravelDepth;
  double? _sandDepth;

  @override
  void dispose() { _areaController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 200;

    // Base depths based on use
    double gravelDepthIn;
    double sandDepthIn;
    switch (_useType) {
      case 'patio':
        gravelDepthIn = 4;
        sandDepthIn = 1;
        break;
      case 'walkway':
        gravelDepthIn = 3;
        sandDepthIn = 1;
        break;
      case 'driveway':
        gravelDepthIn = 8;
        sandDepthIn = 1;
        break;
      default:
        gravelDepthIn = 4;
        sandDepthIn = 1;
    }

    // Calculate volumes
    final gravelCuFt = area * (gravelDepthIn / 12);
    final gravelCuYd = gravelCuFt / 27;
    final gravelTons = gravelCuYd * 1.4; // Crusite ~1.4 tons/cu yd

    final sandCuFt = area * (sandDepthIn / 12);
    final sandCuYd = sandCuFt / 27;
    final sandTons = sandCuYd * 1.35;

    setState(() {
      _gravelTons = gravelTons;
      _sandTons = sandTons;
      _gravelDepth = gravelDepthIn;
      _sandDepth = sandDepthIn;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '200'; setState(() { _useType = 'patio'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Paver Base', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'USE TYPE', ['walkway', 'patio', 'driveway'], _useType, {'walkway': 'Walkway', 'patio': 'Patio', 'driveway': 'Driveway'}, (v) { setState(() => _useType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Paver Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_gravelTons != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('GRAVEL BASE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gravelTons!.toStringAsFixed(2)} tons', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 4),
                Text('${_gravelDepth!.toStringAsFixed(0)}\" depth', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Bedding sand', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_sandTons!.toStringAsFixed(2)} tons', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 4),
                Text('${_sandDepth!.toStringAsFixed(0)}\" depth', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ]),
            ),
            const SizedBox(height: 20),
            _buildBaseGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildBaseGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BASE SPECIFICATIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Walkway', '3\" gravel + 1\" sand'),
        _buildTableRow(colors, 'Patio', '4\" gravel + 1\" sand'),
        _buildTableRow(colors, 'Driveway', '6-8\" gravel + 1\" sand'),
        _buildTableRow(colors, 'Compaction', '95% per 2\" lift'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
