/// ViewModels du module Adoption : état d'écran et logique légère.
///
/// Les ViewModels appellent [AdoptionRepository]. Ils ne connaissent ni HTTP
/// ni widget, conformément au socle MVVM du projet.
library;

import 'dart:async';

import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/models/species.dart';

import 'adoption_models.dart';
import 'adoption_repository.dart';
import 'api/api_client.dart';

String adoptionErrorMessage(Object error) => error is ApiException
    ? error.message
    : 'Une erreur inattendue est survenue. Réessayez.';

class AdoptionListViewModel extends ViewModel {
  AdoptionListViewModel(this._repository, {this.forceEmpty = false}) {
    load();
  }

  final AdoptionRepository _repository;
  final bool forceEmpty;

  List<AdoptionPet> _pets = const [];
  bool _loading = true;
  String? _error;
  bool _refreshing = false;
  String _query = '';
  Species? _species;

  bool get loading => _loading;
  bool get refreshing => _refreshing;
  String? get error => _error;
  String get query => _query;
  Species? get species => _species;
  int get total => _pets.length;
  bool get hasFilters => _query.trim().isNotEmpty || _species != null;

  List<AdoptionPet> get results {
    if (forceEmpty) return const [];
    final q = _query.trim().toLowerCase();
    return _pets.where((pet) {
      final sameSpecies = _species == null || pet.species == _species;
      if (!sameSpecies) return false;
      if (q.isEmpty) return true;
      final haystack = '${pet.name} ${pet.breed} ${pet.city} ${pet.area}'
          .toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      _refreshing = true;
    } else {
      _loading = true;
    }
    _error = null;
    notify();
    try {
      _pets = await _repository.listings(species: _species);
    } catch (error) {
      _error = adoptionErrorMessage(error);
    } finally {
      _loading = false;
      _refreshing = false;
      notify();
    }
  }

  void setQuery(String value) {
    _query = value;
    notify();
  }

  void setSpecies(Species? value) {
    _species = value;
    notify();
    load();
  }

  void clearFilters() {
    _query = '';
    _species = null;
    notify();
  }
}

class AdoptionDetailsViewModel extends ViewModel {
  AdoptionDetailsViewModel(
    this._repository,
    this.listingId, {
    AdoptionPet? initial,
  }) : _pet = initial {
    load();
  }

  final AdoptionRepository _repository;
  final String listingId;

  AdoptionPet? _pet;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  AdoptionPet? get pet => _pet;
  bool get loading => _loading;
  bool get busy => _busy;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notify();
    try {
      _pet = await _repository.listing(listingId);
    } catch (error) {
      _error = adoptionErrorMessage(error);
    } finally {
      _loading = false;
      notify();
    }
  }

  Future<bool> publish() => _apply(() => _repository.publish(listingId));

  Future<bool> pause() => _apply(() => _repository.pause(listingId));

  Future<bool> archive() => _apply(() => _repository.archive(listingId));

  Future<bool> adminHide() => _apply(() => _repository.adminHide(listingId));

  Future<bool> adminArchive() =>
      _apply(() => _repository.adminArchive(listingId));

  Future<bool> _apply(Future<AdoptionPet> Function() action) async {
    if (_busy) return false;
    _busy = true;
    _error = null;
    notify();
    try {
      _pet = await action();
      return true;
    } catch (error) {
      _error = adoptionErrorMessage(error);
      return false;
    } finally {
      _busy = false;
      notify();
    }
  }
}

class AdoptionRequestFormViewModel extends ViewModel {
  AdoptionRequestFormViewModel(this._repository);

  final AdoptionRepository _repository;

  bool _sending = false;
  String? _error;

  AdoptionAiAdvice? _advice;
  bool _adviceLoading = false;
  bool _adviceUnavailable = false;
  Timer? _adviceTimer;

  bool get sending => _sending;
  String? get error => _error;
  AdoptionAiAdvice? get advice => _advice;
  bool get adviceLoading => _adviceLoading;
  bool get adviceUnavailable => _adviceUnavailable;

