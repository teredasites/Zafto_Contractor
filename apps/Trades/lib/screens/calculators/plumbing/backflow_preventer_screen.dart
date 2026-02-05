import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Backflow Preventer Selection - Design System v2.6
///
/// Helps select the correct backflow prevention device based on hazard level
/// and application type per IPC/ASSE standards.
///
/// References: IPC 608, ASSE 1001-1056 standards
class BackflowPreventerScreen extends ConsumerStatefulWidget {
  const BackflowPreventerScreen({super.key});
  @override
  ConsumerState<BackflowPreventerScreen> createState() => _BackflowPreventerScreenState();
}

class _BackflowPreventerScreenState extends ConsumerState<BackflowPreventerScreen> {
  // Hazard level
  String _hazardLevel = 'high'; // 'low' (pollution) or 'high' (contamination)

  // Connection type
  String _connectionType = 'direct'; // 'direct' or 'indirect' or 'submerged'

  // Application
  String _application = 'irrigation';

  // Pipe size
  String _pipeSize = '1';

  // Backpressure vs backsiphonage
  bool _backpressure = false;

  // Applications with hazard classifications
  static const Map<String, ({String hazard, String desc, List<String> devices})> _applications = {
    'irrigation': (
      hazard: 'high',
      desc: 'Lawn/garden sprinklers',
      devices: ['RP', 'PVB', 'SVB'],
    ),
    'boiler': (
      hazard: 'high',
      desc: 'Heating system makeup',
      devices: ['RP', 'DCB'],
    ),
    'fireService': (
      hazard: 'high',
      desc: 'Fire sprinkler/standpipe',
      devices: ['RP', 'DCDA', 'DCB'],
    ),
    'labEquip': (
      hazard: 'high',
      desc: 'Lab sinks, medical equip',
      devices: ['RP', 'AG'],
    ),
    'pool': (
      hazard: 'high',
      desc: 'Swimming pool fill',
      devices: ['RP', 'AG'],
    ),
    'hosebibb': (
      hazard: 'high',
      desc: 'Outdoor hose connections',
      devices: ['HVB', 'AVB'],
    ),
    'coffeeMaker': (
      hazard: 'low',
      desc: 'Coffee/ice machines',
      devices: ['DCB', 'AG'],
    ),
    'dishwasher': (
      hazard: 'low',
      desc: 'Commercial dishwasher',
      devices: ['DCB', 'AG'],
    ),
    'coolingTower': (
      hazard: 'high',
      desc: 'HVAC cooling tower',
      devices: ['RP', 'AG'],
    ),
    'processWater': (
      hazard: 'high',
      desc: 'Industrial processes',
      devices: ['RP', 'AG'],
    ),
  };

  // Device types with descriptions
  static const Map<String, ({String name, String desc, bool backpressure, String hazard, String asse})> _deviceTypes = {
    'AG': (
      name: 'Air Gap',
      desc: 'Physical separation, highest protection',
      backpressure: true,
      hazard: 'high',
      asse: 'ASSE 1001',
    ),
    'RP': (
      name: 'Reduced Pressure Zone (RPZ)',
      desc: 'Testable, high hazard, backpressure OK',
      backpressure: true,
      hazard: 'high',
      asse: 'ASSE 1013',
    ),
    'DCB': (
      name: 'Double Check Valve',
      desc: 'Testable, low hazard only',
      backpressure: true,
      hazard: 'low',
      asse: 'ASSE 1015',
    ),
    'DCDA': (
      name: 'Double Check Detector Assembly',
      desc: 'Fire service with meter',
      backpressure: true,
      hazard: 'low',
      asse: 'ASSE 1048',
    ),
    'PVB': (
      name: 'Pressure Vacuum Breaker',
      desc: 'High hazard, backsiphonage only',
      backpressure: false,
      hazard: 'high',
      asse: 'ASSE 1020',
    ),
    'SVB': (
      name: 'Spill-Resistant Vacuum Breaker',
      desc: 'Similar to PVB, less spillage',
      backpressure: false,
      hazard: 'high',
      asse: 'ASSE 1056',
    ),
    'AVB': (
      name: 'Atmospheric Vacuum Breaker',
      desc: 'Backsiphonage only, no valves downstream',
      backpressure: false,
      hazard: 'high',
      asse: 'ASSE 1001',
    ),
    'HVB': (
      name: 'Hose Connection Vacuum Breaker',
      desc: 'Hose bibbs and outlets',
      backpressure: false,
      hazard: 'high',
      asse: 'ASSE 1011',
    ),
  };

