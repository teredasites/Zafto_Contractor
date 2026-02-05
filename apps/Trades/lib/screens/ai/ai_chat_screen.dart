import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/ai/ai_conversation_service.dart';
import '../../models/ai_conversation.dart';
import '../../widgets/zafto/zafto_widgets.dart';

// Industrial accent color for AI chat
const Color _industrialOrange = Color(0xFFFF6B00);

/// AI Chat Screen - "[User's Name]'s Assistant"
///
/// Full conversation interface with:
/// - Personalized assistant name
/// - Message history
/// - Photo attachments with context tips
/// - Voice input (future)
/// - Suggested follow-ups
/// - Typing indicator
/// - Graceful offline state
class AIChatScreen extends ConsumerStatefulWidget {
  /// Optional initial message to send
  final String? initialMessage;

  /// Optional conversation ID to resume
  final String? conversationId;

  const AIChatScreen({
    super.key,
    this.initialMessage,
    this.conversationId,
  });

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  List<MessageAttachment> _pendingAttachments = [];
  bool _showContextTip = false;

  @override
  void initState() {
    super.initState();

    // Load conversation or start new
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final service = ref.read(aiConversationServiceProvider.notifier);

      if (widget.conversationId != null) {
        await service.loadConversation(widget.conversationId!);
      }

      // Send initial message if provided
      if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
        _messageController.text = widget.initialMessage!;
        _sendMessage();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final aiState = ref.watch(aiConversationServiceProvider);
    final assistantName = ref.watch(assistantNameProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: _buildAppBar(colors, assistantName),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _buildMessagesList(colors, aiState),
          ),
          // Context tip for photos
          if (_showContextTip) _buildContextTip(colors),
          // Pending attachments
          if (_pendingAttachments.isNotEmpty)
            _buildPendingAttachments(colors),
          // Suggested actions (when empty)
          if (aiState.messages.isEmpty && !aiState.isTyping)
            _buildSuggestedActions(colors),
          // Input area
          _buildInputArea(colors, aiState),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ZaftoColors colors, String assistantName) {
    return AppBar(
      backgroundColor: colors.bgBase,
      elevation: 0,
      toolbarHeight: 60,
      leading: IconButton(
        icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: const ZaftoHazardHeaderCompact(
        height: 32,
        primaryColor: Colors.white,
        stripeColor: Color(0xFFFFD600), // Trades yellow
      ),
      actions: [
        IconButton(
          icon: Icon(LucideIcons.plus, color: colors.textSecondary),
          onPressed: () {
            ref.read(aiConversationServiceProvider.notifier).clearConversation();
          },
          tooltip: 'New conversation',
        ),
        IconButton(
          icon: Icon(LucideIcons.moreVertical, color: colors.textSecondary),
          onPressed: () => _showOptionsSheet(colors),
        ),
      ],
    );
  }

  Widget _buildMessagesList(ZaftoColors colors, AIConversationState state) {
    if (state.messages.isEmpty && !state.isTyping) {
      return _buildEmptyState(colors);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: state.messages.length + (state.isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.messages.length && state.isTyping) {
          return _buildTypingIndicator(colors);
        }
        return _buildMessageBubble(colors, state.messages[index]);
      },
    );
  }

