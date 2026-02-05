import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// UPS Sizing Calculator - Design System v2.6
/// Uninterruptible Power Supply selection for backup power
class UpsSizingScreen extends ConsumerStatefulWidget {
  const UpsSizingScreen({super.key});
  @override
  ConsumerState<UpsSizingScreen> createState() => _UpsSizingScreenState();
}

class _UpsSizingScreenState extends ConsumerState<UpsSizingScreen> {
  // Equipment list
  final List<Map<String, dynamic>> _equipment = [
    {'name': 'Desktop Computer', 'watts': 300, 'qty': 1, 'enabled': true},
    {'name': 'Monitor (24")', 'watts': 40, 'qty': 1, 'enabled': true},
    {'name': 'Router/Modem', 'watts': 20, 'qty': 1, 'enabled': true},
  ];

  double _customWatts = 0;
  int _runtimeMinutes = 15; // Desired runtime in minutes
  double _powerFactor = 0.8; // Typical for computers
  String _upsType = 'line_interactive'; // standby, line_interactive, online

  // UPS type descriptions
  static const Map<String, Map<String, dynamic>> _upsTypes = {
    'standby': {
      'name': 'Standby (Offline)',
      'efficiency': 0.95,
      'switchTime': '5-12 ms',
      'cost': '\$',
      'use': 'Basic computers, home use',
    },
    'line_interactive': {
      'name': 'Line Interactive',
      'efficiency': 0.97,
      'switchTime': '2-4 ms',
      'cost': '\$\$',
      'use': 'Small servers, workstations',
    },
    'online': {
      'name': 'Online (Double Conversion)',
      'efficiency': 0.90,
      'switchTime': '0 ms',
      'cost': '\$\$\$',
      'use': 'Critical servers, medical',
    },
  };

  // Common equipment presets
  static const List<Map<String, dynamic>> _equipmentPresets = [
    {'name': 'Desktop Computer', 'watts': 300},
    {'name': 'Gaming PC', 'watts': 600},
    {'name': 'Laptop', 'watts': 65},
    {'name': 'Monitor (24")', 'watts': 40},
    {'name': 'Monitor (27" 4K)', 'watts': 65},
    {'name': 'Router/Modem', 'watts': 20},
    {'name': 'NAS (4-bay)', 'watts': 100},
    {'name': 'Server (Small)', 'watts': 400},
    {'name': 'Server (Rack)', 'watts': 800},
    {'name': 'Network Switch', 'watts': 50},
    {'name': 'External Drive', 'watts': 15},
    {'name': 'Printer (Laser)', 'watts': 600},
    {'name': 'Security Camera', 'watts': 12},
    {'name': 'Smart Home Hub', 'watts': 10},
  ];

  double get _totalWatts {
    double total = 0;
    for (final item in _equipment) {
      if (item['enabled'] == true) {
        total += (item['watts'] as int) * (item['qty'] as int);
      }
    }
    total += _customWatts;
    return total;
  }

  // VA = Watts / Power Factor
  double get _totalVA => _totalWatts / _powerFactor;

  // Add 25% safety margin
  double get _recommendedVA => _totalVA * 1.25;

  // Standard UPS sizes
  static const List<int> _standardSizes = [350, 450, 550, 650, 750, 850, 1000, 1350, 1500, 2000, 2200, 3000];

  int get _recommendedUPSSize {
    for (final size in _standardSizes) {
      if (size >= _recommendedVA) return size;
    }
    return _standardSizes.last;
  }

  // Estimated runtime calculation (simplified)
  // Runtime = (UPS VA × Power Factor × Battery Efficiency × Runtime Factor) / Load Watts
  double get _estimatedRuntime {
    final batteryEfficiency = 0.9;
    final runtimeFactor = 0.5; // Typical for small UPS at full load
    final upsSize = _recommendedUPSSize.toDouble();
    if (_totalWatts == 0) return 0;
    return (upsSize * _powerFactor * batteryEfficiency * runtimeFactor) / _totalWatts;
  }

  // Battery Ah estimation (for extended runtime)
  double get _batteryAhFor15Min {
    // Wh = W × hours
    // Ah = Wh / Voltage (typically 12V battery)
    final whNeeded = _totalWatts * (_runtimeMinutes / 60);
    return whNeeded / 12 / 0.8; // 80% depth of discharge
  }

