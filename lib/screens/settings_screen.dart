import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mitra_umkm_admin/theme/admin_theme.dart';
import 'package:mitra_umkm_admin/main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _versionCodeController = TextEditingController();
  final _versionNameController = TextEditingController();
  final _releaseNotesController = TextEditingController();
  final _downloadUrlController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final doc = await FirebaseFirestore.instance.doc('system_config/app_version').get();
      if (doc.exists) {
        final data = doc.data()!;
        _versionCodeController.text = (data['latest_version_code'] ?? '1').toString();
        _versionNameController.text = data['latest_version_name'] ?? '1.0.0';
        _releaseNotesController.text = data['release_notes'] ?? '';
        _downloadUrlController.text = data['download_url'] ?? '';
      }
    } catch (e) {
      debugPrint('Error loading config: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveVersionConfig() async {
    final versionCode = int.tryParse(_versionCodeController.text);
    if (versionCode == null || _versionNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi Nama Versi dan Kode Versi (angka).')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.doc('system_config/app_version').set({
        'latest_version_code': versionCode,
        'latest_version_name': _versionNameController.text.trim(),
        'release_notes': _releaseNotesController.text.trim(),
        'download_url': _downloadUrlController.text.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informasi versi aplikasi berhasil disimpan.')),
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

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pengaturan Sistem', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Kelola versi aplikasi seluler Mitra UMKM dan catatan rilis.', style: TextStyle(color: AdminTheme.textSecondary)),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Versi Aplikasi Seluler (Android/iOS)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _versionNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nama Versi (Version Name)',
                                hintText: 'misal: 1.0.0',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _versionCodeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Kode Versi (Version Code)',
                                hintText: 'misal: 1',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _downloadUrlController,
                        decoration: const InputDecoration(
                          labelText: 'URL Download APK / Play Store',
                          hintText: 'https://...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _releaseNotesController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Catatan Rilis (Release Notes)',
                          hintText: 'Tulis fitur baru atau perbaikan di versi ini...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveVersionConfig,
                          icon: const Icon(Icons.save),
                          label: _isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Simpan Pengaturan Versi'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}