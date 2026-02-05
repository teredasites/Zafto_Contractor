import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Walk-In Tub/Shower Calculator - Accessible bath conversion rough-in
class WalkinTubScreen extends ConsumerStatefulWidget {
  const WalkinTubScreen({super.key});
  @override
  ConsumerState<WalkinTubScreen> createState() => _WalkinTubScreenState();
}

class _WalkinTubScreenState extends ConsumerState<WalkinTubScreen> {
  final _openingWidthController = TextEditingController(text: '60');
  final _openingDepthController = TextEditingController(text: '32');

  String _conversionType = 'walkin_tub';
  String _currentFixture = 'tub';

  String? _unitSize;
  String? _roughIn;
  String? _electrical;
  String? _plumbing;
  String? _structural;

  @override
  void dispose() { _openingWidthController.dispose(); _openingDepthController.dispose(); super.dispose(); }

  void _calculate() {
    final openingWidth = double.tryParse(_openingWidthController.text) ?? 60;
    final openingDepth = double.tryParse(_openingDepthController.text) ?? 32;

    String unitSize;
    String roughIn;
    String electrical;
    String plumbing;
    String structural;

    switch (_conversionType) {
      case 'walkin_tub':
        // Walk-in tub dimensions
        if (openingWidth >= 60 && openingDepth >= 30) {
          unitSize = '60" x 30" soaker or 52" x 28" compact';
        } else if (openingWidth >= 52) {
          unitSize = '52" x 28" compact walk-in';
        } else {
          unitSize = 'Opening too small - minimum 52" x 28"';
        }
        roughIn = 'Drain at existing location or relocate. Supply lines at tub end.';
        electrical = '15A dedicated circuit for heated seat, jets, or inline heater. GFCI required.';
        plumbing = 'Fast drain pump recommended (7 GPM). 3/4" supply for fill speed.';
        structural = 'Verify floor can support 600+ lbs filled. May need sistering joists.';
        break;
      case 'walkin_shower':
        // Walk-in shower (curbless)
        unitSize = openingWidth >= 36 ? '${openingWidth.toStringAsFixed(0)}" x ${openingDepth.toStringAsFixed(0)}" roll-in' : 'Min 36" x 36" for wheelchair access';
        roughIn = 'Linear drain at entry or center. 1/4" per ft slope to drain.';
        electrical = 'GFCI lighting. Optional heated floor circuit.';
        plumbing = 'Handheld + fixed shower head. Pressure balance or thermostatic valve.';
        structural = 'Subfloor must slope to drain. Waterproof membrane required.';
        break;
      case 'tub_to_shower':
        // Standard tub-to-shower conversion
        unitSize = '60" x 32" shower base fits standard tub alcove';
        roughIn = 'Valve at 48" height. Relocate drain if needed.';
        electrical = 'GFCI for vent fan and lighting.';
        plumbing = 'Standard 1/2" supply. 2" drain.';
        structural = 'Minimal - existing floor typically adequate.';
        break;
      default:
        unitSize = 'Select conversion type';
        roughIn = '';
        electrical = '';
        plumbing = '';
        structural = '';
    }

    setState(() {
      _unitSize = unitSize;
      _roughIn = roughIn;
      _electrical = electrical;
      _plumbing = plumbing;
      _structural = structural;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _openingWidthController.text = '60'; _openingDepthController.text = '32'; setState(() { _conversionType = 'walkin_tub'; _currentFixture = 'tub'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Walk-In Tub/Shower', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'CONVERSION TYPE', ['walkin_tub', 'walkin_shower', 'tub_to_shower'], _conversionType, {'walkin_tub': 'Walk-In Tub', 'walkin_shower': 'Roll-In Shower', 'tub_to_shower': 'Tub to Shower'}, (v) { setState(() => _conversionType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'CURRENT FIXTURE', ['tub', 'shower', 'combo'], _currentFixture, {'tub': 'Tub Only', 'shower': 'Shower Only', 'combo': 'Tub/Shower'}, (v) { setState(() => _currentFixture = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Opening Width', unit: 'inches', controller: _openingWidthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Opening Depth', unit: 'inches', controller: _openingDepthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_unitSize != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('UNIT SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(_unitSize!, style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                _buildRequirementRow(colors, 'Rough-In', _roughIn!),
                const SizedBox(height: 12),
                _buildRequirementRow(colors, 'Electrical', _electrical!),
                const SizedBox(height: 12),
                _buildRequirementRow(colors, 'Plumbing', _plumbing!),
                const SizedBox(height: 12),
                _buildRequirementRow(colors, 'Structural', _structural!),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSizeTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildRequirementRow(ZaftoColors colors, String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
    ]);
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

  Widget _buildSizeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Walk-in tub', '52-60" x 28-32"'),
        _buildTableRow(colors, 'Roll-in shower', '36" x 36" min'),
        _buildTableRow(colors, 'ADA shower', '60" x 30" min'),
        _buildTableRow(colors, 'Seat height', '17-19"'),
        _buildTableRow(colors, 'Door threshold', '< 1/2"'),
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
