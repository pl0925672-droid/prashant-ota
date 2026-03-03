import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SocialRepository {
  final _supabase = Supabase.instance.client;

  // Real-time Messages
  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatRoomId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id']) // Fixed: changed primary_key to primaryKey
        .order('created_at', ascending: false);
  }

  Future<void> sendMessage({
    required String receiverId,
    required String content,
    String? filePath,
    String? type,
  }) async {
    String? fileUrl;
    final userId = _supabase.auth.currentUser!.id;

    if (filePath != null) {
      final file = File(filePath);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      await _supabase.storage.from('chat_media').upload(fileName, file);
      fileUrl = _supabase.storage.from('chat_media').getPublicUrl(fileName);
    }

    await _supabase.from('messages').insert({
      'sender_id': userId,
      'receiver_id': receiverId,
      'content': content,
      'file_url': fileUrl,
      'message_type': type ?? 'text',
    });
  }

  // Stories
  Future<void> deleteStory(String storyId) async {
    await _supabase.from('stories').delete().eq('id', storyId);
  }

  // Status
  Future<void> updateStatus(bool isOnline) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _supabase.from('profiles').update({
        'is_online': isOnline,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    }
  }
}
