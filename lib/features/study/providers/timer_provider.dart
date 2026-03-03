import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum TimerMode { pomodoro, countdown, stopwatch }

class TimerProvider with ChangeNotifier {
  Timer? _timer;
  int _seconds = 1500;
  int _initialSeconds = 1500;
  bool _isRunning = false;
  TimerMode _mode = TimerMode.pomodoro;
  String _currentTopic = "";

  int get seconds => _seconds;
  bool get isRunning => _isRunning;
  TimerMode get mode => _mode;
  String get currentTopic => _currentTopic;

  double get percent {
    if (_mode == TimerMode.stopwatch) return 1.0;
    if (_initialSeconds == 0) return 0.0;
    return _seconds / _initialSeconds;
  }

  String get timerString {
    int minutes = _seconds ~/ 60;
    int seconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void setTopic(String topic) {
    _currentTopic = topic;
    notifyListeners();
  }

  void setMode(TimerMode mode) {
    _mode = mode;
    _isRunning = false;
    _timer?.cancel();
    if (mode == TimerMode.pomodoro) {
      _seconds = 1500;
      _initialSeconds = 1500;
    } else if (mode == TimerMode.countdown) {
      _seconds = 600;
      _initialSeconds = 600;
    } else {
      _seconds = 0;
      _initialSeconds = 0;
    }
    notifyListeners();
  }

  void startTimer() async {
    if (_isRunning) return;
    _isRunning = true;

    // Optional: Update online status if possible
    try {
      await _updateStudyStatus(true);
    } catch (_) {}

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_mode == TimerMode.stopwatch) {
        _seconds++;
      } else {
        if (_seconds > 0) {
          _seconds--;
        } else {
          stopTimer();
        }
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void stopTimer() async {
    if (!_isRunning) return;
    _isRunning = false;
    _timer?.cancel();

    try {
      await _updateStudyStatus(false);
    } catch (_) {}

    await _logStudySession();
    notifyListeners();
  }

  void resetTimer() {
    stopTimer();
    setMode(_mode);
  }

  Future<void> _updateStudyStatus(bool studying) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      await supabase.from('profiles').update({
        'is_studying': studying,
        'current_topic': studying ? _currentTopic : null,
      }).eq('id', userId);
    }
  }

  Future<void> _logStudySession() async {
    int durationMinutes = 0;
    if (_mode == TimerMode.stopwatch) {
      durationMinutes = _seconds ~/ 60;
    } else {
      durationMinutes = (_initialSeconds - _seconds) ~/ 60;
    }

    if (durationMinutes > 0) {
      // 1. Always log to local Hive box (Offline Support)
      final studyBox = Hive.box('study_logs');
      final logData = {
        'subject': 'General',
        'topic': _currentTopic,
        'duration_minutes': durationMinutes,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await studyBox.add(logData);

      // 2. Try to sync with Supabase if online
      try {
        final supabase = Supabase.instance.client;
        final userId = supabase.auth.currentUser?.id;
        if (userId != null) {
          await supabase.from('study_logs').insert({
            'user_id': userId,
            'subject': 'General',
            'topic': _currentTopic,
            'duration_minutes': durationMinutes,
          });

          final profile = await supabase.from('profiles').select('total_study_hours').eq('id', userId).single();
          double currentHours = (profile['total_study_hours'] ?? 0).toDouble();
          await supabase.from('profiles').update({
            'total_study_hours': currentHours + (durationMinutes / 60.0),
          }).eq('id', userId);
        }
      } catch (e) {
        debugPrint("Supabase logging failed (User might be offline): $e");
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
