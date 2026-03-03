import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prashant/features/social/data/social_repository.dart';
import 'package:prashant/features/social/presentation/screens/snap_camera_screen.dart';
import 'package:prashant/features/social/presentation/screens/snap_view_screen.dart';
import 'package:prashant/features/profile/presentation/screens/profile_screen.dart';
import 'package:prashant/core/widgets/common_avatar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class IndividualChatScreen extends StatefulWidget {
  final Map<String, dynamic> friend;
  const IndividualChatScreen({super.key, required this.friend});

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final SocialRepository _socialRepository = SocialRepository();
  final String _currentUserId = Supabase.instance.client.auth.currentUser!.id;

  String get _chatRoomId {
    List<String> ids = [_currentUserId, widget.friend['id']];
    ids.sort();
    return ids.join('_');
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _socialRepository.sendMessage(
        receiverId: widget.friend['id'],
        content: "Sent a photo",
        filePath: image.path,
        type: 'image',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: widget.friend['id'])));
          },
          child: Row(
            children: [
              CommonAvatar(url: widget.friend['avatar_url'], radius: 20),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.friend['username'] ?? 'Chat', style: const TextStyle(fontSize: 16)),
                  Text(widget.friend['is_online'] == true ? 'Online' : 'Offline',
                    style: const TextStyle(fontSize: 12, color: Colors.green)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: Colors.orange),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SnapCameraScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _socialRepository.getMessagesStream(_chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    bool isMe = msg['sender_id'] == _currentUserId;
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          if (msg['message_type'] == 'snap' && msg['file_url'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SnapViewScreen(url: msg['file_url'])),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? Colors.deepPurple : Colors.grey[200],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (msg['message_type'] == 'snap')
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text('Snap (Tap to View)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                )
              else if (msg['file_url'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(msg['file_url'], width: 200),
                  ),
                ),
              if (msg['message_type'] != 'snap')
                Text(
                  msg['content'] ?? '',
                  style: TextStyle(color: isMe ? Colors.white : Colors.black),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.add_photo_alternate, color: Colors.deepPurple), onPressed: _pickMedia),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.deepPurple),
            onPressed: () {
              if (_messageController.text.isNotEmpty) {
                _socialRepository.sendMessage(
                  receiverId: widget.friend['id'],
                  content: _messageController.text,
                );
                _messageController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
