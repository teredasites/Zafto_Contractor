import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Load Side vs Supply Side Calculator - Connection method selector
class LoadSideSupplySideScreen extends ConsumerStatefulWidget {
  const LoadSideSupplySideScreen({super.key});
  @override
  ConsumerState<LoadSideSupplySideScreen> createState() => _LoadSideSupplySideScreenState();
}

class _LoadSideSupplySideScreenState extends ConsumerState<LoadSideSupplySideScreen> {
  final _mainBreakerController = TextEditingController(text: '200');
  final _busbarRatingController = TextEditingController(text: '200');
  final _solarBreakerController = TextEditingController(text: '60');
  final _serviceConductorController = TextEditingController(text: '200');

  bool? _loadSideOk;
  bool? _supplySideOk;
  double? _loadSideMax;
  double? _supplySideMax;
  String? _recommendedMethod;
  List<String>? _loadSideNotes;
  List<String>? _supplySideNotes;

  @override
  void dispose() {
    _mainBreakerController.dispose();
    _busbarRatingController.dispose();
    _solarBreakerController.dispose();
    _serviceConductorController.dispose();
    super.dispose();
  }

  void _calculate() {
    final mainBreaker = double.tryParse(_mainBreakerController.text);
    final busbarRating = double.tryParse(_busbarRatingController.text);
    final solarBreaker = double.tryParse(_solarBreakerController.text);
    final serviceConductor = double.tryParse(_serviceConductorController.text);

    if (mainBreaker == null || busbarRating == null || solarBreaker == null || serviceConductor == null) {
      setState(() {
        _loadSideOk = null;
        _supplySideOk = null;
        _loadSideMax = null;
        _supplySideMax = null;
        _recommendedMethod = null;
        _loadSideNotes = null;
        _supplySideNotes = null;
      });
      return;
    }

    // Load side calculation - NEC 705.12(B)(2)
    // Sum of breakers ≤ 120% of busbar
    final loadSideMax = (busbarRating * 1.2) - mainBreaker;
    final loadSideOk = solarBreaker <= loadSideMax;

    List<String> loadSideNotes = [];
    loadSideNotes.add('120% Rule: ${mainBreaker.toStringAsFixed(0)}A + ${solarBreaker.toStringAsFixed(0)}A ≤ ${(busbarRating * 1.2).toStringAsFixed(0)}A');
    if (loadSideOk) {
      loadSideNotes.add('Breaker must be at opposite end from main');
      loadSideNotes.add('Requires permanent warning label');
    } else {
      loadSideNotes.add('Can de-rate main to ${(busbarRating * 1.2 - solarBreaker).toStringAsFixed(0)}A');
    }

    // Supply side calculation - NEC 705.12(A)
    // Connected ahead of main service disconnect
    // Limited by service entrance conductor ampacity
    final supplySideMax = serviceConductor; // Simplified - actual depends on conductor
    final supplySideOk = solarBreaker <= supplySideMax * 0.25; // Conservative 25%

    List<String> supplySideNotes = [];
    supplySideNotes.add('Line-side tap ahead of main breaker');
    supplySideNotes.add('No 120% limitation applies');
    supplySideNotes.add('Must meet tap conductor rules (NEC 240.21)');
    supplySideNotes.add('Requires separate disconnect per NEC 705.12(A)');
    if (!supplySideOk) {
      supplySideNotes.add('Large system - verify service conductor sizing');
    }

    // Determine recommended method
    String recommendedMethod;
    if (loadSideOk) {
      recommendedMethod = 'Load Side - Simpler installation, passes 120% rule.';
    } else if (supplySideOk) {
      recommendedMethod = 'Supply Side - Required due to 120% rule limitation.';
    } else {
      recommendedMethod = 'Service Upgrade - Current service cannot accommodate solar size.';
    }

    setState(() {
      _loadSideOk = loadSideOk;
      _supplySideOk = supplySideOk;
      _loadSideMax = loadSideMax;
      _supplySideMax = supplySideMax * 0.25;
      _recommendedMethod = recommendedMethod;
      _loadSideNotes = loadSideNotes;
      _supplySideNotes = supplySideNotes;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _mainBreakerController.text = '200';
    _busbarRatingController.text = '200';
    _solarBreakerController.text = '60';
    _serviceConductorController.text = '200';
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
        title: Text('Load vs Supply Side', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ELECTRICAL SERVICE'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Main Breaker',
                      unit: 'A',
                      hint: 'Panel main',
                      controller: _mainBreakerController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Busbar Rating',
                      unit: 'A',
                      hint: 'Panel busbar',
                      controller: _busbarRatingController,
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
                      label: 'Solar Breaker',
                      unit: 'A',
                      hint: 'Backfeed needed',
                      controller: _solarBreakerController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Service Conductor',
                      unit: 'A',
                      hint: 'SEC ampacity',
                      controller: _serviceConductorController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_loadSideOk != null) ...[
                _buildSectionHeader(colors, 'CONNECTION OPTIONS'),
                const SizedBox(height: 12),
                _buildLoadSideCard(colors),
                const SizedBox(height: 12),
                _buildSupplySideCard(colors),
                const SizedBox(height: 16),
                _buildRecommendationCard(colors),
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
              Icon(LucideIcons.gitBranch, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Load Side vs Supply Side',
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
            'Compare interconnection methods per NEC 705.12',
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

  Widget _buildLoadSideCard(ZaftoColors colors) {
    final statusColor = _loadSideOk! ? colors.accentSuccess : colors.accentError;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _loadSideOk! ? LucideIcons.check : LucideIcons.x,
                  size: 16,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LOAD SIDE CONNECTION', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('NEC 705.12(B)(2) - 120% Rule', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Max: ${_loadSideMax!.toStringAsFixed(0)}A',
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._loadSideNotes!.map((note) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.dot, size: 14, color: colors.textTertiary),
                const SizedBox(width: 4),
                Expanded(child: Text(note, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSupplySideCard(ZaftoColors colors) {
    final statusColor = _supplySideOk! ? colors.accentSuccess : colors.accentWarning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _supplySideOk! ? LucideIcons.check : LucideIcons.alertTriangle,
                  size: 16,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SUPPLY SIDE CONNECTION', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('NEC 705.12(A) - Line Side Tap', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Max: ${_supplySideMax!.toStringAsFixed(0)}A',
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._supplySideNotes!.map((note) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.dot, size: 14, color: colors.textTertiary),
                const SizedBox(width: 4),
                Expanded(child: Text(note, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.lightbulb, size: 20, color: colors.accentPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RECOMMENDATION', style: TextStyle(color: colors.accentPrimary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(
                  _recommendedMethod!,
                  style: TextStyle(color: colors.textPrimary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
