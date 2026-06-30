import 'package:flutter/material.dart';

class RestaurateurForm extends StatelessWidget {
  final TextEditingController nomCtrl;
  final TextEditingController telCtrl;
  final TextEditingController pwdCtrl;
  final VoidCallback onSubmit;

  const RestaurateurForm({super.key, required this.nomCtrl, required this.telCtrl, required this.pwdCtrl, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nom du Restaurateur')),
      TextField(controller: telCtrl, decoration: const InputDecoration(labelText: 'Téléphone')),
      TextField(controller: pwdCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Mot de passe')),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: onSubmit, child: const Text('Créer Restaurateur')),
    ]);
  }
}