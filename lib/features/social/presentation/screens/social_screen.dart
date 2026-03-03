import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../widgets/chat_item.dart';
import '../widgets/story_circle.dart';
import 'leaderboard_screen.dart';
import 'friend_requests_screen.dart';
import 'snap_camera_screen.dart';
import 'create_story_screen.dart';
import 'story_view_screen.dart';
import '../../data/friend_repository.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final friendRepository = FriendRepository();
  late Stream<List<Map<String, dynamic>>> _usersStream;
  late Stream<List<Map<String, dynamic>>> _storiesStream;

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;

    _usersStream = supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .order('total_study_hours', ascending: false);

    _storiesStream = supabase
        .from('stories')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  Future<void> _pickStoryMedia() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateStoryScreen(
              mediaFile: File(image.path),
              mediaType: 'image',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect & Share', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.orange, size: 28),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SnapCameraScreen())),
          ),
          _buildFriendRequestButton(),
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          SizedBox(
            height: 110,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _storiesStream,
              builder: (context, snapshot) {
                final allStories = snapshot.data ?? [];
                final yesterday = DateTime.now().subtract(const Duration(hours: 24));

                // 1. Group stories by user
                Map<String, List<Map<String, dynamic>>> groupedStories = {};
                for (var story in allStories) {
                  final createdAt = DateTime.parse(story['created_at']);
                  if (createdAt.isBefore(yesterday)) continue;

                  bool isVisible = story['user_id'] == currentUserId ||
                                  story['privacy_type'] == 'public' ||
                                  (story['visible_to'] != null && (story['visible_to'] as List).contains(currentUserId));

                  if (isVisible) {
                    groupedStories.putIfAbsent(story['user_id'], () => []).add(story);
                  }
                }

                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildMyStoryButton(),
                    ...groupedStories.entries.map((entry) {
                      final userId = entry.key;
                      final userStories = entry.value;
                      return FutureBuilder<Map<String, dynamic>>(
                        future: Supabase.instance.client.from('profiles').select().eq('id', userId).single(),
                        builder: (context, profSnapshot) {
                          if (!profSnapshot.hasData) return const SizedBox();
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => StoryViewScreen(stories: userStories)),
                            ),
                            child: StoryCircle(story: {'profiles': profSnapshot.data}),
                          );
                        },
                      );
                    }).toList(),
                  ],
                );
              }
            ),
          ),
          const Divider(height: 1),
          _buildFriendsList(),
        ],
      ),
    );
  }

  Widget _buildMyStoryButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickStoryMedia,
            child: Stack(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white, size: 35),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text('My Story', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFriendRequestButton() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: friendRepository.getPendingRequests(),
      builder: (context, snapshot) {
        int count = snapshot.data?.length ?? 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.person_add_rounded),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendRequestsScreen())),
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.red,
                  child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Find new friends...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        onSubmitted: (value) async {
          final users = await friendRepository.searchUsers(value);
          if (context.mounted) _showUserSearchDialog(context, users);
        },
      ),
    );
  }

  Widget _buildFriendsList() {
    return Expanded(
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _usersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data ?? [];
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(indent: 70, height: 1),
            itemBuilder: (context, index) => ChatItem(user: users[index]),
          );
        },
      ),
    );
  }

  void _showUserSearchDialog(BuildContext context, List<Map<String, dynamic>> users) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Friends'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(user['avatar_url'] ?? 'https://via.placeholder.com/150')),
                title: Text(user['username'] ?? 'User'),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.deepPurple),
                  onPressed: () async {
                    await friendRepository.sendFriendRequest(user['id']);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Friend request sent!')));
                    }
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
