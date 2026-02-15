# ZAFTO AI INTEGRATION SPEC
## Complete Architecture for Plug-and-Play AI
### February 3, 2026

---

## THE CORE PRINCIPLE

**Everything goes through ONE service. Not a million pieces.**

```
                    ┌─────────────────────────────────────────┐
                    │           ZaftoAIService                │
                    │     (Single Entry Point for ALL AI)     │
                    └─────────────────────────────────────────┘
                                       │
         ┌─────────────────────────────┼─────────────────────────────┐
         │                             │                             │
         ▼                             ▼                             ▼
   ┌───────────┐               ┌───────────┐               ┌───────────┐
   │  Mobile   │               │    Web    │               │  Backend  │
   │    App    │               │  Portal   │               │ Functions │
   └───────────┘               └───────────┘               └───────────┘

Every AI interaction uses ZaftoAIService.chat()
Every tool call goes through the same executor
Every permission check uses the same policy handler
```

---

## DATA ARCHITECTURE

### Thread Model (Firestore)

```
companies/{companyId}/aiThreads/{threadId}
├── id: string
├── title: string                    // Auto-generated or user-set
├── createdAt: timestamp
├── lastMessageAt: timestamp
├── messageCount: number
├── tokenCount: number               // Track API usage
│
├── linkedEntity: {                  // Optional - links to business object
│   type: "job" | "customer" | "bid" | "invoice" | "general"
│   id: string
│   name: string
│   }
│
├── summary: string                  // Auto-generated when >20 messages
├── summarizedAt: timestamp          // When summary was created
│
└── messages: [                      // Last 50 messages (older summarized)
    {
      id: string
      role: "user" | "assistant" | "system"
      content: string
      timestamp: timestamp
      tokensUsed: number
      toolCalls: [...]               // If AI called tools
      toolResults: [...]             // Results of tool calls
    }
  ]
```

### Audit Log Model (Firestore)

```
companies/{companyId}/aiAuditLogs/{logId}
├── id: string
├── threadId: string
├── userId: string
├── timestamp: timestamp
│
├── action: {
│   type: "create" | "update" | "delete" | "send" | "calculate"
│   resource: "job" | "invoice" | "bid" | "customer" | "document"
│   resourceId: string
│   }
│
├── tier: "GREEN" | "YELLOW" | "RED"  // What level was this
├── userConfirmed: boolean            // Did user confirm (YELLOW/RED)
│
├── previousState: {...}              // For undo capability
├── newState: {...}                   // After action
│
└── reversible: boolean               // Can this be undone
```

### Soft Delete Model (All Collections)

```
// Every document that can be "deleted" gets these fields:
{
  // ... existing fields ...

  deletedAt: timestamp | null         // null = active, timestamp = deleted
  deletedBy: string | null            // userId who deleted
  deletedByAI: boolean                // Was this deleted by AI assistant

  // Soft deleted items:
  // - Hidden from normal queries
  // - Visible in Trash
  // - Restorable for 30 days
  // - Auto-purged after 30 days (Cloud Function)
}
```

### Trash Collection (Per Company)

```
companies/{companyId}/trash/{trashId}
├── id: string
├── originalCollection: string        // "jobs", "invoices", etc.
├── originalId: string
├── deletedAt: timestamp
├── deletedBy: string
├── expiresAt: timestamp              // deletedAt + 30 days
├── data: {...}                       // Full document snapshot
└── restorable: boolean
```

---

## ACTION TIER SYSTEM

### Tier Definitions

| Tier | Color | Actions | UX |
|:----:|:-----:|---------|-----|
| **GREEN** | Safe | Read, search, calculate, answer | Auto-execute, no confirmation |
| **YELLOW** | Caution | Create, edit jobs/invoices/bids/customers | Preview + [Confirm] [Cancel] |
| **RED** | Danger | Delete, send invoice, process payment | Warning modal, explicit confirm |
| **NEVER** | Blocked | Cross-company access, auth changes, raw DB | Hard block, not even shown to AI |

### Action Classification

```dart
// lib/ai/action_tiers.dart

enum ActionTier { green, yellow, red, never }

class ActionTierClassifier {
  static final Map<String, Map<String, ActionTier>> tiers = {
    // GREEN - Read operations
    'job': {
      'get': ActionTier.green,
      'list': ActionTier.green,
      'search': ActionTier.green,
      'create': ActionTier.yellow,
      'update': ActionTier.yellow,
      'delete': ActionTier.red,
    },
    'invoice': {
      'get': ActionTier.green,
      'list': ActionTier.green,
      'search': ActionTier.green,
      'create': ActionTier.yellow,
      'update': ActionTier.yellow,
      'delete': ActionTier.red,
      'send': ActionTier.red,           // Sends to customer!
      'markPaid': ActionTier.yellow,
    },
    'bid': {
      'get': ActionTier.green,
      'list': ActionTier.green,
      'create': ActionTier.yellow,
      'update': ActionTier.yellow,
      'delete': ActionTier.red,
      'send': ActionTier.red,           // Sends to customer!
      'convertToJob': ActionTier.yellow,
    },
    'customer': {
      'get': ActionTier.green,
      'list': ActionTier.green,
      'search': ActionTier.green,
      'create': ActionTier.yellow,
      'update': ActionTier.yellow,
      'delete': ActionTier.red,
    },
    'document': {
      'get': ActionTier.green,
      'create': ActionTier.yellow,
      'update': ActionTier.yellow,
      'delete': ActionTier.red,
    },
    'calculator': {
      'execute': ActionTier.green,      // Always safe
      'explain': ActionTier.green,
    },
    'settings': {
      'get': ActionTier.green,
      'update': ActionTier.never,       // NEVER let AI change settings
    },
    'payment': {
      '*': ActionTier.never,            // NEVER let AI touch payments
    },
    'auth': {
      '*': ActionTier.never,            // NEVER let AI touch auth
    },
  };

  static ActionTier classify(String resource, String action) {
    final resourceTiers = tiers[resource];
    if (resourceTiers == null) return ActionTier.never;

    // Check for wildcard block
    if (resourceTiers['*'] == ActionTier.never) return ActionTier.never;

    return resourceTiers[action] ?? ActionTier.never;
  }
}
```

### Confirmation UI

```dart
// lib/widgets/ai/action_confirmation.dart

class AIActionConfirmation extends StatelessWidget {
  final ActionTier tier;
  final String action;
  final String description;
  final Map<String, dynamic> preview;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    if (tier == ActionTier.green) {
      // Auto-execute, no UI
      onConfirm();
      return const SizedBox.shrink();
    }

    if (tier == ActionTier.yellow) {
      // Soft confirm - inline preview
      return _buildYellowConfirmation();
    }

    if (tier == ActionTier.red) {
      // Hard confirm - modal with warning
      return _buildRedConfirmation();
    }

    // Never tier - should not reach here
    return const SizedBox.shrink();
  }

  Widget _buildYellowConfirmation() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZaftoColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ZaftoColors.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertCircle, color: ZaftoColors.warning),
              SizedBox(width: 8),
              Text('Confirm Action', style: ZaftoTypography.subtitle),
            ],
          ),
          SizedBox(height: 12),
          Text(description),
          SizedBox(height: 12),
          // Preview of what will happen
          _buildPreview(),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onCancel, child: Text('Cancel')),
              SizedBox(width: 8),
              ElevatedButton(onPressed: onConfirm, child: Text('Confirm')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRedConfirmation() {
    // Shows as modal dialog with explicit warning
    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.alertTriangle, color: ZaftoColors.error),
          SizedBox(width: 8),
          Text('Are you sure?'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(description, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Text('This action cannot be easily undone.'),
          // For delete: mention it goes to trash for 30 days
          if (action == 'delete')
            Text('(Will be moved to Trash for 30 days)'),
        ],
      ),
      actions: [
        TextButton(onPressed: onCancel, child: Text('Cancel')),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(backgroundColor: ZaftoColors.error),
          child: Text('Yes, $action'),
        ),
      ],
    );
  }
}
```

---

## CONTEXT INJECTION SYSTEM

### What Gets Injected (Always)

