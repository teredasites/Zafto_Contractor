/// ZAFTO AI Services
///
/// This file exports all AI-related services and models.
///
/// Usage:
/// ```dart
/// import 'package:zafto/services/ai/ai_services.dart';
/// ```
///
/// Components:
/// - AIConversationService - Main conversation handler with Riverpod
/// - SystemPromptBuilder - Builds context-aware system prompts
/// - AIToolRegistry - Registers and executes AI tools
/// - Conversation models - Message, Conversation, etc.

library ai_services;

export 'ai_conversation_service.dart';
export 'system_prompt_builder.dart';
export 'ai_tools.dart';
