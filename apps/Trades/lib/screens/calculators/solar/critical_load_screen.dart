import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Critical Load Calculator - Essential circuits sizing
class CriticalLoadScreen extends ConsumerStatefulWidget {
  const CriticalLoadScreen({super.key});
  @override
  ConsumerState<CriticalLoadScreen> createState() => _CriticalLoadScreenState();
}

class _CriticalLoadScreenState extends ConsumerState<CriticalLoadScreen> {
  // Common loads with typical wattages
  final Map<String, double> _loads = {
    'Refrigerator': 150,
    'Freezer': 100,
    'Lights (LED)': 50,
    'Router/Modem': 20,
    'Phone Chargers': 20,
    'TV': 100,
    'Laptop': 50,
    'Sump Pump': 800,
    'Garage Door': 500,
    'Security System': 30,
    'Medical Equipment': 200,
    'Well Pump': 1000,
  };

  final Map<String, bool> _selectedLoads = {};
  final Map<String, TextEditingController> _customWatts = {};

  double _totalWatts = 0;
  double _totalKwh = 0;
  String? _recommendation;

  @override
  void initState() {
    super.initState();
    for (final load in _loads.keys) {
      _selectedLoads[load] = false;
      _customWatts[load] = TextEditingController(text: _loads[load]!.toStringAsFixed(0));
    }
    _calculate();
  }

  @override
  void dispose() {
    for (final controller in _customWatts.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _calculate() {
    double totalWatts = 0;
    for (final load in _loads.keys) {
      if (_selectedLoads[load] == true) {
        final watts = double.tryParse(_customWatts[load]!.text) ?? 0;
        totalWatts += watts;
      }
    }

    // Assume 24hr runtime for daily kWh
    final totalKwh = (totalWatts / 1000) * 24;

    String recommendation;
    if (totalWatts < 1000) {
      recommendation = 'Light load - any battery system will provide extended backup.';
    } else if (totalWatts < 3000) {
      recommendation = 'Moderate load - 10-15 kWh battery recommended.';
    } else if (totalWatts < 5000) {
      recommendation = 'Heavy load - 20+ kWh or multiple batteries needed.';
    } else {
      recommendation = 'Very heavy load - consider load-shedding or generator backup.';
    }

    setState(() {
      _totalWatts = totalWatts;
      _totalKwh = totalKwh;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    for (final load in _loads.keys) {
      _selectedLoads[load] = false;
      _customWatts[load]!.text = _loads[load]!.toStringAsFixed(0);
    }
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
        title: Text('Critical Loads', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary),
            onPressed: _clearAll,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoCard(colors),
                    const SizedBox(height: 24),
                    _buildSectionHeader(colors, 'SELECT ESSENTIAL LOADS'),
                    const SizedBox(height: 12),
                    ..._loads.keys.map((load) => _buildLoadRow(colors, load)),
                  ],
                ),
              ),
            ),
            _buildSummaryBar(colors),
          ],
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
              Icon(LucideIcons.listChecks, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Critical Load Audit',
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
            'Select loads to include on backup circuits',
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

  Widget _buildLoadRow(ZaftoColors colors, String load) {
    final isSelected = _selectedLoads[load] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedLoads[load] = !isSelected);
              _calculate();
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: isSelected
                  ? Icon(LucideIcons.check, size: 16, color: colors.isDark ? Colors.black : Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              load,
              style: TextStyle(
                color: isSelected ? colors.textPrimary : colors.textSecondary,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: TextField(
              controller: _customWatts[load],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: '0',
                hintStyle: TextStyle(color: colors.textTertiary),
                suffixText: ' W',
                suffixStyle: TextStyle(color: colors.textTertiary, fontSize: 12),
              ),
              onChanged: (_) => _calculate(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Critical Load', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                    Text(
                      '${(_totalWatts / 1000).toStringAsFixed(2)} kW',
                      style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Daily Usage', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                    Text(
                      '${_totalKwh.toStringAsFixed(1)} kWh/day',
                      style: TextStyle(color: colors.textSecondary, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_recommendation != null) ...[
            const SizedBox(height: 12),
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
        ],
      ),
    );
  }
}
