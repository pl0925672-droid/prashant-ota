import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'core/app_theme.dart';
import 'features/study/providers/timer_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/study/providers/alarm_provider.dart';
import 'features/study/data/models/alarm_model.dart';
import 'features/onboarding/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Alarm Manager
  await AndroidAlarmManager.initialize();

  // Initialize Hive
  await Hive.initFlutter();

  // Registering a manual adapter since we can't run build_runner here easily
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(AlarmModelAdapter());
  }

  await Hive.openBox('settings');
  await Hive.openBox('study_logs');
  await Hive.openBox<AlarmModel>('alarms');

  // Initialize Supabase with your credentials
  await Supabase.initialize(
    url: 'https://imhgjaiqvnkyjwyolccf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImltaGdqYWlxdm5reWp3eW9sY2NmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxNTkxNjMsImV4cCI6MjA4NzczNTE2M30.3TGUoD9x_LTpB54jwTmKy58_CxPAHaAvLn7EDSBFViQ',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AlarmProvider()),
      ],
      child: const PrashantApp(),
    ),
  );
}

class PrashantApp extends StatelessWidget {
  const PrashantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prashant Productivity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}

// Manual Hive Adapter for AlarmModel
class AlarmModelAdapter extends TypeAdapter<AlarmModel> {
  @override
  final int typeId = 1;

  @override
  AlarmModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlarmModel(
      id: fields[0] as int,
      hour: fields[1] as int,
      minute: fields[2] as int,
      isEnabled: fields[3] as bool,
      repeatDays: (fields[4] as List).cast<int>(),
      customSoundPath: fields[5] as String?,
      vibrate: fields[6] as bool,
      label: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AlarmModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.hour)
      ..writeByte(2)
      ..write(obj.minute)
      ..writeByte(3)
      ..write(obj.isEnabled)
      ..writeByte(4)
      ..write(obj.repeatDays)
      ..writeByte(5)
      ..write(obj.customSoundPath)
      ..writeByte(6)
      ..write(obj.vibrate)
      ..writeByte(7)
      ..write(obj.label);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
