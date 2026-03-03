import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prashant/features/social/data/friend_repository.dart';

class SnapCameraScreen extends StatefulWidget {
  const SnapCameraScreen({super.key});

  @override
  State<SnapCameraScreen> createState() => _SnapCameraScreenState();
}

class _SnapCameraScreenState extends State<SnapCameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.high);
      await _controller!.initialize();
      if (mounted) setState(() => _isReady = true);
    }
  }

  Future<void> _takeSnap() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final XFile photo = await _controller!.takePicture();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SnapPreviewScreen(imagePath: photo.path),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takeSnap,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 5)),
                  child: const Center(child: CircleAvatar(radius: 30, backgroundColor: Colors.white)),
                ),
              ),
            ),
          ),
          Positioned(top: 40, left: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context))),
        ],
      ),
    );
  }
}

class SnapPreviewScreen extends StatefulWidget {
  final String imagePath;
  const SnapPreviewScreen({super.key, required this.imagePath});

  @override
  State<SnapPreviewScreen> createState() => _SnapPreviewScreenState();
}

class _SnapPreviewScreenState extends State<SnapPreviewScreen> {
  final _friendRepository = FriendRepository();
  final List<String> _selectedFriends = [];
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Image.file(File(widget.imagePath), fit: BoxFit.cover, height: double.infinity, width: double.infinity),
          _buildFriendPicker(),
          Positioned(
            bottom: 40,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: _selectedFriends.isEmpty || _isSending ? null : _sendToAll,
              label: _isSending ? const CircularProgressIndicator(color: Colors.white) : const Text('Send Snap 🚀'),
              icon: const Icon(Icons.send),
              backgroundColor: Colors.yellow.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendPicker() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;

    return DraggableScrollableSheet(
      initialChildSize: 0.15,
      minChildSize: 0.1,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const Padding(padding: EdgeInsets.all(16.0), child: Text("Send To Friends", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _friendRepository.getMyFriends(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final friends = snapshot.data!;
                    if (friends.isEmpty) return const Center(child: Text("Add friends first!"));

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friendRow = friends[index];
                        final String friendId = friendRow['user_id'] == userId ? friendRow['friend_id'] : friendRow['user_id'];

                        // Fetching real name for each friend ID
                        return FutureBuilder<Map<String, dynamic>>(
                          future: supabase.from('profiles').select().eq('id', friendId).single(),
                          builder: (context, profileSnapshot) {
                            final name = profileSnapshot.data?['username'] ?? "Friend";
                            return CheckboxListTile(
                              title: Text(name),
                              secondary: CircleAvatar(backgroundImage: NetworkImage(profileSnapshot.data?['avatar_url'] ?? 'https://via.placeholder.com/150')),
                              value: _selectedFriends.contains(friendId),
                              onChanged: (val) {
                                setState(() {
                                  if (val!) { _selectedFriends.add(friendId); } else { _selectedFriends.remove(friendId); }
                                });
                              },
                            );
                          }
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendToAll() async {
    setState(() => _isSending = true);
    final supabase = Supabase.instance.client;
    final file = File(widget.imagePath);
    final fileName = 'snap_${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      await supabase.storage.from('snaps').upload(fileName, file);
      final url = supabase.storage.from('snaps').getPublicUrl(fileName);

      for (var fId in _selectedFriends) {
        await supabase.from('messages').insert({
          'sender_id': supabase.auth.currentUser!.id,
          'receiver_id': fId,
          'file_url': url,
          'message_type': 'snap',
          'content': 'New Snap! 🔥',
        });
      }

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Snap sent to friends!')));
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}