  void scheduleAdvice({
    required String listingId,
    required HousingType housingType,
    required bool hasGarden,
    required bool hasOtherPets,
    String? otherPetsDetails,
    String? experience,
    String? motivation,
  }) {
    final ready = (experience ?? '').trim().length >= 20 ||
        (motivation ?? '').trim().length >= 20;
    if (!ready) {
      _adviceTimer?.cancel();
      _advice = null;
      _adviceLoading = false;
      _adviceUnavailable = false;
      notify();
      return;
    }

    _adviceTimer?.cancel();
    _adviceLoading = true;
    _adviceUnavailable = false;
    notify();

    _adviceTimer = Timer(const Duration(milliseconds: 600), () async {
      try {
        final result = await _repository.matchingAdvice(
          listingId: listingId,
          housingType: housingType,
          hasGarden: hasGarden,
          hasOtherPets: hasOtherPets,
          otherPetsDetails: otherPetsDetails,
          experience: experience,
          motivation: motivation,
        );
        if (_adviceTimer == null) return;
        _advice = result;
        _adviceUnavailable = false;
      } on ApiException {
        _advice = null;
        _adviceUnavailable = true;
      } catch (_) {
        _advice = null;
        _adviceUnavailable = true;
      } finally {
        _adviceLoading = false;
        notify();
      }
    });
  }

  Future<bool> send({
    required AdoptionPet pet,
    required String fullName,
    required String phone,
    required String address,
    required String experience,
    required String motivation,
    required HousingType housingType,
    required bool hasGarden,
    required bool hasOtherPets,
    String? otherPetsDetails,
  }) async {
    if (_sending) return false;
    _sending = true;
    _error = null;
    notify();
    try {
      await _repository.sendRequest(
        listingId: pet.id,
        fullName: fullName,
        phone: phone,
        address: address,
        message: motivation,
        experience: experience,
        housingType: housingType,
        hasGarden: hasGarden,
        hasOtherPets: hasOtherPets,
        otherPetsDetails: otherPetsDetails,
        aiScore: null,
      );
      return true;
    } catch (error) {
      _error = adoptionErrorMessage(error);
      return false;
    } finally {
      _sending = false;
      notify();
    }
  }

  @override
  void dispose() {
    _adviceTimer?.cancel();
    _adviceTimer = null;
    super.dispose();
  }
}

enum AdoptionRequestsScope { sent, received }

class AdoptionRequestsViewModel extends ViewModel {
  AdoptionRequestsViewModel(
    this._repository,
    this.scope, {
    this.forceEmpty = false,
  }) {
    load();
  }

  final AdoptionRepository _repository;
  final AdoptionRequestsScope scope;
  final bool forceEmpty;

  List<AdoptionRequest> _requests = const [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  List<AdoptionRequest> get requests => forceEmpty ? const [] : _requests;
  bool get loading => _loading;
  bool get refreshing => _refreshing;
  String? get error => _error;

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      _refreshing = true;
    } else {
      _loading = true;
    }
    _error = null;
    notify();
    try {
      _requests = scope == AdoptionRequestsScope.sent
          ? await _repository.sentRequests()
          : await _repository.receivedRequests();
    } catch (error) {
      _error = adoptionErrorMessage(error);
    } finally {
      _loading = false;
      _refreshing = false;
      notify();
    }
  }
}

class AdoptionRequestDetailsViewModel extends ViewModel {
  AdoptionRequestDetailsViewModel(this._repository, this.requestId) {
    load();
  }

  final AdoptionRepository _repository;
  final String requestId;

