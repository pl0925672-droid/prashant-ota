import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class NoteViewerScreen extends StatelessWidget {
  final String url;
  final String title;

  const NoteViewerScreen({super.key, required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Implement download logic
            },
          ),
        ],
      ),
      body: url.toLowerCase().endsWith('.pdf')
          ? SfPdfViewer.network(url)
          : Center(child: Image.network(url)),
    );
  }
}
