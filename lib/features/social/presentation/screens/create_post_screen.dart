import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prashant/features/social/data/post_repository.dart';
import 'package:prashant/features/social/data/friend_repository.dart';

class CreatePostScreen extends StatefulWidget {
  final File mediaFile;
  final String mediaType;

  const CreatePostScreen({
    super.key,
    required this.mediaFile,
    required this.mediaType,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final _postRepository = PostRepository();
  final _friendRepository = FriendRepository();
  final List<String> _taggedUserIds = [];
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        actions: [
          if (_isUploading)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
          else
            TextButton(
              onPressed: _upload,
              child: const Text('Share', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: widget.mediaType == 'image'
                  ? Image.file(widget.mediaFile, fit: BoxFit.cover)
                  : const Center(child: Icon(Icons.videocam, size: 100)), // Simplified video preview
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _captionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Write a caption...',
                  border: InputBorder.none,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1),
              title: const Text('Tag/Collaborate with Friends'),
              subtitle: Text(_taggedUserIds.isEmpty ? 'None' : '${_taggedUserIds.length} friends tagged'),
              onTap: _showTagFriendPicker,
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }

  void _showTagFriendPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: _friendRepository.getMyFriends(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final friends = snapshot.data!;
          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              final String friendId = friend['user_id'] == Supabase.instance.client.auth.currentUser!.id
                  ? friend['friend_id'] : friend['user_id'];

              return CheckboxListTile(
                title: Text('Friend ID: $friendId'),
                value: _taggedUserIds.contains(friendId),
                onChanged: (val) {
                  setState(() {
                    if (val!) {
                      _taggedUserIds.add(friendId);
                    } else {
                      _taggedUserIds.remove(friendId);
                    }
                  });
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _upload() async {
    setState(() => _isUploading = true);
    try {
      await _postRepository.uploadPost(
        file: widget.mediaFile,
        caption: _captionController.text,
        mediaType: widget.mediaType,
        taggedUserIds: _taggedUserIds,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post Shared Successfully! 🚀')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}
