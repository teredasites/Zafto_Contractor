import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Interconnection Calculator - Grid interconnection analysis
class InterconnectionCalculatorScreen extends ConsumerStatefulWidget {
  const InterconnectionCalculatorScreen({super.key});
  @override
  ConsumerState<InterconnectionCalculatorScreen> createState() => _InterconnectionCalculatorScreenState();
}

class _InterconnectionCalculatorScreenState extends ConsumerState<InterconnectionCalculatorScreen> {
  final _inverterAcController = TextEditingController(text: '7600');
  final _mainBreakerController = TextEditingController(text: '200');
  final _busbarRatingController = TextEditingController(text: '200');
  final _solarBreakerController = TextEditingController(text: '40');

  String _panelType = 'Load Center';
  String _connectionMethod = 'Load Side';

  bool? _passesTest;
  double? _busbarLoad;
  double? _maxSolarBreaker;
  String? _testMethod;
  String? _recommendation;

  @override
  void dispose() {
    _inverterAcController.dispose();
    _mainBreakerController.dispose();
    _busbarRatingController.dispose();
    _solarBreakerController.dispose();
    super.dispose();
  }

  void _calculate() {
    final inverterAc = double.tryParse(_inverterAcController.text);
    final mainBreaker = double.tryParse(_mainBreakerController.text);
    final busbarRating = double.tryParse(_busbarRatingController.text);
    final solarBreaker = double.tryParse(_solarBreakerController.text);

    if (inverterAc == null || mainBreaker == null || busbarRating == null || solarBreaker == null) {
      setState(() {
        _passesTest = null;
        _busbarLoad = null;
        _maxSolarBreaker = null;
        _testMethod = null;
        _recommendation = null;
      });
      return;
    }

    bool passesTest;
    double maxSolarBreaker;
    String testMethod;

    if (_connectionMethod == 'Load Side') {
      // NEC 705.12(B)(2) - 120% Rule
      // Sum of all overcurrent devices ≤ 120% of busbar rating
      // Main breaker + Solar breaker ≤ 1.2 × Busbar rating
      final maxTotal = busbarRating * 1.2;
      maxSolarBreaker = maxTotal - mainBreaker;
      passesTest = (mainBreaker + solarBreaker) <= maxTotal;
      testMethod = '120% Rule (NEC 705.12(B)(2))';
    } else {
      // Supply side connection - NEC 705.12(A)
      // Connected ahead of main breaker, no 120% calculation needed
      // Limited by service conductor ampacity
      maxSolarBreaker = busbarRating * 0.25; // Simplified - typically 25% for supply side
      passesTest = solarBreaker <= maxSolarBreaker;
      testMethod = 'Supply Side (NEC 705.12(A))';
    }

    // Calculate busbar loading
    final busbarLoad = ((mainBreaker + solarBreaker) / busbarRating) * 100;

    String recommendation;
    if (!passesTest) {
      if (_connectionMethod == 'Load Side') {
        recommendation = 'Exceeds 120% rule. Options: supply side tap, service upgrade, or de-rate main breaker.';
      } else {
        recommendation = 'Exceeds supply side limits. Verify with utility and AHJ.';
      }
    } else if (busbarLoad > 110) {
      recommendation = 'Passes but near limit. Consider future expansion needs.';
    } else if (busbarLoad > 100) {
      recommendation = 'Meets requirements. Standard interconnection applies.';
    } else {
      recommendation = 'Well within limits. Straightforward interconnection.';
    }

    setState(() {
      _passesTest = passesTest;
      _busbarLoad = busbarLoad;
      _maxSolarBreaker = maxSolarBreaker;
      _testMethod = testMethod;
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
    _inverterAcController.text = '7600';
    _mainBreakerController.text = '200';
    _busbarRatingController.text = '200';
    _solarBreakerController.text = '40';
    setState(() {
      _panelType = 'Load Center';
      _connectionMethod = 'Load Side';
    });
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
        title: Text('Interconnection', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CONNECTION METHOD'),
              const SizedBox(height: 12),
              _buildConnectionMethodSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ELECTRICAL PANEL'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Main Breaker',
                      unit: 'A',
                      hint: 'Panel main',
                      controller: _mainBreakerController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Busbar Rating',
                      unit: 'A',
                      hint: 'Panel busbar',
                      controller: _busbarRatingController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SOLAR SYSTEM'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Inverter AC Output',
                      unit: 'W',
                      hint: 'Max output',
                      controller: _inverterAcController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Solar Breaker',
                      unit: 'A',
                      hint: 'Backfeed',
                      controller: _solarBreakerController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_passesTest != null) ...[
                _buildSectionHeader(colors, 'INTERCONNECTION ANALYSIS'),
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
              Icon(LucideIcons.plug, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Interconnection Calculator',
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
            'NEC 705.12 grid interconnection compliance',
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

  Widget _buildConnectionMethodSelector(ZaftoColors colors) {
    final methods = ['Load Side', 'Supply Side'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: methods.map((method) {
          final isSelected = _connectionMethod == method;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _connectionMethod = method);
                _calculate();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    method,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final statusColor = _passesTest! ? colors.accentSuccess : colors.accentError;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _passesTest! ? LucideIcons.checkCircle : LucideIcons.xCircle,
                  size: 18,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _passesTest! ? 'Passes ${_connectionMethod == 'Load Side' ? '120% Rule' : 'Supply Side'}' : 'Fails Requirements',
                  style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Busbar Load', '${_busbarLoad!.toStringAsFixed(0)}%', _busbarLoad! <= 120 ? colors.accentSuccess : colors.accentError),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Max Solar Breaker', '${_maxSolarBreaker!.toStringAsFixed(0)}A', colors.accentInfo),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CALCULATION', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const SizedBox(height: 8),
                if (_connectionMethod == 'Load Side') ...[
                  _buildCalcRow(colors, 'Main Breaker', '${_mainBreakerController.text}A'),
                  _buildCalcRow(colors, '+ Solar Breaker', '${_solarBreakerController.text}A'),
                  Divider(color: colors.borderSubtle, height: 16),
                  _buildCalcRow(colors, 'Total', '${double.parse(_mainBreakerController.text) + double.parse(_solarBreakerController.text)}A'),
                  _buildCalcRow(colors, '120% of Busbar', '${(double.parse(_busbarRatingController.text) * 1.2).toStringAsFixed(0)}A'),
                ] else ...[
                  _buildCalcRow(colors, 'Busbar Rating', '${_busbarRatingController.text}A'),
                  _buildCalcRow(colors, 'Max Solar (25%)', '${_maxSolarBreaker!.toStringAsFixed(0)}A'),
                  _buildCalcRow(colors, 'Proposed Solar', '${_solarBreakerController.text}A'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.bookOpen, size: 14, color: colors.accentInfo),
                    const SizedBox(width: 8),
                    Text(_testMethod!, style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _recommendation!,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(ZaftoColors colors, String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildCalcRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