  Widget _buildEmptyState(ZaftoColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Industrial Z Mark with premium styling
            _buildIndustrialZMark(),
            const SizedBox(height: 28),
            const Text(
              'YOUR ENTIRE TRADE.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'ONE CONVERSATION.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFF6B00),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Codes, calculations, diagnostics, estimates.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            // Attachment tips
            _buildAttachmentTip(
              colors,
              LucideIcons.camera,
              'Take a photo of panels, nameplates, or issues',
            ),
            const SizedBox(height: 12),
            _buildAttachmentTip(
              colors,
              LucideIcons.file,
              'Drop files like plans, specs, or documents',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndustrialZMark() {
    // Z mark without container box - just the floating Z
    return SizedBox(
      width: 90,
      height: 90,
      child: CustomPaint(
        painter: _IndustrialZPainter(color: const Color(0xFFFFD600)),
      ),
    );
  }

  Widget _buildAttachmentTip(ZaftoColors colors, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ZaftoColors colors, Message message) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Attachments (photos)
          if (message.attachments.isNotEmpty) ...[
            _buildAttachmentsPreview(colors, message.attachments, isUser),
            const SizedBox(height: 8),
          ],
          // Message bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? colors.accentPrimary : colors.bgElevated,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: isUser ? const Radius.circular(4) : null,
                bottomLeft: !isUser ? const Radius.circular(4) : null,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: isUser ? Colors.black : colors.textPrimary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                // Tool results
                if (message.toolCalls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...message.toolCalls.map((tc) => _buildToolResult(colors, tc)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsPreview(
    ZaftoColors colors,
    List<MessageAttachment> attachments,
    bool isUser,
  ) {
    final images = attachments.where((a) => a.type == AttachmentType.image).toList();
    if (images.isEmpty) return const SizedBox();

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: images.map((img) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 120,
              height: 120,
              color: colors.bgElevated,
              child: img.url != null
                  ? Image.network(img.url!, fit: BoxFit.cover)
                  : img.base64 != null
                      ? const Center(child: Icon(LucideIcons.image))
                      : const Center(child: Icon(LucideIcons.image)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildToolResult(ZaftoColors colors, ToolCall toolCall) {
    if (toolCall.result == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getToolIcon(toolCall.name),
                size: 14,
                color: colors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                _getToolDisplayName(toolCall.name),
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            toolCall.result.toString(),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getToolIcon(String toolName) {
    switch (toolName) {
      case 'run_calculation':
        return LucideIcons.calculator;
      case 'search_nec':
      case 'get_nec_article':
        return LucideIcons.bookOpen;
      case 'get_job_details':
      case 'get_schedule':
        return LucideIcons.clipboardList;
      case 'get_customer_info':
        return LucideIcons.user;
      default:
        return LucideIcons.wrench;
    }
  }

  String _getToolDisplayName(String toolName) {
    switch (toolName) {
      case 'run_calculation':
        return 'Calculation';
      case 'search_nec':
      case 'get_nec_article':
        return 'NEC Lookup';
      case 'get_job_details':
        return 'Job Details';
      case 'get_schedule':
        return 'Schedule';
      case 'get_customer_info':
        return 'Customer';
      default:
        return toolName;
    }
  }

  Widget _buildTypingIndicator(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
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
                _TypingDot(delay: 0, colors: colors),
                const SizedBox(width: 4),
                _TypingDot(delay: 150, colors: colors),
                const SizedBox(width: 4),
                _TypingDot(delay: 300, colors: colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextTip(ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x143B82F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.lightbulb, size: 16, color: Color(0xFF3B82F6)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'The more photos and details you share, the more accurate my help will be.',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showContextTip = false),
            child: Icon(LucideIcons.x, size: 16, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAttachments(ZaftoColors colors) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _pendingAttachments.length,
        itemBuilder: (context, index) {
          final attachment = _pendingAttachments[index];
          return Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: colors.bgElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: attachment.url != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(attachment.url!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(child: Icon(LucideIcons.image)),
              ),
              Positioned(
                top: -4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _pendingAttachments.removeAt(index);
                    });
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: colors.accentError,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.x, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSuggestedActions(ZaftoColors colors) {
    final suggestions = ref.watch(suggestedActionsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((suggestion) {
          return GestureDetector(
            onTap: () {
              _messageController.text = suggestion;
              _sendMessage();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors.bgElevated,
                border: Border.all(color: colors.borderSubtle),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                suggestion,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputArea(ZaftoColors colors, AIConversationState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Attachment button (camera + files)
            GestureDetector(
              onTap: _showAttachmentOptions,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.bgInset,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  LucideIcons.paperclip,
                  size: 18,
                  color: colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Input field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colors.bgInset,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _inputFocusNode,
                  style: TextStyle(color: colors.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Ask anything...',
                    hintStyle: TextStyle(color: colors.textTertiary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  maxLines: 4,
                  minLines: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Send button
            GestureDetector(
              onTap: state.isTyping ? null : _sendMessage,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: state.isTyping
                      ? colors.fillDefault
                      : colors.accentPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  LucideIcons.arrowUp,
                  size: 18,
                  color: state.isTyping ? colors.textTertiary : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) return;

    HapticFeedback.lightImpact();

    final service = ref.read(aiConversationServiceProvider.notifier);
    service.sendMessage(
      content: text,
      attachments: _pendingAttachments.isNotEmpty ? _pendingAttachments : null,
    );

    _messageController.clear();
    setState(() {
      _pendingAttachments = [];
      if (_pendingAttachments.isNotEmpty) {
        _showContextTip = true;
      }
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentOptions() {
    HapticFeedback.lightImpact();
    final colors = ref.read(zaftoColorsProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
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
                _buildAttachmentOption(
                  colors,
                  LucideIcons.camera,
                  'Take Photo',
                  'Capture panels, nameplates, issues',
                  () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 8),
                _buildAttachmentOption(
                  colors,
                  LucideIcons.image,
                  'Photo Library',
                  'Choose from your gallery',
                  () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
                _buildAttachmentOption(
                  colors,
                  LucideIcons.file,
                  'Browse Files',
                  'Plans, specs, documents',
                  () {
                    Navigator.pop(context);
                    _pickFile();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(
    ZaftoColors colors,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
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
            Icon(LucideIcons.chevronRight, size: 18, color: colors.textQuaternary),
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

    setState(() {
      _pendingAttachments.add(
        MessageAttachment.photo(
          id: _uuid.v4(),
          url: image.path,
        ),
      );
    });
  }

  Future<void> _pickFile() async {
    // TODO: Implement file picker using file_picker package
    // For now, show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('File picker coming soon'),
        backgroundColor: ref.read(zaftoColorsProvider).bgElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showOptionsSheet(ZaftoColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                ListTile(
                  leading: Icon(LucideIcons.history, color: colors.textSecondary),
                  title: Text('Conversation History', style: TextStyle(color: colors.textPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to history
                  },
                ),
                ListTile(
                  leading: Icon(LucideIcons.trash2, color: colors.accentError),
                  title: Text('Clear Conversation', style: TextStyle(color: colors.accentError)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(aiConversationServiceProvider.notifier).clearConversation();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Animated typing dot
class _TypingDot extends StatefulWidget {
  final int delay;
  final ZaftoColors colors;

  const _TypingDot({required this.delay, required this.colors});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
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
            color: widget.colors.textTertiary.withOpacity(_animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

/// Paints the industrial Z mark with echo/shadow effect
class _IndustrialZPainter extends CustomPainter {
  final Color color;

  _IndustrialZPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    final margin = size.width * 0.22;
    final strokeWidth = size.width * 0.08;

    Path createZ() {
      return Path()
        ..moveTo(margin, margin)
        ..lineTo(size.width - margin, margin)
        ..lineTo(margin, size.height - margin)
        ..lineTo(size.width - margin, size.height - margin);
    }

    // Glow layer
    paint.color = color.withOpacity(0.2);
    paint.strokeWidth = strokeWidth * 3;
    paint.maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8);
    canvas.drawPath(createZ(), paint);
    paint.maskFilter = null;

    // Shadow echo (offset back)
    paint.color = color.withOpacity(0.15);
    paint.strokeWidth = strokeWidth;
    canvas.save();
    canvas.translate(4, 4);
    canvas.drawPath(createZ(), paint);
    canvas.restore();

    // Middle echo
    paint.color = color.withOpacity(0.35);
    canvas.save();
    canvas.translate(2, 2);
    canvas.drawPath(createZ(), paint);
    canvas.restore();

    // Main Z stroke
    paint.color = color;
    paint.strokeWidth = strokeWidth * 1.2;
    canvas.drawPath(createZ(), paint);

    // Highlight edge
    paint.color = color.withOpacity(0.8);
    paint.strokeWidth = strokeWidth * 0.4;
    canvas.save();
    canvas.translate(-1, -1);
    canvas.drawPath(createZ(), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IndustrialZPainter oldDelegate) =>
      oldDelegate.color != color;
}
