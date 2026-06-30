// lib/presentation/pages/restaurateur/modifier_plat_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/plat.dart';
import '../../../presentation/providers/restaurateur/restaurateur_provider.dart';
import '../../../presentation/providers/auth_provider.dart';

class ModifierPlatPage extends ConsumerStatefulWidget {
  final String platId;
  const ModifierPlatPage({super.key, required this.platId});

  @override
  ConsumerState<ModifierPlatPage> createState() => _ModifierPlatPageState();
}

class _ModifierPlatPageState extends ConsumerState<ModifierPlatPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prixController = TextEditingController();

  bool _estDisponible = true;
  bool _isLoading = false;
  bool _isLoadingPlat = true;
  Plat? _plat;

  static const Color _primaryColor = Color(0xFFFF6B00);
  static const Color _backgroundColor = Color(0xFFF5F6FA);

  @override
  void initState() {
    super.initState();
    _loadPlat();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    super.dispose();
  }

  Future<void> _loadPlat() async {
    setState(() => _isLoadingPlat = true);
    
    try {
      final platsAsync = ref.read(restaurateurPlatsProvider);
      final plats = platsAsync.valueOrNull;
      
      if (plats != null) {
        final plat = plats.firstWhere(
          (p) => p.id == widget.platId,
          orElse: () => throw Exception('Plat non trouvé'),
        );
        
        setState(() {
          _plat = plat;
          _nomController.text = plat.nom;
          _descriptionController.text = plat.description ?? '';
          _prixController.text = plat.prix.toString();
          _estDisponible = plat.estDisponible;
          _isLoadingPlat = false;
        });
      } else {
        await ref.refresh(restaurateurPlatsProvider.future);
        final newPlats = ref.read(restaurateurPlatsProvider).valueOrNull;
        
        if (newPlats != null) {
          final plat = newPlats.firstWhere(
            (p) => p.id == widget.platId,
            orElse: () => throw Exception('Plat non trouvé'),
          );
          
          setState(() {
            _plat = plat;
            _nomController.text = plat.nom;
            _descriptionController.text = plat.description ?? '';
            _prixController.text = plat.prix.toString();
            _estDisponible = plat.estDisponible;
            _isLoadingPlat = false;
          });
        } else {
          throw Exception('Impossible de charger les plats');
        }
      }
    } catch (e) {
      print('❌ Erreur chargement plat: $e');
      setState(() => _isLoadingPlat = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez corriger les erreurs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await ref.read(authNotifierProvider.notifier).getToken();
      
      if (token == null || token.isEmpty) {
        throw Exception('Non authentifié');
      }

      final prix = double.tryParse(_prixController.text.trim()) ?? 0;
      
      if (prix <= 0) {
        throw Exception('Le prix doit être supérieur à 0');
      }

      // ✅ CORRECTION : Utiliser copyWith pour conserver les données existantes
      if (_plat == null) {
        throw Exception('Plat non chargé');
      }

      final updatedPlat = _plat!.copyWith(
        nom: _nomController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        prix: prix,
        estDisponible: _estDisponible,
      );

      print('🔍 [MODIFIER_PLAT] Envoi: ${updatedPlat.toJson()}');

      final repo = ref.read(restaurateurRepositoryProvider);
      await repo.updatePlat(widget.platId, updatedPlat);

      ref.refresh(restaurateurPlatsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Plat modifié avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/restaurateur-home');
      }
    } catch (e) {
      print('❌ [MODIFIER_PLAT] Erreur: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le plat'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/restaurateur-home'),
        ),
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
        child: _isLoadingPlat
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Chargement du plat...'),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Modifier les informations du plat',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),

                        TextFormField(
                          controller: _nomController,
                          decoration: const InputDecoration(
                            labelText: 'Nom du plat *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.food_bank),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Veuillez entrer un nom';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _prixController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Prix *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                            suffixText: 'Ar',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Veuillez entrer un prix';
                            }
                            final prix = double.tryParse(value.trim());
                            if (prix == null) {
                              return 'Prix invalide';
                            }
                            if (prix <= 0) {
                              return 'Le prix doit être supérieur à 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            const Text('Disponible'),
                            const Spacer(),
                            Switch(
                              value: _estDisponible,
                              onChanged: (value) {
                                setState(() {
                                  _estDisponible = value;
                                });
                              },
                              activeColor: _primaryColor,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _isLoading ? null : _submit,
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
                                  'Modifier le plat',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _isLoading ? null : () => context.go('/restaurateur-home'),
                          child: const Text('Annuler'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}