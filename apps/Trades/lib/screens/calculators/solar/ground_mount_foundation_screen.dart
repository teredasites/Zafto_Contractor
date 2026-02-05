import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Ground Mount Foundation Calculator - Foundation sizing
class GroundMountFoundationScreen extends ConsumerStatefulWidget {
  const GroundMountFoundationScreen({super.key});
  @override
  ConsumerState<GroundMountFoundationScreen> createState() => _GroundMountFoundationScreenState();
}

class _GroundMountFoundationScreenState extends ConsumerState<GroundMountFoundationScreen> {
  final _windSpeedController = TextEditingController(text: '115');
  final _arrayHeightController = TextEditingController(text: '8');
  final _arrayWidthController = TextEditingController(text: '20');
  final _tiltAngleController = TextEditingController(text: '30');
  final _postSpacingController = TextEditingController(text: '10');

  String _foundationType = 'Ground Screw';
  String _soilType = 'Medium Clay';

  double? _totalUplift;
  double? _totalLateral;
  double? _foundationDepth;
  double? _foundationSize;
  String? _recommendation;

  // Soil bearing capacities (psf)
  final Map<String, double> _soilCapacities = {
    'Soft Clay': 1000,
    'Medium Clay': 2000,
    'Stiff Clay': 4000,
    'Loose Sand': 1500,
    'Medium Sand': 3000,
    'Dense Sand': 4000,
    'Gravel': 5000,
  };

  List<String> get _soilTypes => _soilCapacities.keys.toList();
  List<String> get _foundationTypes => ['Ground Screw', 'Concrete Pier', 'Driven Post', 'Ballast Block'];

  @override
  void dispose() {
    _windSpeedController.dispose();
    _arrayHeightController.dispose();
    _arrayWidthController.dispose();
    _tiltAngleController.dispose();
    _postSpacingController.dispose();
    super.dispose();
  }

