import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'note_viewer_screen.dart'; // Import Note Viewer

class NotesMarketplaceScreen extends StatefulWidget {
  const NotesMarketplaceScreen({super.key});

  @override
  State<NotesMarketplaceScreen> createState() => _NotesMarketplaceScreenState();
}

class _NotesMarketplaceScreenState extends State<NotesMarketplaceScreen> {
  final _supabase = Supabase.instance.client;
  bool _isUploading = false;

  Future<void> _showUploadDialog() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );

    if (result != null && mounted) {
      final File file = File(result.files.single.path!);
      final String defaultName = result.files.single.name;
      final TextEditingController nameController = TextEditingController(text: defaultName);
      final TextEditingController subjectController = TextEditingController();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Upload Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Note Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Subject (Optional)', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _performUpload(file, nameController.text, subjectController.text);
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _performUpload(File file, String name, String subject) async {
    setState(() => _isUploading = true);
    try {
      final fileName = 'note_${DateTime.now().millisecondsSinceEpoch}_$name';
      await _supabase.storage.from('notes').upload(fileName, file);
      final url = _supabase.storage.from('notes').getPublicUrl(fileName);

      await _supabase.from('notes').insert({
        'title': name,
        'file_url': url,
        'user_id': _supabase.auth.currentUser!.id,
        'subject': subject.isEmpty ? 'General' : subject,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note uploaded successfully! 📚')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes Marketplace')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase.from('notes').stream(primaryKey: ['id']).order('created_at'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notes = snapshot.data ?? [];
          if (notes.isEmpty) return const Center(child: Text('No notes available yet.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.description, color: Colors.blue, size: 30),
                  title: Text(note['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Subject: ${note['subject']}'),
                  trailing: const Icon(Icons.remove_red_eye, color: Colors.deepPurple), // View Icon
                  onTap: () {
                    // Open Note Viewer without download
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NoteViewerScreen(url: note['file_url'], title: note['title']),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _showUploadDialog,
        label: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text('Upload Note'),
        icon: const Icon(Icons.upload_file),
      ),
    );
  }
}
