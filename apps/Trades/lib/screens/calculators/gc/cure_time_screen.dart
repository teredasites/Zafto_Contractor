import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Cure Time Calculator - Concrete curing schedule
class CureTimeScreen extends ConsumerStatefulWidget {
  const CureTimeScreen({super.key});
  @override
  ConsumerState<CureTimeScreen> createState() => _CureTimeScreenState();
}

class _CureTimeScreenState extends ConsumerState<CureTimeScreen> {
  final _tempController = TextEditingController(text: '70');

  String _mixStrength = '3000';
  String _application = 'slab';

  int? _initialSet;
  int? _finalSet;
  int? _formRemoval;
  int? _lightTraffic;
  int? _fullStrength;

  @override
  void dispose() { _tempController.dispose(); super.dispose(); }

  void _calculate() {
    final temp = double.tryParse(_tempController.text);

    if (temp == null) {
      setState(() { _initialSet = null; _finalSet = null; _formRemoval = null; _lightTraffic = null; _fullStrength = null; });
      return;
    }

    // Temperature adjustment factor (baseline 70°F)
    double tempFactor;
    if (temp < 50) {
      tempFactor = 2.0; // Cold weather doubles cure time
    } else if (temp < 60) {
      tempFactor = 1.5;
    } else if (temp <= 80) {
      tempFactor = 1.0;
    } else {
      tempFactor = 0.8; // Hot weather accelerates but requires more water control
    }

    // Base times in hours
    int baseInitialSet = 2; // hours
    int baseFinalSet = 8; // hours
    int baseFormRemoval, baseLightTraffic;

    // Adjust for application type
    switch (_application) {
      case 'slab':
        baseFormRemoval = 24;
        baseLightTraffic = 48;
        break;
      case 'wall':
        baseFormRemoval = 48;
        baseLightTraffic = 72;
        break;
      case 'column':
        baseFormRemoval = 72;
        baseLightTraffic = 96;
        break;
      case 'beam':
        baseFormRemoval = 168; // 7 days
        baseLightTraffic = 336; // 14 days
        break;
      default:
        baseFormRemoval = 24;
        baseLightTraffic = 48;
    }

    // Higher strength mixes take longer
    double strengthFactor;
    switch (_mixStrength) {
      case '2500': strengthFactor = 0.9; break;
      case '3000': strengthFactor = 1.0; break;
      case '3500': strengthFactor = 1.1; break;
      case '4000': strengthFactor = 1.2; break;
      default: strengthFactor = 1.0;
    }

    final initialSet = (baseInitialSet * tempFactor).ceil();
    final finalSet = (baseFinalSet * tempFactor).ceil();
    final formRemoval = (baseFormRemoval * tempFactor * strengthFactor).ceil();
    final lightTraffic = (baseLightTraffic * tempFactor * strengthFactor).ceil();
    final fullStrength = (28 * 24 * tempFactor).ceil(); // 28 days baseline

    setState(() {
      _initialSet = initialSet;
      _finalSet = finalSet;
      _formRemoval = formRemoval;
      _lightTraffic = lightTraffic;
      _fullStrength = fullStrength;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _tempController.text = '70'; setState(() { _mixStrength = '3000'; _application = 'slab'; }); _calculate(); }

  String _formatTime(int hours) {
    if (hours < 24) return '$hours hrs';
    final days = hours ~/ 24;
    final remainingHours = hours % 24;
    if (remainingHours == 0) return '$days days';
    return '$days days $remainingHours hrs';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Cure Time', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MIX STRENGTH', ['2500', '3000', '3500', '4000'], _mixStrength, (v) { setState(() => _mixStrength = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'APPLICATION', ['slab', 'wall', 'column', 'beam'], _application, (v) { setState(() => _application = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Ambient Temperature', unit: '°F', controller: _tempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_initialSet != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('FULL STRENGTH', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_formatTime(_fullStrength!), style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Initial Set', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_formatTime(_initialSet!), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Final Set', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_formatTime(_finalSet!), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Form Removal', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_formatTime(_formRemoval!), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Light Traffic', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_formatTime(_lightTraffic!), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Keep concrete moist during curing. Below 50°F use insulated blankets. Above 90°F use curing compound or wet burlap.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        final label = o[0].toUpperCase() + o.substring(1);
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
