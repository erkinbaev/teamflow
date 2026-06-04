import 'package:flutter/material.dart';
import 'package:teamflow/profile/profile_page.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teamflow/project/project_page.dart';

//ГЛАВНЫЙ ЭКРАН С ПРОЕКТАМИ
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //параметр для отслеживания текста названия проекта при добавлении
  final projectNameController = TextEditingController();

//цвета для покраски ячеек
  final List<int> projectColors = [
    0xFFEF5350,
    0xFFAB47BC,
    0xFF5C6BC0,
    0xFF29B6F6,
    0xFF26A69A,
    0xFF66BB6A,
    0xFFFFCA28,
    0xFFFF7043,
  ];

  @override
  void dispose() {
    projectNameController.dispose();
    super.dispose();
  }

//верста интерфейса
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("Пользователь не авторизован"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Проекты"),
        actions: [
          IconButton(
            onPressed: navigateToProfile,
            icon: const Icon(Icons.account_circle),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("projects")
            .where("members", arrayContains: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Проектов пока нет",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final projects = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final data = projects[index].data() as Map<String, dynamic>;

              final title = data["title"] ?? "";
              final colorValue = data["color"] ?? 0xFF2196F3;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectPage(
                          projectId: projects[index].id,
                          projectTitle: title,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Color(colorValue),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showCreateProjectModal,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

//переход на экран профиля
  void navigateToProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfilePage(),
      ),
    );
  }

//открытие модального окна для создание проекта
  void showCreateProjectModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
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
                  "Новый проект",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: projectNameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: "Название проекта",
                    hintText: "Например: TeamFlow",
                    prefixIcon: const Icon(Icons.folder_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          projectNameController.clear();
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
                        onPressed: createProject,
                        child: const Text("Создать"),
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
  }

//логика добавления проекта в базу
  Future<void> createProject() async {
    final title = projectNameController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Введите название проекта")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Пользователь не авторизован")),
      );
      return;
    }

    final randomColor = projectColors[Random().nextInt(projectColors.length)];

    await FirebaseFirestore.instance.collection("projects").add({
      "title": title,
      "ownerId": user.uid,
      "members": [user.uid],
      "color": randomColor,
      "tasksCount": 0,
      "completedTasksCount": 0,
      "createdAt": FieldValue.serverTimestamp(),
    });

    projectNameController.clear();

    if (!mounted) return;

    Navigator.pop(context);
  }
}