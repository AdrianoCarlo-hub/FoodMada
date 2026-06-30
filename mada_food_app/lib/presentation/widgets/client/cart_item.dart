// lib/presentation/widgets/client/plat_card.dart
import 'package:flutter/material.dart';
import '../../../domain/entities/plat.dart';

class PlatCard extends StatelessWidget {
  final Plat plat;
  final VoidCallback onAddToCart;

  const PlatCard({
    super.key,
    required this.plat,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ✅ Icône uniquement (pas d'image)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                color: Colors.orange,
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            // ✅ Informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plat.nom,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (plat.description != null)
                    Text(
                      plat.description!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${plat.prix} Ar',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            // ✅ Bouton Ajouter
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: plat.estDisponible ? Colors.orange : Colors.grey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: plat.estDisponible ? onAddToCart : null,
              icon: Icon(
                plat.estDisponible ? Icons.add : Icons.block,
                size: 16,
              ),
              label: Text(
                plat.estDisponible ? 'Ajouter' : 'Indisponible',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}