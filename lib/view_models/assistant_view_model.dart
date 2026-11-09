import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/data/repositories/assistant_repository.dart';
import 'package:pet_sitter/data/repositories/cart_repository.dart';
import 'package:pet_sitter/data/sources/api_client.dart';
import 'package:pet_sitter/data/sources/session.dart';
import 'package:pet_sitter/models/models.dart';

/// Écran de l'assistant : une question, puis des produits à ajouter au panier.
class AssistantViewModel extends ViewModel {
  AssistantViewModel(this._assistant, this._cart, this._session);

  final AssistantRepository _assistant;
  final CartRepository _cart;
  final Session _session;

  bool get needsLogin => !_session.isLoggedIn;

  bool _asking = false;
  bool get asking => _asking;

  String? _error;
  String? get error => _error;

  AssistantReply? _reply;
  AssistantReply? get reply => _reply;

  Future<void> ask(String question) async {
    final text = question.trim();
    if (text.isEmpty || _asking) return;
    _asking = true;
    _error = null;
    _reply = null;
    notify();
    try {
      _reply = await _assistant.ask(text);
    } on ApiException catch (e) {
      _error = e.message;
    } on TypeError {
      _error = 'L\'assistant a envoyé une réponse illisible. Réessayez.';
    } on ArgumentError {
      _error = 'L\'assistant a envoyé une réponse illisible. Réessayez.';
    }
    _asking = false;
    notify();
  }

  void addToCart(Product p) {
    final option = p.firstAvailable;
    if (option != null) _cart.add(p, option);
  }
}
