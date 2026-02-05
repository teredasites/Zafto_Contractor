import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Head Bolt Torque Calculator - Head bolt torque specifications
class HeadBoltTorqueScreen extends ConsumerStatefulWidget {
  const HeadBoltTorqueScreen({super.key});
  @override
  ConsumerState<HeadBoltTorqueScreen> createState() => _HeadBoltTorqueScreenState();
}

class _HeadBoltTorqueScreenState extends ConsumerState<HeadBoltTorqueScreen> {
  String _boltType = 'tty';
  String _boltSize = 'm11';

  final Map<String, Map<String, dynamic>> _boltSpecs = {
    'm10': {'size': 'M10', 'standard': '35-45 ft-lbs', 'tty': '25 ft-lbs + 90° + 90°'},
    'm11': {'size': 'M11', 'standard': '55-65 ft-lbs', 'tty': '30 ft-lbs + 90° + 90°'},
    'm12': {'size': 'M12', 'standard': '65-80 ft-lbs', 'tty': '40 ft-lbs + 90° + 90°'},
    '716': {'size': '7/16"', 'standard': '65-75 ft-lbs', 'tty': '35 ft-lbs + 90° + 90°'},
    '12': {'size': '1/2"', 'standard': '100-115 ft-lbs', 'tty': '50 ft-lbs + 90° + 90°'},
  };

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Head Bolt Torque', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildBoltTypeSelector(colors),
            const SizedBox(height: 24),
            _buildBoltSizeSelector(colors),
            const SizedBox(height: 24),
            _buildTorqueSpec(colors),
            const SizedBox(height: 24),
            _buildProcedure(colors),
            const SizedBox(height: 24),
            _buildWarnings(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildBoltTypeSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BOLT TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildTypeOption(colors, 'standard', 'Standard')),
          const SizedBox(width: 12),
          Expanded(child: _buildTypeOption(colors, 'tty', 'TTY (Stretch)')),
        ]),
        const SizedBox(height: 8),
        Text(_boltType == 'tty' ? 'Torque-To-Yield: One-time use, must replace' : 'Standard bolts can be reused if in good condition', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildTypeOption(ZaftoColors colors, String value, String label) {
    final isSelected = _boltType == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() { _boltType = value; });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? colors.bgBase : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildBoltSizeSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BOLT SIZE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _boltSpecs.keys.map((key) => _buildSizeChip(colors, key)).toList()),
      ]),
    );
  }

  Widget _buildSizeChip(ZaftoColors colors, String key) {
    final isSelected = _boltSize == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() { _boltSize = key; });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
        ),
        child: Text(_boltSpecs[key]!['size'], style: TextStyle(color: isSelected ? colors.bgBase : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildTorqueSpec(ZaftoColors colors) {
    final spec = _boltSpecs[_boltSize]!;
    final torque = _boltType == 'tty' ? spec['tty'] : spec['standard'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('TORQUE SPECIFICATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Text(torque, style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('${spec['size']} ${_boltType == 'tty' ? 'TTY' : 'Standard'} Bolt', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      ]),
    );
  }

  Widget _buildProcedure(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TORQUE SEQUENCE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('1. Hand-start all bolts', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('2. Snug in sequence from center out', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        if (_boltType == 'tty') ...[
          Text('3. Torque to initial spec in sequence', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('4. Turn additional degrees in sequence', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('5. Final angle turn in sequence', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ] else ...[
          Text('3. Torque to 50% spec in sequence', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('4. Torque to 75% spec in sequence', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('5. Final torque to full spec', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Always torque from center outward in spiral pattern', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildWarnings(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.warning.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.alertTriangle, color: colors.warning, size: 18),
          const SizedBox(width: 8),
          Text('IMPORTANT', style: TextStyle(color: colors.warning, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
        Text('• Always consult factory service manual', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• TTY bolts MUST be replaced - never reuse', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Clean threads and bolt holes', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Check for thread damage before install', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Use new head gasket', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
