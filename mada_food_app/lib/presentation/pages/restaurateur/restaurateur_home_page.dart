// lib/presentation/pages/restaurateur/restaurateur_home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mada_food_app/domain/entities/commande.dart';
import 'package:mada_food_app/domain/entities/plat.dart';
import '../../providers/restaurateur/restaurateur_provider.dart';
import '../../widgets/restaurateur/stat_card.dart';
import 'ajouter_plat_page.dart';
import 'modifier_plat_page.dart';
import '../../providers/auth_provider.dart';

class RestaurateurHomePage extends ConsumerStatefulWidget {
  const RestaurateurHomePage({super.key});

  @override
  ConsumerState<RestaurateurHomePage> createState() => _RestaurateurHomePageState();
}

class _RestaurateurHomePageState extends ConsumerState<RestaurateurHomePage> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _pages = [
      const RestaurateurDashboard(),
      const RestaurateurPlatsPage(),
      const RestaurateurCommandesPage(),
    ];
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkToken();
    });
  }

  Future<void> _checkToken() async {
    final token = await _storage.read(key: 'jwt_token');
    print('Token dans RestaurateurHomePage: ${token?.substring(0, 20)}...');
    
    if (token == null || token.isEmpty) {
      print('Pas de token - Redirection vers login');
      if (mounted) {
        context.go('/login?role=RESTAURATEUR');
      }
    }
  }

  Future<void> _logout() async {
    await _storage.delete(key: 'jwt_token');
    print('Deconnexion - Token supprime');
    ref.read(authNotifierProvider.notifier).logout();
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.orange.shade700,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            activeIcon: Icon(Icons.restaurant_menu),
            label: 'Mes plats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Commandes',
          ),
        ],
      ),
    );
  }
}

