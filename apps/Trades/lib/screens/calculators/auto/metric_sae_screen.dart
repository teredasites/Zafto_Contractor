import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Metric SAE Calculator - Socket/wrench size conversion
class MetricSaeScreen extends ConsumerStatefulWidget {
  const MetricSaeScreen({super.key});
  @override
  ConsumerState<MetricSaeScreen> createState() => _MetricSaeScreenState();
}

class _MetricSaeScreenState extends ConsumerState<MetricSaeScreen> {
  final _sizeController = TextEditingController();
  String _fromUnit = 'metric';

  double? _convertedSize;
  String? _closestStandard;

  final List<double> _metricSizes = [4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 24, 27, 30, 32, 36];
  final List<double> _saeSizes = [5/32, 3/16, 7/32, 1/4, 9/32, 5/16, 11/32, 3/8, 7/16, 1/2, 9/16, 5/8, 11/16, 3/4, 13/16, 7/8, 15/16, 1.0, 1+1/16, 1+1/8, 1+1/4, 1+5/16];
  final List<String> _saeLabels = ['5/32"', '3/16"', '7/32"', '1/4"', '9/32"', '5/16"', '11/32"', '3/8"', '7/16"', '1/2"', '9/16"', '5/8"', '11/16"', '3/4"', '13/16"', '7/8"', '15/16"', '1"', '1-1/16"', '1-1/8"', '1-1/4"', '1-5/16"'];

  void _calculate() {
    final size = double.tryParse(_sizeController.text);

    if (size == null) {
      setState(() { _convertedSize = null; });
      return;
    }

    double converted;
    String closest;

    if (_fromUnit == 'metric') {
      // Metric to SAE (mm to inches)
      converted = size / 25.4;
      // Find closest SAE size
      double minDiff = double.infinity;
      int closestIndex = 0;
      for (int i = 0; i < _saeSizes.length; i++) {
        final diff = (converted - _saeSizes[i]).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closestIndex = i;
        }
      }
      closest = _saeLabels[closestIndex];
    } else {
      // SAE to metric (inches to mm)
      converted = size * 25.4;
      // Find closest metric size
      double minDiff = double.infinity;
      double closestMetric = 10;
      for (final m in _metricSizes) {
        final diff = (converted - m).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closestMetric = m;
        }
      }
      closest = '${closestMetric.toStringAsFixed(0)}mm';
    }

    setState(() {
      _convertedSize = converted;
      _closestStandard = closest;
    });
  }

  @override
  void dispose() {
    _sizeController.dispose();
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
        title: Text('Metric / SAE', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildUnitSelector(colors),
            const SizedBox(height: 24),
            ZaftoInputField(
              label: _fromUnit == 'metric' ? 'Metric Size' : 'SAE Size',
              unit: _fromUnit == 'metric' ? 'mm' : 'in',
              hint: 'Enter size',
              controller: _sizeController,
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 32),
            if (_convertedSize != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildQuickReference(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildUnitSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CONVERT FROM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildUnitOption(colors, 'metric', 'Metric (mm)')),
          const SizedBox(width: 12),
          Expanded(child: _buildUnitOption(colors, 'sae', 'SAE (inches)')),
        ]),
      ]),
    );
  }

  Widget _buildUnitOption(ZaftoColors colors, String value, String label) {
    final isSelected = _fromUnit == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _fromUnit = value;
          _sizeController.clear();
          _convertedSize = null;
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

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('CONVERSION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(_fromUnit == 'metric' ? '${_convertedSize!.toStringAsFixed(3)}"' : '${_convertedSize!.toStringAsFixed(2)}mm', style: TextStyle(color: colors.accentPrimary, fontSize: 40, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text('CLOSEST STANDARD SIZE', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(_closestStandard!, style: TextStyle(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildQuickReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON EQUIVALENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildEquivRow(colors, '10mm', '3/8"'),
        _buildEquivRow(colors, '13mm', '1/2"'),
        _buildEquivRow(colors, '14mm', '9/16"'),
        _buildEquivRow(colors, '17mm', '11/16"'),
        _buildEquivRow(colors, '19mm', '3/4"'),
        _buildEquivRow(colors, '22mm', '7/8"'),
        const SizedBox(height: 8),
        Text('Note: These are close but not exact matches.', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildEquivRow(ZaftoColors colors, String metric, String sae) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(metric, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text('≈', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
        Text(sae, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
    );
  }
}
