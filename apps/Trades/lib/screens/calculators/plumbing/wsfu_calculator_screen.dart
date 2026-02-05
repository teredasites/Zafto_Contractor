import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Water Supply Fixture Unit (WSFU) Calculator - Design System v2.6
///
/// Calculates total WSFU load and determines water supply pipe sizing per IPC 2024.
/// Covers: building supply, branches, risers.
///
/// References: IPC Table 604.3, IPC Table E103.3(2), IPC 604.3
class WsfuCalculatorScreen extends ConsumerStatefulWidget {
  const WsfuCalculatorScreen({super.key});
  @override
  ConsumerState<WsfuCalculatorScreen> createState() => _WsfuCalculatorScreenState();
}

class _WsfuCalculatorScreenState extends ConsumerState<WsfuCalculatorScreen> {
  // Fixture counts - residential (private use)
  int _waterClosetTank = 0;
  int _waterClosetFlush = 0;
  int _lavatory = 0;
  int _bathtub = 0;
  int _shower = 0;
  int _kitchenSink = 0;
  int _dishwasher = 0;
  int _clothesWasher = 0;
  int _laundryTub = 0;
  int _hoseBibb = 0;

  // Fixture counts - commercial/public
  int _urinalFlush = 0;
  int _urinalTank = 0;
  int _serviceSink = 0;
  int _drinkingFountain = 0;
  int _mopSink = 0;

  // Display mode
  bool _showCommercial = false;

  // Flush type toggle for WSFU values
  String _systemType = 'private'; // 'private' or 'public'

  // WSFU values per IPC 2024 Table 604.3
  // Format: {fixture: {cold, hot, total}}
  static const Map<String, Map<String, double>> _wsfuValuesPrivate = {
    'waterClosetTank': {'cold': 2.2, 'hot': 0, 'total': 2.2},
    'waterClosetFlush': {'cold': 2.2, 'hot': 0, 'total': 2.2},
    'lavatory': {'cold': 0.5, 'hot': 0.5, 'total': 1.0},
    'bathtub': {'cold': 1.0, 'hot': 1.0, 'total': 1.4},
    'shower': {'cold': 1.0, 'hot': 1.0, 'total': 1.4},
    'kitchenSink': {'cold': 1.0, 'hot': 1.0, 'total': 1.4},
    'dishwasher': {'cold': 0, 'hot': 1.4, 'total': 1.4},
    'clothesWasher': {'cold': 1.0, 'hot': 1.0, 'total': 1.4},
    'laundryTub': {'cold': 1.0, 'hot': 1.0, 'total': 1.4},
    'hoseBibb': {'cold': 2.5, 'hot': 0, 'total': 2.5},
  };

  static const Map<String, Map<String, double>> _wsfuValuesPublic = {
    'waterClosetTank': {'cold': 2.2, 'hot': 0, 'total': 2.2},
    'waterClosetFlush': {'cold': 5.0, 'hot': 0, 'total': 5.0},
    'lavatory': {'cold': 1.5, 'hot': 1.5, 'total': 2.0},
    'urinalFlush': {'cold': 3.0, 'hot': 0, 'total': 3.0},
    'urinalTank': {'cold': 2.0, 'hot': 0, 'total': 2.0},
    'serviceSink': {'cold': 1.5, 'hot': 1.5, 'total': 2.25},
    'drinkingFountain': {'cold': 0.25, 'hot': 0, 'total': 0.25},
    'mopSink': {'cold': 1.5, 'hot': 1.5, 'total': 3.0},
  };

  // Water supply pipe sizing (IPC Table E103.3(2))
  // Meter/service size limits based on WSFU at 40-60 PSI, developed length 100ft
  static final List<({String size, double maxWsfu, String gpm})> _meterSizing = [
    (size: '3/4"', maxWsfu: 14, gpm: '12'),
    (size: '1"', maxWsfu: 30, gpm: '20'),
    (size: '1-1/4"', maxWsfu: 54, gpm: '30'),
    (size: '1-1/2"', maxWsfu: 96, gpm: '46'),
    (size: '2"', maxWsfu: 216, gpm: '92'),
    (size: '2-1/2"', maxWsfu: 360, gpm: '136'),
    (size: '3"', maxWsfu: 580, gpm: '198'),
  ];

