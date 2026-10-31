/// Une réservation de garde et son statut.
library;

import 'pet.dart';
import 'sitter.dart';
import 'species.dart';

enum BookingStatus { envoyee, attente, confirmee, enCours, terminee, annulee }

extension BookingStatusX on BookingStatus {
  String get label => switch (this) {
    BookingStatus.envoyee => 'Demande envoyée',
    BookingStatus.attente => 'En attente de réponse',
    BookingStatus.confirmee => 'Confirmée',
    BookingStatus.enCours => 'En cours',
    BookingStatus.terminee => 'Terminée',
    BookingStatus.annulee => 'Annulée',
  };
}

class Booking {
  final String id;
  final Sitter sitter;
  final List<Pet> pets;
  final ServiceType service;
  final String dates;
  final int total;
  final BookingStatus status;
  const Booking(this.id, this.sitter, this.pets, this.service, this.dates, this.total, this.status);
}

/// Devis d'une garde : règles de prix (supplément par animal, frais de service).
/// Ces règles « métier » vivent dans le modèle, pas dans l'écran.
class BookingQuote {
  const BookingQuote({
    required this.unitPrice,
    required this.units,
    required this.petCount,
    this.extraPetFee = 10,
    this.serviceFee = 8,
  });

  final int unitPrice; // prix par nuit ou par visite
  final int units; // nombre de nuits ou de visites
  final int petCount;
  final int extraPetFee;
  final int serviceFee;

  int get base => unitPrice * units;
  int get extra => petCount > 1 ? (petCount - 1) * extraPetFee * units : 0;
  int get total => petCount == 0 ? 0 : base + extra + serviceFee;
}
