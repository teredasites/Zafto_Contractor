import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fastener Torque Calculator - General fastener torque lookup
class FastenerTorqueScreen extends ConsumerStatefulWidget {
  const FastenerTorqueScreen({super.key});
  @override
  ConsumerState<FastenerTorqueScreen> createState() => _FastenerTorqueScreenState();
}

class _FastenerTorqueScreenState extends ConsumerState<FastenerTorqueScreen> {
  String _system = 'sae';
  String _grade = '8';

  final Map<String, Map<String, Map<String, String>>> _torqueSpecs = {
    'sae': {
      '5': {'1/4': '6-8', '5/16': '12-15', '3/8': '22-27', '7/16': '35-43', '1/2': '55-68', '9/16': '80-100', '5/8': '115-140', '3/4': '200-250'},
      '8': {'1/4': '10-12', '5/16': '20-24', '3/8': '35-42', '7/16': '55-65', '1/2': '85-100', '9/16': '125-150', '5/8': '175-210', '3/4': '320-380'},
    },
    'metric': {
      '8.8': {'M6': '7-9', 'M8': '18-22', 'M10': '35-43', 'M12': '65-75', 'M14': '100-115', 'M16': '155-180'},
      '10.9': {'M6': '10-12', 'M8': '25-30', 'M10': '50-60', 'M12': '90-105', 'M14': '145-165', 'M16': '220-255'},
      '12.9': {'M6': '12-14', 'M8': '30-36', 'M10': '60-72', 'M12': '110-125', 'M14': '175-200', 'M16': '270-310'},
    },
  };

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Fastener Torque', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSystemSelector(colors),
            const SizedBox(height: 24),
            _buildGradeSelector(colors),
            const SizedBox(height: 24),
            _buildTorqueTable(colors),
            const SizedBox(height: 24),
            _buildGradeInfo(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSystemSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('FASTENER SYSTEM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildSystemOption(colors, 'sae', 'SAE (Inch)')),
          const SizedBox(width: 12),
          Expanded(child: _buildSystemOption(colors, 'metric', 'Metric')),
        ]),
      ]),
    );
  }

  Widget _buildSystemOption(ZaftoColors colors, String value, String label) {
    final isSelected = _system == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _system = value;
          _grade = value == 'sae' ? '8' : '10.9';
        });
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

  Widget _buildGradeSelector(ZaftoColors colors) {
    final grades = _system == 'sae' ? ['5', '8'] : ['8.8', '10.9', '12.9'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BOLT GRADE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: grades.map((g) => _buildGradeChip(colors, g)).toList()),
      ]),
    );
  }

  Widget _buildGradeChip(ZaftoColors colors, String grade) {
    final isSelected = _grade == grade;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() { _grade = grade; });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
        ),
        child: Text('Grade $grade', style: TextStyle(color: isSelected ? colors.bgBase : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildTorqueTable(ZaftoColors colors) {
    final specs = _torqueSpecs[_system]![_grade]!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TORQUE VALUES (ft-lbs)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        ...specs.entries.map((e) => _buildTorqueRow(colors, e.key, e.value)),
      ]),
    );
  }

  Widget _buildTorqueRow(ZaftoColors colors, String size, String torque) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(6)),
          child: Text(size, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        Text('$torque ft-lbs', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildGradeInfo(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('GRADE IDENTIFICATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        if (_system == 'sae') ...[
          Text('Grade 5: 3 radial lines on head', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('Grade 8: 6 radial lines on head', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ] else ...[
          Text('8.8: Number marked on head', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('10.9: Number marked on head', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('12.9: Number marked on head', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('Values for dry threads. Lubricated threads reduce torque by 15-25%.', style: TextStyle(color: colors.warning, fontSize: 11)),
        ),
      ]),
    );
  }
}
