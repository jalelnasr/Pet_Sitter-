/// Réservations : liste, envoi d'une demande.
library;

import 'package:pet_sitter/data/sources/mock_data.dart';
import 'package:pet_sitter/models/models.dart';

abstract class BookingRepository {
  List<Booking> all();
  Future<void> sendRequest({
    required Sitter sitter,
    required List<Pet> pets,
    required SitterService service,
    required DateTime start,
    required DateTime end,
    required String notes,
  });
}

class MockBookingRepository implements BookingRepository {
  @override
  List<Booking> all() => Mock.bookings;

  @override
  Future<void> sendRequest({
    required Sitter sitter,
    required List<Pet> pets,
    required SitterService service,
    required DateTime start,
    required DateTime end,
    required String notes,
  }) => Future.delayed(const Duration(milliseconds: 1400));
}
