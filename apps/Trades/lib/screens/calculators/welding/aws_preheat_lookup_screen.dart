import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// AWS Preheat Lookup - D1.1 Table 3.2 reference
class AwsPreheatLookupScreen extends ConsumerStatefulWidget {
  const AwsPreheatLookupScreen({super.key});
  @override
  ConsumerState<AwsPreheatLookupScreen> createState() => _AwsPreheatLookupScreenState();
}

class _AwsPreheatLookupScreenState extends ConsumerState<AwsPreheatLookupScreen> {
  final _thicknessController = TextEditingController();
  String _steelCategory = 'A36/A992';
  String _weldProcess = 'Low H2';

  int? _minPreheat;
  String? _steelGroup;
  String? _notes;
  List<Map<String, String>>? _tableData;

  // AWS D1.1 Table 3.2 preheat temperatures
  static const Map<String, Map<String, List<int>>> _preheatTable = {
    'A36/A992': {
      // [up to 3/4", 3/4-1.5", 1.5-2.5", >2.5"]
      'Low H2': [50, 50, 150, 225],
      'Non-Low H2': [50, 150, 225, 300],
    },
    'A572 Gr50': {
      'Low H2': [50, 50, 150, 225],
      'Non-Low H2': [50, 150, 225, 300],
    },
    'A588': {
      'Low H2': [50, 50, 200, 300],
      'Non-Low H2': [50, 200, 300, 400],
    },
    'A514/A517': {
      'Low H2': [50, 125, 175, 225],
      'Non-Low H2': [100, 200, 250, 300],
    },
    'A913 Gr65': {
      'Low H2': [50, 50, 150, 225],
      'Non-Low H2': [100, 150, 225, 300],
    },
  };

  void _calculate() {
    final thickness = double.tryParse(_thicknessController.text);

    final temps = _preheatTable[_steelCategory]?[_weldProcess] ?? [50, 50, 150, 225];

    int preheat;
    String range;
    if (thickness == null || thickness <= 0.75) {
      preheat = temps[0];
      range = 'Up to 3/4"';
    } else if (thickness <= 1.5) {
      preheat = temps[1];
      range = '3/4" to 1-1/2"';
    } else if (thickness <= 2.5) {
      preheat = temps[2];
      range = '1-1/2" to 2-1/2"';
    } else {
      preheat = temps[3];
      range = 'Over 2-1/2"';
    }

    // Generate table data
    final tableData = <Map<String, String>>[
      {'range': 'Up to 3/4"', 'temp': '${temps[0]}\u00B0F'},
      {'range': '3/4" - 1-1/2"', 'temp': '${temps[1]}\u00B0F'},
      {'range': '1-1/2" - 2-1/2"', 'temp': '${temps[2]}\u00B0F'},
      {'range': 'Over 2-1/2"', 'temp': '${temps[3]}\u00B0F'},
    ];

    String notes;
    if (_weldProcess == 'Low H2') {
      notes = 'Low hydrogen process (E70XX-H4/H8, FCAW with H4 designation)';
    } else {
      notes = 'Non-low hydrogen process (E6010, E6011, E7014, etc.)';
    }

    setState(() {
      _minPreheat = preheat;
      _steelGroup = '$_steelCategory - $range';
      _notes = notes;
      _tableData = tableData;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _thicknessController.clear();
    _calculate();
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _thicknessController.dispose();
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
        title: Text('AWS Preheat', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Steel Category', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildSteelSelector(colors),
            const SizedBox(height: 16),
            Text('Welding Process', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildProcessSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Thickness', unit: 'in', hint: 'Optional - defaults to lowest', controller: _thicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_minPreheat != null) _buildResultsCard(colors),
            const SizedBox(height: 16),
            if (_tableData != null) _buildTableCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSteelSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _preheatTable.keys.map((s) => ChoiceChip(
        label: Text(s, style: const TextStyle(fontSize: 11)),
        selected: _steelCategory == s,
        onSelected: (_) => setState(() { _steelCategory = s; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildProcessSelector(ZaftoColors colors) {
    final processes = ['Low H2', 'Non-Low H2'];
    return Wrap(
      spacing: 8,
      children: processes.map((p) => ChoiceChip(
        label: Text(p),
        selected: _weldProcess == p,
        onSelected: (_) => setState(() { _weldProcess = p; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('AWS D1.1 Table 3.2', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Prequalified minimum preheat temperatures', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Min Preheat', '$_minPreheat\u00B0F', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Steel/Range', _steelGroup!),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_notes!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _buildTableCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Full Table for $_steelCategory', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._tableData!.map((row) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(row['range']!, style: TextStyle(color: colors.textTertiary, fontSize: 13)),
                Text(row['temp']!, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Flexible(child: Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 14, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600), textAlign: TextAlign.right)),
    ]);
  }
}
