/// Injection des dépendances : les dépôts sont créés une seule fois, au lancement,
/// puis mis à disposition de tous les écrans via `Deps.of(context)`.
library;

import 'package:flutter/widgets.dart';
import 'package:pet_sitter/core/config/api_constants.dart';
import 'package:pet_sitter/core/session/auth_session.dart';
import 'package:pet_sitter/data/repositories/admin_repository.dart';
import 'package:pet_sitter/data/repositories/auth_repository.dart';
import 'package:pet_sitter/data/repositories/booking_repository.dart';
import 'package:pet_sitter/data/repositories/cart_repository.dart';
import 'package:pet_sitter/data/repositories/message_repository.dart';
import 'package:pet_sitter/data/repositories/order_repository.dart';
import 'package:pet_sitter/data/repositories/pet_repository.dart';
import 'package:pet_sitter/data/repositories/review_repository.dart';
import 'package:pet_sitter/data/repositories/sales_analysis_repository.dart';
import 'package:pet_sitter/data/repositories/shop_repository.dart';
import 'package:pet_sitter/data/repositories/sitter_repository.dart';
import 'package:pet_sitter/data/repositories/sitter_space_repository.dart';
import 'package:pet_sitter/data/sources/api_client.dart';
import 'package:pet_sitter/data/sources/gemini_client.dart';
import 'package:pet_sitter/data/sources/store_config.dart';

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
    OrderRepository? orders,
    AdminRepository? admin,
    ReviewRepository? reviews,
    SalesAnalysisRepository? salesAnalysis,
    required super.child,
  }) : session = session ?? AuthSession.instance,
       orders = orders ?? MockOrderRepository(),
       admin = admin ?? MockAdminRepository(),
       reviews = reviews ?? MockReviewRepository(),
       salesAnalysis = salesAnalysis ?? const DisabledSalesAnalysis();

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
  factory Deps.live({required Widget child}) {
    // Boutique : catalogue, commandes, avis et administration passent par le backend commun.
    final store = ApiClient(baseUrl: ApiConstants.baseUrl, session: AuthSession.instance);
    return Deps(
    auth: ApiAuthRepository(),
    sitters: MockSitterRepository(),
    pets: MockPetRepository(),
    bookings: MockBookingRepository(),
    messages: ApiMessageRepository(),
    shop: ApiShopRepository(baseUrl: ApiConstants.baseUrl),
    cart: CartRepository(demo: false),
    sitterSpace: MockSitterSpaceRepository(),
    orders: ApiOrderRepository(store),
    admin: ApiAdminRepository(store),
    reviews: ApiReviewRepository(store),
    salesAnalysis: GeminiSalesAnalysis(GeminiClient(apiKey: StoreConfig.geminiKey, model: StoreConfig.geminiModel)),
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

  /// Utilisateur connecté (partagé, écoutable).
  final AuthSession session;

  // Boutique et commandes
  final OrderRepository orders;
  final AdminRepository admin;
  final ReviewRepository reviews;

  /// Analyse des ventes par Gemini, appelé directement depuis l'application.
  final SalesAnalysisRepository salesAnalysis;

  static Deps of(BuildContext context) {
    final deps = context.getInheritedWidgetOfExactType<Deps>();
    assert(deps != null, 'Deps introuvable : enveloppez l\'application dans Deps.mock(...)');
    return deps!;
  }

  @override
  bool updateShouldNotify(Deps oldWidget) => false;
}
