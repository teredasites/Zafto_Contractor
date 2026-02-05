import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pipe Boot Calculator - Calculate pipe flashing/boot requirements
class PipeBootScreen extends ConsumerStatefulWidget {
  const PipeBootScreen({super.key});
  @override
  ConsumerState<PipeBootScreen> createState() => _PipeBootScreenState();
}

class _PipeBootScreenState extends ConsumerState<PipeBootScreen> {
  final _ventPipesController = TextEditingController(text: '3');
  final _exhaustPipesController = TextEditingController(text: '1');
  final _hvacPipesController = TextEditingController(text: '0');

  String _bootType = 'Rubber';

  int? _totalBoots;
  Map<String, int> _bootsBySize = {};

  @override
  void dispose() {
    _ventPipesController.dispose();
    _exhaustPipesController.dispose();
    _hvacPipesController.dispose();
    super.dispose();
  }

  void _calculate() {
    final ventPipes = int.tryParse(_ventPipesController.text) ?? 0;
    final exhaustPipes = int.tryParse(_exhaustPipesController.text) ?? 0;
    final hvacPipes = int.tryParse(_hvacPipesController.text) ?? 0;

    // Standard pipe sizes:
    // Vent pipes: typically 1.5" - 3" (most common 2")
    // Exhaust: typically 3" - 4"
    // HVAC: typically 4" - 6"

    final Map<String, int> bootsBySize = {};

    // Vent pipes (1.5" - 3")
    if (ventPipes > 0) {
      bootsBySize['1.5" - 3"'] = ventPipes;
    }

    // Exhaust pipes (3" - 4")
    if (exhaustPipes > 0) {
      bootsBySize['3" - 4"'] = (bootsBySize['3" - 4"'] ?? 0) + exhaustPipes;
    }

    // HVAC pipes (4" - 6")
    if (hvacPipes > 0) {
      bootsBySize['4" - 6"'] = hvacPipes;
    }

    final totalBoots = ventPipes + exhaustPipes + hvacPipes;

    setState(() {
      _totalBoots = totalBoots;
      _bootsBySize = bootsBySize;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _ventPipesController.text = '3';
    _exhaustPipesController.text = '1';
    _hvacPipesController.text = '0';
    setState(() => _bootType = 'Rubber');
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
        title: Text('Pipe Boot', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'BOOT TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PIPE COUNT BY TYPE'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Plumbing Vents',
                unit: 'qty',
                hint: '1.5" - 3" pipes',
                controller: _ventPipesController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Exhaust Vents',
                unit: 'qty',
                hint: '3" - 4" pipes',
                controller: _exhaustPipesController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'HVAC Pipes',
                unit: 'qty',
                hint: '4" - 6" pipes',
                controller: _hvacPipesController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_totalBoots != null && _totalBoots! > 0) ...[
                _buildSectionHeader(colors, 'BOOTS NEEDED'),
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
              Icon(LucideIcons.circle, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Pipe Boot Calculator',
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
            'Calculate pipe flashing requirements',
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

  Widget _buildTypeSelector(ZaftoColors colors) {
    final types = ['Rubber', 'Lead', 'Aluminum', 'TPO/PVC'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = _bootType == type;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _bootType = type);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? colors.accentPrimary : colors.bgElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? colors.accentPrimary : colors.borderSubtle,
              ),
            ),
            child: Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : colors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          _buildResultRow(colors, 'TOTAL BOOTS', '$_totalBoots', isHighlighted: true),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          ..._bootsBySize.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildResultRow(colors, 'Size ${entry.key}', '${entry.value}'),
          )),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.info, size: 16, color: colors.accentInfo),
                    const SizedBox(width: 8),
                    Text('Pipe Boot Info', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Rubber: Most common, 15-20 year life', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Lead: Moldable, long-lasting', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Verify pipe diameter before ordering', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: isHighlighted ? colors.accentPrimary : colors.textPrimary,
            fontSize: isHighlighted ? 20 : 14,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
