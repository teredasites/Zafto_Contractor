import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// CC/CI/Liter Converter - Engine displacement unit conversion
class CcConverterScreen extends ConsumerStatefulWidget {
  const CcConverterScreen({super.key});
  @override
  ConsumerState<CcConverterScreen> createState() => _CcConverterScreenState();
}

class _CcConverterScreenState extends ConsumerState<CcConverterScreen> {
  final _ccController = TextEditingController();
  final _ciController = TextEditingController();
  final _literController = TextEditingController();

  bool _isUpdating = false;

  void _updateFromCc(String value) {
    if (_isUpdating) return;
    _isUpdating = true;
    final cc = double.tryParse(value);
    if (cc != null) {
      _ciController.text = (cc / 16.387).toStringAsFixed(1);
      _literController.text = (cc / 1000).toStringAsFixed(2);
    }
    _isUpdating = false;
  }

  void _updateFromCi(String value) {
    if (_isUpdating) return;
    _isUpdating = true;
    final ci = double.tryParse(value);
    if (ci != null) {
      _ccController.text = (ci * 16.387).toStringAsFixed(0);
      _literController.text = (ci * 0.016387).toStringAsFixed(2);
    }
    _isUpdating = false;
  }

  void _updateFromLiter(String value) {
    if (_isUpdating) return;
    _isUpdating = true;
    final liter = double.tryParse(value);
    if (liter != null) {
      _ccController.text = (liter * 1000).toStringAsFixed(0);
      _ciController.text = (liter * 61.024).toStringAsFixed(1);
    }
    _isUpdating = false;
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _ccController.clear();
    _ciController.clear();
    _literController.clear();
  }

  @override
  void dispose() {
    _ccController.dispose();
    _ciController.dispose();
    _literController.dispose();
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
        title: Text('CC Converter', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Cubic Centimeters', unit: 'cc', hint: 'e.g. 5700', controller: _ccController, onChanged: _updateFromCc),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Cubic Inches', unit: 'ci', hint: 'e.g. 350', controller: _ciController, onChanged: _updateFromCi),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Liters', unit: 'L', hint: 'e.g. 5.7', controller: _literController, onChanged: _updateFromLiter),
            const SizedBox(height: 32),
            _buildReferenceCard(colors),
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
        Text('1 ci = 16.387 cc = 0.0164 L', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Enter any value to convert between units', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildReferenceCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON ENGINES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildRefRow(colors, 'Small Block 350', '350 ci / 5.7L'),
        _buildRefRow(colors, 'LS3 / L99', '376 ci / 6.2L'),
        _buildRefRow(colors, 'Coyote 5.0', '302 ci / 5.0L'),
        _buildRefRow(colors, 'HEMI 392', '392 ci / 6.4L'),
        _buildRefRow(colors, '2JZ-GTE', '183 ci / 3.0L'),
        _buildRefRow(colors, 'RB26DETT', '159 ci / 2.6L'),
      ]),
    );
  }

  Widget _buildRefRow(ZaftoColors colors, String engine, String size) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(engine, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(size, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
