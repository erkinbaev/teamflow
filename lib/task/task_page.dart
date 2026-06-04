import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TaskPage extends StatefulWidget {
  final String taskId;

  const TaskPage({
    super.key,
    required this.taskId,
  });

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  String getStatusTitle(String status) {
    switch (status) {
      case "todo":
        return "Не начато";
      case "inProgress":
        return "В процессе";
      case "done":
        return "Выполнено";
      default:
        return "Не начато";
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "inProgress":
        return Colors.blue;
      case "done":
        return Colors.green;
      case "todo":
      default:
        return Colors.grey;
    }
  }

  Future<void> updateStatus(String status) async {
    await FirebaseFirestore.instance
        .collection("tasks")
        .doc(widget.taskId)
        .update({
      "status": status,
      "isCompleted": status == "done",
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  Future<String> getUserName(String userId) async {
    if (userId.isEmpty) return "Не указан";

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .get();

    final data = doc.data();

    return data?["name"] ?? data?["email"] ?? "Без имени";
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "Не указан";

    final date = timestamp.toDate();

    return "${date.day}.${date.month}.${date.year}";
  }

  bool isOverdue(String status, Timestamp? deadline) {
    if (status == "done") return false;
    if (deadline == null) return false;

    return deadline.toDate().isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        title: const Text("Задача"),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("tasks")
            .doc(widget.taskId)
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

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("Задача не найдена"),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final title = data["title"] ?? "";
          final description = data["description"] ?? "";
          final status = data["status"] ?? "todo";
          final assignedTo = data["assignedTo"] ?? "";
          final deadline = data["deadline"] as Timestamp?;

          final canChangeStatus = currentUserId == assignedTo;
          final overdue = isOverdue(status, deadline);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      description.isEmpty
                          ? "Описание отсутствует"
                          : description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: overdue ? Colors.red : getStatusColor(status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        overdue ? "Просрочено" : getStatusTitle(status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "Статус",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "todo",
                          child: Text("Не начато"),
                        ),
                        DropdownMenuItem(
                          value: "inProgress",
                          child: Text("В процессе"),
                        ),
                        DropdownMenuItem(
                          value: "done",
                          child: Text("Выполнено"),
                        ),
                      ],
                      onChanged: canChangeStatus
                          ? (value) {
                              if (value == null) return;
                              updateStatus(value);
                            }
                          : null,
                    ),

                    if (!canChangeStatus) ...[
                      const SizedBox(height: 8),
                      const Text(
                        "Статус может менять только ответственный за задачу",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month),
                      title: const Text("Дедлайн"),
                      subtitle: Text(formatDate(deadline)),
                    ),

                    FutureBuilder<String>(
                      future: getUserName(assignedTo),
                      builder: (context, userSnapshot) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.person_outline),
                          title: const Text("Ответственный"),
                          subtitle: Text(
                            userSnapshot.data ?? "Загрузка...",
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}