// lib/presentation/widgets/admin/admin_sidebar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.orange.shade50,
      child: Column(
        children: [
          Container(
            height: 80,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.fastfood, color: Colors.orange, size: 32),
                const SizedBox(width: 8),
                const Text(
                  'MadaFood',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                _buildItem(
                  index: 0,
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                ),
                _buildItem(
                  index: 1,
                  icon: Icons.restaurant,
                  label: 'Restaurants',
                ),
                _buildItem(
                  index: 2,
                  icon: Icons.people,
                  label: 'Utilisateurs',
                ),
                _buildItem(
                  index: 3,
                  icon: Icons.shopping_cart,
                  label: 'Commandes',
                ),
                const Divider(),
                // Actions rapides dans la sidebar
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'ACTIONS RAPIDES',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.add_business, color: Colors.orange),
                  title: const Text('Créer un restaurant'),
                  onTap: () {
                    context.go('/admin/restaurants/create');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_add, color: Colors.blue),
                  title: const Text('Créer un restaurateur'),
                  onTap: () {
                    context.go('/admin/users/create-restaurateur');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Déconnexion',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    context.go('/');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.orange : Colors.grey,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.orange : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? Colors.orange.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () => onItemSelected(index),
    );
  }
}