import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Mowing Time Calculator - Estimate job duration
class MowingTimeScreen extends ConsumerStatefulWidget {
  const MowingTimeScreen({super.key});
  @override
  ConsumerState<MowingTimeScreen> createState() => _MowingTimeScreenState();
}

class _MowingTimeScreenState extends ConsumerState<MowingTimeScreen> {
  final _areaController = TextEditingController(text: '10000');
  final _rateController = TextEditingController(text: '45');

  String _mowerType = 'push';
  String _terrain = 'flat';

  double? _mowingTime;
  double? _trimTime;
  double? _totalTime;
  double? _price;

  @override
  void dispose() { _areaController.dispose(); _rateController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 10000;
    final hourlyRate = double.tryParse(_rateController.text) ?? 45;

    // Mower coverage rates (sq ft per hour)
    double sqftPerHour;
    switch (_mowerType) {
      case 'push': sqftPerHour = 8000; break;
      case 'self': sqftPerHour = 12000; break;
      case 'ride36': sqftPerHour = 25000; break;
      case 'ride52': sqftPerHour = 40000; break;
      case 'ride60': sqftPerHour = 55000; break;
      default: sqftPerHour = 8000;
    }

    // Terrain adjustment
    double terrainFactor;
    switch (_terrain) {
      case 'flat': terrainFactor = 1.0; break;
      case 'moderate': terrainFactor = 1.25; break;
      case 'steep': terrainFactor = 1.5; break;
      default: terrainFactor = 1.0;
    }

    final adjustedRate = sqftPerHour / terrainFactor;
    final mowingHours = area / adjustedRate;

    // Trimming: ~15% of mowing time
    final trimmingHours = mowingHours * 0.15;

    final totalHours = mowingHours + trimmingHours;
    final price = totalHours * hourlyRate;

    setState(() {
      _mowingTime = mowingHours * 60; // Convert to minutes
      _trimTime = trimmingHours * 60;
      _totalTime = totalHours * 60;
      _price = price;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '10000'; _rateController.text = '45'; setState(() { _mowerType = 'push'; _terrain = 'flat'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Mowing Time', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MOWER TYPE', ['push', 'self', 'ride36', 'ride52', 'ride60'], _mowerType, {'push': 'Push', 'self': 'Self-Prop', 'ride36': '36" ZT', 'ride52': '52" ZT', 'ride60': '60" ZT'}, (v) { setState(() => _mowerType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector2(colors, 'TERRAIN', ['flat', 'moderate', 'steep'], _terrain, {'flat': 'Flat', 'moderate': 'Moderate', 'steep': 'Steep'}, (v) { setState(() => _terrain = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Lawn Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Hourly Rate', unit: '\$/hr', controller: _rateController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_totalTime != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL TIME', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalTime!.toStringAsFixed(0)} min', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Mowing', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_mowingTime!.toStringAsFixed(0)} min', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Trimming', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_trimTime!.toStringAsFixed(0)} min', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Suggested price', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_price!.toStringAsFixed(0)}', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildMowerGuide(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildSelector2(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
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

  Widget _buildMowerGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COVERAGE RATES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '21" push', '~8,000 sq ft/hr'),
        _buildTableRow(colors, '21" self-prop', '~12,000 sq ft/hr'),
        _buildTableRow(colors, '36" zero-turn', '~25,000 sq ft/hr'),
        _buildTableRow(colors, '52" zero-turn', '~40,000 sq ft/hr'),
        _buildTableRow(colors, '60" zero-turn', '~55,000 sq ft/hr'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
