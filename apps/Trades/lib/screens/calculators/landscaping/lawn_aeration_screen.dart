import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Lawn Aeration Calculator - Equipment time and pricing
class LawnAerationScreen extends ConsumerStatefulWidget {
  const LawnAerationScreen({super.key});
  @override
  ConsumerState<LawnAerationScreen> createState() => _LawnAerationScreenState();
}

class _LawnAerationScreenState extends ConsumerState<LawnAerationScreen> {
  final _areaController = TextEditingController(text: '10000');
  final _rateController = TextEditingController(text: '15');

  String _equipment = 'walk';

  double? _timeHours;
  double? _price;
  int? _passes;

  @override
  void dispose() { _areaController.dispose(); _rateController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 10000;
    final ratePerK = double.tryParse(_rateController.text) ?? 15;

    // Coverage rate (sq ft per hour)
    double sqftPerHour;
    switch (_equipment) {
      case 'walk': sqftPerHour = 8000; break;
      case 'ride': sqftPerHour = 20000; break;
      case 'tow': sqftPerHour = 15000; break;
      default: sqftPerHour = 8000;
    }

    // Two passes recommended
    final passes = 2;
    final totalArea = area * passes;
    final timeHours = totalArea / sqftPerHour;

    // Pricing per 1000 sq ft
    final price = (area / 1000) * ratePerK;

    setState(() {
      _timeHours = timeHours;
      _price = price;
      _passes = passes;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '10000'; _rateController.text = '15'; setState(() { _equipment = 'walk'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Lawn Aeration', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'EQUIPMENT TYPE', ['walk', 'ride', 'tow'], _equipment, {'walk': 'Walk-Behind', 'ride': 'Ride-On', 'tow': 'Tow-Behind'}, (v) { setState(() => _equipment = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Lawn Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Price Rate', unit: '\$/1000 sq ft', controller: _rateController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_timeHours != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('EST. TIME', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_timeHours!.toStringAsFixed(1)} hrs', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Passes recommended', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_passes', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Suggested price', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_price!.toStringAsFixed(0)}', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Best done in fall or spring when grass is actively growing. Water day before.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildAerationGuide(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildAerationGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('AERATION GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Core size', '2-3" deep, 0.5" wide'),
        _buildTableRow(colors, 'Hole spacing', '2-3" apart'),
        _buildTableRow(colors, 'Cool season', 'Sept-Oct or Apr-May'),
        _buildTableRow(colors, 'Warm season', 'May-July'),
        _buildTableRow(colors, 'Frequency', '1-2x per year'),
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
