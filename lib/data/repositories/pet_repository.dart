/// Les animaux de l'utilisateur connecté.
library;

import 'package:flutter/foundation.dart';
import 'package:pet_sitter/core/session/auth_session.dart';
import 'package:pet_sitter/data/sources/mock_data.dart';
import 'package:pet_sitter/models/models.dart';

/// Écoutable : l'accueil, « Mes animaux » et le profil se redessinent après un ajout.
abstract class PetRepository extends ChangeNotifier {
  String get ownerFirstName;
  String get ownerFullName;
  String get ownerPhoto;
  List<Pet> myPets();

  /// Enregistre la fiche remplie dans « Ajouter un animal » (voir [PetFormViewModel.answers]).
  Future<void> savePet(Map<String, Object?> answers);
}

/// Démonstration (`DEMO_DATA`, tests) : les animaux de Leïla, plus ceux ajoutés.
class MockPetRepository extends PetRepository {
  final List<Pet> _added = [];

  @override
  String get ownerFirstName => Mock.ownerFirstName;
  @override
  String get ownerFullName => Mock.ownerFullName;
  @override
  String get ownerPhoto => Photos.leila;

  @override
  List<Pet> myPets() => [...Mock.pets, ..._added];

  @override
  Future<void> savePet(Map<String, Object?> answers) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _added.add(petFromAnswers('pet-${DateTime.now().microsecondsSinceEpoch}', answers));
    notifyListeners();
  }
}

/// Application réelle : aucun animal fictif. Chaque compte voit les animaux qu'il a
/// ajoutés avec le formulaire (inscription, étape 2 sur 2, ou « Mes animaux »).
class SessionPetRepository extends PetRepository {
  SessionPetRepository(this._session) {
    _session.addListener(notifyListeners);
  }

  final AuthSession _session;
  final Map<String, List<Pet>> _byAccount = {};

  AppUser? get _user => _session.user;

  @override
  String get ownerFirstName => _user?.firstName ?? '';
  @override
  String get ownerFullName => _user?.fullName ?? '';
  @override
  String get ownerPhoto => _user?.photoUrl ?? '';

  @override
  List<Pet> myPets() => List.unmodifiable(_byAccount[_user?.id] ?? const <Pet>[]);

  @override
  Future<void> savePet(Map<String, Object?> answers) async {
    final userId = _user?.id;
    if (userId == null) return;
    _byAccount.putIfAbsent(userId, () => []).add(petFromAnswers('pet-${DateTime.now().microsecondsSinceEpoch}', answers));
    notifyListeners();
  }

  @override
  void dispose() {
    _session.removeListener(notifyListeners);
    super.dispose();
  }
}

/// Fiche [Pet] à partir des réponses du formulaire.
Pet petFromAnswers(String id, Map<String, Object?> a) {
  String text(String key) => (a[key] as String?)?.trim() ?? '';
  final vetName = text('vetName');
  final vetPhone = text('vetPhone');
  final vet = [vetName, vetPhone].where((s) => s.isNotEmpty).join(' · ');
  return Pet(
    id: id,
    name: text('name'),
    species: Species.values.firstWhere((s) => s.name == a['species'], orElse: () => Species.autre),
    breed: text('breed'),
    age: text('age'),
    photo: text('photo'),
    sex: text('sex').isEmpty ? '—' : text('sex'),
    food: Map<String, String>.from(a['food'] as Map? ?? const {}),
    habits: Map<String, String>.from(a['habits'] as Map? ?? const {}),
    behavior: List<String>.from(a['behavior'] as List? ?? const []),
    care: text('care'),
    vet: vet.isEmpty ? null : vet,
  );
}
