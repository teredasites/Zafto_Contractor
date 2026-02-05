import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Service Entrance Calculator - Design System v2.6
class ServiceEntranceScreen extends ConsumerStatefulWidget {
  const ServiceEntranceScreen({super.key});
  @override
  ConsumerState<ServiceEntranceScreen> createState() => _ServiceEntranceScreenState();
}

class _ServiceEntranceScreenState extends ConsumerState<ServiceEntranceScreen> {
  final _loadController = TextEditingController();
  String _voltage = '240';
  String _phase = '1';
  String _serviceType = 'Overhead';
  Map<String, dynamic>? _result;

  static const List<Map<String, dynamic>> _serviceSizes = [
    {'amps': 100, 'cuSize': '4', 'alSize': '2', 'gecCu': '8', 'gecAl': '6'},
    {'amps': 110, 'cuSize': '3', 'alSize': '1', 'gecCu': '8', 'gecAl': '6'},
    {'amps': 125, 'cuSize': '2', 'alSize': '1/0', 'gecCu': '8', 'gecAl': '6'},
    {'amps': 150, 'cuSize': '1', 'alSize': '2/0', 'gecCu': '6', 'gecAl': '4'},
    {'amps': 175, 'cuSize': '1/0', 'alSize': '3/0', 'gecCu': '6', 'gecAl': '4'},
    {'amps': 200, 'cuSize': '2/0', 'alSize': '4/0', 'gecCu': '4', 'gecAl': '2'},
    {'amps': 225, 'cuSize': '3/0', 'alSize': '250', 'gecCu': '4', 'gecAl': '2'},
    {'amps': 250, 'cuSize': '4/0', 'alSize': '300', 'gecCu': '2', 'gecAl': '1/0'},
    {'amps': 300, 'cuSize': '250', 'alSize': '350', 'gecCu': '2', 'gecAl': '1/0'},
    {'amps': 350, 'cuSize': '350', 'alSize': '500', 'gecCu': '1/0', 'gecAl': '3/0'},
    {'amps': 400, 'cuSize': '400', 'alSize': '600', 'gecCu': '1/0', 'gecAl': '3/0'},
  ];

  static const List<int> _standardServices = [100, 125, 150, 200, 225, 300, 400, 600, 800, 1000, 1200];

  @override
  void dispose() { _loadController.dispose(); super.dispose(); }

  void _calculate() {
    final loadAmps = double.tryParse(_loadController.text);
    if (loadAmps == null || loadAmps <= 0) { setState(() => _result = null); return; }
    int serviceSize = _standardServices.last;
    for (final size in _standardServices) { if (size >= loadAmps) { serviceSize = size; break; } }
    Map<String, dynamic>? sizing;
    for (final s in _serviceSizes) { if (s['amps'] >= serviceSize) { sizing = s; break; } }
    sizing ??= _serviceSizes.last;
    final voltage = int.parse(_voltage);
    final phase = int.parse(_phase);
    setState(() { _result = {'loadAmps': loadAmps, 'serviceSize': serviceSize, 'cuServiceSize': sizing!['cuSize'], 'alServiceSize': sizing['alSize'], 'gecCu': sizing['gecCu'], 'gecAl': sizing['gecAl'], 'numHots': phase == 1 ? 2 : 3, 'neutralReq': 'Required', 'voltage': voltage, 'phase': phase}; });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Service Entrance', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: () { _loadController.clear(); setState(() => _result = null); })],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInputCard(colors),
          const SizedBox(height: 16),
          _buildOptionsCard(colors),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _calculate, style: ElevatedButton.styleFrom(backgroundColor: colors.accentPrimary, foregroundColor: colors.isDark ? Colors.black : Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('CALCULATE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1))),
          const SizedBox(height: 20),
          if (_result != null) _buildResults(colors),
          const SizedBox(height: 16),
          _buildNecInfo(colors),
        ],
      ),
    );
  }

  Widget _buildInputCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Calculated Load', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        const SizedBox(height: 10),
        TextField(controller: _loadController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600), decoration: InputDecoration(hintText: 'From load calculation', hintStyle: TextStyle(color: colors.textTertiary), suffixText: 'Amps', suffixStyle: TextStyle(color: colors.textTertiary), filled: true, fillColor: colors.bgBase, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
        const SizedBox(height: 12),
        Text('Use Dwelling Load or Commercial Load calculator first', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildOptionsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Voltage', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: DropdownButton<String>(value: _voltage, dropdownColor: colors.bgElevated, underline: const SizedBox(), isExpanded: true, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500), items: ['240', '208', '480'].map((v) => DropdownMenuItem(value: v, child: Text('$v V'))).toList(), onChanged: (v) => setState(() => _voltage = v!)),
            ),
          ])),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Phase', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
              child: DropdownButton<String>(value: _phase, dropdownColor: colors.bgElevated, underline: const SizedBox(), isExpanded: true, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500), items: const [DropdownMenuItem(value: '1', child: Text('Single (1Φ)')), DropdownMenuItem(value: '3', child: Text('Three (3Φ)'))], onChanged: (v) => setState(() => _phase = v!)),
            ),
          ])),
        ]),
        const SizedBox(height: 16),
        Text('Service Type', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _buildToggle(colors, 'Overhead', _serviceType == 'Overhead', () => setState(() => _serviceType = 'Overhead'))),
          const SizedBox(width: 8),
          Expanded(child: _buildToggle(colors, 'Underground', _serviceType == 'Underground', () => setState(() => _serviceType = 'Underground'))),
        ]),
      ]),
    );
  }

  Widget _buildToggle(ZaftoColors colors, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)), child: Center(child: Text(label, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)))),
    );
  }

  Widget _buildResults(ZaftoColors colors) {
    final r = _result!;
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3))),
        child: Column(children: [
          Text('Minimum Service Size', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Text('${r['serviceSize']} A', style: TextStyle(color: colors.accentSuccess, fontSize: 36, fontWeight: FontWeight.w700)),
          Text('${r['phase']}Φ ${r['voltage']}V', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        ]),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.borderSubtle)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('SERVICE CONDUCTORS', style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Copper', '${r['cuServiceSize']} AWG/kcmil'),
          _buildResultRow(colors, 'Aluminum', '${r['alServiceSize']} AWG/kcmil'),
          _buildResultRow(colors, 'Hot Conductors', '${r['numHots']}'),
          _buildResultRow(colors, 'Neutral', r['neutralReq']),
          Divider(color: colors.borderSubtle, height: 24),
          Text('GROUNDING ELECTRODE CONDUCTOR', style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'GEC Copper', '${r['gecCu']} AWG'),
          _buildResultRow(colors, 'GEC Aluminum', '${r['gecAl']} AWG'),
        ]),
      ),
    ]);
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      Text(value, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
    ]));
  }

  Widget _buildNecInfo(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.scale, color: colors.accentPrimary, size: 18), const SizedBox(width: 8), Text('NEC Article 230', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))]),
        const SizedBox(height: 10),
        Text('• 230.42: Service conductors sized per load\n• 230.79: Minimum service 100A for dwelling\n• 250.66: GEC sizing table\n• 310.12: Service conductor ampacity', style: TextStyle(color: colors.textTertiary, fontSize: 12, height: 1.5)),
      ]),
    );
  }
}
