import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CommonAvatar extends StatelessWidget {
  final String? url;
  final double radius;

  const CommonAvatar({super.key, this.url, this.radius = 25});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, size: radius, color: Colors.grey[600]),
      );
    }

    // Check if it's a DiceBear SVG avatar
    if (url!.contains('api.dicebear.com') || url!.endsWith('.svg')) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: ClipOval(
          child: SvgPicture.network(
            url!,
            fit: BoxFit.cover,
            placeholderBuilder: (context) => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    // Regular Image
    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(url!),
      backgroundColor: Colors.grey[200],
    );
  }
}
