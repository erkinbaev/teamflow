//сущность описания проекта со следующими свойствами
class ProjectModel {
  final String id;
  final String title;
  final String ownerId;
  final List<String> members;
  final int color;

  ProjectModel({
    required this.id,
    required this.title,
    required this.ownerId,
    required this.members,
    required this.color,
  });

  factory ProjectModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return ProjectModel(
      id: id,
      title: map["title"] ?? "",
      ownerId: map["ownerId"] ?? "",
      members: List<String>.from(
        map["members"] ?? [],
      ),
      color: map["color"] ?? 0xFF2196F3,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "title": title,
      "ownerId": ownerId,
      "members": members,
      "color": color,
    };
  }
}
