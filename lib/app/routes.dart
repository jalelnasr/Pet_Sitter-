import 'package:flutter/material.dart';

import 'package:pet_sitter/data/sources/mock_data.dart';
import 'package:pet_sitter/view_models/auth_view_model.dart';
import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/views/account/account_screens.dart';
import 'package:pet_sitter/views/auth/auth_screens.dart';
import 'package:pet_sitter/views/booking/booking_screens.dart';
import 'package:pet_sitter/views/catalog/catalog_screen.dart';
import 'package:pet_sitter/views/catalog/style_guide_screen.dart';
import 'package:pet_sitter/views/messages/messages_screens.dart';
import 'package:pet_sitter/views/onboarding/onboarding_screen.dart';
import 'package:pet_sitter/views/onboarding/splash_screen.dart';
import 'package:pet_sitter/views/owner/owner_shell.dart';
import 'package:pet_sitter/views/owner/pet_screens.dart';
import 'package:pet_sitter/views/owner/search_screen.dart';
import 'package:pet_sitter/views/owner/sitter_profile_screen.dart';
import 'package:pet_sitter/data/sources/mock_shop_data.dart';
import 'package:pet_sitter/views/shop/shop_screens.dart';
import 'package:pet_sitter/views/sitter/sitter_screens.dart';

/// Noms de routes (utilisables aussi en URL web : /#/search, /#/sitter…).
class R {
  R._();
  static const catalog = '/';
  static const splash = '/splash';
  static const splashPreview = '/splash-preview';
  static const onboarding = '/onboarding';
  static const onboarding2 = '/onboarding-2';
  static const onboarding3 = '/onboarding-3';
  static const signup = '/signup';
  static const signupErrors = '/signup-errors';
  static const login = '/login';
  static const loginError = '/login-error';
  static const forgot = '/forgot';
  static const role = '/role';
  static const addPet = '/add-pet';
  static const addPetFish = '/add-pet-fish';
  static const addPetDog = '/add-pet-dog';
  static const owner = '/owner';
  static const shop = '/shop';
  static const product = '/product';
  static const cart = '/cart';
  static const orderDone = '/order-done';
  static const bookings = '/bookings';
  static const messages = '/messages';
  static const account = '/account';
  static const search = '/search';
  static const searchMap = '/search-map';
  static const searchEmpty = '/search-empty';
  static const sitter = '/sitter';
  static const sitterNew = '/sitter-new';
  static const pet = '/pet';
  static const petFish = '/pet-fish';
  static const booking = '/booking';
  static const status = '/booking-status';
  static const statusPending = '/booking-pending';
  static const statusConfirmed = '/booking-confirmed';
  static const chat = '/chat';
  static const journal = '/journal';
  static const myPets = '/my-pets';
  static const favorites = '/favorites';
  static const notifications = '/notifications';
  static const help = '/help';
  static const settings = '/settings';
  static const sitterSpace = '/sitter-space';
  static const availability = '/availability';
  static const services = '/services';
  static const styleGuide = '/style-guide';

