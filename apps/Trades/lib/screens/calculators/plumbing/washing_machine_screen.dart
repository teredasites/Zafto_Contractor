import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Washing Machine Rough-In Calculator - Design System v2.6
///
/// Calculates rough-in dimensions for residential washing machines.
/// Covers outlet box, standpipe, and supply requirements.
///
/// References: IPC 2024 Section 802.4
class WashingMachineScreen extends ConsumerStatefulWidget {
  const WashingMachineScreen({super.key});
  @override
  ConsumerState<WashingMachineScreen> createState() => _WashingMachineScreenState();
}

class _WashingMachineScreenState extends ConsumerState<WashingMachineScreen> {
  // Installation type
  String _installType = 'outlet_box';

  // Machine type
  String _machineType = 'standard';

  // Location
  String _location = 'laundry_room';

  static const Map<String, ({String desc, int standpipeHeight, int supplyHeight})> _installTypes = {
    'outlet_box': (desc: 'Outlet Box (Recessed)', standpipeHeight: 42, supplyHeight: 42),
    'exposed': (desc: 'Exposed Plumbing', standpipeHeight: 36, supplyHeight: 48),
    'stacked': (desc: 'Stacked Unit', standpipeHeight: 60, supplyHeight: 60),
  };

  static const Map<String, ({String desc, int dfu, double gpm})> _machineTypes = {
    'standard': (desc: 'Standard Top Load', dfu: 2, gpm: 4.0),
    'high_efficiency': (desc: 'High Efficiency', dfu: 2, gpm: 2.5),
    'commercial': (desc: 'Commercial', dfu: 3, gpm: 6.0),
  };

  static const Map<String, ({String desc, bool floorDrain})> _locations = {
    'laundry_room': (desc: 'Dedicated Laundry Room', floorDrain: true),
    'basement': (desc: 'Basement', floorDrain: true),
    'closet': (desc: 'Closet/Alcove', floorDrain: false),
    'garage': (desc: 'Garage', floorDrain: true),
    'upstairs': (desc: 'Upstairs/2nd Floor', floorDrain: false),
  };

  // Rough-in dimensions
  Map<String, String> get _roughInDimensions {
    final install = _installTypes[_installType];

    return {
      'Supply height': '${install?.supplyHeight ?? 42}\" AFF',
      'Supply spacing': '6\" center-to-center',
      'Standpipe height': '${install?.standpipeHeight ?? 42}\" AFF',
      'Standpipe size': '2\" minimum',
      'Trap size': '2\" P-trap',
      'Vent': '1½\" minimum',
    };
  }

  // Machine specs
  String get _drainGpm => '${_machineTypes[_machineType]?.gpm ?? 4.0} GPM';
  int get _dfu => _machineTypes[_machineType]?.dfu ?? 2;
  bool get _needsFloorDrain => _locations[_location]?.floorDrain ?? false;

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
          'Washing Machine Rough-In',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildInstallTypeCard(colors),
          const SizedBox(height: 16),
          _buildMachineTypeCard(colors),
          const SizedBox(height: 16),
          _buildLocationCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final install = _installTypes[_installType];

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
            '${install?.standpipeHeight ?? 42}\"',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Standpipe Height (AFF)',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ROUGH-IN DIMENSIONS',
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                ..._roughInDimensions.entries.map((entry) =>
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _buildResultRow(colors, entry.key, entry.value),
                  ),
                ),
                Divider(color: colors.borderSubtle, height: 16),
                _buildResultRow(colors, 'DFU', '$_dfu'),
                const SizedBox(height: 4),
                _buildResultRow(colors, 'Drain Rate', _drainGpm),
                if (_needsFloorDrain) ...[
                  const SizedBox(height: 4),
                  _buildResultRow(colors, 'Floor Drain', 'Recommended'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallTypeCard(ZaftoColors colors) {
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
            'INSTALLATION TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._installTypes.entries.map((entry) {
            final isSelected = _installType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _installType = entry.key);
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

  Widget _buildMachineTypeCard(ZaftoColors colors) {
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
            'MACHINE TYPE',
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
            children: _machineTypes.entries.map((entry) {
              final isSelected = _machineType == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _machineType = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value.desc,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 12,
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

  Widget _buildLocationCard(ZaftoColors colors) {
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
            'LOCATION',
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
            children: _locations.entries.map((entry) {
              final isSelected = _location == entry.key;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _location = entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value.desc,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 12,
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
              Icon(LucideIcons.waves, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC 2024 Section 802.4',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Standpipe: 18\" - 42\" AFF\n'
            '• Standpipe: 2\" minimum diameter\n'
            '• Air gap: 1\" above flood rim\n'
            '• Supply: ½\" minimum\n'
            '• Hammer arresters recommended\n'
            '• Single lever shutoffs accessible',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
