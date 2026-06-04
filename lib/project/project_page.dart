import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:teamflow/statistics/statistics_page.dart';
import 'package:teamflow/task/task_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

//ЭКРАН СО СПИСКОМ ЗАДАЧ
class ProjectPage extends StatefulWidget {
  final String projectId;
  final String projectTitle;

  const ProjectPage({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  //переменные для отслеживания названия задачи, описания
  final taskTitleController = TextEditingController();
  final taskDescriptionController = TextEditingController();

//дедлайн, ответственный за задачу его id, и остальные участники
  DateTime? selectedDeadline;
  String? selectedUserId;
  String? selectedMemberId;

  @override
  void dispose() {
    taskTitleController.dispose();
    taskDescriptionController.dispose();
    super.dispose();
  }

//установка цвета в зависимости от статуса
  Color getTaskColor(String status) {
    switch (status) {
      case "inProgress":
        return Colors.blue;
      case "done":
        return Colors.green;
      case "overdue":
        return Colors.red;
      case "todo":
      default:
        return Colors.white;
    }
  }

//установка цвета текста статуса
  Color getTaskTextColor(String status) {
    return status == "todo" ? Colors.black : Colors.white;
  }

  String getDisplayStatus(Map<String, dynamic> data) {
    final status = data["status"] ?? "todo";

    if (status == "done") return "done";

    final deadline = data["deadline"] as Timestamp?;

    if (deadline != null && deadline.toDate().isBefore(DateTime.now())) {
      return "overdue";
    }

    return status;
  }

//установка текста статуса
  String getStatusText(String status) {
    switch (status) {
      case "inProgress":
        return "В процессе";
      case "done":
        return "Готово";
      case "overdue":
        return "Просрочено";
      case "todo":
      default:
        return "Не начато";
    }
  }

//форматирование даты в формат день/месяц/год
  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "Без дедлайна";

    final date = timestamp.toDate();
    return "${date.day}.${date.month}.${date.year}";
  }

//верста интерфейса
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectTitle),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("projects")
                .doc(widget.projectId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox();
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final ownerId = data["ownerId"] ?? "";
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;

              final isOwner = ownerId == currentUserId;

              if (!isOwner) {
                return const SizedBox();
              }

              return IconButton(
                onPressed: showMembersModal,
                icon: const Icon(Icons.group_add),
              );
            },
          ),
          IconButton(
            onPressed: () => navigateToStatistics(context),
            icon: const Icon(Icons.bar_chart),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("tasks")
            .where("projectId", isEqualTo: widget.projectId)
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

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Задач пока нет",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            );
          }

          final tasks = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final data = tasks[index].data() as Map<String, dynamic>;

              final title = data["title"] ?? "";
              final deadline = data["deadline"] as Timestamp?;
              final status = getDisplayStatus(data);

              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskPage(
                        taskId: tasks[index].id,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: getTaskColor(status),
                    borderRadius: BorderRadius.circular(20),
                    border: status == "todo"
                        ? Border.all(color: Colors.grey.shade300)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: getTaskColor(status).withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: getTaskTextColor(status),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: getTaskTextColor(status),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            getStatusText(status),
                            style: TextStyle(
                              color: getTaskTextColor(status),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 18,
                            color: getTaskTextColor(status),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatDate(deadline),
                            style: TextStyle(
                              color: getTaskTextColor(status),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showCreateTaskModal,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

//функция для создания задачи и запись в базу
  Future<void> createTask() async {
    final title = taskTitleController.text.trim();
    final description = taskDescriptionController.text.trim();

    if (title.isEmpty ||
        description.isEmpty ||
        selectedDeadline == null ||
        selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Заполните все поля")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection("tasks").add({
      "projectId": widget.projectId,
      "title": title,
      "description": description,
      "deadline": Timestamp.fromDate(selectedDeadline!),
      "assignedTo": selectedUserId,
      "status": "todo",
      "isCompleted": false,
      "createdAt": FieldValue.serverTimestamp(),
    });

    taskTitleController.clear();
    taskDescriptionController.clear();

    setState(() {
      selectedDeadline = null;
      selectedUserId = null;
    });

    if (!mounted) return;

    Navigator.pop(context);
  }

//модальное окно создания задачи
  void showCreateTaskModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Новая задача",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: taskTitleController,
                        decoration: InputDecoration(
                          labelText: "Название задачи",
                          prefixIcon: const Icon(Icons.task_alt),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: taskDescriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Описание",
                          prefixIcon: const Icon(Icons.description_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2035),
                          );

                          if (date != null) {
                            setModalState(() {
                              selectedDeadline = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: "Дедлайн",
                            prefixIcon: const Icon(Icons.calendar_month),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            selectedDeadline == null
                                ? "Выберите дату"
                                : "${selectedDeadline!.day}.${selectedDeadline!.month}.${selectedDeadline!.year}",
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      buildResponsibleDropdown(setModalState),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                taskTitleController.clear();
                                taskDescriptionController.clear();

                                setState(() {
                                  selectedDeadline = null;
                                  selectedUserId = null;
                                });

                                Navigator.pop(context);
                              },
                              child: const Text("Отмена"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: createTask,
                              child: const Text("Создать"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

//показ списка участников проекта
  Widget buildResponsibleDropdown(StateSetter setModalState) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("projects")
          .doc(widget.projectId)
          .snapshots(),
      builder: (context, projectSnapshot) {
        if (projectSnapshot.hasError) {
          return Text(
            projectSnapshot.error.toString(),
            style: const TextStyle(color: Colors.red),
          );
        }

        if (!projectSnapshot.hasData || !projectSnapshot.data!.exists) {
          return const CircularProgressIndicator();
        }

        final projectData = projectSnapshot.data!.data() as Map<String, dynamic>;
        final members = List<String>.from(projectData["members"] ?? []);

        if (members.isEmpty) {
          return const Text("В проекте нет участников");
        }

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection("users")
              .where(FieldPath.documentId, whereIn: members)
              .get(),
          builder: (context, usersSnapshot) {
            if (usersSnapshot.hasError) {
              return Text(
                usersSnapshot.error.toString(),
                style: const TextStyle(color: Colors.red),
              );
            }

            if (!usersSnapshot.hasData) {
              return const CircularProgressIndicator();
            }

            final users = usersSnapshot.data!.docs;

            if (users.isEmpty) {
              return const Text("Участники не найдены");
            }

            return DropdownButtonFormField<String>(
              value: selectedUserId,
              isExpanded: true,
              menuMaxHeight: 250,
              decoration: InputDecoration(
                labelText: "Ответственный",
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: users.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(
                    data["name"] ?? data["email"] ?? "Без имени",
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setModalState(() {
                  selectedUserId = value;
                });
              },
            );
          },
        );
      },
    );
  }

//добавление участников проекта
  void showMembersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Участники проекта",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("projects")
                            .doc(widget.projectId)
                            .snapshots(),
                        builder: (context, projectSnapshot) {
                          if (projectSnapshot.hasError) {
                            return Text(
                              projectSnapshot.error.toString(),
                              style: const TextStyle(color: Colors.red),
                            );
                          }

                          if (!projectSnapshot.hasData ||
                              !projectSnapshot.data!.exists) {
                            return const CircularProgressIndicator();
                          }

                          final projectData =
                              projectSnapshot.data!.data() as Map<String, dynamic>;

                          final members =
                              List<String>.from(projectData["members"] ?? []);

                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("users")
                                .snapshots(),
                            builder: (context, usersSnapshot) {
                              if (usersSnapshot.hasError) {
                                return Text(
                                  usersSnapshot.error.toString(),
                                  style: const TextStyle(color: Colors.red),
                                );
                              }

                              if (!usersSnapshot.hasData) {
                                return const CircularProgressIndicator();
                              }

                              final users = usersSnapshot.data!.docs;

                              final projectMembers = users.where((doc) {
                                return members.contains(doc.id);
                              }).toList();

                              final availableUsers = users.where((doc) {
                                return !members.contains(doc.id);
                              }).toList();

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (projectMembers.isEmpty)
                                    const Text("Пока нет участников"),

                                  ...projectMembers.map((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;

                                    return ListTile(
                                      leading: const Icon(Icons.person),
                                      title: Text(
                                        data["name"] ??
                                            data["email"] ??
                                            "Без имени",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        data["position"] ?? "",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }),

                                  const SizedBox(height: 16),

                                  if (availableUsers.isEmpty)
                                    const Text(
                                      "Нет пользователей для добавления",
                                      style: TextStyle(color: Colors.grey),
                                    )
                                  else
                                    DropdownButtonFormField<String>(
                                      value: selectedMemberId,
                                      isExpanded: true,
                                      menuMaxHeight: 250,
                                      decoration: InputDecoration(
                                        labelText: "Добавить участника",
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      items: availableUsers.map((doc) {
                                        final data =
                                            doc.data() as Map<String, dynamic>;

                                        return DropdownMenuItem<String>(
                                          value: doc.id,
                                          child: Text(
                                            data["name"] ??
                                                data["email"] ??
                                                "Без имени",
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setModalState(() {
                                          selectedMemberId = value;
                                        });
                                      },
                                    ),

                                  const SizedBox(height: 20),

                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: selectedMemberId == null
                                          ? null
                                          : () async {
                                              await FirebaseFirestore.instance
                                                  .collection("projects")
                                                  .doc(widget.projectId)
                                                  .update({
                                                "members":
                                                    FieldValue.arrayUnion(
                                                  [selectedMemberId],
                                                ),
                                              });

                                              setModalState(() {
                                                selectedMemberId = null;
                                              });
                                            },
                                      child: const Text("Добавить"),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

//переход на экран статистики
  void navigateToStatistics(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatisticsPage(
          projectId: widget.projectId,
          projectTitle: widget.projectTitle,
        ),
      ),
    );
  }
}