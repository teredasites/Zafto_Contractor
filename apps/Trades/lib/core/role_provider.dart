import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zafto/core/user_role.dart';

// Current role state — will be driven by auth/profile in production
final currentRoleProvider = StateProvider<UserRole>((ref) => UserRole.owner);
