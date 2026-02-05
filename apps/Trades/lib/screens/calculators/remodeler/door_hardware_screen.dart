import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Door Hardware Calculator - Door hardware estimation
class DoorHardwareScreen extends ConsumerStatefulWidget {
  const DoorHardwareScreen({super.key});
  @override
  ConsumerState<DoorHardwareScreen> createState() => _DoorHardwareScreenState();
}

class _DoorHardwareScreenState extends ConsumerState<DoorHardwareScreen> {
  final _interiorController = TextEditingController(text: '8');
  final _exteriorController = TextEditingController(text: '2');
  final _closetController = TextEditingController(text: '4');

  String _style = 'lever';

  int? _passageKnobs;
  int? _privacyKnobs;
  int? _entryLocks;
  int? _hingeSets;
  int? _deadbolts;

  @override
  void dispose() { _interiorController.dispose(); _exteriorController.dispose(); _closetController.dispose(); super.dispose(); }

  void _calculate() {
    final interior = int.tryParse(_interiorController.text) ?? 0;
    final exterior = int.tryParse(_exteriorController.text) ?? 0;
    final closet = int.tryParse(_closetController.text) ?? 0;

    // Passage: hallways, closets (no lock)
    final passageKnobs = closet;

    // Privacy: bedrooms, bathrooms
    final privacyKnobs = interior;

    // Entry: exterior doors
    final entryLocks = exterior;

    // Deadbolts: one per exterior door
    final deadbolts = exterior;

    // Hinges: 3 per door standard
    final hingeSets = (interior + exterior + closet) * 3;

    setState(() { _passageKnobs = passageKnobs; _privacyKnobs = privacyKnobs; _entryLocks = entryLocks; _hingeSets = hingeSets ~/ 3; _deadbolts = deadbolts; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _interiorController.text = '8'; _exteriorController.text = '2'; _closetController.text = '4'; setState(() => _style = 'lever'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Door Hardware', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Interior Doors (bed/bath)', unit: 'qty', controller: _interiorController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Exterior Doors', unit: 'qty', controller: _exteriorController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Closet Doors', unit: 'qty', controller: _closetController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_passageKnobs != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Text('HARDWARE LIST', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Passage (no lock)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_passageKnobs', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Privacy (push lock)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_privacyKnobs', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Entry (keyed)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_entryLocks', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Deadbolts', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_deadbolts', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Hinge Sets (3 each)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_hingeSets doors', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Match all hardware finish. Standard bore: 2-1/8\" face, 1\" edge. Check backset.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildBacksetTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['knob', 'lever', 'modern'];
    final labels = {'knob': 'Knob', 'lever': 'Lever', 'modern': 'Modern'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('STYLE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _style == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _style = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildBacksetTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BACKSET REFERENCE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Standard backset', '2-3/8\"'),
        _buildTableRow(colors, 'Extended backset', '2-3/4\"'),
        _buildTableRow(colors, 'Face bore', '2-1/8\"'),
        _buildTableRow(colors, 'Edge bore', '1\"'),
        _buildTableRow(colors, 'Deadbolt bore', '2-1/8\" or 1-1/2\"'),
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
