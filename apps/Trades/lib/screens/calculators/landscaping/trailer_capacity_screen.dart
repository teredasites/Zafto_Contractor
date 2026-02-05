import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Trailer Capacity Calculator - Load planning and weight
class TrailerCapacityScreen extends ConsumerStatefulWidget {
  const TrailerCapacityScreen({super.key});
  @override
  ConsumerState<TrailerCapacityScreen> createState() => _TrailerCapacityScreenState();
}

class _TrailerCapacityScreenState extends ConsumerState<TrailerCapacityScreen> {
  final _lengthController = TextEditingController(text: '16');
  final _widthController = TextEditingController(text: '6.5');
  final _sideHeightController = TextEditingController(text: '2');

  String _trailerType = 'utility';

  double? _volumeCuFt;
  double? _volumeCuYd;
  double? _maxPayload;
  double? _mulchYards;
  double? _soilYards;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _sideHeightController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 16;
    final width = double.tryParse(_widthController.text) ?? 6.5;
    final sideHeight = double.tryParse(_sideHeightController.text) ?? 2;

    // Volume calculation
    final volumeCuFt = length * width * sideHeight;
    final volumeCuYd = volumeCuFt / 27;

    // Max payload by trailer type
    double maxLbs;
    switch (_trailerType) {
      case 'utility':
        maxLbs = 2500;
        break;
      case 'landscape':
        maxLbs = 5000;
        break;
      case 'dump':
        maxLbs = 10000;
        break;
      case 'equipment':
        maxLbs = 7000;
        break;
      default:
        maxLbs = 5000;
    }

    // Material limits based on weight (mulch ~500 lbs/cy, soil ~2200 lbs/cy)
    final mulchByWeight = maxLbs / 500;
    final soilByWeight = maxLbs / 2200;

    // Use lesser of volume or weight limit
    final mulchYards = mulchByWeight < volumeCuYd ? mulchByWeight : volumeCuYd;
    final soilYards = soilByWeight < volumeCuYd ? soilByWeight : volumeCuYd;

    setState(() {
      _volumeCuFt = volumeCuFt;
      _volumeCuYd = volumeCuYd;
      _maxPayload = maxLbs;
      _mulchYards = mulchYards;
      _soilYards = soilYards;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '16'; _widthController.text = '6.5'; _sideHeightController.text = '2'; setState(() { _trailerType = 'utility'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Trailer Capacity', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'TRAILER TYPE', ['utility', 'landscape', 'dump', 'equipment'], _trailerType, {'utility': 'Utility', 'landscape': 'Landscape', 'dump': 'Dump', 'equipment': 'Equipment'}, (v) { setState(() => _trailerType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Side Height', unit: 'ft', controller: _sideHeightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_volumeCuYd != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('VOLUME CAPACITY', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_volumeCuYd!.toStringAsFixed(1)} cu yd', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Volume (cu ft)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_volumeCuFt!.toStringAsFixed(0)} cu ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Max payload', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${(_maxPayload! / 1000).toStringAsFixed(1)}K lbs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Mulch limit', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_mulchYards!.toStringAsFixed(1)} yards', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Soil/gravel limit', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_soilYards!.toStringAsFixed(1)} yards', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Weight often limits before volume. Check trailer GVWR and tow vehicle rating.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ),
            const SizedBox(height: 20),
            _buildTrailerGuide(colors),
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

  Widget _buildTrailerGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON TRAILER SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '5x8 utility', '~1.5 cu yd'),
        _buildTableRow(colors, '6x12 landscape', '~4 cu yd'),
        _buildTableRow(colors, '7x16 landscape', '~6 cu yd'),
        _buildTableRow(colors, '7x14 dump', '~5 cu yd'),
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
