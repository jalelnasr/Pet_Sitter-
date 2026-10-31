// Affiche les écrans de la boutique en mode API : aucun plantage ni débordement.

import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_sitter/app/dependencies.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';
import 'package:pet_sitter/core/widgets/floating_nav.dart';
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
import 'package:pet_sitter/data/sources/mock_shop_data.dart';
import 'package:pet_sitter/data/sources/session.dart';
import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/views/admin/admin_screens.dart';
import 'package:pet_sitter/views/shop/orders_screens.dart';
import 'package:pet_sitter/views/shop/shop_screens.dart';

Order _order(OrderStatus status) => Order(
  id: 1,
  number: 'PS-10001',
  status: status,
  paid: status == OrderStatus.delivered,
  subtotal: 98,
  shipping: 0,
  total: 98,
  itemCount: 2,
  delivery: const DeliveryAddress(recipient: 'Sami', phone: '20000000', address: 'Rue du Lac', city: 'La Marsa'),
  createdAt: DateTime(2026, 10, 31, 14),
  lines: const [OrderLine(productName: 'Croquettes', optionLabel: '2 kg', unitPrice: 49, quantity: 2, lineTotal: 98)],
  history: [OrderEvent(OrderStatus.confirmed, DateTime(2026, 10, 31, 14))],
);

class _FakeOrders implements OrderRepository {
  @override
  bool get cardAvailable => false;
  @override
  bool get requiresLogin => true;
  @override
  Future<Order> place({
    required List<CartLine> lines,
    required String payment,
    required DeliveryAddress delivery,
  }) async => _order(OrderStatus.confirmed);
  @override
  Future<List<Order>> mine() async => [_order(OrderStatus.confirmed)];
  @override
  Future<Order> cancel(int id) async => _order(OrderStatus.cancelled);
}

class _FakeAdmin implements AdminRepository {
  @override
  Future<List<Product>> products() async => Shop.products;
  @override
  Future<String> uploadImage(Uint8List bytes, String filename) async => '/api/images/x.png';
  @override
  Future<void> createProduct(String id, Map<String, dynamic> product) async {}
  @override
  Future<void> updateProduct(String id, Map<String, dynamic> product) async {}
  @override
  Future<void> removeProduct(String id) async {}
  @override
  Future<List<Order>> orders({OrderStatus? status}) async => [_order(OrderStatus.confirmed)];
  @override
  Future<Order> setStatus(int id, OrderStatus status) async => _order(status);
}

class _FakeReviews implements ReviewRepository {
  @override
  bool get enabled => true;
  @override
  Future<ReviewSummary> list(String productId) async => ReviewSummary(
    average: 4.5,
    count: 1,
    items: [ProductReview(id: 1, author: 'Amira', rating: 5, comment: 'Parfait', date: DateTime(2026, 10, 31))],
  );
  @override
  Future<MyReviewStatus> mine(String productId) async => const MyReviewStatus(canReview: true);
  @override
  Future<void> save(String productId, {required int rating, String? comment}) async {}
  @override
  Future<void> deleteMine(String productId) async {}
  @override
  Future<void> delete(int reviewId) async {}
}

Widget _app(Widget home, {CartRepository? cart, ReviewRepository? reviews, Session? session}) => Deps(
  auth: MockAuthRepository(),
  sitters: MockSitterRepository(),
  pets: MockPetRepository(),
  bookings: MockBookingRepository(),
  messages: MockMessageRepository(),
  shop: MockShopRepository(),
  cart: cart ?? CartRepository(demo: false),
  sitterSpace: MockSitterSpaceRepository(),
  session: session ?? Session(),
  orders: _FakeOrders(),
  admin: _FakeAdmin(),
  reviews: reviews ?? MockReviewRepository(),
  child: MaterialApp(home: home),
);

Future<void> _show(
  WidgetTester tester,
  Widget home, {
  CartRepository? cart,
  ReviewRepository? reviews,
  Session? session,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(home, cart: cart, reviews: reviews, session: session));
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(seconds: 2));
}

