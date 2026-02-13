// ZAFTO Property Scan Screen
// Created: Phase P — Sprint P7
//
// Address search → scan → swipeable result cards → lead score
// Tabs: Roof | Walls | Lot | Trades | Lead Score

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../models/property_scan.dart';
import '../../providers/property_scan_provider.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

class PropertyScanScreen extends ConsumerStatefulWidget {
  final String? initialAddress;
  final String? jobId;
  final String? scanId;

  const PropertyScanScreen({
    super.key,
    this.initialAddress,
    this.jobId,
    this.scanId,
  });

  @override
  ConsumerState<PropertyScanScreen> createState() => _PropertyScanScreenState();
}

class _PropertyScanScreenState extends ConsumerState<PropertyScanScreen> {
  final _addressController = TextEditingController();
  bool _scanning = false;
  String? _activeScanId;
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.initialAddress != null) {
      _addressController.text = widget.initialAddress!;
    }
    _activeScanId = widget.scanId;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _triggerScan() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    setState(() => _scanning = true);

    try {
      final repo = ref.read(propertyScanRepoProvider);
      final scanId = await repo.triggerScan(address: address, jobId: widget.jobId);
      if (scanId != null && mounted) {
        setState(() => _activeScanId = scanId);
        // Refresh the provider
        ref.invalidate(scanFullDataProvider(scanId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: Text(
          'Property Scan',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ── Address Search Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addressController,
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Enter property address...',
                      hintStyle: TextStyle(color: colors.textSecondary),
                      prefixIcon: Icon(LucideIcons.mapPin, size: 18, color: colors.textSecondary),
                      filled: true,
                      fillColor: colors.bgElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.accentPrimary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _triggerScan(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  width: 48,
                  child: Material(
                    color: colors.accentPrimary,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _scanning ? null : _triggerScan,
                      child: Center(
                        child: _scanning
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Icon(LucideIcons.satellite, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Scan Results ──
          Expanded(
            child: _activeScanId != null
                ? _ScanResults(
                    scanId: _activeScanId!,
                    pageController: _pageController,
                    currentPage: _currentPage,
                    onPageChanged: (page) => setState(() => _currentPage = page),
                  )
                : _EmptyState(colors: colors),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// EMPTY STATE
// ════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final ZaftoColors colors;

  const _EmptyState({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.satellite, size: 48, color: colors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'Enter an address to scan',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Get instant roof measurements, wall data,\ntrade estimates, and lead scoring.',
              style: TextStyle(color: colors.textSecondary.withValues(alpha: 0.7), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// SCAN RESULTS (swipeable cards)
// ════════════════════════════════════════════════════════════════

class _ScanResults extends ConsumerWidget {
  final String scanId;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const _ScanResults({
    required this.scanId,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
  });

  static const _tabs = ['Roof', 'Walls', 'Trades', 'Lead Score', 'History'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final asyncData = ref.watch(scanFullDataProvider(scanId));

    return asyncData.when(
      loading: () => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colors.accentPrimary),
            const SizedBox(height: 16),
            Text(
              'Scanning property...',
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.alertCircle, size: 32, color: colors.accentError),
              const SizedBox(height: 12),
              Text(
                e.toString(),
                style: TextStyle(color: colors.accentError, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      data: (data) {
        if (data == null) {
          return Center(
            child: Text(
              'Scan not found',
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
          );
        }

        return Column(
          children: [
            // Confidence + Verification badges
            _ScanStatusBar(data: data, colors: colors),

            // Tab indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final active = currentPage == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => pageController.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: active ? colors.accentPrimary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          _tabs[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: active ? colors.accentPrimary : colors.textSecondary,
                            fontSize: 12,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Swipeable pages
            Expanded(
              child: PageView(
                controller: pageController,
                onPageChanged: onPageChanged,
                children: [
                  _RoofCard(data: data, colors: colors),
                  _WallsCard(data: data, colors: colors),
                  _TradesCard(data: data, colors: colors),
                  _LeadScoreCard(data: data, colors: colors),
                  _HistoryCard(data: data, colors: colors),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
// STATUS BAR
// ════════════════════════════════════════════════════════════════

class _ScanStatusBar extends StatelessWidget {
  final ScanFullData data;
  final ZaftoColors colors;

  const _ScanStatusBar({required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    final scan = data.scan;
    final conf = scan.confidenceGrade;
    final confColor = conf == ConfidenceGrade.high
        ? Colors.green
        : conf == ConfidenceGrade.moderate
            ? Colors.amber
            : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Address
          Expanded(
            child: Text(
              scan.address,
              style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Confidence badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: confColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: confColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(
                  '${scan.confidenceScore}%',
                  style: TextStyle(color: confColor, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // Verification badge
          if (scan.isVerified) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.checkCircle, size: 12, color: Colors.blue),
                  const SizedBox(width: 3),
                  Text(
                    'Verified',
                    style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w600),
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

// ════════════════════════════════════════════════════════════════
// ROOF CARD
// ════════════════════════════════════════════════════════════════

class _RoofCard extends StatelessWidget {
  final ScanFullData data;
  final ZaftoColors colors;

  const _RoofCard({required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    final roof = data.roof;
    if (roof == null) {
      return _NoDataMessage(icon: LucideIcons.home, label: 'No roof data available', colors: colors);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          _DataCard(
            colors: colors,
            title: 'Roof Summary',
            icon: LucideIcons.home,
            rows: [
              _DataRow('Total Area', '${roof.totalAreaSqft.toStringAsFixed(0)} sq ft'),
              _DataRow('Squares', '${roof.totalAreaSquares.toStringAsFixed(1)} SQ'),
              if (roof.pitchPrimary != null) _DataRow('Primary Pitch', roof.pitchPrimary!),
              _DataRow('Facets', '${roof.facetCount}'),
              _DataRow('Complexity', '${roof.complexityScore}/10'),
              if (roof.predominantShape != null) _DataRow('Shape', roof.predominantShape!.name),
            ],
          ),
          const SizedBox(height: 12),
          // Edge lengths
          if (roof.totalEdgeLengthFt > 0)
            _DataCard(
              colors: colors,
              title: 'Edge Lengths',
              icon: LucideIcons.ruler,
              rows: [
                if (roof.ridgeLengthFt > 0) _DataRow('Ridge', '${roof.ridgeLengthFt.toStringAsFixed(0)} ft'),
                if (roof.hipLengthFt > 0) _DataRow('Hip', '${roof.hipLengthFt.toStringAsFixed(0)} ft'),
                if (roof.valleyLengthFt > 0) _DataRow('Valley', '${roof.valleyLengthFt.toStringAsFixed(0)} ft'),
                if (roof.eaveLengthFt > 0) _DataRow('Eave', '${roof.eaveLengthFt.toStringAsFixed(0)} ft'),
                if (roof.rakeLengthFt > 0) _DataRow('Rake', '${roof.rakeLengthFt.toStringAsFixed(0)} ft'),
              ],
            ),
          const SizedBox(height: 12),
          // Facets table
          if (data.facets.isNotEmpty)
            _DataCard(
              colors: colors,
              title: 'Facets (${data.facets.length})',
              icon: LucideIcons.layers,
              child: Column(
                children: data.facets.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text('#${f.facetNumber}', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                      ),
                      Expanded(
                        child: Text(
                          '${f.areaSqft.toStringAsFixed(0)} sqft  |  ${f.pitchDegrees.toStringAsFixed(0)}°  |  ${f.compassDirection}',
                          style: TextStyle(color: colors.textPrimary, fontSize: 12),
                        ),
                      ),
                      if (f.annualSunHours != null)
                        Text(
                          '${f.annualSunHours!.toStringAsFixed(0)}h sun',
                          style: TextStyle(color: colors.textSecondary, fontSize: 11),
                        ),
                    ],
                  ),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// WALLS CARD
// ════════════════════════════════════════════════════════════════

class _WallsCard extends StatelessWidget {
  final ScanFullData data;
  final ZaftoColors colors;

  const _WallsCard({required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    final wall = data.wall;
    if (wall == null) {
      return _NoDataMessage(icon: LucideIcons.square, label: 'No wall data available', colors: colors);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DataCard(
            colors: colors,
            title: 'Wall Summary',
            icon: LucideIcons.square,
            rows: [
              _DataRow('Total Wall Area', '${wall.totalWallAreaSqft.toStringAsFixed(0)} sq ft'),
              _DataRow('Siding Area', '${wall.totalSidingAreaSqft.toStringAsFixed(0)} sq ft'),
              _DataRow('Stories', '${wall.stories}'),
              _DataRow('Avg Height', '${wall.avgWallHeightFt.toStringAsFixed(0)} ft'),
            ],
          ),
          const SizedBox(height: 12),
          _DataCard(
            colors: colors,
            title: 'Trim & Accessories',
            icon: LucideIcons.scissors,
            rows: [
              _DataRow('Windows (est)', '${wall.windowAreaEstSqft.toStringAsFixed(0)} sq ft'),
              _DataRow('Doors (est)', '${wall.doorAreaEstSqft.toStringAsFixed(0)} sq ft'),
              _DataRow('Trim', '${wall.trimLinearFt.toStringAsFixed(0)} lf'),
              _DataRow('Fascia', '${wall.fasciaLinearFt.toStringAsFixed(0)} lf'),
              _DataRow('Soffit', '${wall.soffitSqft.toStringAsFixed(0)} sq ft'),
            ],
          ),
          const SizedBox(height: 12),
          if (wall.perFace.isNotEmpty)
            _DataCard(
              colors: colors,
              title: 'Per Face',
              icon: LucideIcons.compass,
              child: Column(
                children: wall.perFace.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(f.direction, style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      Expanded(
                        child: Text(
                          '${f.widthFt.toStringAsFixed(0)}×${f.heightFt.toStringAsFixed(0)} ft  =  ${f.netAreaSqft.toStringAsFixed(0)} sqft net',
                          style: TextStyle(color: colors.textPrimary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// TRADES CARD
// ════════════════════════════════════════════════════════════════

class _TradesCard extends StatelessWidget {
  final ScanFullData data;
  final ZaftoColors colors;

  const _TradesCard({required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    if (data.tradeBids.isEmpty) {
      return _NoDataMessage(icon: LucideIcons.wrench, label: 'No trade data available', colors: colors);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.tradeBids.map((bid) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _DataCard(
            colors: colors,
            title: bid.trade.name[0].toUpperCase() + bid.trade.name.substring(1),
            icon: LucideIcons.wrench,
            rows: [
              _DataRow('Waste Factor', '${bid.wasteFactorPct.toStringAsFixed(0)}%'),
              _DataRow('Complexity', '${bid.complexityScore}/10'),
              _DataRow('Crew Size', '${bid.recommendedCrewSize}'),
              if (bid.estimatedLaborHours != null)
                _DataRow('Est. Hours', '${bid.estimatedLaborHours!.toStringAsFixed(1)}'),
              _DataRow('Materials', '${bid.materialList.length} items'),
            ],
            child: bid.materialList.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(color: colors.borderSubtle, height: 1),
                        const SizedBox(height: 8),
                        ...bid.materialList.take(5).map((m) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      m.item,
                                      style: TextStyle(color: colors.textSecondary, fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${m.totalWithWaste.toStringAsFixed(1)} ${m.unit}',
                                    style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            )),
                        if (bid.materialList.length > 5)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '+ ${bid.materialList.length - 5} more items',
                              style: TextStyle(color: colors.textSecondary, fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  )
                : null,
          ),
        )).toList(),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// LEAD SCORE CARD
// ════════════════════════════════════════════════════════════════

class _LeadScoreCard extends StatelessWidget {
  final ScanFullData data;
  final ZaftoColors colors;

  const _LeadScoreCard({required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    final score = data.leadScore;
    if (score == null) {
      return _NoDataMessage(icon: LucideIcons.target, label: 'No lead score available', colors: colors);
    }

    final gradeColor = score.isHot
        ? Colors.red
        : score.isWarm
            ? Colors.orange
            : Colors.blue;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Big score circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: gradeColor.withValues(alpha: 0.1),
              border: Border.all(color: gradeColor.withValues(alpha: 0.3), width: 3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${score.overallScore}',
                  style: TextStyle(color: gradeColor, fontSize: 36, fontWeight: FontWeight.w700),
                ),
                Text(
                  score.grade.toUpperCase(),
                  style: TextStyle(color: gradeColor, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Score breakdown
          _DataCard(
            colors: colors,
            title: 'Score Breakdown',
            icon: LucideIcons.barChart3,
            rows: [
              _DataRow('Roof Age', '${score.roofAgeScore}'),
              _DataRow('Property Value', '${score.propertyValueScore}'),
              _DataRow('Owner Tenure', '${score.ownerTenureScore}'),
              _DataRow('Condition', '${score.conditionScore}'),
              _DataRow('Permit History', '${score.permitScore}'),
              if (score.stormDamageProbability > 0)
                _DataRow('Storm Damage %', '${score.stormDamageProbability.toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// HISTORY CARD
// ════════════════════════════════════════════════════════════════

class _HistoryCard extends StatelessWidget {
  final ScanFullData data;
  final ZaftoColors colors;

  const _HistoryCard({required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    if (data.history.isEmpty) {
      return _NoDataMessage(icon: LucideIcons.clock, label: 'No scan history', colors: colors);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.history.length,
      itemBuilder: (context, index) {
        final entry = data.history[index];
        final icon = switch (entry.action) {
          ScanAction.created => LucideIcons.plus,
          ScanAction.updated => LucideIcons.edit,
          ScanAction.verified => LucideIcons.checkCircle,
          ScanAction.adjusted => LucideIcons.pencil,
          ScanAction.reScanned => LucideIcons.refreshCw,
        };
        final actionColor = switch (entry.action) {
          ScanAction.verified => Colors.green,
          ScanAction.adjusted => Colors.orange,
          _ => colors.textSecondary,
        };

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 16, color: actionColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.action.name.replaceAll('reScanned', 'Re-scanned'),
                        style: TextStyle(color: actionColor, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      if (entry.fieldChanged != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${entry.fieldChanged}: ${entry.oldValue ?? "—"} → ${entry.newValue ?? "—"}',
                            style: TextStyle(color: colors.textSecondary, fontSize: 12),
                          ),
                        ),
                      if (entry.notes != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            entry.notes!,
                            style: TextStyle(color: colors.textSecondary, fontSize: 11),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _formatDate(entry.performedAt),
                          style: TextStyle(color: colors.textSecondary.withValues(alpha: 0.6), fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ════════════════════════════════════════════════════════════════

class _DataRow {
  final String label;
  final String value;
  const _DataRow(this.label, this.value);
}

class _DataCard extends StatelessWidget {
  final ZaftoColors colors;
  final String title;
  final IconData icon;
  final List<_DataRow>? rows;
  final Widget? child;

  const _DataCard({
    required this.colors,
    required this.title,
    required this.icon,
    this.rows,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: colors.accentPrimary),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (rows != null)
            ...rows!.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                      Text(r.value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _NoDataMessage extends StatelessWidget {
  final IconData icon;
  final String label;
  final ZaftoColors colors;

  const _NoDataMessage({required this.icon, required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: colors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
