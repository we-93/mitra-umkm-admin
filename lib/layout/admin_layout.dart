import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mitra_umkm_admin/main.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const AdminLayout({
    Key? key,
    required this.child,
    required this.currentRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Logo or Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront, color: Color(0xFF0F766E), size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'MITRA UMKM\nAdmin',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F766E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Navigation Links
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _NavItem(
                        title: 'Dashboard',
                        icon: Icons.dashboard_outlined,
                        route: '/',
                        currentRoute: currentRoute,
                      ),
                      _NavItem(
                        title: 'Pengguna',
                        icon: Icons.people_outline,
                        route: '/users',
                        currentRoute: currentRoute,
                      ),
                      _NavItem(
                        title: 'Invoices',
                        icon: Icons.receipt_long_outlined,
                        route: '/invoices',
                        currentRoute: currentRoute,
                      ),
                      _NavItem(
                        title: 'LMS Edukasi',
                        icon: Icons.school_outlined,
                        route: '/lms',
                        currentRoute: currentRoute,
                      ),
                      _NavItem(
                        title: 'Konfigurasi Produk',
                        icon: Icons.inventory_2_outlined,
                        route: '/products_config',
                        currentRoute: currentRoute,
                      ),
                      _NavItem(
                        title: 'Konsultan AI',
                        icon: Icons.smart_toy_outlined,
                        route: '/ai',
                        currentRoute: currentRoute,
                      ),
                      _NavItem(
                        title: 'Notifikasi',
                        icon: Icons.notifications_outlined,
                        route: '/notifications',
                        currentRoute: currentRoute,
                      ),
                      _NavItem(
                        title: 'Pengaturan',
                        icon: Icons.settings_outlined,
                        route: '/settings',
                        currentRoute: currentRoute,
                      ),
                    ],
                  ),
                ),
                
                // Footer (Theme & Logout)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          MitraUmkmAdminApp.of(context).isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        ),
                        title: Text(MitraUmkmAdminApp.of(context).isDarkMode ? 'Light Mode' : 'Dark Mode', style: const TextStyle(fontSize: 14)),
                        onTap: () {
                          MitraUmkmAdminApp.of(context).toggleTheme();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text('Keluar', style: TextStyle(color: Colors.red, fontSize: 14)),
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final String route;
  final String currentRoute;

  const _NavItem({
    Key? key,
    required this.title,
    required this.icon,
    required this.route,
    required this.currentRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Treat '/' and '/dashboard' as the same
    bool isActive = currentRoute == route || (route == '/' && currentRoute == '/dashboard');

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0F766E).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? const Color(0xFF0F766E) : Theme.of(context).iconTheme.color,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFF0F766E) : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () {
          if (!isActive) {
            Navigator.of(context).pushReplacementNamed(route);
          }
        },
      ),
    );
  }
}
