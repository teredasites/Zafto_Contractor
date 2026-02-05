import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Misfire Diagnosis Helper Calculator
class MisfireAnalysisScreen extends ConsumerStatefulWidget {
  const MisfireAnalysisScreen({super.key});
  @override
  ConsumerState<MisfireAnalysisScreen> createState() => _MisfireAnalysisScreenState();
}

class _MisfireAnalysisScreenState extends ConsumerState<MisfireAnalysisScreen> {
  // Symptom checkboxes
  bool _roughIdle = false;
  bool _hesitation = false;
  bool _powerLoss = false;
  bool _checkEngineLight = false;
  bool _flashingCel = false;
  bool _poorFuelEconomy = false;
  bool _backfire = false;
  bool _engineShake = false;
  bool _coldOnly = false;
  bool _warmOnly = false;
  bool _loadOnly = false;
  bool _allConditions = false;
  bool _randomCylinders = false;
  bool _specificCylinder = false;

  final _cylinderController = TextEditingController();
  final _misfireCountController = TextEditingController();
  final _rpmController = TextEditingController();

  String? _diagnosis;
  String? _diagnosisColor;
  String? _primaryCause;
  List<String> _possibleCauses = [];
  List<String> _diagnosticSteps = [];
  int _severity = 0;

  @override
  void dispose() {
    _cylinderController.dispose();
    _misfireCountController.dispose();
    _rpmController.dispose();
    super.dispose();
  }

