// lib/presentation/pages/admin/create_restaurateur_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/admin/admin_dashboard_provider.dart';
import '../../../domain/entities/restaurant_entity.dart';

class CreateRestaurateurPage extends ConsumerStatefulWidget {
  const CreateRestaurateurPage({super.key});

  @override
  ConsumerState<CreateRestaurateurPage> createState() => _CreateRestaurateurPageState();
}

class _CreateRestaurateurPageState extends ConsumerState<CreateRestaurateurPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _restaurantSearchController = TextEditingController();
  
  String? _selectedRestaurantId;
  bool _isLoading = false;
  bool _isLoadingRestaurants = true;
  List<RestaurantEntity> _restaurants = [];
  RestaurantEntity? _selectedRestaurant;
  String _restaurantSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _restaurantSearchController.dispose();
    super.dispose();
  }

  // Chargement de la liste des restaurants
  Future<void> _loadRestaurants() async {
    if (!mounted) return;
    setState(() => _isLoadingRestaurants = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final restaurants = await repo.getAllRestaurants();
      if (!mounted) return;
      setState(() {
        _restaurants = restaurants;
        if (restaurants.isNotEmpty) {
          _selectedRestaurantId = restaurants.first.id;
          _selectedRestaurant = restaurants.first;
        }
        _isLoadingRestaurants = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRestaurants = false);
      _showSnackBar('Erreur lors du chargement des restaurants: $e', Colors.red);
    }
  }

  // Soumission du formulaire
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Veuillez corriger les erreurs', Colors.red);
      return;
    }

    if (_selectedRestaurantId == null) {
      _showSnackBar('Veuillez selectionner un restaurant', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.createRestaurateur(
        nom: _nomController.text.trim(),
        telephone: _telephoneController.text.trim(),
        motDePasse: _passwordController.text.trim(),
        restaurantId: _selectedRestaurantId!,
      );

      if (mounted) {
        _showSnackBar('Restaurateur cree avec succes', Colors.green);
        context.go('/admin/users');
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
    if (!mounted) return;
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
            const Text('Comment creer un restaurateur'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Remplissez les informations personnelles'),
            Text('2. Choisissez un mot de passe securise'),
            Text('3. Associez un restaurant existant'),
            Text('4. Cliquez sur "Creer le restaurateur"'),
            SizedBox(height: 12),
            Text(
              'Le restaurateur pourra se connecter avec son telephone et son mot de passe',
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
              context.go('/admin/users');
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
      _telephoneController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _emailController.clear();
      _restaurantSearchController.clear();
      _restaurantSearchQuery = '';
      if (_restaurants.isNotEmpty) {
        _selectedRestaurantId = _restaurants.first.id;
        _selectedRestaurant = _restaurants.first;
      }
      _formKey.currentState?.reset();
    });
    _showSnackBar('Formulaire reinitialise', Colors.blue);
  }

  @override
  Widget build(BuildContext context) {
    // Filtrer les restaurants par recherche
    final filteredRestaurants = _restaurants.where((restaurant) {
      if (_restaurantSearchQuery.isEmpty) return true;
      final query = _restaurantSearchQuery.toLowerCase().trim();
      return restaurant.nom.toLowerCase().contains(query) ||
             restaurant.adresse.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Creer un restaurateur',
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
          onPressed: () => context.go('/admin/users'),
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
      body: _isLoadingRestaurants
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 40,
                    width: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chargement des restaurants...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
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
                              Icons.person_add,
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
                                  'Nouveau restaurateur',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  'Creation d\'un compte restaurateur',
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

                    // Section 1: Informations personnelles
                    const Text(
                      'Informations personnelles',
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

                    // Nom complet
                    TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet *',
                        hintText: 'Ex: Jean RANDRIANARIVO',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
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

                    // Telephone
                    TextFormField(
                      controller: _telephoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: 'Numero de telephone *',
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
                        hintText: 'Ex: jean@restaurant.com',
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

                    // Section 2: Securite
                    const Text(
                      'Securite',
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

                    // Mot de passe
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe *',
                        hintText: 'Minimum 6 caracteres',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un mot de passe';
                        }
                        if (value.length < 6) {
                          return 'Le mot de passe doit contenir au moins 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirmation mot de passe
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirmer le mot de passe *',
                        hintText: 'Re-tapez le mot de passe',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez confirmer le mot de passe';
                        }
                        if (value != _passwordController.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Section 3: Association restaurant
                    const Text(
                      'Association au restaurant',
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

                    if (_restaurants.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.restaurant,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Aucun restaurant disponible',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                context.go('/admin/restaurants/create');
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Creer un restaurant'),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          // Barre de recherche pour les restaurants
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1.5,
                              ),
                            ),
                            child: TextField(
                              controller: _restaurantSearchController,
                              decoration: InputDecoration(
                                hintText: 'Rechercher un restaurant...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.orange.shade400,
                                ),
                                suffixIcon: _restaurantSearchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          color: Colors.grey.shade400,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _restaurantSearchController.clear();
                                            _restaurantSearchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _restaurantSearchQuery = value;
                                });
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Affichage du restaurant selectionne
                          if (_selectedRestaurant != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Restaurant selectionne',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          _selectedRestaurant!.nom,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedRestaurant!.estOuvert
                                          ? Colors.green.shade100
                                          : Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _selectedRestaurant!.estOuvert ? 'Ouvert' : 'Ferme',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedRestaurant!.estOuvert
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          const SizedBox(height: 12),
                          
                          // Dropdown pour changer de restaurant
                          if (filteredRestaurants.isNotEmpty)
                            DropdownButtonFormField<String>(
                              value: _selectedRestaurantId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Changer de restaurant *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.swap_horiz),
                              ),
                              items: filteredRestaurants.map((restaurant) {
                                final isSelected = restaurant.id == _selectedRestaurantId;
                                return DropdownMenuItem<String>(
                                  value: restaurant.id,
                                  child: Row(
                                    children: [
                                      Icon(
                                        restaurant.estOuvert 
                                            ? Icons.check_circle 
                                            : Icons.cancel,
                                        color: restaurant.estOuvert 
                                            ? Colors.green 
                                            : Colors.red,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          restaurant.nom,
                                          style: TextStyle(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: isSelected ? Colors.orange.shade700 : Colors.grey.shade800,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check,
                                          color: Colors.orange.shade700,
                                          size: 16,
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _selectedRestaurantId = value;
                                  _selectedRestaurant = _restaurants.firstWhere(
                                    (r) => r.id == value,
                                  );
                                  // Effacer la recherche apres selection
                                  _restaurantSearchController.clear();
                                  _restaurantSearchQuery = '';
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Veuillez selectionner un restaurant';
                                }
                                return null;
                              },
                            ),
                          if (filteredRestaurants.isEmpty && _restaurantSearchQuery.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Aucun restaurant trouve',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 24),

                    // Apercu
                    if (_selectedRestaurant != null || 
                        _nomController.text.isNotEmpty || 
                        _telephoneController.text.isNotEmpty ||
                        _emailController.text.isNotEmpty)
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
                              'Apercu du restaurateur',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_nomController.text.isNotEmpty)
                              Text('• Nom: ${_nomController.text}'),
                            if (_telephoneController.text.isNotEmpty)
                              Text('• Telephone: ${_telephoneController.text}'),
                            if (_emailController.text.isNotEmpty)
                              Text('• Email: ${_emailController.text}'),
                            if (_selectedRestaurant != null)
                              Text('• Restaurant: ${_selectedRestaurant!.nom}'),
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
                              'Creer le restaurateur',
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
    );
  }
}