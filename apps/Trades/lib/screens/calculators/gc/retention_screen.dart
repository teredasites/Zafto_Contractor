import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Retention Calculator - Stormwater retention/detention sizing
class RetentionScreen extends ConsumerStatefulWidget {
  const RetentionScreen({super.key});
  @override
  ConsumerState<RetentionScreen> createState() => _RetentionScreenState();
}

class _RetentionScreenState extends ConsumerState<RetentionScreen> {
  final _drainageAreaController = TextEditingController(text: '10000');
  final _rainfallController = TextEditingController(text: '2');
  final _imperviousController = TextEditingController(text: '50');

  String _pondType = 'detention';

  double? _runoffVolume;
  double? _pondVolume;
  double? _pondArea;
  double? _pondDepth;

  @override
  void dispose() { _drainageAreaController.dispose(); _rainfallController.dispose(); _imperviousController.dispose(); super.dispose(); }

  void _calculate() {
    final drainageArea = double.tryParse(_drainageAreaController.text);
    final rainfall = double.tryParse(_rainfallController.text);
    final impervious = double.tryParse(_imperviousController.text);

    if (drainageArea == null || rainfall == null || impervious == null) {
      setState(() { _runoffVolume = null; _pondVolume = null; _pondArea = null; _pondDepth = null; });
      return;
    }

    // Runoff coefficient based on impervious percentage
    final runoffCoef = 0.3 + (impervious / 100 * 0.6);

    // Runoff volume in cubic feet
    // Rainfall in inches, area in sq ft
    final runoffVolume = (rainfall / 12) * drainageArea * runoffCoef;

    // Pond sizing
    double sizeFactor;
    switch (_pondType) {
      case 'detention': sizeFactor = 1.0; break;  // Temporary storage
      case 'retention': sizeFactor = 1.5; break;  // Permanent pool + storage
      case 'infiltration': sizeFactor = 0.8; break;  // Underground infiltration
      default: sizeFactor = 1.0;
    }

    final pondVolume = runoffVolume * sizeFactor;

    // Assume 3' average water depth for surface ponds
    final avgDepth = _pondType == 'infiltration' ? 4.0 : 3.0;
    final pondArea = pondVolume / avgDepth;

    setState(() {
      _runoffVolume = runoffVolume;
      _pondVolume = pondVolume;
      _pondArea = pondArea;
      _pondDepth = avgDepth;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _drainageAreaController.text = '10000'; _rainfallController.text = '2'; _imperviousController.text = '50'; setState(() => _pondType = 'detention'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Retention', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'POND TYPE', ['detention', 'retention', 'infiltration'], _pondType, (v) { setState(() => _pondType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Drainage Area', unit: 'sq ft', controller: _drainageAreaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Design Rainfall', unit: 'inches', controller: _rainfallController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Impervious', unit: '%', controller: _imperviousController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_pondVolume != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('STORAGE VOLUME', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${(_pondVolume! / 27).toStringAsFixed(0)} yd³', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Runoff Volume', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_runoffVolume!.toStringAsFixed(0)} cu ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Pond Volume', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_pondVolume!.toStringAsFixed(0)} cu ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Surface Area @ ${_pondDepth!.toStringAsFixed(0)}\' depth', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_pondArea!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getPondNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getPondNote() {
    switch (_pondType) {
      case 'detention': return 'Detention: Dry between storms. 24-48 hr drain time typical. Requires outlet structure.';
      case 'retention': return 'Retention: Permanent pool for water quality. Add 50% volume for sediment storage.';
      case 'infiltration': return 'Infiltration: Underground chambers or gravel beds. Requires soil perc test.';
      default: return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    final labels = {'detention': 'Detention', 'retention': 'Retention', 'infiltration': 'Infiltration'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o] ?? o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