```dart
// lib/ai/context_builder.dart

class AIContextBuilder {

  /// Always injected - small, static context (~500 tokens)
  static Map<String, dynamic> buildBaseContext(Company company, User user) {
    return {
      'company': {
        'name': company.name,
        'trade': company.primaryTrade,
        'state': company.state,
        'tier': company.subscriptionTier,
      },
      'user': {
        'name': user.displayName,
        'role': user.role,
      },
      'quickStats': {
        'activeJobs': company.activeJobCount,
        'pendingInvoices': company.pendingInvoiceCount,
        'unpaidAmount': company.unpaidInvoiceTotal,
        'todaySchedule': company.todayJobCount,
      },
      'today': DateTime.now().toIso8601String(),
    };
  }

  /// Thread context - only if continuing a thread
  static Map<String, dynamic> buildThreadContext(AIThread thread) {
    return {
      'threadTitle': thread.title,
      'summary': thread.summary,              // If exists
      'recentMessages': thread.messages       // Last 10
          .takeLast(10)
          .map((m) => {'role': m.role, 'content': m.content})
          .toList(),
      'linkedEntity': thread.linkedEntity,    // What this thread is about
    };
  }

  /// Entity context - fetched on demand based on linked entity
  static Future<Map<String, dynamic>> buildEntityContext(
    LinkedEntity? entity,
  ) async {
    if (entity == null) return {};

    switch (entity.type) {
      case 'job':
        final job = await JobService.get(entity.id);
        return {
          'job': {
            'id': job.id,
            'title': job.title,
            'customer': job.customerName,
            'address': job.address,
            'status': job.status,
            'scheduledDate': job.scheduledStart,
            'lineItems': job.lineItems,
            'notes': job.notes,
          }
        };
      case 'customer':
        final customer = await CustomerService.get(entity.id);
        return {
          'customer': {
            'id': customer.id,
            'name': customer.name,
            'phone': customer.phone,
            'email': customer.email,
            'address': customer.address,
            'recentJobs': customer.recentJobs.take(5).toList(),
          }
        };
      // ... similar for bid, invoice
      default:
        return {};
    }
  }

  /// On-demand context - fetched based on what user is asking about
  static Future<Map<String, dynamic>> buildQueryContext(
    String userMessage,
    Company company,
  ) async {
    final context = <String, dynamic>{};

    // Detect mentions and fetch relevant data

    // Job mentions: "#123", "job 123", "the Smith job"
    final jobMentions = _detectJobMentions(userMessage);
    if (jobMentions.isNotEmpty) {
      context['mentionedJobs'] = await Future.wait(
        jobMentions.map((id) => JobService.get(id)),
      );
    }

    // Customer mentions: "@Smith", "customer Smith"
    final customerMentions = _detectCustomerMentions(userMessage);
    if (customerMentions.isNotEmpty) {
      context['mentionedCustomers'] = await CustomerService.search(
        customerMentions.first,
        limit: 3,
      );
    }

    // Date mentions: "this week", "Friday", "tomorrow"
    final dateRange = _detectDateRange(userMessage);
    if (dateRange != null) {
      context['scheduleForDateRange'] = await CalendarService.getRange(
        dateRange.start,
        dateRange.end,
      );
    }

    // Invoice mentions: "unpaid invoices", "invoice #456"
    if (_mentionsInvoices(userMessage)) {
      context['invoiceSummary'] = await InvoiceService.getSummary(company.id);
    }

    // Price/material/bid mentions - ALWAYS include Price Book
    if (_mentionsPricing(userMessage)) {
      context['priceBook'] = await PriceBookService.getRelevantItems(
        companyId: company.id,
        query: userMessage,
        limit: 20,
      );
    }

    return context;
  }

  /// Detect if user is asking about pricing, materials, estimates, bids
  static bool _mentionsPricing(String message) {
    final pricingKeywords = [
      'price', 'cost', 'estimate', 'bid', 'quote', 'material',
      'how much', 'what would', 'parts', 'supplies', 'markup',
    ];
    final lower = message.toLowerCase();
    return pricingKeywords.any((k) => lower.contains(k));
  }
}

---

## PRICE BOOK AI INTEGRATION

### Rule: Never Make Up Prices

AI must ALWAYS use company's Price Book when discussing pricing.

```dart
// lib/ai/tools/price_book_tools.dart

final priceBookTools = [
  Tool(
    name: 'price_book_search',
    description: 'Search company Price Book for material pricing. ALWAYS use this for pricing questions.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'query': {'type': 'string', 'description': 'Material to search for'},
        'category': {'type': 'string', 'description': 'Optional category filter'},
        'trade': {'type': 'string', 'description': 'Optional trade filter'},
      },
      'required': ['query'],
    },
  ),
  Tool(
    name: 'price_book_add',
    description: 'Add item to Price Book (requires user confirmation)',
    inputSchema: {
      'type': 'object',
      'properties': {
        'name': {'type': 'string'},
        'description': {'type': 'string'},
        'category': {'type': 'string'},
        'suggestedCost': {'type': 'number', 'description': 'Suggested cost (user confirms)'},
        'unit': {'type': 'string'},
      },
      'required': ['name', 'category'],
    },
  ),
];
```

### AI Behavior Examples

**Good (uses Price Book):**
```
User: "What would materials cost for a 200A panel upgrade?"

AI: [Searches Price Book]

"Based on your Price Book:
- 200A Main Breaker Panel: $285.00
- 200A Main Breaker: $89.00
- #2/0 Copper (per ft): $4.50 × 20ft = $90.00
- Ground rods (2): $12.00 × 2 = $24.00

Subtotal: $488.00

Note: 3 items not in your Price Book:
- Grounding electrode conductor
- Panel cover screws
- Weather head

Want me to add these items?"
```

**Bad (never do this):**
```
User: "What would materials cost for a 200A panel upgrade?"

AI: "A 200A panel upgrade typically costs around $400-600 in materials..."
❌ NO - Never estimate without Price Book
```

### System Prompt Addition

```
PRICING RULES:
- ALWAYS search Price Book before discussing costs
- Use ONLY the company's actual prices
- If item not in Price Book, say "not in your Price Book" and offer to add
- Never estimate or guess prices
- Never use "typical" or "average" prices
```

### Full Context Assembly

```dart
// What gets sent to Claude API

Future<String> buildFullPrompt(
  String userMessage,
  AIThread? thread,
  Company company,
  User user,
) async {
  // 1. System prompt (personality, capabilities) - ~300 tokens
  final systemPrompt = _buildSystemPrompt(company.primaryTrade);

  // 2. Base context (always) - ~200 tokens
  final baseContext = AIContextBuilder.buildBaseContext(company, user);

  // 3. Thread context (if continuing) - ~500 tokens
  final threadContext = thread != null
      ? AIContextBuilder.buildThreadContext(thread)
      : {};

  // 4. Entity context (if linked) - ~300 tokens
  final entityContext = await AIContextBuilder.buildEntityContext(
    thread?.linkedEntity,
  );

  // 5. Query context (on-demand) - ~500 tokens
  final queryContext = await AIContextBuilder.buildQueryContext(
    userMessage,
    company,
  );

  // Total: ~1800 tokens input context (well under limits)

  return '''
$systemPrompt

CONTEXT:
${jsonEncode({
    ...baseContext,
    ...threadContext,
    ...entityContext,
    ...queryContext,
  })}

USER: $userMessage
''';
}
```

---

## THREAD MANAGEMENT

### Creating Threads

```dart
// lib/services/ai_thread_service.dart

class AIThreadService {
  final FirebaseFirestore _db;

  /// Start a new conversation
  Future<AIThread> createThread({
    required String companyId,
    required String userId,
    LinkedEntity? linkedEntity,
    String? initialTitle,
  }) async {
    final thread = AIThread(
      id: _db.collection('companies/$companyId/aiThreads').doc().id,
      title: initialTitle ?? _generateTitle(linkedEntity),
      linkedEntity: linkedEntity,
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
      messageCount: 0,
      messages: [],
    );

    await _db
        .collection('companies/$companyId/aiThreads')
        .doc(thread.id)
        .set(thread.toJson());

    return thread;
  }

  /// Get or create thread for an entity
  /// (If user asks AI about a job, reuse existing thread for that job)
  Future<AIThread> getOrCreateForEntity({
    required String companyId,
    required String userId,
    required LinkedEntity entity,
  }) async {
    // Check for existing thread for this entity
    final existing = await _db
        .collection('companies/$companyId/aiThreads')
        .where('linkedEntity.type', isEqualTo: entity.type)
        .where('linkedEntity.id', isEqualTo: entity.id)
        .orderBy('lastMessageAt', descending: true)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return AIThread.fromJson(existing.docs.first.data());
    }

    // Create new thread for this entity
    return createThread(
      companyId: companyId,
      userId: userId,
      linkedEntity: entity,
    );
  }

  String _generateTitle(LinkedEntity? entity) {
    if (entity == null) return 'New Conversation';
    switch (entity.type) {
      case 'job':
        return 'Questions about ${entity.name}';
      case 'customer':
        return '${entity.name} - Discussion';
      case 'bid':
        return 'Bid: ${entity.name}';
      case 'invoice':
        return 'Invoice: ${entity.name}';
      default:
        return 'New Conversation';
    }
  }
}
```

### Auto-Summarization

```typescript
// firebase/functions/src/aiThreadSummarizer.ts

import * as functions from 'firebase-functions';
import Anthropic from '@anthropic-ai/sdk';

export const summarizeThread = functions.firestore
  .document('companies/{companyId}/aiThreads/{threadId}')
  .onUpdate(async (change, context) => {
    const thread = change.after.data();
    const before = change.before.data();

    // Only run if message count crossed threshold
    if (thread.messageCount <= 20 || before.messageCount > 20) {
      return;
    }

    // Don't re-summarize if already done
    if (thread.summarizedAt) {
      return;
    }

    const anthropic = new Anthropic();

    // Get messages to summarize (all except last 10)
    const messagesToSummarize = thread.messages.slice(0, -10);

    const summary = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 500,
      messages: [{
        role: 'user',
        content: `Summarize this conversation in 2-3 sentences. Focus on:
- What the user asked about
- Key decisions or information shared
- Any actions taken

Conversation:
${messagesToSummarize.map(m => `${m.role}: ${m.content}`).join('\n')}`,
      }],
    });

    // Update thread with summary, keep only last 10 messages
    await change.after.ref.update({
      summary: summary.content[0].text,
      summarizedAt: Date.now(),
      messages: thread.messages.slice(-10),
    });
  });
```

---

## THE UNIFIED AI SERVICE

```dart
// lib/services/zafto_ai_service.dart

