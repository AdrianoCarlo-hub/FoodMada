import 'package:madafood_backend/core/database_client.dart';
import 'package:madafood_backend/domain/entities/plat.dart';
import 'package:madafood_backend/domain/entities/commande.dart';
import 'package:madafood_backend/domain/repositories/restaurateur_repository.dart';
import 'package:madafood_backend/data/models/plat_model.dart';
import 'package:postgres/postgres.dart';

class RestaurateurRepositoryImpl implements RestaurateurRepository {
  final DatabaseClient dbClient;
  RestaurateurRepositoryImpl(this.dbClient);

  @override
  Future<List<Plat>> getPlatsByRestaurant(String restaurantId) async {
    final result = await dbClient.pool.execute(
      Sql.named('SELECT * FROM plats WHERE restaurant_id = @rid'),
      parameters: {'rid': restaurantId},
    );
    return result.map((row) => PlatModel.fromJson(row.toColumnMap())).toList();
  }

  @override
  Future<List<Commande>> getCommandesByRestaurant(String restaurantId) async {
    // Réutiliser ici votre logique existante de CommandeRepositoryImpl
    // en filtrant par restaurant_id
    throw UnimplementedError('À relier avec CommandeRepositoryImpl');
  }

  
}