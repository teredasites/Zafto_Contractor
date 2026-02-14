/// AI Tools for Function Calling
///
/// These tools allow the AI to take actions within the app.
/// Each tool has a schema for Claude's tool_use and an executor function.

import 'dart:async';

/// Tool definition for Claude API
class AITool {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> args) execute;

  const AITool({
    required this.name,
    required this.description,
    required this.inputSchema,
    required this.execute,
  });

  /// Convert to Claude API tool format
  Map<String, dynamic> toClaudeFormat() => {
    'name': name,
    'description': description,
    'input_schema': inputSchema,
  };
}

/// Registry of all available AI tools
class AIToolRegistry {
  final Map<String, AITool> _tools = {};

  AIToolRegistry() {
    _registerAllTools();
  }

  void _registerAllTools() {
    // Calculator tools
    register(searchCalculatorsTool);
    register(runCalculationTool);

    // NEC reference tools
    register(searchNecTool);
    register(getNecArticleTool);

    // Job management tools
    register(getJobDetailsTool);
    register(updateJobTool);
    register(getScheduleTool);

    // Customer tools
    register(getCustomerInfoTool);
    register(searchCustomersTool);

    // Invoice tools
    register(createInvoiceDraftTool);

    // Business tools
    register(getBusinessMetricsTool);

    // Navigation tools
    register(openCalculatorTool);
    register(openJobTool);
  }

  void register(AITool tool) {
    _tools[tool.name] = tool;
  }

  AITool? get(String name) => _tools[name];

  List<Map<String, dynamic>> getAllForClaude() {
    return _tools.values.map((t) => t.toClaudeFormat()).toList();
  }

  Future<Map<String, dynamic>> execute(String name, Map<String, dynamic> args) async {
    final tool = _tools[name];
    if (tool == null) {
      return {'error': 'Unknown tool: $name'};
    }
    try {
      return await tool.execute(args);
    } catch (e) {
      return {'error': 'Tool execution failed: $e'};
    }
  }
}

// =============================================================================
// CALCULATOR TOOLS
// =============================================================================

final searchCalculatorsTool = AITool(
  name: 'search_calculators',
  description: 'Search for calculators by name, category, or purpose. Returns a list of matching calculators with their IDs.',
  inputSchema: {
    'type': 'object',
    'properties': {
      'query': {
        'type': 'string',
        'description': 'Search query (e.g., "voltage drop", "conduit fill", "motor")',
      },
      'category': {
        'type': 'string',
        'description': 'Optional category filter',
        'enum': ['wire', 'conduit', 'load', 'motor', 'box', 'grounding', 'transformer', 'all'],
      },
    },
    'required': ['query'],
  },
  execute: (args) async {
    return {
      'error': 'AI calculator search is not yet available. This feature will be enabled in a future update.',
      'results': <Map<String, dynamic>>[],
      'count': 0,
    };
  },
);

final runCalculationTool = AITool(
  name: 'run_calculation',
  description: 'Execute a calculation and return the result. Use this to actually compute values for the user.',
  inputSchema: {
    'type': 'object',
    'properties': {
      'calculator_id': {
        'type': 'string',
        'description': 'ID of the calculator to use (from search_calculators)',
      },
      'inputs': {
        'type': 'object',
        'description': 'Input parameters for the calculation',
        'additionalProperties': true,
      },
    },
    'required': ['calculator_id', 'inputs'],
  },
  execute: (args) async {
    return {
      'success': false,
      'error': 'AI-powered calculations are not yet available. This feature will be enabled in a future update.',
    };
  },
);

final openCalculatorTool = AITool(
  name: 'open_calculator',
  description: 'Navigate to and open a specific calculator in the app.',
  inputSchema: {
    'type': 'object',
    'properties': {
      'calculator_id': {
        'type': 'string',
        'description': 'ID of the calculator to open',
      },
      'prefill': {
        'type': 'object',
        'description': 'Optional values to prefill in the calculator',
        'additionalProperties': true,
      },
    },
    'required': ['calculator_id'],
  },
  execute: (args) async {
    return {
      'action': 'navigate',
      'destination': 'calculator',
      'calculatorId': args['calculator_id'],
      'prefill': args['prefill'],
    };
  },
);

// =============================================================================
// NEC REFERENCE TOOLS
// =============================================================================

