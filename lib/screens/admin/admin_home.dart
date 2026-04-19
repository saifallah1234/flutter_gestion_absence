// lib/screens/admin/admin_home.dart
import 'package:flutter/material.dart';
import 'etudiants_screen.dart';
import 'enseignants_screen.dart';
import 'classes_screen.dart';
import 'seances_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    EtudiantsScreen(),
    EnseignantsScreen(),
    ClassesScreen(),
    SeancesScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = [
    {'title': 'Étudiants', 'icon': Icons.people},
    {'title': 'Enseignants', 'icon': Icons.person_outline},
    {'title': 'Classes', 'icon': Icons.class_},
    {'title': 'Séances', 'icon': Icons.calendar_today},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF000666),
                    Color(0xFF1A237E),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Admin Panel',
              style: TextStyle(
                color: Color(0xFF000666),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF000666),
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
          ),
          elevation: 0,
          items: _navItems.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item['icon']),
              label: item['title'],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/');
            },
            child: const Text(
              'Se déconnecter',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}