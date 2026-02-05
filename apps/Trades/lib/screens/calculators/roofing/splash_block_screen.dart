import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Splash Block Calculator - Calculate splash blocks and downspout extensions
class SplashBlockScreen extends ConsumerStatefulWidget {
  const SplashBlockScreen({super.key});
  @override
  ConsumerState<SplashBlockScreen> createState() => _SplashBlockScreenState();
}

class _SplashBlockScreenState extends ConsumerState<SplashBlockScreen> {
  final _downspoutsController = TextEditingController(text: '4');
  final _extensionLengthController = TextEditingController(text: '4');

  String _extensionType = 'Splash Block';

  int? _splashBlocks;
  double? _flexExtensionFeet;
  int? _rigidExtensions;

  @override
  void dispose() {
    _downspoutsController.dispose();
    _extensionLengthController.dispose();
    super.dispose();
  }

  void _calculate() {
    final downspouts = int.tryParse(_downspoutsController.text);
    final extensionLength = double.tryParse(_extensionLengthController.text);

    if (downspouts == null || extensionLength == null) {
      setState(() {
        _splashBlocks = null;
        _flexExtensionFeet = null;
        _rigidExtensions = null;
      });
      return;
    }

    if (_extensionType == 'Splash Block') {
      // One splash block per downspout
      setState(() {
        _splashBlocks = downspouts;
        _flexExtensionFeet = null;
        _rigidExtensions = null;
      });
    } else if (_extensionType == 'Flexible') {
      // Flexible extensions come in various lengths
      final totalFeet = downspouts * extensionLength;
      setState(() {
        _splashBlocks = null;
        _flexExtensionFeet = totalFeet;
        _rigidExtensions = null;
      });
    } else {
      // Rigid extensions (typically 2-4 ft sections)
      final sectionsPerDownspout = (extensionLength / 3).ceil(); // 3 ft sections typical
      setState(() {
        _splashBlocks = null;
        _flexExtensionFeet = null;
        _rigidExtensions = downspouts * sectionsPerDownspout;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _downspoutsController.text = '4';
    _extensionLengthController.text = '4';
    setState(() => _extensionType = 'Splash Block');
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
        title: Text('Splash Block', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'EXTENSION TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'REQUIREMENTS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Downspouts',
                      unit: 'qty',
                      hint: 'Total count',
                      controller: _downspoutsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Extension',
                      unit: 'ft',
                      hint: 'From foundation',
                      controller: _extensionLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'MATERIALS NEEDED'),
              const SizedBox(height: 12),
              _buildResultsCard(colors),
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
              Icon(LucideIcons.droplets, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Splash Block Calculator',
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
            'Calculate downspout drainage extensions',
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
    final types = ['Splash Block', 'Flexible', 'Rigid'];
    return Row(
      children: types.map((type) {
        final isSelected = _extensionType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _extensionType = type);
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
              child: Column(
                children: [
                  Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    type == 'Splash Block' ? 'Concrete/plastic' : (type == 'Flexible' ? 'Roll-out' : 'PVC/aluminum'),
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
          if (_splashBlocks != null)
            _buildResultRow(colors, 'SPLASH BLOCKS', '$_splashBlocks', isHighlighted: true),
          if (_flexExtensionFeet != null)
            _buildResultRow(colors, 'FLEX EXTENSION', '${_flexExtensionFeet!.toStringAsFixed(0)} ft', isHighlighted: true),
          if (_rigidExtensions != null)
            _buildResultRow(colors, 'RIGID SECTIONS', '$_rigidExtensions', isHighlighted: true),
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
                    Text('Drainage Tips', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Discharge 4-6 ft from foundation', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Slope away at 1" per foot minimum', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Consider underground drain tiles', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
            fontSize: isHighlighted ? 20 : 14,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
