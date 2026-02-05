import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Adhesive Calculator - Construction adhesive estimation
class AdhesiveScreen extends ConsumerStatefulWidget {
  const AdhesiveScreen({super.key});
  @override
  ConsumerState<AdhesiveScreen> createState() => _AdhesiveScreenState();
}

class _AdhesiveScreenState extends ConsumerState<AdhesiveScreen> {
  final _areaSqftController = TextEditingController(text: '100');

  String _type = 'construction';
  String _application = 'bead';

  double? _tubes10oz;
  double? _tubes28oz;
  double? _coverage;

  @override
  void dispose() { _areaSqftController.dispose(); super.dispose(); }

  void _calculate() {
    final areaSqft = double.tryParse(_areaSqftController.text) ?? 0;

    // Coverage depends on application method
    double coveragePerTube10oz;
    switch (_application) {
      case 'bead':
        coveragePerTube10oz = 25; // 1/4" bead, ~25 lf per tube, panels ~8 sqft
        break;
      case 'spread':
        coveragePerTube10oz = 15; // Full spread
        break;
      case 'dab':
        coveragePerTube10oz = 35; // Spot adhesive
        break;
      default:
        coveragePerTube10oz = 25;
    }

    // Adjust for adhesive type
    switch (_type) {
      case 'construction':
        // Standard coverage
        break;
      case 'panel':
        coveragePerTube10oz *= 0.9; // Slightly thicker
        break;
      case 'subfloor':
        coveragePerTube10oz *= 0.8; // Thicker bead
        break;
      case 'heavy':
        coveragePerTube10oz *= 0.7; // Heavy duty needs more
        break;
    }

    final tubes10oz = areaSqft / coveragePerTube10oz;
    final tubes28oz = areaSqft / (coveragePerTube10oz * 2.7);

    setState(() { _tubes10oz = tubes10oz; _tubes28oz = tubes28oz; _coverage = coveragePerTube10oz; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaSqftController.text = '100'; setState(() { _type = 'construction'; _application = 'bead'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Adhesive', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'TYPE', ['construction', 'panel', 'subfloor', 'heavy'], _type, {'construction': 'Construction', 'panel': 'Panel', 'subfloor': 'Subfloor', 'heavy': 'Heavy Duty'}, (v) { setState(() => _type = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'APPLICATION', ['bead', 'spread', 'dab'], _application, {'bead': 'Bead (1/4\")', 'spread': 'Full Spread', 'dab': 'Spot/Dab'}, (v) { setState(() => _application = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Area to Cover', unit: 'sq ft', controller: _areaSqftController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_tubes10oz != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TUBES NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_tubes10oz!.ceil()}', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('10.3 oz Tubes', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_tubes10oz!.ceil()}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('28 oz Tubes (alt)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_tubes28oz!.ceil()}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Est. Coverage', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_coverage!.toStringAsFixed(0)} sqft/tube', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Apply in S-pattern or serpentine for panels. Use mechanical fasteners too for structural.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTypeTable(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildTypeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ADHESIVE USES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Construction', 'General purpose'),
        _buildTableRow(colors, 'Panel/FRP', 'Paneling, FRP'),
        _buildTableRow(colors, 'Subfloor', 'Squeaks, gaps'),
        _buildTableRow(colors, 'Heavy duty', 'Stone, concrete'),
        _buildTableRow(colors, 'Mirror mastic', 'Mirrors only'),
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
