import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StoryCircle extends StatelessWidget {
  final Map<String, dynamic> story;
  const StoryCircle({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    // Assuming 'story' contains user data or we need to fetch it.
    // For now, let's assume it has 'profiles' data joined or we use a placeholder.
    final avatarUrl = story['profiles']?['avatar_url'] ?? 'https://via.placeholder.com/150';
    final username = story['profiles']?['username'] ?? 'User';

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.orange, Colors.red],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: _buildAvatar(avatarUrl),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            username,
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String url) {
    if (url.contains('.svg') || url.contains('api.dicebear.com')) {
      return SvgPicture.network(
        url,
        width: 54,
        height: 54,
        fit: BoxFit.cover,
        placeholderBuilder: (context) => const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Image.network(
      url,
      width: 54,
      height: 54,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person),
    );
  }
}