  void _analyze() {
    List<String> causes = [];
    List<String> steps = [];
    String diagnosis;
    String diagnosisColor;
    String primaryCause;
    int severity = 0;

    // Determine severity
    if (_flashingCel) severity = 3;
    else if (_checkEngineLight && _powerLoss) severity = 2;
    else if (_roughIdle || _hesitation) severity = 1;

    // Analyze based on conditions
    if (_randomCylinders || (_allConditions && !_specificCylinder)) {
      // Random misfire - usually fuel or ignition system wide
      diagnosis = 'Random Misfire';
      diagnosisColor = 'orange';
      primaryCause = 'System-wide issue affecting multiple cylinders';
      causes = [
        'Low fuel pressure',
        'Vacuum leak (intake manifold)',
        'Failing ignition coil pack',
        'Bad fuel quality',
        'Clogged fuel filter',
        'MAF sensor contamination',
        'EGR valve stuck open',
        'Timing chain stretch',
      ];
      steps = [
        'Check for vacuum leaks with smoke test',
        'Test fuel pressure at rail',
        'Scan for pending codes',
        'Check MAF sensor readings',
        'Inspect intake manifold gaskets',
        'Test ignition coils one at a time',
      ];
    } else if (_specificCylinder) {
      // Specific cylinder misfire
      diagnosis = 'Cylinder-Specific Misfire';
      diagnosisColor = 'yellow';
      primaryCause = 'Component failure in cylinder ${_cylinderController.text.isNotEmpty ? _cylinderController.text : "X"}';
      causes = [
        'Faulty spark plug',
        'Bad ignition coil/wire',
        'Clogged fuel injector',
        'Low compression (rings/valves)',
        'Intake valve carbon buildup',
        'Head gasket leak (that cylinder)',
        'Injector driver circuit failure',
      ];
      steps = [
        'Swap ignition coil with good cylinder',
        'Swap spark plug with good cylinder',
        'Test injector pulse and spray pattern',
        'Perform compression test on that cylinder',
        'Check for coolant in cylinder (head gasket)',
        'Inspect valve seal and stem',
      ];
    } else if (_coldOnly) {
      // Cold misfire only
      diagnosis = 'Cold Start Misfire';
      diagnosisColor = 'yellow';
      primaryCause = 'Temperature-related component issue';
      causes = [
        'Worn spark plugs (gap widens when cold)',
        'Cracked spark plug insulators',
        'Coolant temperature sensor fault',
        'Cold start injector problem',
        'Valve seal leak (oil fouling)',
        'Carbon deposits on valves',
        'Weak ignition coil (fails when cold)',
      ];
      steps = [
        'Replace spark plugs with OEM spec',
        'Test coolant temp sensor resistance',
        'Check for oil fouling on plugs',
        'Perform carbon cleaning if needed',
        'Test ignition coils when cold',
      ];
    } else if (_warmOnly) {
      // Warm only misfire
      diagnosis = 'Hot Engine Misfire';
      diagnosisColor = 'orange';
      primaryCause = 'Heat-related component breakdown';
      causes = [
        'Failing ignition coil (heat sensitive)',
        'Cracked plug wire insulation',
        'Vapor lock in fuel system',
        'Heat soak ignition failure',
        'Overheating engine',
        'Weak fuel pump (worse when hot)',
      ];
      steps = [
        'Test ignition coils when hot',
        'Check fuel pressure when hot',
        'Inspect plug wires for cracks',
        'Verify cooling system operation',
        'Check for heat shield presence',
      ];
    } else if (_loadOnly) {
      // Load only misfire
      diagnosis = 'Load-Induced Misfire';
      diagnosisColor = 'orange';
      primaryCause = 'Component failure under stress';
      causes = [
        'Weak ignition coil/module',
        'Insufficient fuel pressure',
        'Clogged injectors (can\'t flow enough)',
        'Boost leak (turbo vehicles)',
        'Carbon buildup reducing flow',
        'Knock sensor retarding timing',
        'Catalytic converter restriction',
      ];
      steps = [
        'Test fuel pressure under load',
        'Check for knock sensor codes',
        'Perform injector flow test',
        'Check boost pressure (if turbo)',
        'Test exhaust backpressure',
        'Monitor knock retard with scan tool',
      ];
    } else if (_backfire) {
      // Backfire present
      diagnosis = 'Severe Misfire with Backfire';
      diagnosisColor = 'red';
      severity = 3;
      primaryCause = 'Unburned fuel entering exhaust';
      causes = [
        'Severely worn spark plugs',
        'Completely dead ignition coil',
        'Stuck open injector',
        'Jumped timing chain/belt',
        'Burnt exhaust valve',
        'Large vacuum leak',
      ];
      steps = [
        'CAUTION: Can damage catalytic converter',
        'Do not drive - tow to shop',
        'Check timing marks alignment',
        'Compression test all cylinders',
        'Inspect for visible damage',
      ];
    } else {
      // General misfire
      diagnosis = 'General Misfire';
      diagnosisColor = 'yellow';
      primaryCause = 'Ignition, fuel, or mechanical issue';
      causes = [
        'Worn spark plugs',
        'Failing ignition coil',
        'Fuel delivery issue',
        'Vacuum leak',
        'Low compression',
        'Sensor malfunction',
      ];
      steps = [
        'Pull codes with OBD2 scanner',
        'Inspect spark plugs',
        'Check fuel pressure',
        'Listen for vacuum leaks',
        'Test compression if needed',
      ];
    }

    // Adjust for flashing CEL
    if (_flashingCel) {
      diagnosis = 'SEVERE - $diagnosis';
      diagnosisColor = 'red';
      steps.insert(0, 'STOP DRIVING - Catalytic converter damage imminent');
    }

    setState(() {
      _diagnosis = diagnosis;
      _diagnosisColor = diagnosisColor;
      _primaryCause = primaryCause;
      _possibleCauses = causes;
      _diagnosticSteps = steps;
      _severity = severity;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    setState(() {
      _roughIdle = false;
      _hesitation = false;
      _powerLoss = false;
      _checkEngineLight = false;
      _flashingCel = false;
      _poorFuelEconomy = false;
      _backfire = false;
      _engineShake = false;
      _coldOnly = false;
      _warmOnly = false;
      _loadOnly = false;
      _allConditions = false;
      _randomCylinders = false;
      _specificCylinder = false;
      _diagnosis = null;
    });
    _cylinderController.clear();
    _misfireCountController.clear();
    _rpmController.clear();
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
        title: Text('Misfire Analysis', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SYMPTOMS'),
              const SizedBox(height: 12),
              _buildSymptomGrid(colors),
              const SizedBox(height: 20),
              _buildSectionHeader(colors, 'WHEN DOES IT OCCUR?'),
              const SizedBox(height: 12),
              _buildConditionGrid(colors),
              const SizedBox(height: 20),
              _buildSectionHeader(colors, 'AFFECTED CYLINDERS'),
              const SizedBox(height: 12),
              _buildCylinderSelection(colors),
              if (_specificCylinder) ...[
                const SizedBox(height: 12),
                ZaftoInputField(label: 'Cylinder Number', unit: '', hint: 'Which cylinder?', controller: _cylinderController, onChanged: (_) => _analyze()),
              ],
              const SizedBox(height: 20),
              _buildSectionHeader(colors, 'SCAN DATA (Optional)'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: ZaftoInputField(label: 'Misfire Count', unit: '', hint: 'From scanner', controller: _misfireCountController, onChanged: (_) => _analyze())),
                  const SizedBox(width: 12),
                  Expanded(child: ZaftoInputField(label: 'RPM at Misfire', unit: 'rpm', hint: 'When it occurs', controller: _rpmController, onChanged: (_) => _analyze())),
                ],
              ),
              const SizedBox(height: 24),
              _buildAnalyzeButton(colors),
              const SizedBox(height: 24),
              if (_diagnosis != null) _buildResultsCard(colors),
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
          Text('Misfire = Ignition + Fuel + Compression', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
          const SizedBox(height: 8),
          Text('Select symptoms and conditions to narrow down the cause', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildSymptomGrid(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip(colors, 'Rough Idle', _roughIdle, (v) => setState(() { _roughIdle = v; })),
        _buildChip(colors, 'Hesitation', _hesitation, (v) => setState(() { _hesitation = v; })),
        _buildChip(colors, 'Power Loss', _powerLoss, (v) => setState(() { _powerLoss = v; })),
        _buildChip(colors, 'Check Engine', _checkEngineLight, (v) => setState(() { _checkEngineLight = v; })),
        _buildChip(colors, 'FLASHING CEL', _flashingCel, (v) => setState(() { _flashingCel = v; }), isWarning: true),
        _buildChip(colors, 'Poor MPG', _poorFuelEconomy, (v) => setState(() { _poorFuelEconomy = v; })),
        _buildChip(colors, 'Backfire', _backfire, (v) => setState(() { _backfire = v; }), isWarning: true),
        _buildChip(colors, 'Engine Shake', _engineShake, (v) => setState(() { _engineShake = v; })),
      ],
    );
  }

  Widget _buildConditionGrid(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip(colors, 'Cold Only', _coldOnly, (v) => setState(() { _coldOnly = v; _warmOnly = false; _allConditions = false; })),
        _buildChip(colors, 'Warm Only', _warmOnly, (v) => setState(() { _warmOnly = v; _coldOnly = false; _allConditions = false; })),
        _buildChip(colors, 'Under Load', _loadOnly, (v) => setState(() { _loadOnly = v; })),
        _buildChip(colors, 'All Conditions', _allConditions, (v) => setState(() { _allConditions = v; _coldOnly = false; _warmOnly = false; })),
      ],
    );
  }

