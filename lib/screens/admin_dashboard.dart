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
  String _pendapatanFilter = 'Bulan Ini'; // 'Bulan Ini' or 'Tahun Ini'

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isDark = MitraUmkmAdminApp.of(context).isDarkMode;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('transactions').orderBy('created_at', descending: true).snapshots(),
          builder: (context, invoiceSnapshot) {
            List<QueryDocumentSnapshot> users = userSnapshot.data?.docs ?? [];
            List<QueryDocumentSnapshot> transactions = invoiceSnapshot.data?.docs ?? [];

            // Aggregate User Data
            int totalUsers = users.length;
            int totalMikro = 0;
            int totalKecil = 0;
            int totalMenengah = 0;
            int activeUsers = 0;
            
            // For Growth Chart (Bulan Ini)
            Map<int, int> usersPerDay = {};
            List<Map<String, dynamic>> recentUsers = [];

            for (var u in users) {
              final d = u.data() as Map<String, dynamic>;
              final s = (d['status'] ?? 'mikro').toString().toLowerCase();
              if (s.contains('mikro')) totalMikro++;
              else if (s.contains('kecil')) totalKecil++;
              else if (s.contains('menengah')) totalMenengah++;
              else totalMikro++;

              // Active Users (last 24 hours)
              if (d['last_online'] != null) {
                Timestamp lastOnlineTs = d['last_online'];
                if (now.difference(lastOnlineTs.toDate()).inHours <= 24) {
                  activeUsers++;
                }
              }
              
              // Created at mapping
              if (d['created_at'] != null) {
                 Timestamp createdAtTs = d['created_at'];
                 DateTime createdAt = createdAtTs.toDate();
                 if (createdAt.month == now.month && createdAt.year == now.year) {
                   usersPerDay[createdAt.day] = (usersPerDay[createdAt.day] ?? 0) + 1;
                 }
                 recentUsers.add(d);
              }
            }
            
            recentUsers.sort((a, b) {
              Timestamp ta = a['created_at'];
              Timestamp tb = b['created_at'];
              return tb.toDate().compareTo(ta.toDate());
            });
            List<Map<String, dynamic>> top5RecentUsers = recentUsers.take(5).toList();

            // Aggregate Revenue Data
            double totalRevenue = 0;
            Map<int, double> revenueData = {};

            for (var inv in transactions) {
              final d = inv.data() as Map<String, dynamic>;
              final st = (d['status'] ?? '').toString().toLowerCase();
              if (st == 'paid' || st == 'success') {
                double amount = (d['total_amount'] ?? d['amount'] ?? 0).toDouble();
                totalRevenue += amount;
                
                if (d['created_at'] != null) {
                  Timestamp createdAtTs = d['created_at'];
                  DateTime createdAt = createdAtTs.toDate();
                  
                  if (_pendapatanFilter == 'Bulan Ini') {
                    if (createdAt.month == now.month && createdAt.year == now.year) {
                      revenueData[createdAt.day] = (revenueData[createdAt.day] ?? 0) + amount;
                    }
                  } else {
                    if (createdAt.year == now.year) {
                      revenueData[createdAt.month] = (revenueData[createdAt.month] ?? 0) + amount;
                    }
                  }
                }
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
                      // Header Section
                      const Text('Overview', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Laporan Statistik Mitra UMKM', style: TextStyle(color: AdminTheme.textSecondary, fontSize: 16)),
                      const SizedBox(height: 32),

                      // Section 1: Stat Cards
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isMobile ? 2 : 4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isMobile ? 1.4 : 1.8,
                        children: [
                          _HoverStatCard(
                            title: 'Total Pengguna',
                            value: '$totalUsers',
                            icon: Icons.storefront,
                            baseColor: const Color(0xFF0E766D),
                            textColorLight: Colors.white,
                            isDark: isDark,
                          ),
                          _HoverStatCard(
                            title: 'Pengguna Aktif',
                            value: '$activeUsers',
                            icon: Icons.online_prediction,
                            baseColor: const Color(0xFF14B2A5),
                            textColorLight: Colors.white,
                            isDark: isDark,
                          ),
                          _HoverStatCard(
                            title: 'Total Invoice',
                            value: '${transactions.length}',
                            icon: Icons.receipt_long,
                            baseColor: const Color(0xFF8FEBD8),
                            textColorLight: const Color(0xFF262626),
                            isDark: isDark,
                          ),
                          _HoverStatCard(
                            title: 'Total Pendapatan',
                            value: currencyFormatter.format(totalRevenue),
                            icon: Icons.account_balance_wallet,
                            baseColor: const Color(0xFFF97417),
                            textColorLight: Colors.white,
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Section 2: Revenue Chart & Category Donut
                      if (isMobile) ...[
                        _buildRevenueChart(isDark, revenueData),
                        const SizedBox(height: 24),
                        _buildCategoryDonut(isDark, totalMikro, totalKecil, totalMenengah),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: _buildRevenueChart(isDark, revenueData)),
                            const SizedBox(width: 16),
                            Expanded(flex: 3, child: _buildCategoryDonut(isDark, totalMikro, totalKecil, totalMenengah)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 32),

                      // Section 3: Recent Users Table & Growth Bar Chart
                      if (isMobile) ...[
                        _buildRecentUsersTable(isDark, top5RecentUsers),
                        const SizedBox(height: 24),
                        _buildGrowthChart(isDark, usersPerDay),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: _buildRecentUsersTable(isDark, top5RecentUsers)),
                            const SizedBox(width: 16),
                            Expanded(flex: 3, child: _buildGrowthChart(isDark, usersPerDay)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 48),

                      // Footer
                      const Center(
                        child: Text(
                          '© 2026 Mitra UMKM. Hak Cipta Dilindungi.',
                          style: TextStyle(color: AdminTheme.textSecondary, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 24),
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

  Widget _buildRevenueChart(bool isDark, Map<int, double> data) {
    List<FlSpot> spots = [];
    if (data.isEmpty) {
      spots = [const FlSpot(0, 0)];
    } else {
      var sortedKeys = data.keys.toList()..sort();
      for (var key in sortedKeys) {
        spots.add(FlSpot(key.toDouble(), data[key]!));
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tren Pendapatan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    _filterButton('Bulan Ini', isDark),
                    const SizedBox(width: 8),
                    _filterButton('Tahun Ini', isDark),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AdminTheme.primary,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(
                        show: true,
                        color: AdminTheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterButton(String label, bool isDark) {
    bool isActive = _pendapatanFilter == label;
    return InkWell(
      onTap: () {
        setState(() {
          _pendapatanFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AdminTheme.primary : (isDark ? const Color(0xFF333333) : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDonut(bool isDark, int mikro, int kecil, int menengah) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kategori Pengguna', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 60,
                      sections: [
                        PieChartSectionData(
                          value: mikro.toDouble() == 0 ? 0.1 : mikro.toDouble(), 
                          color: const Color(0xFF14B2A5), 
                          title: '',
                          radius: 20,
                        ),
                        PieChartSectionData(
                          value: kecil.toDouble() == 0 ? 0.1 : kecil.toDouble(), 
                          color: const Color(0xFFF97417), 
                          title: '',
                          radius: 20,
                        ),
                        PieChartSectionData(
                          value: menengah.toDouble() == 0 ? 0.1 : menengah.toDouble(), 
                          color: Colors.purple, 
                          title: '',
                          radius: 20,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${mikro + kecil + menengah}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const Text('Total', style: TextStyle(color: AdminTheme.textSecondary, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('Mikro', const Color(0xFF14B2A5)),
                _buildLegendItem('Kecil', const Color(0xFFF97417)),
                _buildLegendItem('Menengah', Colors.purple),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildRecentUsersTable(bool isDark, List<Map<String, dynamic>> users) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('5 Pendaftar Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (users.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: Text('Belum ada data pendaftar terbaru.')),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.textSecondary),
                  columns: const [
                    DataColumn(label: Text('Nama (Toko)')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Kategori')),
                    DataColumn(label: Text('Tanggal Daftar')),
                  ],
                  rows: users.map((u) {
                    final date = u['created_at'] != null ? DateFormat('dd MMM yyyy').format((u['created_at'] as Timestamp).toDate()) : '-';
                    return DataRow(
                      cells: [
                        DataCell(Text(u['store_name'] ?? u['name'] ?? '-')),
                        DataCell(Text(u['email'] ?? '-')),
                        DataCell(Text(u['status'] ?? 'Usaha Mikro')),
                        DataCell(Text(date)),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthChart(bool isDark, Map<int, int> data) {
    List<BarChartGroupData> barGroups = [];
    if (data.isEmpty) {
      barGroups = [BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 0)])];
    } else {
      var sortedKeys = data.keys.toList()..sort();
      for (var key in sortedKeys) {
        barGroups.add(
          BarChartGroupData(
            x: key,
            barRods: [
              BarChartRodData(
                toY: data[key]!.toDouble(),
                color: const Color(0xFF14B2A5),
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              )
            ],
          ),
        );
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tren Pertumbuhan UMKM (Bulan Ini)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % 5 == 0 || value.toInt() == 1 || value.toInt() == 31) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                value.toInt().toString(),
                                style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverStatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color baseColor;
  final Color textColorLight;
  final bool isDark;

  const _HoverStatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.baseColor,
    required this.textColorLight,
    required this.isDark,
  }) : super(key: key);

  @override
  State<_HoverStatCard> createState() => _HoverStatCardState();
}

class _HoverStatCardState extends State<_HoverStatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF262626) : widget.baseColor;
    final borderColor = widget.isDark ? widget.baseColor : Colors.transparent;
    final textColor = widget.isDark ? Colors.white : widget.textColorLight;
    final iconColor = widget.isDark ? widget.baseColor : textColor.withOpacity(0.8);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()..translate(0.0, _isHovered ? -5.0 : 0.0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: widget.isDark ? 1.5 : 0),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.isDark ? widget.baseColor.withOpacity(0.2) : widget.baseColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    )
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: iconColor, size: 28),
              const Spacer(),
              Text(
                widget.title,
                style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.value,
                  style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}