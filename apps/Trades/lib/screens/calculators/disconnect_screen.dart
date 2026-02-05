import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Disconnect Sizing Calculator - Design System v2.6
class DisconnectScreen extends ConsumerStatefulWidget {
  const DisconnectScreen({super.key});
  @override
  ConsumerState<DisconnectScreen> createState() => _DisconnectScreenState();
}

class _DisconnectScreenState extends ConsumerState<DisconnectScreen> {
  final _flaController = TextEditingController();
  final _hpController = TextEditingController();
  String _loadType = 'Motor';
  String _voltage = '480';
  String _phase = '3';
  Map<String, dynamic>? _result;

  static const List<int> _standardSizes = [30, 60, 100, 200, 400, 600, 800, 1200];

  @override
  void dispose() { _flaController.dispose(); _hpController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Disconnect Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: () { _flaController.clear(); _hpController.clear(); setState(() => _result = null); })],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _buildTypeSelector(colors),
        const SizedBox(height: 16),
        _buildInputCard(colors),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _calculate, style: ElevatedButton.styleFrom(backgroundColor: colors.accentPrimary, foregroundColor: colors.isDark ? Colors.black : Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Calculate', style: TextStyle(fontWeight: FontWeight.w600)))),
        const SizedBox(height: 20),
        if (_result != null) _buildResults(colors),
        const SizedBox(height: 16),
        _buildNecInfo(colors),
      ]),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(child: _buildTypeButton(colors, 'Motor', LucideIcons.settings, _loadType == 'Motor', () => setState(() => _loadType = 'Motor'))),
        Expanded(child: _buildTypeButton(colors, 'Non-Motor', LucideIcons.plug, _loadType == 'Non-Motor', () => setState(() => _loadType = 'Non-Motor'))),
      ]),
    );
  }

  Widget _buildTypeButton(ZaftoColors colors, String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textTertiary),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildInputCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(
          controller: _flaController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(labelText: _loadType == 'Motor' ? 'Motor FLA' : 'Load Amps', labelStyle: TextStyle(color: colors.textSecondary), hintText: 'Enter amperage', suffixText: 'A', suffixStyle: TextStyle(color: colors.textTertiary), filled: true, fillColor: colors.bgBase, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
        ),
        if (_loadType == 'Motor') ...[
          const SizedBox(height: 16),
          TextField(
            controller: _hpController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(labelText: 'Motor HP (optional)', labelStyle: TextStyle(color: colors.textSecondary), hintText: 'For HP-rated disconnect', suffixText: 'HP', suffixStyle: TextStyle(color: colors.textTertiary), filled: true, fillColor: colors.bgBase, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
          ),
        ],
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)),
            child: DropdownButton<String>(value: _voltage, isExpanded: true, dropdownColor: colors.bgElevated, underline: const SizedBox(), style: TextStyle(color: colors.textPrimary), items: ['120', '208', '240', '277', '480', '600'].map((v) => DropdownMenuItem(value: v, child: Text('$v V'))).toList(), onChanged: (v) => setState(() => _voltage = v!)),
          )),
          const SizedBox(width: 16),
          Expanded(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(10)),
            child: DropdownButton<String>(value: _phase, isExpanded: true, dropdownColor: colors.bgElevated, underline: const SizedBox(), style: TextStyle(color: colors.textPrimary), items: ['1', '3'].map((p) => DropdownMenuItem(value: p, child: Text('$pΦ'))).toList(), onChanged: (v) => setState(() => _phase = v!)),
          )),
        ]),
      ]),
    );
  }

  Widget _buildResults(ZaftoColors colors) {
    final r = _result!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3))),
      child: Column(children: [
        Row(children: [
          Icon(LucideIcons.checkCircle, color: colors.accentSuccess),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Minimum Disconnect Size', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            Text('${r['selectedSize']} A', style: TextStyle(color: colors.accentSuccess, fontSize: 28, fontWeight: FontWeight.w700)),
          ])),
        ]),
        Divider(height: 24, color: colors.borderSubtle),
        _buildResultRow(colors, 'Load Current', '${r['fla'].toStringAsFixed(1)} A'),
        _buildResultRow(colors, 'Min Rating (115%)', '${r['minRating'].toStringAsFixed(1)} A'),
        _buildResultRow(colors, 'Selected Size', '${r['selectedSize']} A'),
        if (r['hpRequirement'] != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(LucideIcons.info, color: colors.accentInfo, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(r['hpRequirement'], style: TextStyle(color: colors.accentInfo, fontSize: 12))),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildNecInfo(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.scale, color: colors.accentInfo, size: 18), const SizedBox(width: 8), Text('NEC Requirements', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))]),
        const SizedBox(height: 10),
        Text('Motor Disconnects (430.109, 430.110):\n• Must be rated ≥115% of motor FLA\n• Must be HP-rated or equivalent\n• Must be within sight of motor, or lockable\n• Required for each motor\n\nNon-Motor Disconnects:\n• Size for continuous + non-continuous load\n• 125% for continuous loads', style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.5)),
      ]),
    );
  }

  void _calculate() {
    double? fla = double.tryParse(_flaController.text);
    if (fla == null || fla <= 0) { setState(() => _result = null); return; }
    final minRating = fla * 1.15;
    int selectedSize = _standardSizes.last;
    for (final size in _standardSizes) { if (size >= minRating) { selectedSize = size; break; } }
    String? hpRequirement;
    if (_loadType == 'Motor' && _hpController.text.isNotEmpty) {
      final hp = double.tryParse(_hpController.text);
      if (hp != null) hpRequirement = 'Disconnect must be HP-rated for ${hp.toStringAsFixed(1)} HP or greater';
    }
    setState(() { _result = {'fla': fla, 'minRating': minRating, 'selectedSize': selectedSize, 'hpRequirement': hpRequirement, 'isMotor': _loadType == 'Motor'}; });
  }
}
