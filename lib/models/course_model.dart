class CourseMaterial {
  final String id;
  final String title;
  final String videoUrl;
  final String descriptionMarkdown;
  final bool isLockedForMikro;
  final bool isLockedForKecil;

  CourseMaterial({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.descriptionMarkdown,
    this.isLockedForMikro = false,
    this.isLockedForKecil = false,
  });

  factory CourseMaterial.fromMap(Map<String, dynamic> map) {
    return CourseMaterial(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      videoUrl: map['video_url'] ?? '',
      descriptionMarkdown: map['description_markdown'] ?? '',
      isLockedForMikro: map['is_locked_for_mikro'] ?? false,
      isLockedForKecil: map['is_locked_for_kecil'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'video_url': videoUrl,
      'description_markdown': descriptionMarkdown,
      'is_locked_for_mikro': isLockedForMikro,
      'is_locked_for_kecil': isLockedForKecil,
    };
  }
}

class CourseModel {
  final String courseId; // Represents Module ID
  final String title; // Module Title
  final int order;
  final bool isLockedForMikro;
  final bool isLockedForKecil;
  final List<CourseMaterial> materials;

  CourseModel({
    required this.courseId,
    required this.title,
    required this.order,
    required this.isLockedForMikro,
    required this.isLockedForKecil,
    required this.materials,
  });

  factory CourseModel.fromMap(Map<String, dynamic> map, String id) {
    var materialsList = map['materials'] as List? ?? [];
    return CourseModel(
      courseId: id,
      title: map['title'] ?? '',
      order: map['order']?.toInt() ?? 0,
      isLockedForMikro: map['is_locked_for_mikro'] ?? false,
      isLockedForKecil: map['is_locked_for_kecil'] ?? false,
      materials: materialsList.map((m) => CourseMaterial.fromMap(m)).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'order': order,
      'is_locked_for_mikro': isLockedForMikro,
      'is_locked_for_kecil': isLockedForKecil,
      'materials': materials.map((m) => m.toMap()).toList(),
    };
  }
}