/// THE SINGLE ENTRY POINT FOR ALL AI INTERACTIONS
class ZaftoAIService {
  final Anthropic _anthropic;
  final AIThreadService _threadService;
  final AIContextBuilder _contextBuilder;
  final ToolExecutor _toolExecutor;
  final AuditLogger _auditLogger;

  /// Main chat method - everything goes through here
  Future<AIResponse> chat({
    required String message,
    required String companyId,
    required String userId,
    String? threadId,
    LinkedEntity? linkedEntity,
  }) async {
    // 1. Get or create thread
    final thread = threadId != null
        ? await _threadService.getThread(companyId, threadId)
        : linkedEntity != null
            ? await _threadService.getOrCreateForEntity(
                companyId: companyId,
                userId: userId,
                entity: linkedEntity,
              )
            : await _threadService.createThread(
                companyId: companyId,
                userId: userId,
              );

    // 2. Build full context
    final company = await CompanyService.get(companyId);
    final user = await UserService.get(userId);
    final fullContext = await _contextBuilder.buildFullContext(
      message: message,
      thread: thread,
      company: company,
      user: user,
    );

    // 3. Call Claude with tools
    final response = await _anthropic.messages.create(
      model: 'claude-sonnet-4-20250514',
      maxTokens: 4096,
      system: fullContext.systemPrompt,
      messages: fullContext.messages,
      tools: _getToolsForUser(user, company),
    );

    // 4. Process tool calls if any
    final processedResponse = await _processToolCalls(
      response: response,
      company: company,
      user: user,
      thread: thread,
    );

    // 5. Save message to thread
    await _threadService.addMessage(
      companyId: companyId,
      threadId: thread.id,
      userMessage: message,
      assistantResponse: processedResponse,
    );

    // 6. Return response
    return AIResponse(
      threadId: thread.id,
      message: processedResponse.text,
      pendingActions: processedResponse.pendingActions,
      executedActions: processedResponse.executedActions,
    );
  }

  /// Process tool calls with action tier checking
  Future<ProcessedResponse> _processToolCalls({
    required MessageResponse response,
    required Company company,
    required User user,
    required AIThread thread,
  }) async {
    final pendingActions = <PendingAction>[];
    final executedActions = <ExecutedAction>[];

    for (final block in response.content) {
      if (block is! ToolUseBlock) continue;

      final toolName = block.name;
      final input = block.input;

      // Parse resource and action from tool name
      final (resource, action) = _parseToolName(toolName);

      // Get action tier
      final tier = ActionTierClassifier.classify(resource, action);

      if (tier == ActionTier.never) {
        // Block completely
        continue;
      }

      if (tier == ActionTier.green) {
        // Auto-execute
        final result = await _toolExecutor.execute(
          toolName: toolName,
          input: input,
          companyId: company.id,
          userId: user.id,
        );
        executedActions.add(ExecutedAction(
          toolName: toolName,
          input: input,
          result: result,
          tier: tier,
        ));

        // Log it
        await _auditLogger.log(
          companyId: company.id,
          userId: user.id,
          threadId: thread.id,
          action: action,
          resource: resource,
          resourceId: input['id'],
          tier: tier,
          userConfirmed: false, // Auto-executed
        );
      } else {
        // YELLOW or RED - needs confirmation
        // Return as pending action for UI to handle
        final preview = await _toolExecutor.preview(
          toolName: toolName,
          input: input,
          companyId: company.id,
        );

        pendingActions.add(PendingAction(
          id: Uuid().v4(),
          toolName: toolName,
          input: input,
          tier: tier,
          preview: preview,
          description: _describeAction(toolName, input),
        ));
      }
    }

    return ProcessedResponse(
      text: _extractText(response),
      pendingActions: pendingActions,
      executedActions: executedActions,
    );
  }

  /// Confirm and execute a pending action
  Future<ExecutedAction> confirmAction({
    required String companyId,
    required String userId,
    required String threadId,
    required PendingAction action,
  }) async {
    final result = await _toolExecutor.execute(
      toolName: action.toolName,
      input: action.input,
      companyId: companyId,
      userId: userId,
    );

    // Log with confirmation
    await _auditLogger.log(
      companyId: companyId,
      userId: userId,
      threadId: threadId,
      action: _parseAction(action.toolName),
      resource: _parseResource(action.toolName),
      resourceId: action.input['id'],
      tier: action.tier,
      userConfirmed: true,
      previousState: action.preview.previousState,
      newState: result.newState,
    );

    return ExecutedAction(
      toolName: action.toolName,
      input: action.input,
      result: result,
      tier: action.tier,
    );
  }
}
```

---

## TOOL DEFINITIONS

### Calculator Tools (1,186 total)

```dart
// lib/ai/tools/calculator_tools.dart

/// These are auto-generated from calculator_registry.json
/// Each calculator becomes a Claude tool

final calculatorTools = [
  Tool(
    name: 'calc_voltage_drop',
    description: 'Calculate wire size needed to limit voltage drop. Use for any wire sizing question.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'amps': {'type': 'number', 'description': 'Circuit amperage'},
        'distance_ft': {'type': 'number', 'description': 'One-way distance in feet'},
        'voltage': {'type': 'number', 'description': 'System voltage (default 120)'},
        'max_drop_percent': {'type': 'number', 'description': 'Max voltage drop % (default 3)'},
      },
      'required': ['amps', 'distance_ft'],
    },
  ),
  // ... 1,185 more calculator tools
];
```

### Business Tools (CRUD Operations)

```dart
// lib/ai/tools/business_tools.dart

final businessTools = [
  // JOB TOOLS
  Tool(
    name: 'job_get',
    description: 'Get job details by ID',
    inputSchema: {...},
  ),
  Tool(
    name: 'job_list',
    description: 'List jobs with optional filters',
    inputSchema: {...},
  ),
  Tool(
    name: 'job_create',
    description: 'Create a new job',
    inputSchema: {...},
  ),
  Tool(
    name: 'job_update',
    description: 'Update an existing job',
    inputSchema: {...},
  ),
  Tool(
    name: 'job_delete',
    description: 'Delete a job (moves to Trash)',
    inputSchema: {...},
  ),

  // INVOICE TOOLS
  Tool(
    name: 'invoice_get',
    description: 'Get invoice details',
    inputSchema: {...},
  ),
  Tool(
    name: 'invoice_create',
    description: 'Create a new invoice',
    inputSchema: {...},
  ),
  Tool(
    name: 'invoice_send',
    description: 'Send invoice to customer via email/SMS',
    inputSchema: {...},
  ),

  // BID TOOLS
  Tool(
    name: 'bid_create',
    description: 'Create a new bid with Good/Better/Best options',
    inputSchema: {...},
  ),
  Tool(
    name: 'bid_convert_to_job',
    description: 'Convert accepted bid to job',
    inputSchema: {...},
  ),

  // CUSTOMER TOOLS
  Tool(
    name: 'customer_search',
    description: 'Search customers by name, phone, or address',
    inputSchema: {...},
  ),

  // DOCUMENT TOOLS
  Tool(
    name: 'document_create',
    description: 'Create a document (proposal, contract, change order)',
    inputSchema: {...},
  ),

  // CALENDAR TOOLS
  Tool(
    name: 'calendar_get_schedule',
    description: 'Get schedule for a date range',
    inputSchema: {...},
  ),
  Tool(
    name: 'calendar_schedule_job',
    description: 'Schedule a job on the calendar',
    inputSchema: {...},
  ),
];
```

---

## SOFT DELETE IMPLEMENTATION

### Delete Handler

```dart
// lib/services/soft_delete_service.dart

class SoftDeleteService {
  final FirebaseFirestore _db;

  /// Soft delete any document
  Future<void> softDelete({
    required String collection,
    required String documentId,
    required String companyId,
    required String userId,
    bool deletedByAI = false,
  }) async {
    final docRef = _db.collection('companies/$companyId/$collection').doc(documentId);
    final doc = await docRef.get();

    if (!doc.exists) return;

    final data = doc.data()!;

    // 1. Update original document with deleted flag
    await docRef.update({
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedBy': userId,
      'deletedByAI': deletedByAI,
    });

    // 2. Create trash entry for restore capability
    await _db.collection('companies/$companyId/trash').add({
      'originalCollection': collection,
      'originalId': documentId,
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedBy': userId,
      'deletedByAI': deletedByAI,
      'expiresAt': DateTime.now().add(Duration(days: 30)),
      'data': data,
      'restorable': true,
    });
  }

  /// Restore a soft-deleted document
  Future<void> restore({
    required String companyId,
    required String trashId,
  }) async {
    final trashDoc = await _db
        .collection('companies/$companyId/trash')
        .doc(trashId)
        .get();

    if (!trashDoc.exists) throw Exception('Item not found in trash');

    final trashData = trashDoc.data()!;
    final originalCollection = trashData['originalCollection'];
    final originalId = trashData['originalId'];

    // 1. Remove deleted flags from original
    await _db
        .collection('companies/$companyId/$originalCollection')
        .doc(originalId)
        .update({
          'deletedAt': null,
          'deletedBy': null,
          'deletedByAI': null,
        });

    // 2. Remove from trash
    await trashDoc.reference.delete();
  }

  /// Get trash items
  Future<List<TrashItem>> getTrash(String companyId) async {
    final query = await _db
        .collection('companies/$companyId/trash')
        .where('expiresAt', isGreaterThan: DateTime.now())
        .orderBy('deletedAt', descending: true)
        .get();

    return query.docs.map((d) => TrashItem.fromJson(d.data())).toList();
  }

