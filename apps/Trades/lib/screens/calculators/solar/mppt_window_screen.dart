import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// MPPT Window Checker - Verify string voltage fits inverter MPPT range
class MpptWindowScreen extends ConsumerStatefulWidget {
  const MpptWindowScreen({super.key});
  @override
  ConsumerState<MpptWindowScreen> createState() => _MpptWindowScreenState();
}

class _MpptWindowScreenState extends ConsumerState<MpptWindowScreen> {
  final _moduleVmpController = TextEditingController(text: '41.7');
  final _modulesInStringController = TextEditingController(text: '12');
  final _tempCoeffController = TextEditingController(text: '-0.27');
  final _tempLowController = TextEditingController(text: '-10');
  final _tempHighController = TextEditingController(text: '65');
  final _mpptMinController = TextEditingController(text: '200');
  final _mpptMaxController = TextEditingController(text: '480');

  double? _vmpAtLow;
  double? _vmpAtHigh;
  bool? _fitsWindow;
  String? _status;

  @override
  void dispose() {
    _moduleVmpController.dispose();
    _modulesInStringController.dispose();
    _tempCoeffController.dispose();
    _tempLowController.dispose();
    _tempHighController.dispose();
    _mpptMinController.dispose();
    _mpptMaxController.dispose();
    super.dispose();
  }

