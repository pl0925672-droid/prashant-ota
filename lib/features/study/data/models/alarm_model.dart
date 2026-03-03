class AlarmModel {
  int id;
  int hour;
  int minute;
  bool isEnabled;
  List<int> repeatDays;
  String? customSoundPath;
  bool vibrate;
  String label;

  AlarmModel({
    required this.id,
    required this.hour,
    required this.minute,
    this.isEnabled = true,
    this.repeatDays = const [],
    this.customSoundPath,
    this.vibrate = true,
    this.label = 'Alarm',
  });

  String get timeString {
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  // Helper method for manual Hive adapter
  void save() {}
  void delete() {}
}
