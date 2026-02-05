import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Surge Protector Calculator - Design System v2.6
/// SPD selection and sizing per NEC and UL 1449
class SurgeProtectorScreen extends ConsumerStatefulWidget {
  const SurgeProtectorScreen({super.key});
  @override
  ConsumerState<SurgeProtectorScreen> createState() => _SurgeProtectorScreenState();
}

class _SurgeProtectorScreenState extends ConsumerState<SurgeProtectorScreen> {
  String _locationType = 'service';
  int _voltage = 480;
  String _phase = 'three';
  String _loadType = 'general';
  bool _hasUps = false;

  String? _spdType;
  int? _minKaRating;
  int? _vprRating;
  String? _modesRequired;
  String? _recommendation;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    String spdType;
    int minKa;
    int vpr;
    String modes;

    // SPD Type based on location
    if (_locationType == 'service') {
      spdType = 'Type 1 or Type 2';
      minKa = _loadType == 'critical' ? 200 : 100;
    } else if (_locationType == 'distribution') {
      spdType = 'Type 2';
      minKa = _loadType == 'critical' ? 100 : 50;
    } else {
      spdType = 'Type 3';
      minKa = 10;
    }

    // VPR based on voltage
    if (_voltage == 120) {
      vpr = 700;
    } else if (_voltage == 208 || _voltage == 240) {
      vpr = 1200;
    } else if (_voltage == 480) {
      vpr = 2000;
    } else {
      vpr = 2500;
    }

    // Protection modes
    if (_phase == 'single') {
      modes = 'L-N, L-G, N-G';
    } else {
      modes = 'L-L, L-N, L-G, N-G (all modes)';
    }

    String recommendation;
    if (_locationType == 'service') {
      recommendation = 'Install at main service entrance per NEC 230.67. Use Type 1 if ahead of main OCPD.';
    } else if (_locationType == 'distribution') {
      recommendation = 'Install at subpanel for cascaded protection. Coordinate VPR with service SPD.';
    } else {
      recommendation = 'Point-of-use protection. Supplement panel-level SPD for sensitive equipment.';
    }

    if (_hasUps) {
      recommendation += ' Install SPD upstream of UPS for maximum protection.';
    }

    setState(() {
      _spdType = spdType;
      _minKaRating = minKa;
      _vprRating = vpr;
      _modesRequired = modes;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _locationType = 'service';
      _voltage = 480;
      _phase = 'three';
      _loadType = 'general';
      _hasUps = false;
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
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Surge Protector', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'INSTALLATION LOCATION'),
              const SizedBox(height: 12),
              _buildLocationSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SYSTEM PARAMETERS'),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Voltage', options: const ['120V', '208V', '480V', '600V'], selectedIndex: [120, 208, 480, 600].indexOf(_voltage), onChanged: (i) { setState(() => _voltage = [120, 208, 480, 600][i]); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Phase', options: const ['Single', 'Three'], selectedIndex: _phase == 'single' ? 0 : 1, onChanged: (i) { setState(() => _phase = i == 0 ? 'single' : 'three'); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Load Type', options: const ['General', 'Critical', 'Data Center'], selectedIndex: ['general', 'critical', 'datacenter'].indexOf(_loadType), onChanged: (i) { setState(() => _loadType = ['general', 'critical', 'datacenter'][i]); _calculate(); }),
              const SizedBox(height: 12),
              _buildCheckboxRow(colors, label: 'UPS system present', value: _hasUps, onChanged: (v) { setState(() => _hasUps = v ?? false); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'SPD REQUIREMENTS'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(LucideIcons.shieldCheck, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Select SPD per NEC 285 and UL 1449. Service entrance SPD required per NEC 230.67 (2020+).', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildLocationSelector(ZaftoColors colors) {
    final locations = [
      ('service', 'Service Entrance', LucideIcons.home),
      ('distribution', 'Distribution Panel', LucideIcons.layoutGrid),
      ('pointofuse', 'Point of Use', LucideIcons.plug),
    ];
    return Row(
      children: locations.map((l) {
        final selected = _locationType == l.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _locationType = l.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: l != locations.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Column(children: [
                Icon(l.$3, color: selected ? Colors.white : colors.textSecondary, size: 20),
                const SizedBox(height: 6),
                Text(l.$2, textAlign: TextAlign.center, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSegmentedToggle(ZaftoColors colors, {required String label, required List<String> options, required int selectedIndex, required ValueChanged<int> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: options.asMap().entries.map((e) {
              final selected = e.key == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: selected ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text(e.value, style: TextStyle(color: selected ? Colors.white : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 11))),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxRow(ZaftoColors colors, {required String label, required bool value, required ValueChanged<bool?> onChanged}) {
    return Row(children: [
      Checkbox(value: value, onChanged: onChanged, activeColor: colors.accentPrimary),
      Expanded(child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14))),
    ]);
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_spdType == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text(_spdType!, style: TextStyle(color: colors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700)),
          Text('SPD Classification', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _buildSpecItem(colors, 'Min kA Rating', '${_minKaRating}kA')),
            Container(width: 1, height: 50, color: colors.borderDefault),
            Expanded(child: _buildSpecItem(colors, 'Max VPR', '${_vprRating}V')),
          ]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Protection Modes', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(_modesRequired ?? '', style: TextStyle(color: colors.textPrimary, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.info, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
    ]);
  }
}
