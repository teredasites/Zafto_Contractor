import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Thermostat Temperature Selection Calculator
class ThermostatTempScreen extends ConsumerStatefulWidget {
  const ThermostatTempScreen({super.key});
  @override
  ConsumerState<ThermostatTempScreen> createState() => _ThermostatTempScreenState();
}

class _ThermostatTempScreenState extends ConsumerState<ThermostatTempScreen> {
  String _engineType = 'stock';
  String _fuelType = 'gasoline';
  String _climate = 'moderate';
  bool _hasAC = true;

  int? _recommendedTemp;
  String? _thermostatType;
  String? _notes;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    int temp;
    String type;
    String notes;

    // Base temperature selection logic
    if (_engineType == 'stock') {
      // Stock engines: Follow OEM spec
      if (_fuelType == 'diesel') {
        temp = 195;
        type = 'OEM Replacement';
        notes = 'Diesels need higher temps for emissions and fuel atomization';
      } else {
        temp = 195;
        type = 'OEM Replacement';
        notes = 'Stock engines designed for 195°F operating temp';
      }
    } else if (_engineType == 'mild') {
      // Mild performance
      temp = 180;
      type = 'Performance 180°F';
      notes = 'Lower temp for increased power, still emissions compliant';
    } else if (_engineType == 'race') {
      // Race/high performance
      temp = 160;
      type = 'High-Flow 160°F';
      notes = 'Maximum cooling for high-output engines, not street legal';
    } else {
      // Forced induction
      temp = 180;
      type = 'Performance 180°F with High-Flow';
      notes = 'Turbo/supercharged engines benefit from cooler intake temps';
    }

    // Climate adjustments
    if (_climate == 'hot' && temp > 160) {
      temp -= 5;
      notes += '. Hot climate: consider 5°F lower';
    } else if (_climate == 'cold') {
      if (temp < 195) {
        notes += '. Cold climate: ensure proper warm-up before driving hard';
      }
    }

    // AC consideration
    if (_hasAC && temp < 180) {
      notes += '. A/C equipped: may need higher-flow water pump';
    }

    setState(() {
      _recommendedTemp = temp;
      _thermostatType = type;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    setState(() {
      _engineType = 'stock';
      _fuelType = 'gasoline';
      _climate = 'moderate';
      _hasAC = true;
    });
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Thermostat Temp', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildSelector(colors, 'Engine Type', _engineType, {
              'stock': 'Stock/Daily',
              'mild': 'Mild Performance',
              'forced': 'Turbo/Supercharged',
              'race': 'Race Only',
            }, (v) { _engineType = v; _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, 'Fuel Type', _fuelType, {
              'gasoline': 'Gasoline',
              'diesel': 'Diesel',
              'e85': 'E85/Flex Fuel',
            }, (v) { _fuelType = v; _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, 'Climate', _climate, {
              'cold': 'Cold (<40°F avg)',
              'moderate': 'Moderate',
              'hot': 'Hot (>90°F avg)',
            }, (v) { _climate = v; _calculate(); }),
            const SizedBox(height: 12),
            _buildToggle(colors, 'Has A/C System', _hasAC, (v) { _hasAC = v; _calculate(); }),
            const SizedBox(height: 32),
            if (_recommendedTemp != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Thermostat opens at rated temperature', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Lower temp = more cooling but less efficiency', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String label, String value, Map<String, String> options, Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: options.entries.map((e) {
          final isSelected = e.key == value;
          return GestureDetector(
            onTap: () => setState(() => onChanged(e.key)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: Text(e.value, style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textSecondary, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
            ),
          );
        }).toList()),
      ]),
    );
  }

  Widget _buildToggle(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Switch(
          value: value,
          onChanged: (v) => setState(() => onChanged(v)),
          activeColor: colors.accentPrimary,
        ),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Recommended Temp', '${_recommendedTemp!}°F', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Thermostat Type', _thermostatType!),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(LucideIcons.info, color: colors.accentPrimary, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(_notes!, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
          ]),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
