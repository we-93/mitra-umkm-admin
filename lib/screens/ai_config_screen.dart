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
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController(text: 'wz/gpt-5.4');
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final doc = await FirebaseFirestore.instance.doc('system_config/general').get();
      if (doc.exists) {
        final data = doc.data()!;
        _apiKeyController.text = data['api_key_weizerouter'] ?? '';
        _modelController.text = data['ai_model_name'] ?? 'wz/gpt-5.4';
      }
    } catch (e) {
      debugPrint('Error loading config: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.doc('system_config/general').set({
        'api_key_weizerouter': _apiKeyController.text.trim(),
        'ai_model_name': _modelController.text.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konfigurasi API berhasil disimpan.')),
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

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0).copyWith(bottom: 0),
            child: Text(
              'Konfigurasi Asisten AI',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AdminTheme.textPrimary,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
            child: Text('Atur API Key dari WeizeRouter dan model AI untuk aplikasi Mitra UMKM.', style: TextStyle(color: AdminTheme.textSecondary)),
          ),
          const SizedBox(height: 16),
          TabBar(
            labelColor: AdminTheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AdminTheme.primary,
            tabs: const [
              Tab(icon: Icon(Icons.chat_bubble_outline), text: 'API Chat (Konsultan)'),
              Tab(icon: Icon(Icons.image_outlined), text: 'API Image (Coming Soon)'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildChatTab(isDark),
                _buildImageTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Konfigurasi API WeizeRouter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _apiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'API Key WeizeRouter',
                      hintText: 'Masukkan Bearer Token API...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Model AI (Chat)',
                      hintText: 'Contoh: wz/gpt-5.4',
                      border: OutlineInputBorder(),
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
          _buildPresetsSection(isDark),
        ],
      ),
    );
  }

  Widget _buildImageTab(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Konfigurasi API Image (Generator Flyer)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Segera Hadir (Coming Soon)',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsSection(bool isDark) {
    return Card(
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