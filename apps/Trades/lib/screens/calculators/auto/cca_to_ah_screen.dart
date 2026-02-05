import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// CCA to Ah Converter - Convert between battery ratings
class CcaToAhScreen extends ConsumerStatefulWidget {
  const CcaToAhScreen({super.key});
  @override
  ConsumerState<CcaToAhScreen> createState() => _CcaToAhScreenState();
}

class _CcaToAhScreenState extends ConsumerState<CcaToAhScreen> {
  final _ccaController = TextEditingController();
  final _ahController = TextEditingController();

  bool _isUpdating = false;

  void _updateFromCca(String value) {
    if (_isUpdating) return;
    _isUpdating = true;
    final cca = double.tryParse(value);
    if (cca != null) {
      // Approximate: Ah ≈ CCA / 7.5 for typical automotive batteries
      _ahController.text = (cca / 7.5).toStringAsFixed(1);
    }
    setState(() {});
    _isUpdating = false;
  }

  void _updateFromAh(String value) {
    if (_isUpdating) return;
    _isUpdating = true;
    final ah = double.tryParse(value);
    if (ah != null) {
      _ccaController.text = (ah * 7.5).toStringAsFixed(0);
    }
    setState(() {});
    _isUpdating = false;
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _ccaController.clear();
    _ahController.clear();
  }

  @override
  void dispose() {
    _ccaController.dispose();
    _ahController.dispose();
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
        title: Text('CCA to Ah', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Cold Cranking Amps', unit: 'CCA', hint: 'Battery CCA rating', controller: _ccaController, onChanged: _updateFromCca),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Amp Hours', unit: 'Ah', hint: 'Battery capacity', controller: _ahController, onChanged: _updateFromAh),
            const SizedBox(height: 32),
            _buildRatingsCard(colors),
            const SizedBox(height: 24),
            _buildInfoCard(colors),
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
        Text('Ah ≈ CCA / 7.5', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Approximate conversion - varies by battery design', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildRatingsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('OTHER RATINGS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildRatingRow(colors, 'CA (Cranking Amps)', 'CCA × 1.25 @ 32°F'),
        _buildRatingRow(colors, 'MCA (Marine CA)', 'CCA × 1.25 @ 32°F'),
        _buildRatingRow(colors, 'HCA (Hot CA)', 'CCA × 1.5 @ 80°F'),
        _buildRatingRow(colors, 'RC (Reserve Cap)', 'Minutes @ 25A to 10.5V'),
      ]),
    );
  }

  Widget _buildRatingRow(ZaftoColors colors, String rating, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(rating, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(description, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.info, size: 16, color: colors.accentPrimary),
          const SizedBox(width: 8),
          Text('NOTE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        ]),
        const SizedBox(height: 12),
        Text('CCA measures burst power for starting. Ah measures total capacity. A battery can have high CCA but low Ah (starting battery) or moderate CCA with high Ah (deep cycle).', style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5)),
      ]),
    );
  }
}
