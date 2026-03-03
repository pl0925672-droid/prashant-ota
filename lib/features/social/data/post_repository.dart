import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostRepository {
  final _supabase = Supabase.instance.client;

  Future<void> uploadPost({
    required File file,
    required String caption,
    required String mediaType,
    List<String>? taggedUserIds,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final fileName = 'post_${DateTime.now().millisecondsSinceEpoch}';

    try {
      // 1. Upload to Storage
      await _supabase.storage.from('posts').upload(fileName, file);
      final mediaUrl = _supabase.storage.from('posts').getPublicUrl(fileName);

      // 2. Insert into DB
      await _supabase.from('posts').insert({
        'user_id': userId,
        'media_url': mediaUrl,
        'caption': caption,
        'media_type': mediaType,
        'tagged_user_ids': taggedUserIds ?? [],
      });
    } catch (e) {
      throw "Upload failed: $e";
    }
  }

  Stream<List<Map<String, dynamic>>> getUserPostsStream(String userId) {
    return _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }
}
