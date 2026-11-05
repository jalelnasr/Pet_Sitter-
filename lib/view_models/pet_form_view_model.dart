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

  final Map<String, Object> _answers = {};

  bool _saving = false;
  bool get saving => _saving;

  /// Nom proposé selon l'espèce (exemple de démonstration).
  String get suggestedName => switch (_species) {
    Species.chat => 'Simba',
    Species.chien => 'Rocky',
    Species.poisson => 'Bulle',
    _ => '',
  };

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

  Set<String> choiceOf(ChoiceQ q) => (_answers[_key(q)] as Set<String>?) ?? q.initial;
  bool toggleOf(ToggleQ q) => (_answers[_key(q)] as bool?) ?? q.initial;
  int counterOf(CounterQ q) => (_answers[_key(q)] as int?) ?? q.initial;

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

  Future<void> save(String name) async {
    _saving = true;
    notify();
    await _pets.savePet({'name': name, 'species': _species.name, 'sex': _sex, ..._answers});
    _saving = false;
    notify();
  }
}