final searchNecTool = AITool(
  name: 'search_nec',
  description: 'Search the NEC code book for articles, sections, or topics.',
  inputSchema: {
    'type': 'object',
    'properties': {
      'query': {
        'type': 'string',
        'description': 'Search query (e.g., "grounding electrode", "210.8", "GFCI requirements")',
      },
      'year': {
        'type': 'string',
        'description': 'NEC year (default: 2023)',
        'enum': ['2023', '2020', '2017'],
      },
    },
    'required': ['query'],
  },
  execute: (args) async {
    return {
      'results': [
        {
          'article': '210.8',
          'title': 'Ground-Fault Circuit-Interrupter Protection for Personnel',
          'summary': 'GFCI protection requirements for dwelling units and other occupancies',
        },
      ],
      'count': 1,
    };
  },
);

final getNecArticleTool = AITool(
  name: 'get_nec_article',
  description: 'Get the full text and details of a specific NEC article.',
  inputSchema: {
    'type': 'object',
    'properties': {
      'article': {
        'type': 'string',
        'description': 'Article number (e.g., "210.8(A)(1)", "310.16")',
      },
      'year': {
        'type': 'string',
        'description': 'NEC year',
      },
    },
    'required': ['article'],
  },
  execute: (args) async {
    return {
      'article': args['article'],
      'title': 'GFCI Protection - Dwelling Units',
      'text': 'All 125-volt through 250-volt receptacles installed in the locations specified in 210.8(A)(1) through (A)(11)...',
      'exceptions': ['Exception No. 1: Receptacles that are not readily accessible...'],
    };
  },
);

// =============================================================================
// JOB MANAGEMENT TOOLS
// =============================================================================

final getJobDetailsTool = AITool(
  name: 'get_job_details',
  description: 'Get detailed information about a specific job.',
  inputSchema: {
    'type': 'object',
    'properties': {
      'job_id': {
        'type': 'string',
        'description': 'Job ID (use "current" for the active job)',
      },
    },
    'required': ['job_id'],
  },
  execute: (args) async {
    // Will be replaced with actual Firestore lookup
    return {
      'job': {
        'id': args['job_id'],
        'title': 'Panel Upgrade - 200A',
        'customer': 'Michael Chen',
        'address': '1847 Oak Street',
        'status': 'inProgress',
        'scheduledStart': '2026-02-01T14:00:00Z',
      },
    };
  },
);

final updateJobTool = AITool(
  name: 'update_job',
  description: 'Update job details, status, or add notes. Requires appropriate permissions.',
  inputSchema: {
    'type': 'object',
    'properties': {
      'job_id': {
        'type': 'string',
        'description': 'Job ID to update',
      },
      'updates': {
        'type': 'object',
        'description': 'Fields to update',
        'properties': {
          'status': {'type': 'string', 'enum': ['draft', 'scheduled', 'inProgress', 'completed', 'onHold']},
          'notes': {'type': 'string'},
          'internalNotes': {'type': 'string'},
        },
      },
    },
    'required': ['job_id', 'updates'],
  },
  execute: (args) async {
    return {
      'success': true,
      'jobId': args['job_id'],
      'updated': args['updates'],
    };
  },
);

final getScheduleTool = AITool(
  name: 'get_schedule',
  description: "Get the user's upcoming jobs and schedule.",
  inputSchema: {
    'type': 'object',
    'properties': {
      'range': {
        'type': 'string',
        'description': 'Time range',
        'enum': ['today', 'tomorrow', 'this_week', 'next_week'],
      },
    },
    'required': ['range'],
  },
  execute: (args) async {
    return {
      'range': args['range'],
      'jobs': [
        {'id': 'job_1', 'title': 'Panel Upgrade', 'time': '2:00 PM', 'customer': 'Michael Chen'},
        {'id': 'job_2', 'title': 'Outlet Installation', 'time': '4:30 PM', 'customer': 'Sarah Wilson'},
      ],
      'count': 2,
    };
  },
);

final openJobTool = AITool(
  name: 'open_job',
  description: 'Navigate to a job detail screen.',
  inputSchema: {
    'type': 'object',
    'properties': {
      'job_id': {
        'type': 'string',
        'description': 'Job ID to open',
      },
    },
    'required': ['job_id'],
  },
  execute: (args) async {
    return {
      'action': 'navigate',
      'destination': 'job',
      'jobId': args['job_id'],
    };
  },
);

// =============================================================================
// CUSTOMER TOOLS
// =============================================================================

