import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fluid Capacity Calculator - Transmission fluid capacity estimator
class FluidCapacityScreen extends ConsumerStatefulWidget {
  const FluidCapacityScreen({super.key});
  @override
  ConsumerState<FluidCapacityScreen> createState() => _FluidCapacityScreenState();
}

class _FluidCapacityScreenState extends ConsumerState<FluidCapacityScreen> {
  final _panCapacityController = TextEditingController();
  final _converterCapacityController = TextEditingController();
  final _coolerLineController = TextEditingController(text: '1.0');

  String _transType = 'auto';
  String _serviceType = 'drain';

  double? _serviceAmount;
  double? _totalCapacity;
  String? _recommendation;

  void _calculate() {
    final panCapacity = double.tryParse(_panCapacityController.text);
    final converterCapacity = double.tryParse(_converterCapacityController.text);
    final coolerLine = double.tryParse(_coolerLineController.text) ?? 1.0;

    if (panCapacity == null) {
      setState(() { _serviceAmount = null; });
      return;
    }

    double total;
    double service;
    String recommendation;

    if (_transType == 'manual') {
      // Manual trans - simpler calculation
      total = panCapacity;
      service = panCapacity;
      recommendation = 'Drain and fill with manufacturer-spec gear oil (75W-90 or spec)';
    } else {
      // Automatic trans
      total = panCapacity + (converterCapacity ?? 0) + coolerLine;

      switch (_serviceType) {
        case 'drain':
          // Pan drop only gets ~40-50% of total
          service = panCapacity;
          recommendation = 'Pan drop service - replace filter, refill with ATF. May need 2-3 services for complete fluid exchange.';
          break;
        case 'flush':
          // Full flush replaces all fluid
          service = total * 1.1; // Slight overage for flush
          recommendation = 'Full flush exchanges all fluid. Use only if trans is in good condition.';
          break;
        case 'converter':
          // Converter drain adds converter capacity
          service = panCapacity + (converterCapacity ?? panCapacity * 0.6);
          recommendation = 'Drain pan + converter for more complete service. Requires converter drain plug.';
          break;
        default:
          service = panCapacity;
          recommendation = 'Standard drain and fill service';
      }
    }

    setState(() {
      _serviceAmount = service;
      _totalCapacity = total;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _panCapacityController.clear();
    _converterCapacityController.clear();
    _coolerLineController.text = '1.0';
    setState(() {
      _transType = 'auto';
      _serviceType = 'drain';
      _serviceAmount = null;
    });
  }

  @override
  void dispose() {
    _panCapacityController.dispose();
    _converterCapacityController.dispose();
    _coolerLineController.dispose();
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
        title: Text('Fluid Capacity', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildTransTypeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Pan/Case Capacity', unit: 'qts', hint: 'e.g. 4', controller: _panCapacityController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            if (_transType == 'auto') ...[
              ZaftoInputField(label: 'Torque Converter Capacity', unit: 'qts', hint: 'e.g. 3', controller: _converterCapacityController, onChanged: (_) => _calculate()),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Cooler Lines', unit: 'qts', hint: 'Usually 0.5-1.5', controller: _coolerLineController, onChanged: (_) => _calculate()),
              const SizedBox(height: 16),
              _buildServiceTypeSelector(colors),
            ],
            const SizedBox(height: 32),
            if (_serviceAmount != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTransTypeSelector(ZaftoColors colors) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Transmission Type', style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Row(children: [
        _buildTypeChip(colors, 'auto', 'Automatic', true),
        const SizedBox(width: 8),
        _buildTypeChip(colors, 'manual', 'Manual', true),
      ]),
    ]);
  }

  Widget _buildServiceTypeSelector(ZaftoColors colors) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Service Type', style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _buildTypeChip(colors, 'drain', 'Pan Drain', false),
        _buildTypeChip(colors, 'converter', 'Converter Drain', false),
        _buildTypeChip(colors, 'flush', 'Full Flush', false),
      ]),
    ]);
  }

  Widget _buildTypeChip(ZaftoColors colors, String value, String label, bool isTransType) {
    final isSelected = isTransType ? _transType == value : _serviceType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isTransType) {
            _transType = value;
          } else {
            _serviceType = value;
          }
        });
        _calculate();
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
        Text('Total = Pan + Converter + Lines', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Pan drain only replaces ~40-50% of total fluid', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Fluid Needed', '${_serviceAmount!.toStringAsFixed(1)} qts', isPrimary: true),
        if (_transType == 'auto') ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Total System Capacity', '${_totalCapacity!.toStringAsFixed(1)} qts'),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Text('Always verify fluid level with engine running, trans in Park', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          ]),
        ),
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