  /// Permanently delete (empty trash or auto-purge)
  Future<void> permanentDelete({
    required String companyId,
    required String trashId,
  }) async {
    final trashDoc = await _db
        .collection('companies/$companyId/trash')
        .doc(trashId)
        .get();

    if (!trashDoc.exists) return;

    final trashData = trashDoc.data()!;

    // 1. Permanently delete original document
    await _db
        .collection('companies/$companyId/${trashData['originalCollection']}')
        .doc(trashData['originalId'])
        .delete();

    // 2. Delete trash entry
    await trashDoc.reference.delete();
  }
}
```

### Auto-Purge Cloud Function

```typescript
// firebase/functions/src/trashAutoPurge.ts

export const purgeExpiredTrash = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    // Get all companies
    const companies = await db.collection('companies').get();

    for (const company of companies.docs) {
      const expiredTrash = await db
        .collection(`companies/${company.id}/trash`)
        .where('expiresAt', '<', now)
        .get();

      const batch = db.batch();

      for (const trashDoc of expiredTrash.docs) {
        const data = trashDoc.data();

        // Permanently delete original document
        const originalRef = db
          .collection(`companies/${company.id}/${data.originalCollection}`)
          .doc(data.originalId);
        batch.delete(originalRef);

        // Delete trash entry
        batch.delete(trashDoc.ref);
      }

      await batch.commit();
    }
  });
```

---

## AI PERSONALITY

### System Prompt

```dart
// lib/ai/system_prompt.dart

String buildSystemPrompt(String primaryTrade) => '''
You are Z, the Zafto AI assistant for trade professionals.

PERSONALITY:
- Professional, efficient, work-focused
- Concise - contractors are busy, respect their time
- Knowledgeable about trades, especially $primaryTrade
- Action-oriented - always looking to help get things done
- Friendly but not chatty

CAPABILITIES:
- Answer questions about trade work, codes, best practices
- Use calculators for any math (1,186 calculators available)
- Create, update, and manage jobs, invoices, bids, customers, documents
- Search business data
- Schedule work on the calendar
- Generate documents and proposals

BEHAVIOR GUIDELINES:
- For off-topic questions: Answer briefly, then redirect to work
- For vague questions: Ask one clarifying question
- For calculations: Always use the calculator tools, never calculate manually
- For actions: Describe what you're about to do before doing it
- For uncertainty: Be honest, suggest alternatives

EXAMPLES OF GOOD RESPONSES:

User: "How's it going?"
You: "Ready to work! What do you need - calculations, schedule check, or something else?"

User: "I'm stressed about this project"
You: "Let's break it down. What's the main blocker I can help with?"

User: "What wire size for 30 amps at 150 feet?"
You: [Uses voltage_drop_calculator] "You'll need #8 AWG copper to keep voltage drop under 3%. [Shows calculation details]"

User: "Create an invoice for the Smith job"
You: "I'll create an invoice for the Smith Kitchen Remodel job. Here's what I'll include: [shows preview]. Confirm to create?"

NEVER:
- Make up numbers - always use calculators
- Execute RED tier actions without confirmation
- Access other companies' data
- Modify settings or authentication
- Process payments directly
''';
```

---

## STRUCTURED TEMPLATES (Smart Prompts)

### Why Templates Matter

Free-form chat wastes API calls and user patience:
- 5-6 back-and-forth messages to get full context
- User frustrated, AI guessing
- $0.30+ per question

Structured templates get it right first time:
- User provides everything upfront
- Photo + structured data = complete picture
- One API call, accurate answer

### Template Architecture

```dart
// lib/ai/templates/ai_template.dart

class AITemplate {
  final String id;
  final String name;
  final String description;
  final String category;          // troubleshooting, code, estimating, etc.
  final IconData icon;
  final List<TemplateField> fields;
  final String systemPromptAddition;  // Extra context for AI
}

class TemplateField {
  final String id;
  final String label;
  final TemplateFieldType type;   // text, dropdown, photo, number, toggle
  final bool required;
  final List<String>? options;    // For dropdowns
  final String? placeholder;
  final String? aiHint;           // Tells AI what this field means
}

enum TemplateFieldType {
  text,
  textarea,
  dropdown,
  photo,
  multiPhoto,
  number,
  toggle,
  date,
  location,
}
```

### Template Definitions

```dart
// lib/ai/templates/troubleshooting_templates.dart

final equipmentIssueTemplate = AITemplate(
  id: 'troubleshoot_equipment',
  name: 'Troubleshoot Equipment',
  description: 'Diagnose equipment issues with photo + symptoms',
  category: 'troubleshooting',
  icon: LucideIcons.wrench,
  fields: [
    TemplateField(
      id: 'equipment_type',
      label: 'Equipment Type',
      type: TemplateFieldType.dropdown,
      required: true,
      options: ['Boiler', 'Furnace', 'AC Unit', 'Water Heater',
                'Heat Pump', 'Electrical Panel', 'Other'],
      aiHint: 'The type of equipment having issues',
    ),
    TemplateField(
      id: 'photo',
      label: 'Photo of Equipment',
      type: TemplateFieldType.photo,
      required: true,
      aiHint: 'Visual of the equipment and any visible issues',
    ),
    TemplateField(
      id: 'model_serial',
      label: 'Model/Serial Number',
      type: TemplateFieldType.text,
      required: false,
      placeholder: 'If visible on equipment',
      aiHint: 'Equipment model and serial for specific guidance',
    ),
    TemplateField(
      id: 'symptom',
      label: 'Main Symptom',
      type: TemplateFieldType.dropdown,
      required: true,
      options: ['Not turning on', 'Strange noise', 'Leaking',
                'Not heating/cooling', 'Error code', 'Cycling on/off',
                'Other'],
      aiHint: 'Primary symptom the customer is experiencing',
    ),
    TemplateField(
      id: 'when_started',
      label: 'When did this start?',
      type: TemplateFieldType.dropdown,
      required: false,
      options: ['Just now', 'Today', 'This week', 'After recent service',
                'Gradually getting worse', 'Unknown'],
    ),
    TemplateField(
      id: 'error_code',
      label: 'Error Code (if any)',
      type: TemplateFieldType.text,
      required: false,
      placeholder: 'E-04, F1, etc.',
    ),
    TemplateField(
      id: 'notes',
      label: 'Additional Details',
      type: TemplateFieldType.textarea,
      required: false,
      placeholder: 'Anything else relevant...',
    ),
  ],
  systemPromptAddition: '''
The user is troubleshooting equipment. They've provided:
- Equipment type and photo
- Symptoms and when they started
- Model info and error codes if available

Analyze the photo carefully. Provide:
1. Likely diagnosis based on symptoms + visual
2. Immediate safety concerns if any
3. Troubleshooting steps they can try
4. When to call a professional
5. Parts that might need replacement
''',
);

final codeComplianceTemplate = AITemplate(
  id: 'code_compliance',
  name: 'Is This To Code?',
  description: 'Check if installation meets code requirements',
  category: 'code',
  icon: LucideIcons.clipboardCheck,
  fields: [
    TemplateField(
      id: 'trade',
      label: 'Trade/Type',
      type: TemplateFieldType.dropdown,
      required: true,
      options: ['Electrical', 'Plumbing', 'HVAC', 'Gas', 'Structural'],
    ),
    TemplateField(
      id: 'photo',
      label: 'Photo of Installation',
      type: TemplateFieldType.photo,
      required: true,
    ),
    TemplateField(
      id: 'location',
      label: 'State/Jurisdiction',
      type: TemplateFieldType.dropdown,
      required: true,
      options: [...allStates],  // All 50 states
    ),
    TemplateField(
      id: 'location_type',
      label: 'Location in Building',
      type: TemplateFieldType.dropdown,
      required: false,
      options: ['Bathroom', 'Kitchen', 'Bedroom', 'Garage', 'Basement',
                'Attic', 'Exterior', 'Commercial space'],
    ),
    TemplateField(
      id: 'question',
      label: 'Specific Concern',
      type: TemplateFieldType.textarea,
      required: false,
      placeholder: 'What specifically are you unsure about?',
    ),
  ],
  systemPromptAddition: '''
The user is asking about code compliance. They've provided:
- Trade type and photo of installation
- State/jurisdiction for applicable codes
- Location in building (affects requirements)

Analyze the photo and provide:
1. Whether this appears code-compliant (based on visible elements)
2. Specific code references (NEC article, IPC section, etc.)
3. Any violations or concerns visible
4. What an inspector would likely flag
5. How to correct any issues

IMPORTANT: Note that you can only assess what's visible. Hidden work may have other issues.
''',
);