  void _calculate() {
    final windSpeed = double.tryParse(_windSpeedController.text);
    final arrayHeight = double.tryParse(_arrayHeightController.text);
    final arrayWidth = double.tryParse(_arrayWidthController.text);
    final tiltAngle = double.tryParse(_tiltAngleController.text);
    final postSpacing = double.tryParse(_postSpacingController.text);

    if (windSpeed == null || arrayHeight == null || arrayWidth == null ||
        tiltAngle == null || postSpacing == null) {
      setState(() {
        _totalUplift = null;
        _totalLateral = null;
        _foundationDepth = null;
        _foundationSize = null;
        _recommendation = null;
      });
      return;
    }

    final soilCapacity = _soilCapacities[_soilType]!;

    // Wind pressure (simplified ASCE 7)
    final windPressure = 0.00256 * 1.0 * 0.85 * math.pow(windSpeed, 2);

    // Array area tributary to each post
    final tributaryArea = postSpacing * arrayWidth;

    // Force coefficients based on tilt
    final tiltRad = tiltAngle * math.pi / 180;
    final dragCoef = 1.3 + (0.01 * tiltAngle);
    final liftCoef = 0.8 * math.sin(2 * tiltRad);

    // Forces per post
    final lateralForce = windPressure * tributaryArea * dragCoef;
    final upliftForce = windPressure * tributaryArea * liftCoef;

    // Dead load (system weight counteracts uplift)
    final deadLoad = tributaryArea * 3.5; // ~3.5 psf for typical ground mount
    final netUplift = math.max(0, upliftForce - deadLoad);

    // Foundation sizing based on type
    double foundationDepth;
    double foundationSize;

    switch (_foundationType) {
      case 'Ground Screw':
        // Depth based on pullout resistance
        foundationDepth = math.max(4, netUplift / (soilCapacity * 0.15));
        foundationSize = 3; // Typical helix diameter
        break;
      case 'Concrete Pier':
        // Minimum 3' depth, more for uplift
        foundationDepth = math.max(3, 3 + netUplift / 2000);
        foundationSize = math.max(10, math.sqrt(lateralForce / (soilCapacity * 0.3)));
        break;
      case 'Driven Post':
        // Depth for lateral and pullout
        foundationDepth = math.max(4, math.max(lateralForce, netUplift) / (soilCapacity * 0.1));
        foundationSize = 4; // Typical W-beam width
        break;
      case 'Ballast Block':
        // Weight to counteract uplift with 1.5 safety factor
        foundationDepth = 0;
        foundationSize = (netUplift * 1.5) / 150; // Concrete ~150 pcf
        break;
      default:
        foundationDepth = 4;
        foundationSize = 12;
    }

    String recommendation;
    if (_foundationType == 'Ballast Block') {
      recommendation = 'Each block needs ${foundationSize.toStringAsFixed(0)} cu ft (~${(foundationSize * 150).toStringAsFixed(0)} lbs).';
    } else if (foundationDepth > 6) {
      recommendation = 'Deep foundation required. Consider soil testing for accurate capacity.';
    } else if (foundationDepth > 4) {
      recommendation = 'Standard depth. Verify soil conditions match assumptions.';
    } else {
      recommendation = 'Shallow foundation adequate. Good soil bearing capacity.';
    }

    setState(() {
      _totalUplift = netUplift.toDouble();
      _totalLateral = lateralForce;
      _foundationDepth = foundationDepth;
      _foundationSize = foundationSize;
      _recommendation = recommendation;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _windSpeedController.text = '115';
    _arrayHeightController.text = '8';
    _arrayWidthController.text = '20';
    _tiltAngleController.text = '30';
    _postSpacingController.text = '10';
    setState(() {
      _foundationType = 'Ground Screw';
      _soilType = 'Medium Clay';
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
        title: Text('Ground Mount Foundation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'FOUNDATION TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 12),
              _buildSoilSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ARRAY PARAMETERS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Wind Speed',
                      unit: 'mph',
                      hint: 'ASCE 7',
                      controller: _windSpeedController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Tilt Angle',
                      unit: 'deg',
                      hint: 'Panel tilt',
                      controller: _tiltAngleController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Array Height',
                      unit: 'ft',
                      hint: 'Table height',
                      controller: _arrayHeightController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Array Width',
                      unit: 'ft',
                      hint: 'Panel rows',
                      controller: _arrayWidthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Post Spacing',
                unit: 'ft',
                hint: 'Between posts',
                controller: _postSpacingController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_foundationDepth != null) ...[
                _buildSectionHeader(colors, 'FOUNDATION REQUIREMENTS'),
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
              Icon(LucideIcons.anchor, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Ground Mount Foundation',
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
            'Size foundations for ground-mounted solar arrays',
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

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _foundationType,
          isExpanded: true,
          dropdownColor: colors.bgElevated,
          style: TextStyle(color: colors.textPrimary, fontSize: 16),
          icon: Icon(LucideIcons.chevronDown, color: colors.textSecondary),
          items: _foundationTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              HapticFeedback.selectionClick();
              setState(() => _foundationType = value);
              _calculate();
            }
          },
        ),
      ),
    );
  }

  Widget _buildSoilSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _soilType,
          isExpanded: true,
          dropdownColor: colors.bgElevated,
          style: TextStyle(color: colors.textPrimary, fontSize: 16),
          icon: Icon(LucideIcons.chevronDown, color: colors.textSecondary),
          items: _soilTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              HapticFeedback.selectionClick();
              setState(() => _soilType = value);
              _calculate();
            }
          },
        ),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isBallast = _foundationType == 'Ballast Block';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  colors,
                  isBallast ? 'Block Size' : 'Depth',
                  isBallast ? '${_foundationSize!.toStringAsFixed(1)} cu ft' : '${_foundationDepth!.toStringAsFixed(1)} ft',
                  colors.accentPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(
                  colors,
                  isBallast ? 'Weight' : 'Diameter',
                  isBallast ? '${(_foundationSize! * 150).toStringAsFixed(0)} lbs' : '${_foundationSize!.toStringAsFixed(0)} in',
                  colors.accentSuccess,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Net Uplift/Post', '${_totalUplift!.toStringAsFixed(0)} lbs'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Lateral Force/Post', '${_totalLateral!.toStringAsFixed(0)} lbs'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Soil Capacity', '${_soilCapacities[_soilType]!.toStringAsFixed(0)} psf'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, size: 16, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _recommendation!,
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

  Widget _buildStatTile(ZaftoColors colors, String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
