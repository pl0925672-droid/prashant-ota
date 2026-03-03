import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/timer_provider.dart';
import 'package:percent_indicator/percent_indicator.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Timer')),
      body: Consumer<TimerProvider>(
        builder: (context, timer, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _fadeIn(
                  child: TextField(
                    onChanged: (value) => timer.setTopic(value),
                    decoration: InputDecoration(
                      hintText: 'What are you studying today?',
                      prefixIcon: const Icon(Icons.edit_note),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                ScaleTransition(
                  scale: timer.isRunning
                      ? Tween<double>(begin: 1.0, end: 1.03).animate(_pulseController)
                      : const AlwaysStoppedAnimation(1.0),
                  child: CircularPercentIndicator(
                    radius: 120.0,
                    lineWidth: 13.0,
                    animation: false,
                    percent: timer.percent,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          timer.timerString,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 40.0),
                        ),
                        if (timer.currentTopic.isNotEmpty)
                          Text(
                            timer.currentTopic,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    circularStrokeCap: CircularStrokeCap.round,
                    progressColor: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 40),
                _fadeIn(
                  delay: 0.2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAnimatedButton(
                        label: 'Start',
                        color: Colors.green,
                        icon: Icons.play_arrow,
                        onPressed: timer.isRunning ? null : () => timer.startTimer(),
                      ),
                      const SizedBox(width: 20),
                      _buildAnimatedButton(
                        label: 'Stop',
                        color: Colors.red,
                        icon: Icons.stop,
                        onPressed: timer.isRunning ? () => timer.stopTimer() : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _fadeIn(
                  delay: 0.4,
                  child: TextButton.icon(
                    onPressed: () => timer.resetTimer(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Timer'),
                  ),
                ),
                const SizedBox(height: 40),
                _fadeIn(
                  delay: 0.6,
                  child: Column(
                    children: [
                      const Text('Select Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ToggleButtons(
                        borderRadius: BorderRadius.circular(15),
                        isSelected: [
                          timer.mode == TimerMode.pomodoro,
                          timer.mode == TimerMode.countdown,
                          timer.mode == TimerMode.stopwatch,
                        ],
                        onPressed: (index) {
                          timer.setMode(TimerMode.values[index]);
                        },
                        children: const [
                          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Pomodoro')),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Countdown')),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Stopwatch')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedButton({required String label, required Color color, required IconData icon, VoidCallback? onPressed}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed == null ? Colors.grey.shade300 : color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  Widget _fadeIn({required Widget child, double delay = 0.0}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Interval(delay.clamp(0.0, 1.0), 1.0, curve: Curves.easeOut),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
