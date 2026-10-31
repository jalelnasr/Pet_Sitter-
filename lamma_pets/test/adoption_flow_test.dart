import 'dart:io';
// Tests temporaires de vérification de l'intégration Flutter Adoption.
// Ils utilisent un dépôt simulé : aucun backend n'est requis.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_sitter/adoption/adoption_models.dart';
import 'package:pet_sitter/adoption/adoption_repository.dart';
import 'package:pet_sitter/adoption/adoption_screens.dart';
import 'package:pet_sitter/adoption/api/demo_session.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/widgets/common.dart';
import 'package:pet_sitter/models/species.dart';

class FakeAdoptionRepository implements AdoptionRepository {
  FakeAdoptionRepository({
    List<AdoptionPet>? pets,
    List<AdoptionRequest>? sent,
    List<AdoptionRequest>? received,
  }) : pets = [...?pets],
       sent = [...?sent],
       received = [...?received];

  final List<AdoptionPet> pets;
  final List<AdoptionRequest> sent;
  final List<AdoptionRequest> received;
  AdoptionDraft? createdDraft;
  AdoptionDraft? updatedDraft;
  String? lastAction;

  @override
  Future<List<AdoptionPet>> listings({
    Species? species,
    String? location,
  }) async => [...pets];

  @override
  Future<AdoptionPet> listing(String id) async =>
      pets.firstWhere((pet) => pet.id == id);

  @override
  Future<List<AdoptionPet>> mine() async => pets
      .where(
        (pet) => pet.publisherId == DemoSessionProvider.instance.currentUserId,
      )
      .toList();

  @override
  Future<AdoptionPet> create(
    AdoptionDraft draft, {
    bool asDraft = false,
  }) async {
    createdDraft = draft;
    final pet = fixturePet(
      id: 'created-${pets.length + 1}',
      name: draft.petName,
      status: asDraft
          ? AdoptionListingStatus.draft
          : AdoptionListingStatus.published,
      publisherId: DemoSessionProvider.instance.currentUserId,
    );
    pets.add(pet);
    return pet;
  }

  @override
  Future<AdoptionPet> update(String id, AdoptionDraft draft) async {
    updatedDraft = draft;
    final updated = fixturePet(
      id: id,
      name: draft.petName,
      publisherId: DemoSessionProvider.instance.currentUserId,
    );
    _replacePet(updated);
    return updated;
  }

  @override
  Future<AdoptionPet> publish(String id) async =>
      _status(id, AdoptionListingStatus.published);

  @override
  Future<AdoptionPet> pause(String id) async =>
      _status(id, AdoptionListingStatus.paused);

  @override
  Future<AdoptionPet> archive(String id) async =>
      _status(id, AdoptionListingStatus.archived);

  @override
  Future<List<AdoptionPet>> adminListings() async => [...pets];

  @override
  Future<AdoptionPet> adminHide(String id) async =>
      _status(id, AdoptionListingStatus.hidden);

  @override
  Future<AdoptionPet> adminArchive(String id) async =>
      _status(id, AdoptionListingStatus.archived);

  @override
  Future<String> uploadImage(File file, {String? contentType}) async =>
      'https://example.com/test.jpg';

  @override
  Future<AdoptionRequest> sendRequest({
    required String listingId,
    required String fullName,
    required String phone,
    required String address,
    required String message,
    required String experience,
    required HousingType housingType,
    required bool hasGarden,
    required bool hasOtherPets,
    String? otherPetsDetails,
    int? aiScore,
  }) async {
    final request = fixtureRequest(
      pet: pets.firstWhere((pet) => pet.id == listingId),
      fullName: fullName,
      phone: phone,
      address: address,
      motivation: message,
      experience: experience,
      housingType: housingType,
      hasGarden: hasGarden,
      hasOtherPets: hasOtherPets,
      aiScore: aiScore,
    );
    sent.insert(0, request);
    received.insert(0, request);
    return request;
  }

  @override
  Future<AdoptionAiAdvice> matchingAdvice({
    required String listingId,
    required HousingType housingType,
    required bool hasGarden,
    required bool hasOtherPets,
    String? otherPetsDetails,
    String? experience,
    String? motivation,
  }) async {
    return const AdoptionAiAdvice(
      score: 75,
      summary: 'Conseil IA de test.',
      tips: ['Conseil de test.'],
    );
  }

  @override
  Future<List<AdoptionRequest>> sentRequests() async => [...sent];

  @override
  Future<List<AdoptionRequest>> receivedRequests() async => [...received];

