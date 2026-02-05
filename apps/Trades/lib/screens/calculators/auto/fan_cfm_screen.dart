import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Cooling Fan CFM Calculator
class FanCfmScreen extends ConsumerStatefulWidget {
  const FanCfmScreen({super.key});
  @override
  ConsumerState<FanCfmScreen> createState() => _FanCfmScreenState();
}

class _FanCfmScreenState extends ConsumerState<FanCfmScreen> {
  final _hpController = TextEditingController();
  final _radiatorWidthController = TextEditingController();
  final _radiatorHeightController = TextEditingController();

  double? _minCfm;
  double? _recommendedCfm;
  double? _radiatorArea;
  String? _fanRecommendation;

  void _calculate() {
    final hp = double.tryParse(_hpController.text);
    final width = double.tryParse(_radiatorWidthController.text);
    final height = double.tryParse(_radiatorHeightController.text);

    if (hp == null) {
      setState(() { _minCfm = null; });
      return;
    }

    // CFM rule of thumb: 2-3 CFM per HP for adequate cooling
    // Higher HP engines need better airflow efficiency
    final minCfm = hp * 2.0;
    final recCfm = hp * 2.5;

    double? area;
    String fanRec;

    if (width != null && height != null) {
      area = width * height;

      // Fan sizing based on radiator area
      if (area <= 300) {
        fanRec = 'Single 12" electric fan (1,200-1,600 CFM)';
      } else if (area <= 400) {
        fanRec = 'Single 14" or 16" electric fan (1,800-2,500 CFM)';
      } else if (area <= 500) {
        fanRec = 'Dual 12" or single 16" high-output (2,500-3,200 CFM)';
      } else {
        fanRec = 'Dual 14" or 16" high-output fans (3,500+ CFM)';
      }
    } else {
      // Base recommendation on HP only
      if (hp <= 250) {
        fanRec = 'Single 12-14" electric fan';
      } else if (hp <= 400) {
        fanRec = 'Single 16" or dual 12" fans';
      } else if (hp <= 600) {
        fanRec = 'Dual 14" high-output fans';
      } else {
        fanRec = 'Dual 16" high-output fans with shroud';
      }
    }

    setState(() {
      _minCfm = minCfm;
      _recommendedCfm = recCfm;
      _radiatorArea = area;
      _fanRecommendation = fanRec;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _hpController.clear();
    _radiatorWidthController.clear();
    _radiatorHeightController.clear();
    setState(() { _minCfm = null; });
  }

  @override
  void dispose() {
    _hpController.dispose();
    _radiatorWidthController.dispose();
    _radiatorHeightController.dispose();
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
        title: Text('Fan CFM', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
            ZaftoInputField(label: 'Radiator Width', unit: 'in', hint: 'Optional - core width', controller: _radiatorWidthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Radiator Height', unit: 'in', hint: 'Optional - core height', controller: _radiatorHeightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_minCfm != null) _buildResultsCard(colors),
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
        Text('CFM = HP x 2.0 to 2.5', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Pusher fans less efficient than puller fans', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Minimum CFM', '${_minCfm!.toStringAsFixed(0)} CFM', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Recommended CFM', '${_recommendedCfm!.toStringAsFixed(0)} CFM'),
        if (_radiatorArea != null) ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Radiator Area', '${_radiatorArea!.toStringAsFixed(0)} sq in'),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(LucideIcons.fan, color: colors.accentPrimary, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(_fanRecommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
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
