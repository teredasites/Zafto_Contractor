import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// AC Disconnect Sizing Calculator - Utility side disconnect
class AcDisconnectSizingScreen extends ConsumerStatefulWidget {
  const AcDisconnectSizingScreen({super.key});
  @override
  ConsumerState<AcDisconnectSizingScreen> createState() => _AcDisconnectSizingScreenState();
}

class _AcDisconnectSizingScreenState extends ConsumerState<AcDisconnectSizingScreen> {
  final _inverterKwController = TextEditingController(text: '7.6');
  final _voltageController = TextEditingController(text: '240');

  String _phases = 'Single';

  double? _outputCurrent;
  double? _minDisconnectAmps;
  int? _recommendedSize;
  String? _disconnectType;

  @override
  void dispose() {
    _inverterKwController.dispose();
    _voltageController.dispose();
    super.dispose();
  }

  void _calculate() {
    final inverterKw = double.tryParse(_inverterKwController.text);
    final voltage = double.tryParse(_voltageController.text);

    if (inverterKw == null || voltage == null || voltage == 0) {
      setState(() {
        _outputCurrent = null;
        _minDisconnectAmps = null;
        _recommendedSize = null;
        _disconnectType = null;
      });
      return;
    }

    // Calculate output current
    double outputCurrent;
    if (_phases == 'Single') {
      outputCurrent = (inverterKw * 1000) / voltage;
    } else {
      outputCurrent = (inverterKw * 1000) / (voltage * 1.732);
    }

    // NEC 690.8 - 125% for continuous
    final minDisconnectAmps = outputCurrent * 1.25;

    // Standard disconnect sizes
    final sizes = [30, 60, 100, 200, 400, 600, 800, 1000];
    int recommendedSize = 30;
    for (final size in sizes) {
      if (size >= minDisconnectAmps) {
        recommendedSize = size;
        break;
      }
    }

    String disconnectType;
    if (recommendedSize <= 60) {
      disconnectType = 'Fused AC disconnect or non-fused safety switch';
    } else if (recommendedSize <= 200) {
      disconnectType = 'Heavy-duty safety switch or circuit breaker enclosure';
    } else {
      disconnectType = 'Molded case switch or fusible disconnect';
    }

    setState(() {
      _outputCurrent = outputCurrent;
      _minDisconnectAmps = minDisconnectAmps;
      _recommendedSize = recommendedSize;
      _disconnectType = disconnectType;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _inverterKwController.text = '7.6';
    _voltageController.text = '240';
    setState(() => _phases = 'Single');
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
        title: Text('AC Disconnect', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'INVERTER OUTPUT'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'AC Output',
                      unit: 'kW',
                      hint: 'Inverter rating',
                      controller: _inverterKwController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Voltage',
                      unit: 'V',
                      hint: '240/208/480',
                      controller: _voltageController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildPhaseSelector(colors),
              const SizedBox(height: 32),
              if (_recommendedSize != null) ...[
                _buildSectionHeader(colors, 'DISCONNECT SIZING'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildRequirementsCard(colors),
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
              Icon(LucideIcons.toggleRight, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'AC Disconnect Sizing',
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
            'Size utility-accessible AC disconnect for inverter output',
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

  Widget _buildPhaseSelector(ZaftoColors colors) {
    final phases = ['Single', 'Three-Phase'];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: phases.map((phase) {
          final isSelected = _phases == phase;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _phases = phase);
                _calculate();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    phase,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
          Text('Minimum Disconnect Rating', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '${_recommendedSize}A',
            style: TextStyle(color: colors.accentSuccess, fontSize: 48, fontWeight: FontWeight.w700),
          ),
          Text(
            _phases == 'Single' ? 'Single-phase' : 'Three-phase',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Output', '${_outputCurrent!.toStringAsFixed(1)} A', colors.accentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, '125%', '${_minDisconnectAmps!.toStringAsFixed(1)} A', colors.accentInfo),
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
                Icon(LucideIcons.package, size: 16, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _disconnectType!,
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

  Widget _buildRequirementsCard(ZaftoColors colors) {
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
          Text('UTILITY REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildRequirement(colors, 'Visible blade or verification window'),
          _buildRequirement(colors, 'Lockable in OFF position'),
          _buildRequirement(colors, 'Accessible to utility personnel'),
          _buildRequirement(colors, 'Labeled "Solar Disconnect" or similar'),
          _buildRequirement(colors, 'Within 10 ft of meter (typical utility rule)'),
        ],
      ),
    );
  }

  Widget _buildRequirement(ZaftoColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(LucideIcons.check, size: 14, color: colors.accentSuccess),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
