import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Emission Readings Analysis Calculator
class EmissionTestScreen extends ConsumerStatefulWidget {
  const EmissionTestScreen({super.key});
  @override
  ConsumerState<EmissionTestScreen> createState() => _EmissionTestScreenState();
}

class _EmissionTestScreenState extends ConsumerState<EmissionTestScreen> {
  final _hcController = TextEditingController();
  final _coController = TextEditingController();
  final _co2Controller = TextEditingController();
  final _o2Controller = TextEditingController();
  final _noxController = TextEditingController();

  String _testCondition = 'idle';
  int _modelYear = 1996;

  String? _overallResult;
  String? _resultColor;
  Map<String, Map<String, dynamic>> _gasAnalysis = {};
  List<String> _possibleCauses = [];
  List<String> _recommendations = [];

  // Emission limits (vary by year and test type)
  final Map<String, Map<String, double>> _limits = {
    'hc_idle': {'pre96': 220, 'post96': 100},
    'hc_2500': {'pre96': 220, 'post96': 100},
    'co_idle': {'pre96': 1.2, 'post96': 0.5},
    'co_2500': {'pre96': 1.2, 'post96': 0.5},
    'nox_2500': {'pre96': 1500, 'post96': 600},
  };

  @override
  void dispose() {
    _hcController.dispose();
    _coController.dispose();
    _co2Controller.dispose();
    _o2Controller.dispose();
    _noxController.dispose();
    super.dispose();
  }

