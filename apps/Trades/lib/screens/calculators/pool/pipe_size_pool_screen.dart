import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool Pipe Size Calculator
class PipeSizePoolScreen extends ConsumerStatefulWidget {
  const PipeSizePoolScreen({super.key});
  @override
  ConsumerState<PipeSizePoolScreen> createState() => _PipeSizePoolScreenState();
}

class _PipeSizePoolScreenState extends ConsumerState<PipeSizePoolScreen> {
  final _gpmController = TextEditingController();
  String _pipeType = 'Return';

  String? _recommendedSize;
  double? _velocity;
  String? _note;

  // Max velocity recommendations
  // Suction: 4-6 fps, Return: 6-8 fps
  static const Map<String, Map<String, double>> _pipeData = {
    '1.5"': {'area': 0.0122, 'maxSuction': 33, 'maxReturn': 44},
    '2"': {'area': 0.0218, 'maxSuction': 59, 'maxReturn': 78},
    '2.5"': {'area': 0.0341, 'maxSuction': 92, 'maxReturn': 122},
    '3"': {'area': 0.0491, 'maxSuction': 133, 'maxReturn': 177},
  };

  void _calculate() {
    final gpm = double.tryParse(_gpmController.text);

    if (gpm == null || gpm <= 0) {
      setState(() { _recommendedSize = null; });
      return;
    }

    final isSuction = _pipeType == 'Suction';
    String recommended = '3"';
    double velocity = 0;

    for (final entry in _pipeData.entries) {
      final maxFlow = isSuction ? entry.value['maxSuction']! : entry.value['maxReturn']!;
      if (gpm <= maxFlow) {
        recommended = entry.key;
        final area = entry.value['area']!;
        final cfs = gpm / 449;
        velocity = cfs / area;
        break;
      }
    }

    String note;
    if (isSuction && velocity > 6) {
      note = 'Velocity too high for suction - size up';
    } else if (!isSuction && velocity > 8) {
      note = 'Velocity too high - may cause noise and wear';
    } else if (velocity < 2) {
      note = 'Velocity low - consider smaller pipe';
    } else {
      note = 'Good velocity for ${_pipeType.toLowerCase()} side';
    }

    setState(() {
      _recommendedSize = recommended;
      _velocity = velocity;
      _note = note;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _gpmController.clear();
    setState(() { _recommendedSize = null; });
  }

  @override
  void dispose() {
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
        title: Text('Pool Pipe Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('PIPE LOCATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildTypeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Flow Rate', unit: 'GPM', hint: 'Pump output', controller: _gpmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_recommendedSize != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Row(children: [
      ChoiceChip(label: const Text('Suction'), selected: _pipeType == 'Suction', onSelected: (_) => setState(() { _pipeType = 'Suction'; _calculate(); })),
      const SizedBox(width: 8),
      ChoiceChip(label: const Text('Return'), selected: _pipeType == 'Return', onSelected: (_) => setState(() { _pipeType = 'Return'; _calculate(); })),
    ]);
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Suction: 4-6 fps, Return: 6-8 fps', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Lower velocity on suction prevents cavitation', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Recommended', _recommendedSize!, isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Velocity', '${_velocity!.toStringAsFixed(1)} fps'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_note!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 32 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