  // Branch sizing (smaller pipes)
  static final List<({String size, double maxWsfu})> _branchSizing = [
    (size: '1/2"', maxWsfu: 4),
    (size: '3/4"', maxWsfu: 14),
    (size: '1"', maxWsfu: 30),
    (size: '1-1/4"', maxWsfu: 54),
    (size: '1-1/2"', maxWsfu: 96),
    (size: '2"', maxWsfu: 216),
  ];

  double _getWsfuValue(String fixture, String type) {
    if (_systemType == 'private') {
      return _wsfuValuesPrivate[fixture]?[type] ?? 0;
    } else {
      return _wsfuValuesPublic[fixture]?[type] ?? _wsfuValuesPrivate[fixture]?[type] ?? 0;
    }
  }

  double get _totalWsfuCold {
    double total = 0;
    total += _waterClosetTank * _getWsfuValue('waterClosetTank', 'cold');
    total += _waterClosetFlush * _getWsfuValue('waterClosetFlush', 'cold');
    total += _lavatory * _getWsfuValue('lavatory', 'cold');
    total += _bathtub * _getWsfuValue('bathtub', 'cold');
    total += _shower * _getWsfuValue('shower', 'cold');
    total += _kitchenSink * _getWsfuValue('kitchenSink', 'cold');
    total += _dishwasher * _getWsfuValue('dishwasher', 'cold');
    total += _clothesWasher * _getWsfuValue('clothesWasher', 'cold');
    total += _laundryTub * _getWsfuValue('laundryTub', 'cold');
    total += _hoseBibb * _getWsfuValue('hoseBibb', 'cold');
    total += _urinalFlush * _getWsfuValue('urinalFlush', 'cold');
    total += _urinalTank * _getWsfuValue('urinalTank', 'cold');
    total += _serviceSink * _getWsfuValue('serviceSink', 'cold');
    total += _drinkingFountain * _getWsfuValue('drinkingFountain', 'cold');
    total += _mopSink * _getWsfuValue('mopSink', 'cold');
    return total;
  }

  double get _totalWsfuHot {
    double total = 0;
    total += _lavatory * _getWsfuValue('lavatory', 'hot');
    total += _bathtub * _getWsfuValue('bathtub', 'hot');
    total += _shower * _getWsfuValue('shower', 'hot');
    total += _kitchenSink * _getWsfuValue('kitchenSink', 'hot');
    total += _dishwasher * _getWsfuValue('dishwasher', 'hot');
    total += _clothesWasher * _getWsfuValue('clothesWasher', 'hot');
    total += _laundryTub * _getWsfuValue('laundryTub', 'hot');
    total += _serviceSink * _getWsfuValue('serviceSink', 'hot');
    total += _mopSink * _getWsfuValue('mopSink', 'hot');
    return total;
  }

  double get _totalWsfu {
    double total = 0;
    total += _waterClosetTank * _getWsfuValue('waterClosetTank', 'total');
    total += _waterClosetFlush * _getWsfuValue('waterClosetFlush', 'total');
    total += _lavatory * _getWsfuValue('lavatory', 'total');
    total += _bathtub * _getWsfuValue('bathtub', 'total');
    total += _shower * _getWsfuValue('shower', 'total');
    total += _kitchenSink * _getWsfuValue('kitchenSink', 'total');
    total += _dishwasher * _getWsfuValue('dishwasher', 'total');
    total += _clothesWasher * _getWsfuValue('clothesWasher', 'total');
    total += _laundryTub * _getWsfuValue('laundryTub', 'total');
    total += _hoseBibb * _getWsfuValue('hoseBibb', 'total');
    total += _urinalFlush * _getWsfuValue('urinalFlush', 'total');
    total += _urinalTank * _getWsfuValue('urinalTank', 'total');
    total += _serviceSink * _getWsfuValue('serviceSink', 'total');
    total += _drinkingFountain * _getWsfuValue('drinkingFountain', 'total');
    total += _mopSink * _getWsfuValue('mopSink', 'total');
    return total;
  }

