import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Sound Attenuation Calculator - Design System v2.6
/// HVAC noise control and silencer sizing
class SoundAttenuationScreen extends ConsumerStatefulWidget {
  const SoundAttenuationScreen({super.key});
  @override
  ConsumerState<SoundAttenuationScreen> createState() => _SoundAttenuationScreenState();
}

class _SoundAttenuationScreenState extends ConsumerState<SoundAttenuationScreen> {
  double _sourceLevel = 75; // dB
  double _targetLevel = 45; // dB (NC rating)
  double _ductSize = 18; // inches
  double _ductLength = 20; // feet
  String _silencerType = 'rectangular';
  String _spaceType = 'office';

  double? _requiredAttenuation;
  double? _naturalAttenuation;
  double? _silencerLength;
  String? _recommendation;

  // NC ratings by space type
  final Map<String, int> _ncRatings = {
    'office': 40,
    'conference': 30,
    'hospital': 35,
    'classroom': 35,
    'restaurant': 45,
    'retail': 50,
  };

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Required attenuation
    final requiredAttenuation = _sourceLevel - _targetLevel;

    // Natural attenuation from duct (approximately 0.1 dB/ft for unlined, 0.5-1.0 for lined)
    final naturalAttenuation = _ductLength * 0.3; // Assuming lined duct

    // Additional attenuation needed
    final additionalNeeded = requiredAttenuation - naturalAttenuation;

    // Silencer length (rule of thumb: 3-5 dB per foot for standard silencer)
    double silencerLength = 0;
    double attenuationPerFoot;
    switch (_silencerType) {
      case 'rectangular':
        attenuationPerFoot = 4.0;
        break;
      case 'round':
        attenuationPerFoot = 3.5;
        break;
      case 'elbow':
        attenuationPerFoot = 5.0;
        break;
      case 'plenum':
        attenuationPerFoot = 6.0;
        break;
      default:
        attenuationPerFoot = 4.0;
    }

    if (additionalNeeded > 0) {
      silencerLength = additionalNeeded / attenuationPerFoot;
    }

    String recommendation;
    recommendation = 'Source: ${_sourceLevel.toStringAsFixed(0)} dB. Target NC: ${_targetLevel.toStringAsFixed(0)}. Required reduction: ${requiredAttenuation.toStringAsFixed(0)} dB. ';

    if (additionalNeeded <= 0) {
      recommendation += 'Natural duct attenuation (${naturalAttenuation.toStringAsFixed(0)} dB) is sufficient.';
    } else {
      recommendation += 'Need ${additionalNeeded.toStringAsFixed(0)} dB additional attenuation. ';
      recommendation += 'Silencer: ${silencerLength.toStringAsFixed(1)} ft minimum length.';
    }

    switch (_silencerType) {
      case 'rectangular':
        recommendation += ' Rectangular silencer: Standard choice. 3-5 dB/ft. Low to moderate pressure drop.';
        break;
      case 'round':
        recommendation += ' Round silencer: For round duct. Slightly less attenuation than rectangular.';
        break;
      case 'elbow':
        recommendation += ' Elbow silencer: Combines direction change with attenuation. Space-efficient.';
        break;
      case 'plenum':
        recommendation += ' Lined plenum: High attenuation. Also provides flow conditioning.';
        break;
    }

    final ncTarget = _ncRatings[_spaceType] ?? 40;
    if (_targetLevel > ncTarget) {
      recommendation += ' Note: Target exceeds typical NC-${ncTarget} for ${_spaceType.replaceAll('_', ' ')}.';
    }

    // Velocity considerations
    final ductArea = math.pi * math.pow(_ductSize / 24, 2); // sq ft
    recommendation += ' Limit silencer face velocity to 1500-2000 fpm to avoid regenerated noise.';

    if (_ductSize < 12) {
      recommendation += ' Small duct: Consider inline silencer or duct lining.';
    }

