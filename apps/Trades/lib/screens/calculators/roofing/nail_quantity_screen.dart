import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Nail Quantity Calculator - Estimate roofing nails needed
class NailQuantityScreen extends ConsumerStatefulWidget {
  const NailQuantityScreen({super.key});
  @override
  ConsumerState<NailQuantityScreen> createState() => _NailQuantityScreenState();
}

class _NailQuantityScreenState extends ConsumerState<NailQuantityScreen> {
  final _squaresController = TextEditingController(text: '24');

  String _shingleType = 'Architectural';
  String _windZone = 'Standard';
  bool _includeAccessories = true;

  int? _fieldNails;
  int? _accessoryNails;
  int? _totalNails;
  int? _poundsNeeded;
  int? _boxesNeeded;

  @override
  void dispose() {
    _squaresController.dispose();
    super.dispose();
  }

  void _calculate() {
    final squares = double.tryParse(_squaresController.text);

    if (squares == null) {
      setState(() {
        _fieldNails = null;
        _accessoryNails = null;
        _totalNails = null;
        _poundsNeeded = null;
        _boxesNeeded = null;
      });
      return;
    }

    // Base nails per square
    int nailsPerSquare;
    switch (_shingleType) {
      case '3-Tab':
        nailsPerSquare = 320; // 4 nails per shingle, 80 shingles/sq
        break;
      case 'Architectural':
        nailsPerSquare = 320;
        break;
      case 'Premium':
        nailsPerSquare = 400; // Extra nailing
        break;
      default:
        nailsPerSquare = 320;
    }

    // Wind zone adjustment
    if (_windZone == 'High Wind') {
      nailsPerSquare = (nailsPerSquare * 1.5).round(); // 6 nails per shingle
    }

    final fieldNails = (squares * nailsPerSquare).round();

    // Accessory nails (starter, ridge, flashing)
    int accessoryNails = 0;
    if (_includeAccessories) {
      // Estimate: 20% additional for accessories
      accessoryNails = (fieldNails * 0.2).round();
    }

    final totalNails = fieldNails + accessoryNails;

    // Convert to pounds (1" roofing nails: ~350 per lb)
    final poundsNeeded = (totalNails / 350).ceil();

    // Boxes (typically 5 lb or 30 lb)
    final boxesNeeded = (poundsNeeded / 30).ceil(); // Using 30 lb boxes

    setState(() {
      _fieldNails = fieldNails;
      _accessoryNails = accessoryNails;
      _totalNails = totalNails;
      _poundsNeeded = poundsNeeded;
      _boxesNeeded = boxesNeeded;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _squaresController.text = '24';
    setState(() {
      _shingleType = 'Architectural';
      _windZone = 'Standard';
      _includeAccessories = true;
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
        title: Text('Nail Quantity', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ROOF SIZE'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Roof Squares',
                unit: 'sq',
                hint: 'Total squares',
                controller: _squaresController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SHINGLE TYPE'),
              const SizedBox(height: 12),
              _buildShingleSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'WIND ZONE'),
              const SizedBox(height: 12),
              _buildWindSelector(colors),
              const SizedBox(height: 12),
              _buildAccessoryToggle(colors),
              const SizedBox(height: 32),
              if (_totalNails != null) ...[
                _buildSectionHeader(colors, 'NAILS NEEDED'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
              ],
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
              Icon(LucideIcons.pin, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Nail Quantity Calculator',
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
            'Estimate roofing nails for shingle installation',
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

  Widget _buildShingleSelector(ZaftoColors colors) {
    final types = ['3-Tab', 'Architectural', 'Premium'];
    return Row(
      children: types.map((type) {
        final isSelected = _shingleType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _shingleType = type);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: type != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                type,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWindSelector(ZaftoColors colors) {
    final zones = ['Standard', 'High Wind'];
    return Row(
      children: zones.map((zone) {
        final isSelected = _windZone == zone;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _windZone = zone);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: zone != zones.last ? 12 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    zone,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    zone == 'Standard' ? '4 nails/shingle' : '6 nails/shingle',
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : colors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAccessoryToggle(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Include Accessories', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
              Text('Starter, ridge cap, flashing', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            ],
          ),
          Switch(
            value: _includeAccessories,
            activeColor: colors.accentPrimary,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _includeAccessories = value);
              _calculate();
            },
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
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          _buildResultRow(colors, 'Field Nails', '${_fieldNails!.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'),
          if (_includeAccessories) ...[
            const SizedBox(height: 8),
            _buildResultRow(colors, 'Accessory Nails', '${_accessoryNails!.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'),
          ],
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'TOTAL NAILS', '${_totalNails!.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}', isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Pounds Needed', '$_poundsNeeded lbs'),
          const SizedBox(height: 8),
          _buildResultRow(colors, '30-lb Boxes', '$_boxesNeeded boxes', isHighlighted: true),
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
                Row(
                  children: [
                    Icon(LucideIcons.info, size: 16, color: colors.accentInfo),
                    const SizedBox(width: 8),
                    Text('Nail Guide', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Use 1-1/4" for new deck, 1-3/4" for re-roof', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('~350 nails per pound for 1" roofing nails', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('High wind: 6 nails per shingle required', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: isHighlighted ? colors.accentPrimary : colors.textPrimary,
            fontSize: isHighlighted ? 18 : 14,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