final quickEstimateTemplate = AITemplate(
  id: 'quick_estimate',
  name: 'Quick Material Estimate',
  description: 'Estimate materials needed from photo + description',
  category: 'estimating',
  icon: LucideIcons.calculator,
  fields: [
    TemplateField(
      id: 'photos',
      label: 'Photos of Area/Job',
      type: TemplateFieldType.multiPhoto,
      required: true,
    ),
    TemplateField(
      id: 'work_type',
      label: 'Type of Work',
      type: TemplateFieldType.dropdown,
      required: true,
      options: ['Electrical rough-in', 'Electrical finish', 'Plumbing rough-in',
                'Plumbing finish', 'HVAC install', 'Panel upgrade',
                'Water heater', 'Remodel', 'New construction', 'Service/repair'],
    ),
    TemplateField(
      id: 'scope',
      label: 'Scope Description',
      type: TemplateFieldType.textarea,
      required: true,
      placeholder: 'Describe what needs to be done...',
    ),
    TemplateField(
      id: 'dimensions',
      label: 'Approximate Dimensions',
      type: TemplateFieldType.text,
      required: false,
      placeholder: '10x12 room, 50 ft run, etc.',
    ),
  ],
  systemPromptAddition: '''
The user needs a material estimate. They've provided:
- Photos of the job site/area
- Type of work and scope description
- Dimensions if available

Provide:
1. List of materials needed with quantities
2. Any assumptions you're making
3. Suggest using specific Zafto calculators for precise numbers
4. Note anything you can't determine from the photos
''',
);
```

### Template UI

```dart
// lib/screens/ai/template_selector.dart

class TemplateSelectorSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(LucideIcons.layoutTemplate),
                  SizedBox(width: 8),
                  Text('Ask with Template', style: ZaftoTypography.h3),
                ],
              ),
            ),

            // Template grid
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: allTemplates.length,
                itemBuilder: (context, index) {
                  final template = allTemplates[index];
                  return TemplateCard(
                    template: template,
                    onTap: () => _openTemplate(context, template),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
```

### Sending Template to AI

```dart
// When user completes template and taps "Ask Z AI"

Future<AIResponse> sendTemplateQuery({
  required AITemplate template,
  required Map<String, dynamic> fieldValues,
  required List<File> photos,
  required String companyId,
  required String userId,
}) async {
  // 1. Upload photos to get URLs
  final photoUrls = await Future.wait(
    photos.map((f) => StorageService.uploadTempImage(f)),
  );

  // 2. Build structured message
  final structuredMessage = _buildTemplateMessage(template, fieldValues, photoUrls);

  // 3. Build image content blocks for Claude
  final imageBlocks = await Future.wait(
    photos.map((f) async => ImageBlock(
      type: 'image',
      source: ImageSource(
        type: 'base64',
        mediaType: 'image/jpeg',
        data: base64Encode(await f.readAsBytes()),
      ),
    )),
  );

  // 4. Send to AI with images
  return ZaftoAIService.chatWithImages(
    message: structuredMessage,
    images: imageBlocks,
    systemPromptAddition: template.systemPromptAddition,
    companyId: companyId,
    userId: userId,
  );
}

String _buildTemplateMessage(
  AITemplate template,
  Map<String, dynamic> values,
  List<String> photoUrls,
) {
  final buffer = StringBuffer();
  buffer.writeln('TEMPLATE: ${template.name}');
  buffer.writeln('---');

  for (final field in template.fields) {
    if (field.type == TemplateFieldType.photo ||
        field.type == TemplateFieldType.multiPhoto) {
      buffer.writeln('${field.label}: [See attached photos]');
    } else {
      final value = values[field.id];
      if (value != null && value.toString().isNotEmpty) {
        buffer.writeln('${field.label}: $value');
      }
    }
  }

  return buffer.toString();
}
```

### Chat UI with Template Button

```
┌─────────────────────────────────────────────────────────────┐
│ Z AI                                              [+ New]   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [Messages here...]                                         │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [📷] [🎤] [Type a message...              ] [📋] [Send]   │
│                                                             │
│   ^                                           ^             │
│   Photo                                    Templates        │
│                                                             │
└─────────────────────────────────────────────────────────────┘

📋 = Opens template selector
📷 = Quick photo attach (no template)
🎤 = Voice input
```

---

## PLUG-AND-PLAY INTEGRATION POINTS

### From Any Screen

```dart
// Any screen can open AI chat about that entity

// Job Detail Screen
IconButton(
  icon: Icon(LucideIcons.messageSquare),
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AIChatScreen(
        linkedEntity: LinkedEntity(
          type: 'job',
          id: job.id,
          name: job.title,
        ),
      ),
    ),
  ),
)

// Customer Detail Screen
IconButton(
  icon: Icon(LucideIcons.messageSquare),
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AIChatScreen(
        linkedEntity: LinkedEntity(
          type: 'customer',
          id: customer.id,
          name: customer.name,
        ),
      ),
    ),
  ),
)
```

### Command Palette Integration

```dart
// Command palette can invoke AI

AppCommand(
  id: 'ai_chat',
  title: 'Ask Z AI',
  subtitle: 'Chat with AI assistant',
  icon: LucideIcons.sparkles,
  action: () => Navigator.push(context, MaterialPageRoute(
    builder: (_) => AIChatScreen(),
  )),
)

AppCommand(
  id: 'ai_quick_action',
  title: 'Quick AI Action',
  subtitle: 'Type a command for AI to execute',
  icon: LucideIcons.zap,
  action: () => showQuickAIInput(context),
)
```

### Voice Input (Optional)

```dart
// Voice button in chat or anywhere

IconButton(
  icon: Icon(LucideIcons.mic),
  onPressed: () async {
    final speech = await SpeechService.listen();
    if (speech != null) {
      await ZaftoAIService.chat(message: speech, ...);
    }
  },
)
```

---

## IMPLEMENTATION ORDER

### Phase A: Core AI (Online Only)
**Do this FIRST - proves architecture works**

1. `ZaftoAIService` skeleton
2. `AIThread` model and persistence
3. `ActionTierClassifier`
4. `ToolExecutor` (calculators only)
5. Basic chat UI
6. **TEST:** Chat works, calculators route correctly

### Phase B: Business Tools + Confirmations
**Full online functionality**

1. Add business tools (job, invoice, bid, customer)
2. Confirmation UI for YELLOW/RED tiers
3. `AuditLogger`
4. `SoftDeleteService`
5. Trash UI
6. **TEST:** Create/update/delete with confirmations

### Phase C: Thread Management
**Context stays manageable**

1. Thread linking to entities
2. Auto-summarization Cloud Function
3. Thread list UI
4. Context injection system
5. **TEST:** Long conversations summarize correctly

### Phase D: Templates + Images
**Better UX, lower costs**

1. Template system
2. Image handling
3. Template UI
4. Multi-modal API calls
5. **TEST:** Templates provide complete context in one call

### Phase E: Error Handling + Polish
**Production ready**

1. Retry logic
2. Rate limiting
3. Cost tracking
4. Concurrency guard
5. Offline fallback (calculators only)
6. **TEST:** Handles all failure modes gracefully

---

### Phase F: Offline Calculator Intelligence (LAST)
**Do this AFTER everything above works**

1. Build calculator metadata index from screen_registry (name, description, trade, tags, keywords)
2. Implement Tier 1 fuzzy search against calculator metadata
3. Evaluate and integrate small sentence embedding model (~30-50MB) for Tier 2 semantic search
4. Generate calculator embedding vectors from metadata index
5. Build reference content search index (111 diagrams, 21 guides, 9 tables)
6. Implement similarity threshold + fallback to calculator category browser UI
7. **TEST:** Offline calculator search finds right calculator for natural language queries

**Why last?**
- Online AI proves the architecture
- INTEL content can be refined based on real usage
- Offline search is a "nice to have" for v1, not a blocker
- Easier to debug when online version works first

**NOTE:** On-device LLM (Phi-4 Mini, 2GB) was SCRAPPED. 2GB download for
calculator routing is not worth it when fuzzy search + 50MB embedding model
achieves the same result with zero thermal issues and no device restrictions.

---

## FILE STRUCTURE

```
lib/
├── ai/
│   ├── zafto_ai_service.dart        # THE single entry point
│   ├── action_tiers.dart            # GREEN/YELLOW/RED classification
│   ├── context_builder.dart         # Builds context for API calls
│   ├── system_prompt.dart           # AI personality
│   ├── audit_logger.dart            # Logs all AI actions
│   ├── cost_tracker.dart            # Token/cost monitoring
│   ├── rate_limiter.dart            # Per-user rate limiting
│   ├── concurrency_guard.dart       # Prevent edit conflicts
│   │
│   ├── tools/
│   │   ├── calculator_tools.dart    # 1,186 calculator tool definitions
│   │   ├── business_tools.dart      # CRUD tool definitions
│   │   └── tool_executor.dart       # Executes tool calls
│   │
│   ├── thread/
│   │   ├── ai_thread_service.dart   # Thread CRUD
│   │   └── thread_models.dart       # AIThread, AIMessage models
│   │
│   ├── templates/
│   │   ├── ai_template.dart         # Template model
│   │   ├── troubleshooting_templates.dart
│   │   ├── code_templates.dart
│   │   ├── estimating_templates.dart
│   │   └── template_executor.dart   # Build message from template
│   │
│   ├── images/
│   │   └── image_handler.dart       # Compress, validate, encode images
│   │
│   └── offline/                     # PHASE F - Added last
│       ├── offline_search_service.dart  # Tiered calculator search (fuzzy + embedding)
│       ├── calculator_index.dart    # Calculator metadata index
│       ├── embedding_service.dart   # Sentence embedding for Tier 2 semantic search
│       └── reference_index.dart     # Reference content search index
│
├── services/
│   ├── soft_delete_service.dart     # Soft delete + restore
│   └── trash_service.dart           # Trash management
│
├── screens/
│   └── ai/
│       ├── ai_chat_screen.dart      # Main chat UI
│       ├── ai_thread_list.dart      # Thread browser
│       ├── ai_trash_screen.dart     # Trash/restore UI
│       ├── template_selector.dart   # Template picker
│       └── template_form.dart       # Fill out template
│
├── widgets/
│   └── ai/
│       ├── ai_message_bubble.dart   # Message display
│       ├── action_confirmation.dart # YELLOW/RED confirm UI
│       ├── action_preview.dart      # Preview of what AI will do
│       ├── ai_fab.dart              # Floating action button to open AI
│       └── offline_indicator.dart   # Shows when using offline AI

