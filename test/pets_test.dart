// Animaux du propriétaire : aucun animal inventé dans l'application réelle, la fiche
// remplie dans « Ajouter un animal » apparaît pour le compte qui l'a ajoutée.
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_sitter/core/session/auth_session.dart';
import 'package:pet_sitter/data/repositories/cart_repository.dart';
import 'package:pet_sitter/data/repositories/pet_repository.dart';
import 'package:pet_sitter/data/repositories/shop_repository.dart';
import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/view_models/account_view_model.dart';
import 'package:pet_sitter/view_models/home_view_model.dart';
import 'package:pet_sitter/view_models/pet_form_view_model.dart';
import 'package:pet_sitter/data/repositories/sitter_repository.dart';

const _leila = AppUser(id: 'leila', firstName: 'Leïla', email: 'l@exemple.tn', role: AppRole.owner);
const _sami = AppUser(id: 'sami', firstName: 'Sami', email: 's@exemple.tn', role: AppRole.owner);

void main() {
  late AuthSession session;
  late SessionPetRepository pets;

  setUp(() async {
    session = AuthSession.isolated();
    await session.open(token: 't1', user: _leila);
    pets = SessionPetRepository(session);
  });

  tearDown(() => pets.dispose());

  test('nouveau compte : aucun animal inventé', () {
    expect(pets.myPets(), isEmpty);
    expect(AccountViewModel(pets, MockSitterRepository(), session: session).petsSummary, 'Aucun animal pour le moment');
  });

  test('le formulaire enregistre toute la fiche, rangée comme la fiche de l\'animal', () async {
    final form = PetFormViewModel(pets, initial: Species.chien, firstTime: true);
    final race = form.sections.expand((s) => s.$3).whereType<TextQ>().firstWhere((q) => q.label == 'Race');
    final food = form.sections.expand((s) => s.$3).whereType<TextQ>().firstWhere((q) => q.label == 'Nourriture et quantité');
    final character = form.sections.expand((s) => s.$3).whereType<ChoiceQ>().firstWhere((q) => q.label == 'Caractère');
    form
      ..setText(race, 'Berger allemand')
      ..setText(food, 'Croquettes, 250 g par jour')
      ..tapChoice(character, 'Joueur')
      ..setSex('Femelle')
      ..age = '3'
      ..care = 'Vermifuge le 1er du mois'
      ..vetName = 'Clinique du Lac'
      ..vetPhone = '71 000 000';

    expect(await form.save('  Nala '), isTrue);

    final nala = pets.myPets().single;
    expect(nala.name, 'Nala');
    expect(nala.species, Species.chien);
    expect(nala.breed, 'Berger allemand');
    expect(nala.age, '3 ans');
    expect(nala.sex, 'Femelle');
    expect(nala.food['Nourriture et quantité'], 'Croquettes, 250 g par jour');
    expect(nala.food['Repas par jour'], '2');
    expect(nala.habits['Promenades par jour'], '3');
    expect(nala.behavior, contains('Joueur'));
    expect(nala.care, 'Vermifuge le 1er du mois');
    expect(nala.vet, 'Clinique du Lac · 71 000 000');
    form.dispose();
  });

  test('sans nom, rien n\'est enregistré', () async {
    final form = PetFormViewModel(pets);
    expect(await form.save('   '), isFalse);
    expect(form.error, isNotNull);
    expect(pets.myPets(), isEmpty);
    form.dispose();
  });

  test('un poisson : pas de sexe enregistré', () async {
    final form = PetFormViewModel(pets, initial: Species.poisson);
    await form.save('Bulle');
    expect(pets.myPets().single.sex, '—');
    form.dispose();
  });

  test('chaque compte voit ses propres animaux', () async {
    await PetFormViewModel(pets).save('Mimi');
    await session.open(token: 't2', user: _sami);
    expect(pets.myPets(), isEmpty);
    await PetFormViewModel(pets, initial: Species.chien).save('Rex');
    expect(pets.myPets().map((p) => p.name), ['Rex']);
    await session.open(token: 't3', user: _leila);
    expect(pets.myPets().map((p) => p.name), ['Mimi']);
  });

  test('l\'accueil et la boutique suivent les animaux ajoutés', () async {
    final home = HomeViewModel(pets: pets, shop: MockShopRepository(), cart: CartRepository(), session: session);
    var redraws = 0;
    home.addListener(() => redraws++);
    expect(home.shopSubtitle, 'Accessoires et nourriture · livraison offerte dès 80 DT');

    await PetFormViewModel(pets).save('Mimi');
    await PetFormViewModel(pets, initial: Species.chien).save('Rex');
    expect(redraws, greaterThan(0));
    expect(home.pets.map((p) => p.name), ['Mimi', 'Rex']);
    expect(home.shopSubtitle, 'Pour Mimi et Rex · livraison offerte dès 80 DT');
    home.dispose();
  });

  test('salutation selon l\'heure', () {
    HomeViewModel at(int hour) => HomeViewModel(
      pets: pets,
      shop: MockShopRepository(),
      cart: CartRepository(),
      now: () => DateTime(2026, 11, 10, hour),
    );
    expect(at(9).greeting, startsWith('Bonne journée'));
    expect(at(20).greeting, startsWith('Bonne soirée'));
  });
}
