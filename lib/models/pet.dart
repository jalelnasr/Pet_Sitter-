/// Un animal de compagnie et sa fiche (repas, habitudes, soins).
library;

import 'species.dart';

class Pet {
  final String id;
  final String name;
  final Species species;
  final String breed;
  final String age;
  final String photo;
  final String sex;
  final Map<String, String> food;
  final Map<String, String> habits;
  final List<String> behavior;
  final String care;
  final String? vet;
  const Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.age,
    required this.photo,
    required this.sex,
    required this.food,
    required this.habits,
    required this.behavior,
    required this.care,
    this.vet,
  });
}
