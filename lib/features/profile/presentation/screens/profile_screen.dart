import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:prashant/features/auth/providers/auth_provider.dart';
import 'package:prashant/features/auth/presentation/screens/login_screen.dart';
import 'package:prashant/features/social/data/post_repository.dart';
import 'package:prashant/features/social/presentation/screens/create_post_screen.dart';
import 'package:prashant/features/social/presentation/screens/post_detail_screen.dart';
import 'package:prashant/features/social/data/friend_repository.dart';
import 'package:prashant/core/widgets/full_screen_image.dart';
import 'package:prashant/core/widgets/common_avatar.dart';
import 'edit_profile_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PageController _avatarPageController = PageController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final supabase = Supabase.instance.client;
    final String targetUserId = widget.userId ?? authProvider.user?.id ?? '';
    final bool isCurrentUser = targetUserId == authProvider.user?.id;
    final postRepository = PostRepository();
    final friendRepository = FriendRepository();

    if (targetUserId.isEmpty && !authProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle, size: 100, color: Colors.grey),
              const SizedBox(height: 20),
              const Text('Please Login to see your profile'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
                child: const Text('Login / Sign Up'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isCurrentUser ? 'My Profile' : 'Student Profile'),
        actions: [
          if (isCurrentUser) ...[
            IconButton(
              icon: const Icon(Icons.add_box, color: Colors.deepPurple, size: 28),
              onPressed: () => _showUploadOptions(context),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async => await authProvider.signOut(),
            ),
          ] else ...[
            _buildFriendOptions(context, targetUserId, friendRepository),
          ]
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: supabase
            .from('profiles')
            .stream(primaryKey: ['id'])
            .eq('id', targetUserId)
            .map((event) => event.first),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snapshot.data ?? {};

          return DefaultTabController(
            length: 2,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Swipeable Profile Picture & Avatar
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: PageView(
                          controller: _avatarPageController,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (profile['avatar_url'] != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FullScreenImage(
                                        imageUrl: profile['avatar_url'],
                                        title: profile['username'] ?? 'Profile Photo',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: CommonAvatar(url: profile['avatar_url'], radius: 60),
                            ),
                            // Here you could have a distinct bitmoji/avatar if you store it separately,
                            // or just show the same avatar with a different style.
                            // For now, let's assume bitmoji_url is another column or just show a fallback.
                            Center(
                              child: CommonAvatar(
                                url: profile['bitmoji_url'] ?? 'https://api.dicebear.com/7.x/bottts/svg?seed=${profile['username']}',
                                radius: 60,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        profile['username'] ?? 'User Name',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      if (profile['bio'] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                          child: Text(
                            profile['bio'],
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      if (isCurrentUser)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EditProfileScreen(currentProfile: profile)),
                            );
                          },
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit Profile'),
                        ),
                      const SizedBox(height: 20),
                      _buildStatsRow(profile),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                const SliverAppBar(
                  pinned: true,
                  toolbarHeight: 0,
                  bottom: TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.grid_on)),
                      Tab(icon: Icon(Icons.history_edu)),
                    ],
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _buildPostsGrid(targetUserId, postRepository),
                  const Center(child: Text('Stories & Highlights Coming Soon')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFriendOptions(BuildContext context, String friendId, FriendRepository repo) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'unfriend') {
          await repo.unfriend(friendId);
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unfriended successfully')));
        } else if (value == 'block') {
          await repo.blockUser(friendId);
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User blocked')));
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'unfriend', child: Text('Unfriend')),
        const PopupMenuItem(value: 'block', child: Text('Block User')),
      ],
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('Study', '${profile['total_study_hours']?.toStringAsFixed(1) ?? 0}h'),
        _buildStatItem('Screen', '${profile['current_screen_time'] ?? 0}m'),
        _buildStatItem('Streak', '7 Days'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildPostsGrid(String userId, PostRepository repo) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: repo.getUserPostsStream(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final posts = snapshot.data!;
        if (posts.isEmpty) return const Center(child: Text('No posts yet'));

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
                );
              },
              child: Image.network(post['media_url'], fit: BoxFit.cover),
            );
          },
        );
      },
    );
  }

  void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo'),
              onTap: () async {
                final picker = ImagePicker();
                final image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null && context.mounted) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreatePostScreen(mediaFile: File(image.path), mediaType: 'image')
                    )
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Video'),
              onTap: () async {
                final picker = ImagePicker();
                final video = await picker.pickVideo(source: ImageSource.gallery);
                if (video != null && context.mounted) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreatePostScreen(mediaFile: File(video.path), mediaType: 'video')
                    )
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
