import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/core/user_role.dart';
import 'package:zafto/core/role_provider.dart';
import 'package:zafto/navigation/app_shell.dart';
import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/zafto_theme_builder.dart';

class RoleSwitcherScreen extends ConsumerWidget {
  const RoleSwitcherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;
    final currentRole = ref.watch(currentRoleProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'ZAFTO',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Select your role to continue',
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: colors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'BUSINESS ROLES',
                style: TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: colors.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              _buildRoleTile(context, colors, UserRole.owner, currentRole, ref),
              _buildRoleTile(context, colors, UserRole.admin, currentRole, ref),
              _buildRoleTile(context, colors, UserRole.office, currentRole, ref),
              const SizedBox(height: 16),
              Text(
                'FIELD ROLES',
                style: TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: colors.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              _buildRoleTile(context, colors, UserRole.tech, currentRole, ref),
              _buildRoleTile(context, colors, UserRole.inspector, currentRole, ref),
              const SizedBox(height: 16),
              Text(
                'FINANCE & EXTERNAL',
                style: TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: colors.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              _buildRoleTile(context, colors, UserRole.cpa, currentRole, ref),
              _buildRoleTile(context, colors, UserRole.client, currentRole, ref),
              _buildRoleTile(context, colors, UserRole.tenant, currentRole, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTile(
    BuildContext context,
    ZaftoColors colors,
    UserRole role,
    UserRole currentRole,
    WidgetRef ref,
  ) {
    final isSelected = role == currentRole;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(currentRoleProvider.notifier).state = role;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AppShell(role: role)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary.withValues(alpha: 0.08) : colors.bgElevated,
          borderRadius: BorderRadius.circular(ZaftoThemeBuilder.radiusMD),
          border: Border.all(
            color: isSelected ? colors.accentPrimary.withValues(alpha: 0.3) : colors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.accentPrimary.withValues(alpha: 0.15)
                    : colors.bgInset,
                borderRadius: BorderRadius.circular(ZaftoThemeBuilder.radiusSM),
              ),
              child: Icon(
                _iconForRole(role),
                size: 20,
                color: isSelected ? colors.accentPrimary : colors.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.label,
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? colors.accentPrimary : colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _descriptionForRole(role),
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colors.accentPrimary, size: 20),
          ],
        ),
      ),
    );
  }

  IconData _iconForRole(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return Icons.star_outline;
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
      case UserRole.office:
        return Icons.desk_outlined;
      case UserRole.tech:
        return Icons.build_outlined;
      case UserRole.inspector:
        return Icons.checklist_outlined;
      case UserRole.cpa:
        return Icons.calculate_outlined;
      case UserRole.client:
        return Icons.home_outlined;
      case UserRole.tenant:
        return Icons.apartment_outlined;
    }
  }

  String _descriptionForRole(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'Full business control';
      case UserRole.admin:
        return 'Manage team and operations';
      case UserRole.office:
        return 'Schedule, customers, invoicing';
      case UserRole.tech:
        return 'Field work and job tracking';
      case UserRole.inspector:
        return 'Inspections and compliance';
      case UserRole.cpa:
        return 'Financial oversight and reports';
      case UserRole.client:
        return 'Track projects and payments';
      case UserRole.tenant:
        return 'Rent, maintenance, and unit info';
    }
  }
}