    setState(() {
      _requiredAttenuation = requiredAttenuation;
      _naturalAttenuation = naturalAttenuation;
      _silencerLength = silencerLength;
      _recommendation = recommendation;
    });
  }

  void _reset() {
    setState(() {
      _sourceLevel = 75;
      _targetLevel = 45;
      _ductSize = 18;
      _ductLength = 20;
      _silencerType = 'rectangular';
      _spaceType = 'office';
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
        title: Text('Sound Attenuation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SILENCER TYPE'),
              const SizedBox(height: 12),
              _buildSilencerTypeSelector(colors),
              const SizedBox(height: 12),
              _buildSpaceTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SOUND LEVELS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Source', _sourceLevel, 50, 100, ' dB', (v) { setState(() => _sourceLevel = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Target NC', _targetLevel, 25, 55, '', (v) { setState(() => _targetLevel = v); _calculate(); })),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DUCT PARAMETERS'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildCompactSlider(colors, 'Duct Size', _ductSize, 8, 48, '"', (v) { setState(() => _ductSize = v); _calculate(); })),
                const SizedBox(width: 12),
                Expanded(child: _buildCompactSlider(colors, 'Length', _ductLength, 5, 100, ' ft', (v) { setState(() => _ductLength = v); _calculate(); })),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'ATTENUATION ANALYSIS'),
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
        Icon(LucideIcons.volume2, color: colors.accentPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('NC (Noise Criteria) rating for HVAC noise. Offices NC-40, conference rooms NC-30. Silencers provide 3-6 dB/ft attenuation.', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildSilencerTypeSelector(ZaftoColors colors) {
    final types = [('rectangular', 'Rectangular'), ('round', 'Round'), ('elbow', 'Elbow'), ('plenum', 'Plenum')];
    return Row(
      children: types.map((t) {
        final selected = _silencerType == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _silencerType = t.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: t != types.last ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSpaceTypeSelector(ZaftoColors colors) {
    final spaces = [('office', 'Office'), ('conference', 'Conf'), ('hospital', 'Hospital'), ('classroom', 'School')];
    return Row(
      children: spaces.map((s) {
        final selected = _spaceType == s.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _spaceType = s.$1); _calculate(); },
            child: Container(
              margin: EdgeInsets.only(right: s != spaces.last ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.accentPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? colors.accentPrimary : colors.borderDefault),
              ),
              child: Center(child: Text(s.$2, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactSlider(ZaftoColors colors, String label, double value, double min, double max, String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(6)),
          child: Text('${value.toStringAsFixed(0)}$unit', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: colors.accentPrimary, inactiveTrackColor: colors.bgCard, thumbColor: colors.accentPrimary, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    if (_requiredAttenuation == null) return const SizedBox.shrink();

    final needsSilencer = (_silencerLength ?? 0) > 0;
    final statusColor = needsSilencer ? Colors.orange : Colors.green;
    final status = needsSilencer ? 'SILENCER REQUIRED' : 'DUCT SUFFICIENT';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderDefault)),
      child: Column(
        children: [
          Text('${_requiredAttenuation?.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 56, fontWeight: FontWeight.w700)),
          Text('dB Required Attenuation', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
          const SizedBox(height: 16),
          if (needsSilencer)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Column(children: [
                Text('${_silencerLength?.toStringAsFixed(1)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w600)),
                Text('Minimum Silencer Length', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ]),
            ),
          Row(children: [
            Expanded(child: _buildResultItem(colors, 'Source', '${_sourceLevel.toStringAsFixed(0)} dB')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Duct Atten', '${_naturalAttenuation?.toStringAsFixed(0)} dB')),
            Container(width: 1, height: 40, color: colors.borderDefault),
            Expanded(child: _buildResultItem(colors, 'Target', 'NC-${_targetLevel.toStringAsFixed(0)}')),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(LucideIcons.info, color: colors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_recommendation ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(ZaftoColors colors, String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
    ]);
  }
}
