import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Snow Removal Calculator - Time and salt estimate
class SnowRemovalScreen extends ConsumerStatefulWidget {
  const SnowRemovalScreen({super.key});
  @override
  ConsumerState<SnowRemovalScreen> createState() => _SnowRemovalScreenState();
}

class _SnowRemovalScreenState extends ConsumerState<SnowRemovalScreen> {
  final _areaController = TextEditingController(text: '2000');
  final _depthController = TextEditingController(text: '4');

  String _equipment = 'shovel';
  String _surface = 'driveway';

  double? _timeMinutes;
  double? _saltLbs;
  double? _snowCuYd;

  @override
  void dispose() { _areaController.dispose(); _depthController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 2000;
    final depthIn = double.tryParse(_depthController.text) ?? 4;

    // Equipment rate (sq ft per hour)
    double sqftPerHour;
    switch (_equipment) {
      case 'shovel': sqftPerHour = 200; break;
      case 'blower': sqftPerHour = 1500; break;
      case 'plow': sqftPerHour = 10000; break;
      default: sqftPerHour = 200;
    }

    // Adjust for depth (every 2" adds 25% time)
    final depthFactor = 1 + ((depthIn / 2) * 0.25);
    final adjustedRate = sqftPerHour / depthFactor;
    final timeHours = area / adjustedRate;
    final timeMinutes = timeHours * 60;

    // Salt: 2-4 lbs per 100 sq ft for ice melt
    double saltRate;
    switch (_surface) {
      case 'driveway': saltRate = 3; break;
      case 'sidewalk': saltRate = 2.5; break;
      case 'parking': saltRate = 4; break;
      default: saltRate = 3;
    }
    final saltLbs = (area / 100) * saltRate;

    // Snow volume
    final depthFt = depthIn / 12;
    final snowCuFt = area * depthFt;
    final snowCuYd = snowCuFt / 27;

    setState(() {
      _timeMinutes = timeMinutes;
      _saltLbs = saltLbs;
      _snowCuYd = snowCuYd;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '2000'; _depthController.text = '4'; setState(() { _equipment = 'shovel'; _surface = 'driveway'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Snow Removal', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'EQUIPMENT', ['shovel', 'blower', 'plow'], _equipment, {'shovel': 'Shovel', 'blower': 'Snow Blower', 'plow': 'Plow'}, (v) { setState(() => _equipment = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'SURFACE', ['driveway', 'sidewalk', 'parking'], _surface, {'driveway': 'Driveway', 'sidewalk': 'Sidewalk', 'parking': 'Parking Lot'}, (v) { setState(() => _surface = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Snow Depth', unit: 'in', controller: _depthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_timeMinutes != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('EST. TIME', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_timeMinutes!.toStringAsFixed(0)} min', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Snow volume', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_snowCuYd!.toStringAsFixed(1)} cu yd', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Ice melt needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_saltLbs!.toStringAsFixed(0)} lbs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('50 lb bags', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${(_saltLbs! / 50).ceil()} bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildPricingGuide(colors),
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

  Widget _buildPricingGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PRICING GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Driveway (2-car)', '\$35-75'),
        _buildTableRow(colors, 'Per inch trigger', '+\$10-20'),
        _buildTableRow(colors, 'Sidewalk', '\$15-25'),
        _buildTableRow(colors, 'Salt application', '\$25-50'),
        _buildTableRow(colors, 'Seasonal contract', '\$250-600'),
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