  void _calculate() {
    final moduleVmp = double.tryParse(_moduleVmpController.text);
    final modulesInString = int.tryParse(_modulesInStringController.text);
    final tempCoeff = double.tryParse(_tempCoeffController.text);
    final tempLow = double.tryParse(_tempLowController.text);
    final tempHigh = double.tryParse(_tempHighController.text);
    final mpptMin = double.tryParse(_mpptMinController.text);
    final mpptMax = double.tryParse(_mpptMaxController.text);

    if (moduleVmp == null || modulesInString == null || tempCoeff == null ||
        tempLow == null || tempHigh == null || mpptMin == null || mpptMax == null) {
      setState(() {
        _vmpAtLow = null;
        _vmpAtHigh = null;
        _fitsWindow = null;
        _status = null;
      });
      return;
    }

    // Calculate Vmp at cold temperature (highest voltage)
    final lowDelta = tempLow - 25;
    final vmpAtLow = moduleVmp * (1 + (tempCoeff / 100) * lowDelta) * modulesInString;

    // Calculate Vmp at hot temperature (lowest voltage)
    final highDelta = tempHigh - 25;
    final vmpAtHigh = moduleVmp * (1 + (tempCoeff / 100) * highDelta) * modulesInString;

    // Check if both extremes fit within MPPT window
    final coldOk = vmpAtLow <= mpptMax;
    final hotOk = vmpAtHigh >= mpptMin;
    final fitsWindow = coldOk && hotOk;

    String status;
    if (fitsWindow) {
      status = 'String fits MPPT window across all temperatures';
    } else if (!coldOk && !hotOk) {
      status = 'String outside MPPT window at both extremes';
    } else if (!coldOk) {
      status = 'Cold weather: Vmp exceeds MPPT max - reduce string size';
    } else {
      status = 'Hot weather: Vmp below MPPT min - increase string size';
    }

    setState(() {
      _vmpAtLow = vmpAtLow;
      _vmpAtHigh = vmpAtHigh;
      _fitsWindow = fitsWindow;
      _status = status;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _moduleVmpController.text = '41.7';
    _modulesInStringController.text = '12';
    _tempCoeffController.text = '-0.27';
    _tempLowController.text = '-10';
    _tempHighController.text = '65';
    _mpptMinController.text = '200';
    _mpptMaxController.text = '480';
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
        title: Text('MPPT Window', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'MODULE & STRING'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Module Vmp',
                      unit: 'V',
                      hint: 'Max power',
                      controller: _moduleVmpController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Modules/String',
                      unit: '',
                      hint: 'Series count',
                      controller: _modulesInStringController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Vmp Temp Coefficient',
                unit: '%/°C',
                hint: 'Negative value',
                controller: _tempCoeffController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'TEMPERATURE RANGE'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Low Temp',
                      unit: '°C',
                      hint: 'Coldest day',
                      controller: _tempLowController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'High Temp',
                      unit: '°C',
                      hint: 'Cell temp',
                      controller: _tempHighController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'INVERTER MPPT RANGE'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'MPPT Min',
                      unit: 'V',
                      hint: 'Lower bound',
                      controller: _mpptMinController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'MPPT Max',
                      unit: 'V',
                      hint: 'Upper bound',
                      controller: _mpptMaxController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_vmpAtLow != null) ...[
                _buildSectionHeader(colors, 'COMPATIBILITY CHECK'),
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
          Text(
            'MPPT Operating Window',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Verify string Vmp stays within inverter MPPT range at all temperatures',
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
    final fitsWindow = _fitsWindow!;
    final mpptMin = double.parse(_mpptMinController.text);
    final mpptMax = double.parse(_mpptMaxController.text);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fitsWindow ? colors.accentSuccess.withValues(alpha: 0.3) : colors.accentError.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Visual bar showing MPPT window and string range
          _buildWindowVisual(colors, mpptMin, mpptMax),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildVoltageCard(
                  colors,
                  'Cold (${_tempLowController.text}°C)',
                  '${_vmpAtLow!.toStringAsFixed(1)} V',
                  _vmpAtLow! <= mpptMax,
                  LucideIcons.snowflake,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildVoltageCard(
                  colors,
                  'Hot (${_tempHighController.text}°C)',
                  '${_vmpAtHigh!.toStringAsFixed(1)} V',
                  _vmpAtHigh! >= mpptMin,
                  LucideIcons.flame,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (fitsWindow ? colors.accentSuccess : colors.accentError).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  fitsWindow ? LucideIcons.checkCircle : LucideIcons.xCircle,
                  size: 18,
                  color: fitsWindow ? colors.accentSuccess : colors.accentError,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _status!,
                    style: TextStyle(
                      color: fitsWindow ? colors.accentSuccess : colors.accentError,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowVisual(ZaftoColors colors, double mpptMin, double mpptMax) {
    // Calculate positions for visualization
    final rangeSpan = mpptMax - mpptMin;
    final visualMin = mpptMin - rangeSpan * 0.2;
    final visualMax = mpptMax + rangeSpan * 0.2;
    final visualSpan = visualMax - visualMin;

    double vmpLowPos = ((_vmpAtLow! - visualMin) / visualSpan).clamp(0.0, 1.0);
    double vmpHighPos = ((_vmpAtHigh! - visualMin) / visualSpan).clamp(0.0, 1.0);
    double mpptMinPos = ((mpptMin - visualMin) / visualSpan).clamp(0.0, 1.0);
    double mpptMaxPos = ((mpptMax - visualMin) / visualSpan).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.fillDefault,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text('MPPT Window vs String Vmp Range', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return Stack(
                  children: [
                    // MPPT window (green zone)
                    Positioned(
                      left: mpptMinPos * width,
                      right: width - mpptMaxPos * width,
                      top: 15,
                      bottom: 15,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.accentSuccess.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    // String Vmp range line
                    Positioned(
                      left: vmpHighPos * width,
                      right: width - vmpLowPos * width,
                      top: 25,
                      child: Container(height: 10, color: colors.accentPrimary),
                    ),
                    // Markers
                    Positioned(
                      left: vmpHighPos * width - 3,
                      top: 22,
                      child: Container(width: 6, height: 16, decoration: BoxDecoration(color: colors.accentWarning, borderRadius: BorderRadius.circular(2))),
                    ),
                    Positioned(
                      left: vmpLowPos * width - 3,
                      top: 22,
                      child: Container(width: 6, height: 16, decoration: BoxDecoration(color: colors.accentInfo, borderRadius: BorderRadius.circular(2))),
                    ),
                  ],
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${mpptMin.toInt()}V', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              Text('MPPT Range', style: TextStyle(color: colors.accentSuccess, fontSize: 10, fontWeight: FontWeight.w600)),
              Text('${mpptMax.toInt()}V', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoltageCard(ZaftoColors colors, String label, String value, bool isOk, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isOk ? colors.accentSuccess : colors.accentError).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isOk ? colors.accentSuccess : colors.accentError),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: isOk ? colors.accentSuccess : colors.accentError, fontSize: 18, fontWeight: FontWeight.w700)),
          Icon(isOk ? LucideIcons.check : LucideIcons.x, size: 14, color: isOk ? colors.accentSuccess : colors.accentError),
        ],
      ),
    );
  }
}