  @override
  Future<AdoptionRequest> request(String id) async =>
      [...sent, ...received].firstWhere((request) => request.id == id);

  @override
  Future<AdoptionRequest> acceptRequest(String id, {String? message}) async =>
      _process(id, AdoptionStatus.accepted, message);

  @override
  Future<AdoptionRequest> rejectRequest(String id, {String? message}) async =>
      _process(id, AdoptionStatus.refused, message);

  @override
  Future<AdoptionRequest> cancelRequest(String id, {String? message}) async =>
      _process(id, AdoptionStatus.cancelled, message);

  AdoptionPet _status(String id, AdoptionListingStatus status) {
    lastAction = status.name;
    final index = pets.indexWhere((pet) => pet.id == id);
    final current = pets[index];
    final updated = AdoptionPet(
      id: current.id,
      name: current.name,
      species: current.species,
      breed: current.breed,
      age: current.age,
      sex: current.sex,
      city: current.city,
      area: current.area,
      photo: current.photo,
      description: current.description,
      health: current.health,
      vaccinated: current.vaccinated,
      sterilized: current.sterilized,
      extra: current.extra,
      status: status,
      publisherId: current.publisherId,
      publisherName: current.publisherName,
      gender: current.gender,
      imageUrls: current.imageUrls,
      ageYears: current.ageYears,
      createdAt: current.createdAt,
    );
    _replacePet(updated);
    return updated;
  }

  AdoptionRequest _process(String id, AdoptionStatus status, String? message) {
    final source = [
      ...sent,
      ...received,
    ].firstWhere((request) => request.id == id);
    final updated = AdoptionRequest(
      id: source.id,
      pet: status == AdoptionStatus.accepted
          ? _status(source.pet.id, AdoptionListingStatus.adopted)
          : source.pet,
      fullName: source.fullName,
      phone: source.phone,
      address: source.address,
      experience: source.experience,
      motivation: source.motivation,
      date: source.date,
      status: status,
      applicantId: source.applicantId,
      applicantName: source.applicantName,
      aiScore: source.aiScore,
      responseMessage: message,
      processedAt: DateTime(2026, 10, 30),
      housingType: source.housingType,
      hasGarden: source.hasGarden,
      hasOtherPets: source.hasOtherPets,
      otherPetsDetails: source.otherPetsDetails,
    );
    for (var i = 0; i < sent.length; i++) {
      if (sent[i].id == id) sent[i] = updated;
    }
    for (var i = 0; i < received.length; i++) {
      if (received[i].id == id) received[i] = updated;
    }
    return updated;
  }

  void _replacePet(AdoptionPet updated) {
    final index = pets.indexWhere((pet) => pet.id == updated.id);
    if (index >= 0) pets[index] = updated;
  }
}

AdoptionPet fixturePet({
  String id = 'listing-1',
  String name = 'Milo',
  AdoptionListingStatus status = AdoptionListingStatus.published,
  String publisherId = 'OWNER_DEMO',
  String publisherName = 'Amira',
  int? ageYears = 2,
}) => AdoptionPet(
  id: id,
  name: name,
  species: Species.chat,
  breed: 'Européen',
  age: ageYears == null ? 'Âge inconnu' : '$ageYears ans',
  sex: 'Mâle',
  city: 'Tunis',
  area: 'La Marsa',
  photo: 'https://example.com/milo.jpg',
  description: 'Un chat calme et câlin qui cherche une famille.',
  health: 'En bonne santé',
  vaccinated: true,
  sterilized: true,
  extra: const {},
  status: status,
  publisherId: publisherId,
  publisherName: publisherName,
  gender: PetGender.male,
  imageUrls: const ['https://example.com/milo.jpg'],
  ageYears: ageYears,
);

AdoptionRequest fixtureRequest({
  String id = 'request-1',
  AdoptionPet? pet,
  AdoptionStatus status = AdoptionStatus.pending,
  String applicantId = 'PETSITTER_DEMO',
  String applicantName = 'Sami',
  String fullName = 'Sami Ben Ali',
  String phone = '22 345 678',
  String address = '12 rue des Jasmins, Tunis',
  String motivation =
      'Je souhaite offrir un foyer calme et aimant à cet animal.',
  String experience = 'J\'ai déjà gardé des chats pendant plusieurs années.',
  HousingType housingType = HousingType.apartment,
  bool hasGarden = false,
  bool hasOtherPets = false,
  int? aiScore = 85,
  String? responseMessage,
}) => AdoptionRequest(
  id: id,
  pet: pet ?? fixturePet(),
  fullName: fullName,
  phone: phone,
  address: address,
  experience: experience,
  motivation: motivation,
  date: DateTime(2026, 10, 12),
  status: status,
  applicantId: applicantId,
  applicantName: applicantName,
  aiScore: aiScore,
  responseMessage: responseMessage,
  housingType: housingType,
  hasGarden: hasGarden,
  hasOtherPets: hasOtherPets,
);

