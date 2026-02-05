import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Trellis Calculator - Garden trellis materials estimation
class TrellisScreen extends ConsumerStatefulWidget {
  const TrellisScreen({super.key});
  @override
  ConsumerState<TrellisScreen> createState() => _TrellisScreenState();
}

class _TrellisScreenState extends ConsumerState<TrellisScreen> {
  final _widthController = TextEditingController(text: '4');
  final _heightController = TextEditingController(text: '6');
  final _countController = TextEditingController(text: '2');

  String _style = 'lattice';
  String _material = 'cedar';

  double? _latticeSqft;
  double? _frameFeet;
  int? _posts;
  int? _screws;

  @override
  void dispose() { _widthController.dispose(); _heightController.dispose(); _countController.dispose(); super.dispose(); }

  void _calculate() {
    final width = double.tryParse(_widthController.text) ?? 4;
    final height = double.tryParse(_heightController.text) ?? 6;
    final count = int.tryParse(_countController.text) ?? 2;

    // Lattice/grid area
    final latticeSqft = width * height * count * 1.10; // +10% waste

    // Frame: perimeter of each panel
    final perimeterPerPanel = (width + height) * 2;
    final frameFeet = perimeterPerPanel * count;

    // Posts: 2 per freestanding panel, 0 for wall-mounted
    int posts;
    switch (_style) {
      case 'lattice':
        posts = 0; // typically wall-mounted
        break;
      case 'freestanding':
        posts = count * 2;
        break;
      case 'arched':
        posts = count * 2;
        break;
      case 'fan':
        posts = 0;
        break;
      default:
        posts = 0;
    }

    // Screws: frame joints + lattice attachment
    final screws = (count * 16) + (posts * 4);

    setState(() { _latticeSqft = latticeSqft; _frameFeet = frameFeet; _posts = posts; _screws = screws; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _widthController.text = '4'; _heightController.text = '6'; _countController.text = '2'; setState(() { _style = 'lattice'; _material = 'cedar'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Trellis', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'STYLE', ['lattice', 'freestanding', 'arched', 'fan'], _style, {'lattice': 'Lattice', 'freestanding': 'Freestanding', 'arched': 'Arched', 'fan': 'Fan'}, (v) { setState(() => _style = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'MATERIAL', ['cedar', 'vinyl', 'metal', 'bamboo'], _material, {'cedar': 'Cedar', 'vinyl': 'Vinyl', 'metal': 'Metal', 'bamboo': 'Bamboo'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Number of Panels', unit: 'qty', controller: _countController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'feet', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Height', unit: 'feet', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_latticeSqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('LATTICE/GRID', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_latticeSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Frame Material', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_frameFeet!.toStringAsFixed(0)} lin ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_posts! > 0) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Posts (4x4)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_posts', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Screws', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_screws', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Space trellis 2-4\" from wall for air circulation. Use rot-resistant wood or treat annually. Size for mature plant weight.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildPlantsTable(colors),
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

  Widget _buildPlantsTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CLIMBING PLANTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Clematis', 'Light trellis OK'),
        _buildTableRow(colors, 'Climbing rose', 'Heavy-duty needed'),
        _buildTableRow(colors, 'Wisteria', 'Very heavy, reinforce'),
        _buildTableRow(colors, 'Jasmine', 'Medium weight'),
        _buildTableRow(colors, 'Honeysuckle', 'Light to medium'),
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
