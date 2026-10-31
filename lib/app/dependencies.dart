/// Injection des dépendances : les dépôts sont créés une seule fois, au lancement,
/// puis mis à disposition de tous les écrans via `Deps.of(context)`.
library;

import 'package:flutter/widgets.dart';
import 'package:pet_sitter/data/repositories/admin_repository.dart';
import 'package:pet_sitter/data/repositories/auth_repository.dart';
import 'package:pet_sitter/data/repositories/booking_repository.dart';
import 'package:pet_sitter/data/repositories/cart_repository.dart';
import 'package:pet_sitter/data/repositories/message_repository.dart';
import 'package:pet_sitter/data/repositories/order_repository.dart';
import 'package:pet_sitter/data/repositories/pet_repository.dart';
import 'package:pet_sitter/data/repositories/review_repository.dart';
import 'package:pet_sitter/data/repositories/shop_repository.dart';
import 'package:pet_sitter/data/repositories/sitter_repository.dart';
import 'package:pet_sitter/data/repositories/sitter_space_repository.dart';
import 'package:pet_sitter/data/sources/api_client.dart';
import 'package:pet_sitter/data/sources/api_config.dart';
import 'package:pet_sitter/data/sources/session.dart';

class Deps extends InheritedWidget {
  const Deps({
    super.key,
    required this.auth,
    required this.sitters,
    required this.pets,
    required this.bookings,
    required this.messages,
    required this.shop,
    required this.cart,
    required this.sitterSpace,
    required this.session,
    required this.orders,
    required this.admin,
    required this.reviews,
    required super.child,
  });

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
    session: Session(),
    orders: MockOrderRepository(),
    admin: MockAdminRepository(),
    reviews: MockReviewRepository(),
    child: child,
  );

  /// Comptes et boutique servis par le backend ; les autres domaines restent simulés pour l'instant.
  factory Deps.api({required Session session, required Widget child}) {
    final api = ApiClient(baseUrl: ApiConfig.baseUrl, session: session);
    return Deps(
      auth: ApiAuthRepository(api, session),
      sitters: MockSitterRepository(),
      pets: MockPetRepository(),
      bookings: MockBookingRepository(),
      messages: MockMessageRepository(),
      shop: ApiShopRepository(baseUrl: ApiConfig.baseUrl),
      cart: CartRepository(demo: false),
      sitterSpace: MockSitterSpaceRepository(),
      session: session,
      orders: ApiOrderRepository(api),
      admin: ApiAdminRepository(api),
      reviews: ApiReviewRepository(api),
      child: child,
    );
  }

  final AuthRepository auth;
  final SitterRepository sitters;
  final PetRepository pets;
  final BookingRepository bookings;
  final MessageRepository messages;
  final ShopRepository shop;
  final CartRepository cart;
  final SitterSpaceRepository sitterSpace;
  final Session session;
  final OrderRepository orders;
  final AdminRepository admin;
  final ReviewRepository reviews;

  static Deps of(BuildContext context) {
    final deps = context.getInheritedWidgetOfExactType<Deps>();
    assert(deps != null, 'Deps introuvable : enveloppez l\'application dans Deps.mock(...)');
    return deps!;
  }

  @override
  bool updateShouldNotify(Deps oldWidget) => false;
}
