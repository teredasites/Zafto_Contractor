import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Muffler Calculator - Size and select muffler for application
class MufflerScreen extends ConsumerStatefulWidget {
  const MufflerScreen({super.key});
  @override
  ConsumerState<MufflerScreen> createState() => _MufflerScreenState();
}

class _MufflerScreenState extends ConsumerState<MufflerScreen> {
  final _horsepowerController = TextEditingController();
  final _exhaustDiaController = TextEditingController();

  String? _recommendation;
  String? _soundLevel;

  void _calculate() {
    final horsepower = double.tryParse(_horsepowerController.text);
    final exhaustDia = double.tryParse(_exhaustDiaController.text);

    if (horsepower == null) {
      setState(() { _recommendation = null; });
      return;
    }

    String recommendation;
    String soundLevel;

    if (horsepower < 250) {
      recommendation = 'Small chambered muffler or turbo-style';
      soundLevel = 'Quiet to moderate';
    } else if (horsepower < 400) {
      recommendation = 'Medium performance muffler';
      soundLevel = 'Moderate - sporty';
    } else if (horsepower < 600) {
      recommendation = 'Large performance or straight-through design';
      soundLevel = 'Aggressive';
    } else {
      recommendation = 'Race muffler or straight-through with large case';
      soundLevel = 'Very aggressive';
    }

    // Adjust for exhaust diameter
    if (exhaustDia != null) {
      if (exhaustDia < 2.25) {
        recommendation += '\nNote: Exhaust may be undersized for power level';
      } else if (exhaustDia > 3.5 && horsepower < 400) {
        recommendation += '\nNote: Large exhaust may reduce low-end torque';
      }
    }

    setState(() {
      _recommendation = recommendation;
      _soundLevel = soundLevel;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _horsepowerController.clear();
    _exhaustDiaController.clear();
    setState(() { _recommendation = null; });
  }

  @override
  void dispose() {
    _horsepowerController.dispose();
    _exhaustDiaController.dispose();
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
        title: Text('Muffler Selection', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildInfoCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Horsepower', unit: 'hp', hint: 'Target HP', controller: _horsepowerController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Exhaust Diameter', unit: 'in', hint: 'Pipe size', controller: _exhaustDiaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_recommendation != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildMufflerTypes(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Muffler Sizing Guide', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Select muffler based on power level and sound preference', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('RECOMMENDATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Text(_recommendation!, style: TextStyle(color: colors.textPrimary, fontSize: 14), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(LucideIcons.volume2, color: colors.accentPrimary, size: 18),
            const SizedBox(width: 8),
            Text('Sound: $_soundLevel', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildMufflerTypes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MUFFLER TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTypeRow(colors, 'Chambered', 'Classic muscle car sound, good flow'),
        _buildTypeRow(colors, 'Turbo-Style', 'Quiet, uses baffles/packing'),
        _buildTypeRow(colors, 'Straight-Through', 'Best flow, louder, performance'),
        _buildTypeRow(colors, 'Resonator', 'Cancels drone, use with muffler'),
        const SizedBox(height: 12),
        Text('Dual mufflers vs single: Sound preference, dual is quieter per HP', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildTypeRow(ZaftoColors colors, String type, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(type, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
