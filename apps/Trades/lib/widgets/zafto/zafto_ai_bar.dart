import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// ZAFTO AI Bar - Design System v2.6 / Phase 0.5
///
/// The AI Bar is the primary input. It replaces the old search bar.
///
/// Structure:
/// ┌─────────────────────────────────────────────────┐
/// │  [AI Icon]  "Ask anything or search..."  [Mic][Cam] │
/// └─────────────────────────────────────────────────┘
///
/// Features:
/// - Blue-purple gradient background
/// - Top glow line effect
/// - Sparkles AI icon
/// - Voice (mic) and Camera action buttons
///
/// Spec: S8_02_5_DESIGN_SPEC_LOCKED.md
///
/// Usage:
/// ```dart
/// ZaftoAIBar(
///   onTap: () => _openAIChat(),
///   onVoiceTap: () => _startVoiceInput(),
///   onCameraTap: () => _openScanner(),
/// )
/// ```

class ZaftoAIBar extends ConsumerWidget {
  /// Callback when the bar is tapped (opens AI chat)
  final VoidCallback? onTap;

  /// Callback when the voice button is tapped
  final VoidCallback? onVoiceTap;

  /// Callback when the camera button is tapped
  final VoidCallback? onCameraTap;

  /// Callback when the bar is long pressed (e.g. opens traditional search)
  final VoidCallback? onLongPress;

  /// Custom placeholder text
  final String placeholder;

  /// Whether to show the voice button
  final bool showVoiceButton;

  /// Whether to show the camera button
  final bool showCameraButton;

  const ZaftoAIBar({
    super.key,
    this.onTap,
    this.onVoiceTap,
    this.onCameraTap,
    this.onLongPress,
    this.placeholder = 'Ask anything or search...',
    this.showVoiceButton = true,
    this.showCameraButton = true,
  });

  // Spec colors
  static const Color _blueAccent = Color(0xFF3B82F6);
  static const Color _purpleAccent = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      onLongPress: onLongPress != null
          ? () {
              HapticFeedback.mediumImpact();
              onLongPress?.call();
            }
          : null,
      child: Container(
        // Spec: margin 20px horizontal
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          // Spec: gradient Blue 12% to Purple 8%
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0x1F3B82F6), // Blue 12%
              Color(0x148B5CF6), // Purple 8%
            ],
          ),
          // Spec: border Blue 25%, 1px
          border: Border.all(
            color: const Color(0x403B82F6), // Blue 25%
            width: 1,
          ),
          // Spec: 16px border radius
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // Top glow line
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Color(0x663B82F6), // Blue 40%
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              // Spec: 16px padding
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // AI Icon container
                  _buildAIIcon(),
                  // Spec: 12px gap
                  const SizedBox(width: 12),
                  // Placeholder text
                  Expanded(
                    child: Text(
                      placeholder,
                      // Spec: 14px, text.secondary
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  // Action buttons
                  if (showVoiceButton || showCameraButton) ...[
                    // Spec: 12px gap
                    const SizedBox(width: 12),
                    _buildActionButtons(colors),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIIcon() {
    return Container(
      // Spec: 36x36px, rounded 10px
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        // Spec: gradient #3B82F6 to #8B5CF6
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_blueAccent, _purpleAccent],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        // Spec: sparkles icon, 20px, white
        child: Icon(
          LucideIcons.sparkles,
          size: 20,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildActionButtons(ZaftoColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showVoiceButton)
          _ActionButton(
            icon: LucideIcons.mic,
            onTap: onVoiceTap,
            colors: colors,
          ),
        if (showVoiceButton && showCameraButton)
          const SizedBox(width: 8),
        if (showCameraButton)
          _ActionButton(
            icon: LucideIcons.camera,
            onTap: onCameraTap,
            colors: colors,
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final ZaftoColors colors;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        // Spec: 32x32px, rounded 8px
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          // Spec: rgba(255,255,255,0.08)
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          // Spec: 16px icon, text.secondary
          child: Icon(
            icon,
            size: 16,
            color: colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Expanded AI Bar for the chat input at bottom of AI screen
///
/// Usage:
/// ```dart
/// ZaftoAIBarInput(
///   controller: _messageController,
///   onSend: () => _sendMessage(),
///   onVoiceTap: () => _startVoiceInput(),
/// )
/// ```
class ZaftoAIBarInput extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onSend;
  final VoidCallback? onVoiceTap;
  final VoidCallback? onCameraTap;
  final String placeholder;
  final FocusNode? focusNode;

  const ZaftoAIBarInput({
    super.key,
    required this.controller,
    this.onSend,
    this.onVoiceTap,
    this.onCameraTap,
    this.placeholder = 'Ask anything...',
    this.focusNode,
  });

  @override
  ConsumerState<ZaftoAIBarInput> createState() => _ZaftoAIBarInputState();
}

class _ZaftoAIBarInputState extends ConsumerState<ZaftoAIBarInput> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x1F3B82F6),
            Color(0x148B5CF6),
          ],
        ),
        border: Border.all(
          color: const Color(0x403B82F6),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Top glow line
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color(0x663B82F6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // AI Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF3B82F6),
                        Color(0xFF8B5CF6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.sparkles,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Text input
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.textPrimary,
                    ),
                    decoration: InputDecoration.collapsed(
                      hintText: widget.placeholder,
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: colors.textSecondary,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => widget.onSend?.call(),
                    maxLines: 4,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                // Action buttons
                if (!_hasText) ...[
                  if (widget.onVoiceTap != null)
                    _ActionButton(
                      icon: LucideIcons.mic,
                      onTap: widget.onVoiceTap,
                      colors: colors,
                    ),
                  if (widget.onVoiceTap != null && widget.onCameraTap != null)
                    const SizedBox(width: 8),
                  if (widget.onCameraTap != null)
                    _ActionButton(
                      icon: LucideIcons.camera,
                      onTap: widget.onCameraTap,
                      colors: colors,
                    ),
                ] else ...[
                  // Send button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onSend?.call();
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.accentPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          LucideIcons.arrowUp,
                          size: 16,
                          color: colors.isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
