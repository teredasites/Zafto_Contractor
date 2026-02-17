// ZAFTO New Conversation Screen
// Created: Sprint FIELD1 (Session 131)
//
// Pick team members to start a direct or group conversation.
// Shows company team members, search/filter, create group option.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/messaging_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import 'chat_screen.dart';

class NewConversationScreen extends ConsumerStatefulWidget {
  const NewConversationScreen({super.key});

  @override
  ConsumerState<NewConversationScreen> createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends ConsumerState<NewConversationScreen> {
  String _searchQuery = '';
  final Set<String> _selectedIds = {};
  bool _isGroupMode = false;
  final _groupNameController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _startDirectChat(String userId, String userName) async {
    setState(() => _isCreating = true);
    try {
      final conv = await ref.read(messagingActionsProvider.notifier)
          .getOrCreateDirect(userId);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: conv.id,
              title: userName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _createGroupChat() async {
    if (_selectedIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least 2 members')),
      );
      return;
    }

    final name = _groupNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a group name')),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final conv = await ref.read(messagingActionsProvider.notifier).createGroup(
            title: name,
            participantIds: _selectedIds.toList(),
          );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: conv.id,
              title: name,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: $e')),
        );
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(teamMembersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isGroupMode ? 'New Group' : 'New Message'),
        actions: [
          if (!_isGroupMode)
            TextButton(
              onPressed: () => setState(() => _isGroupMode = true),
              child: const Text('Group'),
            ),
          if (_isGroupMode)
            TextButton(
              onPressed: _isCreating ? null : _createGroupChat,
              child: _isCreating
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Group name input (group mode only)
          if (_isGroupMode)
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.group),
                ),
              ),
            ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search team members...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          // Selected chips (group mode)
          if (_isGroupMode && _selectedIds.isNotEmpty)
            SizedBox(
              height: 50,
              child: membersAsync.when(
                data: (members) {
                  final selected = members
                      .where((m) => _selectedIds.contains(m['id']))
                      .toList();
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: selected.map((m) {
                      final name = '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.trim();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(name),
                          onDeleted: () => setState(() => _selectedIds.remove(m['id'])),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          // Member list
          Expanded(
            child: membersAsync.when(
              loading: () => const LoadingState(message: 'Loading team...'),
              error: (error, stack) => ErrorState(
                message: 'Failed to load team members',
                onRetry: () => ref.invalidate(teamMembersProvider),
              ),
              data: (members) {
                final filtered = members.where((m) {
                  if (_searchQuery.isEmpty) return true;
                  final name = '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No team members found'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final member = filtered[index];
                    final name = '${member['first_name'] ?? ''} ${member['last_name'] ?? ''}'.trim();
                    final role = member['role'] as String? ?? '';
                    final id = member['id'] as String;
                    final isSelected = _selectedIds.contains(id);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                        ),
                      ),
                      title: Text(name.isEmpty ? 'Unknown' : name),
                      subtitle: Text(role),
                      trailing: _isGroupMode
                          ? Checkbox(
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedIds.add(id);
                                  } else {
                                    _selectedIds.remove(id);
                                  }
                                });
                              },
                            )
                          : null,
                      onTap: _isGroupMode
                          ? () {
                              setState(() {
                                if (isSelected) {
                                  _selectedIds.remove(id);
                                } else {
                                  _selectedIds.add(id);
                                }
                              });
                            }
                          : () => _startDirectChat(id, name),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
