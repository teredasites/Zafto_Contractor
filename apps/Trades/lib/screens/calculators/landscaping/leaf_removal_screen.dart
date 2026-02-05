import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Leaf Removal Calculator - Time and debris estimate
class LeafRemovalScreen extends ConsumerStatefulWidget {
  const LeafRemovalScreen({super.key});
  @override
  ConsumerState<LeafRemovalScreen> createState() => _LeafRemovalScreenState();
}

class _LeafRemovalScreenState extends ConsumerState<LeafRemovalScreen> {
  final _areaController = TextEditingController(text: '10000');
  final _treesController = TextEditingController(text: '5');
  final _rateController = TextEditingController(text: '50');

  String _coverage = 'moderate';
  String _equipment = 'blower';

  double? _timeHours;
  double? _debrisCuYd;
  double? _price;
  int? _bags;

  @override
  void dispose() { _areaController.dispose(); _treesController.dispose(); _rateController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 10000;
    final trees = int.tryParse(_treesController.text) ?? 5;
    final hourlyRate = double.tryParse(_rateController.text) ?? 50;

    // Coverage factor
    double coverageFactor;
    switch (_coverage) {
      case 'light': coverageFactor = 0.5; break;
      case 'moderate': coverageFactor = 1.0; break;
      case 'heavy': coverageFactor = 2.0; break;
      default: coverageFactor = 1.0;
    }

    // Equipment rate (sq ft per hour)
    double sqftPerHour;
    switch (_equipment) {
      case 'rake': sqftPerHour = 500; break;
      case 'blower': sqftPerHour = 3000; break;
      case 'vacuum': sqftPerHour = 5000; break;
      default: sqftPerHour = 3000;
    }

    final adjustedRate = sqftPerHour / coverageFactor;
    final timeHours = area / adjustedRate;

    // Debris: ~1 cu yd per large tree with full coverage
    final debrisCuYd = trees * coverageFactor * 0.5;
    final bags = (debrisCuYd * 27 / 3).ceil(); // ~3 cu ft per 30-gal bag

    final price = timeHours * hourlyRate;

    setState(() {
      _timeHours = timeHours;
      _debrisCuYd = debrisCuYd;
      _price = price;
      _bags = bags;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '10000'; _treesController.text = '5'; _rateController.text = '50'; setState(() { _coverage = 'moderate'; _equipment = 'blower'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Leaf Removal', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'LEAF COVERAGE', ['light', 'moderate', 'heavy'], _coverage, {'light': 'Light', 'moderate': 'Moderate', 'heavy': 'Heavy'}, (v) { setState(() => _coverage = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'EQUIPMENT', ['rake', 'blower', 'vacuum'], _equipment, {'rake': 'Rake', 'blower': 'Blower', 'vacuum': 'Vacuum'}, (v) { setState(() => _equipment = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Lawn Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Trees', unit: '', controller: _treesController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Hourly Rate', unit: '\$/hr', controller: _rateController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_timeHours != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('EST. TIME', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${(_timeHours! * 60).toStringAsFixed(0)} min', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Debris estimate', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_debrisCuYd!.toStringAsFixed(1)} cu yd', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('30-gal bags', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~$_bags bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Suggested price', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_price!.toStringAsFixed(0)}', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTipsGuide(colors),
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

  Widget _buildTipsGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PRICING GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Small yard', '\$100-200'),
        _buildTableRow(colors, 'Medium yard', '\$200-400'),
        _buildTableRow(colors, 'Large yard', '\$400-600+'),
        _buildTableRow(colors, 'Haul away', '+\$25-50/load'),
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
