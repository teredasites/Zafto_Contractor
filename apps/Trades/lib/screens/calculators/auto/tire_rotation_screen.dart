import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Tire Rotation Pattern Guide - Correct rotation patterns by drivetrain
class TireRotationScreen extends ConsumerStatefulWidget {
  const TireRotationScreen({super.key});
  @override
  ConsumerState<TireRotationScreen> createState() => _TireRotationScreenState();
}

class _TireRotationScreenState extends ConsumerState<TireRotationScreen> {
  String _drivetrain = 'fwd';
  bool _directional = false;
  bool _staggered = false;

  String _getPattern() {
    if (_staggered) {
      return 'Side to Side Only\n\nFront stays front, rear stays rear.\nSwap left/right on each axle.';
    }
    if (_directional) {
      return 'Front to Rear Only\n\nKeep tires on same side.\nFront moves to rear, rear moves to front.';
    }
    switch (_drivetrain) {
      case 'fwd':
        return 'Forward Cross\n\nFront tires go straight back.\nRear tires cross to opposite front.';
      case 'rwd':
        return 'Rearward Cross\n\nRear tires go straight forward.\nFront tires cross to opposite rear.';
      case 'awd':
        return 'X-Pattern\n\nAll tires cross diagonally.\nFront-left to rear-right, etc.';
      default:
        return '';
    }
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    setState(() {
      _drivetrain = 'fwd';
      _directional = false;
      _staggered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Tire Rotation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildSectionHeader(colors, 'DRIVETRAIN'),
            const SizedBox(height: 12),
            _buildDrivetrainSelector(colors),
            const SizedBox(height: 20),
            _buildSectionHeader(colors, 'TIRE TYPE'),
            const SizedBox(height: 12),
            _buildToggle(colors, 'Directional Tires', _directional, (v) => setState(() => _directional = v)),
            const SizedBox(height: 8),
            _buildToggle(colors, 'Staggered (Different Front/Rear)', _staggered, (v) => setState(() => _staggered = v)),
            const SizedBox(height: 32),
            _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildIntervalCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildDrivetrainSelector(ZaftoColors colors) {
    return Row(children: [
      _buildDriveOption(colors, 'FWD', 'fwd'),
      const SizedBox(width: 8),
      _buildDriveOption(colors, 'RWD', 'rwd'),
      const SizedBox(width: 8),
      _buildDriveOption(colors, 'AWD/4WD', 'awd'),
    ]);
  }

  Widget _buildDriveOption(ZaftoColors colors, String label, String value) {
    final selected = _drivetrain == value;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _drivetrain = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colors.accentPrimary : colors.bgElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: selected ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600)),
      ),
    ));
  }

  Widget _buildToggle(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Container(
            width: 44, height: 24,
            decoration: BoxDecoration(color: value ? colors.accentPrimary : colors.borderSubtle, borderRadius: BorderRadius.circular(12)),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(width: 20, height: 20, margin: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Rotate every 5,000-7,500 miles', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Even wear extends tire life significantly', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ROTATION PATTERN', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text(_getPattern(), style: TextStyle(color: colors.textPrimary, fontSize: 15, height: 1.5)),
      ]),
    );
  }

  Widget _buildIntervalCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(LucideIcons.info, size: 16, color: colors.accentPrimary),
          const SizedBox(width: 8),
          Text('TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        ]),
        const SizedBox(height: 12),
        Text('- Rotate with every oil change\n- Check and adjust pressures after rotation\n- Inspect for uneven wear patterns\n- Include spare if full-size match', style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5)),
      ]),
    );
  }
}
