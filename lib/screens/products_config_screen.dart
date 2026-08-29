import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mitra_umkm_admin/theme/admin_theme.dart';
import 'package:mitra_umkm_admin/main.dart';

class ProductsConfigScreen extends StatefulWidget {
  const ProductsConfigScreen({Key? key}) : super(key: key);

  @override
  State<ProductsConfigScreen> createState() => _ProductsConfigScreenState();
}

class _ProductsConfigScreenState extends State<ProductsConfigScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _bankAccounts = [];
  List<Map<String, dynamic>> _upgradePackages = [];
  String _qrisUrl = '';
  String _adminWaNumber = '';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final docBank = await _firestore.doc('system_config/payment_accounts').get();
      if (docBank.exists) {
        if (docBank.data()!.containsKey('accounts')) {
          final List accounts = docBank.data()!['accounts'];
          _bankAccounts = accounts.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        if (docBank.data()!.containsKey('qris_url')) {
          _qrisUrl = docBank.data()!['qris_url'] ?? '';
        }
      }

      final docGeneral = await _firestore.doc('system_config/general').get();
      if (docGeneral.exists && docGeneral.data()!.containsKey('admin_wa_number')) {
        _adminWaNumber = docGeneral.data()!['admin_wa_number'] ?? '';
      }

      final docPackages = await _firestore.doc('system_config/upgrade_packages').get();
      if (docPackages.exists && docPackages.data()!.containsKey('packages')) {
        final List packages = docPackages.data()!['packages'];
        _upgradePackages = packages.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        // Default packages if not found
        _upgradePackages = [
          {
            'name': 'Usaha Kecil',
            'price': 35000,
            'ai_credits': 100,
            'cashier_quota': 100,
            'product_quota': 20
          },
          {
            'name': 'Usaha Menengah',
            'price': 75000,
            'ai_credits': 200,
            'cashier_quota': -1, // -1 means unlimited
            'product_quota': -1
          }
        ];
      }
      setState(() {});
    } catch (e) {
      debugPrint('Error loading config: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      await _firestore.doc('system_config/payment_accounts').set({
        'accounts': _bankAccounts,
        'qris_url': _qrisUrl,
        'updated_at': FieldValue.serverTimestamp(),
      });
      await _firestore.doc('system_config/general').set({
        'admin_wa_number': _adminWaNumber,
      }, SetOptions(merge: true));
      await _firestore.doc('system_config/upgrade_packages').set({
        'packages': _upgradePackages,
        'updated_at': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konfigurasi produk & rekening berhasil disimpan.')),
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

  void _addBankAccount() {
    setState(() {
      _bankAccounts.add({
        'bank_name': 'Bank BCA',
        'account_number': '',
        'account_name': '',
        'logo_url': '',
      });
    });
  }

  void _addPackage() {
    setState(() {
      _upgradePackages.add({
        'name': 'Paket Baru',
        'price': 0,
        'ai_credits': 0,
        'cashier_quota': 0,
        'product_quota': 0
      });
    });
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
            padding: const EdgeInsets.all(24.0),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Produk & Rekening Pembayaran', style: TextStyle(fontSize: MediaQuery.of(context).size.width < 600 ? 20 : 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Kelola paket upgrade kategori dan opsi pembayaran.', style: TextStyle(color: AdminTheme.textSecondary)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveConfig,
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan Perubahan'),
                )
              ],
            ),
          ),
          const TabBar(
            labelColor: AdminTheme.primary,
            unselectedLabelColor: AdminTheme.textSecondary,
            indicatorColor: AdminTheme.primary,
            tabs: [
              Tab(text: 'Manajemen Paket'),
              Tab(text: 'Daftar Rekening Bank'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: Upgrade Packages
                _buildPackagesTab(),
                // Tab 2: Bank Accounts
                _buildBankAccountsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              const Text('Daftar Paket Upgrade', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _addPackage,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Paket'),
                style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _upgradePackages.isEmpty
              ? const Padding(padding: EdgeInsets.all(16), child: Text('Belum ada paket upgrade.'))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _upgradePackages.length,
                  itemBuilder: (ctx, index) {
                    final pkg = _upgradePackages[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: MediaQuery.of(context).size.width < 800 ? Column(
                                children: [
                                  TextField(
                                    controller: TextEditingController(text: pkg['name']),
                                    decoration: const InputDecoration(labelText: 'Nama Kategori (Misal: Usaha Kecil)', border: OutlineInputBorder()),
                                    onChanged: (val) => _upgradePackages[index]['name'] = val,
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: TextEditingController(text: pkg['price'].toString()),
                                    decoration: const InputDecoration(labelText: 'Harga (Rp)', border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) => _upgradePackages[index]['price'] = int.tryParse(val) ?? 0,
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: TextEditingController(text: pkg['ai_credits'].toString()),
                                    decoration: const InputDecoration(labelText: 'Kuota AI', border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) => _upgradePackages[index]['ai_credits'] = int.tryParse(val) ?? 0,
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: TextEditingController(text: pkg['cashier_quota'].toString()),
                                    decoration: const InputDecoration(labelText: 'Kuota Kasir (-1 = Unlimited)', border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) => _upgradePackages[index]['cashier_quota'] = int.tryParse(val) ?? 0,
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: TextEditingController(text: pkg['product_quota'].toString()),
                                    decoration: const InputDecoration(labelText: 'Kuota Produk (-1 = Unlimited)', border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) => _upgradePackages[index]['product_quota'] = int.tryParse(val) ?? 0,
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: TextEditingController(text: (pkg['lms_quota'] ?? 'Akses Semua Kursus').toString()),
                                    decoration: const InputDecoration(labelText: 'Akses Kursus LMS (Teks Bebas)', border: OutlineInputBorder()),
                                    keyboardType: TextInputType.text,
                                    onChanged: (val) => _upgradePackages[index]['lms_quota'] = val,
                                  ),
                                ],
                              ) : Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(text: pkg['name']),
                                          decoration: const InputDecoration(labelText: 'Nama Kategori (Misal: Usaha Kecil)', border: OutlineInputBorder()),
                                          onChanged: (val) => _upgradePackages[index]['name'] = val,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(text: pkg['price'].toString()),
                                          decoration: const InputDecoration(labelText: 'Harga (Rp)', border: OutlineInputBorder()),
                                          keyboardType: TextInputType.number,
                                          onChanged: (val) => _upgradePackages[index]['price'] = int.tryParse(val) ?? 0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(text: pkg['ai_credits'].toString()),
                                          decoration: const InputDecoration(labelText: 'Kuota AI', border: OutlineInputBorder()),
                                          keyboardType: TextInputType.number,
                                          onChanged: (val) => _upgradePackages[index]['ai_credits'] = int.tryParse(val) ?? 0,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(text: pkg['cashier_quota'].toString()),
                                          decoration: const InputDecoration(labelText: 'Kuota Kasir (-1 = Unlimited)', border: OutlineInputBorder()),
                                          keyboardType: TextInputType.number,
                                          onChanged: (val) => _upgradePackages[index]['cashier_quota'] = int.tryParse(val) ?? 0,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(text: pkg['product_quota'].toString()),
                                          decoration: const InputDecoration(labelText: 'Kuota Produk (-1 = Unlimited)', border: OutlineInputBorder()),
                                          keyboardType: TextInputType.number,
                                          onChanged: (val) => _upgradePackages[index]['product_quota'] = int.tryParse(val) ?? 0,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(text: (pkg['lms_quota'] ?? 'Akses Semua Kursus').toString()),
                                          decoration: const InputDecoration(labelText: 'Akses Kursus LMS (Teks Bebas)', border: OutlineInputBorder()),
                                          keyboardType: TextInputType.text,
                                          onChanged: (val) => _upgradePackages[index]['lms_quota'] = val,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => setState(() => _upgradePackages.removeAt(index)),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildBankAccountsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              const Text('Daftar Rekening Bank Transfer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _addBankAccount,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Rekening'),
                style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.secondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // WA and QRIS Box
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: _adminWaNumber),
                  decoration: const InputDecoration(
                    labelText: 'Nomor WhatsApp Admin (Untuk Konfirmasi)',
                    hintText: 'Contoh: 628123456789',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => _adminWaNumber = val,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: _qrisUrl),
                  decoration: const InputDecoration(
                    labelText: 'URL Gambar QRIS',
                    hintText: 'https://...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => _qrisUrl = val,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _bankAccounts.isEmpty
              ? const Padding(padding: EdgeInsets.all(16), child: Text('Belum ada rekening pembayaran.'))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _bankAccounts.length,
                  itemBuilder: (ctx, index) {
                    final acc = _bankAccounts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(text: acc['bank_name']),
                                          decoration: const InputDecoration(labelText: 'Nama Bank', border: OutlineInputBorder()),
                                          onChanged: (val) => _bankAccounts[index]['bank_name'] = val,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(text: acc['account_number']),
                                          decoration: const InputDecoration(labelText: 'Nomor Rekening', border: OutlineInputBorder()),
                                          onChanged: (val) => _bankAccounts[index]['account_number'] = val,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(text: acc['account_name']),
                                          decoration: const InputDecoration(labelText: 'Atas Nama (Pemilik)', border: OutlineInputBorder()),
                                          onChanged: (val) => _bankAccounts[index]['account_name'] = val,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: TextEditingController(text: acc['logo_url']),
                                          decoration: const InputDecoration(labelText: 'URL Logo Bank (Opsional)', border: OutlineInputBorder()),
                                          onChanged: (val) => _bankAccounts[index]['logo_url'] = val,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => setState(() => _bankAccounts.removeAt(index)),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
