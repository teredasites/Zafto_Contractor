import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Cycle Life Estimator Calculator - Battery lifespan projection
class CycleLifeEstimatorScreen extends ConsumerStatefulWidget {
  const CycleLifeEstimatorScreen({super.key});
  @override
  ConsumerState<CycleLifeEstimatorScreen> createState() => _CycleLifeEstimatorScreenState();
}

class _CycleLifeEstimatorScreenState extends ConsumerState<CycleLifeEstimatorScreen> {
  final _cyclesPerDayController = TextEditingController(text: '1');
  final _warrantyYearsController = TextEditingController(text: '10');
  final _warrantyCyclesController = TextEditingController(text: '4000');

  String _batteryType = 'Lithium-Ion';

  double? _annualCycles;
  double? _yearsAtRate;
  double? _remainingAfterWarranty;
  String? _recommendation;

  @override
  void dispose() {
    _cyclesPerDayController.dispose();
    _warrantyYearsController.dispose();
    _warrantyCyclesController.dispose();
    super.dispose();
  }

  void _calculate() {
    final cyclesPerDay = double.tryParse(_cyclesPerDayController.text);
    final warrantyYears = double.tryParse(_warrantyYearsController.text);
    final warrantyCycles = double.tryParse(_warrantyCyclesController.text);

    if (cyclesPerDay == null || warrantyYears == null || warrantyCycles == null || cyclesPerDay == 0) {
      setState(() {
        _annualCycles = null;
        _yearsAtRate = null;
        _remainingAfterWarranty = null;
        _recommendation = null;
      });
      return;
    }

    final annualCycles = cyclesPerDay * 365;
    final yearsAtRate = warrantyCycles / annualCycles;
    final cyclesAtWarrantyEnd = warrantyYears * annualCycles;
    final remainingAfterWarranty = ((warrantyCycles - cyclesAtWarrantyEnd) / warrantyCycles * 100).clamp(0, 100);

    String recommendation;
    if (yearsAtRate > warrantyYears * 1.5) {
      recommendation = 'Excellent - battery should last well beyond warranty.';
    } else if (yearsAtRate > warrantyYears) {
      recommendation = 'Good - expect full warranty period with margin.';
    } else if (yearsAtRate > warrantyYears * 0.7) {
      recommendation = 'Marginal - may approach cycle limit near warranty end.';
    } else {
      recommendation = 'Heavy use - consider reducing cycles or larger battery.';
    }

    setState(() {
      _annualCycles = annualCycles;
      _yearsAtRate = yearsAtRate;
      _remainingAfterWarranty = remainingAfterWarranty.toDouble();
      _recommendation = recommendation;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _cyclesPerDayController.text = '1';
    _warrantyYearsController.text = '10';
    _warrantyCyclesController.text = '4000';
    setState(() => _batteryType = 'Lithium-Ion');
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Cycle Life', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary),
            onPressed: _clearAll,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'USAGE PATTERN'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Cycles Per Day',
                unit: 'cycles',
                hint: 'Avg full cycles',
                controller: _cyclesPerDayController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'WARRANTY TERMS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Warranty Years',
                      unit: 'yrs',
                      hint: 'Duration',
                      controller: _warrantyYearsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Warranty Cycles',
                      unit: 'cycles',
                      hint: 'Max cycles',
                      controller: _warrantyCyclesController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_yearsAtRate != null) ...[
                _buildSectionHeader(colors, 'LIFESPAN PROJECTION'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildWarrantyComparison(colors),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.repeat, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Battery Cycle Life',
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Estimate battery lifespan based on cycling pattern',
            style: TextStyle(color: colors.textTertiary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(
      title,
      style: TextStyle(
        color: colors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isHealthy = _yearsAtRate! > double.parse(_warrantyYearsController.text);
    final statusColor = isHealthy ? colors.accentSuccess : colors.accentWarning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Expected Lifespan', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _yearsAtRate!.toStringAsFixed(1),
                style: TextStyle(color: statusColor, fontSize: 48, fontWeight: FontWeight.w700),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  ' years',
                  style: TextStyle(color: colors.textSecondary, fontSize: 20),
                ),
              ),
            ],
          ),
          Text(
            'at ${_annualCycles!.toStringAsFixed(0)} cycles/year',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(isHealthy ? LucideIcons.checkCircle : LucideIcons.alertTriangle, size: 16, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _recommendation!,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarrantyComparison(ZaftoColors colors) {
    final warrantyYears = double.tryParse(_warrantyYearsController.text) ?? 10;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WARRANTY ANALYSIS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildCompareRow(colors, 'Warranty Period', '$warrantyYears years'),
          _buildCompareRow(colors, 'Est. Cycle Life', '${_yearsAtRate!.toStringAsFixed(1)} years'),
          _buildCompareRow(colors, 'Cycles at Warranty End', '${(_annualCycles! * warrantyYears).toStringAsFixed(0)}'),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Remaining Capacity', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text('~${_remainingAfterWarranty!.toStringAsFixed(0)}%',
                  style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Most warranties guarantee 70-80% capacity at end of term.',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildCompareRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