assets/
├── ai/
│   ├── calculator_registry.json     # All 1,186 calculator metadata (name, description, trade, tags)
│   ├── calculator_vectors.bin       # Pre-computed embedding vectors for Tier 2 search
│   ├── reference_index.json         # Searchable index of 111 diagrams, 21 guides, 9 tables
│   └── model_config.json            # Model settings

# Downloaded on demand (~50MB total):
# ~/Documents/Zafto/models/minilm-l6-v2.onnx (sentence embedding for Tier 2 semantic search)
# NOTE: On-device LLM (Phi-4 Mini) SCRAPPED — not worth 2GB for calculator routing

# NOTE: Platform-specific offline AI folders (iOS MLX Swift, Android llama.cpp) REMOVED
# On-device LLM scrapped. Offline search handled entirely in Dart (fuzzy + ONNX embedding).

firebase/functions/src/
├── aiThreadSummarizer.ts            # Auto-summarize long threads
├── trashAutoPurge.ts                # Delete expired trash items
└── aiAuditExport.ts                 # Export audit logs (optional)

# Build tools (run during CI/CD):
tools/
├── prepare_intel_embeddings.dart    # Embed INTEL files → vector DB
├── generate_calculator_registry.dart # Extract calculator signatures
└── validate_intel_coverage.dart     # Ensure all trades covered
```

---

## IMPLEMENTATION ORDER

### Phase 1: Foundation (Do First)
1. Create `AIThread` and `AIMessage` models
2. Create `ZaftoAIService` skeleton
3. Create `ActionTierClassifier`
4. Create `SoftDeleteService`
5. Add `deletedAt` fields to all models

### Phase 2: Core AI
1. Implement `AIContextBuilder`
2. Implement `ToolExecutor` (just calculators first)
3. Implement basic `AIChatScreen`
4. Test: Chat works, calculators work

### Phase 3: Business Tools
1. Add business tools (job, invoice, bid, customer, document)
2. Implement action tier confirmation UI
3. Implement `AuditLogger`
4. Test: Create/update actions require confirmation

### Phase 4: Thread Management
1. Implement `AIThreadService`
2. Implement thread list UI
3. Implement auto-summarization (Cloud Function)
4. Test: Threads persist, summaries generate

### Phase 5: Polish
1. Add Trash UI
2. Add auto-purge Cloud Function
3. Add voice input (optional)
4. Test full flow

---

## BULLETPROOF SAFEGUARDS

### Offline LLM Architecture

**Full AI capabilities offline - not just calculators.**

When no internet: Local LLM handles questions using INTEL knowledge base.

```
┌─────────────────────────────────────────────────────────────────┐
│                      OFFLINE AI STACK                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   USER QUESTION                                                  │
│        │                                                         │
│        ▼                                                         │
│   ┌─────────────┐                                               │
│   │  Embedding  │ ← Model2Vec (iOS) / ONNX MiniLM (Android)    │
│   │   Model     │   Converts question to vector                 │
│   └─────────────┘                                               │
│        │                                                         │
│        ▼                                                         │
│   ┌─────────────┐                                               │
│   │  Vector DB  │ ← VecturaKit (iOS) / Chroma (Android)        │
│   │   Search    │   Finds relevant INTEL chunks                 │
│   └─────────────┘                                               │
│        │                                                         │
│        ▼ (Top 3-5 relevant chunks)                              │
│   ┌─────────────┐                                               │
│   │  Local LLM  │ ← MLX Swift (iOS) / llama.cpp (Android)      │
│   │  Inference  │   Phi-4 Mini (2B params) or Llama 4 Scout    │
│   └─────────────┘                                               │
│        │                                                         │
│        ▼                                                         │
│   ┌─────────────┐                                               │
│   │ Calculator  │ ← If LLM identifies calculation needed       │
│   │   Router    │   Routes to actual Dart calculator code      │
│   └─────────────┘                                               │
│        │                                                         │
│        ▼                                                         │
│   VERIFIED ANSWER + CODE CITATION                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### iOS Offline Stack

| Layer | Technology | Size | Purpose |
|-------|------------|------|---------|
| LLM Runtime | **MLX Swift** | - | Apple's ML framework for on-device inference |
| Model | **Phi-4 Mini Q4** | ~1.5GB | Language understanding, reasoning |
| Vector Store | **VecturaKit** | ~50MB | Swift-native vector database |
| Embeddings | **Model2Vec** | ~90MB | Text → vector conversion |
| Knowledge | INTEL chunks | ~20MB | All trade knowledge, pre-embedded |

```swift
// ios/Runner/OfflineAI/ZaftoOfflineAI.swift

import MLX
import MLXLLM
import VecturaKit

class ZaftoOfflineAI {
    private var llm: LLMModel?
    private var vectorStore: VecturaKit
    private var embeddings: Model2Vec

    // Load on app startup (background)
    func initialize() async throws {
        // Load quantized Phi-4 Mini (~1.5GB)
        llm = try await LLMModel.load(from: "phi-4-mini-q4")

        // Load embeddings model (~90MB)
        embeddings = try Model2Vec.load("minilm-l6-v2")

        // Vector store already loaded with INTEL embeddings
        vectorStore = try VecturaKit.load(from: "intel_vectors.db")
    }

    func query(_ question: String) async throws -> OfflineResponse {
        // 1. Embed the question
        let questionVector = embeddings.encode(question)

        // 2. Find relevant INTEL chunks (RAG)
        let relevantChunks = vectorStore.search(
            vector: questionVector,
            topK: 5,
            threshold: 0.7
        )

        // 3. Build prompt with context
        let prompt = buildPrompt(question: question, context: relevantChunks)

        // 4. Run inference
        let response = try await llm.generate(
            prompt: prompt,
            maxTokens: 1024,
            temperature: 0.3  // Lower = more factual
        )

        // 5. Check if calculator needed
        if let calcIntent = parseCalculatorIntent(response) {
            let calcResult = try await executeCalculator(calcIntent)
            return OfflineResponse(
                text: formatWithCalculation(response, calcResult),
                source: .localLLM,
                calculatorUsed: calcIntent.calculatorId,
                intelChunks: relevantChunks.map { $0.id }
            )
        }

        return OfflineResponse(
            text: response,
            source: .localLLM,
            intelChunks: relevantChunks.map { $0.id }
        )
    }

    private func buildPrompt(question: String, context: [INTELChunk]) -> String {
        """
        You are a trade professional assistant. Answer based on the reference material below.

        REFERENCE MATERIAL:
        \(context.map { "[\($0.source)]\n\($0.content)" }.joined(separator: "\n\n"))

        RULES:
        - Only answer based on the reference material
        - Cite sources: "Per NEC 310.16..." or "According to IPC 604.1..."
        - If calculation needed, output: CALC_NEEDED: calculator_name(param1, param2)
        - If you don't know, say so

        QUESTION: \(question)

        ANSWER:
        """
    }
}
```

### Android Offline Stack

| Layer | Technology | Size | Purpose |
|-------|------------|------|---------|
| LLM Runtime | **llama.cpp** | - | Cross-platform LLM inference |
| Model | **Phi-4 Mini GGUF Q4** | ~1.5GB | Same model, GGUF format |
| Vector Store | **Chroma** or SQLite | ~50MB | Vector search |
| Embeddings | **ONNX MiniLM** | ~90MB | Same embeddings, ONNX runtime |
| Knowledge | INTEL chunks | ~20MB | Same knowledge base |

```kotlin
// android/app/src/main/kotlin/com/zafto/app/ai/ZaftoOfflineAI.kt

class ZaftoOfflineAI(private val context: Context) {
    private lateinit var llm: LlamaModel
    private lateinit var vectorStore: ChromaDB
    private lateinit var embeddings: ONNXEmbeddings

    suspend fun initialize() {
        // Load quantized model
        llm = LlamaModel.load(
            context.assets.open("models/phi-4-mini-q4.gguf")
        )

        // Load ONNX embeddings
        embeddings = ONNXEmbeddings.load(
            context.assets.open("models/minilm-l6-v2.onnx")
        )

        // Load vector store
        vectorStore = ChromaDB.open(
            context.getDatabasePath("intel_vectors.db")
        )
    }

    suspend fun query(question: String): OfflineResponse {
        // Same flow as iOS
        val questionVector = embeddings.encode(question)
        val relevantChunks = vectorStore.search(questionVector, topK = 5)
        val prompt = buildPrompt(question, relevantChunks)
        val response = llm.generate(prompt, maxTokens = 1024)

        // Handle calculator routing...
        return OfflineResponse(text = response, source = Source.LOCAL_LLM)
    }
}
```

### INTEL Knowledge Preparation (Build Time)

