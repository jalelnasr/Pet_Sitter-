// Tests des ViewModels : la logique de l'application se vérifie sans afficher un seul écran.
// Lancer : flutter test
import 'package:flutter/material.dart' show RangeValues;
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_sitter/data/repositories/auth_repository.dart';
import 'package:pet_sitter/data/repositories/booking_repository.dart';
import 'package:pet_sitter/data/repositories/cart_repository.dart';
import 'package:pet_sitter/data/repositories/pet_repository.dart';
import 'package:pet_sitter/data/repositories/sitter_repository.dart';
import 'package:pet_sitter/data/sources/mock_data.dart';
import 'package:pet_sitter/data/sources/mock_shop_data.dart';
import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/view_models/auth_view_model.dart';
import 'package:pet_sitter/view_models/booking_view_model.dart';
import 'package:pet_sitter/view_models/pet_form_view_model.dart';
import 'package:pet_sitter/view_models/search_view_model.dart';
import 'package:pet_sitter/view_models/shop_view_model.dart';

void main() {
  group('Devis de réservation (modèle)', () {
    test('3 nuits à 35 DT, 2 animaux : 105 + 30 de supplément + 8 de frais = 143 DT', () {
      const q = BookingQuote(unitPrice: 35, units: 3, petCount: 2);
      expect(q.base, 105);
      expect(q.extra, 30);
      expect(q.total, 143);
    });

    test('aucun animal choisi : total nul', () {
      expect(const BookingQuote(unitPrice: 35, units: 3, petCount: 0).total, 0);
    });
  });

  group('BookingRequestViewModel', () {
    test('ne propose pas Bulle (poisson) à une sitter qui ne garde pas les poissons', () {
      final vm = BookingRequestViewModel(
        sitter: Mock.amira,
        bookings: MockBookingRepository(),
        pets: MockPetRepository(),
      );
      expect(vm.accepts(Mock.bulle), isFalse);
      vm.togglePet(Mock.bulle);
      expect(vm.isSelected(Mock.bulle), isFalse);
      expect(vm.quote.total, 143);
    });

    test('passer en visites à domicile recalcule le nombre de visites', () {
      final vm = BookingRequestViewModel(
        sitter: Mock.amira,
        bookings: MockBookingRepository(),
        pets: MockPetRepository(),
      );
      vm.setService(Mock.amira.services.firstWhere((s) => s.type == ServiceType.visite));
      expect(vm.units, 4); // 4 jours × 1 visite
      vm.setVisitsPerDay(2);
      expect(vm.units, 8);
    });
  });

  group('SearchViewModel', () {
    test('un budget maximum de 30 DT écarte les sitters plus chers', () {
      final vm = SearchViewModel(MockSitterRepository());
      final before = vm.results.length;
      vm.setBudget(const RangeValues(10, 30));
      expect(vm.results.length, lessThan(before));
      expect(vm.results.every((s) => s.services.firstWhere((o) => o.type == vm.query.service).price <= 30), isTrue);
    });

    test('l\'aperçu « aucun résultat » renvoie une liste vide', () {
      expect(SearchViewModel(MockSitterRepository(), forceEmpty: true).results, isEmpty);
    });
  });

  group('PetFormViewModel', () {
    test('un poisson n\'a ni promenade ni question de sexe', () {
      final vm = PetFormViewModel(MockPetRepository(), initial: Species.poisson);
      final labels = vm.sections.expand((s) => s.$3).map((f) => f.label);
      expect(labels, isNot(contains('Promenades par jour')));
      expect(vm.asksSex, isFalse);
    });

    test('un chien a bien des promenades', () {
      final vm = PetFormViewModel(MockPetRepository(), initial: Species.chien);
      final labels = vm.sections.expand((s) => s.$3).map((f) => f.label);
      expect(labels, contains('Promenades par jour'));
    });
  });

  group('Panier', () {
    test('livraison offerte à partir de 80 DT', () {
      final cart = CartRepository(); // contient déjà 49 + 2 × 14 = 77 DT
      final vm = CartViewModel(cart);
      expect(vm.subtotal, 77);
      expect(vm.shipping, CartRepository.shippingFee);
      expect(vm.missingForFreeShipping, 3);
      vm.add(Shop.products.firstWhere((p) => p.id == 'foin')); // +9 DT
      expect(vm.shipping, 0);
      vm.dispose();
    });

    test('commander vide le panier et renvoie le total', () async {
      final vm = CartViewModel(CartRepository());
      final (total, count) = await vm.order();
      expect(total, 84);
      expect(count, 3);
      expect(vm.isEmpty, isTrue);
      vm.dispose();
    });
  });

  group('AuthViewModel', () {
    test('valide les adresses e-mail', () {
      expect(AuthViewModel.validateEmail('leila@'), isNotNull);
      expect(AuthViewModel.validateEmail('leila@exemple.tn'), isNull);
    });

    test('un mot de passe trop court à la connexion affiche une erreur', () async {
      final vm = AuthViewModel(MockAuthRepository(), initialMode: AuthMode.login);
      final ok = await vm.submit(fieldsValid: true, name: '', email: 'a@b.tn', password: 'court');
      expect(ok, isFalse);
      expect(vm.banner, contains('incorrect'));
    });

    test('à l\'inscription, les conditions doivent être acceptées', () async {
      final vm = AuthViewModel(MockAuthRepository());
      expect(
        await vm.submit(fieldsValid: true, name: 'Leïla Ben Salah', email: 'a@b.tn', password: 'chat2026!'),
        isFalse,
      );
      expect(vm.termsError, isTrue);
      vm.setTerms(true);
      expect(
        await vm.submit(fieldsValid: true, name: 'Leïla Ben Salah', email: 'a@b.tn', password: 'chat2026!'),
        isTrue,
      );
    });
  });
}