  AdoptionRequest? _request;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  AdoptionRequest? get request => _request;
  bool get loading => _loading;
  bool get busy => _busy;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notify();
    try {
      _request = await _repository.request(requestId);
    } catch (error) {
      _error = adoptionErrorMessage(error);
    } finally {
      _loading = false;
      notify();
    }
  }

  Future<bool> accept({String? message}) =>
      _apply(() => _repository.acceptRequest(requestId, message: message));

  Future<bool> reject({String? message}) =>
      _apply(() => _repository.rejectRequest(requestId, message: message));

  Future<bool> cancel({String? message}) =>
      _apply(() => _repository.cancelRequest(requestId, message: message));

  Future<bool> _apply(Future<AdoptionRequest> Function() action) async {
    if (_busy) return false;
    _busy = true;
    _error = null;
    notify();
    try {
      _request = await action();
      return true;
    } catch (error) {
      _error = adoptionErrorMessage(error);
      return false;
    } finally {
      _busy = false;
      notify();
    }
  }
}

class MyAdoptionListingsViewModel extends ViewModel {
  MyAdoptionListingsViewModel(this._repository) {
    load();
  }

  final AdoptionRepository _repository;

  List<AdoptionPet> _listings = const [];
  bool _loading = true;
  bool _refreshing = false;
  bool _busy = false;
  String? _error;

  List<AdoptionPet> get listings => _listings;
  bool get loading => _loading;
  bool get refreshing => _refreshing;
  bool get busy => _busy;
  String? get error => _error;

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      _refreshing = true;
    } else {
      _loading = true;
    }
    _error = null;
    notify();
    try {
      _listings = await _repository.mine();
    } catch (error) {
      _error = adoptionErrorMessage(error);
    } finally {
      _loading = false;
      _refreshing = false;
      notify();
    }
  }

  Future<bool> publish(String id) =>
      _apply(id, (listing) => _repository.publish(listing));

  Future<bool> pause(String id) =>
      _apply(id, (listing) => _repository.pause(listing));

  Future<bool> archive(String id) =>
      _apply(id, (listing) => _repository.archive(listing));

  Future<bool> _apply(
    String id,
    Future<AdoptionPet> Function(String id) action,
  ) async {
    if (_busy) return false;
    _busy = true;
    _error = null;
    notify();
    try {
      final updated = await action(id);
      _listings = [
        for (final listing in _listings)
          if (listing.id == id) updated else listing,
      ];
      return true;
    } catch (error) {
      _error = adoptionErrorMessage(error);
      return false;
    } finally {
      _busy = false;
      notify();
    }
  }
}

class AdminAdoptionViewModel extends ViewModel {
  AdminAdoptionViewModel(this._repository) {
    load();
  }

  final AdoptionRepository _repository;

  List<AdoptionPet> _listings = const [];
  bool _loading = true;
  bool _refreshing = false;
  bool _busy = false;
  String? _error;

  List<AdoptionPet> get listings => _listings;
  bool get loading => _loading;
  bool get refreshing => _refreshing;
  bool get busy => _busy;
  String? get error => _error;

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      _refreshing = true;
    } else {
      _loading = true;
    }
    _error = null;
    notify();
    try {
      _listings = await _repository.adminListings();
    } catch (error) {
      _error = adoptionErrorMessage(error);
    } finally {
      _loading = false;
      _refreshing = false;
      notify();
    }
  }

  Future<bool> hide(String id) =>
      _apply(id, (listing) => _repository.adminHide(listing));

  Future<bool> archive(String id) =>
      _apply(id, (listing) => _repository.adminArchive(listing));

  Future<bool> _apply(
    String id,
    Future<AdoptionPet> Function(String id) action,
  ) async {
    if (_busy) return false;
    _busy = true;
    _error = null;
    notify();
    try {
      final updated = await action(id);
      _listings = [
        for (final listing in _listings)
          if (listing.id == id) updated else listing,
      ];
      return true;
    } catch (error) {
      _error = adoptionErrorMessage(error);
      return false;
    } finally {
      _busy = false;
      notify();
    }
  }
}

class CreateListingViewModel extends ViewModel {
  CreateListingViewModel(this._repository);

  final AdoptionRepository _repository;

  bool _saving = false;
  String? _error;

  bool get saving => _saving;
  String? get error => _error;

