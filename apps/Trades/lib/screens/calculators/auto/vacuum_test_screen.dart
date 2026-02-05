import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Vacuum Gauge Reading Interpretation Calculator
class VacuumTestScreen extends ConsumerStatefulWidget {
  const VacuumTestScreen({super.key});
  @override
  ConsumerState<VacuumTestScreen> createState() => _VacuumTestScreenState();
}

class _VacuumTestScreenState extends ConsumerState<VacuumTestScreen> {
  final _idleVacuumController = TextEditingController();
  final _altitudeController = TextEditingController(text: '0');

  String _needleBehavior = 'steady';

  double? _adjustedVacuum;
  String? _condition;
  String? _conditionColor;
  String? _diagnosis;
  List<String> _possibleCauses = [];

  final Map<String, String> _needleBehaviors = {
    'steady': 'Steady (Normal)',
    'low_steady': 'Steady but Low',
    'fluctuating': 'Fluctuating 3-4 inHg',
    'drifting': 'Drifting 4-5 inHg',
    'rapid_vibrate': 'Rapid Vibration',
    'drops_snap': 'Drops & Snaps Back',
    'intermittent_drop': 'Intermittent Drop',
    'gradual_drop': 'Gradual Drop at Idle',
    'back_snap': 'Snaps to 0, Snaps Back',
  };

  @override
  void dispose() {
    _idleVacuumController.dispose();
    _altitudeController.dispose();
    super.dispose();
  }

