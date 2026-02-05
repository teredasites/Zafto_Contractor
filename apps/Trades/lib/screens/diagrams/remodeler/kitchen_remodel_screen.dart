import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class KitchenRemodelScreen extends ConsumerWidget {
  const KitchenRemodelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Kitchen Remodel Basics',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWorkTriangle(colors),
            const SizedBox(height: 24),
            _buildLayoutDiagram(colors),
            const SizedBox(height: 24),
            _buildDemoSequence(colors),
            const SizedBox(height: 24),
            _buildInstallSequence(colors),
            const SizedBox(height: 24),
            _buildClearances(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkTriangle(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.triangle, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Kitchen Work Triangle',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '''         REFRIGERATOR
              ◆
             /|\\
            / | \\
           /  |  \\
       4-9'  |   4-9'
         /   |   \\
        /    |    \\
       /     |     \\
      ◆------+------◆
    SINK   4-9'   RANGE

    Total: 13-26 ft combined
    No leg < 4' or > 9'
    No obstacles crossing legs''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'The work triangle connects the three main work areas. Each leg should be 4-9 feet, with a combined total of 13-26 feet for optimal efficiency.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutDiagram(ZaftoColors colors) {
    final layouts = [
      {
        'name': 'Galley',
        'diagram': '  ═══════\n  │     │\n  ═══════',
        'best': 'Small spaces, one cook',
        'width': '4-6 ft min aisle',
      },
      {
        'name': 'L-Shape',
        'diagram': '  ═══════\n  │\n  │\n  │',
        'best': 'Open layouts, corner use',
        'width': 'Flexible sizing',
      },
      {
        'name': 'U-Shape',
        'diagram': '  │     │\n  │     │\n  ═══════',
        'best': 'Maximum storage',
        'width': '8 ft min width',
      },
      {
        'name': 'Island',
        'diagram': '  ═══════\n    ▬▬▬\n  ═══════',
        'best': 'Large kitchens',
        'width': '42" clearance min',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.layoutGrid, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Kitchen Layouts',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: layouts.map((l) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l['name'] as String,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l['diagram'] as String,
                    style: TextStyle(
                      color: colors.accentPrimary,
                      fontFamily: 'monospace',
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l['best'] as String,
                    style: TextStyle(color: colors.textSecondary, fontSize: 10),
                  ),
                  Text(
                    l['width'] as String,
                    style: TextStyle(color: colors.accentInfo, fontSize: 9),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoSequence(ZaftoColors colors) {
    final steps = [
      {'step': '1', 'task': 'Disconnect utilities', 'note': 'Water, gas, electric at source'},
      {'step': '2', 'task': 'Remove appliances', 'note': 'Cap gas lines, protect floors'},
      {'step': '3', 'task': 'Remove countertops', 'note': 'Check for attachment method'},
      {'step': '4', 'task': 'Remove upper cabinets', 'note': 'Top down, support while removing screws'},
      {'step': '5', 'task': 'Remove base cabinets', 'note': 'Disconnect plumbing first'},
      {'step': '6', 'task': 'Remove backsplash', 'note': 'Score edges, pry carefully'},
      {'step': '7', 'task': 'Remove flooring', 'note': 'Check for asbestos if pre-1980'},
      {'step': '8', 'task': 'Address subfloor issues', 'note': 'Replace damaged sections'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentError.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.hammer, color: colors.accentError, size: 20),
              const SizedBox(width: 8),
              Text(
                'Demo Sequence',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: colors.accentError,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      s['step']!,
                      style: TextStyle(
                        color: colors.bgBase,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['task']!,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        s['note']!,
                        style: TextStyle(color: colors.textTertiary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInstallSequence(ZaftoColors colors) {
    final steps = [
      {'step': '1', 'task': 'Rough-in plumbing/electric', 'icon': LucideIcons.wrench},
      {'step': '2', 'task': 'Install subfloor if needed', 'icon': LucideIcons.layers},
      {'step': '3', 'task': 'Install flooring (before cabs)', 'icon': LucideIcons.layoutGrid},
      {'step': '4', 'task': 'Set base cabinets (level/plumb)', 'icon': LucideIcons.alignVerticalJustifyCenter},
      {'step': '5', 'task': 'Install upper cabinets', 'icon': LucideIcons.alignVerticalJustifyStart},
      {'step': '6', 'task': 'Template countertops', 'icon': LucideIcons.ruler},
      {'step': '7', 'task': 'Install countertops', 'icon': LucideIcons.square},
      {'step': '8', 'task': 'Install backsplash', 'icon': LucideIcons.layoutGrid},
      {'step': '9', 'task': 'Install appliances', 'icon': LucideIcons.refrigerator},
      {'step': '10', 'task': 'Final connections/trim', 'icon': LucideIcons.checkCircle},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.listOrdered, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Installation Sequence',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colors.accentSuccess,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        s['step'] as String,
                        style: TextStyle(
                          color: colors.bgBase,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(s['icon'] as IconData, color: colors.textTertiary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s['task'] as String,
                      style: TextStyle(color: colors.textPrimary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildClearances(ZaftoColors colors) {
    final clearances = [
      {'item': 'Counter depth', 'min': '24"', 'std': '25"'},
      {'item': 'Counter height', 'min': '34"', 'std': '36"'},
      {'item': 'Upper cab height', 'min': '15"', 'std': '18" above counter'},
      {'item': 'Island clearance', 'min': '36"', 'std': '42-48"'},
      {'item': 'Walkway width', 'min': '36"', 'std': '42-48"'},
      {'item': 'Work aisle', 'min': '42"', 'std': '48" (two cooks)'},
      {'item': 'Range to window', 'min': '12"', 'std': 'No curtains'},
      {'item': 'Sink to corner', 'min': '3"', 'std': '18" preferred'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.ruler, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Standard Clearances',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Item', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Min', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Standard', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              ...clearances.map((c) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(c['item']!, style: TextStyle(color: colors.textPrimary, fontSize: 11)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(c['min']!, style: TextStyle(color: colors.accentWarning, fontSize: 11)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(c['std']!, style: TextStyle(color: colors.accentSuccess, fontSize: 11)),
                  ),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }
}
