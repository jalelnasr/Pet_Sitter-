/// Assistant d'achat de la boutique.
library;

import 'package:pet_sitter/data/sources/api_client.dart';
import 'package:pet_sitter/models/models.dart';

class AssistantPick {
  const AssistantPick(this.product, this.reason);
  final Product product;
  final String reason;
}

class AssistantReply {
  const AssistantReply({required this.message, required this.picks, required this.demo});
  final String message;
  final List<AssistantPick> picks;

  /// Réponse produite sans IA (backend sans clé API) : l'écran le signale.
  final bool demo;
}

abstract class AssistantRepository {
  /// Faux en démonstration : l'application n'a pas de serveur à interroger.
  bool get enabled;

  /// Lance [ApiException] en cas d'échec.
  Future<AssistantReply> ask(String question);
}

class MockAssistantRepository implements AssistantRepository {
  @override
  bool get enabled => false;

  @override
  Future<AssistantReply> ask(String question) async => const AssistantReply(message: '', picks: [], demo: true);
}

class ApiAssistantRepository implements AssistantRepository {
  ApiAssistantRepository(this._api);
  final ApiClient _api;

  // Une réponse d'IA peut prendre bien plus de temps qu'un appel ordinaire.
  static const _timeout = Duration(seconds: 70);

  @override
  bool get enabled => true;

  @override
  Future<AssistantReply> ask(String question) async {
    final json = await _api.post('/assistant', {'question': question}, _timeout) as Map<String, dynamic>;
    return AssistantReply(
      message: json['message'] as String,
      demo: json['demo'] as bool,
      picks: [
        for (final r in json['recommendations'] as List)
          AssistantPick(Product.fromJson(r['product'] as Map<String, dynamic>), r['reason'] as String),
      ],
    );
  }
}
