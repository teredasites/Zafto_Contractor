import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Weld Symbol Decoder - AWS weld symbol reference
class WeldSymbolDecoderScreen extends ConsumerStatefulWidget {
  const WeldSymbolDecoderScreen({super.key});
  @override
  ConsumerState<WeldSymbolDecoderScreen> createState() => _WeldSymbolDecoderScreenState();
}

class _WeldSymbolDecoderScreenState extends ConsumerState<WeldSymbolDecoderScreen> {
  String _selectedSymbol = 'Fillet';
  String _selectedSupplement = 'None';

  String? _symbolDescription;
  String? _arrowSide;
  String? _otherSide;
  String? _supplementInfo;

  // Weld symbol descriptions
  static const Map<String, Map<String, String>> _symbolInfo = {
    'Fillet': {
      'description': 'Triangular cross-section weld joining two surfaces at right angles',
      'arrow': 'Weld on arrow side - triangle pointing down',
      'other': 'Weld on other side - triangle pointing up (above line)',
      'both': 'Weld both sides - triangles on both sides of line',
    },
    'Square Groove': {
      'description': 'Square edge preparation with no bevel',
      'arrow': 'Two parallel vertical lines - on arrow side',
      'other': 'Two parallel vertical lines - above reference line',
      'both': 'Typically welded from one side only',
    },
    'V-Groove': {
      'description': 'V-shaped groove preparation',
      'arrow': 'V shape pointing down below reference line',
      'other': 'V shape pointing up above reference line',
      'both': 'Double V - Vs on both sides',
    },
    'Bevel': {
      'description': 'Single bevel on one member only',
      'arrow': 'Half V below line - bevel on arrow side member',
      'other': 'Half V above line - bevel on other side member',
      'both': 'Double bevel - bevels on both sides',
    },
    'U-Groove': {
      'description': 'U-shaped groove preparation',
      'arrow': 'U shape below reference line',
      'other': 'U shape above reference line',
      'both': 'Double U - U shapes on both sides',
    },
    'J-Groove': {
      'description': 'J-shaped groove on one member',
      'arrow': 'J shape below line',
      'other': 'J shape above line',
      'both': 'Double J - J shapes on both sides',
    },
    'Plug/Slot': {
      'description': 'Weld through hole in one member',
      'arrow': 'Rectangle below line - hole in arrow side member',
      'other': 'Rectangle above line - hole in other side member',
      'both': 'N/A - typically one side only',
    },
    'Spot': {
      'description': 'Circular weld, resistance or arc spot',
      'arrow': 'Circle below reference line',
      'other': 'Circle above reference line',
      'both': 'Circle centered on line',
    },
    'Seam': {
      'description': 'Continuous weld along a seam',
      'arrow': 'Circle with horizontal lines through it',
      'other': 'Same symbol above line',
      'both': 'Same symbol centered on line',
    },
    'Surfacing': {
      'description': 'Built-up surface (overlay, hardfacing)',
      'arrow': 'Semicircle below reference line',
      'other': 'N/A - applied to surface',
      'both': 'N/A',
    },
  };

  // Supplementary symbols
  static const Map<String, String> _supplementInfoMap = {
    'None': 'No supplementary symbol',
    'Field Weld': 'Flag symbol - weld to be made in field, not shop',
    'Weld All Around': 'Circle at junction - weld entire perimeter',
    'Flush': 'Straight line over weld - finish flush with surface',
    'Convex': 'Arc over weld - finish with convex contour',
    'Concave': 'Arc under weld - finish with concave contour',
    'Melt-Through': 'Filled black semicircle - complete penetration visible from back',
    'Backing': 'Open semicircle - backing strip or ring used',
    'Spacer': 'Rectangle - spacer between members',
  };

  void _calculate() {
    final info = _symbolInfo[_selectedSymbol] ?? {};

    setState(() {
      _symbolDescription = info['description'];
      _arrowSide = info['arrow'];
      _otherSide = info['other'];
      _supplementInfo = _supplementInfoMap[_selectedSupplement];
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Weld Symbols', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Weld Type', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildSymbolSelector(colors),
            const SizedBox(height: 16),
            Text('Supplementary Symbol', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildSupplementSelector(colors),
            const SizedBox(height: 32),
            _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSymbolSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _symbolInfo.keys.map((s) => ChoiceChip(
        label: Text(s, style: const TextStyle(fontSize: 11)),
        selected: _selectedSymbol == s,
        onSelected: (_) => setState(() { _selectedSymbol = s; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildSupplementSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _supplementInfoMap.keys.map((s) => ChoiceChip(
        label: Text(s, style: const TextStyle(fontSize: 10)),
        selected: _selectedSupplement == s,
        onSelected: (_) => setState(() { _selectedSupplement = s; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('AWS A2.4 Weld Symbol Reference', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Decode welding symbols from drawings', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_selectedSymbol, style: TextStyle(color: colors.accentPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Text(_symbolDescription ?? '', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
        const SizedBox(height: 16),
        _buildInfoRow(colors, 'Arrow Side:', _arrowSide ?? ''),
        const SizedBox(height: 8),
        _buildInfoRow(colors, 'Other Side:', _otherSide ?? ''),
        if (_selectedSupplement != 'None') ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(LucideIcons.info, size: 16, color: colors.textTertiary),
              const SizedBox(width: 8),
              Expanded(child: Text(_supplementInfo ?? '', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildInfoRow(ZaftoColors colors, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
      ],
    );
  }
}
