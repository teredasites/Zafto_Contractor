// ZAFTO Z Chat Sheet — Bottom Sheet AI Interface
// Created: Z Intelligence Mobile Integration
//
// DraggableScrollableSheet chat UI opened by the Z FAB button.
// Uses AiService (Supabase Edge Functions) via aiChatProvider.
//
// Features:
// - Draggable sheet (min 0.4, max 0.9, initial 0.6)
// - Message list with user/assistant bubbles
// - Quick action chips (Diagnose, Scan Photo, Find Part, Repair Guide)
// - Photo attach via camera or gallery
// - Typing animation
// - Structured response cards for diagnosis, parts, repair guides

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../services/ai_service.dart';
import '../../theme/theme_provider.dart';
import '../../theme/zafto_colors.dart';
import '../../widgets/error_widgets.dart';
import 'ai_photo_analyzer.dart';

// =============================================================================
// SHOW HELPER
// =============================================================================

/// Show the Z Chat bottom sheet. Call from the Z FAB onPressed.
void showZChatSheet(BuildContext context) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => const ZChatSheet(),
  );
}

// =============================================================================
// Z CHAT SHEET
// =============================================================================

class ZChatSheet extends ConsumerStatefulWidget {
  const ZChatSheet({super.key});

  @override
  ConsumerState<ZChatSheet> createState() => _ZChatSheetState();
}

