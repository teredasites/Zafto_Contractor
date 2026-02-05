import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/saved_calculation.dart';
import '../../services/calculation_history_service.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

enum HistoryFilter { all, favorites, recent }

final historyFilterProvider = StateProvider<HistoryFilter>((ref) => HistoryFilter.all);
final selectedCalcTypeProvider = StateProvider<CalculatorType?>((ref) => null);

final filteredCalculationsProvider = Provider<List<SavedCalculation>>((ref) {
  final allCalcs = ref.watch(calculationHistoryProvider);
  final filter = ref.watch(historyFilterProvider);
  final selectedType = ref.watch(selectedCalcTypeProvider);
  List<SavedCalculation> filtered;
  switch (filter) {
    case HistoryFilter.favorites: filtered = allCalcs.where((c) => c.isFavorite).toList(); break;
    case HistoryFilter.recent: filtered = allCalcs.take(10).toList(); break;
    case HistoryFilter.all: default: filtered = allCalcs;
  }
  if (selectedType != null) filtered = filtered.where((c) => c.calculatorType == selectedType).toList();
  return filtered;
});

class CalculationHistoryScreen extends ConsumerWidget {
  const CalculationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final calculations = ref.watch(filteredCalculationsProvider);
    final currentFilter = ref.watch(historyFilterProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0, leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Calculation History', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [if (calculations.isNotEmpty) IconButton(icon: Icon(LucideIcons.trash2, color: colors.textSecondary), onPressed: () => _showClearAllDialog(context, ref, colors))]),
      body: Column(children: [_buildFilterChips(ref, currentFilter, colors), _buildTypeFilter(ref, colors), Expanded(child: calculations.isEmpty ? _buildEmptyState(currentFilter, colors) : _buildCalculationsList(context, ref, calculations, colors))]),
    );
  }

  Widget _buildFilterChips(WidgetRef ref, HistoryFilter current, ZaftoColors colors) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [
      _FilterChip(label: 'All', isSelected: current == HistoryFilter.all, colors: colors, onTap: () => ref.read(historyFilterProvider.notifier).state = HistoryFilter.all),
      const SizedBox(width: 8),
      _FilterChip(label: 'Favorites', icon: LucideIcons.star, isSelected: current == HistoryFilter.favorites, colors: colors, onTap: () => ref.read(historyFilterProvider.notifier).state = HistoryFilter.favorites),
      const SizedBox(width: 8),
      _FilterChip(label: 'Recent', icon: LucideIcons.clock, isSelected: current == HistoryFilter.recent, colors: colors, onTap: () => ref.read(historyFilterProvider.notifier).state = HistoryFilter.recent),
    ]));
  }

  Widget _buildTypeFilter(WidgetRef ref, ZaftoColors colors) {
    final selectedType = ref.watch(selectedCalcTypeProvider);
    final allCalcs = ref.watch(calculationHistoryProvider);
    final types = allCalcs.map((c) => c.calculatorType).toSet().toList();
    if (types.isEmpty) return const SizedBox.shrink();
    return Container(height: 40, margin: const EdgeInsets.only(bottom: 8), child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
      _TypeChip(label: 'All Types', isSelected: selectedType == null, colors: colors, onTap: () => ref.read(selectedCalcTypeProvider.notifier).state = null),
      ...types.map((type) => Padding(padding: const EdgeInsets.only(left: 8), child: _TypeChip(label: type.displayName, isSelected: selectedType == type, colors: colors, onTap: () => ref.read(selectedCalcTypeProvider.notifier).state = type))),
    ]));
  }

  Widget _buildEmptyState(HistoryFilter filter, ZaftoColors colors) {
    String message; IconData icon;
    switch (filter) {
      case HistoryFilter.favorites: message = 'No favorite calculations yet.\nTap the star on any calculation to save it here.'; icon = LucideIcons.star; break;
      case HistoryFilter.recent: message = 'No recent calculations.\nYour last 10 calculations will appear here.'; icon = LucideIcons.clock; break;
      default: message = 'No calculations saved yet.\nRun any calculator and your results\nwill be saved automatically.'; icon = LucideIcons.calculator;
    }
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(20)), child: Icon(icon, size: 40, color: colors.textTertiary)),
      const SizedBox(height: 24),
      Text(message, textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary, fontSize: 16, height: 1.5)),
    ])));
  }

  Widget _buildCalculationsList(BuildContext context, WidgetRef ref, List<SavedCalculation> calculations, ZaftoColors colors) {
    return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: calculations.length, itemBuilder: (context, index) {
      final calc = calculations[index];
      return Padding(padding: const EdgeInsets.only(bottom: 12), child: _CalculationCard(calc: calc, colors: colors, onTap: () => _showDetailSheet(context, calc, colors), onFavorite: () => ref.read(calculationHistoryProvider.notifier).toggleFavorite(calc.id), onDelete: () => ref.read(calculationHistoryProvider.notifier).delete(calc.id)));
    });
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref, ZaftoColors colors) {
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: colors.bgElevated, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Clear All History?', style: TextStyle(color: colors.textPrimary)),
      content: Text('This will permanently delete all saved calculations.', style: TextStyle(color: colors.textSecondary)),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: colors.textSecondary))), TextButton(onPressed: () { ref.read(calculationHistoryProvider.notifier).clearAll(); Navigator.pop(context); }, child: const Text('Clear All', style: TextStyle(color: Colors.red)))],
    ));
  }

  void _showDetailSheet(BuildContext context, SavedCalculation calc, ZaftoColors colors) {
    showModalBottomSheet(context: context, backgroundColor: colors.bgElevated, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(calc.calculatorType.displayName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.textPrimary)),
        const SizedBox(height: 4),
        Text(_formatDate(calc.createdAt), style: TextStyle(color: colors.textTertiary, fontSize: 13)),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('INPUTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 8),
            ...calc.inputs.entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key, style: TextStyle(color: colors.textSecondary, fontSize: 13)), Text(e.value.toString(), style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))]))),
          ])),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('RESULTS', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 8),
            ...calc.outputs.entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key, style: TextStyle(color: colors.textSecondary, fontSize: 13)), Text(e.value.toString(), style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 14))]))),
          ])),
        const SizedBox(height: 24),
      ])));
  }

  String _formatDate(DateTime dt) => '${dt.month}/${dt.day}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
}

