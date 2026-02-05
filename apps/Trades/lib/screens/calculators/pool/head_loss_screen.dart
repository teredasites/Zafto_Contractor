import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool Plumbing Head Loss Calculator
class HeadLossScreen extends ConsumerStatefulWidget {
  const HeadLossScreen({super.key});
  @override
  ConsumerState<HeadLossScreen> createState() => _HeadLossScreenState();
}

class _HeadLossScreenState extends ConsumerState<HeadLossScreen> {
  final _pipeRunController = TextEditingController();
  final _elbowsController = TextEditingController(text: '4');
  final _gpmController = TextEditingController();
  String _pipeSize = '2"';

  double? _totalHead;
  double? _velocityFps;
  String? _assessment;

  // Friction loss per 100 ft at various GPM (simplified)
  double _getFrictionLoss(double gpm, String pipeSize) {
    // Approximate friction loss per 100 ft for PVC Schedule 40
    switch (pipeSize) {
      case '1.5"':
        return gpm * gpm * 0.0025;
      case '2"':
        return gpm * gpm * 0.0008;
      case '2.5"':
        return gpm * gpm * 0.0003;
      case '3"':
        return gpm * gpm * 0.00012;
      default:
        return gpm * gpm * 0.0008;
    }
  }

  double _getPipeArea(String pipeSize) {
    switch (pipeSize) {
      case '1.5"': return 0.0122; // sq ft
      case '2"': return 0.0218;
      case '2.5"': return 0.0341;
      case '3"': return 0.0491;
      default: return 0.0218;
    }
  }

  void _calculate() {
    final pipeRun = double.tryParse(_pipeRunController.text);
    final elbows = double.tryParse(_elbowsController.text) ?? 0;
    final gpm = double.tryParse(_gpmController.text);

    if (pipeRun == null || gpm == null || pipeRun <= 0 || gpm <= 0) {
      setState(() { _totalHead = null; });
      return;
    }

    // Equivalent length for fittings (each 90° elbow ≈ 5 ft)
    final equivalentLength = pipeRun + (elbows * 5);

    // Friction loss
    final frictionPer100 = _getFrictionLoss(gpm, _pipeSize);
    final frictionLoss = (equivalentLength / 100) * frictionPer100;

    // Add filter (5-10 ft), heater (5 ft), equipment
    final equipmentLoss = 15.0;

    final totalHead = frictionLoss + equipmentLoss;

    // Velocity check
    final area = _getPipeArea(_pipeSize);
    final cfs = gpm / 449; // GPM to CFS
    final velocity = cfs / area;

    String assessment;
    if (velocity > 8) {
      assessment = 'Velocity too high - upsize pipe';
    } else if (velocity > 6) {
      assessment = 'Velocity acceptable but noisy';
    } else if (velocity < 2) {
      assessment = 'Velocity low - good for suction side';
    } else {
      assessment = 'Velocity optimal';
    }

    setState(() {
      _totalHead = totalHead;
      _velocityFps = velocity;
      _assessment = assessment;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _pipeRunController.clear();
    _elbowsController.text = '4';
    _gpmController.clear();
    setState(() { _totalHead = null; });
  }

  @override
  void dispose() {
    _pipeRunController.dispose();
    _elbowsController.dispose();
    _gpmController.dispose();
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
        title: Text('Head Loss', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('PIPE SIZE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildPipeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Pipe Run', unit: 'ft', hint: 'Total pipe length', controller: _pipeRunController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: '90° Elbows', unit: '', hint: 'Number of elbows', controller: _elbowsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Flow Rate', unit: 'GPM', hint: 'Pump flow', controller: _gpmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_totalHead != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildPipeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: ['1.5"', '2"', '2.5"', '3"'].map((size) => ChoiceChip(
        label: Text(size),
        selected: _pipeSize == size,
        onSelected: (_) => setState(() { _pipeSize = size; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('TDH = Friction + Equipment', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Target velocity: 4-6 fps return, <4 fps suction', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Total Head', '${_totalHead!.toStringAsFixed(1)} ft', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Velocity', '${_velocityFps!.toStringAsFixed(1)} fps'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_assessment!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
