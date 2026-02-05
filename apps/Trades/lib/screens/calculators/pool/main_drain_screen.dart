import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool Main Drain Calculator
class MainDrainScreen extends ConsumerStatefulWidget {
  const MainDrainScreen({super.key});
  @override
  ConsumerState<MainDrainScreen> createState() => _MainDrainScreenState();
}

class _MainDrainScreenState extends ConsumerState<MainDrainScreen> {
  final _gpmController = TextEditingController();
  final _poolDepthController = TextEditingController(text: '8');
  bool _isCommercial = false;

  int? _drainsNeeded;
  String? _drainSize;
  String? _vgbRequirement;

  void _calculate() {
    final gpm = double.tryParse(_gpmController.text);
    final poolDepth = double.tryParse(_poolDepthController.text);

    if (gpm == null || poolDepth == null || gpm <= 0) {
      setState(() { _drainsNeeded = null; });
      return;
    }

    // VGB Act requires dual drains for suction entrapment protection
    // Or single drain with SVRS (Safety Vacuum Release System)
    int drains = 2; // Minimum per VGB

    // Drain size based on flow
    String drainSize;
    if (gpm <= 60) {
      drainSize = '8" × 8" drain covers';
    } else if (gpm <= 100) {
      drainSize = '12" × 12" drain covers';
    } else if (gpm <= 150) {
      drainSize = '18" × 18" drain covers';
    } else {
      drainSize = '24" × 24" or larger';
      drains = 4;
    }

    String vgbRequirement;
    if (_isCommercial) {
      vgbRequirement = 'VGB compliant: Dual drains 3+ ft apart, SVRS required, anti-entrapment covers';
    } else {
      vgbRequirement = 'VGB compliant: Dual drains 3+ ft apart OR single drain with SVRS';
    }

    setState(() {
      _drainsNeeded = drains;
      _drainSize = drainSize;
      _vgbRequirement = vgbRequirement;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _gpmController.clear();
    _poolDepthController.text = '8';
    setState(() { _drainsNeeded = null; });
  }

  @override
  void dispose() {
    _gpmController.dispose();
    _poolDepthController.dispose();
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
        title: Text('Main Drain', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Pump Flow', unit: 'GPM', hint: 'Total pump output', controller: _gpmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Pool Depth', unit: 'ft', hint: 'Deep end depth', controller: _poolDepthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            _buildPoolTypeToggle(colors),
            const SizedBox(height: 32),
            if (_drainsNeeded != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildPoolTypeToggle(ZaftoColors colors) {
    return Row(children: [
      ChoiceChip(label: const Text('Residential'), selected: !_isCommercial, onSelected: (_) => setState(() { _isCommercial = false; _calculate(); })),
      const SizedBox(width: 8),
      ChoiceChip(label: const Text('Commercial'), selected: _isCommercial, onSelected: (_) => setState(() { _isCommercial = true; _calculate(); })),
    ]);
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('VGB Act Compliance Required', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Dual drains prevent suction entrapment', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Drains Needed', '$_drainsNeeded minimum', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Drain Size', _drainSize!),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(LucideIcons.alertTriangle, size: 16, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(_vgbRequirement!, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
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
