import 'package:flutter/material.dart';
import 'package:teamflow/auth/auth_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teamflow/home/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String oldName = "";
  String oldPosition = "";
  final nameController = TextEditingController();
  final positionController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    positionController.dispose();
    super.dispose();
  }

  Future<void> saveProfile() async {
  final name = nameController.text.trim();
  final position = positionController.text.trim();

  if (name.isEmpty || position.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Заполните все поля")),
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

  setState(() {
    isLoading = true;
  });

  try {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .set(
      {
        "uid": user.uid,
        "email": user.email,
        "name": name,
        "position": position,
        "updatedAt": FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MyHomePage(title: ''),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Ошибка сохранения: $e")),
    );
  } finally {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}

Future<void> loadProfile() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  final doc = await FirebaseFirestore.instance
      .collection("users")
      .doc(user.uid)
      .get();

  if (!doc.exists) return;

  final data = doc.data();

  final name = data?["name"] ?? "";
  final position = data?["position"] ?? "";

  setState(() {
    oldName = name;
    oldPosition = position;

    nameController.text = name;
    positionController.text = position;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        title: const Text("Профиль"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 30),

              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade100,
                child: const Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.blue,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Заполните профиль",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Эти данные будут отображаться в проектах",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Имя",
                  hintText: "Введите ваше имя",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: positionController,
                decoration: InputDecoration(
                  labelText: "Должность",
                  hintText: "Например: Project Manager",
                  prefixIcon: const Icon(Icons.work_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
  backgroundColor: Colors.blue,
  foregroundColor: Colors.white,
),
                  onPressed: isLoading ? null : saveProfile,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : Text(FirebaseAuth.instance.currentUser == null ?  "Продолжить" : "Сохранить",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
  width: double.infinity,
  height: 55,
  child: ElevatedButton.icon(
    onPressed: logout,
    icon: const Icon(Icons.logout),
    label: const Text("Выйти"),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
    ),
  ),
)
            ],
          ),
        ),
      ),
    );
  }

  Future<void> logout() async {
  await FirebaseAuth.instance.signOut();

  if (!mounted) return;

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => const AuthPage(),
    ),
    (route) => false,
  );
}
}