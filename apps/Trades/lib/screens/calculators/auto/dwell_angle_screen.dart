import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Ignition Dwell Angle Calculator
class DwellAngleScreen extends ConsumerStatefulWidget {
  const DwellAngleScreen({super.key});
  @override
  ConsumerState<DwellAngleScreen> createState() => _DwellAngleScreenState();
}

class _DwellAngleScreenState extends ConsumerState<DwellAngleScreen> {
  final _cylindersController = TextEditingController(text: '8');
  final _pointGapController = TextEditingController(text: '0.017');
  final _measuredDwellController = TextEditingController();

  double? _idealDwell;
  double? _dwellVariation;
  double? _percentOfCycle;
  String? _assessment;
  String? _assessmentColor;
  String? _recommendation;

  // Dwell specs by cylinder count
  final Map<int, Map<String, double>> _dwellSpecs = {
    4: {'min': 46, 'ideal': 50, 'max': 54},
    6: {'min': 34, 'ideal': 38, 'max': 42},
    8: {'min': 28, 'ideal': 30, 'max': 32},
  };

  @override
  void dispose() {
    _cylindersController.dispose();
    _pointGapController.dispose();
    _measuredDwellController.dispose();
    super.dispose();
  }

  void _calculate() {
    final cylinders = int.tryParse(_cylindersController.text);
    final pointGap = double.tryParse(_pointGapController.text);
    final measuredDwell = double.tryParse(_measuredDwellController.text);

    if (cylinders == null || pointGap == null) {
      setState(() { _idealDwell = null; });
      return;
    }

    // Total degrees in distributor rotation = 360
    // Each cylinder fires once per 2 crankshaft rotations (4-stroke)
    // Distributor turns at 1/2 crank speed
    // Degrees per cylinder = 360 / cylinders
    final degreesPerCylinder = 360.0 / cylinders;

    // Ideal dwell is typically 60% of degrees per cylinder
    final idealDwell = degreesPerCylinder * 0.60;

    // Get specs if available
    final specs = _dwellSpecs[cylinders];

    double? dwellVariation;
    double? percentOfCycle;
    String assessment;
    String assessmentColor;
    String recommendation;

    if (measuredDwell != null && specs != null) {
      dwellVariation = measuredDwell - specs['ideal']!;
      percentOfCycle = (measuredDwell / degreesPerCylinder) * 100;

      if (measuredDwell >= specs['min']! && measuredDwell <= specs['max']!) {
        assessment = 'Good';
        assessmentColor = 'green';
        recommendation = 'Dwell is within specification. No adjustment needed.';
      } else if (measuredDwell < specs['min']!) {
        assessment = 'Too Low';
        assessmentColor = 'orange';
        recommendation = 'Close point gap slightly to increase dwell. Low dwell causes weak spark at high RPM.';
      } else {
        assessment = 'Too High';
        assessmentColor = 'orange';
        recommendation = 'Open point gap slightly to decrease dwell. High dwell can cause points to burn.';
      }
    } else if (measuredDwell != null) {
      percentOfCycle = (measuredDwell / degreesPerCylinder) * 100;
      if (percentOfCycle >= 55 && percentOfCycle <= 65) {
        assessment = 'Likely Good';
        assessmentColor = 'green';
        recommendation = 'Dwell appears to be in typical range (55-65% of cycle).';
      } else {
        assessment = 'Check Specs';
        assessmentColor = 'yellow';
        recommendation = 'Verify against manufacturer specifications for this engine.';
      }
      dwellVariation = measuredDwell - idealDwell;
    } else {
      assessment = 'Enter Reading';
      assessmentColor = 'yellow';
      recommendation = 'Enter your measured dwell angle to analyze.';
    }

    setState(() {
      _idealDwell = idealDwell;
      _dwellVariation = dwellVariation;
      _percentOfCycle = percentOfCycle;
      _assessment = assessment;
      _assessmentColor = assessmentColor;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _cylindersController.text = '8';
    _pointGapController.text = '0.017';
    _measuredDwellController.clear();
    setState(() { _idealDwell = null; });
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
        title: Text('Dwell Angle', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ENGINE CONFIGURATION'),
              const SizedBox(height: 12),
              _buildCylinderSelector(colors),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Point Gap', unit: 'in', hint: 'Breaker point gap', controller: _pointGapController, onChanged: (_) => _calculate()),
              const SizedBox(height: 20),
              _buildSectionHeader(colors, 'MEASUREMENT'),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Measured Dwell', unit: 'deg', hint: 'Dwell meter reading', controller: _measuredDwellController, onChanged: (_) => _calculate()),
              const SizedBox(height: 32),
              if (_idealDwell != null) _buildResultsCard(colors),
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
          Text('Dwell = Degrees points stay closed', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
          const SizedBox(height: 8),
          Text('Dwell angle determines coil saturation time for spark energy', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildCylinderSelector(ZaftoColors colors) {
    return Row(
      children: [4, 6, 8].map((count) {
        final isSelected = int.tryParse(_cylindersController.text) == count;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _cylindersController.text = count.toString();
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: count == 8 ? 0 : 12),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: Center(child: Text('$count Cyl', style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textSecondary, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final cylinders = int.tryParse(_cylindersController.text) ?? 8;
    final specs = _dwellSpecs[cylinders];

    Color statusColor;
    switch (_assessmentColor) {
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
          _buildResultRow(colors, 'Calculated Ideal', '${_idealDwell!.toStringAsFixed(1)} deg', isPrimary: true),
          if (specs != null) ...[
            const SizedBox(height: 12),
            _buildResultRow(colors, 'Spec Range', '${specs['min']!.toStringAsFixed(0)} - ${specs['max']!.toStringAsFixed(0)} deg'),
          ],
          if (_dwellVariation != null) ...[
            const SizedBox(height: 12),
            _buildResultRow(colors, 'Variation', '${_dwellVariation! > 0 ? '+' : ''}${_dwellVariation!.toStringAsFixed(1)} deg'),
          ],
          if (_percentOfCycle != null) ...[
            const SizedBox(height: 12),
            _buildResultRow(colors, '% of Cycle', '${_percentOfCycle!.toStringAsFixed(1)}%'),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Assessment', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(_assessment!, style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (_recommendation != null) ...[
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
                      Icon(LucideIcons.info, size: 16, color: colors.accentPrimary),
                      const SizedBox(width: 8),
                      Text('Recommendation', style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildSpecTable(colors),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DWELL vs POINT GAP', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text('Larger gap = Less dwell (points open sooner)\nSmaller gap = More dwell (points stay closed longer)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STANDARD DWELL SPECS', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text('Cylinders', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600))),
              Expanded(child: Text('Dwell', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600))),
              Expanded(child: Text('Gap', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600))),
            ],
          ),
          const Divider(height: 16),
          _buildSpecRow(colors, '4 Cylinder', '46-54°', '0.018-0.022"'),
          _buildSpecRow(colors, '6 Cylinder', '34-42°', '0.016-0.020"'),
          _buildSpecRow(colors, '8 Cylinder', '28-32°', '0.014-0.019"'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(ZaftoColors colors, String cyl, String dwell, String gap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(cyl, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
          Expanded(child: Text(dwell, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500))),
          Expanded(child: Text(gap, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 20 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
      ],
    );
  }
}