  int get _fixtureCount {
    return _waterClosetTank + _waterClosetFlush + _lavatory + _bathtub +
           _shower + _kitchenSink + _dishwasher + _clothesWasher +
           _laundryTub + _hoseBibb + _urinalFlush + _urinalTank +
           _serviceSink + _drinkingFountain + _mopSink;
  }

  String get _minMeterSize {
    final wsfu = _totalWsfu;
    if (wsfu <= 0) return '--';
    for (final entry in _meterSizing) {
      if (wsfu <= entry.maxWsfu) return entry.size;
    }
    return '3"+';
  }

  String get _minBranchSize {
    final wsfu = _totalWsfu;
    if (wsfu <= 0) return '--';
    for (final entry in _branchSizing) {
      if (wsfu <= entry.maxWsfu) return entry.size;
    }
    return '2"+';
  }

  String get _estimatedGpm {
    final wsfu = _totalWsfu;
    if (wsfu <= 0) return '--';
    for (final entry in _meterSizing) {
      if (wsfu <= entry.maxWsfu) return '${entry.gpm} GPM';
    }
    return '198+ GPM';
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
        title: Text(
          'WSFU Calculator',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showCommercial ? LucideIcons.building2 : LucideIcons.home,
              color: colors.accentPrimary,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _showCommercial = !_showCommercial);
            },
            tooltip: _showCommercial ? 'Show Residential' : 'Show Commercial',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildSystemTypeSelector(colors),
          const SizedBox(height: 16),
          _buildResidentialFixtures(colors),
          if (_showCommercial) ...[
            const SizedBox(height: 16),
            _buildCommercialFixtures(colors),
          ],
          const SizedBox(height: 16),
          _buildPipeSizingTable(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
      floatingActionButton: _fixtureCount > 0
          ? FloatingActionButton.extended(
              onPressed: _resetAll,
              backgroundColor: colors.bgElevated,
              icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary, size: 18),
              label: Text('Reset', style: TextStyle(color: colors.textSecondary)),
            )
          : null,
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            _totalWsfu.toStringAsFixed(_totalWsfu == _totalWsfu.truncate() ? 0 : 1),
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Total Water Supply Fixture Units',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Fixtures', '$_fixtureCount'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Cold WSFU', _totalWsfuCold.toStringAsFixed(1)),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Hot WSFU', _totalWsfuHot.toStringAsFixed(1)),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Est. Peak Demand', _estimatedGpm, highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Min Meter/Service', _minMeterSize, highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Min Building Supply', _minBranchSize),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemTypeSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SYSTEM TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTypeChip(colors, 'private', 'Private Use', 'Residential, single-tenant')),
              const SizedBox(width: 12),
              Expanded(child: _buildTypeChip(colors, 'public', 'Public Use', 'Commercial, public access')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(ZaftoColors colors, String value, String label, String desc) {
    final isSelected = _systemType == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _systemType = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: TextStyle(
                color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResidentialFixtures(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.home, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'RESIDENTIAL FIXTURES',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFixtureRow(colors, 'Water Closet (Tank)', _getWsfuValue('waterClosetTank', 'total'), _waterClosetTank, (v) => setState(() => _waterClosetTank = v)),
          _buildFixtureRow(colors, 'Lavatory', _getWsfuValue('lavatory', 'total'), _lavatory, (v) => setState(() => _lavatory = v)),
          _buildFixtureRow(colors, 'Bathtub', _getWsfuValue('bathtub', 'total'), _bathtub, (v) => setState(() => _bathtub = v)),
          _buildFixtureRow(colors, 'Shower', _getWsfuValue('shower', 'total'), _shower, (v) => setState(() => _shower = v)),
          _buildFixtureRow(colors, 'Kitchen Sink', _getWsfuValue('kitchenSink', 'total'), _kitchenSink, (v) => setState(() => _kitchenSink = v)),
          _buildFixtureRow(colors, 'Dishwasher', _getWsfuValue('dishwasher', 'total'), _dishwasher, (v) => setState(() => _dishwasher = v)),
          _buildFixtureRow(colors, 'Clothes Washer', _getWsfuValue('clothesWasher', 'total'), _clothesWasher, (v) => setState(() => _clothesWasher = v)),
          _buildFixtureRow(colors, 'Laundry Tub', _getWsfuValue('laundryTub', 'total'), _laundryTub, (v) => setState(() => _laundryTub = v)),
          _buildFixtureRow(colors, 'Hose Bibb', _getWsfuValue('hoseBibb', 'total'), _hoseBibb, (v) => setState(() => _hoseBibb = v)),
        ],
      ),
    );
  }

  Widget _buildCommercialFixtures(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.building2, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'COMMERCIAL / PUBLIC',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFixtureRow(colors, 'Water Closet (Flush Valve)', _getWsfuValue('waterClosetFlush', 'total'), _waterClosetFlush, (v) => setState(() => _waterClosetFlush = v)),
          _buildFixtureRow(colors, 'Urinal (Flush Valve)', _getWsfuValue('urinalFlush', 'total'), _urinalFlush, (v) => setState(() => _urinalFlush = v)),
          _buildFixtureRow(colors, 'Urinal (Tank)', _getWsfuValue('urinalTank', 'total'), _urinalTank, (v) => setState(() => _urinalTank = v)),
          _buildFixtureRow(colors, 'Service Sink', _getWsfuValue('serviceSink', 'total'), _serviceSink, (v) => setState(() => _serviceSink = v)),
          _buildFixtureRow(colors, 'Mop Sink', _getWsfuValue('mopSink', 'total'), _mopSink, (v) => setState(() => _mopSink = v)),
          _buildFixtureRow(colors, 'Drinking Fountain', _getWsfuValue('drinkingFountain', 'total'), _drinkingFountain, (v) => setState(() => _drinkingFountain = v)),
        ],
      ),
    );
  }

  Widget _buildFixtureRow(ZaftoColors colors, String name, double wsfu, int count, void Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${wsfu.toStringAsFixed(wsfu == wsfu.truncate() ? 0 : 1)} WSFU',
                  style: TextStyle(color: colors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: count > 0
                      ? () {
                          HapticFeedback.selectionClick();
                          onChanged(count - 1);
                        }
                      : null,
                  icon: Icon(
                    LucideIcons.minus,
                    color: count > 0 ? colors.textSecondary : colors.textQuaternary,
                    size: 18,
                  ),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
                Container(
                  width: 32,
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: count > 0 ? colors.accentPrimary : colors.textTertiary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onChanged(count + 1);
                  },
                  icon: Icon(LucideIcons.plus, color: colors.accentPrimary, size: 18),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipeSizingTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'IPC TABLE E103.3(2) - METER/SERVICE SIZING',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Max WSFU at 40-60 PSI, 100ft developed length',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _meterSizing.map((entry) {
              final isHighlighted = _totalWsfu > 0 && _totalWsfu <= entry.maxWsfu &&
                  (_meterSizing.where((e) => e.maxWsfu < entry.maxWsfu && _totalWsfu <= e.maxWsfu).isEmpty);
              return Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isHighlighted ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
                  borderRadius: BorderRadius.circular(6),
                  border: isHighlighted ? Border.all(color: colors.accentPrimary) : null,
                ),
                child: Column(
                  children: [
                    Text(
                      entry.size,
                      style: TextStyle(
                        color: isHighlighted ? colors.accentPrimary : colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${entry.maxWsfu.toInt()} WSFU',
                      style: TextStyle(
                        color: isHighlighted ? colors.accentPrimary : colors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      entry.gpm,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Row(
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
    );
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.scale, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC 2024 Chapter 6',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Table 604.3 - Fixture unit values (WSFU)\n'
            '• Table E103.3(2) - Meter/service sizing\n'
            '• 604.3 - Water distribution sizing\n'
            '• 604.4 - Min pipe size 3/8" (1/2" to fixture)\n'
            '• UPC uses similar values (check local adoption)',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _resetAll() {
    HapticFeedback.mediumImpact();
    setState(() {
      _waterClosetTank = 0;
      _waterClosetFlush = 0;
      _lavatory = 0;
      _bathtub = 0;
      _shower = 0;
      _kitchenSink = 0;
      _dishwasher = 0;
      _clothesWasher = 0;
      _laundryTub = 0;
      _hoseBibb = 0;
      _urinalFlush = 0;
      _urinalTank = 0;
      _serviceSink = 0;
      _drinkingFountain = 0;
      _mopSink = 0;
    });
  }
}
