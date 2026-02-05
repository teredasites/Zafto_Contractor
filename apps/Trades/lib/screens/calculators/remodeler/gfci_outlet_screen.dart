import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// GFCI Outlet Calculator - GFCI requirements estimation
class GfciOutletScreen extends ConsumerStatefulWidget {
  const GfciOutletScreen({super.key});
  @override
  ConsumerState<GfciOutletScreen> createState() => _GfciOutletScreenState();
}

class _GfciOutletScreenState extends ConsumerState<GfciOutletScreen> {
  final _kitchenCounterController = TextEditingController(text: '4');
  final _bathroomController = TextEditingController(text: '2');
  final _garageController = TextEditingController(text: '2');
  final _outdoorController = TextEditingController(text: '2');

  String _protectionType = 'outlet';
  bool _includeBasement = false;

  int? _gfciOutlets;
  int? _gfciBreakers;
  int? _regularOutlets;
  String? _locationList;

  @override
  void dispose() { _kitchenCounterController.dispose(); _bathroomController.dispose(); _garageController.dispose(); _outdoorController.dispose(); super.dispose(); }

  void _calculate() {
    final kitchenCounter = int.tryParse(_kitchenCounterController.text) ?? 4;
    final bathroom = int.tryParse(_bathroomController.text) ?? 2;
    final garage = int.tryParse(_garageController.text) ?? 2;
    final outdoor = int.tryParse(_outdoorController.text) ?? 2;
    final basement = _includeBasement ? 2 : 0;

    // Total outlets requiring GFCI protection
    final totalGfciLocations = kitchenCounter + bathroom + garage + outdoor + basement;

    int gfciOutlets;
    int gfciBreakers;
    int regularOutlets;

    if (_protectionType == 'outlet') {
      // Each location gets GFCI outlet (or first in chain)
      // Typically 1 GFCI can protect downstream outlets
      gfciOutlets = ((kitchenCounter / 2).ceil() + // Kitchen: 1 per 2 outlets
          bathroom + // Bathrooms: 1 each
          (garage / 2).ceil() + // Garage: 1 per 2
          outdoor + // Outdoor: 1 each
          (basement / 2).ceil()); // Basement: 1 per 2
      gfciBreakers = 0;
      regularOutlets = totalGfciLocations - gfciOutlets;
    } else {
      // GFCI breakers: 1 per circuit
      gfciBreakers = 5; // Typical: kitchen (2), bath, garage, outdoor
      if (_includeBasement) gfciBreakers += 1;
      gfciOutlets = 0;
      regularOutlets = totalGfciLocations;
    }

    final locationList = 'Kitchen counters, bathrooms, garage, outdoor, laundry, ${_includeBasement ? "basement, " : ""}within 6\' of water';

    setState(() { _gfciOutlets = gfciOutlets; _gfciBreakers = gfciBreakers; _regularOutlets = regularOutlets; _locationList = locationList; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _kitchenCounterController.text = '4'; _bathroomController.text = '2'; _garageController.text = '2'; _outdoorController.text = '2'; setState(() { _protectionType = 'outlet'; _includeBasement = false; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('GFCI Outlet', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'PROTECTION TYPE', ['outlet', 'breaker'], _protectionType, {'outlet': 'GFCI Outlets', 'breaker': 'GFCI Breakers'}, (v) { setState(() => _protectionType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildToggle(colors, 'Include Unfinished Basement', _includeBasement, (v) { setState(() => _includeBasement = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Kitchen Counter', unit: 'qty', controller: _kitchenCounterController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Bathroom', unit: 'qty', controller: _bathroomController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Garage', unit: 'qty', controller: _garageController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Outdoor', unit: 'qty', controller: _outdoorController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_gfciOutlets != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                if (_protectionType == 'outlet') ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('GFCI OUTLETS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_gfciOutlets', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                ] else ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('GFCI BREAKERS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_gfciBreakers', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                ],
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Regular Outlets', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_regularOutlets', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('NEC requires GFCI: $_locationList.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildRequirementsTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildToggle(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onChanged(!value); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.borderSubtle)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Icon(value ? LucideIcons.checkSquare : LucideIcons.square, color: value ? colors.accentPrimary : colors.textSecondary, size: 20),
        ]),
      ),
    );
  }

  Widget _buildRequirementsTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('NEC GFCI REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Bathrooms', 'All outlets'),
        _buildTableRow(colors, 'Kitchen', 'Counter outlets'),
        _buildTableRow(colors, 'Garage', 'All 125V outlets'),
        _buildTableRow(colors, 'Outdoor', 'All outlets'),
        _buildTableRow(colors, 'Basement', 'Unfinished areas'),
        _buildTableRow(colors, 'Laundry', 'Within 6\' of sink'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
