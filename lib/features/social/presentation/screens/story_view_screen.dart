import 'package:flutter/material.dart';
import 'package:story_view/story_view.dart';
import 'package:audioplayers/audioplayers.dart';

class StoryViewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> stories;
  const StoryViewScreen({super.key, required this.stories});

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  final StoryController _controller = StoryController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // Play audio for the first story initially
    _playAudio(0);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _playAudio(int index) async {
    await _audioPlayer.stop();
    if (index < widget.stories.length) {
      final audioUrl = widget.stories[index]['audio_url'];
      if (audioUrl != null) {
        await _audioPlayer.play(UrlSource(audioUrl));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StoryView(
        storyItems: widget.stories.map((story) {
          if (story['media_type'] == 'image') {
            return StoryItem.pageImage(
              url: story['media_url'],
              controller: _controller,
              caption: story['audio_name'] != null
                ? Text("🎵 ${story['audio_name']}", style: const TextStyle(color: Colors.white, backgroundColor: Colors.black54))
                : null,
            );
          } else {
            return StoryItem.pageVideo(
              story['media_url'],
              controller: _controller,
            );
          }
        }).toList(),
        controller: _controller,
        onComplete: () => Navigator.pop(context),
        // FIXED: Updated the onStoryShow callback to match the new package signature
        onStoryShow: (storyItem, index) {
          _playAudio(index);
        },
      ),
    );
  }
}
