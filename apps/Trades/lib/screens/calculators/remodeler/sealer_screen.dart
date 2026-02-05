import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Sealer Calculator - Wood/concrete sealer estimation
class SealerScreen extends ConsumerStatefulWidget {
  const SealerScreen({super.key});
  @override
  ConsumerState<SealerScreen> createState() => _SealerScreenState();
}

class _SealerScreenState extends ConsumerState<SealerScreen> {
  final _areaSqftController = TextEditingController(text: '200');

  String _surface = 'concrete';
  String _type = 'penetrating';
  String _coats = '1';

  double? _gallons;
  double? _coverage;

  @override
  void dispose() { _areaSqftController.dispose(); super.dispose(); }

  void _calculate() {
    final areaSqft = double.tryParse(_areaSqftController.text) ?? 0;
    final coats = int.tryParse(_coats) ?? 1;

    // Coverage varies by sealer type and surface
    double coveragePerGal;
    switch (_surface) {
      case 'concrete':
        coveragePerGal = _type == 'penetrating' ? 200 : 150;
        break;
      case 'wood':
        coveragePerGal = _type == 'penetrating' ? 250 : 200;
        break;
      case 'stone':
        coveragePerGal = _type == 'penetrating' ? 150 : 100;
        break;
      case 'brick':
        coveragePerGal = 100; // Very porous
        break;
      default:
        coveragePerGal = 200;
    }

    final gallonsPerCoat = areaSqft / coveragePerGal;
    final gallons = gallonsPerCoat * coats;

    setState(() { _gallons = gallons; _coverage = coveragePerGal; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaSqftController.text = '200'; setState(() { _surface = 'concrete'; _type = 'penetrating'; _coats = '1'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Sealer', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SURFACE', ['concrete', 'wood', 'stone', 'brick'], _surface, {'concrete': 'Concrete', 'wood': 'Wood', 'stone': 'Stone', 'brick': 'Brick'}, (v) { setState(() => _surface = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'TYPE', ['penetrating', 'film', 'topical'], _type, {'penetrating': 'Penetrating', 'film': 'Film-Forming', 'topical': 'Topical'}, (v) { setState(() => _type = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'COATS', ['1', '2', '3'], _coats, {'1': '1 Coat', '2': '2 Coats', '3': '3 Coats'}, (v) { setState(() => _coats = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Area to Seal', unit: 'sq ft', controller: _areaSqftController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_gallons != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('SEALER NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gallons!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Coverage Rate', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_coverage!.toStringAsFixed(0)} sqft/gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getSealerTip(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTypeTable(colors),
          ]),
        ),
      ),
    );
  }

  String _getSealerTip() {
    switch (_surface) {
      case 'concrete':
        return 'Clean and etch concrete first. Apply when dry, above 50F. Reapply every 2-5 years.';
      case 'wood':
        return 'Sand smooth before sealing. Apply thin coats. Recoat every 1-3 years exterior.';
      case 'stone':
        return 'Test in hidden area first. Some stones darken when sealed. Reapply yearly exterior.';
      case 'brick':
        return 'Brick is very porous - may need 2-3 coats. Clean efflorescence first.';
      default:
        return 'Surface must be clean and dry. Apply thin, even coats.';
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

  Widget _buildTypeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SEALER TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Penetrating', 'Soaks in, no sheen'),
        _buildTableRow(colors, 'Film-forming', 'Surface coat, glossy'),
        _buildTableRow(colors, 'Acrylic', 'Clear, UV resistant'),
        _buildTableRow(colors, 'Polyurethane', 'Durable, abrasion'),
        _buildTableRow(colors, 'Epoxy', 'Strongest, chemical'),
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