  List<String> get _recommendedDevices {
    final app = _applications[_application];
    if (app == null) return ['RP', 'AG'];

    List<String> devices = List.from(app.devices);

    // Filter by backpressure capability if needed
    if (_backpressure) {
      devices = devices.where((d) => _deviceTypes[d]?.backpressure == true).toList();
    }

    // Filter by hazard level
    if (_hazardLevel == 'high') {
      devices = devices.where((d) {
        final dev = _deviceTypes[d];
        return dev?.hazard == 'high' || d == 'AG' || d == 'RP';
      }).toList();
    }

    if (devices.isEmpty) {
      return ['RP', 'AG']; // Default to highest protection
    }

    return devices;
  }

  String get _primaryRecommendation {
    final devices = _recommendedDevices;
    if (_hazardLevel == 'high' && _backpressure) return 'RP';
    if (_hazardLevel == 'high' && !_backpressure) return devices.contains('PVB') ? 'PVB' : 'RP';
    if (_hazardLevel == 'low' && _backpressure) return 'DCB';
    return devices.isNotEmpty ? devices.first : 'RP';
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
          'Backflow Preventer',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildApplicationCard(colors),
          const SizedBox(height: 16),
          _buildHazardCard(colors),
          const SizedBox(height: 16),
          _buildConditionsCard(colors),
          const SizedBox(height: 16),
          _buildPipeSizeCard(colors),
          const SizedBox(height: 16),
          _buildDeviceGuide(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final primary = _primaryRecommendation;
    final device = _deviceTypes[primary];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: colors.accentPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              primary,
              style: TextStyle(
                color: colors.isDark ? Colors.black : Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            device?.name ?? 'Unknown Device',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            device?.desc ?? '',
            style: TextStyle(color: colors.textTertiary, fontSize: 13),
            textAlign: TextAlign.center,
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
                _buildResultRow(colors, 'Standard', device?.asse ?? '-'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Hazard Level', _hazardLevel == 'high' ? 'High (Contamination)' : 'Low (Pollution)'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Backpressure', _backpressure ? 'Yes - Required' : 'No', highlight: _backpressure),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Pipe Size', '$_pipeSize"'),
              ],
            ),
          ),
          if (_recommendedDevices.length > 1) ...[
            const SizedBox(height: 12),
            Text(
              'Also acceptable: ${_recommendedDevices.where((d) => d != primary).join(", ")}',
              style: TextStyle(color: colors.textTertiary, fontSize: 11),
            ),
          ],
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
            'APPLICATION TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _applications.entries.map((entry) {
              final isSelected = _application == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _application = entry.key;
                    _hazardLevel = entry.value.hazard;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatAppName(entry.key),
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatAppName(String key) {
    switch (key) {
      case 'irrigation': return 'Irrigation';
      case 'boiler': return 'Boiler';
      case 'fireService': return 'Fire Service';
      case 'labEquip': return 'Lab/Medical';
      case 'pool': return 'Pool/Spa';
      case 'hosebibb': return 'Hose Bibb';
      case 'coffeeMaker': return 'Coffee/Ice';
      case 'dishwasher': return 'Dishwasher';
      case 'coolingTower': return 'Cooling Tower';
      case 'processWater': return 'Industrial';
      default: return key;
    }
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
          Row(
            children: [
              Expanded(child: _buildHazardChip(colors, 'low', 'Low (Pollution)', 'Non-toxic, aesthetic issues')),
              const SizedBox(width: 12),
              Expanded(child: _buildHazardChip(colors, 'high', 'High (Contamination)', 'Health hazard, toxic')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHazardChip(ZaftoColors colors, String value, String label, String desc) {
    final isSelected = _hazardLevel == value;
    final chipColor = value == 'high' ? colors.accentError : colors.accentWarning;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _hazardLevel = value);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withValues(alpha: 0.2) : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: chipColor) : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? chipColor : colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: TextStyle(color: colors.textTertiary, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
            'FLOW CONDITIONS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _backpressure = !_backpressure);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _backpressure ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
                borderRadius: BorderRadius.circular(8),
                border: _backpressure ? Border.all(color: colors.accentPrimary) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    _backpressure ? LucideIcons.checkSquare : LucideIcons.square,
                    color: _backpressure ? colors.accentPrimary : colors.textTertiary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Backpressure Possible',
                          style: TextStyle(
                            color: _backpressure ? colors.accentPrimary : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Downstream pressure can exceed supply (pumps, elevation, thermal)',
                          style: TextStyle(color: colors.textTertiary, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'If only backsiphonage (vacuum), more device options available',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildPipeSizeCard(ZaftoColors colors) {
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
            'PIPE SIZE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['1/2', '3/4', '1', '1-1/4', '1-1/2', '2', '2-1/2', '3', '4', '6'].map((size) {
              final isSelected = _pipeSize == size;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _pipeSize = size);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$size"',
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceGuide(ZaftoColors colors) {
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
            'DEVICE COMPARISON',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...['AG', 'RP', 'DCB', 'PVB', 'AVB', 'HVB'].map((code) {
            final device = _deviceTypes[code]!;
            final isRecommended = _recommendedDevices.contains(code);
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isRecommended ? colors.accentPrimary.withValues(alpha: 0.15) : colors.bgBase,
                borderRadius: BorderRadius.circular(8),
                border: isRecommended ? Border.all(color: colors.accentPrimary.withValues(alpha: 0.5)) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    alignment: Alignment.center,
                    child: Text(
                      code,
                      style: TextStyle(
                        color: isRecommended ? colors.accentPrimary : colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildBadge(colors, device.hazard == 'high' ? 'H' : 'L', device.hazard == 'high' ? colors.accentError : colors.accentWarning),
                      const SizedBox(width: 4),
                      _buildBadge(colors, device.backpressure ? 'BP' : 'BS', device.backpressure ? colors.accentPrimary : colors.textTertiary),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildBadge(colors, 'H', colors.accentError),
              const SizedBox(width: 4),
              Text('High Hazard  ', style: TextStyle(color: colors.textTertiary, fontSize: 9)),
              _buildBadge(colors, 'L', colors.accentWarning),
              const SizedBox(width: 4),
              Text('Low Hazard  ', style: TextStyle(color: colors.textTertiary, fontSize: 9)),
              _buildBadge(colors, 'BP', colors.accentPrimary),
              const SizedBox(width: 4),
              Text('Backpressure  ', style: TextStyle(color: colors.textTertiary, fontSize: 9)),
              _buildBadge(colors, 'BS', colors.textTertiary),
              const SizedBox(width: 4),
              Text('Backsiphon only', style: TextStyle(color: colors.textTertiary, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(ZaftoColors colors, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: highlight ? colors.accentPrimary : colors.textPrimary,
            fontSize: 13,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
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
              Icon(LucideIcons.scale, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC 2024 Section 608',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• 608.1 - Cross-connection control required\n'
            '• 608.13 - Device selection by hazard level\n'
            '• 608.13.2 - Low hazard: DC, AG acceptable\n'
            '• 608.13.7 - High hazard: RP, AG, PVB, SVB\n'
            '• 608.15.1 - Annual testing required (RP, DC)\n'
            '• USC FCCC Manual of Practice',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
