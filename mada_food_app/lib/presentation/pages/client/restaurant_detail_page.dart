// lib/presentation/pages/client/restaurant_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/client/restaurant_provider.dart';
import '../../providers/client/cart_provider.dart';
import '../../widgets/client/plat_card.dart';
import '../../../domain/entities/restaurant_entity.dart';
import '../../../domain/entities/plat.dart';

class RestaurantDetailPage extends ConsumerStatefulWidget {
  final String restaurantId;
  const RestaurantDetailPage({super.key, required this.restaurantId});

  @override
  ConsumerState<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends ConsumerState<RestaurantDetailPage> {
  // Controleur pour la barre de recherche
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final platsAsync = ref.watch(clientRestaurantPlatsProvider(widget.restaurantId));
    final restaurantsAsync = ref.watch(clientRestaurantsProvider);
    
    // Recuperation du restaurant
    RestaurantEntity? restaurant;
    final restaurants = restaurantsAsync.valueOrNull;
    if (restaurants != null) {
      try {
        restaurant = restaurants.firstWhere(
          (r) => r.id == widget.restaurantId,
        );
      } catch (e) {
        // Creation d'un placeholder si le restaurant n'est pas trouve
        restaurant = RestaurantEntity(
          id: widget.restaurantId,
          nom: 'Restaurant',
          adresse: '',
          estOuvert: false,
          dateCreation: DateTime.now(),
        );
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(restaurant),
      body: platsAsync.when(
        data: (plats) {
          // Filtrage des plats par recherche
          final filteredPlats = plats.where((plat) {
            if (_searchQuery.isEmpty) return true;
            final query = _searchQuery.toLowerCase().trim();
            return plat.nom.toLowerCase().contains(query) ||
                   plat.description?.toLowerCase().contains(query) == true;
          }).toList();

          if (plats.isEmpty) {
            return _buildEmptyPlats();
          }

          return Column(
            children: [
              // Barre de recherche
              _buildSearchBar(),
              
              // Resultats ou message si aucun resultat
              if (filteredPlats.isEmpty)
                _buildEmptySearchResults()
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.refresh(clientRestaurantPlatsProvider(widget.restaurantId));
                    },
                    color: Colors.orange.shade700,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                      itemCount: filteredPlats.length,
                      itemBuilder: (context, index) {
                        final plat = filteredPlats[index];
                        return PlatCard(
                          plat: plat,
                          onAddToCart: () {
                            ref.read(cartProvider.notifier).addItem(plat);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${plat.nom} ajoute au panier'),
                                backgroundColor: Colors.green.shade600,
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => _buildLoadingState(),
        error: (err, stack) => _buildErrorState(err),
      ),
    );
  }

  // Barre d'applications personnalisee
  PreferredSizeWidget _buildAppBar(RestaurantEntity? restaurant) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            restaurant?.nom ?? 'Details',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              letterSpacing: 0.3,
            ),
          ),
          if (restaurant?.estOuvert == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade300.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Ouvert',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      backgroundColor: Colors.orange.shade700,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => context.pop(),
        tooltip: 'Retour',
      ),
      actions: [
        // Bouton du panier avec compteur
        Consumer(
          builder: (context, ref, child) {
            final itemCount = ref.watch(cartItemsCountProvider);
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () => context.push('/client/cart'),
                  tooltip: 'Voir le panier',
                ),
                if (itemCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        itemCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.orange.shade300,
        ),
      ),
    );
  }

  // Barre de recherche
  Widget _buildSearchBar() {
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
      child: Container(
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
            hintText: 'Rechercher un plat...',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.orange.shade400,
              size: 22,
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
    );
  }

  // Etat de chargement
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 48,
            width: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Chargement des plats...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Etat d'erreur
  Widget _buildErrorState(Object err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 40,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            err.toString(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
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
            onPressed: () {
              ref.refresh(clientRestaurantPlatsProvider(widget.restaurantId));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reessayer'),
          ),
        ],
      ),
    );
  }

  // Message quand aucun plat n'est disponible
  Widget _buildEmptyPlats() {
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
              Icons.restaurant_menu,
              size: 50,
              color: Colors.orange.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun plat disponible',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ce restaurant n\'a pas encore de plats',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // Message quand aucun resultat de recherche
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
              'Aucun plat trouve',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez une autre recherche',
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
                });
              },
              icon: Icon(Icons.clear, color: Colors.orange.shade700),
              label: Text(
                'Effacer la recherche',
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
}