import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';

import '../../models/user.dart';
import '../../models/company.dart';
import '../../models/job.dart';
import '../../models/customer.dart';
import '../../models/ai_conversation.dart';
import 'system_prompt_builder.dart';
import 'ai_tools.dart';

/// AI availability status
enum AIStatus {
  available,       // AI is ready
  connecting,      // Connecting to service
  unavailable,     // Service down or not purchased
  rateLimited,     // Too many requests
  error,           // Unknown error
}

/// AI Conversation Service State
class AIConversationState {
  final AIStatus status;
  final Conversation? activeConversation;
  final List<Message> messages;
  final bool isTyping;
  final String? errorMessage;
  final bool hasProSubscription;

  const AIConversationState({
    this.status = AIStatus.available,
    this.activeConversation,
    this.messages = const [],
    this.isTyping = false,
    this.errorMessage,
    this.hasProSubscription = false,
  });

  AIConversationState copyWith({
    AIStatus? status,
    Conversation? activeConversation,
    List<Message>? messages,
    bool? isTyping,
    String? errorMessage,
    bool? hasProSubscription,
  }) {
    return AIConversationState(
      status: status ?? this.status,
      activeConversation: activeConversation ?? this.activeConversation,
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      errorMessage: errorMessage,
      hasProSubscription: hasProSubscription ?? this.hasProSubscription,
    );
  }
}

/// AI Conversation Service
///
/// Handles all AI chat functionality:
/// - Sending messages
/// - Streaming responses
/// - Photo context
/// - Tool execution
/// - Firestore persistence
/// - Graceful degradation
class AIConversationService extends StateNotifier<AIConversationState> {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final AIToolRegistry _toolRegistry;
  final Uuid _uuid;

  // Context
  User? _user;
  Company? _company;
  Job? _currentJob;
  Customer? _currentCustomer;

  AIConversationService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _toolRegistry = AIToolRegistry(),
        _uuid = const Uuid(),
        super(const AIConversationState());

  /// Initialize with user context
  Future<void> initialize({
    required User user,
    required Company company,
    Job? currentJob,
    Customer? currentCustomer,
  }) async {
    _user = user;
    _company = company;
    _currentJob = currentJob;
    _currentCustomer = currentCustomer;

    // Check if user has Pro subscription (AI access)
    final hasPro = await _checkProSubscription();

    state = state.copyWith(
      hasProSubscription: hasPro,
      status: hasPro ? AIStatus.available : AIStatus.unavailable,
    );
  }

  /// Check if user has Pro subscription
  Future<bool> _checkProSubscription() async {
    // For now, assume all users have access for development
    // In production, check company.tier or user subscription
    return true;
  }

  /// Get the personalized assistant name
  String getAssistantName() {
    if (_user == null) return 'Your Assistant';
    final firstName = _user!.displayName.split(' ').first;
    return "$firstName's Assistant";
  }

  /// Start a new conversation
  Future<Conversation> startNewConversation() async {
    if (_user == null || _company == null) {
      throw Exception('Service not initialized');
    }

    final conversationId = _uuid.v4();
    final context = ConversationContext(
      userId: _user!.id,
      companyId: _company!.id,
      roleId: _user!.roleId,
      currentJobId: _currentJob?.id,
      currentCustomerId: _currentCustomer?.id,
      trade: _user!.trades.first,
      necYear: _user!.preferredNecYear,
    );

    final conversation = Conversation.create(
      id: conversationId,
      userId: _user!.id,
      companyId: _company!.id,
      context: context,
    );

    // Save to Firestore
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .set(conversation.toMap());

    state = state.copyWith(
      activeConversation: conversation,
      messages: [],
    );

    return conversation;
  }

  /// Load an existing conversation
  Future<void> loadConversation(String conversationId) async {
    final doc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();

    if (!doc.exists) {
      throw Exception('Conversation not found');
    }

    final conversation = Conversation.fromFirestore(doc);

    // Load messages
    final messagesSnapshot = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .get();

    final messages = messagesSnapshot.docs
        .map((doc) => Message.fromFirestore(doc))
        .toList();

    state = state.copyWith(
      activeConversation: conversation,
      messages: messages,
    );
  }

  /// Send a message
  Future<void> sendMessage({
    required String content,
    List<MessageAttachment>? attachments,
  }) async {
    if (state.activeConversation == null) {
      await startNewConversation();
    }

    if (!state.hasProSubscription) {
      state = state.copyWith(
        status: AIStatus.unavailable,
        errorMessage: 'Upgrade to Pro to use the AI assistant',
      );
      return;
    }

    final conversationId = state.activeConversation!.id;
    final messageId = _uuid.v4();

    // Create user message
    final userMessage = Message.user(
      id: messageId,
      conversationId: conversationId,
      content: content,
      attachments: attachments,
    );

    // Add to local state immediately
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isTyping: true,
    );

