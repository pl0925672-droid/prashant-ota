import 'package:supabase_flutter/supabase_flutter.dart';

class GroupRepository {
  final _supabase = Supabase.instance.client;

  // Create a new group
  Future<String?> createGroup(String name, String description, List<String> memberIds) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase.from('groups').insert({
      'name': name,
      'description': description,
      'created_by': userId,
    }).select().single();

    final groupId = response['id'];

    // Add creator as admin
    await _supabase.from('group_members').insert({
      'group_id': groupId,
      'user_id': userId,
      'role': 'admin',
    });

    // Add other members
    for (var mId in memberIds) {
      await _supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': mId,
        'role': 'member',
      });
    }

    return groupId;
  }

  // Stream for Group Messages
  Stream<List<Map<String, dynamic>>> getGroupMessagesStream(String groupId) {
    return _supabase
        .from('group_messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('created_at', ascending: false);
  }

  // Send Message to Group
  Future<void> sendGroupMessage(String groupId, String content) async {
    await _supabase.from('group_messages').insert({
      'group_id': groupId,
      'sender_id': _supabase.auth.currentUser!.id,
      'content': content,
    });
  }

  // Get User's Groups
  Stream<List<Map<String, dynamic>>> getUserGroupsStream() {
    final userId = _supabase.auth.currentUser?.id;
    return _supabase
        .from('group_members')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId ?? '')
        .map((event) => event); // Simplified for now
  }
}