Widget app(Widget child) =>
    MaterialApp(theme: buildPetSitterTheme(), home: child);

Future<void> pumpPushed(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildPetSitterTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => screen)),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    DemoSessionProvider.instance.select(DemoUsers.owner);
  });

  testWidgets('la liste charge les annonces du dépôt', (tester) async {
    final repo = FakeAdoptionRepository(pets: [fixturePet()]);
    await tester.pumpWidget(app(AdoptionListScreen(repository: repo)));
    await tester.pumpAndSettle();

    expect(find.text('Milo'), findsOneWidget);
    expect(find.textContaining('1 animal'), findsOneWidget);
    expect(find.text('Données du backend'), findsOneWidget);
  });

  testWidgets('le sélecteur de démo change les actions affichées', (
    tester,
  ) async {
    final repo = FakeAdoptionRepository(pets: [fixturePet()]);
    await tester.pumpWidget(app(AdoptionListScreen(repository: repo)));
    await tester.pumpAndSettle();

    expect(find.text('Publier'), findsOneWidget);
    expect(find.text('Mes annonces'), findsOneWidget);

    DemoSessionProvider.instance.select(DemoUsers.admin);
    await tester.pumpAndSettle();

    expect(find.text('Modération'), findsOneWidget);
    expect(find.text('Publier'), findsNothing);
    expect(find.text('Mes annonces'), findsNothing);
  });

  testWidgets('la fiche affiche les actions du propriétaire', (tester) async {
    final repo = FakeAdoptionRepository(pets: [fixturePet()]);
    await tester.pumpWidget(
      app(AdoptionDetailsScreen(listingId: 'listing-1', repository: repo)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Modifier'), findsOneWidget);
    expect(find.text('Reçues'), findsOneWidget);
    expect(find.text('Mettre en pause'), findsOneWidget);
    expect(find.text('Faire une demande d\'adoption'), findsNothing);
    expect(
      find.textContaining('Vous avez publié cette annonce'),
      findsOneWidget,
    );
  });

  testWidgets(
    'la fiche affiche le bouton de demande pour un autre utilisateur',
    (tester) async {
      DemoSessionProvider.instance.select(DemoUsers.petsitter);
      final repo = FakeAdoptionRepository(pets: [fixturePet()]);
      await tester.pumpWidget(
        app(AdoptionDetailsScreen(listingId: 'listing-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Faire une demande d\'adoption'), findsOneWidget);
      expect(find.text('Modifier'), findsNothing);
    },
  );

  testWidgets('une annonce adoptée masque le bouton de demande', (
    tester,
  ) async {
    DemoSessionProvider.instance.select(DemoUsers.petsitter);
    final repo = FakeAdoptionRepository(
      pets: [fixturePet(status: AdoptionListingStatus.adopted)],
    );
    await tester.pumpWidget(
      app(AdoptionDetailsScreen(listingId: 'listing-1', repository: repo)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Faire une demande d\'adoption'), findsNothing);
    expect(find.textContaining('aucune demande possible'), findsOneWidget);
  });

  testWidgets('la modération est accessible à l\'admin', (tester) async {
    DemoSessionProvider.instance.select(DemoUsers.admin);
    final repo = FakeAdoptionRepository(pets: [fixturePet()]);
    await tester.pumpWidget(app(AdminAdoptionScreen(repository: repo)));
    await tester.pumpAndSettle();

    expect(find.text('Modération'), findsOneWidget);
    expect(find.text('Masquer'), findsOneWidget);

    await tester.tap(find.text('Masquer').first);
    await tester.pumpAndSettle();

    expect(repo.pets.first.status, AdoptionListingStatus.hidden);
    expect(find.text('Annonce masquée.'), findsOneWidget);
  });

  testWidgets(
    'le propriétaire accepte une demande et l\'annonce devient adoptée',
    (tester) async {
      final request = fixtureRequest();
      final repo = FakeAdoptionRepository(
        pets: [fixturePet()],
        received: [request],
      );
      await tester.pumpWidget(
        app(
          AdoptionRequestDetailsScreen(
            requestId: 'request-1',
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Accepter'), findsOneWidget);
      expect(find.text('Refuser'), findsOneWidget);

      await tester.tap(find.widgetWithText(PawButton, 'Accepter'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Confirmer : accepter'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Accepter'));
      await tester.pumpAndSettle();

      expect(repo.received.first.status, AdoptionStatus.accepted);
      expect(repo.pets.first.status, AdoptionListingStatus.adopted);
      expect(find.text('Acceptée'), findsOneWidget);
    },
  );

  testWidgets('le demandeur peut annuler sa demande en attente', (
    tester,
  ) async {
    DemoSessionProvider.instance.select(DemoUsers.petsitter);
    final repo = FakeAdoptionRepository(
      pets: [fixturePet()],
      sent: [fixtureRequest()],
    );
    await tester.pumpWidget(
      app(
        AdoptionRequestDetailsScreen(requestId: 'request-1', repository: repo),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Annuler ma demande'), findsOneWidget);
    await tester.tap(find.widgetWithText(LoadingButton, 'Annuler ma demande'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmer'));
    await tester.pumpAndSettle();

    expect(repo.sent.first.status, AdoptionStatus.cancelled);
  });

  testWidgets('le formulaire de demande envoie les données au dépôt', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    DemoSessionProvider.instance.select(DemoUsers.petsitter);
    final repo = FakeAdoptionRepository(pets: [fixturePet()]);
    await pumpPushed(
      tester,
      AdoptionRequestScreen(pet: repo.pets.first, repository: repo),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Sami Ben Ali');
    await tester.enterText(find.byType(TextFormField).at(1), '22 345 678');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      '12 rue des Jasmins, Tunis',
    );
    await tester.enterText(
      find.byType(TextFormField).at(3),
      'J\'ai gardé plusieurs chats pendant cinq ans.',
    );
    await tester.enterText(
      find.byType(TextFormField).at(4),
      'Je souhaite offrir un foyer calme et beaucoup d\'attention à Milo.',
    );

    await tester.tap(find.text('Envoyer ma demande'));
    await tester.pumpAndSettle();

    expect(repo.sent, hasLength(1));
    expect(repo.sent.first.fullName, 'Sami Ben Ali');
    expect(repo.sent.first.housingType, HousingType.apartment);
    expect(repo.sent.first.aiScore, isNull);
    expect(find.textContaining('a bien été envoyée'), findsOneWidget);
  });

  testWidgets('mes annonces permet de publier un brouillon', (tester) async {
    final repo = FakeAdoptionRepository(
      pets: [fixturePet(status: AdoptionListingStatus.draft)],
    );
    await tester.pumpWidget(app(MyAdoptionListingsScreen(repository: repo)));
    await tester.pumpAndSettle();

    expect(find.text('Brouillon'), findsOneWidget);
    await tester.tap(find.text('Publier').first);
    await tester.pumpAndSettle();

    expect(repo.pets.first.status, AdoptionListingStatus.published);
    expect(find.text('Annonce publiée.'), findsOneWidget);
  });

  testWidgets('le formulaire de création valide et enregistre', (tester) async {
    final repo = FakeAdoptionRepository();
    await pumpPushed(tester, AdoptionListingFormScreen(repository: repo));

    await tester.tap(find.text('Publier l\'annonce'));
    await tester.pumpAndSettle();
    expect(find.text('Indiquez le nom de l\'animal.'), findsOneWidget);
    expect(find.text('Indiquez la localisation.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Nala');
    await tester.enterText(find.byType(TextFormField).at(3), 'La Marsa, Tunis');
    await tester.enterText(
      find.byType(TextFormField).at(4),
      'Nala décrite avec assez de détails.',
    );

    await tester.tap(find.text('Publier l\'annonce'));
    await tester.pumpAndSettle();

    expect(repo.createdDraft, isNotNull);
    expect(repo.createdDraft!.petName, 'Nala');
    expect(find.text('Annonce publiée.'), findsOneWidget);
  });

  testWidgets('la liste vide propose de publier une annonce', (tester) async {
    final repo = FakeAdoptionRepository();
    await tester.pumpWidget(app(AdoptionListScreen(repository: repo)));
    await tester.pumpAndSettle();

    expect(find.text('Aucun animal trouvé'), findsOneWidget);
    expect(find.text('Publier une annonce'), findsOneWidget);
  });

  testWidgets('la liste tient sur un écran de 320 px', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = FakeAdoptionRepository(pets: [fixturePet()]);
    await tester.pumpWidget(app(AdoptionListScreen(repository: repo)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
