// lib/core/database_client.dart

import 'dart:io';
import 'package:postgres/postgres.dart';

class DatabaseClient {
  final Pool pool;

  DatabaseClient(this.pool);

  /// Initialise la connexion PostgreSQL
  factory DatabaseClient.initialize() {
    final host = Platform.environment['DB_HOST'];
    final port = Platform.environment['DB_PORT'];
    final database = Platform.environment['DB_NAME'];
    final user = Platform.environment['DB_USER'];
    final password = Platform.environment['DB_PASSWORD'];

    final pool = Pool.withEndpoints(
      [
        Endpoint(
          host: host ?? 'localhost',
          port: int.tryParse(port ?? '5432') ?? 5432,
          database: database ?? 'madafood_db',
          username: user ?? 'postgres',
          password: password ?? '',
        ),
      ],
      settings: const PoolSettings(
        maxConnectionCount: 5,

        // Obligatoire sur Render PostgreSQL
        sslMode: SslMode.require,
      ),
    );

    return DatabaseClient(pool);
  }

  /// Ferme proprement les connexions
  Future<void> close() async {
    await pool.close();
  }
}