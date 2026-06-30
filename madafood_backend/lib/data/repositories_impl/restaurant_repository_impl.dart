import 'package:madafood_backend/core/database_client.dart';
import 'package:madafood_backend/data/models/restaurant_model.dart';
import 'package:madafood_backend/domain/entities/restaurant.dart';
import 'package:madafood_backend/domain/repositories/restaurant_repository.dart';
import 'package:postgres/postgres.dart';

class RestaurantRepositoryImpl implements RestaurantRepository {
  final DatabaseClient dbClient;

  RestaurantRepositoryImpl(this.dbClient);

  @override
  Future<List<Restaurant>> getAllRestaurants() async {
    final result = await dbClient.pool.execute(
      Sql.named('SELECT * FROM restaurants ORDER BY date_creation DESC'),
    );

    return result.map((row) => RestaurantModel.fromJson(row.toColumnMap())).toList();
  }

  @override
  Future<Restaurant?> getRestaurantById(String id) async {
    final result = await dbClient.pool.execute(
      Sql.named('SELECT * FROM restaurants WHERE id = @id'),
      parameters: {'id': id},
    );

    if (result.isEmpty) return null;
    return RestaurantModel.fromJson(result.first.toColumnMap());
  }

  @override
  Future<Restaurant?> createRestaurant({
    required String nom,
    required String adresse,
    double? latitude,
    double? longitude,
  }) async {
    final result = await dbClient.pool.execute(
      Sql.named(
        'INSERT INTO restaurants (nom, adresse, latitude, longitude) '
        'VALUES (@nom, @adresse, @latitude, @longitude) RETURNING *',
      ),
      parameters: {
        'nom': nom,
        'adresse': adresse,
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    if (result.isEmpty) return null;
    return RestaurantModel.fromJson(result.first.toColumnMap());
  }

  @override
  Future<Restaurant?> updateStatus(String id, bool estOuvert) async {
    final result = await dbClient.pool.execute(
      Sql.named(
        'UPDATE restaurants SET est_ouvert = @est_ouvert WHERE id = @id RETURNING *',
      ),
      parameters: {
        'id': id,
        'est_ouvert': estOuvert,
      },
    );

    if (result.isEmpty) return null;
    return RestaurantModel.fromJson(result.first.toColumnMap());
  }
}