import 'package:flutter/material.dart';
import '../../../ai/data/ai_service.dart';

class AIInsightCard extends StatefulWidget {
  final int studyMinutes;
  final int screenMinutes;

  const AIInsightCard({
    super.key,
    required this.studyMinutes,
    required this.screenMinutes,
  });

  @override
  State<AIInsightCard> createState() => _AIInsightCardState();
}

class _AIInsightCardState extends State<AIInsightCard> {
  final _aiService = AIService();
  String _insight = "Analyzing your productivity...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateInsight();
  }

  Future<void> _generateInsight() async {
    try {
      final prompt = "Based on today's data: I studied for ${widget.studyMinutes} minutes and spent ${widget.screenMinutes} minutes on my phone. Give me a one-sentence motivation or advice in Hindi (Hinglish). Keep it friendly and student-focused.";
      final response = await _aiService.getStudyHelp(prompt);
      if (mounted) {
        setState(() {
          _insight = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _insight = "Keep pushing! Your hard work will pay off.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade400, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.white, size: 30),
                const SizedBox(width: 10),
                const Text(
                  "AI Productivity Tip",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _insight,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
