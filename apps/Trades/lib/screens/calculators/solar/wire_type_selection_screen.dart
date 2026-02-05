import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Wire Type Selection Calculator - USE-2, PV wire, THWN-2 guide
class WireTypeSelectionScreen extends ConsumerStatefulWidget {
  const WireTypeSelectionScreen({super.key});
  @override
  ConsumerState<WireTypeSelectionScreen> createState() => _WireTypeSelectionScreenState();
}

class _WireTypeSelectionScreenState extends ConsumerState<WireTypeSelectionScreen> {
  bool _isExposedToSunlight = true;
  bool _isInConduit = false;
  bool _isDirectBuried = false;
  bool _isWetLocation = true;
  bool _needsFlexibility = false;

  String? _recommendedType;
  String? _alternateType;
  List<String>? _notes;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    List<String> notes = [];
    String recommendedType;
    String? alternateType;

    if (_isExposedToSunlight && !_isInConduit) {
      // Exposed PV wiring
      if (_needsFlexibility) {
        recommendedType = 'PV Wire';
        alternateType = 'USE-2';
        notes.add('PV Wire is more flexible for module-level connections');
        notes.add('Must be sunlight resistant (per NEC 690.31)');
      } else {
        recommendedType = 'USE-2';
        alternateType = 'PV Wire';
        notes.add('USE-2 rated for wet and sunlight-exposed locations');
        notes.add('Single conductor, 90°C temperature rating');
      }
    } else if (_isInConduit) {
      if (_isWetLocation) {
        recommendedType = 'THWN-2';
        alternateType = 'XHHW-2';
        notes.add('THWN-2 rated for wet locations in conduit');
        notes.add('Most common choice for AC output circuits');
      } else {
        recommendedType = 'THHN';
        alternateType = 'THWN-2';
        notes.add('THHN for dry locations (but THWN-2 works everywhere)');
      }
    } else if (_isDirectBuried) {
      recommendedType = 'USE-2';
      alternateType = null;
      notes.add('USE-2 is rated for direct burial without conduit');
      notes.add('Must maintain 18" minimum burial depth');
    } else {
      // Indoor/protected
      recommendedType = 'THWN-2';
      alternateType = 'USE-2';
      notes.add('THWN-2 versatile for most indoor applications');
    }

    // Add general notes
    if (_isExposedToSunlight) {
      notes.add('NEC 690.31(B) requires sunlight-resistant wire markings');
    }

    setState(() {
      _recommendedType = recommendedType;
      _alternateType = alternateType;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExposedToSunlight = true;
      _isInConduit = false;
      _isDirectBuried = false;
      _isWetLocation = true;
      _needsFlexibility = false;
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
        title: Text('Wire Type Selection', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'INSTALLATION CONDITIONS'),
              const SizedBox(height: 12),
              _buildConditionToggles(colors),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'RECOMMENDED WIRE TYPE'),
              const SizedBox(height: 12),
              _buildResultsCard(colors),
              const SizedBox(height: 16),
              _buildWireComparisonCard(colors),
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
              Icon(LucideIcons.checkSquare, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Wire Type Guide',
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
            'Select correct wire type based on installation environment',
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

  Widget _buildConditionToggles(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          _buildToggleRow(colors, LucideIcons.sun, 'Exposed to Sunlight', _isExposedToSunlight, (v) {
            setState(() => _isExposedToSunlight = v);
            _calculate();
          }),
          _buildToggleRow(colors, LucideIcons.pipette, 'In Conduit', _isInConduit, (v) {
            setState(() {
              _isInConduit = v;
              if (v) _isDirectBuried = false;
            });
            _calculate();
          }),
          _buildToggleRow(colors, LucideIcons.shovel, 'Direct Buried', _isDirectBuried, (v) {
            setState(() {
              _isDirectBuried = v;
              if (v) _isInConduit = false;
            });
            _calculate();
          }),
          _buildToggleRow(colors, LucideIcons.droplet, 'Wet Location', _isWetLocation, (v) {
            setState(() => _isWetLocation = v);
            _calculate();
          }),
          _buildToggleRow(colors, LucideIcons.move, 'Needs Flexibility', _needsFlexibility, (v) {
            setState(() => _needsFlexibility = v);
            _calculate();
          }),
        ],
      ),
    );
  }

  Widget _buildToggleRow(ZaftoColors colors, IconData icon, String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: value ? colors.accentPrimary : colors.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: value ? colors.textPrimary : colors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(!value);
            },
            child: Container(
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: value ? colors.accentPrimary : colors.fillDefault,
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: value ? (colors.isDark ? Colors.black : Colors.white) : colors.textTertiary,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 24),
              const SizedBox(width: 8),
              Text(
                _recommendedType ?? 'Unknown',
                style: TextStyle(color: colors.accentSuccess, fontSize: 32, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (_alternateType != null) ...[
            const SizedBox(height: 8),
            Text(
              'Alternate: $_alternateType',
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
          ],
          const SizedBox(height: 16),
          ...(_notes ?? []).map((note) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, size: 14, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildWireComparisonCard(ZaftoColors colors) {
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
          Text('WIRE TYPE COMPARISON', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 16),
          _buildWireTypeInfo(colors, 'USE-2', [
            'Underground Service Entrance',
            'Sunlight resistant',
            'Wet locations OK',
            'Direct burial rated',
            '90°C temperature',
          ]),
          const Divider(height: 24),
          _buildWireTypeInfo(colors, 'PV Wire', [
            'Specifically for PV systems',
            'More flexible than USE-2',
            'Sunlight resistant',
            'Wet locations OK',
            '90°C or higher',
          ]),
          const Divider(height: 24),
          _buildWireTypeInfo(colors, 'THWN-2', [
            'Thermoplastic insulation',
            'Wet and dry locations',
            'In conduit only',
            'NOT sunlight resistant alone',
            '90°C wet, 75°C dry',
          ]),
        ],
      ),
    );
  }

  Widget _buildWireTypeInfo(ZaftoColors colors, String type, List<String> features) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type,
          style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textTertiary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  feature,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
