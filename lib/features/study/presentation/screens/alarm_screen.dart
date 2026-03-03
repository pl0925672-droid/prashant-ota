import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/alarm_provider.dart';
import '../data/models/alarm_model.dart';

class AlarmScreen extends StatelessWidget {
  const AlarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Alarms')),
      body: Consumer<AlarmProvider>(
        builder: (context, alarmProvider, child) {
          final alarms = alarmProvider.alarms;
          return ListView.builder(
            itemCount: alarms.length,
            itemBuilder: (context, index) {
              final alarm = alarms[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    alarm.timeString,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(alarm.label),
                  trailing: Switch(
                    value: alarm.isEnabled,
                    onChanged: (value) => alarmProvider.toggleAlarm(index, value),
                  ),
                  onLongPress: () => alarmProvider.deleteAlarm(index),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAlarmDialog(context),
        child: const Icon(Icons.add_alarm),
      ),
    );
  }

  void _showAddAlarmDialog(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      String? customSound;
      final result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (result != null) {
        customSound = result.files.single.path;
      }

      final newAlarm = AlarmModel(
        id: DateTime.now().millisecondsSinceEpoch % 10000,
        hour: pickedTime.hour,
        minute: pickedTime.minute,
        customSoundPath: customSound,
      );

      // ignore: use_build_context_synchronously
      Provider.of<AlarmProvider>(context, listen: false).addAlarm(newAlarm);
    }
  }
}
