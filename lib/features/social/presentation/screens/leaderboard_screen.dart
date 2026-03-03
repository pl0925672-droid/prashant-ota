import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Leaderboard'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.indigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('profiles')
            .stream(primaryKey: ['id'])
            .order('total_study_hours', ascending: false)
            .limit(20),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data found'));
          }

          final users = snapshot.data!;

          return Column(
            children: [
              _buildTopThree(users),
              Expanded(
                child: ListView.builder(
                  itemCount: users.length > 3 ? users.length - 3 : 0,
                  itemBuilder: (context, index) {
                    final user = users[index + 3];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 4}'),
                      ),
                      title: Text(user['username'] ?? 'Anonymous'),
                      subtitle: Text('Study Hours: ${user['total_study_hours'] ?? 0}h'),
                      trailing: const Icon(Icons.trending_up, color: Colors.green),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopThree(List<Map<String, dynamic>> users) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: Colors.deepPurple.withOpacity(0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (users.length > 1) _buildPodium(users[1], 2, 80, Colors.grey),
          if (users.length > 0) _buildPodium(users[0], 1, 100, Colors.amber),
          if (users.length > 2) _buildPodium(users[2], 3, 70, Colors.brown),
        ],
      ),
    );
  }

  Widget _buildPodium(Map<String, dynamic> user, int rank, double height, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: rank == 1 ? 40 : 30,
          backgroundColor: color,
          child: CircleAvatar(
            radius: rank == 1 ? 37 : 27,
            backgroundImage: NetworkImage(user['avatar_url'] ?? 'https://via.placeholder.com/150'),
          ),
        ),
        const SizedBox(height: 8),
        Text(user['username'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('${user['total_study_hours'] ?? 0}h', style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
        ),
      ],
    );
  }
}