// ===== DASHBOARD RESTAURATEUR =====
class RestaurateurDashboard extends ConsumerWidget {
  const RestaurateurDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(restaurateurStatsProvider);
    final restaurantAsync = ref.watch(restaurateurInfoProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Tableau de bord',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Deconnexion'),
                  content: const Text('Etes-vous sur de vouloir vous deconnecter ?'),
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
                      child: const Text('Deconnecter'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                final homeState = context.findAncestorStateOfType<_RestaurateurHomePageState>();
                if (homeState != null) {
                  await homeState._logout();
                }
              }
            },
            tooltip: 'Deconnexion',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            restaurantAsync.when(
              data: (restaurant) {
                final bool isTemporary = restaurant.id == 'default' || restaurant.id.contains('temp_');
                
                if (isTemporary) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orange.shade200,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.store,
                          size: 48,
                          color: Colors.orange.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aucun restaurant associe',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Contactez l\'administrateur pour vous associer a un restaurant',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            ref.refresh(restaurateurInfoProvider);
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Reessayer'),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
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
                          Icons.store,
                          color: Colors.orange.shade700,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant.nom,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            if (restaurant.adresse.isNotEmpty && restaurant.adresse != 'Adresse non renseignee')
                              Text(
                                restaurant.adresse,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
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
                                      fontSize: 10,
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
                      ),
                    ],
                  ),
                );
              },
              loading: () => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      height: 40,
                      width: 40,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 150,
                            height: 20,
                            child: ColoredBox(color: Colors.grey),
                          ),
                          SizedBox(height: 4),
                          SizedBox(
                            width: 200,
                            height: 14,
                            child: ColoredBox(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              error: (err, stack) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.orange.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.orange.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Erreur de chargement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Impossible de charger les informations du restaurant',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        ref.refresh(restaurateurInfoProvider);
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reessayer'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            statsAsync.when(
              data: (stats) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Plats',
                        value: stats['total_plats']?.toString() ?? '0',
                        icon: Icons.restaurant_menu,
                        color: Colors.orange,
                        subtitle: 'Disponibles',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Commandes',
                        value: stats['total_commandes']?.toString() ?? '0',
                        icon: Icons.shopping_cart,
                        color: Colors.blue,
                        subtitle: 'En cours',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'CA du jour',
                        value: '${stats['ca_jour']?.toString() ?? '0'} Ar',
                        icon: Icons.trending_up,
                        color: Colors.green,
                        subtitle: "Aujourd'hui",
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
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
                        ref.refresh(restaurateurStatsProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reessayer'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            
            const Text(
              'Actions rapides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    context,
                    icon: Icons.add,
                    label: 'Ajouter un plat',
                    color: Colors.orange,
                    onTap: () => context.push('/restaurateur/plats/ajouter'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    context,
                    icon: Icons.list_alt,
                    label: 'Voir commandes',
                    color: Colors.blue,
                    onTap: () {
                      final homeState = context.findAncestorStateOfType<_RestaurateurHomePageState>();
                      if (homeState != null) {
                        homeState.setState(() {
                          homeState._selectedIndex = 2;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
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
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.orange.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Astuce',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        Text(
                          'Gardez votre menu a jour pour attirer plus de clients',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== GESTION DES PLATS =====
class RestaurateurPlatsPage extends ConsumerStatefulWidget {
  const RestaurateurPlatsPage({super.key});

  @override
  ConsumerState<RestaurateurPlatsPage> createState() => _RestaurateurPlatsPageState();
}

class _RestaurateurPlatsPageState extends ConsumerState<RestaurateurPlatsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final platsAsync = ref.watch(restaurateurPlatsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Mes plats',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push('/restaurateur/plats/ajouter');
            },
            tooltip: 'Ajouter un plat',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(restaurateurPlatsProvider);
            },
            tooltip: 'Rafraichir',
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
      body: platsAsync.when(
        data: (plats) {
          final filteredPlats = plats.where((plat) {
            if (_searchQuery.isEmpty) return true;
            final query = _searchQuery.toLowerCase().trim();
            return plat.nom.toLowerCase().contains(query) ||
                   plat.description?.toLowerCase().contains(query) == true;
          }).toList();

          if (plats.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildSearchBar(),
              if (filteredPlats.isEmpty)
                _buildEmptySearchResults()
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.refresh(restaurateurPlatsProvider);
                    },
                    color: Colors.orange.shade700,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredPlats.length,
                      itemBuilder: (context, index) {
                        final plat = filteredPlats[index];
                        return _buildPlatCard(plat);
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
                'Chargement des plats...',
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
                  ref.refresh(restaurateurPlatsProvider);
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

  Widget _buildPlatCard(Plat plat) {
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
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.shade200,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.restaurant_menu,
                color: Colors.orange.shade300,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plat.nom,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (plat.description != null && plat.description!.isNotEmpty)
                    Text(
                      plat.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${plat.prix.toStringAsFixed(0)} Ar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: plat.estDisponible
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    plat.estDisponible ? 'Disponible' : 'Indisponible',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: plat.estDisponible
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      onPressed: () {
                        context.push('/restaurateur/plats/modifier/${plat.id}');
                      },
                      tooltip: 'Modifier',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outlined,
                        color: Colors.red.shade400,
                        size: 20,
                      ),
                      onPressed: () {
                        _deletePlat(context, ref, plat.id);
                      },
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
              Icons.restaurant_menu,
              size: 50,
              color: Colors.orange.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun plat',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre premier plat',
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
            onPressed: () => context.push('/restaurateur/plats/ajouter'),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un plat'),
          ),
        ],
      ),
    );
  }

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

  Future<void> _deletePlat(BuildContext context, WidgetRef ref, String platId) async {
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
            const Text('Supprimer le plat'),
          ],
        ),
        content: const Text(
          'Etes-vous sur de vouloir supprimer ce plat ? Cette action est irreversible.',
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

    if (confirm == true) {
      try {
        final repo = ref.read(restaurateurRepositoryProvider);
        await repo.deletePlat(platId);
        ref.refresh(restaurateurPlatsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plat supprime avec succes'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

// ===== GESTION DES COMMANDES =====
class RestaurateurCommandesPage extends ConsumerWidget {
  const RestaurateurCommandesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandesAsync = ref.watch(restaurateurCommandesProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Commandes',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(restaurateurCommandesProvider);
            },
            tooltip: 'Rafraichir',
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
      body: commandesAsync.when(
        data: (commandes) {
          if (commandes.isEmpty) {
            return _buildEmptyState();
          }
          
          final sortedCommandes = List.from(commandes)
            ..sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
          
          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(restaurateurCommandesProvider);
            },
            color: Colors.orange.shade700,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sortedCommandes.length,
              itemBuilder: (context, index) {
                final commande = sortedCommandes[index];
                return _buildCommandeCard(context, ref, commande);
              },
            ),
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
                'Chargement des commandes...',
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
                  ref.refresh(restaurateurCommandesProvider);
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

  // Carte d'une commande - SANS BOUTON VOIR DETAILS
  Widget _buildCommandeCard(
    BuildContext context,
    WidgetRef ref,
    Commande commande,
  ) {
    // Fonction pour obtenir le nom du plat de manière sécurisée
    String getNomPlat(dynamic item) {
      if (item == null) return 'Plat inconnu';
      
      if (item is Map) {
        return item['nomPlat']?.toString() ?? 
               item['nom']?.toString() ?? 
               item['nom_plat']?.toString() ?? 
               'Plat inconnu';
      }
      
      try {
        return item.nomPlat ?? item.nom ?? 'Plat inconnu';
      } catch (e) {
        return 'Plat inconnu';
      }
    }

    // Fonction pour obtenir la quantité
    int getQuantite(dynamic item) {
      if (item == null) return 0;
      
      if (item is Map) {
        return int.tryParse(item['quantite']?.toString() ?? '0') ?? 0;
      }
      try {
        return item.quantite ?? 0;
      } catch (e) {
        return 0;
      }
    }

    // Fonction pour obtenir le prix unitaire
    double getPrixUnitaire(dynamic item) {
      if (item == null) return 0.0;
      
      if (item is Map) {
        return double.tryParse(item['prixUnitaire']?.toString() ?? '0') ?? 0.0;
      }
      try {
        return item.prixUnitaire ?? 0.0;
      } catch (e) {
        return 0.0;
      }
    }

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
            // En-tete
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: Colors.orange.shade700,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Commande #${commande.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(commande.statut).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(commande.statut),
                        size: 12,
                        color: _getStatusColor(commande.statut),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusLabel(commande.statut),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(commande.statut),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Details de la commande
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Client #${commande.clientId.substring(0, 6)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(commande.dateCreation),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            commande.adresseLivraison ?? 'Adresse non specifiee',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${commande.total.toStringAsFixed(0)} Ar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    if (commande.items.isNotEmpty)
                      Text(
                        '${commande.items.length} article(s)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
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
            
            // Liste des plats (max 2)
            if (commande.items.isNotEmpty)
              ...commande.items.take(2).map((item) {
                final nomPlat = getNomPlat(item);
                final quantite = getQuantite(item);
                final prixUnitaire = getPrixUnitaire(item);
                final totalItem = prixUnitaire * quantite;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade300,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$nomPlat x$quantite',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      Text(
                        '${totalItem.toStringAsFixed(0)} Ar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            
            if (commande.items.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '+ ${commande.items.length - 2} autre(s) article(s)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Actions sur la commande - SANS BOUTON VOIR DETAILS
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (commande.statut == 'EN_ATTENTE')
                  _buildActionButton(
                    label: 'Preparer',
                    icon: Icons.restaurant,
                    color: Colors.green,
                    onPressed: () => _changeStatus(
                      context,
                      ref,
                      commande.id,
                      'PREPARATION',
                    ),
                  ),
                if (commande.statut == 'PREPARATION')
                  _buildActionButton(
                    label: 'Livrer',
                    icon: Icons.delivery_dining,
                    color: Colors.orange,
                    onPressed: () => _changeStatus(
                      context,
                      ref,
                      commande.id,
                      'EN_ROUTE',
                    ),
                  ),
                if (commande.statut == 'EN_ROUTE')
                  _buildActionButton(
                    label: 'Livree',
                    icon: Icons.check_circle,
                    color: Colors.green,
                    onPressed: () => _changeStatus(
                      context,
                      ref,
                      commande.id,
                      'LIVREE',
                    ),
                  ),
                if (commande.statut != 'LIVREE' && commande.statut != 'ANNULEE')
                  _buildActionButton(
                    label: 'Annuler',
                    icon: Icons.cancel,
                    color: Colors.red,
                    onPressed: () => _changeStatus(
                      context,
                      ref,
                      commande.id,
                      'ANNULEE',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
        minimumSize: const Size(0, 32),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

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
              Icons.shopping_bag_outlined,
              size: 50,
              color: Colors.orange.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune commande',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les commandes apparaitront ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'janv.', 'fevr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'aout', 'sept.', 'oct.', 'nov.', 'dec.'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'EN_ATTENTE':
        return Colors.orange;
      case 'PREPARATION':
        return Colors.blue;
      case 'EN_ROUTE':
        return Colors.purple;
      case 'LIVREE':
        return Colors.green;
      case 'ANNULEE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'EN_ATTENTE':
        return Icons.hourglass_empty;
      case 'PREPARATION':
        return Icons.restaurant;
      case 'EN_ROUTE':
        return Icons.delivery_dining;
      case 'LIVREE':
        return Icons.check_circle_outline;
      case 'ANNULEE':
        return Icons.cancel_outlined;
      default:
        return Icons.circle;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'EN_ATTENTE':
        return 'En attente';
      case 'PREPARATION':
        return 'En prep.';
      case 'EN_ROUTE':
        return 'En livraison';
      case 'LIVREE':
        return 'Livree';
      case 'ANNULEE':
        return 'Annulee';
      default:
        return status;
    }
  }

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    String commandeId,
    String newStatus,
  ) async {
    try {
      print('[changeStatus] Commande: $commandeId, Nouveau statut: $newStatus');

      final repo = ref.read(restaurateurRepositoryProvider);
      await repo.updateOrderStatus(commandeId, newStatus);
      
      ref.refresh(restaurateurCommandesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut change en ${_getStatusLabel(newStatus)}'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors du changement de statut: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}