  // Aperçus d'états et d'interactions (captures du sommaire)
  static const homePlace = '/home-place';
  static const searchFilters = '/search-filters';
  static const searchDog = '/search-dog';
  static const sitterVisitsOnly = '/sitter-visits-only';
  static const addPetFirst = '/add-pet-first';
  static const addPetBird = '/add-pet-bird';
  static const addPetRabbit = '/add-pet-rabbit';
  static const addPetOther = '/add-pet-other';
  static const petBird = '/pet-bird';
  static const bookingDates = '/booking-dates';
  static const bookingVisits = '/booking-visits';
  static const roleChosen = '/role-chosen';
  static const forgotSent = '/forgot-sent';
  static const chatSitter = '/chat-sitter';
  static const journalAdd = '/journal-add';
  static const shopFood = '/shop-food';
  static const productPromo = '/product-promo';
  static const productAccessory = '/product-accessory';
  static const cartEmpty = '/cart-empty';
  static const sitterRefuse = '/sitter-refuse';
  static const sitterAccepted = '/sitter-accepted';
  static const sitterCalendar = '/sitter-calendar';
  static const sitterMessages = '/sitter-messages';
  static const sitterAccount = '/sitter-account';
}

Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  final a = settings.arguments;
  final Widget page = switch (settings.name) {
    R.catalog => const CatalogScreen(),
    R.splash => const SplashScreen(),
    R.splashPreview => const SplashScreen(autoNext: false),
    R.onboarding => const OnboardingScreen(),
    R.onboarding2 => const OnboardingScreen(initialPage: 1),
    R.onboarding3 => const OnboardingScreen(initialPage: 2),
    R.signup => const AuthScreen(initialMode: AuthMode.signup),
    R.signupErrors => const AuthScreen(initialMode: AuthMode.signup, showErrors: true),
    R.login => const AuthScreen(initialMode: AuthMode.login),
    R.loginError => const AuthScreen(initialMode: AuthMode.login, showErrors: true),
    R.forgot => const ForgotPasswordScreen(),
    R.role => const RoleChoiceScreen(),
    R.addPet => switch (a) {
      true => const AddPetScreen(firstTime: true),
      Species s => AddPetScreen(initial: s),
      _ => const AddPetScreen(),
    },
    R.addPetFish => const AddPetScreen(initial: Species.poisson),
    R.addPetDog => const AddPetScreen(initial: Species.chien),
    R.owner => OwnerShell(initialTab: a is int ? a : 0),
    R.shop => const OwnerShell(initialTab: OwnerTab.shop),
    R.product => ProductScreen(product: a is Product ? a : Shop.products.first),
    R.cart => const CartScreen(),
    R.orderDone => a is (int, int) ? OrderDoneScreen(total: a.$1, count: a.$2) : const OrderDoneScreen(),
    R.bookings => const OwnerShell(initialTab: OwnerTab.bookings),
    R.messages => const OwnerShell(initialTab: OwnerTab.messages),
    R.account => const OwnerShell(initialTab: OwnerTab.account),
    R.search => SearchResultsScreen(query: a is SearchQuery ? a : null),
    R.searchMap => const SearchResultsScreen(startOnMap: true),
    R.searchEmpty => const SearchResultsScreen(forceEmpty: true),
    R.sitter => SitterProfileScreen(sitter: a is Sitter ? a : Mock.amira),
    R.sitterNew => SitterProfileScreen(sitter: Mock.mehdi),
    R.pet => PetProfileScreen(pet: a is Pet ? a : Mock.simba),
    R.petFish => PetProfileScreen(pet: Mock.bulle),
    R.booking => BookingRequestScreen(sitter: a is Sitter ? a : Mock.amira),
    R.status => BookingStatusScreen(status: a is BookingStatus ? a : BookingStatus.envoyee),
    R.statusPending => const BookingStatusScreen(status: BookingStatus.attente),
    R.statusConfirmed => const BookingStatusScreen(status: BookingStatus.confirmee),
    R.chat => ChatScreen(asSitter: a == true),
    R.journal => ChatScreen(initialTab: 1, asSitter: a == true),
    R.myPets => const MyPetsScreen(),
    R.favorites => const FavoritesScreen(),
    R.notifications => const NotificationsScreen(),
    R.help => const HelpScreen(),
    R.settings => const SettingsScreen(),
    R.sitterSpace => const SitterShell(),
    R.availability => const AvailabilityScreen(),
    R.services => const ServicesPricingScreen(),
    R.styleGuide => const StyleGuideScreen(),
    R.homePlace => const OwnerShell(preview: 'place'),
    R.searchFilters => const SearchResultsScreen(preview: 'filters'),
    R.searchDog => SearchResultsScreen(query: SearchQuery(species: Species.chien)),
    R.sitterVisitsOnly => SitterProfileScreen(sitter: Mock.salma),
    R.addPetFirst => const AddPetScreen(firstTime: true),
    R.addPetBird => const AddPetScreen(initial: Species.oiseau),
    R.addPetRabbit => const AddPetScreen(initial: Species.lapin),
    R.addPetOther => const AddPetScreen(initial: Species.autre),
    R.petBird => PetProfileScreen(pet: Mock.kiwi),
    R.bookingDates => BookingRequestScreen(sitter: Mock.amira, preview: 'dates'),
    R.bookingVisits => BookingRequestScreen(sitter: Mock.amira, preview: 'visits'),
    R.roleChosen => const RoleChoiceScreen(preview: 'chosen'),
    R.forgotSent => const ForgotPasswordScreen(preview: 'sent'),
    R.chatSitter => const ChatScreen(asSitter: true),
    R.journalAdd => const ChatScreen(initialTab: 1, asSitter: true, preview: 'add-entry'),
    R.shopFood => const OwnerShell(initialTab: OwnerTab.shop, preview: 'food'),
    R.productPromo => ProductScreen(product: Shop.byId('croq-chien')),
    R.productAccessory => ProductScreen(product: Shop.byId('arbre')),
    R.cartEmpty => const CartScreen(preview: 'empty'),
    R.sitterRefuse => const SitterShell(preview: 'refuse'),
    R.sitterAccepted => const SitterShell(preview: 'accepted'),
    R.sitterCalendar => const SitterShell(initialTab: 1),
    R.sitterMessages => const SitterShell(initialTab: 2),
    R.sitterAccount => const SitterShell(initialTab: 3),
    _ => const CatalogScreen(),
  };
  return MaterialPageRoute(builder: (_) => page, settings: settings);
}
