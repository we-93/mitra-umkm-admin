import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mitra_umkm_admin/theme/admin_theme.dart';
import 'package:mitra_umkm_admin/main.dart';
import 'package:intl/intl.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({Key? key}) : super(key: key);

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  String _statusFilter = 'Semua Status';
  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

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
                        child: ListView.separated(
                          itemCount: transactions.length,
                          separatorBuilder: (ctx, i) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final data = transactions[i].data() as Map<String, dynamic>;
                            final amount = (data['total_amount'] ?? data['amount'] ?? 0).toDouble();
                            final status = (data['status'] ?? 'pending').toString();
                            final invoiceNo = data['invoice_number'] ?? data['transaction_id'] ?? transactions[i].id;
                            final date = data['created_at'] != null ? (data['created_at'] as Timestamp).toDate() : DateTime.now();

                            Color statusColor = Colors.orange;
                            if (status == 'paid' || status == 'success') statusColor = Colors.green;
                            if (status == 'failed' || status == 'expired') statusColor = Colors.red;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: statusColor.withOpacity(0.1),
                                child: Icon(Icons.receipt_outlined, color: statusColor),
                              ),
                              title: Text('Invoice #$invoiceNo', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(date)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    currencyFormatter.format(amount),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(width: 16),
                                  Chip(
                                    label: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11)),
                                    backgroundColor: statusColor,
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