import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Superheat Calculator - Suction line superheat
class SuperheatScreen extends ConsumerStatefulWidget {
  const SuperheatScreen({super.key});
  @override
  ConsumerState<SuperheatScreen> createState() => _SuperheatScreenState();
}

class _SuperheatScreenState extends ConsumerState<SuperheatScreen> {
  final _lowSidePressureController = TextEditingController();
  final _suctionLineTempController = TextEditingController();

  double? _satTemp;
  double? _superheat;
  String? _status;

  void _calculate() {
    final lowSidePressure = double.tryParse(_lowSidePressureController.text);
    final suctionLineTemp = double.tryParse(_suctionLineTempController.text);

    if (lowSidePressure == null || suctionLineTemp == null) {
      setState(() { _superheat = null; });
      return;
    }

    // R-134a P/T approximation (simplified)
    // Saturation temp at low side - different relationship
    final satTemp = (lowSidePressure - 14.7) * 1.1 + 32;
    final superheat = suctionLineTemp - satTemp;

    String status;
    if (superheat < 5) {
      status = 'Low superheat - risk of liquid slugging compressor';
    } else if (superheat <= 15) {
      status = 'Normal superheat range';
    } else if (superheat <= 25) {
      status = 'Slightly high - check for low charge';
    } else {
      status = 'High superheat - low charge or restriction';
    }

    setState(() {
      _satTemp = satTemp;
      _superheat = superheat;
      _status = status;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _lowSidePressureController.clear();
    _suctionLineTempController.clear();
    setState(() { _superheat = null; });
  }

  @override
  void dispose() {
    _lowSidePressureController.dispose();
    _suctionLineTempController.dispose();
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
        title: Text('Superheat', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Low Side Pressure', unit: 'psi', hint: 'Blue gauge', controller: _lowSidePressureController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Suction Line Temp', unit: '°F', hint: 'At compressor inlet', controller: _suctionLineTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_superheat != null) _buildResultsCard(colors),
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
        Text('Superheat = Line Temp - Sat Temp', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Ensures vapor returns to compressor', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    Color statusColor;
    if (_superheat! >= 5 && _superheat! <= 15) {
      statusColor = colors.accentSuccess;
    } else if (_superheat! < 5) {
      statusColor = colors.error;
    } else {
      statusColor = colors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('SUPERHEAT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_superheat!.toStringAsFixed(1)}°F', style: TextStyle(color: statusColor, fontSize: 48, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Sat temp: ${_satTemp!.toStringAsFixed(0)}°F', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_status!, style: TextStyle(color: statusColor, fontSize: 13), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 12),
        Text('Target: 8-12°F superheat', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
      ]),
    );
  }
}
