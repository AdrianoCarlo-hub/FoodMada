// lib/presentation/pages/restaurateur/commande_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/restaurateur/restaurateur_provider.dart';
import '../../../domain/entities/commande.dart';

class CommandeDetailPage extends ConsumerStatefulWidget {
  final String commandeId;
  const CommandeDetailPage({super.key, required this.commandeId});

  @override
  ConsumerState<CommandeDetailPage> createState() => _CommandeDetailPageState();
}

class _CommandeDetailPageState extends ConsumerState<CommandeDetailPage> {
  @override
  Widget build(BuildContext context) {
    final commandeAsync = ref.watch(restaurateurCommandeProvider(widget.commandeId));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Details de la commande',
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
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(restaurateurCommandeProvider(widget.commandeId));
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
      body: commandeAsync.when(
        data: (order) {
          if (order == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Commande non trouvee',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }
          return _OrderDetailContent(order: order);
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
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.refresh(restaurateurCommandeProvider(widget.commandeId));
                },
                child: const Text('Reessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderDetailContent extends StatelessWidget {
  final Commande order;

  const _OrderDetailContent({required this.order});

  // Fonction pour tronquer l'ID de manière sécurisée
  String truncateId(String id) {
    if (id.length >= 8) {
      return id.substring(0, 8).toUpperCase();
    }
    return id.toUpperCase();
  }

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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tete
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                    Text(
                      'Commande #${truncateId(order.id)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.statut),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusLabel(order.statut),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.person_outline, 'Client', truncateId(order.clientId)),
                _buildInfoRow(Icons.restaurant_outlined, 'Restaurant', truncateId(order.restaurantId)),
                _buildInfoRow(Icons.calendar_today, 'Date', _formatDate(order.dateCreation)),
                if (order.adresseLivraison != null && order.adresseLivraison!.isNotEmpty)
                  _buildInfoRow(Icons.location_on_outlined, 'Adresse', order.adresseLivraison!),
                if (order.modePaiement != null && order.modePaiement!.isNotEmpty)
                  _buildInfoRow(Icons.payment_outlined, 'Mode de paiement', order.modePaiement!),
                _buildInfoRow(Icons.attach_money, 'Frais de livraison', '${(order.fraisLivraison ?? 0).toStringAsFixed(0)} Ar'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Articles
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                const Text(
                  'Articles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                if (order.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Aucun article dans cette commande',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...order.items.map((item) => _buildItemRow(item)),
                const Divider(),
                _buildPriceRow('Sous-total', order.sousTotal ?? 0),
                _buildPriceRow('Frais de livraison', order.fraisLivraison ?? 0),
                const Divider(),
                _buildPriceRow('Total', order.total, isTotal: true),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bouton retour
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Colors.orange.shade300,
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundColor: Colors.orange.shade700,
              ),
              onPressed: () => context.pop(),
              child: const Text(
                'Retour a la liste',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Non renseigne',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(dynamic item) {
    final nomPlat = getNomPlat(item);
    final quantite = getQuantite(item);
    final prixUnitaire = getPrixUnitaire(item);
    final totalItem = prixUnitaire * quantite;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.restaurant_menu,
                color: Colors.orange.shade400,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nomPlat,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Quantite: $quantite',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${totalItem.toStringAsFixed(0)} Ar',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.grey.shade800 : Colors.grey.shade600,
            ),
          ),
          Text(
            '${value.toStringAsFixed(0)} Ar',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? Colors.green.shade700 : Colors.grey.shade700,
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
    return '${date.day} ${months[date.month - 1]} ${date.year} a ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'EN_ATTENTE':
        return 'En attente';
      case 'PREPARATION':
        return 'En preparation';
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
}