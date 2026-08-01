import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mitra_umkm_admin/theme/admin_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mitra_umkm_admin/main.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final dayName = days[now.weekday - 1];
    String formattedDate = '$dayName, ${now.day} ${months[now.month - 1]} ${now.year}';
    final isDark = MitraUmkmAdminApp.of(context).isDarkMode;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('transactions').orderBy('created_at', descending: true).snapshots(),
          builder: (context, invoiceSnapshot) {
            List<QueryDocumentSnapshot> users = userSnapshot.data?.docs ?? [];
            List<QueryDocumentSnapshot> transactions = invoiceSnapshot.data?.docs ?? [];

            int totalUsers = users.length;
            int totalMikro = 0;
            int totalKecil = 0;
            int totalMenengah = 0;

            for (var u in users) {
              final d = u.data() as Map<String, dynamic>;
              final s = (d['status'] ?? 'mikro').toString().toLowerCase();
              if (s.contains('mikro')) {
                totalMikro++;
              } else if (s.contains('kecil')) {
                totalKecil++;
              } else if (s.contains('menengah')) {
                totalMenengah++;
              } else {
                totalMikro++;
              }
            }

            double totalRevenue = 0;
            for (var inv in transactions) {
              final d = inv.data() as Map<String, dynamic>;
              final st = (d['status'] ?? '').toString().toLowerCase();
              if (st == 'paid' || st == 'success') {
                totalRevenue += (d['total_amount'] ?? d['amount'] ?? 0).toDouble();
              }
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                bool isMobile = constraints.maxWidth < 800;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Dashboard Admin', style: TextStyle(color: AdminTheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('Ikhtisar Panel Kontrol', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AdminTheme.textPrimary)),
                              const SizedBox(height: 4),
                              const Text('Laporan Statistik Mitra UMKM', style: TextStyle(color: AdminTheme.textSecondary, fontSize: 14)),
                            ],
                          ),
                          if (!isMobile)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AdminTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: AdminTheme.primaryContainer),
                                  const SizedBox(width: 8),
                                  Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.primaryContainer)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Stat Cards Grid
                      LayoutBuilder(
                        builder: (context, gridConstraints) {
                          int crossAxisCount = isMobile ? 1 : (gridConstraints.maxWidth < 1100 ? 2 : 4);
                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.8,
                            children: [
                              _HoverStatCard(title: 'TOTAL PENGGUNA', value: '$totalUsers', subtitle: 'Mitra Terdaftar', icon: Icons.storefront, color: AdminTheme.primary, isDark: isDark),
                              _HoverStatCard(title: 'PENDAPATAN LUNAS', value: currencyFormatter.format(totalRevenue), subtitle: '${transactions.length} Transaksi', icon: Icons.account_balance_wallet, color: Colors.green, isDark: isDark),
                              _HoverStatCard(title: 'KATEGORI MIKRO', value: '$totalMikro', subtitle: 'Skala Mikro', icon: Icons.shopping_basket, color: Colors.orange, isDark: isDark),
                              _HoverStatCard(title: 'KATEGORI KECIL/MENENGAH', value: '${totalKecil + totalMenengah}', subtitle: 'Skala Kecil & Menengah', icon: Icons.business, color: Colors.purple, isDark: isDark),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Revenue Chart & Category Distribution
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Grafik Performa Pendapatan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      height: 250,
                                      child: LineChart(
                                        LineChartData(
                                          gridData: const FlGridData(show: true),
                                          titlesData: const FlTitlesData(show: false),
                                          borderData: FlBorderData(show: false),
                                          lineBarsData: [
                                            LineChartBarData(
                                              spots: const [
                                                FlSpot(0, 3),
                                                FlSpot(1, 4),
                                                FlSpot(2, 3.5),
                                                FlSpot(3, 5),
                                                FlSpot(4, 4.8),
                                                FlSpot(5, 7),
                                              ],
                                              isCurved: true,
                                              color: AdminTheme.primary,
                                              barWidth: 4,
                                              isStrokeCapRound: true,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Distribusi Kategori UMKM', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      height: 200,
                                      child: PieChart(
                                        PieChartData(
                                          sectionsSpace: 4,
                                          centerSpaceRadius: 40,
                                          sections: [
                                            PieChartSectionData(value: totalMikro.toDouble() == 0 ? 1 : totalMikro.toDouble(), color: AdminTheme.primary, title: 'Mikro'),
                                            PieChartSectionData(value: totalKecil.toDouble() == 0 ? 1 : totalKecil.toDouble(), color: Colors.orange, title: 'Kecil'),
                                            PieChartSectionData(value: totalMenengah.toDouble() == 0 ? 1 : totalMenengah.toDouble(), color: Colors.purple, title: 'Menengah'),
                                          ],
                                        ),
                                      ),
                                    ),
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
              },
            );
          },
        );
      },
    );
  }
}

class _HoverStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _HoverStatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF333333) : AdminTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: color, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}