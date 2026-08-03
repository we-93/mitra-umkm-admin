import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mitra_umkm_admin/main.dart';
import 'package:mitra_umkm_admin/theme/admin_theme.dart';

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
    final isDark = MitraUmkmAdminApp.of(context).isDarkMode;
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'admin@mitraumkm.com';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        Widget sidebar = _buildSidebar(context, isDark, isMobile);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF262626) : Colors.white,
            elevation: isDark ? 0 : 4,
            shadowColor: Colors.black.withOpacity(0.3),
            iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF0F766E)),
            title: Row(
              children: [
                Image.asset('assets/images/logo.png', height: 32),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: isDark ? Colors.white : const Color(0xFF0F766E)),
                onPressed: () {
                  MitraUmkmAdminApp.of(context).toggleTheme();
                },
              ),
              const SizedBox(width: 12),
              if (!isMobile)
                Center(
                  child: Text(
                    email,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F766E),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.transparent,
                backgroundImage: const AssetImage('assets/images/icon.png'),
              ),
              const SizedBox(width: 16),
            ],
          ),
          drawer: isMobile ? Drawer(child: sidebar) : null,
          body: Row(
            children: [
              if (!isMobile) sidebar,
              Expanded(child: child),
            ],
          ),
        );
      }
    );
  }

  Widget _buildSidebar(BuildContext context, bool isDark, bool isMobile) {
    final bgColor = isDark ? const Color(0xFF262626) : const Color(0xFF0F766E);

    return Container(
      width: 250,
      color: bgColor,
      child: Column(
        children: [
          const SizedBox(height: 24),
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
                  isMobile: isMobile,
                ),
                _NavItem(
                  title: 'Pengguna',
                  icon: Icons.people_outline,
                  route: '/users',
                  currentRoute: currentRoute,
                  isMobile: isMobile,
                ),
                _NavItem(
                  title: 'Invoices',
                  icon: Icons.receipt_long_outlined,
                  route: '/invoices',
                  currentRoute: currentRoute,
                  isMobile: isMobile,
                ),
                _NavItem(
                  title: 'LMS Edukasi',
                  icon: Icons.school_outlined,
                  route: '/lms',
                  currentRoute: currentRoute,
                  isMobile: isMobile,
                ),
                _NavItem(
                  title: 'Konfigurasi Produk',
                  icon: Icons.inventory_2_outlined,
                  route: '/products_config',
                  currentRoute: currentRoute,
                  isMobile: isMobile,
                ),
                _NavItem(
                  title: 'Konsultan AI',
                  icon: Icons.smart_toy_outlined,
                  route: '/ai',
                  currentRoute: currentRoute,
                  isMobile: isMobile,
                ),
                _NavItem(
                  title: 'Notifikasi',
                  icon: Icons.notifications_outlined,
                  route: '/notifications',
                  currentRoute: currentRoute,
                  isMobile: isMobile,
                ),
                _NavItem(
                  title: 'Pengaturan',
                  icon: Icons.settings_outlined,
                  route: '/settings',
                  currentRoute: currentRoute,
                  isMobile: isMobile,
                ),
              ],
            ),
          ),
          
          // Footer (Logout)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text('Keluar', style: TextStyle(color: Colors.white, fontSize: 14)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
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
  final bool isMobile;

  const _NavItem({
    Key? key,
    required this.title,
    required this.icon,
    required this.route,
    required this.currentRoute,
    required this.isMobile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isActive = currentRoute == route || (route == '/' && currentRoute == '/dashboard');

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white70,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () {
          if (!isActive) {
            Navigator.of(context).pushReplacementNamed(route);
          } else if (isMobile) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
