/// Adoption : annonces d'animaux, demandes envoyées et demandes reçues.
library;

import 'package:pet_sitter/models/species.dart';

/// Cycle de vie d'une annonce, aligné sur le backend.
enum AdoptionListingStatus {
  draft,
  published,
  paused,
  adopted,
  archived,
  hidden,
}

extension AdoptionListingStatusX on AdoptionListingStatus {
  String get label => switch (this) {
    AdoptionListingStatus.draft => 'Brouillon',
    AdoptionListingStatus.published => 'Publiée',
    AdoptionListingStatus.paused => 'En pause',
    AdoptionListingStatus.adopted => 'Adopté',
    AdoptionListingStatus.archived => 'Archivée',
    AdoptionListingStatus.hidden => 'Masquée',
  };

  String get apiValue => switch (this) {
    AdoptionListingStatus.draft => 'DRAFT',
    AdoptionListingStatus.published => 'PUBLISHED',
    AdoptionListingStatus.paused => 'PAUSED',
    AdoptionListingStatus.adopted => 'ADOPTED',
    AdoptionListingStatus.archived => 'ARCHIVED',
    AdoptionListingStatus.hidden => 'HIDDEN',
  };

  bool get isPublic => this == AdoptionListingStatus.published;

  static AdoptionListingStatus fromApi(String? value) => switch (value) {
    'DRAFT' => AdoptionListingStatus.draft,
    'PAUSED' => AdoptionListingStatus.paused,
    'ADOPTED' => AdoptionListingStatus.adopted,
    'ARCHIVED' => AdoptionListingStatus.archived,
    'HIDDEN' => AdoptionListingStatus.hidden,
    _ => AdoptionListingStatus.published,
  };
}

enum PetGender { male, female, unknown }

extension PetGenderX on PetGender {
  String get label => switch (this) {
    PetGender.male => 'Mâle',
    PetGender.female => 'Femelle',
    PetGender.unknown => 'Inconnu',
  };

  String get apiValue => switch (this) {
    PetGender.male => 'MALE',
    PetGender.female => 'FEMALE',
    PetGender.unknown => 'UNKNOWN',
  };

  static PetGender fromApi(String? value) => switch (value) {
    'MALE' => PetGender.male,
    'FEMALE' => PetGender.female,
    _ => PetGender.unknown,
  };
}

enum HousingType { apartment, house, farm, other }

extension HousingTypeX on HousingType {
  String get label => switch (this) {
    HousingType.apartment => 'Appartement',
    HousingType.house => 'Maison',
    HousingType.farm => 'Ferme',
    HousingType.other => 'Autre',
  };

  String get apiValue => switch (this) {
    HousingType.apartment => 'APARTMENT',
    HousingType.house => 'HOUSE',
    HousingType.farm => 'FARM',
    HousingType.other => 'OTHER',
  };

  static HousingType fromApi(String? value) => switch (value) {
    'HOUSE' => HousingType.house,
    'FARM' => HousingType.farm,
    'OTHER' => HousingType.other,
    _ => HousingType.apartment,
  };

  static HousingType fromLabel(String? label) {
    for (final type in HousingType.values) {
      if (type.label == label) return type;
    }
    return HousingType.apartment;
  }
}

/// Annonce d'adoption telle qu'affichée par les écrans existants.
///
/// Les noms de champs historiques (`name`, `age`, `city`, `photo`…) sont
/// conservés pour ne pas modifier la conception des cartes et fiches.
class AdoptionPet {
  const AdoptionPet({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.age,
    required this.sex,
    required this.city,
    required this.area,
    required this.photo,
    required this.description,
    required this.health,
    required this.vaccinated,
    required this.sterilized,
    required this.extra,
    this.status = AdoptionListingStatus.published,
    this.publisherId = '',
    this.publisherName = '',
    this.gender = PetGender.unknown,
    this.imageUrls = const [],
    this.ageYears,
    this.createdAt,
  });

  final String id;
  final String name;
  final Species species;
  final String breed;
  final String age;
  final String sex;
  final String city;
  final String area;
  final String photo;
  final String description;
  final String health;
  final bool vaccinated;
  final bool sterilized;
  final Map<String, String> extra;

