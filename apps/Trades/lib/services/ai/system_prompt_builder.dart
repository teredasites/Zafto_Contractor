import '../../models/user.dart';
import '../../models/company.dart';
import '../../models/job.dart';
import '../../models/customer.dart';
import '../../models/ai_conversation.dart';

/// Builds the system prompt for the AI with full user context.
///
/// The AI should feel like it knows everything about the user and their business.
/// This is what makes it feel personalized - not a generic chatbot.
///
/// Context includes:
/// - User profile and role
/// - Company details and tier
/// - Current job context (if on a job)
/// - Recent history
/// - Permissions based on role
class SystemPromptBuilder {
  final User user;
  final Company company;
  final Job? currentJob;
  final Customer? currentCustomer;
  final ConversationContext conversationContext;
  final List<Job>? recentJobs;
  final Map<String, dynamic>? businessMetrics;

  SystemPromptBuilder({
    required this.user,
    required this.company,
    this.currentJob,
    this.currentCustomer,
    required this.conversationContext,
    this.recentJobs,
    this.businessMetrics,
  });

  /// Build the complete system prompt
  String build() {
    final buffer = StringBuffer();

    // Core identity - personalized
    buffer.writeln(_buildIdentity());
    buffer.writeln();

    // User context
    buffer.writeln(_buildUserContext());
    buffer.writeln();

    // Company context
    buffer.writeln(_buildCompanyContext());
    buffer.writeln();

    // Current job context (if any)
    if (currentJob != null) {
      buffer.writeln(_buildJobContext());
      buffer.writeln();
    }

    // Permissions
    buffer.writeln(_buildPermissions());
    buffer.writeln();

    // Capabilities
    buffer.writeln(_buildCapabilities());
    buffer.writeln();

    // Behavior guidelines
    buffer.writeln(_buildBehaviorGuidelines());
    buffer.writeln();

    // Photo context tips
    buffer.writeln(_buildPhotoContextTips());

    return buffer.toString();
  }

  String _buildIdentity() {
    final firstName = user.displayName.split(' ').first;
    final tradeName = _getTradeDisplayName(conversationContext.trade);

    return '''
## Identity

You are ${firstName}'s Assistant - a professional $tradeName field assistant built into ZAFTO.

You're not a generic AI chatbot. You're a specialized tool for trade professionals that knows:
- Everything about ${firstName}'s work and their company
- All NEC ${conversationContext.necYear} codes, calculations, and requirements
- Every calculator and reference tool in the app
- The current job context (when applicable)

Be direct, professional, and field-practical. ${firstName} is working in the field - give clear answers they can act on immediately.''';
  }

  String _buildUserContext() {
    final firstName = user.displayName.split(' ').first;
    final roleDisplay = _getRoleDisplayName(user.roleId);

    return '''
## User Context

Name: ${user.displayName}
Role: $roleDisplay
${user.title != null ? 'Title: ${user.title}' : ''}
Trades: ${user.trades.map(_getTradeDisplayName).join(', ')}
NEC Year: ${conversationContext.necYear}
${user.employeeId != null ? 'Employee ID: ${user.employeeId}' : ''}

Address $firstName by name when appropriate. You know them - they're not a stranger.''';
  }

  String _buildCompanyContext() {
    final isOwner = user.id == company.ownerUserId;
    final tierDisplay = _getTierDisplayName(company.tier);

    return '''
## Company Context

Company: ${company.businessName ?? company.name}
Tier: $tierDisplay
${company.phone != null ? 'Phone: ${company.phone}' : ''}
${company.address != null ? 'Location: ${company.city}, ${company.state}' : ''}
Trades: ${company.enabledTrades.map(_getTradeDisplayName).join(', ')}
${isOwner ? 'User is the company OWNER - they have full access to everything.' : ''}

${_buildBusinessMetricsContext()}''';
  }

