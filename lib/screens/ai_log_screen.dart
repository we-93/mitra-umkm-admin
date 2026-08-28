import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mitra_umkm_admin/theme/admin_theme.dart';
import 'package:mitra_umkm_admin/main.dart';
import 'package:intl/intl.dart';

class AiLogScreen extends StatefulWidget {
  const AiLogScreen({Key? key}) : super(key: key);

  @override
  State<AiLogScreen> createState() => _AiLogScreenState();
}

class _AiLogScreenState extends State<AiLogScreen> {
  final currencyFormatter = NumberFormat.decimalPattern('id');

  @override
  Widget build(BuildContext context) {
    final isDark = MitraUmkmAdminApp.of(context).isDarkMode;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('ai_usage_logs').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Terjadi kesalahan: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }

        final logs = snapshot.data?.docs ?? [];

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log Token AI',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AdminTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Daftar riwayat penggunaan token OpenAI oleh seluruh pengguna UMKM.', style: TextStyle(color: AdminTheme.textSecondary)),
              const SizedBox(height: 24),
              Expanded(
                child: logs.isEmpty
                    ? const Center(child: Text('Belum ada log penggunaan AI.'))
                    : Card(
                        child: ListView.separated(
                          itemCount: logs.length,
                          separatorBuilder: (ctx, i) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final data = logs[i].data() as Map<String, dynamic>;
                            final email = data['email'] ?? 'Tidak diketahui';
                            final storeName = data['store_name'] ?? 'Toko Saya';
                            final tokensUsed = data['tokens_used'] ?? 0;
                            
                            DateTime date = DateTime.now();
                            if (data['timestamp'] != null) {
                              if (data['timestamp'] is Timestamp) {
                                date = (data['timestamp'] as Timestamp).toDate();
                              }
                            }

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF0F766E).withOpacity(0.1),
                                child: const Icon(Icons.psychology, color: Color(0xFF0F766E)),
                              ),
                              title: Text('$email ($storeName)', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(DateFormat('dd MMM yyyy, HH:mm:ss').format(date)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${currencyFormatter.format(tokensUsed)} Token',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
