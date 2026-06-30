import 'package:madafood_backend/core/database_client.dart';
import 'package:madafood_backend/data/models/plat_model.dart';
import 'package:madafood_backend/domain/entities/plat.dart';
import 'package:madafood_backend/domain/repositories/plat_repository.dart';
import 'package:postgres/postgres.dart';

class PlatRepositoryImpl implements PlatRepository {
  final DatabaseClient dbClient;

  PlatRepositoryImpl(this.dbClient);

  @override
Future<List<Plat>> getPlatsPaginated({
  String? restaurantId, 
  int page = 1, 
  int limit = 10
}) async {
  final offset = (page - 1) * limit;
  
  // Requête dynamique
  String sql = 'SELECT * FROM plats WHERE 1=1';
  Map<String, dynamic> params = {};

  if (restaurantId != null) {
    sql += ' AND restaurant_id = @rid';
    params['rid'] = restaurantId;
  }
  
  sql += ' ORDER BY nom LIMIT @limit OFFSET @offset';
  params['limit'] = limit;
  params['offset'] = offset;

  final result = await dbClient.pool.execute(Sql.named(sql), parameters: params);
  return result.map((row) => PlatModel.fromJson(row.toColumnMap())).toList();
}

  @override
  Future<Plat?> createPlat(Plat plat) async {
    final result = await dbClient.pool.execute(
      Sql.named(
        'INSERT INTO plats (restaurant_id, nom, description, prix, est_disponible) '
        'VALUES (@rid, @nom, @desc, @prix, , @dispo) RETURNING *',
      ),
      parameters: {
        'rid': plat.restaurantId,
        'nom': plat.nom,
        'desc': plat.description,
        'prix': plat.prix.toString(),
        'dispo': plat.estDisponible,
      },
    );
    if (result.isEmpty) return null;
    return PlatModel.fromJson(result.first.toColumnMap());
  }

  @override
  Future<bool> deletePlat(String id) async {
    final result = await dbClient.pool.execute(
      Sql.named('DELETE FROM plats WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.affectedRows > 0;
  }

  @override
  Future<bool> updatePlat(String id, Plat plat) async {
    final result = await dbClient.pool.execute(
      Sql.named(
        'UPDATE plats SET nom = @nom, description = @desc, prix = @prix, '
        'est_disponible = @dispo WHERE id = @id',
      ),
      parameters: {
        'id': id,
        'nom': plat.nom,
        'desc': plat.description,
        'prix': plat.prix.toString(),
        'dispo': plat.estDisponible,
      },
    );
    return result.affectedRows > 0;
  }

  @override
Future<List<Plat>> getPlatsByRestaurant(String restaurantId) async {
  final result = await dbClient.pool.execute(
    Sql.named('SELECT * FROM plats WHERE restaurant_id = @rid ORDER BY nom'),
    parameters: {'rid': restaurantId},
  );
  return result.map((row) => PlatModel.fromJson(row.toColumnMap())).toList();
}
} // <--- C'est cette accolade qui manquait pour fermer la classe !