import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Home Run Length Calculator - Wire length estimator
class HomeRunLengthScreen extends ConsumerStatefulWidget {
  const HomeRunLengthScreen({super.key});
  @override
  ConsumerState<HomeRunLengthScreen> createState() => _HomeRunLengthScreenState();
}

class _HomeRunLengthScreenState extends ConsumerState<HomeRunLengthScreen> {
  final _horizontalController = TextEditingController(text: '40');
  final _verticalController = TextEditingController(text: '20');
  final _roofRunController = TextEditingController(text: '30');
  final _slackController = TextEditingController(text: '10');
  final _stringsController = TextEditingController(text: '2');

  double? _totalLength;
  double? _perString;
  double? _withSlack;
  String? _recommendation;

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    _roofRunController.dispose();
    _slackController.dispose();
    _stringsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final horizontal = double.tryParse(_horizontalController.text);
    final vertical = double.tryParse(_verticalController.text);
    final roofRun = double.tryParse(_roofRunController.text);
    final slackPercent = double.tryParse(_slackController.text);
    final strings = int.tryParse(_stringsController.text);

    if (horizontal == null || vertical == null || roofRun == null ||
        slackPercent == null || strings == null || strings == 0) {
      setState(() {
        _totalLength = null;
        _perString = null;
        _withSlack = null;
        _recommendation = null;
      });
      return;
    }

    // Basic home run = horizontal + vertical + roof run
    // × 2 for positive and negative conductors
    final perString = (horizontal + vertical + roofRun) * 2;
    final totalBase = perString * strings;
    final withSlack = totalBase * (1 + slackPercent / 100);

    String recommendation;
    if (perString < 50) {
      recommendation = 'Short run - #10 AWG typically sufficient.';
    } else if (perString < 100) {
      recommendation = 'Medium run - check voltage drop with #10 or #8.';
    } else if (perString < 150) {
      recommendation = 'Long run - consider #8 or #6 AWG.';
    } else {
      recommendation = 'Very long run - size wire carefully for voltage drop.';
    }

    setState(() {
      _totalLength = totalBase;
      _perString = perString;
      _withSlack = withSlack;
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
    _horizontalController.text = '40';
    _verticalController.text = '20';
    _roofRunController.text = '30';
    _slackController.text = '10';
    _stringsController.text = '2';
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
        title: Text('Home Run Length', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ROUTE SEGMENTS'),
              const SizedBox(height: 12),
              _buildSegmentInputs(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ARRAY'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Strings',
                      unit: '#',
                      hint: 'Number of strings',
                      controller: _stringsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Slack/Waste',
                      unit: '%',
                      hint: 'Extra for loops',
                      controller: _slackController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_totalLength != null) ...[
                _buildSectionHeader(colors, 'WIRE NEEDED'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildMaterialList(colors),
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
              Icon(LucideIcons.ruler, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Wire Length Estimator',
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
            'Estimate total PV wire needed for home run from array to inverter',
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

  Widget _buildSegmentInputs(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          _buildSegmentRow(colors, LucideIcons.moveHorizontal, 'Horizontal', 'Ground run', _horizontalController),
          const SizedBox(height: 12),
          _buildSegmentRow(colors, LucideIcons.moveVertical, 'Vertical', 'Wall/mast', _verticalController),
          const SizedBox(height: 12),
          _buildSegmentRow(colors, LucideIcons.home, 'Roof Run', 'On roof', _roofRunController),
        ],
      ),
    );
  }

  Widget _buildSegmentRow(ZaftoColors colors, IconData icon, String label, String hint, TextEditingController controller) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.accentPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: colors.accentPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              Text(hint, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
            ],
          ),
        ),
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: '0',
              hintStyle: TextStyle(color: colors.textTertiary),
              suffixText: ' ft',
              suffixStyle: TextStyle(color: colors.textTertiary, fontSize: 12),
            ),
            onChanged: (_) => _calculate(),
          ),
        ),
      ],
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
          Text('Total Wire Length (with slack)', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '${_withSlack!.toStringAsFixed(0)} ft',
            style: TextStyle(color: colors.accentSuccess, fontSize: 44, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Per String', '${_perString!.toStringAsFixed(0)} ft', colors.accentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Base Total', '${_totalLength!.toStringAsFixed(0)} ft', colors.accentInfo),
              ),
            ],
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
                Icon(LucideIcons.lightbulb, size: 16, color: colors.accentInfo),
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
          Text(value, style: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildMaterialList(ZaftoColors colors) {
    final spools = (_withSlack! / 500).ceil();
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
          Text('ORDERING GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildMaterialRow(colors, '500ft spools', '$spools needed'),
          _buildMaterialRow(colors, 'Or 1000ft spool', '${(_withSlack! / 1000).ceil()} needed'),
          const SizedBox(height: 12),
          Text(
            'Note: Includes both positive and negative conductors. Order same amount of each color (red/black or marked).',
            style: TextStyle(color: colors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialRow(ZaftoColors colors, String item, String qty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(item, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          Text(qty, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