  final AdoptionListingStatus status;
  final String publisherId;
  final String publisherName;
  final PetGender gender;
  final List<String> imageUrls;
  final int? ageYears;
  final DateTime? createdAt;

  String get displayLocation => area.trim().isEmpty ? city : '$area, $city';

  bool get isPublished => status == AdoptionListingStatus.published;

  bool isMine(String userId) => publisherId.isNotEmpty && publisherId == userId;

  /// Conversion depuis le JSON du backend (résumé ou fiche complète).
  factory AdoptionPet.fromJson(Map<String, dynamic> json) {
    final publisher = json['publisher'] is Map<String, dynamic>
        ? json['publisher'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final images =
        (json['imageUrls'] as List?)
            ?.whereType<String>()
            .where((url) => url.trim().isNotEmpty)
            .toList() ??
        const <String>[];

    final location = (json['location'] as String?)?.trim() ?? '';
    final parts = location
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    final city = parts.isEmpty ? '' : parts.last;
    final area = parts.length > 1
        ? parts.sublist(0, parts.length - 1).join(', ')
        : '';

    final rawAge = json['age'];
    final ageYears = rawAge is int ? rawAge : int.tryParse('$rawAge');
    final gender = PetGenderX.fromApi(json['gender'] as String?);
    final health = (json['healthInformation'] as String?)?.trim() ?? '';

    return AdoptionPet(
      id: '${json['id'] ?? ''}',
      name: (json['petName'] as String?)?.trim().isNotEmpty == true
          ? (json['petName'] as String).trim()
          : 'Sans nom',
      species: _speciesFromApi(json['species'] as String?),
      breed: (json['breed'] as String?)?.trim().isNotEmpty == true
          ? (json['breed'] as String).trim()
          : 'Race non précisée',
      age: ageYears == null
          ? 'Âge inconnu'
          : '$ageYears an${ageYears > 1 ? 's' : ''}',
      sex: gender.label,
      city: city,
      area: area,
      photo: images.isNotEmpty ? images.first : '',
      description: (json['description'] as String?)?.trim() ?? '',
      health: health.isEmpty ? 'Non précisé' : health,
      vaccinated: json['vaccinated'] == true,
      sterilized: json['sterilized'] == true,
      extra: const {},
      status: AdoptionListingStatusX.fromApi(json['status'] as String?),
      publisherId: '${publisher['id'] ?? ''}',
      publisherName: (publisher['firstName'] as String?) ?? '',
      gender: gender,
      imageUrls: images,
      ageYears: ageYears,
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
    );
  }

  static Species _speciesFromApi(String? value) => switch (value) {
    'DOG' => Species.chien,
    'CAT' => Species.chat,
    'BIRD' => Species.oiseau,
    'RABBIT' => Species.lapin,
    _ => Species.autre,
  };
}

/// Charge utile envoyée lors de la création ou de la modification d'une annonce.
class AdoptionDraft {
  const AdoptionDraft({
    required this.petName,
    required this.species,
    required this.breed,
    required this.age,
    required this.gender,
    required this.description,
    required this.healthInformation,
    required this.vaccinated,
    required this.sterilized,
    required this.location,
    required this.imageUrls,
  });

  final String petName;
  final Species species;
  final String breed;
  final int? age;
  final PetGender gender;
  final String description;
  final String healthInformation;
  final bool vaccinated;
  final bool sterilized;
  final String location;
  final List<String> imageUrls;

  Map<String, dynamic> toCreateJson({bool draft = false}) => {
    ...toUpdateJson(),
    if (draft) 'status': 'DRAFT',
  };

  Map<String, dynamic> toUpdateJson() => {
    'petName': petName.trim(),
    'species': _speciesApiValue(species),
    'breed': breed.trim().isEmpty ? null : breed.trim(),
    'age': age,
    'gender': gender.apiValue,
    'description': description.trim(),
    'healthInformation': healthInformation.trim().isEmpty
        ? null
        : healthInformation.trim(),
    'vaccinated': vaccinated,
    'sterilized': sterilized,
    'location': location.trim(),
    'imageUrls': imageUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList(),
  };