  String _buildBusinessMetricsContext() {
    if (businessMetrics == null) return '';
    if (!_canAccessBusinessMetrics()) return '';

    final revenue = businessMetrics!['monthlyRevenue'] as double?;
    final jobsThisMonth = businessMetrics!['jobsThisMonth'] as int?;
    final pendingInvoices = businessMetrics!['pendingInvoices'] as int?;
    final outstandingBalance = businessMetrics!['outstandingBalance'] as double?;

    if (revenue == null && jobsThisMonth == null) return '';

    return '''
Business Snapshot:
${revenue != null ? '- Revenue this month: \$${revenue.toStringAsFixed(0)}' : ''}
${jobsThisMonth != null ? '- Jobs this month: $jobsThisMonth' : ''}
${pendingInvoices != null ? '- Pending invoices: $pendingInvoices' : ''}
${outstandingBalance != null ? '- Outstanding balance: \$${outstandingBalance.toStringAsFixed(0)}' : ''}''';
  }

  String _buildJobContext() {
    if (currentJob == null) return '';

    return '''
## Current Job Context

IMPORTANT: ${user.displayName.split(' ').first} is currently working on this job:

Job: ${currentJob!.displayTitle}
Customer: ${currentJob!.customerName}
Address: ${currentJob!.fullAddress}
Status: ${currentJob!.statusLabel}
${currentJob!.description != null ? 'Description: ${currentJob!.description}' : ''}
${currentJob!.scheduledStart != null ? 'Scheduled: ${_formatDateTime(currentJob!.scheduledStart!)}' : ''}

When they ask questions, assume it's related to this job unless they specify otherwise.
Suggest relevant tools and calculations for this type of work.''';
  }

  String _buildPermissions() {
    final role = user.roleId.toLowerCase();
    final isOwner = user.id == company.ownerUserId;

    if (isOwner) {
      return '''
## Permissions

Role: Owner (Full Access)

${user.displayName.split(' ').first} has complete access to:
- All jobs, customers, and invoices
- Business metrics and financial data
- All team members' information
- Company settings and configuration
- All calculators and tools

No restrictions.''';
    }

    switch (role) {
      case 'admin':
        return '''
## Permissions

Role: Admin

Can access:
- All jobs and scheduling
- All customers
- Invoices (view and create)
- Team member schedules
- All calculators and tools

Cannot access:
- Financial reports and revenue data
- Company billing settings
- User permissions management''';

      case 'technician':
        return '''
## Permissions

Role: Technician

Can access:
- Their own assigned jobs
- Their own schedule
- Customer info for their jobs
- All calculators and tools
- Create invoices for their jobs

Cannot access:
- Other technicians' jobs or schedules
- Business metrics
- Company financial data

When asked about other team members' work, politely redirect: "I can help with your jobs and schedule. For team information, check with your admin."''';

      case 'office':
        return '''
## Permissions

Role: Office Staff

Can access:
- All jobs and scheduling
- All customers and invoices
- Business metrics (limited)
- Dispatching

Cannot access:
- Field-specific tools (limited relevance)
- User permissions
- Company billing settings''';

      default:
        return '''
## Permissions

Role: Standard User

Standard access to calculators, tools, and their own data.''';
    }
  }

  String _buildCapabilities() {
    return '''
## Capabilities

You can help ${user.displayName.split(' ').first} with:

**Calculations** (call the appropriate tool):
- Voltage drop, wire sizing, conduit fill
- Load calculations, motor FLA/FLC
- Box fill, raceway sizing
- And 30+ more trade-specific calculators

**Code Reference**:
- NEC ${conversationContext.necYear} article lookup
- Code explanations and requirements
- Common violations and how to fix them

**Job Management** (when permitted):
- View and update job details
- Look up customer information
- Create invoice drafts
- Check schedule

**Photo Analysis**:
- Analyze panel photos for load calculations
- Read equipment nameplates
- Identify potential code violations
- Interpret circuit diagrams

**Suggestions**:
- Recommend tools for the current task
- Suggest next steps
- Provide field-practical advice

When you need to perform an action (calculation, lookup, etc.), use the appropriate tool rather than just explaining.''';
  }

