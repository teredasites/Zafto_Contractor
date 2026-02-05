import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Stair Lift Calculator - Stair lift rail length and electrical requirements
class StairLiftScreen extends ConsumerStatefulWidget {
  const StairLiftScreen({super.key});
  @override
  ConsumerState<StairLiftScreen> createState() => _StairLiftScreenState();
}

class _StairLiftScreenState extends ConsumerState<StairLiftScreen> {
  final _floorToFloorController = TextEditingController(text: '108');
  final _stairWidthController = TextEditingController(text: '36');

  String _stairType = 'straight';
  String _powerType = 'battery';

  double? _railLength;
  String? _clearance;
  String? _electrical;
  String? _considerations;

  @override
  void dispose() { _floorToFloorController.dispose(); _stairWidthController.dispose(); super.dispose(); }

  void _calculate() {
    final floorToFloor = double.tryParse(_floorToFloorController.text) ?? 108; // inches
    final stairWidth = double.tryParse(_stairWidthController.text) ?? 36; // inches

    // Estimate rail length based on floor-to-floor height
    // Typical stair angle is 30-35 degrees, use 35 as conservative
    // Rail length = height / sin(35°) ≈ height × 1.74
    double railLength;
    switch (_stairType) {
      case 'straight':
        railLength = (floorToFloor * 1.74) / 12; // Convert to feet
        break;
      case 'curved':
        railLength = (floorToFloor * 2.0) / 12; // Curved adds ~15%
        break;
      case 'landing':
        railLength = (floorToFloor * 2.2) / 12; // Landing adds more
        break;
      default:
        railLength = (floorToFloor * 1.74) / 12;
    }

    // Clearance check
    String clearance;
    if (stairWidth >= 36) {
      clearance = 'Good: ${(stairWidth - 16).toStringAsFixed(0)}" clear when folded (16" seat width)';
    } else if (stairWidth >= 32) {
      clearance = 'Tight: ${(stairWidth - 16).toStringAsFixed(0)}" clear when folded. May not meet code.';
    } else {
      clearance = 'Too narrow: Minimum 32" stair width recommended.';
    }

    // Electrical requirements
    String electrical;
    switch (_powerType) {
      case 'battery':
        electrical = 'Standard outlet at top or bottom for charging. No dedicated circuit needed.';
        break;
      case 'direct':
        electrical = 'Dedicated 15A circuit recommended. Outlet near top landing.';
        break;
      default:
        electrical = 'Standard outlet for charging.';
    }

    // Type-specific considerations
    String considerations;
    switch (_stairType) {
      case 'straight':
        considerations = 'Most affordable. Rail can extend past landing if space available. 24-48 hr install.';
        break;
      case 'curved':
        considerations = 'Custom rail required. Longer lead time (2-4 weeks). Significantly higher cost.';
        break;
      case 'landing':
        considerations = 'Two straight units or one curved. Platform lift may be alternative.';
        break;
      default:
        considerations = 'Consult manufacturer for specific requirements.';
    }

    setState(() {
      _railLength = railLength;
      _clearance = clearance;
      _electrical = electrical;
      _considerations = considerations;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _floorToFloorController.text = '108'; _stairWidthController.text = '36'; setState(() { _stairType = 'straight'; _powerType = 'battery'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Stair Lift', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'STAIR TYPE', ['straight', 'curved', 'landing'], _stairType, {'straight': 'Straight', 'curved': 'Curved', 'landing': 'With Landing'}, (v) { setState(() => _stairType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'POWER TYPE', ['battery', 'direct'], _powerType, {'battery': 'Battery Backup', 'direct': 'Direct Power'}, (v) { setState(() => _powerType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Floor to Floor', unit: 'inches', controller: _floorToFloorController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Stair Width', unit: 'inches', controller: _stairWidthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_railLength != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RAIL LENGTH', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~${_railLength!.toStringAsFixed(1)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_clearance!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Electrical:', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)),
                    Text(_electrical!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                  ]),
                ),
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_considerations!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSpecsTable(colors),
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

  Widget _buildSpecsTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TYPICAL SPECIFICATIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Weight capacity', '300-400 lbs'),
        _buildTableRow(colors, 'Seat width', '16-20"'),
        _buildTableRow(colors, 'Folded width', '11-14"'),
        _buildTableRow(colors, 'Speed', '20-25 ft/min'),
        _buildTableRow(colors, 'Battery backup', '10-20 trips'),
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