```dart
// tools/prepare_intel_embeddings.dart
// Run this ONCE during build to prepare offline knowledge base

Future<void> prepareINTELEmbeddings() async {
    final embeddings = Model2Vec.load('minilm-l6-v2');
    final vectorStore = VecturaKit(dimensions: 384);

    // Process each trade's INTEL file
    final trades = ['electrical', 'plumbing', 'hvac', 'solar', ...];

    for (final trade in trades) {
        final content = await File('INTEL/TRADES/$trade.md').readAsString();

        // Chunk by ## headers (each section is a chunk)
        final chunks = chunkByHeaders(content);

        for (final chunk in chunks) {
            // Embed the chunk
            final vector = embeddings.encode(chunk.text);

            // Store with metadata
            vectorStore.add(
                id: '${trade}_${chunk.sectionId}',
                vector: vector,
                metadata: {
                    'trade': trade,
                    'section': chunk.section,
                    'subsection': chunk.subsection,
                    'calculators': chunk.relatedCalculators,
                    'codeRefs': chunk.codeReferences,
                },
                content: chunk.text,  // Store full text for retrieval
            );
        }
    }

    // Export for iOS
    await vectorStore.export('assets/ai/intel_vectors_ios.db');

    // Export for Android (Chroma format)
    await vectorStore.exportChroma('assets/ai/intel_vectors_android.db');

    print('Embedded ${vectorStore.count} chunks from ${trades.length} trades');
}
```

### Model Training / Fine-Tuning

**We do NOT train from scratch.** We use pre-trained models + RAG.

| Approach | Effort | Quality | Recommendation |
|----------|--------|---------|----------------|
| Train from scratch | 6+ months, $$$$ | Unknown | NO |
| Fine-tune on INTEL | 2-3 weeks, $$ | Good | OPTIONAL |
| RAG with base model | 1-2 days, $ | Very Good | **YES - DO THIS** |

**RAG (Retrieval Augmented Generation) wins because:**
- INTEL content changes → just re-embed, no retraining
- Base model (Phi-4) already understands language
- We inject trade knowledge at query time
- Much faster to iterate

**Optional Fine-Tuning (Later):**
If we want even better offline quality, we can fine-tune on:
- Q&A pairs generated from INTEL files
- Real user questions + good answers
- Calculator usage patterns

```python
# Optional: Fine-tune Phi-4 Mini on Zafto Q&A
# Only do this AFTER RAG is working well

from transformers import AutoModelForCausalLM, Trainer

# Load base model
model = AutoModelForCausalLM.from_pretrained("microsoft/phi-4-mini")

# Load our Q&A dataset (generated from INTEL)
dataset = load_dataset("json", data_files="zafto_qa_pairs.jsonl")

# Fine-tune with LoRA (efficient, preserves base knowledge)
trainer = Trainer(
    model=model,
    train_dataset=dataset,
    # LoRA config...
)
trainer.train()

# Export quantized for mobile
model.save_quantized("phi-4-mini-zafto-q4")
```

### Offline vs Online Decision Flow

```dart
// lib/ai/zafto_ai_service.dart

Future<AIResponse> chat({...}) async {
    // 1. Check connectivity
    final isOnline = await ConnectivityService.hasInternet();

    if (isOnline) {
        // 2a. Online: Use Claude API (full power)
        return await _callClaudeAPI(message, images, context);
    } else {
        // 2b. Offline: Use local LLM
        return await _callOfflineLLM(message, images);
    }
}

Future<AIResponse> _callOfflineLLM(String message, List<File>? images) async {
    // Note: Image analysis is LIMITED offline
    // Local model can describe what it sees but not as good as Claude

    if (images != null && images.isNotEmpty) {
        // Warn user about limited image capability
        return AIResponse(
            text: await _offlineAI.queryWithImage(message, images.first),
            isOffline: true,
            limitedCapability: true,
            warning: 'Image analysis is limited offline. Reconnect for full analysis.',
        );
    }

    return AIResponse(
        text: await _offlineAI.query(message),
        isOffline: true,
    );
}
```

### Offline Capabilities Matrix

| Feature | Online (Claude) | Offline (Local LLM) |
|---------|:---------------:|:-------------------:|
| Calculator routing | Full | Full |
| Code references | Full | Full (via RAG) |
| Trade Q&A | Full | Good (via RAG) |
| Image analysis | Excellent | Basic |
| Document generation | Full | Limited |
| Complex reasoning | Excellent | Good |
| Business data access | Full | Local cache only |
| Tool execution | All tools | Calculators only |

### Model Sizes & Download

| Component | Size | When Downloaded |
|-----------|------|-----------------|
| Phi-4 Mini Q4 | ~1.5GB | First launch (optional, user prompted) |
| Embeddings model | ~90MB | With app |
| INTEL vectors | ~20MB | With app |
| **Total for offline AI** | **~1.6GB** | Mostly optional download |

```dart
// Prompt user before downloading large model

Future<void> promptOfflineDownload() async {
    final result = await showDialog(
        // ...
        content: Column(
            children: [
                Text('Enable Offline AI?'),
                Text('Download ~1.5GB for full AI capabilities without internet.'),
                Text('You can still use calculators offline without this.'),
            ],
        ),
        actions: [
            TextButton(child: Text('Not Now'), onPressed: () => Navigator.pop(false)),
            ElevatedButton(child: Text('Download'), onPressed: () => Navigator.pop(true)),
        ],
    );

    if (result == true) {
        await OfflineModelManager.downloadModel(
            onProgress: (percent) => setState(() => _downloadProgress = percent),
        );
    }
}
```

### API Failure Handling

```dart
// lib/ai/api_handler.dart

class AIAPIHandler {
  static const maxRetries = 3;
  static const retryDelays = [1000, 2000, 5000]; // ms

  Future<AIResponse> callWithRetry(AIRequest request) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await _callAPI(request);
      } on RateLimitException {
        // Wait and retry
        await Future.delayed(Duration(milliseconds: retryDelays[attempt]));
      } on APIOverloadedException {
        // Claude is busy - try fallback model
        return await _callFallbackModel(request);
      } on NetworkException {
        // No connection - use offline handler
        return AIOfflineHandler().handleOffline(request.message);
      } on AuthException {
        // Token expired - shouldn't happen, but handle it
        throw AIException('Please restart the app');
      }
    }

    // All retries failed
    return AIResponse(
      message: 'I\'m having trouble connecting right now. Try again in a minute.',
      error: true,
    );
  }

  Future<AIResponse> _callFallbackModel(AIRequest request) async {
    // If Opus is overloaded, fall back to Sonnet for non-complex queries
    if (!request.requiresOpus) {
      return await _callAPI(request.copyWith(model: 'claude-sonnet-4-20250514'));
    }
    throw APIOverloadedException();
  }
}
```

### Cost Tracking

```dart
// lib/ai/cost_tracker.dart

class AICostTracker {
  // Approximate costs (update as pricing changes)
  static const costPerInputToken = 0.000015;   // $15 per 1M input
  static const costPerOutputToken = 0.000075;  // $75 per 1M output

  /// Track usage per company per month
  Future<void> trackUsage({
    required String companyId,
    required int inputTokens,
    required int outputTokens,
    required String model,
  }) async {
    final cost = (inputTokens * costPerInputToken) +
                 (outputTokens * costPerOutputToken);

    final monthKey = DateFormat('yyyy-MM').format(DateTime.now());

    await _db.collection('companies/$companyId/aiUsage').doc(monthKey).set({
      'inputTokens': FieldValue.increment(inputTokens),
      'outputTokens': FieldValue.increment(outputTokens),
      'totalCost': FieldValue.increment(cost),
      'queryCount': FieldValue.increment(1),
      'lastQuery': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get current month usage
  Future<AIUsage> getMonthUsage(String companyId) async {
    final monthKey = DateFormat('yyyy-MM').format(DateTime.now());
    final doc = await _db.collection('companies/$companyId/aiUsage').doc(monthKey).get();
    return AIUsage.fromJson(doc.data() ?? {});
  }

  /// Soft warning thresholds (NOT hard limits)
  static Map<String, double> monthlyWarningThresholds = {
    'solo': 10.00,      // Warn at $10/month
    'team': 50.00,      // Warn at $50/month
    'business': 200.00, // Warn at $200/month
    'enterprise': double.infinity, // No warning
  };

  Future<bool> shouldShowWarning(String companyId, String tier) async {
    final usage = await getMonthUsage(companyId);
    final threshold = monthlyWarningThresholds[tier] ?? 10.00;
    return usage.totalCost > threshold;
  }
}
```

### Model Versioning

```dart
// lib/ai/model_config.dart

/// Centralized model configuration - easy to update when new models release
class AIModelConfig {
  // Current models (update when Opus 5 releases)
  static const primaryModel = 'claude-sonnet-4-20250514';      // Default for most queries
  static const powerModel = 'claude-opus-4-5-20251101';     // For complex analysis
  static const fastModel = 'claude-haiku-3-5-20241022';       // For simple/bulk operations

  // Model selection logic
  static String selectModel(AIRequest request) {
    // Complex analysis (contracts, multi-step reasoning)
    if (request.requiresDeepAnalysis) {
      return powerModel;
    }

    // Simple operations (formatting, simple lookups)
    if (request.isSimple) {
      return fastModel;
    }

    // Default
    return primaryModel;
  }

  // Feature flags for gradual rollout
  static bool useOpus5WhenAvailable = false;  // Flip when ready

  // Model capabilities (for UI hints)
  static Map<String, ModelCapabilities> capabilities = {
    primaryModel: ModelCapabilities(
      supportsImages: true,
      maxOutputTokens: 8192,
      supportsTools: true,
    ),
    powerModel: ModelCapabilities(
      supportsImages: true,
      maxOutputTokens: 16384,
      supportsTools: true,
      bestForComplexReasoning: true,
    ),
    fastModel: ModelCapabilities(
      supportsImages: true,
      maxOutputTokens: 4096,
      supportsTools: true,
      lowestLatency: true,
    ),
  };
}
```