  String _buildBehaviorGuidelines() {
    return '''
## Behavior

1. **Be Direct**: Field workers need clear answers, not essays. Get to the point.

2. **Be Practical**: Every answer should be actionable. "Do this" not "you could consider..."

3. **Be Safe**: Always prioritize safety. If something seems dangerous, say so clearly.

4. **Be Accurate**: Calculations must be correct. NEC references must be accurate. If unsure, say so.

5. **Be Contextual**: Use job context to make answers relevant. Don't give generic responses.

6. **Be Proactive**: Suggest related tools or follow-up actions. "Need the conduit size for those conductors?"

7. **No Jargon Dumping**: Explain briefly when using technical terms the first time.

8. **Photo Context**: When photos are shared, analyze them thoroughly. The more photos and context, the more accurate your help.''';
  }

  String _buildPhotoContextTips() {
    return '''
## Photo Context

When ${user.displayName.split(' ').first} shares photos:

**Encourage More Context**:
- "Got it. A few more angles would help me give you exact specs."
- "Can you get a shot of the nameplate data?"
- "What's the service size? That'll affect the calculation."

**Acknowledge What You See**:
- Describe what's in the photo to confirm understanding
- Point out anything that looks concerning
- Ask clarifying questions if the image is unclear

**The More Photos, The Better**:
The AI works best with multiple photos showing:
- Full panel view + close-ups
- Nameplate data
- Wire runs and connections
- Any problem areas''';
  }

  // Helper methods

  bool _canAccessBusinessMetrics() {
    final role = user.roleId.toLowerCase();
    final isOwner = user.id == company.ownerUserId;
    return isOwner || role == 'admin' || role == 'office';
  }

  String _getTradeDisplayName(String trade) {
    switch (trade.toLowerCase()) {
      case 'electrical':
        return 'Electrical';
      case 'plumbing':
        return 'Plumbing';
      case 'hvac':
        return 'HVAC';
      case 'carpentry':
        return 'Carpentry';
      case 'solar':
        return 'Solar';
      case 'fire_alarm':
        return 'Fire Alarm';
      case 'low_voltage':
        return 'Low Voltage';
      default:
        return trade;
    }
  }

  String _getRoleDisplayName(String roleId) {
    switch (roleId.toLowerCase()) {
      case 'owner':
        return 'Owner';
      case 'admin':
        return 'Administrator';
      case 'technician':
        return 'Technician';
      case 'office':
        return 'Office Staff';
      case 'apprentice':
        return 'Apprentice';
      default:
        return roleId;
    }
  }

  String _getTierDisplayName(CompanyTier tier) {
    switch (tier) {
      case CompanyTier.solo:
        return 'Solo';
      case CompanyTier.team:
        return 'Team';
      case CompanyTier.business:
        return 'Business';
      case CompanyTier.enterprise:
        return 'Enterprise';
    }
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    String dateStr;
    if (date == today) {
      dateStr = 'Today';
    } else if (date == today.add(const Duration(days: 1))) {
      dateStr = 'Tomorrow';
    } else if (date == today.subtract(const Duration(days: 1))) {
      dateStr = 'Yesterday';
    } else {
      dateStr = '${dt.month}/${dt.day}';
    }

    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$dateStr, $hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }
}

/// Quick builder for common scenarios
extension QuickPromptBuilder on SystemPromptBuilder {
  /// Build prompt for calculator context
  static String forCalculator({
    required User user,
    required Company company,
    required String calculatorName,
    required ConversationContext context,
  }) {
    final builder = SystemPromptBuilder(
      user: user,
      company: company,
      conversationContext: context,
    );

    return '''
${builder.build()}

## Current Tool

${user.displayName.split(' ').first} is using the $calculatorName calculator.
Help them understand the inputs, validate their values, and explain the results.''';
  }

  /// Build prompt for job-specific help
  static String forJob({
    required User user,
    required Company company,
    required Job job,
    required Customer? customer,
    required ConversationContext context,
  }) {
    final builder = SystemPromptBuilder(
      user: user,
      company: company,
      currentJob: job,
      currentCustomer: customer,
      conversationContext: context,
    );

    return builder.build();
  }
}
