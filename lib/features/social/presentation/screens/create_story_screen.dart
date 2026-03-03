import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:prashant/features/social/data/friend_repository.dart';

class CreateStoryScreen extends StatefulWidget {
  final File mediaFile;
  final String mediaType;

  const CreateStoryScreen({
    super.key,
    required this.mediaFile,
    required this.mediaType,
  });

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _supabase = Supabase.instance.client;
  final _friendRepository = FriendRepository();
  final _audioPlayer = AudioPlayer();
  final TextEditingController _mentionController = TextEditingController();

  String? _selectedAudioPath;
  String? _audioName;
  bool _isUploading = false;
  String _privacy = "public";
  List<String> _visibleToUserIds = [];
  List<String> _mentionedUserIds = [];

  @override
  void dispose() {
    _audioPlayer.dispose();
    _mentionController.dispose();
    super.dispose();
  }

  Future<void> _pickMusic() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedAudioPath = result.files.single.path;
        _audioName = result.files.single.name;
      });
      await _audioPlayer.play(DeviceFileSource(_selectedAudioPath!));
    }
  }

  void _showPrivacyPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.public, color: Colors.blue),
            title: const Text('Public (All Friends)'),
            trailing: _privacy == "public" ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () { setState(() => _privacy = "public"); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.red),
            title: const Text('Private (Selected Friends)'),
            trailing: _privacy == "private" ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              Navigator.pop(context);
              _showFriendPicker(isPrivacy: true);
            },
          ),
        ],
      ),
    );
  }

  void _showFriendPicker({required bool isPrivacy}) {
    final currentUserId = _supabase.auth.currentUser!.id;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, scrollController) => StreamBuilder<List<Map<String, dynamic>>>(
          stream: _friendRepository.getMyFriends(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final friendships = snapshot.data!;

            return StatefulBuilder(
              builder: (context, setModalState) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(isPrivacy ? "Select Friends for Privacy" : "Mention Friends", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: friendships.length,
                      itemBuilder: (context, index) {
                        final friendship = friendships[index];
                        final friendId = friendship['user_id'] == currentUserId ? friendship['friend_id'] : friendship['user_id'];

                        return FutureBuilder<Map<String, dynamic>>(
                          future: _supabase.from('profiles').select('username, avatar_url').eq('id', friendId).single(),
                          builder: (context, profSnapshot) {
                            final name = profSnapshot.data?['username'] ?? "Loading...";
                            final isSelected = isPrivacy ? _visibleToUserIds.contains(friendId) : _mentionedUserIds.contains(friendId);
                            return CheckboxListTile(
                              title: Text(name),
                              value: isSelected,
                              onChanged: (val) {
                                setModalState(() {
                                  if (isPrivacy) {
                                    if (val!) { _visibleToUserIds.add(friendId); } else { _visibleToUserIds.remove(friendId); }
                                    setState(() { _privacy = "private"; });
                                  } else {
                                    if (val!) { _mentionedUserIds.add(friendId); } else { _mentionedUserIds.remove(friendId); }
                                  }
                                });
                              },
                            );
                          }
                        );
                      },
                    ),
                  ),
                  ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Done")),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _uploadStory() async {
    setState(() => _isUploading = true);
    final userId = _supabase.auth.currentUser!.id;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    try {
      final mediaName = 'story_$timestamp.${widget.mediaFile.path.split('.').last}';
      await _supabase.storage.from('stories').upload(mediaName, widget.mediaFile);
      final mediaUrl = _supabase.storage.from('stories').getPublicUrl(mediaName);

      String? audioUrl;
      if (_selectedAudioPath != null) {
        final audioName = 'audio_$timestamp.mp3';
        await _supabase.storage.from('stories').upload(audioName, File(_selectedAudioPath!));
        audioUrl = _supabase.storage.from('stories').getPublicUrl(audioName);
      }

      await _supabase.from('stories').insert({
        'user_id': userId,
        'media_url': mediaUrl,
        'media_type': widget.mediaType,
        'audio_url': audioUrl,
        'audio_name': _audioName,
        'privacy_type': _privacy,
        'visible_to': _privacy == "private" ? _visibleToUserIds : null,
        'mentioned_users': _mentionedUserIds,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Story Shared! ✨')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _uploadStory,
            child: _isUploading
              ? const CircularProgressIndicator()
              : const Text('Share', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(child: widget.mediaType == 'image' ? Image.file(widget.mediaFile) : const Icon(Icons.videocam, color: Colors.white, size: 100)),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Wrap(
                  spacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickMusic,
                      icon: const Icon(Icons.music_note),
                      label: Text(_audioName != null ? "Music added" : "Add Music"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showPrivacyPicker,
                      icon: const Icon(Icons.privacy_tip),
                      label: Text(_privacy.toUpperCase()),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showFriendPicker(isPrivacy: false),
                      icon: const Icon(Icons.alternate_email),
                      label: Text(_mentionedUserIds.isEmpty ? "Mention" : "${_mentionedUserIds.length} Mentioned"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
