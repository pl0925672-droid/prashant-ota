import 'package:flutter/material.dart';
import '../../data/ai_service.dart';

class StudyPlannerScreen extends StatefulWidget {
  const StudyPlannerScreen({super.key});

  @override
  State<StudyPlannerScreen> createState() => _StudyPlannerScreenState();
}

class _StudyPlannerScreenState extends State<StudyPlannerScreen> {
  final _aiService = AIService();
  final _subjectsController = TextEditingController();
  final _daysController = TextEditingController();
  final _hoursController = TextEditingController();

  String _generatedPlan = "";
  bool _isLoading = false;

  void _generatePlan() async {
    if (_subjectsController.text.isEmpty || _daysController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _generatedPlan = "";
    });

    try {
      final prompt = """
      Create a detailed study plan for these subjects: ${_subjectsController.text}.
      I have ${_daysController.text} days and can study for ${_hoursController.text} hours per day.
      Format the plan day-by-day with specific topics and time slots.
      Provide the response in a professional, encouraging tone in Hindi (Hinglish).
      """;

      final plan = await _aiService.getStudyHelp(prompt);
      setState(() {
        _generatedPlan = plan;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Study Planner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Get your personalized study schedule',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _subjectsController,
              decoration: const InputDecoration(
                labelText: 'Subjects (e.g. Physics, Math, Biology)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _daysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Days Left',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: _hoursController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Hrs/Day',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generatePlan,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate AI Plan', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_generatedPlan.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.deepPurple.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.assignment, color: Colors.deepPurple),
                        SizedBox(width: 10),
                        Text('Your AI Study Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const Divider(height: 30),
                    Text(_generatedPlan, style: const TextStyle(fontSize: 15, height: 1.5)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
