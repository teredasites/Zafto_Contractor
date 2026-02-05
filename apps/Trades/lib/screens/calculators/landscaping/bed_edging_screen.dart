import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Bed Edging Calculator - Edging material and labor
class BedEdgingScreen extends ConsumerStatefulWidget {
  const BedEdgingScreen({super.key});
  @override
  ConsumerState<BedEdgingScreen> createState() => _BedEdgingScreenState();
}

class _BedEdgingScreenState extends ConsumerState<BedEdgingScreen> {
  final _lengthController = TextEditingController(text: '100');

  String _edgingType = 'steel';

  double? _materialCost;
  double? _stakesNeeded;
  double? _laborHours;
  double? _totalCost;

  @override
  void dispose() { _lengthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 100;

    // Material costs per linear foot
    double costPerFt;
    double stakesPerFt;
    double ftPerHour;

    switch (_edgingType) {
      case 'steel':
        costPerFt = 3.50;
        stakesPerFt = 0.25; // 1 stake per 4 ft
        ftPerHour = 25;
        break;
      case 'aluminum':
        costPerFt = 4.50;
        stakesPerFt = 0.25;
        ftPerHour = 30;
        break;
      case 'plastic':
        costPerFt = 1.25;
        stakesPerFt = 0.5; // 1 stake per 2 ft
        ftPerHour = 40;
        break;
      case 'brick':
        costPerFt = 8.00;
        stakesPerFt = 0;
        ftPerHour = 10;
        break;
      case 'stone':
        costPerFt = 12.00;
        stakesPerFt = 0;
        ftPerHour = 8;
        break;
      default:
        costPerFt = 3.50;
        stakesPerFt = 0.25;
        ftPerHour = 25;
    }

    final materialCost = length * costPerFt;
    final stakes = length * stakesPerFt;
    final labor = length / ftPerHour;
    final laborCost = labor * 45; // $45/hr labor
    final total = materialCost + laborCost + (stakes * 0.75); // stakes ~$0.75 each

    setState(() {
      _materialCost = materialCost;
      _stakesNeeded = stakes;
      _laborHours = labor;
      _totalCost = total;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '100'; setState(() { _edgingType = 'steel'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Bed Edging', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'EDGING TYPE', ['steel', 'aluminum', 'plastic'], _edgingType, {'steel': 'Steel', 'aluminum': 'Aluminum', 'plastic': 'Plastic'}, (v) { setState(() => _edgingType = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, '', ['brick', 'stone'], _edgingType, {'brick': 'Brick', 'stone': 'Stone'}, (v) { setState(() => _edgingType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Edging Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_totalCost != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL COST', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_totalCost!.toStringAsFixed(0)}', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Material cost', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_materialCost!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                if (_stakesNeeded! > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Stakes needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_stakesNeeded!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_stakesNeeded! > 0) const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Labor hours', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_laborHours!.toStringAsFixed(1)} hrs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildEdgingGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title.isNotEmpty) ...[
        Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 8),
      ],
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

  Widget _buildEdgingGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('EDGING COMPARISON', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Steel', '20+ years, professional'),
        _buildTableRow(colors, 'Aluminum', 'Rust-free, lightweight'),
        _buildTableRow(colors, 'Plastic', 'Budget, DIY friendly'),
        _buildTableRow(colors, 'Brick/Stone', 'Permanent, decorative'),
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
