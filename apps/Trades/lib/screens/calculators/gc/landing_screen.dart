import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Landing Calculator - Stair landing dimensions and materials
class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});
  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  final _widthController = TextEditingController(text: '36');
  final _depthController = TextEditingController(text: '36');
  final _heightController = TextEditingController(text: '54');

  String _landingType = 'platform';
  String _framing = 'wood';

  double? _deckingArea;
  int? _joists;
  int? _posts;
  double? _guardrailLF;

  @override
  void dispose() { _widthController.dispose(); _depthController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final widthInches = double.tryParse(_widthController.text);
    final depthInches = double.tryParse(_depthController.text);
    final heightInches = double.tryParse(_heightController.text);

    if (widthInches == null || depthInches == null || heightInches == null) {
      setState(() { _deckingArea = null; _joists = null; _posts = null; _guardrailLF = null; });
      return;
    }

    final widthFeet = widthInches / 12;
    final depthFeet = depthInches / 12;

    // Decking area
    final deckingArea = widthFeet * depthFeet;

    // Joists at 16" OC
    final joists = ((widthInches / 16).ceil() + 1);

    // Posts at corners (4 for platform, varies for L/U)
    int posts;
    switch (_landingType) {
      case 'platform': posts = 4; break;
      case 'l_shaped': posts = 6; break;
      case 'u_shaped': posts = 8; break;
      default: posts = 4;
    }

    // Guardrail if height > 30"
    double guardrailLF = 0;
    if (heightInches > 30) {
      // Open sides need guardrail (assume 3 sides for platform)
      final openSides = _landingType == 'platform' ? 3 : 4;
      final perimeter = (widthFeet * 2) + (depthFeet * 2);
      guardrailLF = perimeter * openSides / 4; // Rough estimate
    }

    setState(() { _deckingArea = deckingArea; _joists = joists; _posts = posts; _guardrailLF = guardrailLF; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _widthController.text = '36'; _depthController.text = '36'; _heightController.text = '54'; setState(() { _landingType = 'platform'; _framing = 'wood'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Landing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'LANDING TYPE', ['platform', 'l_shaped', 'u_shaped'], _landingType, (v) { setState(() => _landingType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'FRAMING', ['wood', 'steel', 'aluminum'], _framing, (v) { setState(() => _framing = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Depth', unit: 'inches', controller: _depthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Height Above Grade', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_deckingArea != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('DECKING AREA', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_deckingArea!.toStringAsFixed(1)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Joists (16" OC)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_joists', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Support Posts', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_posts', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_guardrailLF! > 0) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Guardrail', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_guardrailLF!.toStringAsFixed(1)} LF', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getLandingNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getLandingNote() {
    switch (_landingType) {
      case 'platform': return 'Code: Min 36" x 36" landing. Must not slope more than 1/4" per foot.';
      case 'l_shaped': return 'L-shaped: 90° turn. Min width equal to stair width on both legs.';
      case 'u_shaped': return 'U-shaped: 180° turn. Requires larger footprint. Check headroom clearance.';
      default: return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    final labels = {'platform': 'Platform', 'l_shaped': 'L-Shape', 'u_shaped': 'U-Shape', 'wood': 'Wood', 'steel': 'Steel', 'aluminum': 'Aluminum'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o] ?? o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
