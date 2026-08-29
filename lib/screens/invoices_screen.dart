import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mitra_umkm_admin/theme/admin_theme.dart';
import 'package:mitra_umkm_admin/main.dart';
import 'package:intl/intl.dart';
import '../services/pdf_service.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({Key? key}) : super(key: key);

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  String _statusFilter = 'Semua Status';
  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
  final Map<String, String> _userEmails = {};

  Future<String> _getUserEmail(String? userId) async {
    if (userId == null || userId.isEmpty) return 'No Email';
    if (_userEmails.containsKey(userId)) return _userEmails[userId]!;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final email = (doc.data() as Map<String, dynamic>?)?['email'] ?? 'No Email';
      _userEmails[userId] = email;
      return email;
    } catch (e) {
      return 'Error';
    }
  }

  Future<void> _acceptInvoice(String docId, String? userId, String packageName) async {
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID Pengguna tidak valid.'), backgroundColor: Colors.red));
      return;
    }
    
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    try {
      final packageDoc = await FirebaseFirestore.instance.collection('system_config').doc('upgrade_packages').get();
      if (!packageDoc.exists) throw Exception('Konfigurasi paket tidak ditemukan di database.');
      
      final packagesList = packageDoc.data()?['packages'] as List<dynamic>? ?? [];
      final pkg = packagesList.firstWhere(
        (p) => (p['name'] as String).toLowerCase() == packageName.toLowerCase(),
        orElse: () => null,
      );
      
      if (pkg == null) throw Exception('Paket $packageName tidak ditemukan di sistem.');

      final aiCredits = pkg['ai_credits'] ?? 0;
      final productLimit = pkg['product_quota'] ?? 0;
      
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      await userRef.update({
        'status': packageName,
        'ai_credits_remaining': aiCredits,
        'product_limit': productLimit,
        'expiry_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      });

      await FirebaseFirestore.instance.collection('transactions').doc(docId).update({
        'status': 'paid'
      });

      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran berhasil di-ACC. Kuota user diperbarui.'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _rejectInvoice(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('transactions').doc(docId).update({'status': 'failed'});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi ditolak.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteInvoice(String docId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('transactions').doc(docId).delete();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi dihapus.')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showInvoiceDetail(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detail Transaksi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice: ${data['invoice_number'] ?? '-'}'),
            Text('Paket: ${data['package_name'] ?? '-'}'),
            Text('Status: ${data['status'] ?? '-'}'),
            Text('User ID: ${data['user_id'] ?? '-'}'),
            Text('Total: Rp ${data['amount'] ?? data['total_amount'] ?? 0}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MitraUmkmAdminApp.of(context).isDarkMode;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('transactions').orderBy('created_at', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<QueryDocumentSnapshot> transactions = snapshot.data?.docs ?? [];

        if (_statusFilter != 'Semua Status') {
          transactions = transactions.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? 'pending').toString().toLowerCase();
            return status == _statusFilter.toLowerCase();
          }).toList();
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invoices & Transaksi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AdminTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Daftar riwayat transaksi dan status pembayaran pengguna.', style: TextStyle(color: AdminTheme.textSecondary)),
              const SizedBox(height: 24),
              Row(
                children: [
                  DropdownButton<String>(
                    value: _statusFilter,
                    items: const [
                      DropdownMenuItem(value: 'Semua Status', child: Text('Semua Status')),
                      DropdownMenuItem(value: 'paid', child: Text('Lunas (Paid)')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'failed', child: Text('Gagal (Failed)')),
                    ],
                    onChanged: (val) => setState(() => _statusFilter = val!),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: transactions.isEmpty
                    ? const Center(child: Text('Belum ada transaksi di koleksi "transactions".'))
                    : Card(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: DataTable(
                                  dataTextStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                                  headingTextStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                                  columnSpacing: 32,
                                  horizontalMargin: 24,
                              columns: const [
                                DataColumn(label: Text('No. Invoice')),
                                DataColumn(label: Text('Email')),
                                DataColumn(label: Text('Tanggal')),
                                DataColumn(label: Text('Total')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Aksi')),
                              ],
                            rows: transactions.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final amount = (data['total_amount'] ?? data['amount'] ?? 0).toDouble();
                              final status = (data['status'] ?? 'pending').toString();
                              
                              // Format the invoice number properly here for display
                              final rawInvoiceNumber = (data['invoice_number'] ?? data['transaction_id'] ?? doc.id).toString();
                              final displayInvoiceNumber = rawInvoiceNumber.startsWith('#') 
                                  ? rawInvoiceNumber 
                                  : (rawInvoiceNumber.startsWith('INV') ? '#$rawInvoiceNumber' : '#INV-$rawInvoiceNumber');

                              final date = data['created_at'] != null ? (data['created_at'] as Timestamp).toDate() : DateTime.now();

                              Color statusColor = Colors.orange;
                              if (status == 'paid' || status == 'success') statusColor = Colors.green;
                              if (status == 'failed' || status == 'expired') statusColor = Colors.red;

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: statusColor.withOpacity(0.1),
                                          child: Icon(Icons.receipt_outlined, color: statusColor, size: 14),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(displayInvoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    data.containsKey('user_email') && data['user_email'].toString().isNotEmpty
                                        ? Text(data['user_email'], style: const TextStyle(fontSize: 12))
                                        : FutureBuilder<String>(
                                            future: _getUserEmail(data['user_id']?.toString()),
                                            builder: (context, snapshot) {
                                              return Text(snapshot.data ?? 'Memuat...', style: const TextStyle(fontSize: 12));
                                            },
                                          ),
                                  ),
                                  DataCell(Text(DateFormat('dd MMM, HH:mm').format(date), style: const TextStyle(fontSize: 12))),
                                  DataCell(Text(currencyFormatter.format(amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataCell(
                                    Chip(
                                      label: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                                      backgroundColor: statusColor,
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (status == 'pending') ...[
                                          IconButton(
                                            icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                            tooltip: 'Terima (Acc)',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _acceptInvoice(doc.id, data['user_id'], data['package_name'] ?? ''),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.cancel, color: Colors.orange, size: 20),
                                            tooltip: 'Tolak',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _rejectInvoice(doc.id),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        IconButton(
                                          icon: const Icon(Icons.download, color: Colors.blue, size: 20),
                                          tooltip: 'Unduh PDF',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () async {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menyiapkan PDF...')));
                                            try {
                                              String storeName = 'Member Mitra UMKM';
                                              String email = 'member@mitraumkm.com';
                                              final userId = data['user_id'];
                                              if (userId != null && userId.toString().isNotEmpty) {
                                                final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
                                                if (userDoc.exists) {
                                                  final userData = userDoc.data();
                                                  if (userData != null) {
                                                    storeName = userData['name'] ?? storeName;
                                                    email = userData['email'] ?? email;
                                                  }
                                                }
                                              }
                                              
                                              final rawInvoiceNumber = (data['invoice_number'] ?? data['transaction_id'] ?? doc.id).toString();
                                              final displayInvoiceNumber = rawInvoiceNumber.startsWith('#') 
                                                  ? rawInvoiceNumber 
                                                  : (rawInvoiceNumber.startsWith('INV') ? '#$rawInvoiceNumber' : '#INV-$rawInvoiceNumber');

                                              await PdfService.downloadInvoicePdf(
                                                packageName: data['package_name'] ?? 'Paket Upgrade',
                                                price: currencyFormatter.format(amount),
                                                invoiceNumber: displayInvoiceNumber,
                                                storeName: storeName,
                                                email: email,
                                                status: status,
                                              );
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengunduh PDF: $e')));
                                              }
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                          tooltip: 'Hapus',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _deleteInvoice(doc.id),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ), // End DataTable
                        ), // End ConstrainedBox
                      ); // End return SingleChildScrollView
                    }, // End builder LayoutBuilder
                  ), // End LayoutBuilder
                ), // End Card
              ), // End Expanded
            ],
          ),
        );
      },
    );
  }
}