class _FilterChip extends StatelessWidget {
  final String label; final IconData? icon; final bool isSelected; final ZaftoColors colors; final VoidCallback onTap;
  const _FilterChip({required this.label, this.icon, required this.isSelected, required this.colors, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderDefault)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [if (icon != null) ...[Icon(icon, size: 14, color: isSelected ? colors.bgBase : colors.textSecondary), const SizedBox(width: 4)], Text(label, style: TextStyle(color: isSelected ? colors.bgBase : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13))])));
}

class _TypeChip extends StatelessWidget {
  final String label; final bool isSelected; final ZaftoColors colors; final VoidCallback onTap;
  const _TypeChip({required this.label, required this.isSelected, required this.colors, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderDefault)),
    child: Text(label, style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500))));
}

class _CalculationCard extends StatelessWidget {
  final SavedCalculation calc; final ZaftoColors colors; final VoidCallback onTap; final VoidCallback onFavorite; final VoidCallback onDelete;
  const _CalculationCard({required this.calc, required this.colors, required this.onTap, required this.onFavorite, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    final primaryResult = calc.outputs.entries.first;
    return Material(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(LucideIcons.calculator, color: colors.accentPrimary, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(calc.calculatorType.displayName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.textPrimary)), const SizedBox(height: 2), Text('${primaryResult.key}: ${primaryResult.value}', style: TextStyle(color: colors.textSecondary, fontSize: 12))])),
        IconButton(icon: Icon(calc.isFavorite ? LucideIcons.star : LucideIcons.star, color: calc.isFavorite ? Colors.amber : colors.textTertiary, size: 20), onPressed: onFavorite),
        IconButton(icon: Icon(LucideIcons.trash2, color: colors.textTertiary, size: 18), onPressed: onDelete),
      ]))));
  }
}