### Concurrent Edit Protection

```dart
// lib/ai/concurrency_guard.dart

class AIConcurrencyGuard {
  // Track what entities AI is currently working on
  static final _activeLocks = <String, AILock>{};

  /// Check if AI can edit this entity
  static bool canEdit(String entityType, String entityId) {
    final key = '$entityType:$entityId';
    final lock = _activeLocks[key];

    if (lock == null) return true;
    if (lock.isExpired) {
      _activeLocks.remove(key);
      return true;
    }

    return false;
  }

  /// Lock entity while AI is editing
  static void lock(String entityType, String entityId, {Duration? timeout}) {
    final key = '$entityType:$entityId';
    _activeLocks[key] = AILock(
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(timeout ?? Duration(seconds: 30)),
    );
  }

  /// Release lock when AI is done
  static void unlock(String entityType, String entityId) {
    final key = '$entityType:$entityId';
    _activeLocks.remove(key);
  }

  /// What to do if user tries to edit something AI is working on
  static void handleConflict(String entityType, String entityId) {
    // Show toast: "Z AI is updating this. Please wait..."
    // Or: Cancel AI operation and let user take over
  }
}

// In tool executor:
Future<ToolResult> _executeUpdate(String resource, String id, Map updates) async {
  if (!AIConcurrencyGuard.canEdit(resource, id)) {
    return ToolResult.error('This $resource is currently being edited. Try again in a moment.');
  }

  AIConcurrencyGuard.lock(resource, id);
  try {
    // Do the update
    return await _doUpdate(resource, id, updates);
  } finally {
    AIConcurrencyGuard.unlock(resource, id);
  }
}
```

### Image Handling

```dart
// lib/ai/image_handler.dart

class AIImageHandler {
  static const maxImageSize = 5 * 1024 * 1024; // 5MB
  static const maxImagesPerQuery = 5;
  static const supportedFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

  /// Prepare images for Claude API
  static Future<List<ImageBlock>> prepareImages(List<File> images) async {
    if (images.length > maxImagesPerQuery) {
      throw AIException('Maximum $maxImagesPerQuery images per question');
    }

    final blocks = <ImageBlock>[];

    for (final image in images) {
      // Validate format
      final ext = image.path.split('.').last.toLowerCase();
      if (!supportedFormats.contains(ext)) {
        throw AIException('Unsupported image format: $ext');
      }

      // Check size and compress if needed
      var bytes = await image.readAsBytes();
      if (bytes.length > maxImageSize) {
        bytes = await _compressImage(bytes);
      }

      blocks.add(ImageBlock(
        type: 'image',
        source: ImageSource(
          type: 'base64',
          mediaType: 'image/$ext',
          data: base64Encode(bytes),
        ),
      ));
    }

    return blocks;
  }

  static Future<Uint8List> _compressImage(Uint8List bytes) async {
    // Use flutter_image_compress or similar
    final result = await FlutterImageCompress.compressWithList(
      bytes,
      quality: 85,
      minWidth: 1920,
      minHeight: 1080,
    );
    return result;
  }
}
```

### Rate Limiting (Per User)

```dart
// lib/ai/rate_limiter.dart

class AIRateLimiter {
  // Queries per minute per user (prevent abuse)
  static const queriesPerMinute = 20;

  // Track recent queries
  final _queryTimestamps = <String, List<DateTime>>{};

  bool canQuery(String userId) {
    final timestamps = _queryTimestamps[userId] ?? [];
    final cutoff = DateTime.now().subtract(Duration(minutes: 1));

    // Remove old timestamps
    timestamps.removeWhere((t) => t.isBefore(cutoff));
    _queryTimestamps[userId] = timestamps;

    return timestamps.length < queriesPerMinute;
  }

  void recordQuery(String userId) {
    final timestamps = _queryTimestamps[userId] ?? [];
    timestamps.add(DateTime.now());
    _queryTimestamps[userId] = timestamps;
  }

  Duration? getWaitTime(String userId) {
    if (canQuery(userId)) return null;

    final timestamps = _queryTimestamps[userId]!;
    final oldest = timestamps.first;
    return oldest.add(Duration(minutes: 1)).difference(DateTime.now());
  }
}
```

---

## TESTING CHECKLIST

### Calculator Tests
- [ ] Ask "What wire size for 30 amps at 150 feet?" - should use voltage_drop calculator
- [ ] Ask "How many BTUs for 2000 sq ft?" - should use HVAC calculator
- [ ] Verify calculator results match actual calculator screens

### Action Tier Tests
- [ ] Ask "What jobs do I have?" - should auto-execute (GREEN)
- [ ] Ask "Create a job for Smith" - should show preview (YELLOW)
- [ ] Ask "Delete the Smith job" - should show warning modal (RED)
- [ ] Ask "Change my password" - should refuse (NEVER)

### Thread Tests
- [ ] Start new conversation - thread created
- [ ] Continue conversation - same thread
- [ ] Start chat from Job Detail - thread linked to job
- [ ] Send 25 messages - auto-summarization triggers

### Soft Delete Tests
- [ ] Delete job via AI - job soft deleted, appears in Trash
- [ ] Restore from Trash - job restored
- [ ] Wait 30 days (simulate) - auto-purge removes permanently

### Context Tests
- [ ] Ask "How's the Smith job?" - should fetch Smith job data
- [ ] Ask "Schedule for Friday" - should fetch calendar data
- [ ] Ask in thread linked to job - job context auto-included

### Template Tests
- [ ] Open template selector from chat
- [ ] Fill out "Troubleshoot Equipment" template with photo
- [ ] Submit - AI receives structured data + image
- [ ] Response addresses all provided info

### Image Tests
- [ ] Send single photo with question - works
- [ ] Send 5 photos - works
- [ ] Send 6 photos - shows max limit error
- [ ] Send 10MB photo - auto-compresses and works
- [ ] Send unsupported format - shows error

### Offline Tests (Basic - No LLM)
- [ ] Turn off wifi, ask "What wire size for 20A at 100ft?" - uses local calculator
- [ ] Turn off wifi, ask "What's on my schedule?" - uses local cache
- [ ] Come back online - normal function resumes

### Offline LLM Tests (After INTEL Phase)
- [ ] Download offline model prompt appears on first launch
- [ ] Model downloads successfully (~1.5GB)
- [ ] Turn off wifi, ask "What's the NEC requirement for bathroom receptacles?" - answers from INTEL
- [ ] Turn off wifi, ask calculation question - routes to calculator correctly
- [ ] Turn off wifi, send photo - warns about limited capability
- [ ] Verify RAG retrieves correct INTEL chunks
- [ ] Response includes code citations

### Error Handling Tests
- [ ] Simulate API timeout - retries then shows friendly error
- [ ] Simulate rate limit - waits and retries
- [ ] Simulate 500 error - falls back to Sonnet model

### Cost Tracking Tests
- [ ] Make 10 queries - usage tracked in Firestore
- [ ] Approach warning threshold - soft warning shown
- [ ] Exceed threshold - warning shown but still works

### Concurrency Tests
- [ ] AI starts editing job, user opens same job - shows "AI is editing" notice
- [ ] AI finishes editing - user can edit normally
- [ ] User cancels - AI operation cancelled

---

## SUMMARY

### What Makes This Bulletproof

| Feature | Protection |
|---------|------------|
| **Action Tiers** | Destructive actions always require confirmation |
| **Soft Delete** | Nothing permanently lost for 30 days |
| **Audit Log** | Every AI action recorded, reversible |
| **Offline LLM** | Full AI works without internet (after INTEL phase) |
| **RAG Architecture** | INTEL knowledge injected, not trained - easy to update |
| **API Retry** | Auto-retry on failures, fallback models |
| **Rate Limiting** | 20 queries/min per user (abuse prevention) |
| **Cost Tracking** | Soft warnings, no hard blocks |
| **Concurrency Guard** | Prevents AI/user edit conflicts |
| **Model Abstraction** | Easy to swap models (Opus 5 ready) |
| **Templates** | Structured input = better answers, lower cost |

### The Template Advantage

Templates aren't redundant - they're a **force multiplier**:

| Without Template | With Template |
|-----------------|---------------|
| 5-6 API calls to get context | 1 API call with complete context |
| ~$0.30 per question | ~$0.08 per question |
| User frustrated by back-and-forth | User provides everything upfront |
| AI guessing | AI has full picture + photo |
| Generic answers | Specific, actionable answers |

### One Service to Rule Them All

```dart
// Entire AI integration is ONE method call:
ZaftoAIService.chat(
  message: userMessage,
  images: photos,           // Optional
  template: template,       // Optional
  linkedEntity: entity,     // Optional
  companyId: company.id,
  userId: user.id,
);

// Everything else is handled internally:
// - Context injection
// - Tool execution
// - Tier enforcement
// - Audit logging
// - Error handling
// - Cost tracking
```

---

*This is the complete AI integration spec. Everything goes through ZaftoAIService. Plug and play.*
*Updated: February 3, 2026*
