import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  final String role;
  const RegisterPage({super.key, required this.role});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nomController = TextEditingController();
  final _telController = TextEditingController();
  final _pwdController = TextEditingController();

  Future<void> _handleRegister() async {
    final nom = _nomController.text.trim();
    final tel = _telController.text.trim();
    final pwd = _pwdController.text.trim();

    if (nom.isEmpty || tel.isEmpty || pwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez remplir tous les champs')));
      return;
    }

    await ref.read(authNotifierProvider.notifier).register(
      nom: nom,
      telephone: tel,
      password: pwd,
      role: widget.role,
    );

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    if (authState.hasValue && authState.value != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inscription réussie !')));
      context.go('/login?role=${widget.role}');
    } else if (authState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authState.error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Inscription - ${widget.role}')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text('Créer un compte ${widget.role.toLowerCase()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 32),
                TextField(controller: _nomController, decoration: const InputDecoration(labelText: 'Nom complet', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
                const SizedBox(height: 16),
                TextField(controller: _telController, decoration: const InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))),
                const SizedBox(height: 16),
                TextField(controller: _pwdController, obscureText: true, decoration: const InputDecoration(labelText: 'Mot de passe', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: authState.isLoading ? null : _handleRegister,
                    child: authState.isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('S\'inscrire', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}