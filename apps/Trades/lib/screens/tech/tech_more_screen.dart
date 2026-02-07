import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/zafto_theme_builder.dart';

class TechMoreScreen extends ConsumerWidget {
  const TechMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    const menuItems = <_MenuItem>[
      _MenuItem(
        icon: Icons.receipt_long_outlined,
        title: 'Receipts',
      ),
      _MenuItem(
        icon: Icons.directions_car_outlined,
        title: 'Mileage',
      ),
      _MenuItem(
        icon: Icons.verified_outlined,
        title: 'Certifications',
      ),
      _MenuItem(
        icon: Icons.shield_outlined,
        title: 'Insurance Field Work',
      ),
      _MenuItem(
        icon: Icons.apartment_outlined,
        title: 'Property Maintenance',
      ),
      _MenuItem(
        icon: Icons.person_outline,
        title: 'Profile & Settings',
      ),
    ];

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: const Text('More'),
        backgroundColor: colors.bgBase,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return _buildMenuItem(context, colors, item, index == menuItems.length - 1);
          },
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    ZaftoColors colors,
    _MenuItem item,
    bool isLast,
  ) {
    return Column(
      children: [
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(ZaftoThemeBuilder.radiusMD),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.fillDefault,
                    borderRadius: BorderRadius.circular(
                      ZaftoThemeBuilder.radiusSM,
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: colors.textQuaternary,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 48,
            color: colors.borderSubtle,
          ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;

  const _MenuItem({
    required this.icon,
    required this.title,
  });
}
