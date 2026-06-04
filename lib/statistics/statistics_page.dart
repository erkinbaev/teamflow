import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StatisticsPage extends StatelessWidget {
  final String projectId;
  final String projectTitle;

  const StatisticsPage({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  String getDisplayStatus(Map<String, dynamic> data) {
    final status = data["status"] ?? "todo";

    if (status == "done") {
      return "done";
    }

    final deadline = data["deadline"] as Timestamp?;

    if (deadline != null && deadline.toDate().isBefore(DateTime.now())) {
      return "overdue";
    }

    return status;
  }

  Widget statCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$count",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        title: const Text("Статистика"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("tasks")
            .where("projectId", isEqualTo: projectId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final tasks = snapshot.data?.docs ?? [];

          int todo = 0;
          int inProgress = 0;
          int done = 0;
          int overdue = 0;

          for (final task in tasks) {
            final data = task.data() as Map<String, dynamic>;
            final status = getDisplayStatus(data);

            switch (status) {
              case "done":
                done++;
                break;
              case "inProgress":
                inProgress++;
                break;
              case "overdue":
                overdue++;
                break;
              case "todo":
              default:
                todo++;
            }
          }

          final total = tasks.length;
          final progress = total == 0 ? 0 : ((done / total) * 100).round();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                projectTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Выполнено $progress% задач",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 20),

              LinearProgressIndicator(
                value: total == 0 ? 0 : done / total,
                minHeight: 12,
                borderRadius: BorderRadius.circular(20),
                backgroundColor: Colors.grey.shade300,
                color: Colors.green,
              ),

              const SizedBox(height: 24),

              statCard(
                title: "Всего задач",
                count: total,
                color: Colors.blueGrey,
                icon: Icons.list_alt,
              ),

              const SizedBox(height: 12),

              statCard(
                title: "Не начато",
                count: todo,
                color: Colors.grey,
                icon: Icons.radio_button_unchecked,
              ),

              const SizedBox(height: 12),

              statCard(
                title: "В процессе",
                count: inProgress,
                color: Colors.blue,
                icon: Icons.timelapse,
              ),

              const SizedBox(height: 12),

              statCard(
                title: "Выполнено",
                count: done,
                color: Colors.green,
                icon: Icons.check_circle_outline,
              ),

              const SizedBox(height: 12),

              statCard(
                title: "Просрочено",
                count: overdue,
                color: Colors.red,
                icon: Icons.warning_amber_rounded,
              ),
            ],
          );
        },
      ),
    );
  }
}