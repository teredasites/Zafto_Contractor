import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Demand Factor Calculator - Design System v2.6
/// NEC 220 demand factor calculations by load type
class DemandFactorScreen extends ConsumerStatefulWidget {
  const DemandFactorScreen({super.key});
  @override
  ConsumerState<DemandFactorScreen> createState() => _DemandFactorScreenState();
}

class _DemandFactorScreenState extends ConsumerState<DemandFactorScreen> {
  String _loadType = 'general_lighting';
  final _connectedLoadController = TextEditingController(text: '15000');
  int _dwellingUnits = 1;

  double? _demandFactor;
  double? _demandLoad;
  String? _necReference;
  String? _factorExplanation;

  final _loadTypes = {
    'general_lighting': 'General Lighting',
    'receptacles': 'Receptacle Outlets',
    'dryers': 'Electric Dryers',
    'ranges': 'Electric Ranges',
    'heating': 'Electric Heating',
    'ac': 'A/C Equipment',
    'motors': 'Motors',
    'kitchen_equip': 'Commercial Kitchen',
  };

  @override
  void initState() { super.initState(); _calculate(); }

  @override
  void dispose() { _connectedLoadController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Demand Factor', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LOAD TYPE'),
              const SizedBox(height: 12),
              _buildLoadTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CONNECTED LOAD'),
              const SizedBox(height: 12),
              _buildInputRow(colors, 'Connected Load (VA)', _connectedLoadController, 'VA'),
              if (_loadType == 'dryers' || _loadType == 'ranges' || _loadType == 'general_lighting') ...[
                const SizedBox(height: 12),
                _buildSliderRow(colors, label: 'Dwelling Units', value: _dwellingUnits, min: 1, max: 50, unit: '', onChanged: (v) { setState(() => _dwellingUnits = v.round()); _calculate(); }),
              ],
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'DEMAND CALCULATION'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(LucideIcons.info, color: colors.accentPrimary, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text('NEC Article 220 demand factors reduce calculated load', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildLoadTypeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _loadTypes.entries.map((e) => GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _loadType = e.key); _calculate(); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _loadType == e.key ? colors.accentPrimary : colors.bgElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _loadType == e.key ? colors.accentPrimary : colors.borderSubtle),
          ),
          child: Text(e.value, style: TextStyle(
            color: _loadType == e.key ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          )),
        ),
      )).toList(),
    );
  }

  Widget _buildInputRow(ZaftoColors colors, String label, TextEditingController controller, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14))),
        SizedBox(
          width: 120,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
            decoration: InputDecoration(isDense: true, border: InputBorder.none, suffixText: unit, suffixStyle: TextStyle(color: colors.textTertiary)),
            onChanged: (_) => _calculate(),
          ),
        ),
      ]),
    );
  }

  Widget _buildSliderRow(ZaftoColors colors, {required String label, required int value, required int min, required int max, required String unit, required ValueChanged<double> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('$value$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
        ]),
        SliderTheme(
          data: SliderThemeData(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.borderSubtle, thumbColor: colors.accentPrimary, overlayColor: colors.accentPrimary.withValues(alpha: 0.2)),
          child: Slider(value: value.toDouble(), min: min.toDouble(), max: max.toDouble(), divisions: max - min, onChanged: onChanged),
        ),
      ]),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        Text('${_demandLoad?.toStringAsFixed(0) ?? '0'}', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 48)),
        Text('VA demand load', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('${((_demandFactor ?? 1) * 100).toStringAsFixed(0)}% demand factor', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Connected load', '${_connectedLoadController.text} VA'),
        _buildCalcRow(colors, 'Demand factor', '${((_demandFactor ?? 1) * 100).toStringAsFixed(0)}%'),
        _buildCalcRow(colors, 'Demand load', '${_demandLoad?.toStringAsFixed(0) ?? '0'} VA', highlight: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(LucideIcons.book, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 8),
              Text(_necReference ?? 'NEC 220', style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 4),
            Text(_factorExplanation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildCalcRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: highlight ? colors.textPrimary : colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontWeight: highlight ? FontWeight.w700 : FontWeight.w600, fontSize: 14)),
      ]),
    );
  }

  void _calculate() {
    final connected = double.tryParse(_connectedLoadController.text) ?? 0;
    double factor = 1.0;
    String necRef = '';
    String explanation = '';

    switch (_loadType) {
      case 'general_lighting':
        // NEC 220.42 - Lighting demand factors
        if (connected <= 3000) {
          factor = 1.0;
        } else if (connected <= 120000) {
          // First 3000 @ 100%, remainder @ 35%
          factor = (3000 + (connected - 3000) * 0.35) / connected;
        } else {
          factor = (3000 + 117000 * 0.35 + (connected - 120000) * 0.25) / connected;
        }
        necRef = 'NEC 220.42';
        explanation = 'First 3000VA @ 100%, 3001-120000VA @ 35%, over 120000VA @ 25%';
        break;

      case 'receptacles':
        // NEC 220.44 - Receptacle loads
        if (connected <= 10000) {
          factor = 1.0;
        } else {
          factor = (10000 + (connected - 10000) * 0.5) / connected;
        }
        necRef = 'NEC 220.44';
        explanation = 'First 10kVA @ 100%, remainder @ 50%';
        break;

      case 'dryers':
        // NEC 220.54 - Electric dryers
        if (_dwellingUnits <= 4) {
          factor = 1.0;
        } else if (_dwellingUnits <= 10) {
          factor = 0.85 - (_dwellingUnits - 5) * 0.02;
        } else {
          factor = 0.65;
        }
        necRef = 'NEC 220.54';
        explanation = '1-4 units @ 100%, 5+ units reduced per Table 220.54';
        break;

      case 'ranges':
        // NEC 220.55 - Electric ranges (simplified)
        if (_dwellingUnits == 1) {
          factor = 0.80; // 8kW for one range
        } else if (_dwellingUnits <= 5) {
          factor = 0.66;
        } else {
          factor = 0.50;
        }
        necRef = 'NEC 220.55';
        explanation = 'Column C values from Table 220.55';
        break;

      case 'heating':
        // NEC 220.51 - Fixed electric heating
        factor = 1.0; // 100% of total connected load
        necRef = 'NEC 220.51';
        explanation = 'Heating loads calculated at 100% demand';
        break;

      case 'ac':
        // NEC 220.60 - Noncoincident loads
        factor = 1.0; // Largest of heating/cooling
        necRef = 'NEC 220.60';
        explanation = 'Use largest of heating or cooling, not both';
        break;

      case 'motors':
        // NEC 430.24 - Several motors
        factor = 1.25; // 125% of largest + 100% of others
        necRef = 'NEC 430.24';
        explanation = '125% of largest motor + 100% of all others';
        break;

      case 'kitchen_equip':
        // NEC 220.56 - Kitchen equipment
        if (_dwellingUnits <= 2) {
          factor = 1.0;
        } else if (_dwellingUnits == 3) {
          factor = 0.90;
        } else if (_dwellingUnits == 4) {
          factor = 0.80;
        } else if (_dwellingUnits == 5) {
          factor = 0.70;
        } else {
          factor = 0.65;
        }
        necRef = 'NEC 220.56';
        explanation = 'Commercial kitchen equipment demand factors';
        break;
    }

    final demand = connected * factor;

    setState(() {
      _demandFactor = factor;
      _demandLoad = demand;
      _necReference = necRef;
      _factorExplanation = explanation;
    });
  }

  void _reset() {
    _connectedLoadController.text = '15000';
    setState(() {
      _loadType = 'general_lighting';
      _dwellingUnits = 1;
    });
    _calculate();
  }
}