  void _calculate() {
    final hc = double.tryParse(_hcController.text);
    final co = double.tryParse(_coController.text);
    final co2 = double.tryParse(_co2Controller.text);
    final o2 = double.tryParse(_o2Controller.text);
    final nox = double.tryParse(_noxController.text);

    if (hc == null && co == null && co2 == null && o2 == null) {
      setState(() { _overallResult = null; });
      return;
    }

    Map<String, Map<String, dynamic>> analysis = {};
    List<String> causes = [];
    List<String> recommendations = [];
    bool anyFail = false;
    bool anyWarning = false;

    final yearKey = _modelYear >= 1996 ? 'post96' : 'pre96';
    final condKey = _testCondition == 'idle' ? 'idle' : '2500';

    // Analyze HC (Hydrocarbons) - ppm
    if (hc != null) {
      final limit = _limits['hc_$condKey']![yearKey]!;
      String status;
      String color;
      if (hc <= limit * 0.7) {
        status = 'Pass';
        color = 'green';
      } else if (hc <= limit) {
        status = 'Marginal';
        color = 'yellow';
        anyWarning = true;
      } else {
        status = 'Fail';
        color = 'red';
        anyFail = true;
        causes.add('High HC: Incomplete combustion');
        recommendations.add('Check ignition system (plugs, wires, coil)');
        recommendations.add('Check for vacuum leaks');
        recommendations.add('Verify fuel system pressure');
      }
      analysis['HC'] = {'value': hc, 'unit': 'ppm', 'limit': limit, 'status': status, 'color': color};
    }

    // Analyze CO (Carbon Monoxide) - %
    if (co != null) {
      final limit = _limits['co_$condKey']![yearKey]!;
      String status;
      String color;
      if (co <= limit * 0.7) {
        status = 'Pass';
        color = 'green';
      } else if (co <= limit) {
        status = 'Marginal';
        color = 'yellow';
        anyWarning = true;
      } else {
        status = 'Fail';
        color = 'red';
        anyFail = true;
        causes.add('High CO: Rich air/fuel mixture');
        recommendations.add('Check O2 sensor operation');
        recommendations.add('Inspect fuel injectors for leaks');
        recommendations.add('Check fuel pressure regulator');
        recommendations.add('Verify MAP/MAF sensor readings');
      }
      analysis['CO'] = {'value': co, 'unit': '%', 'limit': limit, 'status': status, 'color': color};
    }

    // Analyze CO2 (Carbon Dioxide) - %
    if (co2 != null) {
      String status;
      String color;
      // CO2 should be 13-16% for good combustion
      if (co2 >= 13 && co2 <= 16) {
        status = 'Optimal';
        color = 'green';
      } else if (co2 >= 11 && co2 < 13) {
        status = 'Low';
        color = 'yellow';
        anyWarning = true;
        causes.add('Low CO2: Inefficient combustion');
      } else if (co2 > 16 && co2 <= 17) {
        status = 'Marginal';
        color = 'yellow';
        anyWarning = true;
      } else {
        status = 'Poor';
        color = 'orange';
        anyWarning = true;
        causes.add('CO2 out of range: Check overall engine efficiency');
      }
      analysis['CO2'] = {'value': co2, 'unit': '%', 'limit': 13.0, 'status': status, 'color': color, 'note': 'Target: 13-16%'};
    }

    // Analyze O2 (Oxygen) - %
    if (o2 != null) {
      String status;
      String color;
      // O2 should be 0.5-2% at idle
      if (o2 >= 0.5 && o2 <= 2.0) {
        status = 'Optimal';
        color = 'green';
      } else if (o2 < 0.5) {
        status = 'Low';
        color = 'yellow';
        causes.add('Low O2: Rich mixture');
        anyWarning = true;
      } else if (o2 > 2.0 && o2 <= 4.0) {
        status = 'High';
        color = 'yellow';
        causes.add('High O2: Lean mixture or misfire');
        anyWarning = true;
      } else {
        status = 'Very High';
        color = 'red';
        anyFail = true;
        causes.add('Very high O2: Significant lean condition or exhaust leak');
        recommendations.add('Check for exhaust leaks before O2 sensor');
        recommendations.add('Check for vacuum leaks');
        recommendations.add('Test fuel delivery');
      }
      analysis['O2'] = {'value': o2, 'unit': '%', 'limit': 2.0, 'status': status, 'color': color, 'note': 'Target: 0.5-2%'};
    }

    // Analyze NOx (Nitrogen Oxides) - ppm
    if (nox != null && _testCondition == '2500') {
      final limit = _limits['nox_2500']![yearKey]!;
      String status;
      String color;
      if (nox <= limit * 0.7) {
        status = 'Pass';
        color = 'green';
      } else if (nox <= limit) {
        status = 'Marginal';
        color = 'yellow';
        anyWarning = true;
      } else {
        status = 'Fail';
        color = 'red';
        anyFail = true;
        causes.add('High NOx: High combustion temperature');
        recommendations.add('Check EGR system operation');
        recommendations.add('Verify catalytic converter function');
        recommendations.add('Check for carbon buildup');
        recommendations.add('Verify cooling system operation');
      }
      analysis['NOx'] = {'value': nox, 'unit': 'ppm', 'limit': limit, 'status': status, 'color': color};
    }

    // Determine overall result
    String overallResult;
    String resultColor;
    if (anyFail) {
      overallResult = 'FAIL';
      resultColor = 'red';
    } else if (anyWarning) {
      overallResult = 'MARGINAL';
      resultColor = 'yellow';
    } else if (analysis.isNotEmpty) {
      overallResult = 'PASS';
      resultColor = 'green';
    } else {
      overallResult = 'INCOMPLETE';
      resultColor = 'yellow';
    }

    setState(() {
      _overallResult = overallResult;
      _resultColor = resultColor;
      _gasAnalysis = analysis;
      _possibleCauses = causes.toSet().toList();
      _recommendations = recommendations.toSet().toList();
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _hcController.clear();
    _coController.clear();
    _co2Controller.clear();
    _o2Controller.clear();
    _noxController.clear();
    setState(() { _overallResult = null; });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Emission Test', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormulaCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'TEST CONDITIONS'),
              const SizedBox(height: 12),
              _buildConditionSelector(colors),
              const SizedBox(height: 12),
              _buildYearSelector(colors),
              const SizedBox(height: 20),
              _buildSectionHeader(colors, 'GAS READINGS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: ZaftoInputField(label: 'HC', unit: 'ppm', hint: 'Hydrocarbons', controller: _hcController, onChanged: (_) => _calculate())),
                  const SizedBox(width: 12),
                  Expanded(child: ZaftoInputField(label: 'CO', unit: '%', hint: 'Carbon Monox.', controller: _coController, onChanged: (_) => _calculate())),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: ZaftoInputField(label: 'CO2', unit: '%', hint: 'Carbon Diox.', controller: _co2Controller, onChanged: (_) => _calculate())),
                  const SizedBox(width: 12),
                  Expanded(child: ZaftoInputField(label: 'O2', unit: '%', hint: 'Oxygen', controller: _o2Controller, onChanged: (_) => _calculate())),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'NOx', unit: 'ppm', hint: 'Nitrogen Oxides (2500 RPM test)', controller: _noxController, onChanged: (_) => _calculate()),
              const SizedBox(height: 32),
              if (_overallResult != null) _buildResultsCard(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        children: [
          Text('5-Gas Analysis: HC, CO, CO2, O2, NOx', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
          const SizedBox(height: 8),
          Text('Emission readings reveal combustion efficiency and mixture issues', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildConditionSelector(ZaftoColors colors) {
    return Row(
      children: [
        _buildConditionOption(colors, 'idle', 'Idle Test'),
        const SizedBox(width: 12),
        _buildConditionOption(colors, '2500', '2500 RPM Test'),
      ],
    );
  }

  Widget _buildConditionOption(ZaftoColors colors, String value, String label) {
    final isSelected = _testCondition == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _testCondition = value;
          });
          _calculate();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
          ),
          child: Center(child: Text(label, style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textSecondary, fontWeight: FontWeight.w600))),
        ),
      ),
    );
  }

  Widget _buildYearSelector(ZaftoColors colors) {
    return Row(
      children: [
        _buildYearOption(colors, 1995, 'Pre-1996'),
        const SizedBox(width: 12),
        _buildYearOption(colors, 1996, '1996+'),
      ],
    );
  }

  Widget _buildYearOption(ZaftoColors colors, int year, String label) {
    final isSelected = (year < 1996 && _modelYear < 1996) || (year >= 1996 && _modelYear >= 1996);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _modelYear = year;
          });
          _calculate();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
          ),
          child: Center(child: Text(label, style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textSecondary, fontWeight: FontWeight.w600))),
        ),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    Color statusColor;
    switch (_resultColor) {
      case 'green':
        statusColor = Colors.green;
        break;
      case 'yellow':
        statusColor = Colors.amber;
        break;
      case 'orange':
        statusColor = Colors.orange;
        break;
      case 'red':
        statusColor = Colors.red;
        break;
      default:
        statusColor = colors.textPrimary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Overall Result', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(_overallResult!, style: TextStyle(color: statusColor, fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (_gasAnalysis.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._gasAnalysis.entries.map((entry) => _buildGasRow(colors, entry.key, entry.value)),
          ],
          if (_possibleCauses.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Possible Causes:', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  ..._possibleCauses.map((cause) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.alertCircle, size: 12, color: Colors.orange),
                        const SizedBox(width: 4),
                        Expanded(child: Text(cause, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
          if (_recommendations.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.wrench, size: 16, color: colors.accentPrimary),
                      const SizedBox(width: 8),
                      Text('Recommendations', style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._recommendations.map((rec) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.chevronRight, size: 12, color: colors.textTertiary),
                        const SizedBox(width: 4),
                        Expanded(child: Text(rec, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildDiagnosticGuide(colors),
        ],
      ),
    );
  }

  Widget _buildGasRow(ZaftoColors colors, String gas, Map<String, dynamic> data) {
    Color gasColor;
    switch (data['color']) {
      case 'green':
        gasColor = Colors.green;
        break;
      case 'yellow':
        gasColor = Colors.amber;
        break;
      case 'orange':
        gasColor = Colors.orange;
        break;
      case 'red':
        gasColor = Colors.red;
        break;
      default:
        gasColor = colors.textPrimary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text(gas, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600))),
          Expanded(
            child: Text('${data['value']} ${data['unit']}', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          ),
          if (data['limit'] != null) Text('Limit: ${data['limit']} ', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: gasColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
            child: Text(data['status'], style: TextStyle(color: gasColor, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('QUICK DIAGNOSTIC GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 8),
          _buildGuideRow(colors, 'High HC + High CO', 'Rich mixture'),
          _buildGuideRow(colors, 'High HC + Low CO', 'Misfire/lean'),
          _buildGuideRow(colors, 'High CO + Low O2', 'Rich mixture'),
          _buildGuideRow(colors, 'High O2 + High HC', 'Misfire'),
          _buildGuideRow(colors, 'High NOx alone', 'EGR/lean/timing'),
          _buildGuideRow(colors, 'Low CO2 overall', 'Poor efficiency'),
        ],
      ),
    );
  }

  Widget _buildGuideRow(ZaftoColors colors, String reading, String meaning) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(reading, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
          Text(meaning, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
