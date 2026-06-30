// lib/core/database_client.dart

import 'package:postgres/postgres.dart';

class DatabaseClient {
  final Pool pool;

  DatabaseClient(this.pool);

  /// Initialise le pool de connexions vers PostgreSQL
  factory DatabaseClient.initialize() {
    final pool = Pool.withEndpoints(
      [
        Endpoint(
          host: 'localhost',
          port: 5432,
          database: 'madafood_db',
          username: 'postgres',
          //  MDP POSTGRESQL
          password: 'Lovanirina#3', 
        ),
      ],
      settings: const PoolSettings(
        // Autorise jusqu'à 5 connexions simultanées pour gérer les requêtes de l'API
        maxConnectionCount: 5,
        sslMode: SslMode.disable, 
      ),
    );

    return DatabaseClient(pool);
  }

  /// Méthode utilitaire pour fermer proprement la connexion lors de l'arrêt du serveur
  Future<void> close() async {
    await pool.close();
  }
}