/// Injection des dépendances : les dépôts sont créés une seule fois, au lancement,
/// puis mis à disposition de tous les écrans via `Deps.of(context)`.
library;

import 'package:flutter/widgets.dart';
import 'package:pet_sitter/core/session/auth_session.dart';
import 'package:pet_sitter/data/repositories/auth_repository.dart';
import 'package:pet_sitter/data/repositories/booking_repository.dart';
import 'package:pet_sitter/data/repositories/cart_repository.dart';
import 'package:pet_sitter/data/repositories/message_repository.dart';
import 'package:pet_sitter/data/repositories/pet_repository.dart';
import 'package:pet_sitter/data/repositories/shop_repository.dart';
import 'package:pet_sitter/data/repositories/sitter_repository.dart';
import 'package:pet_sitter/data/repositories/sitter_space_repository.dart';

class Deps extends InheritedWidget {
  Deps({
    super.key,
    required this.auth,
    required this.sitters,
    required this.pets,
    required this.bookings,
    required this.messages,
    required this.shop,
    required this.cart,
    required this.sitterSpace,
    AuthSession? session,
    required super.child,
  }) : session = session ?? AuthSession.instance;

  /// Version de démonstration : toutes les données sont simulées en mémoire.
  factory Deps.mock({required Widget child}) => Deps(
    auth: MockAuthRepository(),
    sitters: MockSitterRepository(),
    pets: MockPetRepository(),
    bookings: MockBookingRepository(),
    messages: MockMessageRepository(),
    shop: MockShopRepository(),
    cart: CartRepository(),
    sitterSpace: MockSitterSpaceRepository(),
    child: child,
  );

  /// Version connectée : comptes et messagerie passent par le backend Spring Boot,
  /// les autres domaines gardent leurs données de démonstration.
  factory Deps.live({required Widget child}) => Deps(
    auth: ApiAuthRepository(),
    sitters: MockSitterRepository(),
    pets: MockPetRepository(),
    bookings: MockBookingRepository(),
    messages: ApiMessageRepository(),
    shop: MockShopRepository(),
    cart: CartRepository(),
    sitterSpace: MockSitterSpaceRepository(),
    child: child,
  );

  final AuthRepository auth;
  final SitterRepository sitters;
  final PetRepository pets;
  final BookingRepository bookings;
  final MessageRepository messages;
  final ShopRepository shop;
  final CartRepository cart;
  final SitterSpaceRepository sitterSpace;

  /// Utilisateur connecté (partagé, écoutable).
  final AuthSession session;

  static Deps of(BuildContext context) {
    final deps = context.getInheritedWidgetOfExactType<Deps>();
    assert(deps != null, 'Deps introuvable : enveloppez l\'application dans Deps.mock(...)');
    return deps!;
  }

  @override
  bool updateShouldNotify(Deps oldWidget) => false;
}
