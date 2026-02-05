import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Rapid Shutdown Compliance Calculator - NEC 690.12
class RapidShutdownScreen extends ConsumerStatefulWidget {
  const RapidShutdownScreen({super.key});
  @override
  ConsumerState<RapidShutdownScreen> createState() => _RapidShutdownScreenState();
}

class _RapidShutdownScreenState extends ConsumerState<RapidShutdownScreen> {
  String _buildingType = 'Residential';
  String _necVersion = '2020/2023';
  String _arrayType = 'Rooftop';
  bool _hasMLPE = true;

  String? _requirement;
  String? _arrayBoundary;
  String? _voltageLimit;
  List<String>? _solutions;
  bool? _isCompliant;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    List<String> solutions = [];
    String requirement;
    String arrayBoundary;
    String voltageLimit;
    bool isCompliant;

    if (_necVersion == '2017') {
      // 2017 NEC - Array boundary only
      requirement = 'NEC 690.12(B) - Array boundary rapid shutdown';
      arrayBoundary = '10 ft from array';
      voltageLimit = '30V within 30 seconds';
      isCompliant = true; // Any inverter with RSD function works
      solutions = [
        'String inverter with integrated RSD',
        'RSD transmitter + module-level receivers',
        'Microinverters (inherent compliance)',
        'DC optimizers with safe voltage',
      ];
    } else {
      // 2020/2023 NEC - Module-level requirements
      requirement = 'NEC 690.12(B)(2) - Module-level rapid shutdown (MLRSD)';
      arrayBoundary = '1 ft from each module';
      voltageLimit = '80V within 30 seconds';

      if (_hasMLPE) {
        isCompliant = true;
        solutions = [
          'Microinverters (Enphase, APsystems)',
          'DC Optimizers (SolarEdge, Tigo)',
          'Module-level RSD devices',
        ];
      } else {
        isCompliant = false;
        solutions = [
          'Add module-level power electronics',
          'Use microinverters instead of string inverter',
          'Install DC optimizers on each module',
        ];
      }
    }

    // Ground mount exception
    if (_arrayType == 'Ground Mount') {
      requirement = 'Ground mount systems may be exempt from RSD per 690.12(A)';
      isCompliant = true;
      solutions = ['Verify with AHJ - ground mounts often exempt if >8ft clearance'];
    }

    setState(() {
      _requirement = requirement;
      _arrayBoundary = arrayBoundary;
      _voltageLimit = voltageLimit;
      _solutions = solutions;
      _isCompliant = isCompliant;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    setState(() {
      _buildingType = 'Residential';
      _necVersion = '2020/2023';
      _arrayType = 'Rooftop';
      _hasMLPE = true;
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
        title: Text('Rapid Shutdown', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'PROJECT TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CODE VERSION'),
              const SizedBox(height: 12),
              _buildCodeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'EQUIPMENT'),
              const SizedBox(height: 12),
              _buildEquipmentToggle(colors),
              const SizedBox(height: 32),
              if (_requirement != null) ...[
                _buildSectionHeader(colors, 'COMPLIANCE STATUS'),
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
              Icon(LucideIcons.shieldAlert, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Rapid Shutdown (RSD)',
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
            'Determine NEC 690.12 rapid shutdown requirements',
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

  Widget _buildTypeSelector(ZaftoColors colors) {
    final types = ['Rooftop', 'Ground Mount'];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: types.map((type) {
          final isSelected = _arrayType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _arrayType = type);
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
                    type,
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

  Widget _buildCodeSelector(ZaftoColors colors) {
    final codes = ['2017', '2020/2023'];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: codes.map((code) {
          final isSelected = _necVersion == code;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _necVersion = code);
                _calculate();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentInfo : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'NEC $code',
                      style: TextStyle(
                        color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    Text(
                      code == '2017' ? 'Array-level' : 'Module-level',
                      style: TextStyle(
                        color: isSelected ? (colors.isDark ? Colors.black : Colors.white).withValues(alpha: 0.7) : colors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEquipmentToggle(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.cpu, size: 20, color: _hasMLPE ? colors.accentPrimary : colors.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Module-Level Power Electronics',
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                ),
                Text(
                  'Microinverters, DC optimizers, or MLRSD devices',
                  style: TextStyle(color: colors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _hasMLPE = !_hasMLPE);
              _calculate();
            },
            child: Container(
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: _hasMLPE ? colors.accentSuccess : colors.fillDefault,
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                alignment: _hasMLPE ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _hasMLPE ? (colors.isDark ? Colors.black : Colors.white) : colors.textTertiary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final statusColor = _isCompliant! ? colors.accentSuccess : colors.accentError;

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
                _isCompliant! ? LucideIcons.checkCircle : LucideIcons.xCircle,
                color: statusColor,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                _isCompliant! ? 'COMPLIANT' : 'NOT COMPLIANT',
                style: TextStyle(color: statusColor, fontSize: 24, fontWeight: FontWeight.w700),
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
                Text(_requirement!, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                if (_arrayType == 'Rooftop') ...[
                  const SizedBox(height: 8),
                  _buildSpecRow(colors, 'Boundary', _arrayBoundary!),
                  _buildSpecRow(colors, 'Voltage Limit', _voltageLimit!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
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
          Text(
            _isCompliant! ? 'COMPLIANT SOLUTIONS' : 'REQUIRED ACTIONS',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          ...(_solutions ?? []).map((solution) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  _isCompliant! ? LucideIcons.check : LucideIcons.arrowRight,
                  size: 14,
                  color: _isCompliant! ? colors.accentSuccess : colors.accentWarning,
                ),
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
