import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class PanelMountingScreen extends ConsumerWidget {
  const PanelMountingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Panel Mounting & Racking',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewSection(colors),
            const SizedBox(height: 24),
            _buildMountingTypes(colors),
            const SizedBox(height: 24),
            _buildRoofAttachments(colors),
            const SizedBox(height: 24),
            _buildOrientationSection(colors),
            const SizedBox(height: 24),
            _buildStructuralRequirements(colors),
            const SizedBox(height: 24),
            _buildInstallationTips(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.layers, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Mounting System Overview',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Proper mounting ensures panel security, optimal orientation, code compliance, and long-term reliability. The racking system must withstand wind, snow, and seismic loads.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(colors, '25+', 'Year Warranty', LucideIcons.shield)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(colors, '90-150', 'MPH Wind Rating', LucideIcons.wind)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(colors, 'UL 2703', 'Listing Standard', LucideIcons.fileCheck)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(ZaftoColors colors, String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: colors.accentPrimary, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 9), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildMountingTypes(ZaftoColors colors) {
    final types = [
      {
        'name': 'Roof Mount (Flush)',
        'description': 'Panels parallel to roof surface. Most common residential installation.',
        'pros': ['Lower cost', 'Less visible', 'Easier permit'],
        'cons': ['Limited tilt adjustment', 'Takes roof angle'],
        'icon': LucideIcons.home,
        'color': colors.accentSuccess,
      },
      {
        'name': 'Roof Mount (Tilted)',
        'description': 'Panels tilted on brackets for optimal angle on flat or low-slope roofs.',
        'pros': ['Better production', 'Self-cleaning', 'Adjustable'],
        'cons': ['Higher cost', 'More wind load', 'Visible'],
        'icon': LucideIcons.triangle,
        'color': colors.accentInfo,
      },
      {
        'name': 'Ground Mount',
        'description': 'Steel or aluminum framework on concrete footings or ground screws.',
        'pros': ['Optimal orientation', 'Easy access', 'No roof work'],
        'cons': ['Uses land', 'Higher cost', 'Trenching needed'],
        'icon': LucideIcons.landmark,
        'color': colors.accentWarning,
      },
      {
        'name': 'Pole Mount',
        'description': 'Panels on single pole. Fixed or tracking options available.',
        'pros': ['Adjustable', 'Snow shedding', 'Small footprint'],
        'cons': ['Higher cost', 'Complex install', 'Wind exposure'],
        'icon': LucideIcons.flag,
        'color': colors.accentPrimary,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mounting System Types',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...types.map((t) => _buildMountTypeCard(colors, t)),
        ],
      ),
    );
  }

  Widget _buildMountTypeCard(ZaftoColors colors, Map<String, dynamic> type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (type['color'] as Color).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(type['icon'] as IconData, color: type['color'] as Color, size: 20),
              const SizedBox(width: 8),
              Text(type['name'] as String, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(type['description'] as String, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pros', style: TextStyle(color: colors.accentSuccess, fontSize: 10, fontWeight: FontWeight.w600)),
                    ...(type['pros'] as List<String>).map((p) =>
                      Text('• $p', style: TextStyle(color: colors.textSecondary, fontSize: 10))),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cons', style: TextStyle(color: colors.accentError, fontSize: 10, fontWeight: FontWeight.w600)),
                    ...(type['cons'] as List<String>).map((c) =>
                      Text('• $c', style: TextStyle(color: colors.textSecondary, fontSize: 10))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoofAttachments(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Roof Attachment Methods',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '''
COMPOSITION SHINGLE ROOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                 ┌─── Rail ───┐
                 │            │
    ┌────────────┴────────────┴────────────┐
    │        L-Foot / Standoff             │
    │  ┌────┐              ┌────┐          │
    │  │    │              │    │          │
    │  │ ▼  │   Flashing   │ ▼  │          │
═══════╪════╪══════════════╪════╪══════════════
    │  │    │   ┌──────┐   │    │          │   ← Shingles
    │  └──┬─┘   │      │   └──┬─┘          │
    │     │     │      │      │            │
──────────┼─────┼──────┼──────┼────────────────
          │     └──────┘      │               ← Deck
          │       Lag         │
          │       Bolt        │
──────────┼───────────────────┼────────────────
          │                   │               ← Rafter
          ▼                   ▼

STANDING SEAM METAL ROOF (Non-Penetrating)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ┌─── Rail ───┐
    │            │
    │  S-5 Clamp │
    │   ┌──┐     │
════╪═══│  │═════╪════════════════════════════
    │   │  │     │
    │   └┬─┘     │   ← Seam Clamp grips seam
    │    │       │     NO roof penetration!
════════╪════════════════════════════════════''',
              style: TextStyle(
                color: colors.accentPrimary,
                fontFamily: 'monospace',
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildAttachmentNote(colors, 'Comp Shingle', 'Flashed L-foot into rafter, min 5/16" lag'),
          _buildAttachmentNote(colors, 'Tile Roof', 'Comp tile replacement or tile hook'),
          _buildAttachmentNote(colors, 'Metal Standing Seam', 'S-5 or similar clamp - no penetrations'),
          _buildAttachmentNote(colors, 'Flat/TPO/EPDM', 'Ballasted or adhesive with membrane boots'),
        ],
      ),
    );
  }

  Widget _buildAttachmentNote(ZaftoColors colors, String roof, String method) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(roof, style: TextStyle(color: colors.accentWarning, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          Expanded(child: Text(method, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildOrientationSection(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.compass, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Orientation & Tilt',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOrientationCard(colors, 'Azimuth', 'South-facing = 180°\n(Northern Hemisphere)',
                  'SE/SW lose ~5%\nE/W lose ~15%', LucideIcons.navigation),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOrientationCard(colors, 'Tilt Angle', 'Optimal = Latitude\n(e.g., 40° in CT)',
                  'Flat roof: 10-15°\nSteep: match roof', LucideIcons.mountain),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Production by Orientation:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                _buildProductionRow(colors, 'South', '100%', colors.accentSuccess),
                _buildProductionRow(colors, 'Southeast/Southwest', '~95%', colors.accentSuccess),
                _buildProductionRow(colors, 'East/West', '~85%', colors.accentWarning),
                _buildProductionRow(colors, 'North', '~60%', colors.accentError),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrientationCard(ZaftoColors colors, String title, String optimal, String notes, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: colors.accentWarning, size: 24),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(optimal, style: TextStyle(color: colors.accentSuccess, fontSize: 11), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(notes, style: TextStyle(color: colors.textTertiary, fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildProductionRow(ZaftoColors colors, String direction, String production, Color barColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(direction, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
          Expanded(
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: colors.bgBase,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: double.parse(production.replaceAll(RegExp(r'[^0-9]'), '')) / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 40, child: Text(production, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildStructuralRequirements(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentError.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.hardHat, color: colors.accentError, size: 20),
              const SizedBox(width: 8),
              Text(
                'Structural Requirements',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRequirementItem(colors, 'Dead Load', 'Array weight ~2.5-4 PSF. Verify roof can support.'),
          _buildRequirementItem(colors, 'Wind Load', 'Per ASCE 7. Higher at edges/corners. Wind tunnel tested.'),
          _buildRequirementItem(colors, 'Snow Load', 'Per local code. Panels may increase or decrease load.'),
          _buildRequirementItem(colors, 'Seismic', 'Required in seismic zones per IBC.'),
          _buildRequirementItem(colors, 'Attachment', 'Into rafters or blocking. Min 5/16" lag, 2.5" embedment.'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentError.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Structural engineering letter may be required by AHJ for permit approval.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(ZaftoColors colors, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.check, color: colors.accentSuccess, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: '$title: ', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  TextSpan(text: description, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallationTips(ZaftoColors colors) {
    final tips = [
      {'tip': 'Use stainless steel hardware or match rail metal', 'icon': LucideIcons.wrench},
      {'tip': 'Pre-drill pilot holes to prevent splitting', 'icon': LucideIcons.circleDot},
      {'tip': 'Apply sealant under all flashings', 'icon': LucideIcons.droplet},
      {'tip': 'Torque all bolts to manufacturer spec', 'icon': LucideIcons.gauge},
      {'tip': 'Maintain 3ft fire setbacks from ridge/edges', 'icon': LucideIcons.flame},
      {'tip': 'Leave gaps for thermal expansion', 'icon': LucideIcons.thermometer},
      {'tip': 'Bond all metal per NEC 690.43', 'icon': LucideIcons.link},
      {'tip': 'Document attachment locations for inspection', 'icon': LucideIcons.camera},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.lightbulb, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Installation Best Practices',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3,
            children: tips.map((t) => Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(t['icon'] as IconData, color: colors.accentInfo, size: 14),
                  const SizedBox(width: 6),
                  Expanded(child: Text(t['tip'] as String, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
