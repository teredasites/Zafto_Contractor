import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Walkway Calculator - Walkway materials estimation
class WalkwayScreen extends ConsumerStatefulWidget {
  const WalkwayScreen({super.key});
  @override
  ConsumerState<WalkwayScreen> createState() => _WalkwayScreenState();
}

class _WalkwayScreenState extends ConsumerState<WalkwayScreen> {
  final _lengthController = TextEditingController(text: '30');
  final _widthController = TextEditingController(text: '3');

  String _material = 'paver';
  String _edgeType = 'soldier';

  double? _sqft;
  double? _materialQty;
  double? _baseTons;
  double? _edgeFeet;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 30;
    final width = double.tryParse(_widthController.text) ?? 3;

    final sqft = length * width;
    final edgeFeet = length * 2; // both sides

    double materialQty;
    switch (_material) {
      case 'paver':
        materialQty = sqft * 4.5 * 1.10; // 4.5 pavers per sqft + 10%
        break;
      case 'flagstone':
        materialQty = sqft * 1.10; // sq ft + 10%
        break;
      case 'concrete':
        final cuYd = (sqft * (4 / 12)) / 27; // 4\" thick
        materialQty = cuYd;
        break;
      case 'gravel':
        final cuYd = (sqft * (3 / 12)) / 27; // 3\" thick
        materialQty = cuYd;
        break;
      default:
        materialQty = sqft;
    }

    // Base material: 4\" depth for pavers/stone, none for concrete
    double baseTons;
    if (_material == 'paver' || _material == 'flagstone') {
      baseTons = sqft / 80; // 1 ton covers ~80 sq ft at 4\"
    } else if (_material == 'gravel') {
      baseTons = 0; // gravel is the surface
    } else {
      baseTons = sqft / 160; // 2\" base for concrete
    }

    setState(() { _sqft = sqft; _materialQty = materialQty; _baseTons = baseTons; _edgeFeet = edgeFeet; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '30'; _widthController.text = '3'; setState(() { _material = 'paver'; _edgeType = 'soldier'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Walkway', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MATERIAL', ['paver', 'flagstone', 'concrete', 'gravel'], _material, {'paver': 'Paver', 'flagstone': 'Flagstone', 'concrete': 'Concrete', 'gravel': 'Gravel'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'EDGE STYLE', ['soldier', 'border', 'natural', 'none'], _edgeType, {'soldier': 'Soldier', 'border': 'Border', 'natural': 'Natural', 'none': 'None'}, (v) { setState(() => _edgeType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'feet', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_sqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL AREA', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_sqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_getMaterialLabel(), style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_getMaterialQtyStr(), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                if (_baseTons! > 0)
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Base Gravel', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_baseTons!.toStringAsFixed(1)} tons', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Edge Length', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_edgeFeet!.toStringAsFixed(0)} lin ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Min width 3\' for single person, 4-5\' for two abreast. Slope away from house 1/4\" per foot. Use landscape fabric under gravel.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildWidthTable(colors),
          ]),
        ),
      ),
    );
  }

  String _getMaterialLabel() {
    switch (_material) {
      case 'paver': return 'Pavers (4x8)';
      case 'flagstone': return 'Flagstone';
      case 'concrete': return 'Concrete';
      case 'gravel': return 'Gravel';
      default: return 'Material';
    }
  }

  String _getMaterialQtyStr() {
    switch (_material) {
      case 'paver': return '${_materialQty!.toStringAsFixed(0)} pcs';
      case 'flagstone': return '${_materialQty!.toStringAsFixed(0)} sq ft';
      case 'concrete': return '${_materialQty!.toStringAsFixed(1)} cu yd';
      case 'gravel': return '${_materialQty!.toStringAsFixed(1)} cu yd';
      default: return '${_materialQty!.toStringAsFixed(0)}';
    }
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildWidthTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('RECOMMENDED WIDTHS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Garden path', '18-24\"'),
        _buildTableRow(colors, 'Side yard', '36\" minimum'),
        _buildTableRow(colors, 'Front walk', '4-5\' wide'),
        _buildTableRow(colors, 'ADA accessible', '36\" minimum'),
        _buildTableRow(colors, 'Service access', '36-48\"'),
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
