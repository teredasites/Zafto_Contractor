import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Main Panel Evaluation - Panel upgrade assessment
class MainPanelEvaluationScreen extends ConsumerStatefulWidget {
  const MainPanelEvaluationScreen({super.key});
  @override
  ConsumerState<MainPanelEvaluationScreen> createState() => _MainPanelEvaluationScreenState();
}

class _MainPanelEvaluationScreenState extends ConsumerState<MainPanelEvaluationScreen> {
  final _mainBreakerController = TextEditingController(text: '200');
  final _busbarRatingController = TextEditingController(text: '200');
  final _solarBreakerController = TextEditingController(text: '40');
  final _availableSlotsController = TextEditingController(text: '4');

  String _panelAge = '10-20 years';
  String _panelBrand = 'Square D';
  bool _hasSubpanel = false;

  bool? _suitableForSolar;
  List<String>? _issues;
  List<String>? _options;
  String? _recommendation;

  @override
  void dispose() {
    _mainBreakerController.dispose();
    _busbarRatingController.dispose();
    _solarBreakerController.dispose();
    _availableSlotsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final mainBreaker = double.tryParse(_mainBreakerController.text);
    final busbarRating = double.tryParse(_busbarRatingController.text);
    final solarBreaker = double.tryParse(_solarBreakerController.text);
    final availableSlots = int.tryParse(_availableSlotsController.text);

    if (mainBreaker == null || busbarRating == null || solarBreaker == null || availableSlots == null) {
      setState(() {
        _suitableForSolar = null;
        _issues = null;
        _options = null;
        _recommendation = null;
      });
      return;
    }

    List<String> issues = [];
    List<String> options = [];

    // Check 120% rule
    final totalBreakers = mainBreaker + solarBreaker;
    final maxAllowed = busbarRating * 1.2;
    final passes120 = totalBreakers <= maxAllowed;

    if (!passes120) {
      issues.add('Exceeds 120% rule: ${totalBreakers.toStringAsFixed(0)}A > ${maxAllowed.toStringAsFixed(0)}A');
      options.add('De-rate main breaker to ${(maxAllowed - solarBreaker).toStringAsFixed(0)}A');
      options.add('Use supply-side tap connection');
      options.add('Upgrade panel busbar rating');
    }

    // Check available slots
    if (availableSlots < 2) {
      issues.add('Insufficient breaker slots (need 2 for double-pole)');
      options.add('Install tandem breakers to free slots');
      options.add('Add subpanel for new circuits');
    }

    // Check panel age/brand concerns
    if (_panelAge == '>30 years') {
      issues.add('Panel may be outdated - verify compatibility');
      options.add('Consider full panel upgrade');
    }

    // Known problematic panels
    if (_panelBrand == 'Federal Pacific' || _panelBrand == 'Zinsco') {
      issues.add('${_panelBrand} panels have known safety issues');
      options.add('Panel replacement strongly recommended');
    }

    // Check for small panels
    if (mainBreaker < 100) {
      issues.add('Small service (${mainBreaker.toStringAsFixed(0)}A) may limit solar size');
      options.add('Consider service upgrade to 200A');
    }

    final suitableForSolar = issues.isEmpty;

    String recommendation;
    if (suitableForSolar) {
      recommendation = 'Panel is suitable for solar interconnection. Standard installation applies.';
    } else if (issues.length == 1 && !passes120) {
      recommendation = 'Panel can work with modifications. De-rate main or use supply-side tap.';
    } else if (_panelBrand == 'Federal Pacific' || _panelBrand == 'Zinsco') {
      recommendation = 'Panel replacement required before solar installation.';
    } else {
      recommendation = 'Multiple issues identified. Review options with customer.';
    }

    setState(() {
      _suitableForSolar = suitableForSolar;
      _issues = issues;
      _options = options;
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
    _mainBreakerController.text = '200';
    _busbarRatingController.text = '200';
    _solarBreakerController.text = '40';
    _availableSlotsController.text = '4';
    setState(() {
      _panelAge = '10-20 years';
      _panelBrand = 'Square D';
      _hasSubpanel = false;
    });
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
        title: Text('Panel Evaluation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'PANEL SPECIFICATIONS'),
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
                      hint: 'Backfeed',
                      controller: _solarBreakerController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Available Slots',
                      unit: 'qty',
                      hint: 'Open spaces',
                      controller: _availableSlotsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PANEL DETAILS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildAgeSelector(colors)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildBrandSelector(colors)),
                ],
              ),
              const SizedBox(height: 32),
              if (_suitableForSolar != null) ...[
                _buildSectionHeader(colors, 'EVALUATION RESULTS'),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.clipboardCheck, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Main Panel Evaluation',
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
            'Assess existing panel for solar compatibility',
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

  Widget _buildAgeSelector(ZaftoColors colors) {
    final ages = ['<10 years', '10-20 years', '20-30 years', '>30 years'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _panelAge,
          isExpanded: true,
          dropdownColor: colors.bgElevated,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          icon: Icon(LucideIcons.chevronDown, color: colors.textSecondary, size: 18),
          items: ages.map((age) {
            return DropdownMenuItem(value: age, child: Text(age));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              HapticFeedback.selectionClick();
              setState(() => _panelAge = value);
              _calculate();
            }
          },
        ),
      ),
    );
  }

  Widget _buildBrandSelector(ZaftoColors colors) {
    final brands = ['Square D', 'Siemens', 'Eaton', 'GE', 'Cutler-Hammer', 'Murray', 'Federal Pacific', 'Zinsco', 'Other'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _panelBrand == 'Federal Pacific' || _panelBrand == 'Zinsco' ? colors.accentError : colors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _panelBrand,
          isExpanded: true,
          dropdownColor: colors.bgElevated,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          icon: Icon(LucideIcons.chevronDown, color: colors.textSecondary, size: 18),
          items: brands.map((brand) {
            final isDangerous = brand == 'Federal Pacific' || brand == 'Zinsco';
            return DropdownMenuItem(
              value: brand,
              child: Text(brand, style: TextStyle(color: isDangerous ? colors.accentError : null)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              HapticFeedback.selectionClick();
              setState(() => _panelBrand = value);
              _calculate();
            }
          },
        ),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final statusColor = _suitableForSolar! ? colors.accentSuccess : colors.accentWarning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _suitableForSolar! ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
                  size: 18,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _suitableForSolar! ? 'Suitable for Solar' : 'Issues Identified',
                  style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (_issues != null && _issues!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.accentError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ISSUES', style: TextStyle(color: colors.accentError, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  ..._issues!.map((issue) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.x, size: 14, color: colors.accentError),
                        const SizedBox(width: 8),
                        Expanded(child: Text(issue, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
          if (_options != null && _options!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.accentInfo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('OPTIONS', style: TextStyle(color: colors.accentInfo, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  ..._options!.map((option) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.arrowRight, size: 14, color: colors.accentInfo),
                        const SizedBox(width: 8),
                        Expanded(child: Text(option, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lightbulb, size: 16, color: colors.accentPrimary),
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
}
