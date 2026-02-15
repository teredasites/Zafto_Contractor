import 'package:flutter/material.dart';

import 'matrix_rain_painter.dart';

/// Clean Brand Header — matches CRM portal style
///
/// Reusable across all role home screens with customizable subtitle.
class CleanBrandHeader extends StatelessWidget {
  final String subtitle;

  const CleanBrandHeader({
    super.key,
    this.subtitle = 'CONTRACTOR',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'ZAFTO',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: brandAmber,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }
}
