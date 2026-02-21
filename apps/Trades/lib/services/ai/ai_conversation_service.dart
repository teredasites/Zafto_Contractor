import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    this.status = AIStatus.unavailable,
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

/// AI Conversation Service — STUBBED
///
/// Phase E (AI) is PAUSED. Firebase Cloud Functions removed in S151.
/// When AI is re-enabled, this service will call Supabase Edge Functions
/// instead of Firebase Cloud Functions.
class AIConversationService extends StateNotifier<AIConversationState> {
  final AIToolRegistry _toolRegistry;
  final Uuid _uuid;

  // Context
  User? _user;
  Company? _company;
  Job? _currentJob;
  Customer? _currentCustomer;

  AIConversationService()
      : _toolRegistry = AIToolRegistry(),
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

    // AI features are not yet available — Phase E is paused.
    state = state.copyWith(
      hasProSubscription: false,
      status: AIStatus.unavailable,
    );
  }

  /// Get the personalized assistant name
  String getAssistantName() {
    if (_user == null) return 'Your Assistant';
    final firstName = _user!.displayName.split(' ').first;
    return "$firstName's Assistant";
  }

  /// Start a new conversation — STUBBED (Phase E paused)
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

    // TODO: Save to Supabase when Phase E resumes

    state = state.copyWith(
      activeConversation: conversation,
      messages: [],
    );

    return conversation;
  }

  /// Load an existing conversation — STUBBED
  Future<void> loadConversation(String conversationId) async {
    // TODO: Load from Supabase when Phase E resumes
    throw Exception('AI features not yet available');
  }

  /// Send a message — STUBBED
  Future<void> sendMessage({
    required String content,
    List<MessageAttachment>? attachments,
  }) async {
    state = state.copyWith(
      status: AIStatus.unavailable,
      errorMessage: 'AI features are coming soon. Upgrade to Pro when available.',
    );
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
  bool get isAvailable => false; // Phase E paused

  /// Get recent conversations — STUBBED
  Future<List<Conversation>> getRecentConversations({int limit = 20}) async {
    return []; // Phase E paused
  }

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
  return false; // Phase E paused — AI not available
});

/// Provider for suggested actions
final suggestedActionsProvider = Provider<List<String>>((ref) {
  final service = ref.watch(aiConversationServiceProvider.notifier);
  return service.getSuggestedActions();
});
