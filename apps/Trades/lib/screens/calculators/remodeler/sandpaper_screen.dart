import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Sandpaper Calculator - Abrasive estimation
class SandpaperScreen extends ConsumerStatefulWidget {
  const SandpaperScreen({super.key});
  @override
  ConsumerState<SandpaperScreen> createState() => _SandpaperScreenState();
}

class _SandpaperScreenState extends ConsumerState<SandpaperScreen> {
  final _areaSqftController = TextEditingController(text: '100');

  String _task = 'wood';
  String _method = 'orbital';

  int? _sheets;
  int? _discs;
  String? _grits;

  @override
  void dispose() { _areaSqftController.dispose(); super.dispose(); }

  void _calculate() {
    final areaSqft = double.tryParse(_areaSqftController.text) ?? 0;

    // Coverage varies by task and method
    double sqftPerSheet;
    String grits;

    switch (_task) {
      case 'wood':
        sqftPerSheet = 20;
        grits = '80, 120, 180, 220';
        break;
      case 'drywall':
        sqftPerSheet = 30; // Less aggressive
        grits = '120, 150';
        break;
      case 'paint':
        sqftPerSheet = 15; // Paint clogs faster
        grits = '120, 150, 220';
        break;
      case 'metal':
        sqftPerSheet = 10; // Wears fast
        grits = '80, 120, 220';
        break;
      default:
        sqftPerSheet = 20;
        grits = '120, 180';
    }

    // Method adjustment
    switch (_method) {
      case 'hand':
        sqftPerSheet *= 0.7;
        break;
      case 'orbital':
        // Standard coverage
        break;
      case 'belt':
        sqftPerSheet *= 1.5;
        break;
    }

    // Number of grits needed
    final gritsCount = grits.split(',').length;
    final sheetsPerGrit = (areaSqft / sqftPerSheet).ceil();
    final sheets = sheetsPerGrit * gritsCount;
    final discs = sheets;

    setState(() { _sheets = sheets; _discs = discs; _grits = grits; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaSqftController.text = '100'; setState(() { _task = 'wood'; _method = 'orbital'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Sandpaper', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'TASK', ['wood', 'drywall', 'paint', 'metal'], _task, {'wood': 'Bare Wood', 'drywall': 'Drywall', 'paint': 'Paint Prep', 'metal': 'Metal'}, (v) { setState(() => _task = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'METHOD', ['hand', 'orbital', 'belt'], _method, {'hand': 'Hand', 'orbital': 'Orbital', 'belt': 'Belt Sander'}, (v) { setState(() => _method = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Area to Sand', unit: 'sq ft', controller: _areaSqftController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_sheets != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL PIECES', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~$_sheets', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Sheets/Discs', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_sheets', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Recommended Grits', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Flexible(child: Text(_grits!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.right))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Progress through grits in order. Don\'t skip more than one grit. Sand with the grain.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildGritTable(colors),
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

  Widget _buildGritTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('GRIT GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '40-60', 'Heavy material removal'),
        _buildTableRow(colors, '80-100', 'Shaping, stripping'),
        _buildTableRow(colors, '120-150', 'General sanding'),
        _buildTableRow(colors, '180-220', 'Final before finish'),
        _buildTableRow(colors, '320+', 'Between coats'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
