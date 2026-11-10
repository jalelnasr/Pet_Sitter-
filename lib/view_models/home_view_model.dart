import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/core/session/auth_session.dart';
import 'package:pet_sitter/data/repositories/cart_repository.dart';
import 'package:pet_sitter/data/repositories/pet_repository.dart';
import 'package:pet_sitter/data/repositories/shop_repository.dart';
import 'package:pet_sitter/events/event_models.dart';
import 'package:pet_sitter/events/event_repository.dart';
import 'package:pet_sitter/models/models.dart';

/// Accueil propriétaire : salutation, accès à la garde, événements publiés,
/// produits suggérés pour ses animaux et ses compagnons.
class HomeViewModel extends ViewModel {
  HomeViewModel({
    required PetRepository pets,
    required ShopRepository shop,
    required CartRepository cart,
    AuthSession? session,
    EventRepository? events,
    DateTime Function()? now,
  }) : _pets = pets,
       _shop = shop,
       _cart = cart,
       _session = session,
       _eventsRepo = events,
       _now = now ?? DateTime.now {
    _pets.addListener(notify);
    _loadShop();
    _loadEvents();
  }

  final AuthSession? _session;
  final PetRepository _pets;
  final ShopRepository _shop;
  final CartRepository _cart;
  final EventRepository? _eventsRepo;
  final DateTime Function() _now;

  /// Les suggestions sont facultatives : sans catalogue, l'accueil les masque simplement.
  Future<void> _loadShop() async {
    try {
      await _shop.load();
      notify();
    } on ShopException {
      // La page Boutique affiche l'erreur et propose de réessayer.
    }
  }

  List<PetEvent> _highlights = const [];

  /// Prochains événements publiés (backend) ; vide hors connexion ou sans événement.
  List<PetEvent> get highlights => _highlights;

  Future<void> _loadEvents() async {
    final repo = _eventsRepo;
    if (repo == null) return;
    try {
      final events = await repo.fetchEvents(upcomingOnly: true);
      _highlights = events.where((e) => e.status == EventStatus.published).take(4).toList();
      notify();
    } catch (_) {
      // L'onglet Événements affiche l'erreur et propose de réessayer.
    }
  }

  /// Compte connecté ; sans compte (aperçus du sommaire), la propriétaire de démonstration.
  AppUser? get _user => _session?.user;
  String get ownerFirstName => _user?.firstName ?? _pets.ownerFirstName;
  String get ownerName => _user?.fullName ?? _pets.ownerFullName;
  String get ownerPhoto => _user == null ? _pets.ownerPhoto : (_user!.photoUrl ?? '');
  List<Pet> get pets => _pets.myPets();

  String get greeting => _now().hour < 18 ? 'Bonne journée ! Qui gardons-nous ?' : 'Bonne soirée ! Qui gardons-nous ?';

  /// « Pour Rex et Mimi · livraison offerte dès 80 DT », d'après les animaux du compte.
  String get shopSubtitle {
    final names = pets.map((p) => p.name).where((n) => n.isNotEmpty).toList();
    final delivery = 'livraison offerte dès ${CartRepository.freeShippingFrom} DT';
    if (names.isEmpty) return 'Accessoires et nourriture · $delivery';
    final who = names.length == 1
        ? names.first
        : '${names.sublist(0, names.length - 1).join(', ')} et ${names.last}';
    return 'Pour $who · $delivery';
  }

  List<Product> get recommendedProducts => _shop.recommendedFor(pets.map((p) => p.species));

  void addToCart(Product p) {
    final option = p.firstAvailable;
    if (option != null) _cart.add(p, option);
  }

  @override
  void dispose() {
    _pets.removeListener(notify);
    super.dispose();
  }
}
