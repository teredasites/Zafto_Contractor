import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Rectangular Pool Volume Calculator
class RectangularPoolVolumeScreen extends ConsumerStatefulWidget {
  const RectangularPoolVolumeScreen({super.key});
  @override
  ConsumerState<RectangularPoolVolumeScreen> createState() => _RectangularPoolVolumeScreenState();
}

class _RectangularPoolVolumeScreenState extends ConsumerState<RectangularPoolVolumeScreen> {
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _depthController = TextEditingController();

  double? _gallons;
  double? _liters;
  double? _cubicFeet;

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final depth = double.tryParse(_depthController.text);

    if (length == null || width == null || depth == null || length <= 0 || width <= 0 || depth <= 0) {
      setState(() { _gallons = null; });
      return;
    }

    // Volume = L × W × D (cubic feet)
    // 1 cubic foot = 7.48 gallons
    final cubicFeet = length * width * depth;
    final gallons = cubicFeet * 7.48;
    final liters = gallons * 3.785;

    setState(() {
      _cubicFeet = cubicFeet;
      _gallons = gallons;
      _liters = liters;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _lengthController.clear();
    _widthController.clear();
    _depthController.clear();
    setState(() { _gallons = null; });
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _depthController.dispose();
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
        title: Text('Rectangular Pool Volume', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Length', unit: 'ft', hint: 'Pool length', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Width', unit: 'ft', hint: 'Pool width', controller: _widthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Average Depth', unit: 'ft', hint: 'Average depth', controller: _depthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_gallons != null) _buildResultsCard(colors),
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
        Text('V = L × W × D × 7.48', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('7.48 gallons per cubic foot', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Pool Volume', '${_gallons!.toStringAsFixed(0)} gal', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Liters', '${_liters!.toStringAsFixed(0)} L'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Cubic Feet', '${_cubicFeet!.toStringAsFixed(1)} cu ft'),
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
