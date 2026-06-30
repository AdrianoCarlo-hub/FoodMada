// lib/presentation/pages/admin/create_restaurant_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/admin/admin_dashboard_provider.dart';

class CreateRestaurantPage extends ConsumerStatefulWidget {
  const CreateRestaurantPage({super.key});

  @override
  ConsumerState<CreateRestaurantPage> createState() => _CreateRestaurantPageState();
}

class _CreateRestaurantPageState extends ConsumerState<CreateRestaurantPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _adresseController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  String? _selectedCuisineType;
  bool _isActive = true;

  // Options pour le type de cuisine
  final List<String> _cuisineTypes = [
    'Malagasy',
    'Chinois',
    'Francais',
    'Italien',
    'Indien',
    'Japonais',
    'Americain',
    'Fast Food',
    'Patisserie',
    'Cafe',
    'Autre',
  ];

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _descriptionController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Soumission du formulaire
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Veuillez corriger les erreurs', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.createRestaurant(
        nom: _nomController.text.trim(),
        adresse: _adresseController.text.trim(),
        latitude: double.tryParse(_latitudeController.text.trim()),
        longitude: double.tryParse(_longitudeController.text.trim()),
      );

      if (mounted) {
        _showSnackBar('Restaurant cree avec succes', Colors.green);
        context.go('/admin/restaurants');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erreur: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Affichage d'un message
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Dialogue d'aide
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Comment creer un restaurant'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Remplissez le nom et la description'),
            Text('2. Entrez le telephone et l\'email'),
            Text('3. Saisissez l\'adresse complete'),
            Text('4. Ajoutez les coordonnees GPS'),
            Text('5. Selectionnez le type de cuisine'),
            Text('6. Cliquez sur "Creer le restaurant"'),
            SizedBox(height: 12),
            Text(
              'Les coordonnees GPS aident les clients a trouver le restaurant',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fermer',
              style: TextStyle(color: Colors.orange.shade700),
            ),
          ),
        ],
      ),
    );
  }

  // Dialogue de confirmation d'annulation
  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Annuler la creation ?'),
        content: const Text(
          'Toutes les informations saisies seront perdues. '
          'Voulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Non, continuer',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              context.go('/admin/restaurants');
            },
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  // Reinitialiser le formulaire
  void _resetForm() {
    setState(() {
      _nomController.clear();
      _adresseController.clear();
      _latitudeController.clear();
      _longitudeController.clear();
      _descriptionController.clear();
      _telephoneController.clear();
      _emailController.clear();
      _selectedCuisineType = null;
      _isActive = true;
      _formKey.currentState?.reset();
    });
    _showSnackBar('Formulaire reinitialise', Colors.blue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Creer un restaurant',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.go('/admin/restaurants'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Aide',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.orange.shade300,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // En-tete
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange.shade50,
                        Colors.orange.shade100,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.add_business,
                          color: Colors.orange.shade700,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nouveau restaurant',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Remplissez les informations ci-dessous',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),

                // Information champs obligatoires
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Les champs avec * sont obligatoires',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'REQUIS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // Section 1: Informations principales
                const Text(
                  'Informations principales',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 2,
                  color: Colors.orange.shade200,
                ),
                const SizedBox(height: 16),

                // Nom du restaurant
                TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du restaurant *',
                    hintText: 'Ex: Chez Soa',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.restaurant),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer un nom';
                    }
                    if (value.trim().length < 3) {
                      return 'Le nom doit contenir au moins 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Decrivez votre restaurant...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 16),

                // Telephone
                TextFormField(
                  controller: _telephoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: 'Telephone *',
                    hintText: 'Ex: 0342525281',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer un numero de telephone';
                    }
                    final cleaned = value.trim().replaceAll(RegExp(r'[^\d]'), '');
                    if (cleaned.length != 10) {
                      return 'Le numero doit contenir exactement 10 chiffres';
                    }
                    if (!RegExp(r'^[0-9]{10}$').hasMatch(cleaned)) {
                      return 'Veuillez entrer un numero valide (10 chiffres)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    hintText: 'Ex: contact@restaurant.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer un email';
                    }
                    final email = value.trim();
                    if (!email.contains('@') || !email.contains('.')) {
                      return 'Email invalide (doit contenir @ et .)';
                    }
                    if (email.length < 6) {
                      return 'Email trop court';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Section 2: Localisation
                const Text(
                  'Localisation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 2,
                  color: Colors.blue.shade200,
                ),
                const SizedBox(height: 16),

                // Adresse
                TextFormField(
                  controller: _adresseController,
                  decoration: const InputDecoration(
                    labelText: 'Adresse *',
                    hintText: 'Ex: Antananarivo, Ambohijatovo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer une adresse';
                    }
                    if (value.trim().length < 5) {
                      return 'Adresse trop courte';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Latitude et Longitude
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          hintText: 'Ex: -18.8792',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.my_location),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (double.tryParse(value) == null) {
                              return 'Latitude invalide';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          hintText: 'Ex: 47.5079',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.my_location),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (double.tryParse(value) == null) {
                              return 'Longitude invalide';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Section 3: Options
                const Text(
                  'Options',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 2,
                  color: Colors.green.shade200,
                ),
                const SizedBox(height: 16),

                // Type de cuisine
                DropdownButtonFormField<String>(
                  value: _selectedCuisineType,
                  decoration: const InputDecoration(
                    labelText: 'Type de cuisine',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.restaurant_menu),
                  ),
                  items: _cuisineTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCuisineType = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Statut actif
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      'Restaurant actif',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: const Text(
                      'Desactiver pour masquer le restaurant',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _isActive,
                    activeColor: Colors.green.shade600,
                    activeTrackColor: Colors.green.shade100,
                    inactiveTrackColor: Colors.red.shade100,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 24),

                // Apercu
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange.shade50,
                        Colors.orange.shade100,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Apercu du restaurant',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_nomController.text.isNotEmpty)
                        Text('• Nom: ${_nomController.text}'),
                      if (_adresseController.text.isNotEmpty)
                        Text('• Adresse: ${_adresseController.text}'),
                      if (_selectedCuisineType != null)
                        Text('• Cuisine: $_selectedCuisineType'),
                      if (_isActive)
                        const Text('• Statut: Actif'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Bouton Creer
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save, size: 22),
                  label: _isLoading
                      ? const Text(
                          'Creation en cours...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : const Text(
                          'Creer le restaurant',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 12),

                // Boutons secondaires
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () {
                                _showCancelDialog(context);
                              },
                        icon: Icon(
                          Icons.cancel_outlined,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        label: Text(
                          'Annuler',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.orange.shade300,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _resetForm,
                        icon: Icon(
                          Icons.refresh_outlined,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        label: Text(
                          'Reinitialiser',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}