  Widget _buildCylinderSelection(ZaftoColors colors) {
    return Row(
      children: [
        Expanded(child: _buildChip(colors, 'Random/Multiple', _randomCylinders, (v) => setState(() { _randomCylinders = v; _specificCylinder = false; }))),
        const SizedBox(width: 8),
        Expanded(child: _buildChip(colors, 'Specific Cylinder', _specificCylinder, (v) => setState(() { _specificCylinder = v; _randomCylinders = false; }))),
      ],
    );
  }

  Widget _buildChip(ZaftoColors colors, String label, bool selected, Function(bool) onChanged, {bool isWarning = false}) {
    final activeColor = isWarning ? Colors.red : colors.accentPrimary;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!selected);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.2) : colors.bgElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? activeColor : colors.borderSubtle),
        ),
        child: Text(label, style: TextStyle(color: selected ? activeColor : colors.textSecondary, fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }

  Widget _buildAnalyzeButton(ZaftoColors colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _analyze();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: colors.accentPrimary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.search, size: 20, color: colors.bgBase),
            const SizedBox(width: 8),
            Text('Analyze Misfire', style: TextStyle(color: colors.bgBase, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    Color statusColor;
    switch (_diagnosisColor) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Diagnosis', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(_diagnosis!, style: TextStyle(color: statusColor, fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              _buildSeverityIndicator(colors, statusColor),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Primary Cause', style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(_primaryCause!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          if (_possibleCauses.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('POSSIBLE CAUSES', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 8),
            ..._possibleCauses.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                    child: Center(child: Text('${entry.key + 1}', style: TextStyle(color: colors.accentPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(entry.value, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
                ],
              ),
            )),
          ],
          if (_diagnosticSteps.isNotEmpty) ...[
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
                      Icon(LucideIcons.clipboardList, size: 16, color: colors.accentPrimary),
                      const SizedBox(width: 8),
                      Text('Diagnostic Steps', style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._diagnosticSteps.map((step) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(step.startsWith('CAUTION') || step.startsWith('STOP') ? LucideIcons.alertTriangle : LucideIcons.chevronRight, size: 12, color: step.startsWith('CAUTION') || step.startsWith('STOP') ? Colors.red : colors.textTertiary),
                        const SizedBox(width: 4),
                        Expanded(child: Text(step, style: TextStyle(color: step.startsWith('CAUTION') || step.startsWith('STOP') ? Colors.red : colors.textSecondary, fontSize: 12, fontWeight: step.startsWith('CAUTION') || step.startsWith('STOP') ? FontWeight.w600 : FontWeight.w400))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildCommonCodesReference(colors),
        ],
      ),
    );
  }

  Widget _buildSeverityIndicator(ZaftoColors colors, Color statusColor) {
    return Column(
      children: [
        Text('Severity', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
        const SizedBox(height: 4),
        Row(
          children: List.generate(3, (index) {
            return Container(
              width: 20,
              height: 8,
              margin: const EdgeInsets.only(left: 2),
              decoration: BoxDecoration(
                color: index < _severity ? statusColor : colors.bgBase,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCommonCodesReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMMON MISFIRE CODES', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 8),
          _buildCodeRow(colors, 'P0300', 'Random/Multiple Cylinder Misfire'),
          _buildCodeRow(colors, 'P0301-P0308', 'Cylinder 1-8 Specific Misfire'),
          _buildCodeRow(colors, 'P0171/P0174', 'System Lean (often causes misfire)'),
          _buildCodeRow(colors, 'P0172/P0175', 'System Rich'),
          _buildCodeRow(colors, 'P0351-P0358', 'Ignition Coil Circuit'),
        ],
      ),
    );
  }

  Widget _buildCodeRow(ZaftoColors colors, String code, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(code, style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace'))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }
}
