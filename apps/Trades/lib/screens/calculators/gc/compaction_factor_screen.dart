import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Compaction Factor Calculator - Loose to compacted conversion
class CompactionFactorScreen extends ConsumerStatefulWidget {
  const CompactionFactorScreen({super.key});
  @override
  ConsumerState<CompactionFactorScreen> createState() => _CompactionFactorScreenState();
}

class _CompactionFactorScreenState extends ConsumerState<CompactionFactorScreen> {
  final _compactedVolumeController = TextEditingController(text: '100');

  String _materialType = 'gravel';

  double? _shrinkFactor;
  double? _looseVolumeNeeded;
  double? _extraVolume;

  @override
  void dispose() { _compactedVolumeController.dispose(); super.dispose(); }

  void _calculate() {
    final compactedVolume = double.tryParse(_compactedVolumeController.text);

    if (compactedVolume == null) {
      setState(() { _shrinkFactor = null; _looseVolumeNeeded = null; _extraVolume = null; });
      return;
    }

    // Shrinkage factors (loose to compacted)
    double shrinkFactor;
    switch (_materialType) {
      case 'sand': shrinkFactor = 1.08; break;
      case 'gravel': shrinkFactor = 1.12; break;
      case 'crushed': shrinkFactor = 1.15; break;
      case 'topsoil': shrinkFactor = 1.10; break;
      case 'clay': shrinkFactor = 1.25; break;
      case 'aggregate': shrinkFactor = 1.18; break;
      default: shrinkFactor = 1.15;
    }

    final looseVolumeNeeded = compactedVolume * shrinkFactor;
    final extraVolume = looseVolumeNeeded - compactedVolume;

    setState(() { _shrinkFactor = shrinkFactor; _looseVolumeNeeded = looseVolumeNeeded; _extraVolume = extraVolume; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _compactedVolumeController.text = '100'; setState(() => _materialType = 'gravel'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Compaction Factor', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MATERIAL TYPE', ['sand', 'gravel', 'crushed'], _materialType, (v) { setState(() => _materialType = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, '', ['topsoil', 'clay', 'aggregate'], _materialType, (v) { setState(() => _materialType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Compacted Volume Needed', unit: 'yd³', controller: _compactedVolumeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_looseVolumeNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('LOOSE VOLUME TO ORDER', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_looseVolumeNeeded!.toStringAsFixed(1)} yd³', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Shrink Factor', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${((_shrinkFactor! - 1) * 100).toStringAsFixed(0)}%', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Extra Volume Needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_extraVolume!.toStringAsFixed(1)} yd³', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getMaterialNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildCompactionTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildCompactionTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SHRINKAGE REFERENCE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Sand', '5-10%'),
        _buildTableRow(colors, 'Gravel', '10-15%'),
        _buildTableRow(colors, 'Crushed Stone', '12-18%'),
        _buildTableRow(colors, 'Topsoil', '8-12%'),
        _buildTableRow(colors, 'Clay', '20-30%'),
        _buildTableRow(colors, 'Base Aggregate', '15-20%'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String material, String factor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(material, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(factor, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  String _getMaterialNote() {
    switch (_materialType) {
      case 'sand': return 'Sand: Minimal shrinkage. Compacts well with vibration and water.';
      case 'gravel': return 'Gravel: Self-draining. Good for base layers. Vibrate to compact.';
      case 'crushed': return 'Crushed stone: Angular pieces lock together. Best for structural fill.';
      case 'topsoil': return 'Topsoil: Light compaction only. Don\'t over-compact organic material.';
      case 'clay': return 'Clay: High shrinkage. Moisture-sensitive. Compact in thin lifts.';
      case 'aggregate': return 'Base aggregate: Crusher run with fines. Excellent load-bearing.';
      default: return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    final labels = {'sand': 'Sand', 'gravel': 'Gravel', 'crushed': 'Crushed', 'topsoil': 'Topsoil', 'clay': 'Clay', 'aggregate': 'Aggregate'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title.isNotEmpty) ...[
        Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 8),
      ],
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
