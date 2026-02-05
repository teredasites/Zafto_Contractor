import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Newel Post Calculator - Stair post estimation
class NewelPostScreen extends ConsumerStatefulWidget {
  const NewelPostScreen({super.key});
  @override
  ConsumerState<NewelPostScreen> createState() => _NewelPostScreenState();
}

class _NewelPostScreenState extends ConsumerState<NewelPostScreen> {
  final _flightsController = TextEditingController(text: '1');
  final _landingsController = TextEditingController(text: '0');

  String _style = 'box';
  bool _hasVolute = false;

  int? _startingNewels;
  int? _landingNewels;
  int? _totalNewels;
  int? _caps;

  @override
  void dispose() { _flightsController.dispose(); _landingsController.dispose(); super.dispose(); }

  void _calculate() {
    final flights = int.tryParse(_flightsController.text) ?? 1;
    final landings = int.tryParse(_landingsController.text) ?? 0;

    // Starting newels: 1 per flight bottom (or volute)
    final startingNewels = _hasVolute ? 0 : flights;

    // Landing newels: 2 per landing (turning point)
    final landingNewels = landings * 2;

    // Top newels: 1 per flight
    final topNewels = flights;

    final totalNewels = startingNewels + landingNewels + topNewels;

    // Caps depend on style
    int caps;
    switch (_style) {
      case 'box':
        caps = totalNewels; // Each gets a cap
        break;
      case 'turned':
        caps = 0; // Built-in finial
        break;
      case 'modern':
        caps = totalNewels; // Flat caps
        break;
      default:
        caps = totalNewels;
    }

    setState(() { _startingNewels = startingNewels; _landingNewels = landingNewels; _totalNewels = totalNewels; _caps = caps; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _flightsController.text = '1'; _landingsController.text = '0'; setState(() { _style = 'box'; _hasVolute = false; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Newel Posts', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Stair Flights', unit: 'qty', controller: _flightsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Landings', unit: 'qty', controller: _landingsController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 16),
            _buildToggle(colors, 'Volute/Turnout Start', _hasVolute, (v) { setState(() => _hasVolute = v); _calculate(); }),
            const SizedBox(height: 32),
            if (_totalNewels != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL NEWELS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_totalNewels', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                if (!_hasVolute) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Starting Newels', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_startingNewels', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                  const SizedBox(height: 8),
                ],
                if (_hasVolute) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Volute/Turnout', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('1', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                  const SizedBox(height: 8),
                ],
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Landing Newels', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_landingNewels', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Newel Caps', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_caps', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Starting newels are larger (box) or decorative (volute). Landing newels can be box or turned.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTypeTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['box', 'turned', 'modern'];
    final labels = {'box': 'Box Newel', 'turned': 'Turned', 'modern': 'Modern'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('STYLE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _style == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _style = o); _calculate(); },
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(color: value ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: value ? colors.accentPrimary : colors.borderSubtle)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14))),
          Icon(value ? LucideIcons.checkSquare : LucideIcons.square, size: 20, color: value ? colors.accentPrimary : colors.textTertiary),
        ]),
      ),
    );
  }

  Widget _buildTypeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('NEWEL TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Box newel', '4-6\" square'),
        _buildTableRow(colors, 'Turned newel', '3-4\" base'),
        _buildTableRow(colors, 'Starting newel', 'Larger, ornate'),
        _buildTableRow(colors, 'Landing newel', 'Match starting'),
        _buildTableRow(colors, 'Volute', 'Spiral handrail start'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
