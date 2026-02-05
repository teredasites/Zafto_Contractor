import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Grab Bar Calculator - Bathroom grab bar placement and sizing
class GrabBarScreen extends ConsumerStatefulWidget {
  const GrabBarScreen({super.key});
  @override
  ConsumerState<GrabBarScreen> createState() => _GrabBarScreenState();
}

class _GrabBarScreenState extends ConsumerState<GrabBarScreen> {
  final _bathroomsController = TextEditingController(text: '1');

  String _fixtureType = 'shower';
  String _mountType = 'blocking';

  int? _barsNeeded;
  String? _lengths;
  String? _placement;
  String? _mountNote;

  @override
  void dispose() { _bathroomsController.dispose(); super.dispose(); }

  void _calculate() {
    final bathrooms = int.tryParse(_bathroomsController.text) ?? 1;

    // Bars needed per fixture
    int barsPerFixture;
    String lengths;
    String placement;
    switch (_fixtureType) {
      case 'shower':
        barsPerFixture = 2; // Vertical entry + horizontal
        lengths = '24" vertical, 36" horizontal';
        placement = 'Vertical at entry 33-36" high. Horizontal on control wall 33-36" high.';
        break;
      case 'tub':
        barsPerFixture = 3; // Entry, inside wall, back wall
        lengths = '24" vertical, 2x 36" horizontal';
        placement = 'Vertical at entry. Horizontal on back wall and side wall at 33-36" height.';
        break;
      case 'toilet':
        barsPerFixture = 2; // Both sides or side + swing
        lengths = '2x 24" or 1x 42" swing-up';
        placement = 'Side-mounted 33-36" high, 12" from centerline. Or swing-up bar.';
        break;
      case 'all':
        barsPerFixture = 7; // Complete bathroom
        lengths = 'Various: 24", 36", 42"';
        placement = 'Shower (2), tub (3) or shower/tub combo (3), toilet (2)';
        break;
      default:
        barsPerFixture = 2;
        lengths = '24" and 36"';
        placement = 'Per ADA guidelines.';
    }

    // Mounting notes
    String mountNote;
    switch (_mountType) {
      case 'blocking':
        mountNote = 'Best: Install 2x6 or 3/4" plywood blocking behind drywall before finishing.';
        break;
      case 'studs':
        mountNote = 'Good: Locate studs and anchor bar ends into framing. May limit placement.';
        break;
      case 'anchors':
        mountNote = 'Okay: Use toggler bolts or WingIts rated for 250+ lbs. Check for tile backing.';
        break;
      default:
        mountNote = 'Blocking provides strongest, most flexible mounting.';
    }

    final barsNeeded = barsPerFixture * bathrooms;

    setState(() {
      _barsNeeded = barsNeeded;
      _lengths = lengths;
      _placement = placement;
      _mountNote = mountNote;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _bathroomsController.text = '1'; setState(() { _fixtureType = 'shower'; _mountType = 'blocking'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Grab Bar', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'FIXTURE', ['shower', 'tub', 'toilet', 'all'], _fixtureType, {'shower': 'Shower', 'tub': 'Tub', 'toilet': 'Toilet', 'all': 'Full Bath'}, (v) { setState(() => _fixtureType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'MOUNTING', ['blocking', 'studs', 'anchors'], _mountType, {'blocking': 'Blocking', 'studs': 'Studs', 'anchors': 'Anchors'}, (v) { setState(() => _mountType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Bathrooms', unit: 'qty', controller: _bathroomsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_barsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('GRAB BARS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_barsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Lengths:', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
                  const SizedBox(width: 8),
                  Flexible(child: Text(_lengths!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))),
                ]),
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_placement!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_mountNote!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildADATable(colors),
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

  Widget _buildADATable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ADA GUIDELINES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Mounting height', '33-36" AFF'),
        _buildTableRow(colors, 'Bar diameter', '1.25-2"'),
        _buildTableRow(colors, 'Wall clearance', '1.5"'),
        _buildTableRow(colors, 'Weight rating', '250 lbs min'),
        _buildTableRow(colors, 'Finish', 'Non-slip, textured'),
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
