import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mitra_umkm_admin/theme/admin_theme.dart';
import 'package:mitra_umkm_admin/main.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _targetSegment = 'Semua Pengguna';
  bool _isSending = false;

  Future<void> _sendNotification() async {
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan pesan notifikasi tidak boleh kosong.')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'target': _targetSegment,
        'created_at': FieldValue.serverTimestamp(),
      });

      _titleController.clear();
      _messageController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifikasi broadcast berhasil dikirim.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim notifikasi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MitraUmkmAdminApp.of(context).isDarkMode;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kirim Notifikasi Broadcast',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AdminTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Kirim pesan pengumuman atau notifikasi kepada seluruh atau segmen pengguna UMKM.', style: TextStyle(color: AdminTheme.textSecondary)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Buat Notifikasi Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _targetSegment,
                          decoration: const InputDecoration(labelText: 'Target Pengguna', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'Semua Pengguna', child: Text('Semua Pengguna')),
                            DropdownMenuItem(value: 'Usaha Mikro', child: Text('Usaha Mikro')),
                            DropdownMenuItem(value: 'Usaha Kecil', child: Text('Usaha Kecil')),
                            DropdownMenuItem(value: 'Usaha Menengah', child: Text('Usaha Menengah')),
                          ],
                          onChanged: (val) => setState(() => _targetSegment = val!),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(labelText: 'Judul Notifikasi', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _messageController,
                          maxLines: 4,
                          decoration: const InputDecoration(labelText: 'Isi Pesan Notifikasi', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSending ? null : _sendNotification,
                            icon: const Icon(Icons.send),
                            label: _isSending
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Kirim Notifikasi'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Riwayat Notifikasi Broadcast', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 350,
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('notifications').orderBy('created_at', descending: true).snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              List<QueryDocumentSnapshot> list = snapshot.data?.docs ?? [];
                              if (list.isEmpty) {
                                return const Center(child: Text('Belum ada riwayat notifikasi dikirim.'));
                              }

                              return ListView.builder(
                                itemCount: list.length,
                                itemBuilder: (ctx, i) {
                                  final data = list[i].data() as Map<String, dynamic>;
                                  return ListTile(
                                    leading: const CircleAvatar(backgroundColor: AdminTheme.secondary, child: Icon(Icons.notifications, color: Colors.white)),
                                    title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('${data['target'] ?? ''} • ${data['message'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis),
                                  );
                                },
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}