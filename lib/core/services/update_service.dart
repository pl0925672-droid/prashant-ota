import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  final _supabase = Supabase.instance.client;

  Future<void> checkForUpdates(BuildContext context) async {
    try {
      // 1. Get current app version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      int currentVersionCode = int.parse(packageInfo.buildNumber);

      // 2. Fetch latest version from Supabase
      final response = await _supabase
          .from('app_updates')
          .select()
          .order('version_code', ascending: false)
          .limit(1)
          .single();

      int latestVersionCode = response['version_code'];
      String downloadUrl = response['download_url'];
      String releaseNotes = response['release_notes'] ?? "Bug fixes and improvements.";
      bool isForceUpdate = response['is_force_update'] ?? false;

      // 3. Compare and show dialog if update available
      if (latestVersionCode > currentVersionCode) {
        if (context.mounted) {
          _showUpdateDialog(context, downloadUrl, releaseNotes, isForceUpdate);
        }
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }

  void _showUpdateDialog(BuildContext context, String url, String notes, bool force) {
    showDialog(
      context: context,
      barrierDismissible: !force, // If force update, can't dismiss
      builder: (context) => AlertDialog(
        title: const Text('Update Available! 🚀'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('A new version of Prashant is available. What\'s new:'),
            const SizedBox(height: 10),
            Text(notes, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
          ],
        ),
        actions: [
          if (!force)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe Later'),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
            onPressed: () => _launchURL(url),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
