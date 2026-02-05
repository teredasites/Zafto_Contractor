import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Cross Connection Control Calculator - Design System v2.6
///
/// Determines appropriate backflow prevention device based on hazard level.
/// Covers residential, commercial, and industrial applications.
///
/// References: IPC 2024 Section 608, AWWA M14
class CrossConnectionScreen extends ConsumerStatefulWidget {
  const CrossConnectionScreen({super.key});
  @override
  ConsumerState<CrossConnectionScreen> createState() => _CrossConnectionScreenState();
}

class _CrossConnectionScreenState extends ConsumerState<CrossConnectionScreen> {
  // Hazard level
  String _hazardLevel = 'low';

  // Application type
  String _applicationType = 'irrigation';

  // Continuous pressure
  bool _continuousPressure = true;

  static const Map<String, ({String desc, String example})> _hazardLevels = {
    'low': (desc: 'Low Hazard (Pollutant)', example: 'Food-grade substances'),
    'high': (desc: 'High Hazard (Contaminant)', example: 'Toxic, lethal substances'),
  };

  static const Map<String, ({String desc, String hazard, String device})> _applicationTypes = {
    'irrigation': (desc: 'Irrigation System', hazard: 'high', device: 'RPZ or PVB'),
    'fire_sprinkler': (desc: 'Fire Sprinkler (Non-antifreeze)', hazard: 'low', device: 'DCVA'),
    'fire_antifreeze': (desc: 'Fire Sprinkler (Antifreeze)', hazard: 'high', device: 'RPZ'),
    'boiler': (desc: 'Boiler Makeup', hazard: 'high', device: 'RPZ'),
    'hvac': (desc: 'HVAC/Cooling Tower', hazard: 'high', device: 'RPZ'),
    'medical': (desc: 'Medical Equipment', hazard: 'high', device: 'RPZ'),
    'lab': (desc: 'Laboratory', hazard: 'high', device: 'RPZ'),
    'pool': (desc: 'Swimming Pool Fill', hazard: 'high', device: 'RPZ or AG'),
    'hose_bib': (desc: 'Hose Bib Connection', hazard: 'high', device: 'AVB or HVB'),
    'carbonation': (desc: 'Carbonation System', hazard: 'high', device: 'RPZ'),
  };

  static const Map<String, ({String name, String abbrev, bool testable, int minSize})> _devices = {
    'ag': (name: 'Air Gap', abbrev: 'AG', testable: false, minSize: 0),
    'rpz': (name: 'Reduced Pressure Zone', abbrev: 'RPZ', testable: true, minSize: 1),
    'dcva': (name: 'Double Check Valve Assembly', abbrev: 'DCVA', testable: true, minSize: 1),
    'pvb': (name: 'Pressure Vacuum Breaker', abbrev: 'PVB', testable: true, minSize: 1),
    'svb': (name: 'Spill-Resistant Vacuum Breaker', abbrev: 'SVB', testable: true, minSize: 1),
    'avb': (name: 'Atmospheric Vacuum Breaker', abbrev: 'AVB', testable: false, minSize: 0),
    'hvb': (name: 'Hose Bib Vacuum Breaker', abbrev: 'HVB', testable: false, minSize: 0),
  };

  // Recommended device
  String get _recommendedDevice {
    final app = _applicationTypes[_applicationType];
    if (app == null) return 'RPZ';

    // High hazard always needs RPZ or AG
    if (_hazardLevel == 'high' || app.hazard == 'high') {
      if (_applicationType == 'hose_bib') return 'AVB or HVB';
      if (_applicationType == 'pool') return 'RPZ or AG';
      return 'RPZ';
    }

    // Low hazard can use DCVA
    if (_continuousPressure) {
      return 'DCVA';
    }
    return 'PVB or SVB';
  }

  // Device details
  String get _deviceDescription {
    switch (_recommendedDevice) {
      case 'RPZ':
        return 'Reduced Pressure Zone assembly provides highest protection. Required for all high-hazard connections.';
      case 'DCVA':
        return 'Double Check Valve Assembly suitable for low-hazard connections with continuous pressure.';
      case 'PVB or SVB':
        return 'Pressure or Spill-Resistant Vacuum Breaker for low-hazard, non-continuous pressure.';
      case 'AVB or HVB':
        return 'Atmospheric or Hose Bib Vacuum Breaker for hose connections.';
      case 'RPZ or AG':
        return 'RPZ or Air Gap required. Air gap provides absolute protection.';
      default:
        return 'Consult local authority for specific requirements.';
    }
  }

  // Annual test required
  bool get _annualTestRequired {
    final device = _recommendedDevice;
    return device.contains('RPZ') || device.contains('DCVA') ||
           device.contains('PVB') || device.contains('SVB');
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
          'Cross Connection Control',
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
          _buildPressureCard(colors),
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
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Recommended Device',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _deviceDescription,
              style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Hazard Level', _hazardLevel == 'high' ? 'High (Contaminant)' : 'Low (Pollutant)'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Annual Test', _annualTestRequired ? 'Required' : 'Not Required'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Certified Tester', _annualTestRequired ? 'Yes' : 'No'),
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
          ..._applicationTypes.entries.map((entry) {
            final isSelected = _applicationType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _applicationType = entry.key);
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: entry.value.hazard == 'high'
                              ? (isSelected ? Colors.black12 : colors.accentWarning.withValues(alpha: 0.1))
                              : (isSelected ? Colors.black12 : colors.accentPrimary.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.value.hazard == 'high' ? 'HIGH' : 'LOW',
                          style: TextStyle(
                            color: isSelected
                                ? (colors.isDark ? Colors.black54 : Colors.white70)
                                : (entry.value.hazard == 'high' ? colors.accentWarning : colors.accentPrimary),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
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
          ..._hazardLevels.entries.map((entry) {
            final isSelected = _hazardLevel == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _hazardLevel = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.value.desc,
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        entry.value.example,
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

  Widget _buildPressureCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _continuousPressure ? colors.bgElevated : colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: !_continuousPressure ? Border.all(color: colors.accentPrimary) : null,
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _continuousPressure = !_continuousPressure);
        },
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _continuousPressure ? colors.accentPrimary : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _continuousPressure ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: _continuousPressure
                  ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Continuous Pressure',
                    style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'System maintains pressure at all times',
                    style: TextStyle(color: colors.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
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
              Icon(LucideIcons.shieldCheck, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC 2024 Section 608',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Air gap = 2× supply diameter min\n'
            '• RPZ: Install 12-60" AFF\n'
            '• Annual testing by certified tester\n'
            '• Submit test reports to authority\n'
            '• No bypasses around device\n'
            '• Isolate before testing',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
