import 'dart:io';
import 'package:postgres/postgres.dart';

class DatabaseClient {
  final Pool pool;

  DatabaseClient(this.pool);

  factory DatabaseClient.initialize() {

    final pool = Pool.withEndpoints(
      [
        Endpoint(
          host: Platform.environment['DB_HOST']!,
          port: int.parse(
            Platform.environment['DB_PORT'] ?? '5432',
          ),
          database: Platform.environment['DB_NAME']!,
          username: Platform.environment['DB_USER']!,
          password: Platform.environment['DB_PASSWORD']!,
        ),
      ],
      settings: const PoolSettings(
        maxConnectionCount: 5,
        sslMode: SslMode.require,
      ),
    );

    return DatabaseClient(pool);
  }

  Future<void> close() async {
    await pool.close();
  }
}