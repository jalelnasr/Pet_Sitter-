/// Routes nommées du module Adoption.
///
/// À brancher dans `lib/app/routes.dart` sans modifier les routes existantes :
/// `final adoption = onGenerateAdoptionRoute(settings); if (adoption != null) return adoption;`
library;

import 'package:flutter/material.dart';

import 'adoption_mock.dart';
import 'adoption_models.dart';
import 'adoption_screens.dart';

class AdoptionRoutes {
  AdoptionRoutes._();
  static const list = '/adoption';
  static const details = '/adoption-details';
  static const request = '/adoption-request';
  static const myRequests = '/adoption-requests';
  static const myListings = '/adoption-mine';
  static const receivedRequests = '/adoption-received';
  static const requestDetails = '/adoption-request-details';
  static const createListing = '/adoption-create';
  static const admin = '/adoption-admin';
  static const emptyList = '/adoption-empty';
  static const emptyRequests = '/adoption-requests-empty';
}

Route<dynamic>? onGenerateAdoptionRoute(RouteSettings settings) {
  final a = settings.arguments;
  final Widget? page = switch (settings.name) {
    // `/adoption` est ouvert par l'onglet de navigation (OwnerShell → OwnerTab.adoption).
    AdoptionRoutes.details =>
      a is AdoptionPet
          ? AdoptionDetailsScreen(listingId: a.id, pet: a)
          : AdoptionDetailsScreen(
              listingId: a is String ? a : AdoptionMock.pets.first.id,
              pet: a is String ? null : AdoptionMock.pets.first,
            ),
    AdoptionRoutes.request => AdoptionRequestScreen(
      pet: a is AdoptionPet ? a : AdoptionMock.pets.first,
    ),
    AdoptionRoutes.myRequests => const MyAdoptionRequestsScreen(),
    AdoptionRoutes.myListings => const MyAdoptionListingsScreen(),
    AdoptionRoutes.receivedRequests => const ReceivedAdoptionRequestsScreen(),
    AdoptionRoutes.requestDetails =>
      a is String ? AdoptionRequestDetailsScreen(requestId: a) : null,
    AdoptionRoutes.createListing => const AdoptionListingFormScreen(),
    AdoptionRoutes.admin => const AdminAdoptionScreen(),
    AdoptionRoutes.emptyList => const AdoptionListScreen(forceEmpty: true),
    AdoptionRoutes.emptyRequests => const MyAdoptionRequestsScreen(
      forceEmpty: true,
    ),
    _ => null,
  };
  if (page == null) return null;
  return MaterialPageRoute(builder: (_) => page, settings: settings);
}
