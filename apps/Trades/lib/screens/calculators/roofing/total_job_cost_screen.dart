import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Total Job Cost Calculator - Comprehensive roofing job cost estimator
class TotalJobCostScreen extends ConsumerStatefulWidget {
  const TotalJobCostScreen({super.key});
  @override
  ConsumerState<TotalJobCostScreen> createState() => _TotalJobCostScreenState();
}

class _TotalJobCostScreenState extends ConsumerState<TotalJobCostScreen> {
  final _roofSquaresController = TextEditingController(text: '25');
  final _materialCostController = TextEditingController(text: '350');
  final _laborRateController = TextEditingController(text: '75');
  final _hoursPerSquareController = TextEditingController(text: '1.5');
  final _disposalController = TextEditingController(text: '500');
  final _permitsController = TextEditingController(text: '250');
  final _markupController = TextEditingController(text: '25');

  bool _includeTearOff = true;

  double? _materialTotal;
  double? _laborTotal;
  double? _subtotal;
  double? _markup;
  double? _grandTotal;
  double? _perSquare;

  @override
  void dispose() {
    _roofSquaresController.dispose();
    _materialCostController.dispose();
    _laborRateController.dispose();
    _hoursPerSquareController.dispose();
    _disposalController.dispose();
    _permitsController.dispose();
    _markupController.dispose();
    super.dispose();
  }

  void _calculate() {
    final roofSquares = double.tryParse(_roofSquaresController.text);
    final materialCost = double.tryParse(_materialCostController.text);
    final laborRate = double.tryParse(_laborRateController.text);
    final hoursPerSquare = double.tryParse(_hoursPerSquareController.text);
    final disposal = double.tryParse(_disposalController.text);
    final permits = double.tryParse(_permitsController.text);
    final markupPercent = double.tryParse(_markupController.text);

    if (roofSquares == null || materialCost == null || laborRate == null ||
        hoursPerSquare == null || disposal == null || permits == null || markupPercent == null) {
      setState(() {
        _materialTotal = null;
        _laborTotal = null;
        _subtotal = null;
        _markup = null;
        _grandTotal = null;
        _perSquare = null;
      });
      return;
    }

    // Material costs
    final materialTotal = roofSquares * materialCost;

    // Labor costs
    var totalHours = roofSquares * hoursPerSquare;
    if (_includeTearOff) {
      totalHours += roofSquares * 0.75; // Add 0.75 hr/sq for tear-off
    }
    final laborTotal = totalHours * laborRate;

    // Subtotal
    final subtotal = materialTotal + laborTotal + disposal + permits;

    // Markup/profit
    final markup = subtotal * (markupPercent / 100);

    // Grand total
    final grandTotal = subtotal + markup;

    // Per square
    final perSquare = grandTotal / roofSquares;

    setState(() {
      _materialTotal = materialTotal;
      _laborTotal = laborTotal;
      _subtotal = subtotal;
      _markup = markup;
      _grandTotal = grandTotal;
      _perSquare = perSquare;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _roofSquaresController.text = '25';
    _materialCostController.text = '350';
    _laborRateController.text = '75';
    _hoursPerSquareController.text = '1.5';
    _disposalController.text = '500';
    _permitsController.text = '250';
    _markupController.text = '25';
    setState(() => _includeTearOff = true);
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
        title: Text('Total Job Cost', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'JOB SIZE'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Roof Squares',
                unit: 'sq',
                hint: 'Total area',
                controller: _roofSquaresController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              _buildTearOffToggle(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'MATERIALS'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Material Cost',
                unit: '\$/sq',
                hint: 'Per square',
                controller: _materialCostController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LABOR'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Labor Rate',
                      unit: '\$/hr',
                      hint: 'Hourly',
                      controller: _laborRateController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Hours/Sq',
                      unit: 'hr',
                      hint: 'Install only',
                      controller: _hoursPerSquareController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'OTHER COSTS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Disposal',
                      unit: '\$',
                      hint: 'Dumpster',
                      controller: _disposalController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Permits',
                      unit: '\$',
                      hint: 'Building',
                      controller: _permitsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Profit Markup',
                unit: '%',
                hint: '20-30% typical',
                controller: _markupController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_grandTotal != null) ...[
                _buildSectionHeader(colors, 'JOB ESTIMATE'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
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
              Icon(LucideIcons.calculator, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Total Job Cost Calculator',
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
            'Complete roofing job cost estimate',
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

  Widget _buildTearOffToggle(ZaftoColors colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _includeTearOff = !_includeTearOff);
        _calculate();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(
              _includeTearOff ? LucideIcons.checkSquare : LucideIcons.square,
              color: _includeTearOff ? colors.accentPrimary : colors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Include Tear-Off Labor',
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          _buildResultRow(colors, 'Materials', '\$${_materialTotal!.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Labor', '\$${_laborTotal!.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Disposal & Permits', '\$${(double.parse(_disposalController.text) + double.parse(_permitsController.text)).toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Subtotal', '\$${_subtotal!.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Markup (${_markupController.text}%)', '\$${_markup!.toStringAsFixed(0)}'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'TOTAL', '\$${_grandTotal!.toStringAsFixed(0)}', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'PER SQUARE', '\$${_perSquare!.toStringAsFixed(0)}/sq', isHighlighted: true),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.checkCircle, size: 16, color: colors.accentSuccess),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Adjust markup based on market conditions and competition.',
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

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: isHighlighted ? colors.accentPrimary : colors.textPrimary,
            fontSize: isHighlighted ? 20 : 14,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
