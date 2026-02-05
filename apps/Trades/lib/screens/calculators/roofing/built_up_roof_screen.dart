import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Built-Up Roof Calculator - Calculate BUR materials
class BuiltUpRoofScreen extends ConsumerStatefulWidget {
  const BuiltUpRoofScreen({super.key});
  @override
  ConsumerState<BuiltUpRoofScreen> createState() => _BuiltUpRoofScreenState();
}

class _BuiltUpRoofScreenState extends ConsumerState<BuiltUpRoofScreen> {
  final _roofAreaController = TextEditingController(text: '5000');

  String _plyCount = '3-Ply';
  String _surfacing = 'Gravel';

  double? _squares;
  int? _feltRolls;
  double? _asphaltGallons;
  double? _gravelTons;
  int? _insulationBoards;

  @override
  void dispose() {
    _roofAreaController.dispose();
    super.dispose();
  }

  void _calculate() {
    final roofArea = double.tryParse(_roofAreaController.text);

    if (roofArea == null) {
      setState(() {
        _squares = null;
        _feltRolls = null;
        _asphaltGallons = null;
        _gravelTons = null;
        _insulationBoards = null;
      });
      return;
    }

    final squares = roofArea / 100;

    // Number of plies
    int plies;
    switch (_plyCount) {
      case '2-Ply':
        plies = 2;
        break;
      case '3-Ply':
        plies = 3;
        break;
      case '4-Ply':
        plies = 4;
        break;
      default:
        plies = 3;
    }

    // Felt rolls: 4 squares per roll, multiply by plies
    // Plus base sheet (1 ply)
    final feltRolls = ((roofArea / 400) * (plies + 1) * 1.1).ceil();

    // Hot asphalt: ~25 lbs/100 sq ft per ply interply
    // Plus flood coat if gravel surfaced (~60 lbs/100 sq ft)
    double asphaltLbs = (roofArea / 100) * 25 * plies;
    if (_surfacing == 'Gravel') {
      asphaltLbs += (roofArea / 100) * 60;
    }
    // Convert to gallons (~8.5 lbs/gal for roofing asphalt)
    final asphaltGallons = asphaltLbs / 8.5;

    // Gravel: 400 lbs/100 sq ft
    double gravelTons = 0;
    if (_surfacing == 'Gravel') {
      gravelTons = (roofArea / 100) * 400 / 2000;
    }

    // Insulation boards: 4' × 8' = 32 sq ft per board
    final insulationBoards = (roofArea / 32 * 1.05).ceil();

    setState(() {
      _squares = squares;
      _feltRolls = feltRolls;
      _asphaltGallons = asphaltGallons;
      _gravelTons = gravelTons;
      _insulationBoards = insulationBoards;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _roofAreaController.text = '5000';
    setState(() {
      _plyCount = '3-Ply';
      _surfacing = 'Gravel';
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
        title: Text('Built-Up Roof', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SYSTEM SPECS'),
              const SizedBox(height: 12),
              _buildPlySelector(colors),
              const SizedBox(height: 12),
              _buildSurfacingSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOF AREA'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Roof Area',
                unit: 'sq ft',
                hint: 'Total field area',
                controller: _roofAreaController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_feltRolls != null) ...[
                _buildSectionHeader(colors, 'MATERIALS NEEDED'),
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
              Icon(LucideIcons.layers, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Built-Up Roof Calculator',
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
            'Calculate BUR (tar and gravel) materials',
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

  Widget _buildPlySelector(ZaftoColors colors) {
    final plies = ['2-Ply', '3-Ply', '4-Ply'];
    return Row(
      children: plies.map((ply) {
        final isSelected = _plyCount == ply;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _plyCount = ply);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: ply != plies.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                ply,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSurfacingSelector(ZaftoColors colors) {
    final surfaces = ['Gravel', 'Mineral Cap', 'Smooth'];
    return Row(
      children: surfaces.map((surface) {
        final isSelected = _surfacing == surface;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _surfacing = surface);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: surface != surfaces.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                surface,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
          _buildResultRow(colors, 'Roof Squares', _squares!.toStringAsFixed(1)),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'FELT ROLLS', '$_feltRolls', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Hot Asphalt', '${_asphaltGallons!.toStringAsFixed(0)} gal'),
          if (_gravelTons! > 0) ...[
            const SizedBox(height: 8),
            _buildResultRow(colors, 'Gravel', '${_gravelTons!.toStringAsFixed(1)} tons'),
          ],
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Insulation Boards', '$_insulationBoards'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, size: 16, color: colors.accentWarning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hot asphalt requires kettle. Temp: 375-450°F. Fire watch required.',
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
