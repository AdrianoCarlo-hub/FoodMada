// lib/presentation/pages/admin/admin_restaurants_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/admin/admin_dashboard_provider.dart';
import '../../../domain/entities/restaurant_entity.dart';
import '../../../domain/entities/user_entity.dart';

class AdminRestaurantsPage extends ConsumerStatefulWidget {
  const AdminRestaurantsPage({super.key});

  @override
  ConsumerState<AdminRestaurantsPage> createState() => _AdminRestaurantsPageState();
}

class _AdminRestaurantsPageState extends ConsumerState<AdminRestaurantsPage> {
  // Controleur pour la barre de recherche
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'Tous';

  // Options de filtrage par statut
  final List<String> _statusOptions = [
    'Tous',
    'Ouvert',
    'Ferme',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(adminRestaurantsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Gestion des restaurants',
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
          onPressed: () => context.go('/admin-home'),
          tooltip: 'Retour au tableau de bord',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(adminRestaurantsProvider);
            },
            tooltip: 'Rafraichir',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.go('/admin/restaurants/create');
            },
            tooltip: 'Ajouter un restaurant',
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
      body: restaurantsAsync.when(
        data: (restaurants) {
          // Filtrage des restaurants par recherche
          final filteredBySearch = restaurants.where((restaurant) {
            if (_searchQuery.isEmpty) return true;
            final query = _searchQuery.toLowerCase().trim();
            return restaurant.nom.toLowerCase().contains(query) ||
                   restaurant.adresse.toLowerCase().contains(query);
          }).toList();

          // Filtrage par statut
          final filteredRestaurants = filteredBySearch.where((restaurant) {
            if (_statusFilter == 'Tous') return true;
            if (_statusFilter == 'Ouvert') return restaurant.estOuvert;
            if (_statusFilter == 'Ferme') return !restaurant.estOuvert;
            return true;
          }).toList();

          if (restaurants.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // Barre de recherche et filtres
              _buildSearchAndFilters(),
              
              // Liste des restaurants
              if (filteredRestaurants.isEmpty)
                _buildEmptySearchResults()
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.refresh(adminRestaurantsProvider);
                    },
                    color: Colors.orange.shade700,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredRestaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = filteredRestaurants[index];
                        return _RestaurantCard(
                          key: ValueKey(restaurant.id),
                          restaurant: restaurant,
                          onChanged: () {
                            ref.refresh(adminRestaurantsProvider);
                          },
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(
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
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'Erreur: $err',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  ref.refresh(adminRestaurantsProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Barre de recherche et filtres
  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Champ de recherche
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
              controller: _searchController,
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
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
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
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          // Filtres de statut
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusOptions.map((status) {
                final isSelected = _statusFilter == status;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _statusFilter = status;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getStatusFilterColor(status)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? _getStatusFilterColor(status)
                            : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusFilterIcon(status),
                          size: 14,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Etat vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant,
              size: 50,
              color: Colors.orange.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun restaurant',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Creez votre premier restaurant',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => context.go('/admin/restaurants/create'),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un restaurant'),
          ),
        ],
      ),
    );
  }

  // Resultats de recherche vides
  Widget _buildEmptySearchResults() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 60,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun restaurant trouve',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez une autre recherche ou modifiez les filtres',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _statusFilter = 'Tous';
                });
              },
              icon: Icon(Icons.clear, color: Colors.orange.shade700),
              label: Text(
                'Effacer les filtres',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Couleur du filtre de statut
  Color _getStatusFilterColor(String status) {
    switch (status) {
      case 'Tous':
        return Colors.orange.shade700;
      case 'Ouvert':
        return Colors.green;
      case 'Ferme':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Icone du filtre de statut
  IconData _getStatusFilterIcon(String status) {
    switch (status) {
      case 'Tous':
        return Icons.list_alt;
      case 'Ouvert':
        return Icons.check_circle_outline;
      case 'Ferme':
        return Icons.cancel_outlined;
      default:
        return Icons.circle;
    }
  }
}

// ===== CARTE D'UN RESTAURANT =====
class _RestaurantCard extends ConsumerStatefulWidget {
  final RestaurantEntity restaurant;
  final VoidCallback onChanged;

  const _RestaurantCard({
    super.key,
    required this.restaurant,
    required this.onChanged,
  });

  @override
  ConsumerState<_RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends ConsumerState<_RestaurantCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tete avec nom et statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.restaurant,
                          color: Colors.orange.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant.nom,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              restaurant.adresse,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: restaurant.estOuvert
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: restaurant.estOuvert
                              ? Colors.green
                              : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.estOuvert ? 'Ouvert' : 'Ferme',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: restaurant.estOuvert
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            
            // Date de creation
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 6),
                Text(
                  'Cree le: ${_formatDate(restaurant.dateCreation)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.shade100,
            ),
            const SizedBox(height: 12),
            
            // Boutons d'action
            Row(
              children: [
                // Bouton Ouvrir/Fermer
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: restaurant.estOuvert
                          ? Colors.red.shade600
                          : Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _toggleStatus,
                    icon: Icon(
                      restaurant.estOuvert ? Icons.close : Icons.check,
                      size: 16,
                    ),
                    label: Text(
                      restaurant.estOuvert ? 'Fermer' : 'Ouvrir',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Bouton Modifier
                Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _showEditDialog,
                    icon: Icon(
                      Icons.edit_outlined,
                      color: Colors.orange.shade700,
                      size: 22,
                    ),
                    tooltip: 'Modifier le restaurant',
                  ),
                ),
                const SizedBox(width: 4),
                // Bouton Affecter restaurateur
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _showAssignDialog,
                    icon: Icon(
                      Icons.person_add_outlined,
                      color: Colors.blue.shade700,
                      size: 22,
                    ),
                    tooltip: 'Affecter un restaurateur',
                  ),
                ),
                const SizedBox(width: 4),
                // Bouton Supprimer
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _deleteRestaurant,
                    icon: Icon(
                      Icons.delete_outlined,
                      color: Colors.red.shade400,
                      size: 22,
                    ),
                    tooltip: 'Supprimer le restaurant',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Formatage de la date
  String _formatDate(DateTime date) {
    final months = [
      'janv.', 'fevr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'aout', 'sept.', 'oct.', 'nov.', 'dec.'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Basculer le statut du restaurant
  Future<void> _toggleStatus() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.updateRestaurantStatus(
        widget.restaurant.id,
        !widget.restaurant.estOuvert,
      );
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.restaurant.estOuvert
                  ? 'Restaurant ferme avec succes'
                  : 'Restaurant ouvert avec succes',
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Dialogue de modification du restaurant
  Future<void> _showEditDialog() async {
    final restaurant = widget.restaurant;
    final nomController = TextEditingController(text: restaurant.nom);
    final adresseController = TextEditingController(text: restaurant.adresse);
    final latitudeController = TextEditingController(
      text: restaurant.latitude?.toString() ?? '',
    );
    final longitudeController = TextEditingController(
      text: restaurant.longitude?.toString() ?? '',
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.edit_outlined, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Modifier le restaurant'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  prefixIcon: Icon(Icons.restaurant),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: adresseController,
                decoration: const InputDecoration(
                  labelText: 'Adresse *',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latitudeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        prefixIcon: Icon(Icons.my_location),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: longitudeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        prefixIcon: Icon(Icons.my_location),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final nom = nomController.text.trim();
              final adresse = adresseController.text.trim();
              final latitude = double.tryParse(latitudeController.text.trim());
              final longitude = double.tryParse(longitudeController.text.trim());

              if (nom.isEmpty || adresse.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez remplir tous les champs obligatoires'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _saveRestaurantChanges(
                nom: nom,
                adresse: adresse,
                latitude: latitude,
                longitude: longitude,
              );
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  // Sauvegarder les modifications du restaurant
  Future<void> _saveRestaurantChanges({
    required String nom,
    required String adresse,
    double? latitude,
    double? longitude,
  }) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.updateRestaurant(
        widget.restaurant.id,
        nom: nom,
        adresse: adresse,
        latitude: latitude,
        longitude: longitude,
      );
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restaurant modifie avec succes'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Dialogue d'affectation d'un restaurateur
  Future<void> _showAssignDialog() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final restaurateurs = await repo.getAvailableRestaurateurs();

      if (restaurateurs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun restaurateur disponible'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      String? selectedUserId;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.person_add_outlined, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text('Affecter un restaurateur'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selectionnez un restaurateur a affecter a ce restaurant :',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Choisissez un restaurateur',
                  prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade600),
                ),
                items: restaurateurs.map((user) {
                  return DropdownMenuItem(
                    value: user.id,
                    child: Text('${user.nom} (${user.telephone})'),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedUserId = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (selectedUserId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez selectionner un restaurateur'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                await _assignRestaurateur(selectedUserId!);
              },
              child: const Text('Affecter'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Affecter un restaurateur
  Future<void> _assignRestaurateur(String userId) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.assignRestaurateur(userId, widget.restaurant.id);
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restaurateur affecte avec succes'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Supprimer un restaurant
  Future<void> _deleteRestaurant() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red.shade400),
            const SizedBox(width: 8),
            const Text('Supprimer le restaurant'),
          ],
        ),
        content: Text(
          'Etes-vous sur de vouloir supprimer "${widget.restaurant.nom}" ?\n\n'
          'Cette action est irreversible et supprimera egalement '
          'tous les plats associes a ce restaurant.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
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
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.deleteRestaurant(widget.restaurant.id);
      widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restaurant supprime avec succes'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}