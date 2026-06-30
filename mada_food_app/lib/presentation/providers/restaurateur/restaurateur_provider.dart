// lib/presentation/providers/restaurateur/restaurateur_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/restaurateur/restaurateur_remote_datasource.dart';
import '../../../data/repositories/restaurateur/restaurateur_repository_impl.dart';
import '../../../domain/repositories/restaurateur/i_restaurateur_repository.dart';
import '../../../domain/entities/plat.dart';
import '../../../domain/entities/commande.dart';
import '../../../domain/entities/restaurant_entity.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final dioProvider = Provider<DioClient>((ref) {
  return DioClient();
});

final restaurateurRepositoryProvider = Provider<IRestaurateurRepository>((ref) {
  final dioClient = ref.watch(dioProvider);
  final datasource = RestaurateurRemoteDatasource(dioClient);
  return RestaurateurRepositoryImpl(datasource);
});

// Provider pour les statistiques du restaurateur
final restaurateurStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final repo = ref.read(restaurateurRepositoryProvider);
    return await repo.getStats();
  } catch (e) {
    print('Erreur lors du chargement des statistiques: $e');
    // Si c'est une erreur 401, on peut la propager pour que l'utilisateur soit redirigé
    return {
      'total_plats': 0,
      'total_commandes': 0,
      'ca_jour': 0,
    };
  }
});

// Provider pour les plats du restaurateur
final restaurateurPlatsProvider = FutureProvider<List<Plat>>((ref) async {
  try {
    final repo = ref.read(restaurateurRepositoryProvider);
    return await repo.getPlats();
  } catch (e) {
    print('Erreur lors du chargement des plats: $e');
    return [];
  }
});

// Provider pour les restaurants du restaurateur
final restaurateurRestaurantsProvider = FutureProvider<List<RestaurantEntity>>((ref) async {
  try {
    final repo = ref.read(restaurateurRepositoryProvider);
    return await repo.getRestaurants();
  } catch (e) {
    print('Erreur lors du chargement des restaurants: $e');
    return [];
  }
});

// Provider pour les informations du restaurant du restaurateur connecte
final restaurateurInfoProvider = FutureProvider<RestaurantEntity>((ref) async {
  try {
    final repo = ref.read(restaurateurRepositoryProvider);
    final restaurants = await repo.getRestaurants();
    
    // Verifier que le restaurateur a au moins un restaurant
    if (restaurants.isEmpty) {
      print('Aucun restaurant trouve pour ce restaurateur');
      // Retourner un restaurant par defaut avec un flag temporaire
      return RestaurantEntity(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        nom: 'Aucun restaurant associe',
        adresse: 'Contactez l\'administrateur',
        estOuvert: false,
        dateCreation: DateTime.now(),
      );
    }
    
    // Retourner le premier restaurant
    return restaurants.first;
  } catch (e) {
    print('Erreur lors du chargement des informations du restaurant: $e');
    
    // Si c'est une erreur 401, on la propage
    if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
      // Le token est invalide ou expiré, on va forcer une reconnexion
      print('Token invalide ou expiré, redirection vers login');
      // On peut lancer une exception pour que le front redirige
      rethrow;
    }
    
    // Retourner un restaurant par defaut en cas d'erreur
    return RestaurantEntity(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      nom: 'Erreur de connexion',
      adresse: 'Veuillez vous reconnecter',
      estOuvert: false,
      dateCreation: DateTime.now(),
    );
  }
});

// Provider pour les commandes du restaurateur
final restaurateurCommandesProvider = FutureProvider<List<Commande>>((ref) async {
  try {
    final repo = ref.read(restaurateurRepositoryProvider);
    return await repo.getCommandes();
  } catch (e) {
    print('Erreur lors du chargement des commandes: $e');
    return [];
  }
});

// Provider pour une commande specifique
final restaurateurCommandeProvider = FutureProvider.family<Commande?, String>((ref, id) async {
  try {
    final repo = ref.read(restaurateurRepositoryProvider);
    return await repo.getCommandeById(id);
  } catch (e) {
    print('Erreur lors du chargement de la commande $id: $e');
    return null;
  }
});

// ============================================
// PLATS NOTIFIER
// ============================================

class RestaurateurPlatsNotifier extends StateNotifier<AsyncValue<List<Plat>>> {
  final IRestaurateurRepository _repository;

  RestaurateurPlatsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadPlats();
  }

  // Chargement des plats
  Future<void> _loadPlats() async {
    try {
      final plats = await _repository.getPlats();
      state = AsyncValue.data(plats);
    } catch (e, stack) {
      print('Erreur dans _loadPlats: $e');
      state = AsyncValue.data([]);
    }
  }

  // Rafraichissement de la liste des plats
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadPlats();
  }

  // Ajout d'un nouveau plat
  Future<void> addPlat(Plat plat) async {
    try {
      final newPlat = await _repository.createPlat(plat);
      if (newPlat != null) {
        final currentPlats = state.value ?? [];
        state = AsyncValue.data([...currentPlats, newPlat]);
      }
    } catch (e, stack) {
      print('Erreur dans addPlat: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  // Mise a jour d'un plat existant
  Future<void> updatePlat(String id, Plat plat) async {
    try {
      final updatedPlat = await _repository.updatePlat(id, plat);
      if (updatedPlat != null) {
        final currentPlats = state.value ?? [];
        final index = currentPlats.indexWhere((p) => p.id == id);
        if (index != -1) {
          final newList = List<Plat>.from(currentPlats);
          newList[index] = updatedPlat;
          state = AsyncValue.data(newList);
        }
      }
    } catch (e, stack) {
      print('Erreur dans updatePlat: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  // Suppression d'un plat
  Future<void> deletePlat(String id) async {
    try {
      await _repository.deletePlat(id);
      final currentPlats = state.value ?? [];
      state = AsyncValue.data(currentPlats.where((p) => p.id != id).toList());
    } catch (e, stack) {
      print('Erreur dans deletePlat: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  // Bascule du statut disponibilite d'un plat
  Future<void> toggleDisponibilite(String id) async {
    try {
      final currentPlats = state.value ?? [];
      final index = currentPlats.indexWhere((p) => p.id == id);
      if (index != -1) {
        final plat = currentPlats[index];
        final updatedPlat = plat.copyWith(
          estDisponible: !plat.estDisponible,
        );
        await _repository.updatePlat(id, updatedPlat);
        
        final newList = List<Plat>.from(currentPlats);
        newList[index] = updatedPlat;
        state = AsyncValue.data(newList);
      }
    } catch (e, stack) {
      print('Erreur dans toggleDisponibilite: $e');
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider pour le notifier des plats
final restaurateurPlatsNotifierProvider = StateNotifierProvider<RestaurateurPlatsNotifier, AsyncValue<List<Plat>>>((ref) {
  final repo = ref.read(restaurateurRepositoryProvider);
  return RestaurateurPlatsNotifier(repo);
});

// ============================================
// COMMANDES NOTIFIER
// ============================================

class RestaurateurCommandesNotifier extends StateNotifier<AsyncValue<List<Commande>>> {
  final IRestaurateurRepository _repository;

  RestaurateurCommandesNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadCommandes();
  }

  // Chargement des commandes
  Future<void> _loadCommandes() async {
    try {
      final commandes = await _repository.getCommandes();
      state = AsyncValue.data(commandes);
    } catch (e, stack) {
      print('Erreur dans _loadCommandes: $e');
      state = AsyncValue.data([]);
    }
  }

  // Rafraichissement de la liste des commandes
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadCommandes();
  }

  // Mise a jour du statut d'une commande
  Future<void> updateStatut(String commandeId, String statut) async {
    try {
      final updatedCommande = await _repository.updateOrderStatus(commandeId, statut);
      final currentCommandes = state.value ?? [];
      final index = currentCommandes.indexWhere((c) => c.id == commandeId);
      if (index != -1) {
        final newList = List<Commande>.from(currentCommandes);
        if (updatedCommande != null) {
          newList[index] = updatedCommande;
        } else {
          newList[index] = newList[index].copyWith(statut: statut);
        }
        state = AsyncValue.data(newList);
      }
    } catch (e, stack) {
      print('Erreur dans updateStatut: $e');
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider pour le notifier des commandes
final restaurateurCommandesNotifierProvider = StateNotifierProvider<RestaurateurCommandesNotifier, AsyncValue<List<Commande>>>((ref) {
  final repo = ref.read(restaurateurRepositoryProvider);
  return RestaurateurCommandesNotifier(repo);
});