class _ZChatSheetState extends ConsumerState<ZChatSheet> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const [0.4, 0.6, 0.9],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.bgBase,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(80),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header (non-scrollable)
              _buildHeader(colors, scrollController),
              // Content (scrollable messages + input)
              Expanded(
                child: _buildBody(colors),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader(ZaftoColors colors, ScrollController scrollController) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        // Allow drag on header to resize sheet
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.borderSubtle, width: 0.5),
          ),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colors.textQuaternary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title row
            Row(
              children: [
                // Z mark
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.accentPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Z',
                      style: TextStyle(
                        color: colors.textOnAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Z Intelligence',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                      Text(
                        'Your field assistant',
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Clear chat
                _headerAction(
                  colors,
                  icon: LucideIcons.trash2,
                  tooltip: 'Clear chat',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(aiChatProvider.notifier).clearChat();
                  },
                ),
                // Close
                _headerAction(
                  colors,
                  icon: LucideIcons.x,
                  tooltip: 'Close',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerAction(
    ZaftoColors colors, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18, color: colors.textTertiary),
      onPressed: onTap,
      tooltip: tooltip,
      splashRadius: 18,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }

  // ---------------------------------------------------------------------------
  // BODY (messages + input)
  // ---------------------------------------------------------------------------

  Widget _buildBody(ZaftoColors colors) {
    final chatState = ref.watch(aiChatProvider);

    return Column(
      children: [
        // Messages or empty state
        Expanded(
          child: chatState.messages.isEmpty
              ? _buildEmptyState(colors)
              : _buildMessageList(colors, chatState),
        ),
        // Quick action chips (show when few messages)
        if (chatState.messages.length < 3 && !chatState.isLoading)
          _buildQuickActions(colors),
        // Input area
        _buildInputArea(colors, chatState),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState(ZaftoColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.zap,
              size: 48,
              color: colors.accentPrimary.withAlpha(180),
            ),
            const SizedBox(height: 16),
            Text(
              'How can I help?',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Troubleshoot issues, diagnose photos,\nidentify parts, or get repair guides.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MESSAGE LIST
  // ---------------------------------------------------------------------------

  Widget _buildMessageList(ZaftoColors colors, AiChatState chatState) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == chatState.messages.length && chatState.isLoading) {
          return _buildTypingIndicator(colors);
        }
        return _buildMessageBubble(colors, chatState.messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ZaftoColors colors, AiMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Photo preview for user messages
          if (message.hasPhoto) ...[
            _buildPhotoPreview(colors, message.photoUrl!, isUser),
            const SizedBox(height: 6),
          ],
          // Message bubble or structured card
          if (message.type == AiMessageType.error)
            _buildErrorBubble(colors, message)
          else if (!isUser && message.hasStructuredData)
            _buildStructuredCard(colors, message)
          else
            _buildTextBubble(colors, message, isUser),
        ],
      ),
    );
  }

  Widget _buildTextBubble(
      ZaftoColors colors, AiMessage message, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? colors.accentPrimary : colors.bgElevated,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? colors.textOnAccent : colors.textPrimary,
            fontSize: 15,
            height: 1.45,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBubble(ZaftoColors colors, AiMessage message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.accentError.withAlpha(25),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
          border: Border.all(color: colors.accentError.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.alertTriangle,
                size: 16, color: colors.accentError),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.content,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStructuredCard(ZaftoColors colors, AiMessage message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header with type badge
            _buildCardHeader(colors, message),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                message.content,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            // Structured data fields
            if (message.structuredData != null)
              _buildDataFields(colors, message),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(ZaftoColors colors, AiMessage message) {
    final typeInfo = _getTypeInfo(message.type, colors);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          Icon(typeInfo.icon, size: 14, color: typeInfo.color),
          const SizedBox(width: 6),
          Text(
            typeInfo.label,
            style: TextStyle(
              color: typeInfo.color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataFields(ZaftoColors colors, AiMessage message) {
    final data = message.structuredData!;

    // Filter for displayable fields
    final displayFields = <String, dynamic>{};
    for (final entry in data.entries) {
      if (entry.key == 'content' ||
          entry.key == 'message' ||
          entry.key == 'data') {
        continue;
      }
      if (entry.value is String ||
          entry.value is num ||
          entry.value is bool) {
        displayFields[entry.key] = entry.value;
      }
    }

    if (displayFields.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: displayFields.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    _formatFieldKey(entry.key),
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value.toString(),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPhotoPreview(ZaftoColors colors, String photoUrl, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 160,
          height: 160,
          color: colors.bgElevated,
          child: photoUrl.startsWith('http')
              ? Image.network(photoUrl, fit: BoxFit.cover)
              : Image.file(File(photoUrl), fit: BoxFit.cover),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TYPING INDICATOR
  // ---------------------------------------------------------------------------

  Widget _buildTypingIndicator(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomLeft: const Radius.circular(4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TypingDot(delay: 0, color: colors.textTertiary),
              const SizedBox(width: 4),
              _TypingDot(delay: 150, color: colors.textTertiary),
              const SizedBox(width: 4),
              _TypingDot(delay: 300, color: colors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // QUICK ACTIONS
  // ---------------------------------------------------------------------------

  Widget _buildQuickActions(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip(colors, LucideIcons.search, 'Diagnose Issue',
                _onDiagnoseIssue),
            const SizedBox(width: 8),
            _buildChip(
                colors, LucideIcons.camera, 'Scan Photo', _onScanPhoto),
            const SizedBox(width: 8),
            _buildChip(
                colors, LucideIcons.box, 'Find Part', _onFindPart),
            const SizedBox(width: 8),
            _buildChip(colors, LucideIcons.bookOpen, 'Repair Guide',
                _onRepairGuide),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    ZaftoColors colors,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colors.accentPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INPUT AREA
  // ---------------------------------------------------------------------------

  Widget _buildInputArea(ZaftoColors colors, AiChatState chatState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(
          top: BorderSide(color: colors.borderSubtle, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Attach button
            GestureDetector(
              onTap: _showAttachOptions,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.bgInset,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Icon(
                  LucideIcons.paperclip,
                  size: 18,
                  color: colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Text input
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: colors.bgInset,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _inputController,
                  focusNode: _inputFocusNode,
                  style: TextStyle(color: colors.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Ask Z anything...',
                    hintStyle: TextStyle(color: colors.textTertiary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _onSend(),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Send button
            GestureDetector(
              onTap: chatState.isLoading ? null : _onSend,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: chatState.isLoading
                      ? colors.fillDefault
                      : colors.accentPrimary,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Icon(
                  LucideIcons.arrowUp,
                  size: 18,
                  color: chatState.isLoading
                      ? colors.textTertiary
                      : colors.textOnAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------------------

  void _onSend() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    ref.read(aiChatProvider.notifier).sendMessage(text);
    _inputController.clear();
    _scrollToBottom();
  }

  void _onDiagnoseIssue() {
    _inputController.text = 'I need help diagnosing an issue: ';
    _inputFocusNode.requestFocus();
    // Place cursor at end
    _inputController.selection = TextSelection.fromPosition(
      TextPosition(offset: _inputController.text.length),
    );
  }

  void _onScanPhoto() {
    Navigator.pop(context); // Close sheet
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AiPhotoAnalyzer()),
    );
  }

  void _onFindPart() {
    _inputController.text = 'Help me identify this part: ';
    _inputFocusNode.requestFocus();
    _inputController.selection = TextSelection.fromPosition(
      TextPosition(offset: _inputController.text.length),
    );
  }

  void _onRepairGuide() {
    _inputController.text = 'I need a repair guide for: ';
    _inputFocusNode.requestFocus();
    _inputController.selection = TextSelection.fromPosition(
      TextPosition(offset: _inputController.text.length),
    );
  }

  void _showAttachOptions() {
    HapticFeedback.lightImpact();
    final colors = ref.read(zaftoColorsProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textQuaternary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                _buildAttachOption(
                  colors,
                  icon: LucideIcons.camera,
                  title: 'Camera',
                  subtitle: 'Take a photo of panels, equipment, or issues',
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 8),
                _buildAttachOption(
                  colors,
                  icon: LucideIcons.image,
                  title: 'Gallery',
                  subtitle: 'Choose from your photo library',
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
                _buildAttachOption(
                  colors,
                  icon: LucideIcons.mic,
                  title: 'Voice Note',
                  subtitle: 'Describe the issue verbally',
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    // Voice note — not yet wired
                    showErrorSnackbar(context,
                        message: 'Voice input coming soon.');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachOption(
    ZaftoColors colors, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgBase,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.fillDefault,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: colors.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 18, color: colors.textQuaternary),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image == null) return;
    if (!mounted) return;

    HapticFeedback.lightImpact();

    // Send photo for analysis
    ref
        .read(aiChatProvider.notifier)
        .analyzePhoto(image.path, caption: 'Analyze this photo');
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  _TypeInfo _getTypeInfo(AiMessageType type, ZaftoColors colors) {
    switch (type) {
      case AiMessageType.photoAnalysis:
        return _TypeInfo(
          icon: LucideIcons.scanLine,
          label: 'PHOTO ANALYSIS',
          color: colors.accentInfo,
        );
      case AiMessageType.partIdentification:
        return _TypeInfo(
          icon: LucideIcons.box,
          label: 'PART IDENTIFIED',
          color: colors.accentSuccess,
        );
      case AiMessageType.repairGuide:
        return _TypeInfo(
          icon: LucideIcons.bookOpen,
          label: 'REPAIR GUIDE',
          color: colors.accentWarning,
        );
      case AiMessageType.error:
        return _TypeInfo(
          icon: LucideIcons.alertTriangle,
          label: 'ERROR',
          color: colors.accentError,
        );
      case AiMessageType.text:
        return _TypeInfo(
          icon: LucideIcons.messageSquare,
          label: 'RESPONSE',
          color: colors.textTertiary,
        );
    }
  }

  String _formatFieldKey(String key) {
    // Convert camelCase or snake_case to Title Case
    return key
        .replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m[0]}')
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .map((w) =>
            w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

// =============================================================================
// HELPER CLASS
// =============================================================================

class _TypeInfo {
  final IconData icon;
  final String label;
  final Color color;

  const _TypeInfo({
    required this.icon,
    required this.label,
    required this.color,
  });
}

// =============================================================================
// TYPING DOT ANIMATION
// =============================================================================

class _TypingDot extends StatefulWidget {
  final int delay;
  final Color color;

  const _TypingDot({required this.delay, required this.color});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color.withAlpha((_animation.value * 255).toInt()),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
