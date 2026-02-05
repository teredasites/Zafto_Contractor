import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Battery CCA Calculator - Cold cranking amps requirements
class BatteryCcaScreen extends ConsumerStatefulWidget {
  const BatteryCcaScreen({super.key});
  @override
  ConsumerState<BatteryCcaScreen> createState() => _BatteryCcaScreenState();
}

class _BatteryCcaScreenState extends ConsumerState<BatteryCcaScreen> {
  final _engineCcController = TextEditingController();
  String _engineType = 'gas';
  String _climate = 'moderate';

  double? _minCca;
  double? _recommendedCca;

  void _calculate() {
    final engineCc = double.tryParse(_engineCcController.text);

    if (engineCc == null) {
      setState(() { _minCca = null; });
      return;
    }

    // Base CCA calculation
    double baseCca;
    if (_engineType == 'diesel') {
      baseCca = engineCc * 0.3; // Diesels need more
    } else {
      baseCca = engineCc * 0.2;
    }

    // Climate adjustment
    double climateFactor;
    switch (_climate) {
      case 'cold':
        climateFactor = 1.4;
        break;
      case 'hot':
        climateFactor = 1.1;
        break;
      default:
        climateFactor = 1.2;
    }

    final min = baseCca * climateFactor;
    final recommended = min * 1.2; // 20% headroom

    setState(() {
      _minCca = min;
      _recommendedCca = recommended;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _engineCcController.clear();
    setState(() { _minCca = null; _engineType = 'gas'; _climate = 'moderate'; });
  }

  @override
  void dispose() {
    _engineCcController.dispose();
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
        title: Text('Battery CCA', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Engine Displacement', unit: 'cc', hint: 'Engine size in cc', controller: _engineCcController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            _buildSectionHeader(colors, 'ENGINE TYPE'),
            const SizedBox(height: 8),
            _buildEngineSelector(colors),
            const SizedBox(height: 16),
            _buildSectionHeader(colors, 'CLIMATE'),
            const SizedBox(height: 8),
            _buildClimateSelector(colors),
            const SizedBox(height: 32),
            if (_minCca != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildEngineSelector(ZaftoColors colors) {
    return Row(children: [
      _buildOption(colors, 'Gasoline', 'gas', _engineType, (v) { setState(() => _engineType = v); _calculate(); }),
      const SizedBox(width: 8),
      _buildOption(colors, 'Diesel', 'diesel', _engineType, (v) { setState(() => _engineType = v); _calculate(); }),
    ]);
  }

  Widget _buildClimateSelector(ZaftoColors colors) {
    return Row(children: [
      _buildOption(colors, 'Cold', 'cold', _climate, (v) { setState(() => _climate = v); _calculate(); }),
      const SizedBox(width: 8),
      _buildOption(colors, 'Moderate', 'moderate', _climate, (v) { setState(() => _climate = v); _calculate(); }),
      const SizedBox(width: 8),
      _buildOption(colors, 'Hot', 'hot', _climate, (v) { setState(() => _climate = v); _calculate(); }),
    ]);
  }

  Widget _buildOption(ZaftoColors colors, String label, String value, String current, Function(String) onTap) {
    final selected = current == value;
    return Expanded(child: GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colors.accentPrimary : colors.bgElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: selected ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    ));
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('CCA = Engine CC × Factor × Climate', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Cold Cranking Amps at 0°F (-18°C)', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Minimum CCA', '${_minCca!.toStringAsFixed(0)} CCA'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Recommended', '${_recommendedCca!.toStringAsFixed(0)} CCA', isPrimary: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('More CCA is always better. Never go below minimum for reliable starting.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