  void _calculate() {
    final idleVacuum = double.tryParse(_idleVacuumController.text);
    final altitude = double.tryParse(_altitudeController.text) ?? 0;

    if (idleVacuum == null) {
      setState(() { _adjustedVacuum = null; });
      return;
    }

    // Vacuum drops ~1 inHg per 1000ft altitude
    final altitudeCorrection = altitude / 1000;
    final adjustedVacuum = idleVacuum + altitudeCorrection;

    String condition;
    String conditionColor;
    String diagnosis;
    List<String> causes = [];

    // Analyze based on needle behavior and reading
    switch (_needleBehavior) {
      case 'steady':
        if (adjustedVacuum >= 17 && adjustedVacuum <= 22) {
          condition = 'Good';
          conditionColor = 'green';
          diagnosis = 'Engine is running normally with good vacuum.';
        } else if (adjustedVacuum < 17) {
          condition = 'Low';
          conditionColor = 'yellow';
          diagnosis = 'Steady but low vacuum indicates possible issue.';
          causes = ['Late ignition timing', 'Low compression', 'Intake leak'];
        } else {
          condition = 'High';
          conditionColor = 'yellow';
          diagnosis = 'Higher than normal vacuum - check timing.';
          causes = ['Advanced ignition timing', 'Restricted exhaust'];
        }
        break;
      case 'low_steady':
        condition = 'Problem';
        conditionColor = 'orange';
        diagnosis = 'Consistently low vacuum at idle.';
        causes = ['Retarded ignition timing', 'Intake manifold leak', 'Low compression all cylinders', 'Incorrect camshaft timing'];
        break;
      case 'fluctuating':
        condition = 'Problem';
        conditionColor = 'orange';
        diagnosis = 'Regular fluctuation indicates valve issue.';
        causes = ['Burned valve', 'Sticking valve', 'Valve seat leak', 'Weak valve spring'];
        break;
      case 'drifting':
        condition = 'Problem';
        conditionColor = 'orange';
        diagnosis = 'Slow drifting indicates mixture issue.';
        causes = ['Rich or lean mixture', 'Carburetor problem', 'Fuel injection issue', 'IAC valve problem'];
        break;
      case 'rapid_vibrate':
        condition = 'Problem';
        conditionColor = 'red';
        diagnosis = 'Rapid needle vibration indicates severe issue.';
        causes = ['Worn valve guides', 'Weak valve springs', 'Ignition misfire', 'Intake leak at one runner'];
        break;
      case 'drops_snap':
        condition = 'Problem';
        conditionColor = 'orange';
        diagnosis = 'Regular dropping suggests sticking valve.';
        causes = ['Sticking valve', 'Weak valve spring', 'Valve not seating properly'];
        break;
      case 'intermittent_drop':
        condition = 'Problem';
        conditionColor = 'red';
        diagnosis = 'Intermittent drops indicate ignition issue.';
        causes = ['Spark plug misfire', 'Ignition coil failure', 'Distributor problem', 'Fuel injector issue'];
        break;
      case 'gradual_drop':
        condition = 'Problem';
        conditionColor = 'red';
        diagnosis = 'Gradual drop indicates exhaust restriction.';
        causes = ['Clogged catalytic converter', 'Restricted exhaust', 'Collapsed exhaust pipe'];
        break;
      case 'back_snap':
        condition = 'Problem';
        conditionColor = 'red';
        diagnosis = 'Snapping to zero indicates severe leak or timing.';
        causes = ['Blown head gasket', 'Severely retarded timing', 'Major vacuum leak'];
        break;
      default:
        condition = 'Unknown';
        conditionColor = 'yellow';
        diagnosis = 'Unable to diagnose. Check input values.';
    }

    setState(() {
      _adjustedVacuum = adjustedVacuum;
      _condition = condition;
      _conditionColor = conditionColor;
      _diagnosis = diagnosis;
      _possibleCauses = causes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _idleVacuumController.clear();
    _altitudeController.text = '0';
    setState(() {
      _needleBehavior = 'steady';
      _adjustedVacuum = null;
    });
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
        title: Text('Vacuum Test', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'VACUUM READING'),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Idle Vacuum', unit: 'inHg', hint: 'Reading at idle', controller: _idleVacuumController, onChanged: (_) => _calculate()),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Altitude', unit: 'ft', hint: 'Elevation above sea level', controller: _altitudeController, onChanged: (_) => _calculate()),
              const SizedBox(height: 20),
              _buildSectionHeader(colors, 'NEEDLE BEHAVIOR'),
              const SizedBox(height: 12),
              _buildBehaviorSelector(colors),
              const SizedBox(height: 32),
              if (_adjustedVacuum != null) _buildResultsCard(colors),
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
          Text('Normal: 17-22 inHg at idle (sea level)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
          const SizedBox(height: 8),
          Text('Vacuum gauge diagnosis reveals internal engine issues', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildBehaviorSelector(ZaftoColors colors) {
    return Container(
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        children: _needleBehaviors.entries.map((entry) {
          final isSelected = _needleBehavior == entry.key;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _needleBehavior = entry.key;
              });
              _calculate();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary.withValues(alpha: 0.1) : Colors.transparent,
                border: Border(bottom: BorderSide(color: colors.borderSubtle, width: entry.key == _needleBehaviors.keys.last ? 0 : 1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelected ? colors.accentPrimary : colors.textTertiary, width: 2),
                      color: isSelected ? colors.accentPrimary : Colors.transparent,
                    ),
                    child: isSelected ? Icon(LucideIcons.check, size: 12, color: colors.bgBase) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(entry.value, style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textSecondary, fontSize: 14))),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    Color statusColor;
    switch (_conditionColor) {
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
          _buildResultRow(colors, 'Adjusted Vacuum', '${_adjustedVacuum!.toStringAsFixed(1)} inHg', isPrimary: true),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Condition', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(_condition!, style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
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
                    Text('Diagnosis', style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_diagnosis!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (_possibleCauses.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Possible Causes:', style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  ..._possibleCauses.map((cause) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(LucideIcons.chevronRight, size: 12, color: colors.textTertiary),
                        const SizedBox(width: 4),
                        Expanded(child: Text(cause, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('REFERENCE', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildReferenceRow(colors, '17-22 inHg', 'Normal at sea level'),
                _buildReferenceRow(colors, '-1 inHg/1000ft', 'Altitude correction'),
                _buildReferenceRow(colors, '< 10 inHg', 'Major engine issue'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceRow(ZaftoColors colors, String value, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'monospace'))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textTertiary, fontSize: 12))),
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
