import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mitra_umkm_admin/theme/admin_theme.dart';
import 'package:mitra_umkm_admin/models/course_model.dart';
import 'package:uuid/uuid.dart';
import 'package:mitra_umkm_admin/main.dart';

class LmsScreen extends StatefulWidget {
  const LmsScreen({Key? key}) : super(key: key);

  @override
  State<LmsScreen> createState() => _LmsScreenState();
}

class _LmsScreenState extends State<LmsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    final isDark = MitraUmkmAdminApp.of(context).isDarkMode;

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('courses').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
        }

        List<QueryDocumentSnapshot> docs = snapshot.data?.docs ?? [];
        List<CourseModel> courses = docs.map((doc) {
          return CourseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manajemen Modul & Materi LMS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AdminTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Kelola daftar kelas (courses) dan materi pembelajaran UMKM.',
                        style: TextStyle(color: AdminTheme.textSecondary),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _addCourseDialog(isDark),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Modul Kelas'),
                  )
                ],
              ),
              const SizedBox(height: 24),
              courses.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text('Belum ada data modul kelas ditemukan di koleksi "courses".', style: TextStyle(color: AdminTheme.textSecondary)),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: courses.length,
                      itemBuilder: (ctx, index) {
                        final course = courses[index];
                        final docId = course.courseId;
                        final title = course.title.isEmpty ? docId : course.title;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: AdminTheme.primary.withOpacity(0.1),
                              child: const Icon(Icons.menu_book_rounded, color: AdminTheme.primary),
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text(
                              'Total Materi: ${course.materials.length} | Kunci Mikro: ${course.isLockedForMikro ? "Ya" : "Tidak"} | Kunci Kecil: ${course.isLockedForKecil ? "Ya" : "Tidak"}',
                              style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: AdminTheme.primary),
                                  tooltip: 'Tambah Materi',
                                  onPressed: () => _showMaterialDialog(
                                    course: course,
                                    isDark: isDark,
                                    onSave: (newMaterial) => _addMaterialToCourse(docId, course, newMaterial),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: 'Hapus Modul',
                                  onPressed: () => _confirmDeleteCourse(docId),
                                ),
                              ],
                            ),
                            children: [
                              const Divider(height: 1),
                              if (course.materials.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('Belum ada materi di dalam modul ini.', style: TextStyle(color: AdminTheme.textSecondary)),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: course.materials.length,
                                  separatorBuilder: (c, i) => const Divider(height: 1, indent: 16, endIndent: 16),
                                  itemBuilder: (c, mIndex) {
                                    final mat = course.materials[mIndex];
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                      leading: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.blue.withOpacity(0.1),
                                        child: Text('${mIndex + 1}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                      title: Text(mat.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (mat.descriptionMarkdown.isNotEmpty)
                                            Text(
                                              mat.descriptionMarkdown,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (mat.isLockedForMikro) const Padding(padding: EdgeInsets.only(right: 6), child: Chip(label: Text('Kunci Mikro', style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.orange)),
                                              if (mat.isLockedForKecil) const Padding(padding: EdgeInsets.only(right: 6), child: Chip(label: Text('Kunci Kecil', style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.purple)),
                                            ],
                                          )
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 20, color: AdminTheme.primary),
                                            onPressed: () => _showMaterialDialog(
                                              course: course,
                                              material: mat,
                                              isDark: isDark,
                                              onSave: (updatedMaterial) => _updateMaterialInCourse(docId, course, mIndex, updatedMaterial),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                            onPressed: () => _deleteMaterialFromCourse(docId, course, mIndex),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addMaterialToCourse(String docId, CourseModel course, CourseMaterial newMaterial) async {
    final updatedMaterials = List<CourseMaterial>.from(course.materials)..add(newMaterial);
    await _firestore.collection('courses').doc(docId).update({
      'materials': updatedMaterials.map((m) => m.toMap()).toList(),
    });
  }

  Future<void> _updateMaterialInCourse(String docId, CourseModel course, int index, CourseMaterial updatedMaterial) async {
    final updatedMaterials = List<CourseMaterial>.from(course.materials);
    updatedMaterials[index] = updatedMaterial;
    await _firestore.collection('courses').doc(docId).update({
      'materials': updatedMaterials.map((m) => m.toMap()).toList(),
    });
  }

  Future<void> _deleteMaterialFromCourse(String docId, CourseModel course, int index) async {
    final updatedMaterials = List<CourseMaterial>.from(course.materials)..removeAt(index);
    await _firestore.collection('courses').doc(docId).update({
      'materials': updatedMaterials.map((m) => m.toMap()).toList(),
    });
  }

  void _confirmDeleteCourse(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Modul Kelas'),
        content: Text('Apakah Anda yakin ingin menghapus modul "$docId"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _firestore.collection('courses').doc(docId).delete();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          )
        ],
      ),
    );
  }

  void _addCourseDialog(bool isDark) {
    final titleCtrl = TextEditingController();
    bool isLockedMikro = false;
    bool isLockedKecil = false;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Modul Kelas Baru'),
        content: StatefulBuilder(
          builder: (context, setSt) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Judul / Nama Modul', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Kunci untuk MIKRO', style: TextStyle(fontSize: 14)),
                value: isLockedMikro,
                onChanged: (v) => setSt(() => isLockedMikro = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('Kunci untuk KECIL', style: TextStyle(fontSize: 14)),
                value: isLockedKecil,
                onChanged: (v) => setSt(() => isLockedKecil = v ?? false),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isNotEmpty) {
                String id = titleCtrl.text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
                await _firestore.collection('courses').doc(id).set({
                  'title': titleCtrl.text.trim(),
                  'is_locked_for_mikro': isLockedMikro,
                  'is_locked_for_kecil': isLockedKecil,
                  'materials': [],
                });
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          )
        ],
      ),
    );
  }

  void _showMaterialDialog({
    required CourseModel course,
    CourseMaterial? material,
    required bool isDark,
    required Function(CourseMaterial) onSave,
  }) {
    final titleController = TextEditingController(text: material?.title ?? '');
    final urlController = TextEditingController(text: material?.videoUrl ?? '');
    final descController = TextEditingController(text: material?.descriptionMarkdown ?? '');
    bool isLockedMikro = material?.isLockedForMikro ?? false;
    bool isLockedKecil = material?.isLockedForKecil ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              title: Text(
                material == null ? 'Tambah Materi Baru' : 'Edit Materi',
                style: TextStyle(color: isDark ? Colors.white : AdminTheme.textPrimary),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Judul Materi', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: urlController,
                        decoration: const InputDecoration(labelText: 'URL Video (YouTube)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descController,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'Deskripsi Materi (Markdown)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Kunci untuk MIKRO', style: TextStyle(fontSize: 14)),
                        value: isLockedMikro,
                        activeColor: AdminTheme.primary,
                        onChanged: (val) => setState(() => isLockedMikro = val ?? false),
                      ),
                      CheckboxListTile(
                        title: const Text('Kunci untuk KECIL', style: TextStyle(fontSize: 14)),
                        value: isLockedKecil,
                        activeColor: AdminTheme.primary,
                        onChanged: (val) => setState(() => isLockedKecil = val ?? false),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary),
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty) {
                      final newMat = CourseMaterial(
                        id: material?.id ?? _uuid.v4(),
                        title: titleController.text.trim(),
                        videoUrl: urlController.text.trim(),
                        descriptionMarkdown: descController.text.trim(),
                        isLockedForMikro: isLockedMikro,
                        isLockedForKecil: isLockedKecil,
                      );
                      onSave(newMat);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}