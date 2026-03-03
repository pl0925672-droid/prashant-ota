import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/friend_repository.dart';

class FriendRequestsScreen extends StatelessWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = FriendRepository();
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(title: const Text('Friend Requests')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: repository.getPendingRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const Center(child: Text('No pending requests'));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return FutureBuilder<Map<String, dynamic>>(
                // Fetch sender details
                future: supabase.from('profiles').select().eq('id', request['user_id']).single(),
                builder: (context, profileSnapshot) {
                  if (!profileSnapshot.hasData) return const SizedBox();
                  final profile = profileSnapshot.data!;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(profile['avatar_url'] ?? 'https://via.placeholder.com/150'),
                    ),
                    title: Text(profile['username'] ?? 'Anonymous'),
                    subtitle: const Text('Sent you a friend request'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => repository.updateRequestStatus(request['id'], 'accepted'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => repository.updateRequestStatus(request['id'], 'rejected'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
