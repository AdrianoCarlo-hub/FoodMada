import 'package:dart_frog/dart_frog.dart';
import 'package:madafood_backend/domain/repositories/plat_repository.dart';
import 'package:madafood_backend/domain/entities/plat.dart'; // Importez l'entité
import 'package:madafood_backend/data/models/plat_model.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }

  final repo = context.read<PlatRepository>();
  // On spécifie explicitement que 'plats' est une List<Plat>
  final List<Plat> plats = await repo.getPlatsByRestaurant(id);

  // Maintenant Dart sait que 'p' est de type 'Plat'
  final jsonList = plats.map((p) => PlatModel.fromEntity(p).toJson()).toList();

  return Response.json(body: {'success': true, 'data': jsonList});
}