  static String _speciesApiValue(Species species) => switch (species) {
    Species.chien => 'DOG',
    Species.chat => 'CAT',
    Species.oiseau => 'BIRD',
    Species.lapin => 'RABBIT',
    _ => 'OTHER',
  };
}

enum AdoptionStatus { pending, accepted, refused, cancelled }

extension AdoptionStatusX on AdoptionStatus {
  String get label => switch (this) {
    AdoptionStatus.pending => 'En attente',
    AdoptionStatus.accepted => 'Acceptée',
    AdoptionStatus.refused => 'Refusée',
    AdoptionStatus.cancelled => 'Annulée',
  };

  static AdoptionStatus fromApi(String? value) => switch (value) {
    'ACCEPTED' => AdoptionStatus.accepted,
    'REJECTED' => AdoptionStatus.refused,
    'CANCELLED' => AdoptionStatus.cancelled,
    _ => AdoptionStatus.pending,
  };
}

/// Conseil simulé affiché après le remplissage du formulaire.
class AdoptionAiAdvice {
  const AdoptionAiAdvice({
    required this.score,
    required this.summary,
    required this.tips,
  });

  final int score;
  final String summary;
  final List<String> tips;

  factory AdoptionAiAdvice.fromJson(Map<String, dynamic> json) {
    final rawTips = json['tips'];
    return AdoptionAiAdvice(
      score: json['score'] is int
          ? json['score'] as int
          : int.tryParse('${json['score']}') ?? 0,
      summary: (json['summary'] ?? '').toString(),
      tips: rawTips is List
          ? rawTips.map((tip) => tip.toString()).toList(growable: false)
          : const <String>[],
    );
  }
}

class AdoptionRequest {
  const AdoptionRequest({
    required this.id,
    required this.pet,
    required this.fullName,
    required this.phone,
    required this.address,
    required this.experience,
    required this.motivation,
    required this.date,
    required this.status,
    this.applicantId = '',
    this.applicantName = '',
    this.aiScore,
    this.responseMessage,
    this.processedAt,
    this.housingType = HousingType.apartment,
    this.hasGarden = false,
    this.hasOtherPets = false,
    this.otherPetsDetails,
  });

  final String id;
  final AdoptionPet pet;
  final String fullName;
  final String phone;
  final String address;
  final String experience;
  final String motivation;
  final DateTime date;
  final AdoptionStatus status;

  final String applicantId;
  final String applicantName;
  final int? aiScore;
  final String? responseMessage;
  final DateTime? processedAt;
  final HousingType housingType;
  final bool hasGarden;
  final bool hasOtherPets;
  final String? otherPetsDetails;

  bool get isPending => status == AdoptionStatus.pending;

  bool isApplicant(String userId) =>
      applicantId.isNotEmpty && applicantId == userId;

  bool isPublisher(String userId) =>
      pet.publisherId.isNotEmpty && pet.publisherId == userId;

  factory AdoptionRequest.fromJson(Map<String, dynamic> json) {
    final listing = json['listing'] is Map<String, dynamic>
        ? json['listing'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final applicant = json['applicant'] is Map<String, dynamic>
        ? json['applicant'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return AdoptionRequest(
      id: '${json['id'] ?? ''}',
      pet: AdoptionPet.fromJson(listing),
      fullName: (json['fullName'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      experience: (json['experience'] as String?) ?? '',
      motivation: (json['message'] as String?) ?? '',
      date: DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
      status: AdoptionStatusX.fromApi(json['status'] as String?),
      applicantId: '${applicant['id'] ?? ''}',
      applicantName: (applicant['firstName'] as String?) ?? '',
      aiScore: json['aiScore'] is int ? json['aiScore'] as int : null,
      responseMessage: (json['responseMessage'] as String?)?.trim(),
      processedAt: DateTime.tryParse('${json['processedAt'] ?? ''}'),
      housingType: HousingTypeX.fromApi(json['housingType'] as String?),
      hasGarden: json['hasGarden'] == true,
      hasOtherPets: json['hasOtherPets'] == true,
      otherPetsDetails: (json['otherPetsDetails'] as String?)?.trim(),
    );
  }
}
