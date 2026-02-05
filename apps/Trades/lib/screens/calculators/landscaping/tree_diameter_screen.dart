import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Tree Diameter Calculator - DBH and circumference
class TreeDiameterScreen extends ConsumerStatefulWidget {
  const TreeDiameterScreen({super.key});
  @override
  ConsumerState<TreeDiameterScreen> createState() => _TreeDiameterScreenState();
}

class _TreeDiameterScreenState extends ConsumerState<TreeDiameterScreen> {
  final _circumferenceController = TextEditingController(text: '48');

  double? _dbh;
  double? _radius;
  String? _treeClass;

  @override
  void dispose() { _circumferenceController.dispose(); super.dispose(); }

  void _calculate() {
    final circumference = double.tryParse(_circumferenceController.text) ?? 48;

    // DBH = circumference / π
    final dbh = circumference / 3.14159;
    final radius = dbh / 2;

    // Tree size class
    String treeClass;
    if (dbh < 6) {
      treeClass = 'Small (sapling)';
    } else if (dbh < 12) {
      treeClass = 'Medium';
    } else if (dbh < 24) {
      treeClass = 'Large';
    } else if (dbh < 36) {
      treeClass = 'Very large';
    } else {
      treeClass = 'Specimen/Heritage';
    }

    setState(() {
      _dbh = dbh;
      _radius = radius;
      _treeClass = treeClass;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _circumferenceController.text = '48'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Tree Diameter', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('HOW TO MEASURE', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Wrap tape measure around trunk at 4.5 feet (breast height) above ground.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ]),
            ),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Circumference at DBH', unit: 'inches', controller: _circumferenceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_dbh != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('DIAMETER (DBH)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_dbh!.toStringAsFixed(1)}"', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Radius', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_radius!.toStringAsFixed(1)}"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Size class', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_treeClass!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTreeGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTreeGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TREE SIZE CLASSES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Small/Sapling', '< 6" DBH'),
        _buildTableRow(colors, 'Medium', '6-12" DBH'),
        _buildTableRow(colors, 'Large', '12-24" DBH'),
        _buildTableRow(colors, 'Very large', '24-36" DBH'),
        _buildTableRow(colors, 'Specimen', '> 36" DBH'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildTableRow(colors, 'DBH', 'Diameter at Breast Height'),
        _buildTableRow(colors, 'Measured', '4.5 ft above ground'),
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