final getCustomerInfoTool = AITool(
  name: 'get_customer_info',
  description: 'Get detailed information about a customer.',
  inputSchema: {
    'type': 'object',
    'properties': {
      'customer_id': {
        'type': 'string',
        'description': 'Customer ID',
      },
    },
    'required': ['customer_id'],
  },
  execute: (args) async {
    return {
      'customer': {
        'id': args['customer_id'],
        'name': 'Michael Chen',
        'phone': '(555) 123-4567',
        'address': '1847 Oak Street, Hartford, CT',
        'jobCount': 3,
        'totalRevenue': 4250.00,
        'notes': 'Prefers morning appointments',
      },
    };
  },
);

final searchCustomersTool = AITool(
  name: 'search_customers',
  description: 'Search for customers by name, phone, or address.',
  inputSchema: {
    'type': 'object',
    'properties': {
      'query': {
        'type': 'string',
        'description': 'Search query',
      },
    },
    'required': ['query'],
  },
  execute: (args) async {
    return {
      'results': [
        {'id': 'cust_1', 'name': 'Michael Chen', 'phone': '(555) 123-4567'},
      ],
      'count': 1,
    };
  },
);

// =============================================================================
// INVOICE TOOLS
// =============================================================================

final createInvoiceDraftTool = AITool(
  name: 'create_invoice_draft',
  description: 'Create a draft invoice for a job. Returns the draft for review before sending.',
  inputSchema: {
    'type': 'object',
    'properties': {
      'job_id': {
        'type': 'string',
        'description': 'Job ID to create invoice for',
      },
      'line_items': {
        'type': 'array',
        'description': 'Line items for the invoice',
        'items': {
          'type': 'object',
          'properties': {
            'description': {'type': 'string'},
            'quantity': {'type': 'number'},
            'unit_price': {'type': 'number'},
          },
          'required': ['description', 'quantity', 'unit_price'],
        },
      },
      'notes': {
        'type': 'string',
        'description': 'Optional notes for the invoice',
      },
    },
    'required': ['job_id'],
  },
  execute: (args) async {
    return {
      'success': true,
      'action': 'invoice_draft_created',
      'invoiceId': 'inv_draft_001',
      'total': 2850.00,
      'message': 'Draft invoice created. Review and send when ready.',
    };
  },
);

// =============================================================================
// BUSINESS TOOLS
// =============================================================================

final getBusinessMetricsTool = AITool(
  name: 'get_business_metrics',
  description: 'Get business performance metrics. Only available to owners and admins.',
  inputSchema: {
    'type': 'object',
    'properties': {
      'period': {
        'type': 'string',
        'description': 'Time period',
        'enum': ['today', 'this_week', 'this_month', 'this_year'],
      },
    },
    'required': ['period'],
  },
  execute: (args) async {
    // Permission check will be done in the service layer
    return {
      'period': args['period'],
      'revenue': 12450.00,
      'jobsCompleted': 8,
      'averageJobValue': 1556.25,
      'pendingInvoices': 3,
      'outstandingBalance': 2100.00,
    };
  },
);

// =============================================================================
// TOOL RESULT FORMATTING
// =============================================================================

/// Format tool result for display in chat
class ToolResultFormatter {
  static String format(String toolName, Map<String, dynamic> result) {
    if (result.containsKey('error')) {
      return 'Error: ${result['error']}';
    }

    switch (toolName) {
      case 'run_calculation':
        return _formatCalculation(result);
      case 'get_job_details':
        return _formatJob(result);
      case 'get_schedule':
        return _formatSchedule(result);
      case 'search_nec':
        return _formatNecSearch(result);
      default:
        return result.toString();
    }
  }

  static String _formatCalculation(Map<String, dynamic> result) {
    if (result['success'] != true) return 'Calculation failed';
    final calc = result['result'] as Map<String, dynamic>;
    return '''
${result['calculator']} Result:
${calc.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}''';
  }

  static String _formatJob(Map<String, dynamic> result) {
    final job = result['job'] as Map<String, dynamic>;
    return '''
Job: ${job['title']}
Customer: ${job['customer']}
Address: ${job['address']}
Status: ${job['status']}''';
  }

  static String _formatSchedule(Map<String, dynamic> result) {
    final jobs = result['jobs'] as List;
    if (jobs.isEmpty) return 'No jobs scheduled for ${result['range']}';
    return jobs.map((j) => '- ${j['time']}: ${j['title']} (${j['customer']})').join('\n');
  }

  static String _formatNecSearch(Map<String, dynamic> result) {
    final results = result['results'] as List;
    if (results.isEmpty) return 'No NEC articles found';
    return results.map((r) => 'NEC ${r['article']}: ${r['title']}').join('\n');
  }
}
