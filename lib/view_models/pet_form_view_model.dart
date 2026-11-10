import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/data/repositories/pet_repository.dart';
import 'package:pet_sitter/models/models.dart';

/// Formulaire « Ajouter un animal » : les questions s'adaptent à l'espèce choisie.
class PetFormViewModel extends ViewModel {
  PetFormViewModel(this._pets, {Species initial = Species.chat, this.firstTime = false}) : _species = initial;

  final PetRepository _pets;

  /// Vrai juste après l'inscription (étape 2 sur 2).
  final bool firstTime;

  Species _species;
  Species get species => _species;

  /// Sections et questions propres à l'espèce (voir models/pet_form.dart).
  List<PetSection> get sections => sectionsFor(_species);
  String get adaptNote => adaptNoteFor(_species);
  bool get asksSex => _species != Species.poisson;

  String _ageUnit = 'ans';
  String get ageUnit => _ageUnit;

  String? _sex = 'Mâle';
  String? get sex => _sex;

  /// Photo choisie dans la galerie (data:image/…;base64,…), vide sans photo.
  String _photo = '';
  String get photo => _photo;

  void setPhoto(String dataUri) {
    _photo = dataUri;
    notify();
  }

  // Champs libres : âge, soins, vétérinaire.
  String age = '';
  String care = '';
  String vetName = '';
  String vetPhone = '';

  final Map<String, Object> _answers = {};

  bool _saving = false;
  bool get saving => _saving;

  String? _error;
  String? get error => _error;

  String _key(PetField f) => '${_species.name}.${f.label}';

  void setSpecies(Species s) {
    _species = s;
    notify();
  }

  void setAgeUnit(String u) {
    _ageUnit = u;
    notify();
  }

  void setSex(String s) {
    _sex = s;
    notify();
  }

  // ———— Réponses (valeur par défaut = valeur initiale de la question)

  String textOf(TextQ q) => (_answers[_key(q)] as String?) ?? '';
  Set<String> choiceOf(ChoiceQ q) => (_answers[_key(q)] as Set<String>?) ?? q.initial;
  bool toggleOf(ToggleQ q) => (_answers[_key(q)] as bool?) ?? q.initial;
  int counterOf(CounterQ q) => (_answers[_key(q)] as int?) ?? q.initial;

  void setText(TextQ q, String v) => _answers[_key(q)] = v;

  void tapChoice(ChoiceQ q, String option) {
    final next = {...choiceOf(q)};
    if (q.multi) {
      next.contains(option) ? next.remove(option) : next.add(option);
    } else {
      next
        ..clear()
        ..add(option);
    }
    _answers[_key(q)] = next;
    notify();
  }

  void setToggle(ToggleQ q, bool v) {
    _answers[_key(q)] = v;
    notify();
  }

  void setCounter(CounterQ q, int v) {
    _answers[_key(q)] = v;
    notify();
  }

  /// Réponse lisible d'une question (vide si non renseignée).
  String _display(PetField f) => switch (f) {
    TextQ() => textOf(f).trim(),
    ChoiceQ() => choiceOf(f).join(', '),
    ToggleQ() => toggleOf(f) ? 'Oui' : 'Non',
    CounterQ() => '${counterOf(f)}',
  };

  /// Fiche complète, rangée comme la fiche de l'animal : repas, habitudes, comportement.
  Map<String, Object?> answers(String name) {
    final food = <String, String>{};
    final habits = <String, String>{};
    final behavior = <String>[];
    var breed = '';
    for (final (title, _, fields) in sections) {
      final isFood = title == 'Alimentation' || title == 'Nourriture';
      final isBehavior = title == 'Comportement' || title == 'Manipulation';
      for (final f in fields) {
        final value = _display(f);
        if (value.isEmpty) continue;
        if (f.label == 'Race' || f.label == 'Type d\'oiseau') {
          breed = value;
        } else if (isBehavior && f is ChoiceQ) {
          behavior.addAll(choiceOf(f));
        } else {
          (isFood ? food : habits)[f.label] = value;
        }
      }
    }
    final ageValue = age.trim();
    return {
      'name': name.trim(),
      'species': _species.name,
      'photo': _photo,
      'sex': asksSex && _sex != 'Je ne sais pas' ? _sex : null,
      'age': ageValue.isEmpty ? '' : '$ageValue $_ageUnit',
      'breed': breed,
      'care': care.trim(),
      'vetName': vetName.trim(),
      'vetPhone': vetPhone.trim(),
      'food': food,
      'habits': habits,
      'behavior': behavior,
    };
  }

  /// Enregistre l'animal ; faux (avec [error]) si le nom manque.
  Future<bool> save(String name) async {
    if (name.trim().isEmpty) {
      _error = 'Indiquez le nom de votre animal.';
      notify();
      return false;
    }
    _error = null;
    _saving = true;
    notify();
    await _pets.savePet(answers(name));
    _saving = false;
    notify();
    return true;
  }
}
