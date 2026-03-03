import 'package:flutter/material.dart';

class SnapViewScreen extends StatefulWidget {
  final String url;
  const SnapViewScreen({super.key, required this.url});

  @override
  State<SnapViewScreen> createState() => _SnapViewScreenState();
}

class _SnapViewScreenState extends State<SnapViewScreen> {
  @override
  void initState() {
    super.initState();
    // Auto close after 10 seconds like Snapchat
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Image.network(
              widget.url,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const CircularProgressIndicator(color: Colors.yellow);
              },
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Snap will close in 10s',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