    // Save user message to Firestore
    await _saveMessage(userMessage);

    // Update conversation metadata
    await _updateConversationMeta(
      preview: content,
      role: MessageRole.user,
      photoCount: attachments?.where((a) => a.type == AttachmentType.image).length ?? 0,
    );

    // Call AI
    try {
      await _callAI(content, attachments ?? []);
    } catch (e) {
      state = state.copyWith(
        isTyping: false,
        status: AIStatus.error,
        errorMessage: 'Failed to get response. Please try again.',
      );
    }
  }

  /// Call the AI Cloud Function
  Future<void> _callAI(String userMessage, List<MessageAttachment> attachments) async {
    if (_user == null || _company == null) return;

    // Build system prompt with full context
    final systemPrompt = SystemPromptBuilder(
      user: _user!,
      company: _company!,
      currentJob: _currentJob,
      currentCustomer: _currentCustomer,
      conversationContext: state.activeConversation!.context,
    ).build();

    // Prepare messages for API
    final apiMessages = _prepareMessagesForAPI();

    // Add attachments as image content if any
    final hasImages = attachments.any((a) => a.type == AttachmentType.image);

    try {
      final callable = _functions.httpsCallable('chat');
      final result = await callable.call({
        'systemPrompt': systemPrompt,
        'messages': apiMessages,
        'tools': _toolRegistry.getAllForClaude(),
        'hasImages': hasImages,
        'images': attachments
            .where((a) => a.type == AttachmentType.image)
            .map((a) => {
                  'data': a.base64 ?? a.url,
                  'caption': a.caption,
                })
            .toList(),
      });

      final responseData = result.data as Map<String, dynamic>;
      await _processAIResponse(responseData);
    } catch (e) {
      // Graceful degradation - show offline message
      await _handleAIError(e);
    }
  }

  /// Prepare messages for Claude API format
  List<Map<String, dynamic>> _prepareMessagesForAPI() {
    return state.messages.map((m) {
      return {
        'role': m.role == MessageRole.user ? 'user' : 'assistant',
        'content': m.content,
      };
    }).toList();
  }

  /// Process AI response
  Future<void> _processAIResponse(Map<String, dynamic> response) async {
    final content = response['content'] as String? ?? '';
    final toolCalls = response['tool_calls'] as List<dynamic>? ?? [];
    final stopReason = response['stop_reason'] as String?;

    final messageId = _uuid.v4();

    // Parse tool calls
    final parsedToolCalls = toolCalls.map((tc) {
      final tcMap = tc as Map<String, dynamic>;
      return ToolCall(
        id: tcMap['id'] as String,
        name: tcMap['name'] as String,
        arguments: tcMap['input'] as Map<String, dynamic>,
      );
    }).toList();

    // Create assistant message
    var assistantMessage = Message.assistant(
      id: messageId,
      conversationId: state.activeConversation!.id,
      content: content,
      toolCalls: parsedToolCalls,
    );

    // Execute tool calls if any
    if (parsedToolCalls.isNotEmpty) {
      assistantMessage = await _executeToolCalls(assistantMessage);
    }

    // Update state
    state = state.copyWith(
      messages: [...state.messages, assistantMessage],
      isTyping: false,
    );

    // Save to Firestore
    await _saveMessage(assistantMessage);

    // Update conversation metadata
    await _updateConversationMeta(
      preview: content.length > 100 ? '${content.substring(0, 100)}...' : content,
      role: MessageRole.assistant,
    );

    // If there were tool calls, we might need to continue the conversation
    if (stopReason == 'tool_use' && parsedToolCalls.isNotEmpty) {
      // Send tool results back to AI
      await _continueWithToolResults(assistantMessage);
    }
  }

  /// Execute tool calls
  Future<Message> _executeToolCalls(Message message) async {
    final updatedToolCalls = <ToolCall>[];

    for (final toolCall in message.toolCalls) {
      final result = await _toolRegistry.execute(toolCall.name, toolCall.arguments);
      updatedToolCalls.add(toolCall.copyWith(
        result: result,
        isComplete: true,
      ));
    }

    return message.copyWith(toolCalls: updatedToolCalls);
  }

  /// Continue conversation after tool execution
  Future<void> _continueWithToolResults(Message assistantMessage) async {
    // Format tool results and send back to AI
    final toolResultsContent = assistantMessage.toolCalls.map((tc) {
      return 'Tool ${tc.name} result: ${tc.result}';
    }).join('\n\n');

    // Add a synthetic user message with tool results
    // This continues the conversation
    state = state.copyWith(isTyping: true);

    try {
      final callable = _functions.httpsCallable('chat');
      final result = await callable.call({
        'systemPrompt': '',  // Already have context
        'messages': [
          ..._prepareMessagesForAPI(),
          {'role': 'user', 'content': '[Tool results]\n$toolResultsContent'},
        ],
        'tools': _toolRegistry.getAllForClaude(),
      });

      final responseData = result.data as Map<String, dynamic>;
      await _processAIResponse(responseData);
    } catch (e) {
      state = state.copyWith(isTyping: false);
    }
  }

  /// Handle AI errors with graceful degradation
  Future<void> _handleAIError(dynamic error) async {
    String errorMessage;
    AIStatus status;

    if (error.toString().contains('unauthenticated')) {
      errorMessage = 'Please sign in to use the AI assistant';
      status = AIStatus.unavailable;
    } else if (error.toString().contains('rate-limit')) {
      errorMessage = 'Too many requests. Please wait a moment.';
      status = AIStatus.rateLimited;
    } else if (error.toString().contains('network')) {
      errorMessage = 'No internet connection. AI features require connectivity.';
      status = AIStatus.unavailable;
    } else {
      errorMessage = "I'm having trouble connecting. The app still works offline - try the calculators directly.";
      status = AIStatus.error;
    }

    // Add a graceful error message as assistant response
    final errorResponse = Message.assistant(
      id: _uuid.v4(),
      conversationId: state.activeConversation?.id ?? '',
      content: errorMessage,
    );

    state = state.copyWith(
      messages: [...state.messages, errorResponse],
      isTyping: false,
      status: status,
      errorMessage: errorMessage,
    );
  }

  /// Save message to Firestore
  Future<void> _saveMessage(Message message) async {
    await _firestore
        .collection('conversations')
        .doc(message.conversationId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
  }

  /// Update conversation metadata
  Future<void> _updateConversationMeta({
    required String preview,
    required MessageRole role,
    int photoCount = 0,
  }) async {
    if (state.activeConversation == null) return;

    final updates = {
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessagePreview': preview,
      'lastMessageRole': role.name,
      'messageCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (photoCount > 0) {
      updates['photoCount'] = FieldValue.increment(photoCount);
    }

    await _firestore
        .collection('conversations')
        .doc(state.activeConversation!.id)
        .update(updates);
  }

  /// Get recent conversations for the user
  Future<List<Conversation>> getRecentConversations({int limit = 20}) async {
    if (_user == null) return [];

    final snapshot = await _firestore
        .collection('conversations')
        .where('userId', isEqualTo: _user!.id)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => Conversation.fromFirestore(doc)).toList();
  }

  /// Update current job context
  void updateJobContext(Job? job, Customer? customer) {
    _currentJob = job;
    _currentCustomer = customer;
  }

  /// Clear current conversation
  void clearConversation() {
    state = state.copyWith(
      activeConversation: null,
      messages: [],
      isTyping: false,
      errorMessage: null,
    );
  }

  /// Check if AI is available
  bool get isAvailable =>
      state.status == AIStatus.available && state.hasProSubscription;

  /// Get suggested actions based on context
  List<String> getSuggestedActions() {
    final suggestions = <String>[];

    if (_currentJob != null) {
      suggestions.add('What tools do I need for this job?');
      suggestions.add('Check the NEC requirements');
      suggestions.add('Calculate materials needed');
    } else {
      suggestions.add("What's on my schedule today?");
      suggestions.add('Help me with a calculation');
      suggestions.add('Look up an NEC article');
    }

    return suggestions;
  }
}

// =============================================================================
// PROVIDERS
// =============================================================================

final aiConversationServiceProvider =
    StateNotifierProvider<AIConversationService, AIConversationState>((ref) {
  return AIConversationService();
});

/// Provider for the personalized assistant name
final assistantNameProvider = Provider<String>((ref) {
  final service = ref.watch(aiConversationServiceProvider.notifier);
  return service.getAssistantName();
});

/// Provider for AI availability
final aiAvailableProvider = Provider<bool>((ref) {
  final state = ref.watch(aiConversationServiceProvider);
  return state.status == AIStatus.available && state.hasProSubscription;
});

/// Provider for suggested actions
final suggestedActionsProvider = Provider<List<String>>((ref) {
  final service = ref.watch(aiConversationServiceProvider.notifier);
  return service.getSuggestedActions();
});