  String get _loadPercentage {
    if (_recommendedUPSSize == 0) return '0%';
    return '${((_totalVA / _recommendedUPSSize) * 100).toStringAsFixed(0)}%';
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
        title: Text('UPS Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildEquipmentCard(colors),
          const SizedBox(height: 16),
          _buildAddEquipmentCard(colors),
          const SizedBox(height: 16),
          _buildCustomLoadCard(colors),
          const SizedBox(height: 16),
          _buildUPSTypeCard(colors),
          const SizedBox(height: 16),
          _buildRuntimeCard(colors),
          const SizedBox(height: 20),
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildBreakdownCard(colors),
          const SizedBox(height: 16),
          _buildTipsCard(colors),
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EQUIPMENT TO PROTECT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          ..._equipment.asMap().entries.map((entry) => _buildEquipmentRow(colors, entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildEquipmentRow(ZaftoColors colors, int index, Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _equipment[index]['enabled'] = !item['enabled']);
            },
            child: Icon(
              item['enabled'] ? LucideIcons.checkSquare : LucideIcons.square,
              color: item['enabled'] ? colors.accentPrimary : colors.textTertiary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item['name'],
              style: TextStyle(
                color: item['enabled'] ? colors.textPrimary : colors.textTertiary,
                fontSize: 14,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  if (item['qty'] > 1) {
                    HapticFeedback.selectionClick();
                    setState(() => _equipment[index]['qty'] = item['qty'] - 1);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(4)),
                  child: Icon(LucideIcons.minus, size: 14, color: colors.textSecondary),
                ),
              ),
              Container(
                width: 32,
                alignment: Alignment.center,
                child: Text('${item['qty']}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _equipment[index]['qty'] = item['qty'] + 1);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(4)),
                  child: Icon(LucideIcons.plus, size: 14, color: colors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text(
              '${item['watts']}W',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _equipment.removeAt(index));
            },
            child: Icon(LucideIcons.x, size: 16, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildAddEquipmentCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ADD EQUIPMENT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _equipmentPresets.map((preset) {
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _equipment.add({
                      'name': preset['name'],
                      'watts': preset['watts'],
                      'qty': 1,
                      'enabled': true,
                    });
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.bgBase,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.plus, size: 12, color: colors.accentPrimary),
                      const SizedBox(width: 6),
                      Text(
                        preset['name'],
                        style: TextStyle(color: colors.textPrimary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomLoadCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ADDITIONAL CUSTOM LOAD (watts)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _customWatts,
                  min: 0,
                  max: 2000,
                  divisions: 40,
                  activeColor: colors.accentPrimary,
                  inactiveColor: colors.bgBase,
                  onChanged: (v) => setState(() => _customWatts = v),
                ),
              ),
              Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '${_customWatts.toInt()}W',
                  style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUPSTypeCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('UPS TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          ..._upsTypes.entries.map((entry) => _buildUPSTypeOption(colors, entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildUPSTypeOption(ZaftoColors colors, String key, Map<String, dynamic> data) {
    final isSelected = _upsType == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _upsType = key);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary.withValues(alpha: 0.15) : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? colors.accentPrimary : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
              color: isSelected ? colors.accentPrimary : colors.textTertiary,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(data['name'], style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(data['cost'], style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Switch: ${data['switchTime']} • ${data['use']}', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuntimeCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DESIRED RUNTIME', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [5, 10, 15, 20, 30, 60].map((mins) {
              final isSelected = _runtimeMinutes == mins;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _runtimeMinutes = mins);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    mins >= 60 ? '${mins ~/ 60}hr' : '${mins}min',
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text('Runtime varies based on actual load', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Text('RECOMMENDED UPS SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          const SizedBox(height: 8),
          Text(
            '$_recommendedUPSSize',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text('VA (volt-amps)', style: TextStyle(color: colors.textSecondary, fontSize: 15)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('${_totalWatts.toStringAsFixed(0)}', style: TextStyle(color: colors.accentPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                    Text('Watts', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                  ],
                ),
                Container(width: 1, height: 40, color: colors.borderSubtle),
                Column(
                  children: [
                    Text(_loadPercentage, style: TextStyle(color: colors.textSecondary, fontSize: 20, fontWeight: FontWeight.w700)),
                    Text('Load', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                  ],
                ),
                Container(width: 1, height: 40, color: colors.borderSubtle),
                Column(
                  children: [
                    Text('~${_estimatedRuntime.toStringAsFixed(0)}', style: TextStyle(color: colors.textSecondary, fontSize: 20, fontWeight: FontWeight.w700)),
                    Text('Min runtime', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CALCULATION BREAKDOWN', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildCalcRow(colors, 'Total watts', '${_totalWatts.toStringAsFixed(0)}W', false),
          _buildCalcRow(colors, 'Power factor', _powerFactor.toString(), false),
          _buildCalcRow(colors, 'Calculated VA', '${_totalVA.toStringAsFixed(0)} VA', false),
          _buildCalcRow(colors, '+ 25% safety margin', '${(_totalVA * 0.25).toStringAsFixed(0)} VA', false),
          const Divider(height: 20),
          _buildCalcRow(colors, 'Recommended minimum', '${_recommendedVA.toStringAsFixed(0)} VA', true),
          _buildCalcRow(colors, 'Standard size selected', '$_recommendedUPSSize VA', true),
          const SizedBox(height: 12),
          if (_runtimeMinutes > 15)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.info, color: const Color(0xFFE65100), size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For ${_runtimeMinutes}+ min runtime, consider external battery pack (~${_batteryAhFor15Min.toStringAsFixed(0)}Ah @ 12V)',
                      style: const TextStyle(color: Color(0xFFE65100), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalcRow(ZaftoColors colors, String label, String value, bool highlight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: highlight ? colors.accentPrimary : colors.textPrimary,
              fontSize: 13,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.lightbulb, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 8),
              Text('UPS SELECTION TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip(colors, 'Keep UPS load below 80% for optimal battery life'),
          _buildTip(colors, 'Pure sine wave output recommended for sensitive electronics'),
          _buildTip(colors, 'Replace batteries every 3-5 years'),
          _buildTip(colors, 'Do not connect laser printers to UPS (high surge)'),
          _buildTip(colors, 'Test UPS monthly by unplugging from wall'),
        ],
      ),
    );
  }

  Widget _buildTip(ZaftoColors colors, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.check, color: Colors.green, size: 14),
          const SizedBox(width: 8),
          Expanded(child: Text(tip, style: TextStyle(color: colors.textPrimary, fontSize: 13))),
        ],
      ),
    );
  }
}
