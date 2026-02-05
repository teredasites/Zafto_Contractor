import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Motion Sensor Calculator - Motion sensor coverage estimation
class MotionSensorScreen extends ConsumerStatefulWidget {
  const MotionSensorScreen({super.key});
  @override
  ConsumerState<MotionSensorScreen> createState() => _MotionSensorScreenState();
}

class _MotionSensorScreenState extends ConsumerState<MotionSensorScreen> {
  final _areaLengthController = TextEditingController(text: '30');
  final _areaWidthController = TextEditingController(text: '20');
  final _mountHeightController = TextEditingController(text: '9');

  String _sensorType = 'pir';
  String _location = 'outdoor';

  int? _sensorsNeeded;
  double? _coverageRadius;
  double? _coverageAngle;
  String? _mountingTip;

  @override
  void dispose() { _areaLengthController.dispose(); _areaWidthController.dispose(); _mountHeightController.dispose(); super.dispose(); }

  void _calculate() {
    final areaLength = double.tryParse(_areaLengthController.text) ?? 30;
    final areaWidth = double.tryParse(_areaWidthController.text) ?? 20;
    final mountHeight = double.tryParse(_mountHeightController.text) ?? 9;

    // Sensor coverage based on type
    double coverageRadius;
    double coverageAngle;
    switch (_sensorType) {
      case 'pir':
        coverageRadius = 30; // 30 ft typical
        coverageAngle = 180;
        break;
      case 'microwave':
        coverageRadius = 40;
        coverageAngle = 360;
        break;
      case 'dual':
        coverageRadius = 35;
        coverageAngle = 180;
        break;
      case 'ultrasonic':
        coverageRadius = 25;
        coverageAngle = 180;
        break;
      default:
        coverageRadius = 30;
        coverageAngle = 180;
    }

    // Adjust for mount height (higher = wider but less sensitive)
    if (mountHeight > 10) {
      coverageRadius *= 0.9;
    }

    // Calculate sensors needed
    final areaSqft = areaLength * areaWidth;
    final coverageSqft = 3.14159 * (coverageRadius * coverageRadius) * (coverageAngle / 360);
    var sensorsNeeded = (areaSqft / coverageSqft).ceil();
    if (sensorsNeeded < 1) sensorsNeeded = 1;

    // Mounting tip
    String mountingTip;
    if (_location == 'outdoor') {
      mountingTip = 'Mount 6-10\' high. Aim perpendicular to traffic path. Shield from direct sunlight.';
    } else {
      mountingTip = 'Mount in corner for best coverage. Avoid HVAC vents and windows.';
    }

    setState(() { _sensorsNeeded = sensorsNeeded; _coverageRadius = coverageRadius; _coverageAngle = coverageAngle; _mountingTip = mountingTip; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaLengthController.text = '30'; _areaWidthController.text = '20'; _mountHeightController.text = '9'; setState(() { _sensorType = 'pir'; _location = 'outdoor'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Motion Sensor', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SENSOR TYPE', ['pir', 'microwave', 'dual', 'ultrasonic'], _sensorType, {'pir': 'PIR', 'microwave': 'Microwave', 'dual': 'Dual Tech', 'ultrasonic': 'Ultrasonic'}, (v) { setState(() => _sensorType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'LOCATION', ['outdoor', 'indoor'], _location, {'outdoor': 'Outdoor', 'indoor': 'Indoor'}, (v) { setState(() => _location = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Area Length', unit: 'feet', controller: _areaLengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Area Width', unit: 'feet', controller: _areaWidthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Mount Height', unit: 'feet', controller: _mountHeightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_sensorsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('SENSORS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_sensorsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Coverage Radius', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_coverageRadius!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Coverage Angle', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_coverageAngle!.toStringAsFixed(0)}°', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_mountingTip!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTypesTable(colors),
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

  Widget _buildTypesTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SENSOR TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'PIR', 'Heat detection, common'),
        _buildTableRow(colors, 'Microwave', '360°, through walls'),
        _buildTableRow(colors, 'Dual tech', 'PIR + microwave'),
        _buildTableRow(colors, 'Ultrasonic', 'Sound waves'),
        _buildTableRow(colors, 'Pet immune', 'Ignores <40-80 lbs'),
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
