import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/data/repositories/order_repository.dart';
import 'package:pet_sitter/data/sources/api_client.dart';
import 'package:pet_sitter/models/models.dart';

/// « Mes commandes » : liste, suivi et annulation.
class MyOrdersViewModel extends ViewModel {
  MyOrdersViewModel(this._orders) {
    load();
  }

  final OrderRepository _orders;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  List<Order> _items = const [];
  List<Order> get items => _items;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notify();
    try {
      _items = await _orders.mine();
    } on ApiException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notify();
  }

  Order? byId(int id) {
    for (final o in _items) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// Renvoie un message d'erreur, ou null si l'annulation a réussi.
  Future<String?> cancel(Order order) async {
    try {
      final updated = await _orders.cancel(order.id);
      _items = [for (final o in _items) o.id == updated.id ? updated : o];
      notify();
      return null;
    } on ApiException catch (e) {
      await load(); // la commande a pu avancer entre-temps
      return e.message;
    }
  }
}