/// Fait défiler la première liste de l'écran jusqu'à [finder], puis touche l'élément.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).last);
  await tester.pump();
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    // Polices absentes en test : seul ce message est ignoré, toute autre erreur fait échouer le test.
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('GoogleFonts')) return;
      previous?.call(details);
    };
  });

  testWidgets('panier sans adresse : carte masquée, adresse demandée', (tester) async {
    final cart = CartRepository(demo: false)..add(Shop.products.first, Shop.products.first.options.first);
    await _show(tester, const CartScreen(), cart: cart);
    expect(find.text('Ajouter une adresse'), findsOneWidget);
    expect(find.text('Carte bancaire'), findsNothing);

    await _scrollTo(tester, find.text('Ajouter une adresse'));
    await tester.tap(find.text('Ajouter une adresse'));
    await tester.pumpAndSettle();
    expect(find.text('Adresse de livraison'), findsOneWidget);
    await tester.tap(find.text('Enregistrer l\'adresse'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Champ obligatoire.'), findsWidgets);
    expect(find.text('Numéro de téléphone invalide.'), findsOneWidget);
  });

  testWidgets('confirmation avec le vrai numéro de commande', (tester) async {
    await _show(tester, OrderDoneScreen(order: _order(OrderStatus.confirmed)));
    expect(find.textContaining('PS-10001'), findsOneWidget);
    expect(find.textContaining('20 octobre'), findsNothing);
    expect(find.text('Voir mes commandes'), findsOneWidget);
  });

  testWidgets('mes commandes puis détail', (tester) async {
    await _show(tester, const MyOrdersScreen());
    expect(find.text('PS-10001'), findsOneWidget);
    await tester.tap(find.text('PS-10001'));
    await tester.pumpAndSettle();
    expect(find.text('En préparation'), findsOneWidget);
    await _scrollTo(tester, find.text('Annuler la commande'));
    expect(find.text('Annuler la commande'), findsOneWidget);
  });

  testWidgets('espace admin : commandes, produits et formulaire', (tester) async {
    await _show(tester, const AdminShell());
    expect(find.text('Préparer'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);

    // L'onglet inactif n'affiche que son icône.
    await tester.tap(find.byIcon(PhosphorIconsRegular.storefront));
    await tester.pumpAndSettle();
    expect(find.text('Ajouter'), findsOneWidget);
    // Deux produits par ligne, avec le stock et le nombre d'avis.
    final first = tester.getTopLeft(find.text(Shop.products[0].name).first);
    final second = tester.getTopLeft(find.text(Shop.products[1].name).first);
    expect(first.dy, second.dy);
    expect(second.dx, greaterThan(first.dx));
    expect(find.byType(FloatingNav), findsOneWidget);

    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();
    expect(find.text('Nouveau produit'), findsOneWidget);
    expect(find.text('Choisir une photo'), findsOneWidget);
    expect(find.text('Icône'), findsNothing);
    await tester.tap(find.text('Créer le produit'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Champ obligatoire.'), findsWidgets);
  });

  testWidgets('fiche produit : avis affichés et formulaire d\'avis', (tester) async {
    final session = Session();
    await session.open('j', const SessionUser(id: 'u', name: 'S', email: 'e', role: UserRole.owner));
    await _show(
      tester,
      ProductScreen(product: Shop.products.first),
      reviews: _FakeReviews(),
      session: session,
    );
    await _scrollTo(tester, find.text('Donner mon avis'));
    expect(find.text('Parfait'), findsOneWidget);
    await tester.tap(find.text('Donner mon avis'));
    await tester.pumpAndSettle();
    expect(find.text('Votre avis'), findsOneWidget);
    expect(find.text('Publier mon avis'), findsOneWidget);
  });

  testWidgets('admin : voit et peut supprimer les avis depuis le produit', (tester) async {
    final session = Session();
    await session.open('j', const SessionUser(id: 'a', name: 'Admin', email: 'e', role: UserRole.admin));
    await _show(
      tester,
      ProductFormScreen(product: Shop.products.first),
      reviews: _FakeReviews(),
      session: session,
    );
    // La dernière zone défilante est ici un champ de texte : on vise la liste du formulaire.
    final form = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
    final position = tester.state<ScrollableState>(form).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    await tester.pump();
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    expect(find.text('Parfait'), findsOneWidget);
    expect(find.text('Avis des clients'), findsOneWidget);
    expect(find.byTooltip('Supprimer cet avis'), findsOneWidget);
  });

  testWidgets('produit épuisé : ajout impossible', (tester) async {
    const soldOut = Product(
      id: 'x',
      name: 'Produit',
      brand: 'M',
      category: ShopCategory.jouets,
      species: [Species.chat],
      options: [ProductOption('U', 10, id: 1, stock: 0)],
      rating: 0,
      reviews: 0,
      kind: PackKind.object,
      color: Color(0xFF0F5534),
      tint: Color(0xFFE3F1E7),
      icon: Icons.pets,
      description: 'D',
      details: {},
    );
    await _show(tester, const ProductScreen(product: soldOut));
    expect(find.text('Épuisé'), findsOneWidget);
    expect(find.text('Ajouter au panier'), findsNothing);
  });
}
