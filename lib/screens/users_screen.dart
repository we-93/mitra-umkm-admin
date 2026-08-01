import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mitra_umkm_admin/theme/admin_theme.dart';
import 'package:mitra_umkm_admin/main.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Semua Kategori';
  final List<String> _categories = ['Semua Kategori', 'Usaha Mikro', 'Usaha Kecil', 'Usaha Menengah'];

  int _currentPage = 0;
  final int _itemsPerPage = 10;
  
  List<Map<String, dynamic>> _upgradePackages = [];

  @override
  void initState() {
    super.initState();
    _loadPackagesConfig();
  }
  
  Future<void> _loadPackagesConfig() async {
    try {
      final docPackages = await FirebaseFirestore.instance.doc('system_config/upgrade_packages').get();
      if (docPackages.exists && docPackages.data()!.containsKey('packages')) {
        final List packages = docPackages.data()!['packages'];
        _upgradePackages = packages.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading packages config: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MitraUmkmAdminApp.of(context).isDarkMode;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Terjadi kesalahan saat memuat data.'));
        }

        List<QueryDocumentSnapshot> users = snapshot.data?.docs ?? [];

        int totalUsers = users.length;
        int totalMikro = 0;
        int totalKecil = 0;
        int totalMenengah = 0;

        for (var u in users) {
          final data = u.data() as Map<String, dynamic>;
          String cat = (data['status'] ?? 'Usaha Mikro').toString().toLowerCase();
          if (cat.contains('mikro')) {
            totalMikro++;
          } else if (cat.contains('kecil')) {
            totalKecil++;
          } else if (cat.contains('menengah')) {
            totalMenengah++;
          }
        }

        if (_searchQuery.isNotEmpty) {
          users = users.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final store = (data['store_name'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            final search = _searchQuery.toLowerCase();
            return store.contains(search) || email.contains(search);
          }).toList();
        }

        if (_selectedCategory != 'Semua Kategori') {
          users = users.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final cat = (data['status'] ?? 'Usaha Mikro').toString().toLowerCase();
            return cat == _selectedCategory.toLowerCase();
          }).toList();
        }

        int totalPages = (users.length / _itemsPerPage).ceil();
        if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;

        int startIdx = _currentPage * _itemsPerPage;
        int endIdx = startIdx + _itemsPerPage;
        if (endIdx > users.length) endIdx = users.length;

        List<QueryDocumentSnapshot> paginatedUsers = users.isEmpty ? [] : users.sublist(startIdx, endIdx);

        return LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 800;

            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Manajemen Pengguna', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Kelola data dan status pengguna aplikasi Mitra UMKM.', style: TextStyle(color: AdminTheme.textSecondary)),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(child: _HoverStatCard(title: 'Total Pengguna', value: '$totalUsers', subtitle: 'Seluruh akun terdaftar', icon: Icons.people, color: AdminTheme.primary, isDark: isDark)),
                      const SizedBox(width: 16),
                      Expanded(child: _HoverStatCard(title: 'Usaha Mikro', value: '$totalMikro', subtitle: 'Kategori Mikro', icon: Icons.store, color: Colors.blue, isDark: isDark)),
                      const SizedBox(width: 16),
                      Expanded(child: _HoverStatCard(title: 'Usaha Kecil', value: '$totalKecil', subtitle: 'Kategori Kecil', icon: Icons.business, color: Colors.orange, isDark: isDark)),
                      const SizedBox(width: 16),
                      Expanded(child: _HoverStatCard(title: 'Usaha Menengah', value: '$totalMenengah', subtitle: 'Kategori Menengah', icon: Icons.domain, color: Colors.purple, isDark: isDark)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Cari Toko / Email...',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (val) => setState(() => _searchQuery = val),
                            ),
                          ),
                          const SizedBox(width: 16),
                          DropdownButton<String>(
                            value: _selectedCategory,
                            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) => setState(() => _selectedCategory = val!),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('No.')),
                                DataColumn(label: Text('Nama (Toko & Email)')),
                                DataColumn(label: Text('Kategori')),
                                DataColumn(label: Text('Token AI')),
                                DataColumn(label: Text('Transaksi Kasir')),
                                DataColumn(label: Text('Batas Produk')),
                                DataColumn(label: Text('Aksi')),
                              ],
                              rows: paginatedUsers.asMap().entries.map((entry) {
                                int index = entry.key;
                                final doc = entry.value;
                                final data = doc.data() as Map<String, dynamic>;
                                
                                int aiCredits = data['ai_credits_remaining'] ?? 100;
                                int cashierLimitUsed = data['cashier_limit_used'] ?? 0;
                                int productLimit = data['product_limit'] ?? 3;

                                return DataRow(cells: [
                                  DataCell(Text('${startIdx + index + 1}')),
                                  DataCell(Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(data['store_name'] ?? data['name'] ?? 'Tanpa Nama', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(data['email'] ?? '-', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  )),
                                  DataCell(Chip(label: Text(data['status'] ?? 'Usaha Mikro'))),
                                  DataCell(Text(aiCredits.toString())),
                                  DataCell(Text(cashierLimitUsed.toString())),
                                  DataCell(Text(productLimit.toString())),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: AdminTheme.primary),
                                          onPressed: () => _editUserDialog(doc.id, data),
                                          tooltip: 'Edit Kategori & Kuota',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteUserDialog(doc.id, data['store_name'] ?? data['email'] ?? 'Pengguna'),
                                          tooltip: 'Hapus Pengguna',
                                        ),
                                      ],
                                    ),
                                  ),
                                ]);
                              }).toList(),
                            ),
                          ),

                          if (totalPages > 1) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                                ),
                                Text('Halaman ${_currentPage + 1} dari $totalPages'),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                                ),
                              ],
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _editUserDialog(String userId, Map<String, dynamic> data) {
    String currentCategory = data['status'] ?? 'Usaha Mikro';
    
    // Ensure the default dropdown items exist, even if package names changed, but ideally we match them
    // To be safe, we'll use a dynamic list based on _upgradePackages plus 'Usaha Mikro' as default
    List<String> availableCategories = ['Usaha Mikro'];
    for (var pkg in _upgradePackages) {
      if (pkg['name'] != null && !availableCategories.contains(pkg['name'])) {
        availableCategories.add(pkg['name']);
      }
    }
    if (!availableCategories.contains(currentCategory)) {
      availableCategories.add(currentCategory);
    }

    int aiCredits = data['ai_credits_remaining'] ?? 100;
    int cashierLimit = -1; // unlimited? wait, the display is used limit. But the admin wants to set max.
    // Actually PRD says "transaksi (sisa kuota)". Wait, in Firebase, we track "cashier_limit_used". 
    // And "free_cashier_limit" is from config. Or if they upgrade, does it change max or resets used?
    // Usually if limit is unlimited (-1), we don't care about used.
    // Let's just allow them to reset cashier_limit_used to 0, or set the ai_credits and product_limit.
    
    // Let's use controllers
    TextEditingController aiController = TextEditingController(text: aiCredits.toString());
    TextEditingController productLimitController = TextEditingController(text: (data['product_limit'] ?? 3).toString());
    TextEditingController cashierUsedController = TextEditingController(text: (data['cashier_limit_used'] ?? 0).toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Kategori & Kuota: ${data['store_name'] ?? 'User'}'),
        content: StatefulBuilder(
          builder: (ctx, setSt) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Kategori Usaha'),
                value: currentCategory,
                items: availableCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setSt(() {
                      currentCategory = val;
                      // Autofill based on packages
                      if (val == 'Usaha Mikro') {
                        aiController.text = '100';
                        productLimitController.text = '3';
                        cashierUsedController.text = '0'; // reset used
                      } else {
                        var matchedPkg = _upgradePackages.firstWhere((p) => p['name'] == val, orElse: () => {});
                        if (matchedPkg.isNotEmpty) {
                          aiController.text = (matchedPkg['ai_credits'] ?? 0).toString();
                          productLimitController.text = (matchedPkg['product_quota'] ?? -1).toString();
                          cashierUsedController.text = '0'; // reset used on upgrade
                        }
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: aiController,
                decoration: const InputDecoration(labelText: 'Token AI Tersisa', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: productLimitController,
                decoration: const InputDecoration(labelText: 'Batas Produk (-1 = Unlimited)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cashierUsedController,
                decoration: const InputDecoration(labelText: 'Transaksi Kasir Terpakai', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              int newAi = int.tryParse(aiController.text) ?? 100;
              int newProd = int.tryParse(productLimitController.text) ?? 3;
              int newCashier = int.tryParse(cashierUsedController.text) ?? 0;

              await FirebaseFirestore.instance.collection('users').doc(userId).update({
                'status': currentCategory,
                'ai_credits_remaining': newAi,
                'product_limit': newProd,
                'cashier_limit_used': newCashier,
              });
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _deleteUserDialog(String userId, String userName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengguna'),
        content: Text('Apakah Anda yakin ingin menghapus pengguna "$userName" secara permanen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(userId).delete();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}
