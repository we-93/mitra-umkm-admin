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
  int _freeCashierLimit = 30;

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
      final docConfig = await FirebaseFirestore.instance.doc('system_config/general').get();
      if (docConfig.exists) {
        _freeCashierLimit = docConfig.data()?['free_cashier_limit'] ?? 30;
      }
    } catch (e) {
      debugPrint('Error loading config: $e');
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

        users.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          
          Timestamp tsA = dataA['created_at'] ?? Timestamp.fromMillisecondsSinceEpoch(0);
          Timestamp tsB = dataB['created_at'] ?? Timestamp.fromMillisecondsSinceEpoch(0);
          return tsB.compareTo(tsA);
        });

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

                  LayoutBuilder(
                    builder: (context, gridConstraints) {
                      int crossAxisCount = isMobile ? 2 : 4;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isMobile ? 1.4 : 1.8,
                        children: [
                          _HoverStatCard(
                            title: 'Total Pengguna',
                            value: '$totalUsers',
                            icon: Icons.people,
                            baseColor: const Color(0xFF0E766D),
                            textColorLight: Colors.white,
                            isDark: isDark,
                          ),
                          _HoverStatCard(
                            title: 'Usaha Mikro',
                            value: '$totalMikro',
                            icon: Icons.store,
                            baseColor: const Color(0xFF14B2A5),
                            textColorLight: Colors.white,
                            isDark: isDark,
                          ),
                          _HoverStatCard(
                            title: 'Usaha Kecil',
                            value: '$totalKecil',
                            icon: Icons.business,
                            baseColor: const Color(0xFF8FEBD8),
                            textColorLight: const Color(0xFF262626),
                            isDark: isDark,
                          ),
                          _HoverStatCard(
                            title: 'Usaha Menengah',
                            value: '$totalMenengah',
                            icon: Icons.domain,
                            baseColor: const Color(0xFFF97417),
                            textColorLight: Colors.white,
                            isDark: isDark,
                          ),
                        ],
                      );
                    },
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
                          LayoutBuilder(
                            builder: (context, tableConstraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: tableConstraints.maxWidth),
                                  child: DataTable(
                                    dataTextStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                                    headingTextStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                                    columnSpacing: 16,
                                    columns: const [
                                      DataColumn(label: Text('No.')),
                                      DataColumn(label: Text('Nama (Toko & Email)')),
                                      DataColumn(label: Text('Kategori')),
                                      DataColumn(label: Text('Status')),
                                      DataColumn(label: Text('Token AI')),
                                      DataColumn(label: Text('Kasir')),
                                      DataColumn(label: Text('Produk')),
                                      DataColumn(label: Text('Aksi')),
                                    ],
                                    rows: paginatedUsers.asMap().entries.map((entry) {
                                      int index = entry.key;
                                      final doc = entry.value;
                                      final data = doc.data() as Map<String, dynamic>;
                                      
                                      int aiCredits = data['ai_credits_remaining'] ?? 100;
                                      int cashierLimitUsed = data['cashier_limit_used'] ?? 0;
                                      int productLimit = data['product_limit'] ?? 3;
                                      int productUsed = data['product_used'] ?? 0;

                                      String cashierText = (data['status'] ?? '').toString().toLowerCase().contains('mikro') || (data['status'] == null)
                                        ? '$cashierLimitUsed / $_freeCashierLimit'
                                        : '$cashierLimitUsed / Unlimited';

                                      String productText = productLimit == -1 
                                        ? '$productUsed / Unlimited' 
                                        : '$productUsed / $productLimit';

                                      String categoryText = data['status'] ?? 'Usaha Mikro';
                                      Color categoryColor = Colors.blue;
                                      if (categoryText.toLowerCase().contains('kecil')) categoryColor = Colors.orange;
                                      if (categoryText.toLowerCase().contains('menengah')) categoryColor = Colors.purple;

                                      String onlineStatus = '-';
                                      Color onlineColor = Colors.grey;
                                      if (data['last_online'] != null) {
                                        Timestamp lastOnlineTs = data['last_online'];
                                        DateTime lastOnlineDate = lastOnlineTs.toDate();
                                        DateTime now = DateTime.now();
                                        int diffDays = now.difference(lastOnlineDate).inDays;
                                        
                                        if (diffDays == 0 && now.day == lastOnlineDate.day) {
                                          onlineStatus = 'Online';
                                          onlineColor = Colors.green;
                                        } else if (diffDays == 0) {
                                          onlineStatus = 'Offline (kemarin)';
                                          onlineColor = Colors.red;
                                        } else {
                                          onlineStatus = 'Offline ($diffDays hari yang lalu)';
                                          onlineColor = Colors.red;
                                        }
                                      }

                                      return DataRow(cells: [
                                        DataCell(Text('${startIdx + index + 1}')),
                                        DataCell(Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(data['store_name'] ?? data['name'] ?? 'Tanpa Nama', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            Text(data['email'] ?? '-', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                          ],
                                        )),
                                        DataCell(Text(categoryText, style: TextStyle(color: categoryColor, fontWeight: FontWeight.bold))),
                                        DataCell(Text(onlineStatus, style: TextStyle(color: onlineColor))),
                                        DataCell(Text('Sisa: $aiCredits')),
                                        DataCell(Text(cashierText)),
                                        DataCell(Text(productText)),
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
                              );
                            },
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
    
    List<String> availableCategories = ['Usaha Mikro'];
    for (var pkg in _upgradePackages) {
      if (pkg['name'] != null && !availableCategories.contains(pkg['name'])) {
        availableCategories.add(pkg['name']);
      }
    }
    if (!availableCategories.contains(currentCategory)) {
      availableCategories.add(currentCategory);
    }
    
    TextEditingController addAiController = TextEditingController(text: '0');
    TextEditingController addProductLimitController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Kategori & Tambah Kuota: ${data['store_name'] ?? 'User'}'),
        content: StatefulBuilder(
          builder: (ctx, setSt) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Kategori Usaha'),
                value: currentCategory,
                items: availableCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setSt(() => currentCategory = val);
                },
              ),
              const SizedBox(height: 16),
              const Text('Masukkan angka untuk menambah kuota (bisa negatif untuk mengurangi):', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              TextField(
                controller: addAiController,
                decoration: const InputDecoration(labelText: 'Tambah Token AI (+)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addProductLimitController,
                decoration: const InputDecoration(labelText: 'Tambah Batas Produk (+)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              int addAi = int.tryParse(addAiController.text) ?? 0;
              int addProd = int.tryParse(addProductLimitController.text) ?? 0;

              Map<String, dynamic> updates = {
                'status': currentCategory,
              };
              
              if (addAi != 0) updates['ai_credits_remaining'] = FieldValue.increment(addAi);
              if (addProd != 0) updates['product_limit'] = FieldValue.increment(addProd);

              await FirebaseFirestore.instance.collection('users').doc(userId).update(updates);
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
