import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../services/auth_service.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Profile screen - Design System v2.6
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: Text(
          'Account',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? Center(
              child: Text(
                'Not signed in',
                style: TextStyle(color: colors.textSecondary),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildUserCard(colors, user),
                  const SizedBox(height: 32),
                  if (user.isAnonymous) ...[
                    _buildUpgradeSection(colors),
                    const SizedBox(height: 32),
                  ],
                  _buildActionsSection(colors, user),
                  const SizedBox(height: 32),
                  _buildDangerZone(colors),
                ],
              ),
            ),
    );
  }

  Widget _buildUserCard(ZaftoColors colors, ZaftoUser user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              user.isAnonymous ? LucideIcons.user : LucideIcons.userCheck,
              size: 32,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayIdentifier,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: user.isAnonymous
                        ? colors.accentWarning.withValues(alpha: 0.15)
                        : colors.accentSuccess.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    user.isAnonymous ? 'Guest' : 'Verified',
                    style: TextStyle(
                      color: user.isAnonymous
                          ? colors.accentWarning
                          : colors.accentSuccess,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeSection(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.cloud,
            size: 40,
            color: colors.accentPrimary,
          ),
          const SizedBox(height: 16),
          Text(
            'Upgrade Your Account',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create an account to sync your data across devices and never lose your work.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _showUpgradeDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                foregroundColor: colors.isDark ? Colors.black : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(ZaftoColors colors, ZaftoUser user) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          if (!user.isAnonymous)
            _buildActionTile(
              colors: colors,
              icon: LucideIcons.key,
              title: 'Change Password',
              onTap: _showChangePasswordDialog,
            ),
          _buildActionTile(
            colors: colors,
            icon: LucideIcons.settings,
            title: 'Preferences',
            onTap: () {
              // TODO: Navigate to preferences
            },
          ),
          _buildActionTile(
            colors: colors,
            icon: LucideIcons.helpCircle,
            title: 'Help & Support',
            onTap: () {
              // TODO: Navigate to help
            },
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required ZaftoColors colors,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, size: 22, color: colors.textSecondary),
          title: Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Icon(
            LucideIcons.chevronRight,
            size: 20,
            color: colors.textTertiary,
          ),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 56,
            color: colors.borderSubtle,
          ),
      ],
    );
  }

  Widget _buildDangerZone(ZaftoColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(LucideIcons.logOut, size: 22, color: colors.textSecondary),
            title: Text(
              'Sign Out',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: _handleSignOut,
          ),
          Divider(height: 1, indent: 56, color: colors.borderSubtle),
          ListTile(
            leading: Icon(LucideIcons.trash2, size: 22, color: colors.accentError),
            title: Text(
              'Delete Account',
              style: TextStyle(
                color: colors.accentError,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut() async {
    HapticFeedback.mediumImpact();
    final authNotifier = ref.read(authStateProvider.notifier);
    await authNotifier.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _showUpgradeDialog() {
    final colors = ref.read(zaftoColorsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.bgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Create Account',
          style: TextStyle(color: colors.textPrimary),
        ),
        content: Text(
          'This will link your guest data to a new account.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colors.textTertiary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to account creation
            },
            child: Text('Continue', style: TextStyle(color: colors.accentPrimary)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final colors = ref.read(zaftoColorsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.bgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Change Password',
          style: TextStyle(color: colors.textPrimary),
        ),
        content: Text(
          'We\'ll send a password reset link to your email.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colors.textTertiary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authState = ref.read(authStateProvider);
              if (authState.user?.email != null) {
                await ref.read(authStateProvider.notifier)
                    .resetPassword(authState.user!.email!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset email sent')),
                  );
                }
              }
            },
            child: Text('Send Link', style: TextStyle(color: colors.accentPrimary)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final colors = ref.read(zaftoColorsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.bgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Account',
          style: TextStyle(color: colors.accentError),
        ),
        content: Text(
          'This action cannot be undone. All your data will be permanently deleted.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colors.textTertiary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await ref.read(authStateProvider.notifier).deleteAccount();
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: Text('Delete', style: TextStyle(color: colors.accentError)),
          ),
        ],
      ),
    );
  }
}
