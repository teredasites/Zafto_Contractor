import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// DC Disconnect Sizing Calculator - NEC 690 requirements
class DcDisconnectSizingScreen extends ConsumerStatefulWidget {
  const DcDisconnectSizingScreen({super.key});
  @override
  ConsumerState<DcDisconnectSizingScreen> createState() => _DcDisconnectSizingScreenState();
}

class _DcDisconnectSizingScreenState extends ConsumerState<DcDisconnectSizingScreen> {
  final _vocController = TextEditingController(text: '500');
  final _iscController = TextEditingController(text: '10.8');
  final _stringsController = TextEditingController(text: '2');
  final _tempCorrectionController = TextEditingController(text: '1.14');

  double? _maxVoltage;
  double? _maxCurrent;
  double? _minDisconnectVoltage;
  double? _minDisconnectCurrent;
  String? _recommendation;

  @override
  void dispose() {
    _vocController.dispose();
    _iscController.dispose();
    _stringsController.dispose();
    _tempCorrectionController.dispose();
    super.dispose();
  }

  void _calculate() {
    final voc = double.tryParse(_vocController.text);
    final isc = double.tryParse(_iscController.text);
    final strings = int.tryParse(_stringsController.text);
    final tempCorrection = double.tryParse(_tempCorrectionController.text);

    if (voc == null || isc == null || strings == null || tempCorrection == null) {
      setState(() {
        _maxVoltage = null;
        _maxCurrent = null;
        _minDisconnectVoltage = null;
        _minDisconnectCurrent = null;
        _recommendation = null;
      });
      return;
    }

    // NEC 690.7 - Max system voltage with temperature correction
    final maxVoltage = voc * tempCorrection;

    // NEC 690.8 - Max current = Isc × 1.25 × number of parallel strings
    final maxCurrent = isc * 1.25 * strings;

    // Disconnect must be rated for calculated values
    // Standard DC disconnect ratings
    final disconnectVoltages = [600, 1000, 1500];
    final disconnectCurrents = [30, 60, 100, 200, 400, 600];

    int minDisconnectVoltage = 600;
    for (final v in disconnectVoltages) {
      if (v >= maxVoltage) {
        minDisconnectVoltage = v;
        break;
      }
    }

    int minDisconnectCurrent = 30;
    for (final c in disconnectCurrents) {
      if (c >= maxCurrent) {
        minDisconnectCurrent = c;
        break;
      }
    }

    String recommendation;
    if (maxVoltage > 600) {
      recommendation = '1000V or 1500V rated DC disconnect required (above 600V).';
    } else if (maxCurrent > 100) {
      recommendation = 'Consider fused disconnect or DC-rated molded case switch.';
    } else {
      recommendation = 'Standard 600V DC disconnect suitable for this system.';
    }

    setState(() {
      _maxVoltage = maxVoltage;
      _maxCurrent = maxCurrent;
      _minDisconnectVoltage = minDisconnectVoltage.toDouble();
      _minDisconnectCurrent = minDisconnectCurrent.toDouble();
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
    _vocController.text = '500';
    _iscController.text = '10.8';
    _stringsController.text = '2';
    _tempCorrectionController.text = '1.14';
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
        title: Text('DC Disconnect', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ARRAY PARAMETERS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'String Voc',
                      unit: 'V',
                      hint: 'Open circuit',
                      controller: _vocController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Module Isc',
                      unit: 'A',
                      hint: 'Short circuit',
                      controller: _iscController,
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
                      label: 'Parallel Strings',
                      unit: '#',
                      hint: 'String count',
                      controller: _stringsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Temp Factor',
                      unit: '×',
                      hint: 'NEC 690.7',
                      controller: _tempCorrectionController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_maxVoltage != null) ...[
                _buildSectionHeader(colors, 'DISCONNECT SIZING'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildNecReference(colors),
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
              Icon(LucideIcons.powerOff, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'DC Disconnect Sizing',
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
            'Size PV source circuit disconnect per NEC 690',
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
          Text('Minimum DC Disconnect Rating', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRatingBox(colors, '${_minDisconnectVoltage!.toInt()}V', colors.accentPrimary),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('/', style: TextStyle(color: colors.textTertiary, fontSize: 24)),
              ),
              _buildRatingBox(colors, '${_minDisconnectCurrent!.toInt()}A', colors.accentInfo),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCalcTile(colors, 'Max Voc', '${_maxVoltage!.toStringAsFixed(0)} V'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCalcTile(colors, 'Max Current', '${_maxCurrent!.toStringAsFixed(1)} A'),
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

  Widget _buildRatingBox(ZaftoColors colors, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        value,
        style: TextStyle(color: accentColor, fontSize: 28, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildCalcTile(ZaftoColors colors, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.fillDefault,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildNecReference(ZaftoColors colors) {
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
          Text('NEC REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildNecRow(colors, '690.13', 'Disconnect must isolate all ungrounded conductors'),
          _buildNecRow(colors, '690.14', 'Must be DC-rated (not AC-only)'),
          _buildNecRow(colors, '690.15', 'Load-break rating for disconnecting under load'),
          _buildNecRow(colors, '690.7', 'Voltage rating based on temp-corrected Voc'),
        ],
      ),
    );
  }

  Widget _buildNecRow(ZaftoColors colors, String code, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(code, style: TextStyle(color: colors.accentPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(description, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
