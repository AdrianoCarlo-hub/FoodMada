// lib/presentation/providers/client/cart_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/plat.dart';

class CartItem {
  final Plat plat;
  final int quantite;

  CartItem({required this.plat, required this.quantite});

  double get total => plat.prix * quantite;
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  // Ajouter un article au panier
  void addItem(Plat plat) {
    final existingIndex = state.indexWhere((item) => item.plat.id == plat.id);
    if (existingIndex != -1) {
      final updated = state[existingIndex];
      state = [
        ...state.sublist(0, existingIndex),
        CartItem(plat: updated.plat, quantite: updated.quantite + 1),
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      state = [...state, CartItem(plat: plat, quantite: 1)];
    }
  }

  // Retirer un article du panier (diminue la quantite ou supprime)
  void removeItem(String platId) {
    final existingIndex = state.indexWhere((item) => item.plat.id == platId);
    if (existingIndex != -1) {
      final updated = state[existingIndex];
      if (updated.quantite > 1) {
        state = [
          ...state.sublist(0, existingIndex),
          CartItem(plat: updated.plat, quantite: updated.quantite - 1),
          ...state.sublist(existingIndex + 1),
        ];
      } else {
        state = [
          ...state.sublist(0, existingIndex),
          ...state.sublist(existingIndex + 1),
        ];
      }
    }
  }

  // Mettre a jour la quantite d'un article specifique
  void updateQuantity(String platId, int newQuantity) {
    // Validation: la quantite doit etre superieure ou egale a 0
    if (newQuantity < 0) return;
    
    final existingIndex = state.indexWhere((item) => item.plat.id == platId);
    
    if (existingIndex != -1) {
      if (newQuantity == 0) {
        // Si la quantite est 0, on supprime l'article
        state = [
          ...state.sublist(0, existingIndex),
          ...state.sublist(existingIndex + 1),
        ];
      } else {
        // Sinon on met a jour la quantite
        final existingItem = state[existingIndex];
        state = [
          ...state.sublist(0, existingIndex),
          CartItem(plat: existingItem.plat, quantite: newQuantity),
          ...state.sublist(existingIndex + 1),
        ];
      }
    }
  }

  // Vider completement le panier
  void clearCart() {
    state = [];
  }

  // Calculer le total du panier
  double get total => state.fold(0, (sum, item) => sum + item.total);
  
  // Calculer le nombre total d'articles
  int get totalItems => state.fold(0, (sum, item) => sum + item.quantite);
}

// Provider pour le panier
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

// Provider pour le total du panier
final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, item) => sum + item.total);
});

// Provider pour le nombre total d'articles
final cartItemsCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, item) => sum + item.quantite);
});