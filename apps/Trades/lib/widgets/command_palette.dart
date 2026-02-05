/// Command Palette - Design System v2.6
/// Raycast-style quick search and navigation
/// The fast way to get anywhere in the app

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/zafto_colors.dart';
import '../theme/theme_provider.dart';
import '../services/command_registry.dart';

// Screens imports for navigation
import '../screens/jobs/job_create_screen.dart';
import '../screens/invoices/invoice_create_screen.dart';
import '../screens/customers/customer_create_screen.dart';
import '../screens/jobs/jobs_hub_screen.dart';
import '../screens/invoices/invoices_hub_screen.dart';
import '../screens/customers/customers_hub_screen.dart';
import '../screens/settings/settings_screen.dart';

class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key});
  
  /// Show the command palette as a modal
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => const CommandPalette(),
    );
  }

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<AppCommand> _results = [];
  CommandType? _filterType;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSuggested();
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _loadSuggested() {
    final registry = ref.read(commandRegistryProvider);
    setState(() {
      _results = registry.getSuggested(limit: 8);
    });
  }

  void _search(String query) {
    final registry = ref.read(commandRegistryProvider);
    setState(() {
      _results = registry.search(query, filterType: _filterType, limit: 15);
      _selectedIndex = 0;
    });
  }

  void _setFilter(CommandType? type) {
    setState(() {
      _filterType = type;
      _selectedIndex = 0;
    });
    _search(_searchController.text);
  }

  void _executeCommand(AppCommand command) {
    HapticFeedback.lightImpact();
    Navigator.pop(context); // Close palette first
    
    // Handle navigation based on command ID
    _navigateToCommand(command);
  }

  void _navigateToCommand(AppCommand command) {
    final nav = Navigator.of(context);
    
    switch (command.id) {
      // Quick Actions
      case 'action_new_job':
        nav.push(MaterialPageRoute(builder: (_) => const JobCreateScreen()));
        break;
      case 'action_new_invoice':
        nav.push(MaterialPageRoute(builder: (_) => const InvoiceCreateScreen()));
        break;
      case 'action_new_customer':
        nav.push(MaterialPageRoute(builder: (_) => const CustomerCreateScreen()));
        break;
        
      // Business Hubs
      case 'jobs_hub':
        nav.push(MaterialPageRoute(builder: (_) => const JobsHubScreen()));
        break;
      case 'invoices_hub':
        nav.push(MaterialPageRoute(builder: (_) => const InvoicesHubScreen()));
        break;
      case 'customers_hub':
        nav.push(MaterialPageRoute(builder: (_) => const CustomersHubScreen()));
        break;
        
      // Settings
      case 'settings_main':
      case 'settings_theme':
      case 'settings_state':
      case 'settings_profile':
        nav.push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
        break;
        
      // For other commands, we'd need to add routes
      // This can be expanded as needed
      default:
        // Show coming soon for unimplemented routes
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening ${command.title}...')),
        );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: colors.bgBase,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(colors),
          _buildSearchBar(colors),
          _buildFilters(colors),
          Expanded(child: _buildResults(colors)),
          _buildFooter(colors),
        ],
      ),
    );
  }

  Widget _buildHandle(ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: colors.fillDefault,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSearchBar(ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        style: TextStyle(color: colors.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search commands, calculators, reference...',
          hintStyle: TextStyle(color: colors.textQuaternary),
          prefixIcon: Icon(LucideIcons.search, color: colors.textTertiary, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(LucideIcons.x, color: colors.textTertiary, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _loadSuggested();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (query) {
          if (query.isEmpty) {
            _loadSuggested();
          } else {
            _search(query);
          }
        },
      ),
    );
  }

  Widget _buildFilters(ZaftoColors colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip(colors, null, 'All', LucideIcons.layoutGrid),
          _buildFilterChip(colors, CommandType.action, 'Actions', LucideIcons.zap),
          _buildFilterChip(colors, CommandType.calculator, 'Calculators', LucideIcons.calculator),
          _buildFilterChip(colors, CommandType.reference, 'Reference', LucideIcons.bookOpen),
          _buildFilterChip(colors, CommandType.examPrep, 'Exam', LucideIcons.graduationCap),
          _buildFilterChip(colors, CommandType.diagram, 'Diagrams', LucideIcons.gitFork),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ZaftoColors colors, CommandType? type, String label, IconData icon) {
    final isSelected = _filterType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _setFilter(type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentPrimary.withValues(alpha: 0.15) : colors.fillDefault,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? colors.accentPrimary : colors.borderSubtle,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSelected ? colors.accentPrimary : colors.textTertiary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? colors.accentPrimary : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(ZaftoColors colors) {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.searchX, size: 48, color: colors.textQuaternary),
            const SizedBox(height: 12),
            Text('No results found', style: TextStyle(color: colors.textTertiary)),
          ],
        ),
      );
    }

    // Group results by type for better organization
    final grouped = <CommandType, List<AppCommand>>{};
    for (final cmd in _results) {
      grouped.putIfAbsent(cmd.type, () => []).add(cmd);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final command = _results[index];
        final isSelected = index == _selectedIndex;
        
        // Check if this is first item of a new type (for section headers)
        final showHeader = index == 0 || _results[index - 1].type != command.type;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader && _searchController.text.isEmpty) 
              _buildSectionHeader(colors, command.type),
            _buildCommandTile(colors, command, isSelected),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, CommandType type) {
    final label = switch (type) {
      CommandType.action => 'QUICK ACTIONS',
      CommandType.calculator => 'CALCULATORS',
      CommandType.reference => 'REFERENCE',
      CommandType.examPrep => 'EXAM PREP',
      CommandType.diagram => 'DIAGRAMS',
      CommandType.job => 'JOBS',
      CommandType.invoice => 'INVOICES',
      CommandType.customer => 'CUSTOMERS',
      CommandType.settings => 'SETTINGS',
      CommandType.aiScanner => 'AI FEATURES',
    };
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.textTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCommandTile(ZaftoColors colors, AppCommand command, bool isSelected) {
    return GestureDetector(
      onTap: () => _executeCommand(command),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _getTypeColor(colors, command.type).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                command.icon,
                size: 18,
                color: _getTypeColor(colors, command.type),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          command.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      if (command.isPro)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.accentPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: colors.accentPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (command.subtitle != null)
                    Text(
                      command.subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: colors.textQuaternary),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(ZaftoColors colors, CommandType type) {
    return switch (type) {
      CommandType.action => colors.accentPrimary,
      CommandType.calculator => colors.accentInfo,
      CommandType.reference => colors.accentSuccess,
      CommandType.examPrep => Colors.purple,
      CommandType.diagram => Colors.orange,
      CommandType.job => colors.accentInfo,
      CommandType.invoice => colors.accentSuccess,
      CommandType.customer => colors.textSecondary,
      CommandType.settings => colors.textTertiary,
      CommandType.aiScanner => colors.accentPrimary,
    };
  }

  Widget _buildFooter(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.command, size: 12, color: colors.textQuaternary),
          const SizedBox(width: 4),
          Text(
            'Search anywhere in ZAFTO',
            style: TextStyle(fontSize: 12, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// Global shortcut to show command palette
/// Can be called from anywhere: CommandPalette.show(context)
