import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mitra_umkm_admin/theme/admin_theme.dart';
import 'package:mitra_umkm_admin/main.dart';

class AiConfigScreen extends StatefulWidget {
  const AiConfigScreen({Key? key}) : super(key: key);

  @override
  State<AiConfigScreen> createState() => _AiConfigScreenState();
}

class _AiConfigScreenState extends State<AiConfigScreen> {
  final _systemPromptController = TextEditingController();
  final _modelController = TextEditingController(text: 'gemini-1.5-flash');
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final doc = await FirebaseFirestore.instance.doc('system_config/ai_config').get();
      if (doc.exists) {
        final data = doc.data()!;
        _systemPromptController.text = data['system_prompt'] ?? data['prompt'] ?? '';
        _modelController.text = data['model'] ?? 'gemini-1.5-flash';
      }
    } catch (e) {
      debugPrint('Error loading AI config: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.doc('system_config/ai_config').set({
        'system_prompt': _systemPromptController.text.trim(),
        'model': _modelController.text.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konfigurasi AI berhasil disimpan.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MitraUmkmAdminApp.of(context).isDarkMode;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Konfigurasi Asisten AI',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AdminTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Atur instruksi dasar (system prompt), model AI, dan preset prompt yang digunakan pengguna UMKM.', style: TextStyle(color: AdminTheme.textSecondary)),
          const SizedBox(height: 24),

          // Master Configuration Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pengaturan Utama AI (Master Config)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Model AI',
                      hintText: 'Contoh: gemini-1.5-flash, gemini-1.5-pro',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('System Prompt / Master Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _systemPromptController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan instruksi karakter AI untuk memandu UMKM...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveConfig,
                      icon: const Icon(Icons.save),
                      label: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Simpan Konfigurasi'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Prompts Preset Section (Collection: prompts_preset)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Daftar Prompt Preset (prompts_preset)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Daftar inspirasi prompt siap pakai bagi pengguna UMKM.', style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _addPresetDialog(isDark),
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Preset'),
                        style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('prompts_preset').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      List<QueryDocumentSnapshot> presets = snapshot.data?.docs ?? [];
                      if (presets.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('Belum ada preset prompt di koleksi "prompts_preset".', style: TextStyle(color: AdminTheme.textSecondary))),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: presets.length,
                        separatorBuilder: (c, i) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final data = presets[i].data() as Map<String, dynamic>;
                          final title = data['title'] ?? data['name'] ?? 'Preset #${i + 1}';
                          final promptText = data['prompt'] ?? data['content'] ?? data['description'] ?? '';
                          final category = data['category'] ?? 'Umum';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AdminTheme.primary.withOpacity(0.1),
                              child: const Icon(Icons.lightbulb_outline, color: AdminTheme.primary),
                            ),
                            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('$category • $promptText', maxLines: 2, overflow: TextOverflow.ellipsis),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('prompts_preset').doc(presets[i].id).delete();
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addPresetDialog(bool isDark) {
    final titleCtrl = TextEditingController();
    final promptCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'Pemasaran');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Prompt Preset Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul Preset', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Kategori (misal: Pemasaran, Keuangan)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: promptCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Isi Prompt', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isNotEmpty && promptCtrl.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance.collection('prompts_preset').add({
                  'title': titleCtrl.text.trim(),
                  'category': categoryCtrl.text.trim(),
                  'prompt': promptCtrl.text.trim(),
                  'created_at': FieldValue.serverTimestamp(),
                });
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}