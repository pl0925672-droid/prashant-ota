import 'package:usage_stats/usage_stats.dart';
import 'dart:io';

class UsageService {
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      bool? isPermissionGranted = await UsageStats.checkUsagePermission();
      if (isPermissionGranted != true) {
        await UsageStats.grantUsagePermission();
        return await UsageStats.checkUsagePermission() ?? false;
      }
      return true;
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> getDetailedAppUsage() async {
    DateTime now = DateTime.now();
    // Start of the day (00:00:00)
    DateTime startDate = DateTime(now.year, now.month, now.day);

    // queryUsageStats can return cumulative data depending on the OS.
    // We fetch and then filter/calculate for the specific interval.
    List<UsageInfo> stats = await UsageStats.queryUsageStats(startDate, now);

    List<Map<String, dynamic>> detailedStats = [];

    for (var info in stats) {
      if (info.packageName == null) continue;

      // totalTimeInForeground can be unreliable on some devices for short intervals.
      // We parse it and convert to minutes.
      int duration = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;

      // Filter out system apps with 0 usage or apps used less than 30 seconds
      if (duration > 30000) {
        detailedStats.add({
          'packageName': info.packageName,
          'appName': info.packageName?.split('.').last ?? "Unknown",
          'usageMinutes': duration ~/ 60000,
        });
      }
    }

    // Merge duplicate package entries (some devices return multiple intervals)
    Map<String, Map<String, dynamic>> merged = {};
    for (var item in detailedStats) {
      String pkg = item['packageName'];
      if (merged.containsKey(pkg)) {
        merged[pkg]!['usageMinutes'] += item['usageMinutes'];
      } else {
        merged[pkg] = Map<String, dynamic>.from(item);
      }
    }

    List<Map<String, dynamic>> finalResult = merged.values.toList();
    finalResult.sort((a, b) => b['usageMinutes'].compareTo(a['usageMinutes']));
    return finalResult;
  }

  Future<int> getTodayTotalScreenTime() async {
    final stats = await getDetailedAppUsage();
    int total = 0;
    for (var item in stats) {
      total += item['usageMinutes'] as int;
    }
    return total;
  }
}
