import 'package:supabase_flutter/supabase_flutter.dart';

class FriendRepository {
  final _supabase = Supabase.instance.client;

  // Search for users by username
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final res = await _supabase
        .from('profiles')
        .select()
        .ilike('username', '%$query%')
        .limit(10);
    return List<Map<String, dynamic>>.from(res);
  }

  // Send Friend Request
  Future<void> sendFriendRequest(String friendId) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('friendships').insert({
      'user_id': userId,
      'friend_id': friendId,
      'status': 'pending',
    });
  }

  // Get Pending Requests (Sent to me)
  Stream<List<Map<String, dynamic>>> getPendingRequests() {
    final userId = _supabase.auth.currentUser!.id;
    return _supabase
        .from('friendships')
        .stream(primaryKey: ['id'])
        .map((event) => event.where((m) => m['friend_id'] == userId && m['status'] == 'pending').toList());
  }

  // Accept/Reject Request
  Future<void> updateRequestStatus(int id, String status) async {
    await _supabase.from('friendships').update({'status': status}).eq('id', id);
  }

  // Block/Unblock/Unfriend
  Future<void> unfriend(String friendId) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase
        .from('friendships')
        .delete()
        .or('and(user_id.eq.$userId,friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.$userId)');
  }

  Future<void> blockUser(String targetId) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('friendships').upsert({
      'user_id': userId,
      'friend_id': targetId,
      'status': 'blocked',
    }, onConflict: 'user_id,friend_id');
  }

  Future<void> unblockUser(String targetId) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase
        .from('friendships')
        .delete()
        .eq('user_id', userId)
        .eq('friend_id', targetId)
        .eq('status', 'blocked');
  }

  // Get My Friends List
  Stream<List<Map<String, dynamic>>> getMyFriends() {
    final userId = _supabase.auth.currentUser!.id;
    return _supabase
        .from('friendships')
        .stream(primaryKey: ['id'])
        .map((event) => event.where((m) {
              return (m['user_id'] == userId || m['friend_id'] == userId) && m['status'] == 'accepted';
            }).toList());
  }
}
