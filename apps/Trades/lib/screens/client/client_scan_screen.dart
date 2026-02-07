import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zafto/theme/zafto_colors.dart';
import 'package:zafto/theme/zafto_theme_builder.dart';
import 'package:zafto/widgets/zafto/z_components.dart';

class ClientScanScreen extends ConsumerWidget {
  const ClientScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('Scan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildCameraPreview(colors),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Point at any issue in your home',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Z will identify the problem and suggest next steps',
                style: TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ZButton(
                label: 'Start Scan',
                icon: Icons.camera_alt,
                onPressed: () {},
                isExpanded: true,
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(colors, title: 'RECENT SCANS'),
            _buildEmptyState(colors),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview(ZaftoColors colors) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(ZaftoThemeBuilder.radiusLG),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 56,
            color: colors.textQuaternary,
          ),
          const SizedBox(height: 12),
          Text(
            'Camera preview',
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: colors.textQuaternary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, {required String title}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'SF Pro Text',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: colors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ZaftoColors colors) {
    return ZCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 32,
              color: colors.textQuaternary,
            ),
            const SizedBox(height: 8),
            Text(
              'No recent scans',
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
