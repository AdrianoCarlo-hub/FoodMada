import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade400, Colors.orange.shade900],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fastfood, size: 80, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                "MadaFood",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                "Choisissez votre profil pour continuer",
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 40),
              _buildRoleButton(context, "Je suis un Client", "CLIENT", Icons.person),
              const SizedBox(height: 16),
              _buildRoleButton(context, "Je suis un Restaurateur", "RESTAURATEUR", Icons.restaurant),
              const SizedBox(height: 16),
              _buildRoleButton(context, "Je suis un Administrateur", "ADMIN", Icons.admin_panel_settings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(BuildContext context, String title, String roleCode, IconData icon) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.orange.shade900,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
        ),
        onPressed: () {
          // Navigue vers le login en passant le rôle sélectionné en paramètre optionnel ou query
          context.push('/login?role=$roleCode');
        },
        icon: Icon(icon, size: 24),
        label: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}