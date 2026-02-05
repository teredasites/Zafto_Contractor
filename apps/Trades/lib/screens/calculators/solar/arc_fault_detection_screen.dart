import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Arc Fault Detection Calculator - AFCI compliance
class ArcFaultDetectionScreen extends ConsumerStatefulWidget {
  const ArcFaultDetectionScreen({super.key});
  @override
  ConsumerState<ArcFaultDetectionScreen> createState() => _ArcFaultDetectionScreenState();
}

class _ArcFaultDetectionScreenState extends ConsumerState<ArcFaultDetectionScreen> {
  String _arrayLocation = 'Rooftop';
  String _necVersion = '2020/2023';
  final _dcVoltageController = TextEditingController(text: '80');

  bool? _afciRequired;
  String? _requirement;
  List<String>? _solutions;
  List<String>? _notes;

  @override
  void dispose() {
    _dcVoltageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final dcVoltage = double.tryParse(_dcVoltageController.text) ?? 80;

    bool afciRequired;
    String requirement;
    List<String> solutions = [];
    List<String> notes = [];

    // NEC 690.11 - DC arc-fault circuit protection
    if (_arrayLocation == 'Rooftop' && dcVoltage > 80) {
      afciRequired = true;
      requirement = 'NEC 690.11 - DC AFCI required for rooftop systems >80V';
      solutions = [
        'String inverter with integrated AFCI',
        'DC optimizers (SolarEdge SafeDC)',
        'Microinverters (module-level AC)',
        'Standalone AFCI devices',
      ];
      notes = [
        'Must detect and interrupt DC series arcs',
        'Listed to UL 1699B',
        'Most modern inverters include this protection',
        'Required for fire safety on buildings',
      ];
    } else if (_arrayLocation == 'Ground Mount') {
      afciRequired = false;
      requirement = 'Ground mount systems typically exempt from AFCI per 690.11 Exception';
      solutions = ['AFCI still recommended for safety'];
      notes = [
        'Ground mounts have lower fire risk',
        'Check local AHJ requirements',
        'Consider AFCI for any DC >80V for safety',
      ];
    } else {
      afciRequired = false;
      requirement = 'Systems ≤80V DC exempt from AFCI requirement';
      solutions = ['Microinverter systems often qualify'];
      notes = [
        'Low voltage systems have reduced arc energy',
        'Per NEC 690.11 Exception 1',
      ];
    }

    setState(() {
      _afciRequired = afciRequired;
      _requirement = requirement;
      _solutions = solutions;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _dcVoltageController.text = '80';
    setState(() {
      _arrayLocation = 'Rooftop';
      _necVersion = '2020/2023';
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
        title: Text('Arc Fault Detection', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ARRAY LOCATION'),
              const SizedBox(height: 12),
              _buildLocationSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SYSTEM VOLTAGE'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Max DC Voltage',
                unit: 'V',
                hint: 'Operating voltage',
                controller: _dcVoltageController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_afciRequired != null) ...[
                _buildSectionHeader(colors, 'AFCI REQUIREMENTS'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildSolutionsCard(colors),
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
              Icon(LucideIcons.zap, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'DC Arc-Fault Protection',
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
            'Determine AFCI requirements per NEC 690.11',
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

  Widget _buildLocationSelector(ZaftoColors colors) {
    final locations = ['Rooftop', 'Ground Mount'];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: locations.map((location) {
          final isSelected = _arrayLocation == location;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _arrayLocation = location);
                _calculate();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    location,
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
    final statusColor = _afciRequired! ? colors.accentWarning : colors.accentSuccess;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _afciRequired! ? LucideIcons.alertTriangle : LucideIcons.checkCircle,
                color: statusColor,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                _afciRequired! ? 'AFCI REQUIRED' : 'AFCI NOT REQUIRED',
                style: TextStyle(color: statusColor, fontSize: 20, fontWeight: FontWeight.w700),
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
            child: Text(_requirement!, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
          ),
          const SizedBox(height: 12),
          ...(_notes ?? []).map((note) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, size: 12, color: colors.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(note, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSolutionsCard(ZaftoColors colors) {
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
          Text('COMPLIANT SOLUTIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          ...(_solutions ?? []).map((solution) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(LucideIcons.check, size: 14, color: colors.accentSuccess),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(solution, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
