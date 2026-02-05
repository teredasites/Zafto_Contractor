import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Band Adjustment Calculator - Automatic transmission band adjustment specs
class BandAdjustmentScreen extends ConsumerStatefulWidget {
  const BandAdjustmentScreen({super.key});
  @override
  ConsumerState<BandAdjustmentScreen> createState() => _BandAdjustmentScreenState();
}

class _BandAdjustmentScreenState extends ConsumerState<BandAdjustmentScreen> {
  String _transFamily = 'chrysler';
  String _bandType = 'kickdown';

  Map<String, dynamic>? _specs;

  // Band adjustment specifications database
  final Map<String, Map<String, Map<String, dynamic>>> _bandSpecs = {
    'chrysler': {
      'kickdown': {
        'name': 'Kickdown (Front) Band',
        'torque': '72 in-lb',
        'backoff': '2.5 turns',
        'note': 'A727/A904/46RE/47RE - Accessible from outside case',
      },
      'lowreverse': {
        'name': 'Low-Reverse (Rear) Band',
        'torque': '72 in-lb',
        'backoff': '4 turns',
        'note': 'Requires pan removal for adjustment',
      },
    },
    'ford': {
      'intermediate': {
        'name': 'Intermediate Band',
        'torque': '120 in-lb',
        'backoff': '1.5 turns',
        'note': 'C4/C6 - External adjustment, driver side',
      },
      'lowreverse': {
        'name': 'Low-Reverse Band',
        'torque': '120 in-lb',
        'backoff': '3 turns',
        'note': 'C6 only - Rear servo, pan removal required',
      },
    },
    'gm': {
      'intermediate': {
        'name': 'Intermediate (2nd) Band',
        'torque': '30 in-lb',
        'backoff': '3 turns',
        'note': 'TH350/TH400 - External, passenger side',
      },
    },
    'aode': {
      'intermediate': {
        'name': 'Intermediate Band',
        'torque': '120 in-lb',
        'backoff': '2 turns',
        'note': 'AODE/4R70W - External access',
      },
      'overdrive': {
        'name': 'Overdrive Band',
        'torque': '120 in-lb',
        'backoff': '3 turns',
        'note': 'Requires pan removal',
      },
    },
  };

  void _updateSpecs() {
    final familySpecs = _bandSpecs[_transFamily];
    if (familySpecs != null && familySpecs.containsKey(_bandType)) {
      setState(() {
        _specs = familySpecs[_bandType];
      });
    } else {
      // Default to first available band type for this family
      if (familySpecs != null && familySpecs.isNotEmpty) {
        _bandType = familySpecs.keys.first;
        setState(() {
          _specs = familySpecs[_bandType];
        });
      } else {
        setState(() {
          _specs = null;
        });
      }
    }
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    setState(() {
      _transFamily = 'chrysler';
      _bandType = 'kickdown';
    });
    _updateSpecs();
  }

  @override
  void initState() {
    super.initState();
    _updateSpecs();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Band Adjustment', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildTransFamilySelector(colors),
            const SizedBox(height: 16),
            _buildBandTypeSelector(colors),
            const SizedBox(height: 32),
            if (_specs != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildProcedureCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTransFamilySelector(ZaftoColors colors) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Transmission Family', style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _buildChip(colors, 'chrysler', 'Chrysler/Mopar', true),
        _buildChip(colors, 'ford', 'Ford C4/C6', true),
        _buildChip(colors, 'gm', 'GM TH350/400', true),
        _buildChip(colors, 'aode', 'Ford AODE/4R70W', true),
      ]),
    ]);
  }

  Widget _buildBandTypeSelector(ZaftoColors colors) {
    final familySpecs = _bandSpecs[_transFamily];
    if (familySpecs == null) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Band Selection', style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: familySpecs.keys.map((key) {
        final spec = familySpecs[key]!;
        return _buildChip(colors, key, spec['name'] as String, false);
      }).toList()),
    ]);
  }

  Widget _buildChip(ZaftoColors colors, String value, String label, bool isFamily) {
    final isSelected = isFamily ? _transFamily == value : _bandType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isFamily) {
            _transFamily = value;
          } else {
            _bandType = value;
          }
        });
        _updateSpecs();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? colors.bgBase : colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Torque to Spec → Back Off Turns', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Always torque first, then back off specified turns', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text(_specs!['name'], style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'Initial Torque', _specs!['torque'], isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Back Off', _specs!['backoff']),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_specs!['note'], style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _buildProcedureCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Adjustment Procedure', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _buildStep(colors, '1', 'Loosen locknut while holding adjuster screw'),
        _buildStep(colors, '2', 'Torque adjuster screw to specified in-lb'),
        _buildStep(colors, '3', 'Back off adjuster screw specified turns'),
        _buildStep(colors, '4', 'Hold adjuster and tighten locknut'),
        _buildStep(colors, '5', 'Verify adjuster did not move during locknut torque'),
        const SizedBox(height: 12),
        Text('Warning: Over-tightening causes band drag and premature wear. Under-tightening causes slipping.',
          style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildStep(ZaftoColors colors, String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(num, style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
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
