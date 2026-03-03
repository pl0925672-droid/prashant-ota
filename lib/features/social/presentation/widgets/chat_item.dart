import 'package:flutter/material.dart';
import 'package:prashant/features/profile/presentation/screens/profile_screen.dart';
import 'package:prashant/features/social/presentation/screens/individual_chat_screen.dart';
import 'package:prashant/core/widgets/common_avatar.dart';

class ChatItem extends StatelessWidget {
  final Map<String, dynamic> user;
  const ChatItem({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    bool isOnline = user['is_online'] ?? false;
    String studyStatus = user['current_topic'] ?? "Not studying";
    bool isStudying = user['is_studying'] ?? false;

    return ListTile(
      leading: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfileScreen(userId: user['id'])),
          );
        },
        child: Stack(
          children: [
            CommonAvatar(url: user['avatar_url'], radius: 25),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isStudying ? Colors.orange : (isOnline ? Colors.green : Colors.grey),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: isStudying ? const Icon(Icons.book, size: 8, color: Colors.white) : null,
              ),
            ),
          ],
        ),
      ),
      title: Text(
        user['username'] ?? 'Anonymous',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        isStudying ? "📖 Padh raha hai: $studyStatus" : (isOnline ? "Active now" : "Offline"),
        style: TextStyle(
          color: isStudying ? Colors.orange.shade700 : Colors.grey,
          fontSize: 12,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.deepPurple),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => IndividualChatScreen(friend: user)),
          );
        },
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfileScreen(userId: user['id'])),
        );
      },
    );
  }
}
