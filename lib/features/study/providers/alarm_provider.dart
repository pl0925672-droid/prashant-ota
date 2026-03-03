import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../data/models/alarm_model.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';

class AlarmProvider with ChangeNotifier {
  final Box<AlarmModel> _alarmBox = Hive.box<AlarmModel>('alarms');
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<AlarmModel> get alarms => _alarmBox.values.toList();

  Future<void> addAlarm(AlarmModel alarm) async {
    await _alarmBox.add(alarm);
    if (alarm.isEnabled) {
      await _scheduleAlarm(alarm);
    }
    notifyListeners();
  }

  Future<void> toggleAlarm(int index, bool enabled) async {
    final alarm = _alarmBox.getAt(index);
    if (alarm != null) {
      alarm.isEnabled = enabled;
      // Note: Manual update for non-HiveObject
      await _alarmBox.putAt(index, alarm);
      if (enabled) {
        await _scheduleAlarm(alarm);
      } else {
        await AndroidAlarmManager.cancel(alarm.id);
      }
      notifyListeners();
    }
  }

  Future<void> deleteAlarm(int index) async {
    final alarm = _alarmBox.getAt(index);
    if (alarm != null) {
      await AndroidAlarmManager.cancel(alarm.id);
      await _alarmBox.deleteAt(index);
      notifyListeners();
    }
  }

  Future<void> _scheduleAlarm(AlarmModel alarm) async {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await AndroidAlarmManager.oneShotAt(
      scheduledTime,
      alarm.id,
      alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  @pragma('vm:entry-point')
  static void alarmCallback() {
    debugPrint("Alarm Fired!");
  }

  Future<void> playCustomSound(String path) async {
    await _audioPlayer.play(DeviceFileSource(path));
  }

  void stopSound() {
    _audioPlayer.stop();
  }
}
