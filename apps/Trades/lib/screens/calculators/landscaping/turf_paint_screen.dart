import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Turf Paint Calculator - Lawn colorant application
class TurfPaintScreen extends ConsumerStatefulWidget {
  const TurfPaintScreen({super.key});
  @override
  ConsumerState<TurfPaintScreen> createState() => _TurfPaintScreenState();
}

class _TurfPaintScreenState extends ConsumerState<TurfPaintScreen> {
  final _areaController = TextEditingController(text: '5000');

  String _application = 'touch_up';

  double? _concentrateGal;
  double? _waterGal;
  double? _durationWeeks;

  @override
  void dispose() { _areaController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 5000;

    // Turf paint rates vary by application
    double sqFtPerGalConcentrate;
    double waterPerGalConcentrate;
    double duration;

    switch (_application) {
      case 'touch_up':
        sqFtPerGalConcentrate = 10000; // Light coat
        waterPerGalConcentrate = 10;
        duration = 4;
        break;
      case 'full':
        sqFtPerGalConcentrate = 5000; // Full coverage
        waterPerGalConcentrate = 5;
        duration = 8;
        break;
      case 'heavy':
        sqFtPerGalConcentrate = 3000; // Heavy coverage
        waterPerGalConcentrate = 3;
        duration = 12;
        break;
      default:
        sqFtPerGalConcentrate = 5000;
        waterPerGalConcentrate = 5;
        duration = 8;
    }

    final concentrate = area / sqFtPerGalConcentrate;
    final water = concentrate * waterPerGalConcentrate;

    setState(() {
      _concentrateGal = concentrate;
      _waterGal = water;
      _durationWeeks = duration;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '5000'; setState(() { _application = 'touch_up'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Turf Paint', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'APPLICATION', ['touch_up', 'full', 'heavy'], _application, {'touch_up': 'Touch Up', 'full': 'Full Coverage', 'heavy': 'Heavy'}, (v) { setState(() => _application = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Lawn Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_concentrateGal != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('CONCENTRATE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_concentrateGal!.toStringAsFixed(2)} gal', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Mix with water', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_waterGal!.toStringAsFixed(1)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Expected duration', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_durationWeeks!.toStringAsFixed(0)} weeks', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildPaintGuide(colors),
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

  Widget _buildPaintGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('APPLICATION TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Best time', 'Morning, dry grass'),
        _buildTableRow(colors, 'Dry time', '2-4 hours'),
        _buildTableRow(colors, 'Rain-safe', '24 hours after'),
        _buildTableRow(colors, 'Equipment', 'Pump sprayer or hose'),
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
