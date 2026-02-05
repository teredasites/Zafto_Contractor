import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Vacuum Breaker Selection Calculator - Design System v2.6
///
/// Selects appropriate vacuum breaker type for applications.
/// Covers AVB, PVB, SVB, and other backflow prevention devices.
///
/// References: IPC 2024 Section 608, ASSE Standards
class VacuumBreakerScreen extends ConsumerStatefulWidget {
  const VacuumBreakerScreen({super.key});
  @override
  ConsumerState<VacuumBreakerScreen> createState() => _VacuumBreakerScreenState();
}

class _VacuumBreakerScreenState extends ConsumerState<VacuumBreakerScreen> {
  // Application type
  String _application = 'hose_bib';

  // Hazard level
  String _hazard = 'low';

  // Installation conditions
  bool _backPressure = false;
  bool _continuous = false;
  bool _belowGrade = false;

  static const Map<String, ({String desc, String defaultDevice, bool outdoorOk})> _applications = {
    'hose_bib': (desc: 'Hose Bib/Sillcock', defaultDevice: 'HVB', outdoorOk: true),
    'irrigation': (desc: 'Irrigation System', defaultDevice: 'PVB', outdoorOk: true),
    'toilet_tank': (desc: 'Toilet Fill Valve', defaultDevice: 'AVB', outdoorOk: false),
    'commercial_sink': (desc: 'Commercial Sink Sprayer', defaultDevice: 'AVB', outdoorOk: false),
    'lab_equipment': (desc: 'Laboratory Equipment', defaultDevice: 'RPZ', outdoorOk: false),
    'boiler_fill': (desc: 'Boiler Makeup Water', defaultDevice: 'RPZ', outdoorOk: false),
    'fire_sprinkler': (desc: 'Fire Sprinkler Connection', defaultDevice: 'DCVA', outdoorOk: true),
  };

  static const Map<String, ({String desc, int severity})> _hazards = {
    'low': (desc: 'Low (Non-toxic)', severity: 1),
    'moderate': (desc: 'Moderate (Aesthetic)', severity: 2),
    'high': (desc: 'High (Health Hazard)', severity: 3),
  };

  // Recommended device based on conditions
  String get _recommendedDevice {
    final hazardLevel = _hazards[_hazard]?.severity ?? 1;

    // High hazard always needs RPZ
    if (hazardLevel >= 3) return 'RPZ';

    // Back pressure requires DCVA or RPZ
    if (_backPressure) {
      return hazardLevel >= 2 ? 'RPZ' : 'DCVA';
    }

    // Below grade needs RPZ or DCVA
    if (_belowGrade) {
      return hazardLevel >= 2 ? 'RPZ' : 'DCVA';
    }

    // Continuous use needs PVB (not AVB)
    if (_continuous) {
      return hazardLevel >= 2 ? 'SVB' : 'PVB';
    }

    // Default based on application
    return _applications[_application]?.defaultDevice ?? 'AVB';
  }

  // Device full name
  String get _deviceFullName {
    switch (_recommendedDevice) {
      case 'AVB': return 'Atmospheric Vacuum Breaker';
      case 'PVB': return 'Pressure Vacuum Breaker';
      case 'SVB': return 'Spill-Resistant Vacuum Breaker';
      case 'HVB': return 'Hose Vacuum Breaker';
      case 'DCVA': return 'Double Check Valve Assembly';
      case 'RPZ': return 'Reduced Pressure Zone';
      default: return 'Vacuum Breaker';
    }
  }

  // ASSE standard
  String get _asseStandard {
    switch (_recommendedDevice) {
      case 'AVB': return 'ASSE 1001';
      case 'PVB': return 'ASSE 1020';
      case 'SVB': return 'ASSE 1056';
      case 'HVB': return 'ASSE 1011';
      case 'DCVA': return 'ASSE 1015';
      case 'RPZ': return 'ASSE 1013';
      default: return 'ASSE 1001';
    }
  }

  // Installation notes
  String get _installationNotes {
    switch (_recommendedDevice) {
      case 'AVB':
        return '• Install 6\" above highest outlet\n• No shutoff downstream\n• Non-continuous use only';
      case 'PVB':
        return '• Install 12\" above highest outlet\n• Shutoff downstream OK\n• Annual testing required';
      case 'SVB':
        return '• Install 6\" above highest outlet\n• Shutoff downstream OK\n• Continuous use OK';
      case 'HVB':
        return '• Thread onto hose bib\n• Seasonal removal in cold climates\n• Replace if damaged';
      case 'DCVA':
        return '• Horizontal or vertical install\n• Annual testing required\n• Access for maintenance';
      case 'RPZ':
        return '• Requires floor drain\n• Annual testing required\n• Protected from freezing';
      default:
        return '• Follow manufacturer specs';
    }
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
        title: Text(
          'Vacuum Breaker Selection',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildApplicationCard(colors),
          const SizedBox(height: 16),
          _buildHazardCard(colors),
          const SizedBox(height: 16),
          _buildConditionsCard(colors),
          const SizedBox(height: 16),
          _buildInstallationCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            _recommendedDevice,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            _deviceFullName,
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Standard', _asseStandard),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Application', _applications[_application]?.desc ?? ''),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Hazard Level', _hazards[_hazard]?.desc ?? ''),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Testing', _recommendedDevice == 'AVB' || _recommendedDevice == 'HVB' ? 'Visual inspection' : 'Annual'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'APPLICATION',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._applications.entries.map((entry) {
            final isSelected = _application == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _application = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.value.desc,
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        entry.value.defaultDevice,
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHazardCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HAZARD LEVEL',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._hazards.entries.map((entry) {
            final isSelected = _hazard == entry.key;
            Color severityColor;
            switch (entry.value.severity) {
              case 1: severityColor = colors.accentSuccess; break;
              case 2: severityColor = colors.accentWarning; break;
              default: severityColor = colors.accentError;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _hazard = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isSelected ? (colors.isDark ? Colors.black38 : Colors.white38) : severityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value.desc,
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConditionsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INSTALLATION CONDITIONS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildToggleRow(colors, 'Back Pressure Possible', 'Pump or elevation downstream', _backPressure, (v) => setState(() => _backPressure = v)),
          _buildToggleRow(colors, 'Continuous Use', 'Valve stays open for periods', _continuous, (v) => setState(() => _continuous = v)),
          _buildToggleRow(colors, 'Below Grade/Flood Level', 'Potential for submersion', _belowGrade, (v) => setState(() => _belowGrade = v)),
        ],
      ),
    );
  }

  Widget _buildToggleRow(ZaftoColors colors, String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value ? colors.accentPrimary : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: value ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: value
                  ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(subtitle, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallationCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.wrench, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Installation Notes',
                style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _installationNotes,
            style: TextStyle(color: colors.textSecondary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.shield, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC 2024 Section 608',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Table 608.1: Device selection\n'
            '• AVB: 6\" above highest outlet\n'
            '• PVB: 12\" above highest outlet\n'
            '• RPZ: Protected from flooding\n'
            '• Annual testing for testable devices\n'
            '• Certified installer required',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