  Future<AdoptionPet?> save(
    AdoptionDraft draft, {
    String? listingId,
    bool asDraft = false,
  }) async {
    if (_saving) return null;
    _saving = true;
    _error = null;
    notify();
    try {
      return listingId == null
          ? await _repository.create(draft, asDraft: asDraft)
          : await _repository.update(listingId, draft);
    } catch (error) {
      _error = adoptionErrorMessage(error);
      return null;
    } finally {
      _saving = false;
      notify();
    }
  }
}

/// Estimation locale et simulée : aucun appel réseau, aucun modèle externe.
class AdoptionAiAdvisor {
  AdoptionAiAdvisor._();

  static AdoptionAiAdvice evaluate({
    required AdoptionPet pet,
    required String fullName,
    required String phone,
    required String address,
    required String experience,
    required String motivation,
  }) {
    final name = fullName.trim();
    final phoneDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final exp = experience.trim();
    final mot = motivation.trim();
    final text = '${exp.toLowerCase()} ${mot.toLowerCase()}';

    var score = 42;
    if (name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).length >=
        2) {
      score += 6;
    }
    if (phoneDigits.length >= 8) score += 8;
    if (address.trim().length >= 5) score += 5;
    if (exp.length >= 50) score += 12;
    if (mot.length >= 80) score += 15;

    const keywords = [
      'appartement',
      'maison',
      'jardin',
      'famille',
      'enfant',
      'temps',
      'présence',
      'expérience',
      'soins',
      'vétérinaire',
      'promenade',
      'adopter',
      'compagnon',
      'vacances',
    ];
    var hits = 0;
    for (final keyword in keywords) {
      if (text.contains(keyword)) hits++;
    }
    score += (hits.clamp(0, 5) * 3);
    score = score.clamp(45, 98).toInt();

    final summary = switch (score) {
      >= 85 =>
        'Très bon match : votre foyer semble réunir les conditions pour accueillir ${pet.name} sereinement.',
      >= 70 =>
        'Bon potentiel : votre profil correspond à ${pet.name}, avec quelques points à préciser.',
      >= 55 =>
        'Profil à compléter : les bases sont là, mais la famille de ${pet.name} aura besoin de plus de détails.',
      _ =>
        'Encore trop d\'informations manquent pour estimer la compatibilité avec ${pet.name}.',
    };

    final tips = <String>[];
    if (exp.length < 50) {
      tips.add(
        'Détaillez votre expérience avec les ${pet.species.plural.toLowerCase()} et les soins du quotidien.',
      );
    }
    if (mot.length < 80) {
      tips.add(
        'Expliquez plus précisément votre quotidien et le temps que vous pourrez consacrer à ${pet.name}.',
      );
    }
    if (!text.contains('jardin') &&
        !text.contains('appartement') &&
        !text.contains('maison')) {
      tips.add('Précisez votre logement et l\'espace prévu pour l\'animal.');
    }
    if (!text.contains('vacances')) {
      tips.add(
        'Indiquez qui s\'occupera de ${pet.name} pendant vos absences ou vos vacances.',
      );
    }
    if (pet.species == Species.chien && !text.contains('promenade')) {
      tips.add(
        'Précisez la fréquence et la durée des promenades quotidiennes.',
      );
    }
    if (pet.species == Species.chat && !text.contains('intérieur')) {
      tips.add(
        'Précisez si ${pet.name} vivra à l\'intérieur et si les fenêtres sont sécurisées.',
      );
    }
    if (pet.species == Species.lapin && !text.contains('foin')) {
      tips.add(
        'Mentionnez l\'espace prévu, l\'accès au foin et la litière choisie.',
      );
    }
    if (tips.isEmpty) {
      tips.add(
        'Votre demande est complète : ajoutez une photo de votre logement si vous le souhaitez.',
      );
    }
    if (tips.length < 3) {
      tips.add(
        'Préparez les questions à poser à la famille d\'accueil avant la rencontre.',
      );
    }
    if (tips.length < 3) {
      tips.add(
        'Prévoyez une visite de rencontre avant de finaliser l\'adoption.',
      );
    }

    return AdoptionAiAdvice(
      score: score,
      summary: summary,
      tips: tips.take(3).toList(),
    );
  }
}
