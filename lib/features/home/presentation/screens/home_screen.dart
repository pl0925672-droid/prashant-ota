import 'package:flutter/material.dart';
import 'package:prashant/features/home/presentation/widgets/ai_insight_card.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:prashant/features/ai/presentation/screens/study_planner_screen.dart';
import 'package:prashant/features/social/presentation/screens/notes_marketplace_screen.dart';
import 'package:prashant/features/wellbeing/data/usage_service.dart';
import 'package:prashant/features/ai/presentation/screens/ai_buddy_screen.dart';
import 'package:prashant/core/services/update_service.dart'; // Import
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final UsageService _usageService = UsageService();
  final UpdateService _updateService = UpdateService(); // Instance
  int _studyMinutes = 0;
  int _screenMinutes = 0;
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadStats();

    // Auto check for updates on launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateService.checkForUpdates(context);
    });
  }

  Future<void> _loadStats() async {
    if (mounted) setState(() => _isLoading = true);

    final studyBox = Hive.box('study_logs');
    int todayStudy = 0;
    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    for (var log in studyBox.values) {
      if (log is Map && log['duration_minutes'] != null && log['timestamp'] != null) {
        String logDate = log['timestamp'].toString().split('T')[0];
        if (logDate == todayStr) {
          todayStudy += (log['duration_minutes'] as int);
        }
      }
    }

    int screenTime = await _usageService.getTodayTotalScreenTime();

    if (mounted) {
      setState(() {
        _studyMinutes = todayStudy;
        _screenMinutes = screenTime;
        _isLoading = false;
      });
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double totalTime = (_studyMinutes + _screenMinutes).toDouble();
    double productivityPercent = totalTime > 0 ? _studyMinutes / totalTime : 0.0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fadeIn(
                child: const Text(
                  'Hello!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              _fadeIn(delay: 0.2, child: const Text('Track your productivity for today.')),
              const SizedBox(height: 25),

              if (!_isLoading)
                _fadeIn(delay: 0.4, child: AIInsightCard(studyMinutes: _studyMinutes, screenMinutes: _screenMinutes)),

              const SizedBox(height: 25),

              _fadeIn(delay: 0.6, child: const Text('Explore Features', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(height: 15),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 1.2,
                children: [
                  _scaleIn(delay: 0.7, child: _buildFeatureCard(context, 'AI Planner', 'Study Schedule', Icons.auto_awesome, Colors.deepPurple, const StudyPlannerScreen())),
                  _scaleIn(delay: 0.8, child: _buildFeatureCard(context, 'AI Buddy', 'Doubt Solver', Icons.psychology, Colors.indigo, const AIBuddyScreen())),
                  _scaleIn(delay: 0.9, child: _buildFeatureCard(context, 'Notes Hub', 'Share PDF/Images', Icons.menu_book, Colors.blue, const NotesMarketplaceScreen())),
                  _scaleIn(delay: 1.0, child: _buildFeatureCard(context, 'Social', 'Connect & Chat', Icons.people, Colors.orange, null)),
                ],
              ),

              const SizedBox(height: 30),

              _fadeIn(delay: 1.1, child: const Text('Daily Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _fadeIn(delay: 1.2, child: _buildStatCard(context, 'Study (Today)', '${_studyMinutes ~/ 60}h ${_studyMinutes % 60}m', Icons.book, Colors.green)),
                  _fadeIn(delay: 1.3, child: _buildStatCard(context, 'Screen (Today)', '${_screenMinutes ~/ 60}h ${_screenMinutes % 60}m', Icons.phone_android, Colors.orange)),
                ],
              ),

              const SizedBox(height: 30),

              _fadeIn(
                delay: 1.5,
                child: Center(
                  child: CircularPercentIndicator(
                    radius: 70.0,
                    lineWidth: 12.0,
                    percent: productivityPercent,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${(productivityPercent * 100).toInt()}%",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
                        ),
                        const Text("Score", style: TextStyle(fontSize: 10)),
                      ],
                    ),
                    footer: const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text("Today's Productivity Index", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    circularStrokeCap: CircularStrokeCap.round,
                    progressColor: Colors.deepPurple,
                    backgroundColor: Colors.deepPurple.shade100,
                    animation: true,
                    animationDuration: 1500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fadeIn({required Widget child, double delay = 0.0}) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final start = delay;
        final end = (delay + 0.5).clamp(0.0, 1.0);
        final curve = CurvedAnimation(
          parent: _animationController,
          curve: Interval(start, end, curve: Curves.easeOut),
        );
        return Opacity(opacity: curve.value, child: Transform.translate(offset: Offset(0, 20 * (1 - curve.value)), child: child));
      },
      child: child,
    );
  }

  Widget _scaleIn({required Widget child, double delay = 0.0}) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final start = delay;
        final end = (delay + 0.4).clamp(0.0, 1.0);
        final curve = CurvedAnimation(
          parent: _animationController,
          curve: Interval(start, end, curve: Curves.elasticOut),
        );
        return Transform.scale(scale: curve.value, child: child);
      },
      child: child,
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, String subtitle, IconData icon, Color color, Widget? destination) {
    return GestureDetector(
      onTap: () {
        if (destination != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use the Bottom Navigation for Social!')));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 9), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.42,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
