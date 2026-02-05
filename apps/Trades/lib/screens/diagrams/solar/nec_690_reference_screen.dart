import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class Nec690ReferenceScreen extends ConsumerWidget {
  const Nec690ReferenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'NEC Article 690 Reference',
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
            _buildPartI(colors),
            const SizedBox(height: 24),
            _buildPartII(colors),
            const SizedBox(height: 24),
            _buildPartIII(colors),
            const SizedBox(height: 24),
            _buildPartIV(colors),
            const SizedBox(height: 24),
            _buildPartV(colors),
            const SizedBox(height: 24),
            _buildPartVI(colors),
            const SizedBox(height: 24),
            _buildKeyFormulas(colors),
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
              Icon(LucideIcons.bookOpen, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'NEC Article 690 Overview',
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
            'Article 690 covers the installation of solar photovoltaic (PV) systems including circuits, equipment, and associated wiring. It works in conjunction with other NEC articles.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Article 690 Parts:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildPartOverview(colors, 'I', 'General'),
                _buildPartOverview(colors, 'II', 'Circuit Requirements'),
                _buildPartOverview(colors, 'III', 'Disconnecting Means'),
                _buildPartOverview(colors, 'IV', 'Wiring Methods'),
                _buildPartOverview(colors, 'V', 'Grounding & Bonding'),
                _buildPartOverview(colors, 'VI', 'Marking'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartOverview(ZaftoColors colors, String part, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colors.accentPrimary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(part, style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPartI(ZaftoColors colors) {
    return _buildPartSection(colors, 'I', 'General', [
      {'code': '690.1', 'title': 'Scope', 'desc': 'Covers PV systems that produce power from sunlight'},
      {'code': '690.2', 'title': 'Definitions', 'desc': 'Key terms: PV system, array, string, MLPE, etc.'},
      {'code': '690.4', 'title': 'Installation', 'desc': 'General installation requirements and wiring methods'},
      {'code': '690.6', 'title': 'Listing Req.', 'desc': 'PV modules, inverters must be listed for application'},
    ]);
  }

  Widget _buildPartII(ZaftoColors colors) {
    return _buildPartSection(colors, 'II', 'Circuit Requirements', [
      {'code': '690.7', 'title': 'Max Voltage', 'desc': 'Calculate Voc with temp correction. 600V residential max (some AHJs allow 1000V)'},
      {'code': '690.8', 'title': 'Circuit Sizing', 'desc': 'Conductors sized for 125% of Isc (continuous load)'},
      {'code': '690.9', 'title': 'OCPD', 'desc': 'Overcurrent protection sizing and placement requirements'},
      {'code': '690.11', 'title': 'Arc-Fault', 'desc': 'DC arc-fault protection required for systems on buildings'},
      {'code': '690.12', 'title': 'Rapid Shutdown', 'desc': 'RSD required for rooftop systems. ≤30V outside, ≤80V inside array'},
    ]);
  }

  Widget _buildPartIII(ZaftoColors colors) {
    return _buildPartSection(colors, 'III', 'Disconnecting Means', [
      {'code': '690.13', 'title': 'PV Disconnect', 'desc': 'Required disconnect for all conductors. Lockable open.'},
      {'code': '690.15', 'title': 'DC Disconnects', 'desc': 'Disconnects for equipment (inverter, charge controller)'},
    ]);
  }

  Widget _buildPartIV(ZaftoColors colors) {
    return _buildPartSection(colors, 'IV', 'Wiring Methods', [
      {'code': '690.31', 'title': 'Methods', 'desc': 'Permitted wiring methods and cable types (USE-2, PV Wire)'},
      {'code': '690.31(B)', 'title': 'Single Conductor', 'desc': 'PV source circuits may use single conductor cable'},
      {'code': '690.31(G)', 'title': 'DC Circuits', 'desc': 'DC circuits in buildings must be in metallic raceway or MC cable'},
    ]);
  }

  Widget _buildPartV(ZaftoColors colors) {
    return _buildPartSection(colors, 'V', 'Grounding & Bonding', [
      {'code': '690.41', 'title': 'System Ground', 'desc': 'Grounded systems need GFDI. Ungrounded need GFP.'},
      {'code': '690.43', 'title': 'EGC', 'desc': 'Equipment grounding conductor required for exposed metal'},
      {'code': '690.45', 'title': 'Size', 'desc': 'EGC sized per 250.122 based on OCPD rating'},
      {'code': '690.47', 'title': 'GEC', 'desc': 'Grounding electrode system connection requirements'},
    ]);
  }

  Widget _buildPartVI(ZaftoColors colors) {
    return _buildPartSection(colors, 'VI', 'Marking', [
      {'code': '690.53', 'title': 'DC Marking', 'desc': 'DC PV power source must be marked with operating current/voltage'},
      {'code': '690.54', 'title': 'Interaction', 'desc': 'Interactive system point of connection marking'},
      {'code': '690.56', 'title': 'RSD Label', 'desc': 'Rapid shutdown type and location labels required'},
    ]);
  }

  Widget _buildPartSection(ZaftoColors colors, String part, String title, List<Map<String, String>> codes) {
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.accentPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Part $part', style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...codes.map((c) => _buildCodeItem(colors, c['code']!, c['title']!, c['desc']!)),
        ],
      ),
    );
  }

  Widget _buildCodeItem(ZaftoColors colors, String code, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: colors.accentError.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(code, style: TextStyle(color: colors.accentError, fontWeight: FontWeight.bold, fontSize: 10)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyFormulas(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.calculator, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Key NEC 690 Formulas',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '''
MAXIMUM SYSTEM VOLTAGE (690.7)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Vmax = Voc × # panels in series × Temp Factor

Temp Correction Factors (Table 690.7(A)):
  -40°C = 1.25
  -30°C = 1.21
  -20°C = 1.17
  -10°C = 1.14
    0°C = 1.10

Example: 10 panels × 45V Voc × 1.14 = 513V


CONDUCTOR SIZING (690.8)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Min Ampacity = Isc × 1.25 (continuous)

For conductor selection:
Ampacity ≥ Isc × 1.25 × 1.25 = Isc × 1.56


FUSE SIZING (690.9)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Min Fuse = Isc × 1.56
Max Fuse = Module Iocpd (from spec sheet)


120% RULE (690.64(B))
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Main + PV Breaker ≤ Busbar Rating × 1.2

Example: 200A panel with 200A main
  Max PV breaker = (200 × 1.2) - 200 = 40A

Alternative: Supply-side connection
  (Tap before main breaker, requires own OCPD)''',
              style: TextStyle(
                color: colors.accentWarning,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, color: colors.accentInfo, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Always verify with current NEC edition adopted by your AHJ. Local amendments may apply.',
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
}
