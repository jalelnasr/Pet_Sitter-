/// Les animaux de l'utilisateur connecté.
library;

import 'package:pet_sitter/data/sources/mock_data.dart';
import 'package:pet_sitter/models/models.dart';

abstract class PetRepository {
  String get ownerFirstName;
  String get ownerFullName;
  String get ownerPhoto;
  List<Pet> myPets();
  Future<void> savePet(Map<String, Object?> answers);
}

class MockPetRepository implements PetRepository {
  @override
  String get ownerFirstName => Mock.ownerFirstName;
  @override
  String get ownerFullName => Mock.ownerFullName;
  @override
  String get ownerPhoto => Photos.leila;

  @override
  List<Pet> myPets() => Mock.pets;

  @override
  Future<void> savePet(Map<String, Object?> answers) => Future.delayed(const Duration(milliseconds: 900));
}
