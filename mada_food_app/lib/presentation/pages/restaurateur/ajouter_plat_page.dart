import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart' as dio_client_lib;
import '../../../domain/entities/plat.dart';
import '../../../domain/entities/restaurant_entity.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/restaurateur/restaurateur_provider.dart';

class AjoutPlatPage extends ConsumerStatefulWidget {
  const AjoutPlatPage({super.key});

  @override
  ConsumerState<AjoutPlatPage> createState() => _AjoutPlatPageState();
}

class _AjoutPlatPageState extends ConsumerState<AjoutPlatPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prixController = TextEditingController();
  final _categorieController = TextEditingController();

  bool _isLoading = false;
  String? _selectedRestaurantId;
  bool _disponible = true;

  static const Color _primaryColor = Color(0xFFFF6B00);
  static const Color _backgroundColor = Color(0xFFF5F6FA);

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    _categorieController.dispose();
    super.dispose();
  }

  Future<void> _sauvegarderPlat() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRestaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un restaurant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dioClient = ref.read(dio_client_lib.dioClientProvider);
      final dio = dioClient.dio;
      
      final token = await ref.read(authNotifierProvider.notifier).getToken();

      final platData = {
        'restaurant_id': _selectedRestaurantId,
        'nom': _nomController.text.trim(),
        'description': _descriptionController.text.trim(),
        'prix': double.parse(_prixController.text.trim()),
        'categorie': _categorieController.text.trim(),
        'est_disponible': _disponible,
      };

      final response = await dio.post(
        '/api/restaurateur/plats',
        data: platData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 201) {
        ref.refresh(restaurateurPlatsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plat ajouté avec succès !'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _nomController.clear();
          _descriptionController.clear();
          _prixController.clear();
          _categorieController.clear();
          _selectedRestaurantId = null;
          _disponible = true;
          _isLoading = false;
        });

        Navigator.pop(context, true);
      } else {
        throw Exception('Erreur lors de la sauvegarde');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(restaurateurRestaurantsProvider);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un plat'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Container(
        color: _backgroundColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sélection du restaurant
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Restaurant',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        restaurantsAsync.when(
                          data: (restos) {
                            // ✅ Filtrer les restaurants du restaurateur
                            final mesRestos = user != null
                                ? restos.where((r) => r.proprietaireId == user.id).toList()
                                : [];

                            if (mesRestos.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.restaurant,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Aucun restaurant associé',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Veuillez contacter un administrateur',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }

                            // ✅ CORRECTION : Ajouter le type générique
                            return DropdownButtonFormField<String>(
                              value: _selectedRestaurantId,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Sélectionnez votre restaurant',
                              ),
                              items: mesRestos.map<DropdownMenuItem<String>>((restaurant) {
                                return DropdownMenuItem<String>(
                                  value: restaurant.id,
                                  child: Text(restaurant.nom),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedRestaurantId = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Veuillez sélectionner un restaurant';
                                }
                                return null;
                              },
                            );
                          },
                          loading: () => const Center(
                            child: SizedBox(
                              height: 50,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ),
                          error: (err, stack) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Erreur: $err',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Informations du plat
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nomController,
                          decoration: const InputDecoration(
                            labelText: 'Nom du plat *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.restaurant_menu),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer le nom du plat';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer une description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _prixController,
                                decoration: const InputDecoration(
                                  labelText: 'Prix (Ar) *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.attach_money),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer un prix';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Prix invalide';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _categorieController,
                                decoration: const InputDecoration(
                                  labelText: 'Catégorie',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.category),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Disponible'),
                            const Spacer(),
                            Switch(
                              value: _disponible,
                              onChanged: (value) {
                                setState(() {
                                  _disponible = value;
                                });
                              },
                              activeColor: _primaryColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sauvegarderPlat,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Ajouter le plat',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}