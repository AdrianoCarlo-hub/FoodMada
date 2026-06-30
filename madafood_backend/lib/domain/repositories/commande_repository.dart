// lib/domain/repositories/commande_repository.dart

import 'package:madafood_backend/domain/entities/commande.dart';
class InvalidStatusTransitionException implements Exception {
  final String message;
  InvalidStatusTransitionException(this.message);
}
abstract class CommandeRepository {
  // Créer une nouvelle commande à partir du panier de l'app mobile
  Future<Commande> creerCommande({
    required String clientId,
    required String restaurantId,
    required List<Map<String, dynamic>> itemsBruts,
    required double fraisLivraison,
    String? adresseLivraison,
    String? modePaiement,
  });

  // Récupérer l'historique des commandes d'un client
  Future<List<Commande>> getCommandesByClient(String clientId);

  // Récupérer toutes les commandes (avec filtrage pour l'admin)
  Future<List<Commande>> getAllCommandes({String? restaurantId, String? statut});

  // Mettre à jour le statut d'une commande
  Future<Commande?> changerStatutCommande(String commandeId, String nouveauStatut);

  Future<List<Commande>> getCommandesByRestaurant(String restaurantId);
  Future<Commande?> getCommandeById(String id);

}