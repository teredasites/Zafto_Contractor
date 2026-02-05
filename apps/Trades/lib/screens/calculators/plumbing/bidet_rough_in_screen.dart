import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Bidet Rough-In Calculator - Design System v2.6
///
/// Determines bidet and bidet seat rough-in dimensions.
/// Covers standalone bidets and bidet seat attachments.
///
/// References: IPC 2024 Section 405
class BidetRoughInScreen extends ConsumerStatefulWidget {
  const BidetRoughInScreen({super.key});
  @override
  ConsumerState<BidetRoughInScreen> createState() => _BidetRoughInScreenState();
}

class _BidetRoughInScreenState extends ConsumerState<BidetRoughInScreen> {
  // Bidet type
  String _bidetType = 'seat';

  // Electrical required (for bidet seats)
  bool _needsElectrical = true;

  static const Map<String, ({String desc, bool needsHot, bool needsDrain, bool needsOutlet})> _bidetTypes = {
    'seat': (desc: 'Bidet Seat (Toilet)', needsHot: false, needsDrain: false, needsOutlet: true),
    'attachment': (desc: 'Bidet Attachment', needsHot: false, needsDrain: false, needsOutlet: false),
    'standalone': (desc: 'Standalone Bidet', needsHot: true, needsDrain: true, needsOutlet: false),
    'wall_hung': (desc: 'Wall-Hung Bidet', needsHot: true, needsDrain: true, needsOutlet: false),
  };

  bool get _needsDrain => _bidetTypes[_bidetType]?.needsDrain ?? false;
  bool get _needsHotWater => _bidetTypes[_bidetType]?.needsHot ?? false;
  bool get _needsOutlet => _bidetTypes[_bidetType]?.needsOutlet ?? false;

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
          'Bidet Rough-In',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildBidetTypeCard(colors),
          const SizedBox(height: 16),
          _buildRequirementsCard(colors),
          const SizedBox(height: 16),
          _buildRoughInTable(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final drainText = _needsDrain ? '1¼"' : 'N/A';

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
            drainText,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            _needsDrain ? 'Drain Size' : 'No Separate Drain',
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
                _buildResultRow(colors, 'Type', _bidetTypes[_bidetType]?.desc ?? 'Bidet Seat'),
                const SizedBox(height: 10),
                _buildRequirementRow(colors, 'Cold Water', true),
                _buildRequirementRow(colors, 'Hot Water', _needsHotWater),
                _buildRequirementRow(colors, 'Separate Drain', _needsDrain),
                _buildRequirementRow(colors, 'Electrical Outlet', _needsOutlet),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(ZaftoColors colors, String label, bool required) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          Row(
            children: [
              Icon(
                required ? LucideIcons.check : LucideIcons.x,
                color: required ? colors.accentSuccess : colors.textTertiary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                required ? 'Required' : 'Not Required',
                style: TextStyle(
                  color: required ? colors.textPrimary : colors.textTertiary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBidetTypeCard(ZaftoColors colors) {
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
            'BIDET TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._bidetTypes.entries.map((entry) {
            final isSelected = _bidetType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _bidetType = entry.key);
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
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (entry.value.needsOutlet)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (colors.isDark ? Colors.black26 : Colors.white30)
                                : colors.accentWarning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Electrical',
                            style: TextStyle(
                              color: isSelected
                                  ? (colors.isDark ? Colors.black54 : Colors.white70)
                                  : colors.accentWarning,
                              fontSize: 10,
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

  Widget _buildRequirementsCard(ZaftoColors colors) {
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
            'INSTALLATION REQUIREMENTS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          if (_bidetType == 'seat' || _bidetType == 'attachment') ...[
            _buildReqRow(colors, LucideIcons.droplet, 'Cold Water', 'T-adapter from toilet supply', true),
            if (_bidetType == 'seat')
              _buildReqRow(colors, LucideIcons.plug, 'GFCI Outlet', '15A within 3\' of toilet', true),
          ] else ...[
            _buildReqRow(colors, LucideIcons.droplet, 'Hot & Cold', '½" supplies each', true),
            _buildReqRow(colors, LucideIcons.circleDot, 'P-Trap', '1¼" trap required', true),
            _buildReqRow(colors, LucideIcons.arrowDown, 'Drain', '1¼" to waste', true),
          ],
        ],
      ),
    );
  }

  Widget _buildReqRow(ZaftoColors colors, IconData icon, String title, String subtitle, bool active) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: active ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: active ? colors.accentPrimary : colors.textTertiary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: colors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoughInTable(ZaftoColors colors) {
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
            'ROUGH-IN DIMENSIONS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          if (_bidetType == 'seat' || _bidetType == 'attachment') ...[
            _buildDimRow(colors, 'Water Supply', 'Toilet shutoff (T-adapter)'),
            if (_bidetType == 'seat')
              _buildDimRow(colors, 'Electrical', 'GFCI outlet within 3\''),
            _buildDimRow(colors, 'Clearance', 'Standard toilet clearances'),
          ] else ...[
            _buildDimRow(colors, 'Rough-In', '14-15" from wall to drain C/L'),
            _buildDimRow(colors, 'Drain Height', '6-8" from floor'),
            _buildDimRow(colors, 'Supply Height', '8-10" from floor'),
            _buildDimRow(colors, 'Supply Spread', '4" or 8" center'),
            _buildDimRow(colors, 'Rim Height', '15-17" from floor'),
            _buildDimRow(colors, 'Side Clearance', '15" from C/L to wall'),
            _buildDimRow(colors, 'Front Clearance', '21" in front'),
          ],
        ],
      ),
    );
  }

  Widget _buildDimRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.dot, color: colors.accentPrimary, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: colors.textPrimary, fontSize: 12),
            ),
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
        Text(
          value,
          style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
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
                'IPC 2024 Section 405',
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
            '• Standalone bidet: 1¼" drain\n'
            '• Bidet seat: No additional drain\n'
            '• GFCI protection required (electrical)\n'
            '• Vacuum breaker required on supply\n'
            '• Clearances same as toilet\n'
            '• Hot water optional for seat types',
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
