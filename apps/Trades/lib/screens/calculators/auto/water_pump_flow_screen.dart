import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Water Pump GPM Calculator
class WaterPumpFlowScreen extends ConsumerStatefulWidget {
  const WaterPumpFlowScreen({super.key});
  @override
  ConsumerState<WaterPumpFlowScreen> createState() => _WaterPumpFlowScreenState();
}

class _WaterPumpFlowScreenState extends ConsumerState<WaterPumpFlowScreen> {
  final _hpController = TextEditingController();
  final _engineSizeController = TextEditingController();
  final _maxRpmController = TextEditingController(text: '6000');

  double? _minGpm;
  double? _recommendedGpm;
  double? _systemVolume;
  String? _pumpType;

  void _calculate() {
    final hp = double.tryParse(_hpController.text);
    final engineSize = double.tryParse(_engineSizeController.text);
    final maxRpm = double.tryParse(_maxRpmController.text);

    if (hp == null) {
      setState(() { _minGpm = null; });
      return;
    }

    // Water pump flow calculation
    // Rule of thumb: 1 GPM per 10 HP at idle, scales with RPM
    // At peak RPM, need ~1 GPM per 8 HP for adequate cooling
    final minGpm = hp / 10;
    final recGpm = hp / 7;

    // Estimate system volume if engine size provided
    double? sysVol;
    if (engineSize != null) {
      // Typical cooling system: 1 quart per liter of displacement + 4-6 qt for radiator
      sysVol = (engineSize * 1.0) + 5;
    }

    // Pump type recommendation based on HP and RPM
    String pumpRec;
    if (hp <= 300 && (maxRpm ?? 6000) <= 6500) {
      pumpRec = 'Stock mechanical pump adequate';
    } else if (hp <= 500) {
      pumpRec = 'High-flow mechanical pump recommended';
    } else if (hp <= 700) {
      pumpRec = 'High-volume mechanical or electric pump';
    } else {
      pumpRec = 'Electric water pump with controller';
    }

    // Adjust for high RPM applications
    if ((maxRpm ?? 6000) > 7000) {
      pumpRec += '. High RPM: Consider electric pump to avoid cavitation';
    }

    setState(() {
      _minGpm = minGpm;
      _recommendedGpm = recGpm;
      _systemVolume = sysVol;
      _pumpType = pumpRec;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _hpController.clear();
    _engineSizeController.clear();
    _maxRpmController.text = '6000';
    setState(() { _minGpm = null; });
  }

  @override
  void dispose() {
    _hpController.dispose();
    _engineSizeController.dispose();
    _maxRpmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Water Pump Flow', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Engine Horsepower', unit: 'HP', hint: 'Peak horsepower', controller: _hpController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Engine Displacement', unit: 'L', hint: 'Optional - for capacity estimate', controller: _engineSizeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Max Engine RPM', unit: 'RPM', hint: 'Redline RPM', controller: _maxRpmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_minGpm != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('GPM = HP / 7 to 10', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Higher flow rates needed for high-performance engines', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Minimum Flow', '${_minGpm!.toStringAsFixed(1)} GPM', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Recommended Flow', '${_recommendedGpm!.toStringAsFixed(1)} GPM'),
        if (_systemVolume != null) ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Est. System Volume', '${_systemVolume!.toStringAsFixed(1)} qts'),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(LucideIcons.droplet, color: colors.accentPrimary, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(_pumpType!, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
          ]),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
