import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Load Range Calculator - Tire load capacity lookup
class LoadRangeScreen extends ConsumerStatefulWidget {
  const LoadRangeScreen({super.key});
  @override
  ConsumerState<LoadRangeScreen> createState() => _LoadRangeScreenState();
}

class _LoadRangeScreenState extends ConsumerState<LoadRangeScreen> {
  final _loadIndexController = TextEditingController();
  final _tireCountController = TextEditingController(text: '4');

  double? _loadPerTire;
  double? _totalLoad;

  // Load index to pounds lookup table
  final Map<int, int> _loadTable = {
    70: 739, 71: 761, 72: 783, 73: 805, 74: 827,
    75: 853, 76: 882, 77: 908, 78: 937, 79: 963,
    80: 992, 81: 1019, 82: 1047, 83: 1074, 84: 1102,
    85: 1135, 86: 1168, 87: 1201, 88: 1235, 89: 1279,
    90: 1323, 91: 1356, 92: 1389, 93: 1433, 94: 1477,
    95: 1521, 96: 1565, 97: 1609, 98: 1653, 99: 1709,
    100: 1764, 101: 1819, 102: 1874, 103: 1929, 104: 1984,
    105: 2039, 106: 2094, 107: 2149, 108: 2205, 109: 2271,
    110: 2337, 111: 2403, 112: 2469, 113: 2535, 114: 2601,
    115: 2679, 116: 2756, 117: 2833, 118: 2910, 119: 2998,
    120: 3086, 121: 3197, 122: 3307, 123: 3417, 124: 3527,
    125: 3638, 126: 3748, 127: 3858, 128: 3968, 129: 4079,
  };

  void _calculate() {
    final loadIndex = int.tryParse(_loadIndexController.text);
    final tireCount = int.tryParse(_tireCountController.text) ?? 4;

    if (loadIndex == null || !_loadTable.containsKey(loadIndex)) {
      setState(() { _loadPerTire = null; });
      return;
    }

    final perTire = _loadTable[loadIndex]!.toDouble();
    setState(() {
      _loadPerTire = perTire;
      _totalLoad = perTire * tireCount;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _loadIndexController.clear();
    _tireCountController.text = '4';
    setState(() { _loadPerTire = null; });
  }

  @override
  void dispose() {
    _loadIndexController.dispose();
    _tireCountController.dispose();
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
        title: Text('Load Range', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Load Index', unit: 'index', hint: 'e.g. 94 (from tire)', controller: _loadIndexController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Number of Tires', unit: 'tires', hint: '4 for car, 6 for dually', controller: _tireCountController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_loadPerTire != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildLoadRangeCard(colors),
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
        Text('Load Index = Max weight per tire', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Found on tire sidewall after size (e.g. 225/45R17 94W)', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Load Per Tire', '${_loadPerTire!.toStringAsFixed(0)} lbs', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Total Vehicle Load', '${_totalLoad!.toStringAsFixed(0)} lbs'),
      ]),
    );
  }

  Widget _buildLoadRangeCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('LIGHT TRUCK LOAD RANGES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildLoadRangeRow(colors, 'C (6-ply)', '35 psi max'),
        _buildLoadRangeRow(colors, 'D (8-ply)', '65 psi max'),
        _buildLoadRangeRow(colors, 'E (10-ply)', '80 psi max'),
        _buildLoadRangeRow(colors, 'F (12-ply)', '95 psi max'),
      ]),
    );
  }

  Widget _buildLoadRangeRow(ZaftoColors colors, String range, String pressure) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(range, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        Text(pressure, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
