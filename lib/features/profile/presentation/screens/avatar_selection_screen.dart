import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';

class AvatarSelectionScreen extends StatefulWidget {
  const AvatarSelectionScreen({super.key});

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  final _supabase = Supabase.instance.client;
  String _seed = "Prashant";
  String _currentStyle = "avataaars";
  bool _isSaving = false;

  final List<String> _styles = [
    "avataaars",
    "adventurer",
    "bottts",
    "pixel-art",
    "big-smile",
    "lorelei"
  ];

  String get _avatarUrl => 'https://api.dicebear.com/7.x/$_currentStyle/svg?seed=$_seed';

  void _generateRandom() {
    setState(() {
      _seed = Random().nextInt(100000).toString();
    });
  }

  Future<void> _saveAvatar() async {
    setState(() => _isSaving = true);
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Update profile with the SVG URL
      await _supabase.from('profiles').update({
        'avatar_url': _avatarUrl,
      }).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar Updated Successfully! 🔥')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Your Avatar')),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.deepPurple, width: 4),
                color: Colors.grey[100],
              ),
              child: ClipOval(
                child: SvgPicture.network(
                  _avatarUrl,
                  fit: BoxFit.cover,
                  placeholderBuilder: (context) => const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text('Choose Your Style:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _styles.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(_styles[index]),
                    selected: _currentStyle == _styles[index],
                    selectedColor: Colors.deepPurple.shade100,
                    onSelected: (val) {
                      setState(() => _currentStyle = _styles[index]);
                    },
                  ),
                );
              },
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _generateRandom,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Randomize'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveAvatar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Set as Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
