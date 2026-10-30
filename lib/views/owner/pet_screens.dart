import 'package:flutter/material.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';

import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/app/routes.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/widgets/common.dart';
import 'package:pet_sitter/app/dependencies.dart';
import 'package:pet_sitter/view_models/pet_form_view_model.dart';
import 'package:pet_sitter/view_models/account_view_model.dart';
import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/views/auth/auth_widgets.dart';

// ————————————————————————————————————————————— AJOUT D'UN ANIMAL

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key, this.firstTime = false, this.initial = Species.chat});
  final bool firstTime;
  final Species initial;

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  late final vm = PetFormViewModel(Deps.of(context).pets, initial: widget.initial, firstTime: widget.firstTime);

  late final _name = TextEditingController(text: vm.suggestedName);

  @override
  void dispose() {
    vm.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await vm.save(_name.text);
    if (!mounted) return;
    if (vm.firstTime) {
      Navigator.pushNamedAndRemoveUntil(context, R.owner, (r) => r.settings.name == R.catalog);
    } else {
      Navigator.pop(context);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profil de ${_name.text.isEmpty ? 'votre animal' : _name.text} enregistré.')),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: vm, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(vm.firstTime ? 'Étape 2 sur 2' : 'Ajouter un animal', style: LPText.label),
        centerTitle: true,
        actions: [
          if (vm.firstTime)
            TextButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, R.owner, (r) => r.settings.name == R.catalog),
              child: const Text('Plus tard'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Présentez-nous votre compagnon', style: LPText.h2),
                const SizedBox(height: 8),
                Text('Ces informations sont partagées avec le sitter à chaque demande de garde.', style: LPText.bodyS),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: LP.soft,
                        shape: BoxShape.circle,
                        border: Border.all(color: LP.softDeep, width: 1.5),
                      ),
                      child: Icon(vm.species.icon, size: 36, color: LP.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                            onPressed: () {},
                            icon: const Icon(PhosphorIconsRegular.camera, size: 19),
                            label: const Text('Ajouter une photo'),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Une photo nette aide le sitter à le reconnaître.',
                            style: LPText.bodyS.copyWith(fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Text('Quel animal ?', style: LPText.label),
                const SizedBox(height: 12),
              ],
            ),
          ),
          SpeciesPicker(selected: {vm.species}, onChanged: vm.setSpecies),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FieldLabel('Son nom'),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Ex. : Simba, Kiwi, Noisette'),
                ),
                const SizedBox(height: 18),
                const FieldLabel('Âge'),
                Row(
                  children: [
                    const SizedBox(
                      width: 110,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(hintText: '4'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceGroup(options: const ['ans', 'mois'], selected: {vm.ageUnit}, onTap: vm.setAgeUnit),
                    ),
                  ],
                ),
                if (vm.asksSex) ...[
                  const SizedBox(height: 18),
                  const FieldLabel('Sexe'),
                  ChoiceGroup(
                    options: const ['Mâle', 'Femelle', 'Je ne sais pas'],
                    selected: {?vm.sex},
                    onTap: vm.setSex,
                  ),
                ],
                const SizedBox(height: 22),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: InfoNote(
                    vm.adaptNote,
                    key: ValueKey(vm.species),
                    icon: PhosphorIconsRegular.sparkle,
                    tone: InfoTone.apricot,
                  ),
                ),
              ],
            ),
          ),
          for (final (title, icon, fields) in vm.sections) ...[
            const SizedBox(height: 28),
            Padding(
              padding: LP.pagePadding,
              child: Row(
                children: [
                  Icon(icon, size: 22, color: LP.primary),
                  const SizedBox(width: 10),
                  Text(title, style: LPText.h3),
                ],
              ),
            ),
            const SizedBox(height: 6),
            for (final f in fields) Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 0), child: _buildField(f)),
          ],
          const SizedBox(height: 28),
          Padding(
            padding: LP.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(PhosphorIconsRegular.firstAidKit, size: 22, color: LP.primary),
                    const SizedBox(width: 10),
                    Text('Soins particuliers', style: LPText.h3),
                  ],
                ),
                const SizedBox(height: 12),
                const TextField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Médicaments, allergies, traitement en cours… Indiquez la dose et l\'horaire.',
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Icon(PhosphorIconsRegular.stethoscope, size: 22, color: LP.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        vm.species == Species.poisson ? 'Contact aquariophile ou vétérinaire' : 'Vétérinaire',
                        style: LPText.h3,
                      ),
                    ),
                    Text('facultatif', style: LPText.bodyS),
                  ],
                ),
                const SizedBox(height: 12),
                const TextField(
                  decoration: InputDecoration(
                    hintText: 'Nom ou clinique',
                    prefixIcon: Icon(PhosphorIconsRegular.firstAid, size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                const TextField(
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Téléphone · ex. 71 000 000',
                    prefixIcon: Icon(PhosphorIconsRegular.phone, size: 20),
                  ),
                ),
                const SizedBox(height: 32),
                LoadingButton(label: 'Enregistrer le profil', loading: vm.saving, onPressed: _save),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(PetField f) {
    switch (f) {
      case TextQ(:final hint):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FieldLabel(f.label),
            TextField(decoration: InputDecoration(hintText: hint)),
          ],
        );
      case ChoiceQ(:final options):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FieldLabel(f.label),
            ChoiceGroup(options: options, selected: vm.choiceOf(f), onTap: (v) => vm.tapChoice(f, v)),
          ],
        );
      case ToggleQ(:final sub):
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.label, style: LPText.label),
                  if (sub != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(sub, style: LPText.bodyS),
                    ),
                ],
              ),
            ),
            Switch(value: vm.toggleOf(f), onChanged: (v) => vm.setToggle(f, v)),
          ],
        );
      case CounterQ(:final max):
        return Row(
          children: [
            Expanded(child: Text(f.label, style: LPText.label)),
            Counter(value: vm.counterOf(f), max: max, onChanged: (v) => vm.setCounter(f, v)),
          ],
        );
    }
  }
}

// ————————————————————————————————————————————— PROFIL DE L'ANIMAL

class PetProfileScreen extends StatelessWidget {
  const PetProfileScreen({super.key, required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final facts = [pet.breed, pet.age, if (pet.sex != '—') pet.sex];
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 330,
            pinned: true,
            backgroundColor: LP.bg,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: RoundIconButton(
                PhosphorIconsRegular.arrowLeft,
                onTap: () => Navigator.maybePop(context),
                tooltip: 'Retour',
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: RoundIconButton(
                  PhosphorIconsRegular.pencilSimple,
                  tooltip: 'Modifier',
                  onTap: () => Navigator.pushNamed(context, R.addPet, arguments: pet.species),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: LPImage(pet.photo, radius: 0, width: double.infinity, height: double.infinity),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [Pill(label: pet.species.label, icon: pet.species.icon, bg: LP.mintPale, fg: LP.primary)],
                  ),
                  const SizedBox(height: 12),
                  Text(pet.name, style: LPText.h1.copyWith(fontSize: 36)),
                  const SizedBox(height: 6),
                  Text(facts.join(' · '), style: LPText.bodyL.copyWith(color: LP.muted)),
                  const SizedBox(height: 18),
                  const InfoNote(
                    'Ce profil est joint automatiquement à vos demandes de garde.',
                    icon: PhosphorIconsRegular.shareNetwork,
                  ),
                  _block('Alimentation', PhosphorIconsRegular.bowlFood, pet.food),
                  _block(
                    pet.species == Species.poisson ? 'Aquarium' : 'Habitudes',
                    pet.species == Species.poisson ? PhosphorIconsRegular.waves : PhosphorIconsRegular.houseLine,
                    pet.habits,
                  ),
                  if (pet.behavior.isNotEmpty) ...[
                    _title('Comportement', PhosphorIconsRegular.smiley),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [for (final b in pet.behavior) Pill(label: b, bg: LP.soft, fg: LP.ink)],
                    ),
                  ],
                  _title('Soins particuliers', PhosphorIconsRegular.firstAidKit),
                  Text(pet.care, style: LPText.bodyL),
                  _title(
                    pet.species == Species.poisson ? 'Contact aquariophile' : 'Vétérinaire',
                    PhosphorIconsRegular.stethoscope,
                  ),
                  if (pet.vet != null)
                    Row(
                      children: [
                        Expanded(child: Text(pet.vet!, style: LPText.bodyL)),
                        RoundIconButton(PhosphorIconsRegular.phone, tooltip: 'Appeler', fg: LP.primary),
                      ],
                    )
                  else
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () {},
                      icon: const Icon(PhosphorIconsRegular.plus, size: 18),
                      label: const Text('Ajouter un contact (facultatif)'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(String t, IconData i) => Padding(
    padding: const EdgeInsets.only(top: 30, bottom: 12),
    child: Row(
      children: [
        Icon(i, size: 22, color: LP.primary),
        const SizedBox(width: 10),
        Text(t, style: LPText.h3),
      ],
    ),
  );

  Widget _block(String title, IconData icon, Map<String, String> data) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _title(title, icon),
      for (final e in data.entries) ...[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 118, child: Text(e.key, style: LPText.bodyS)),
              Expanded(
                child: Text(e.value, style: LPText.bodyM.copyWith(fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
        if (e.key != data.keys.last) const Divider(),
      ],
    ],
  );
}

// ————————————————————————————————————————————— MES ANIMAUX

class MyPetsScreen extends StatelessWidget {
  const MyPetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AccountViewModel>(
      create: (context) => AccountViewModel(Deps.of(context).pets, Deps.of(context).sitters),
      builder: (context, vm) => _content(context, vm),
    );
  }

  Widget _content(BuildContext context, AccountViewModel vm) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes animaux')),
      body: ListView(
        children: [
          for (final p in vm.pets) ...[
            InkWell(
              onTap: () => Navigator.pushNamed(context, R.pet, arguments: p),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    LPAvatar(p.photo, size: 64),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: LPText.title),
                          Text('${p.species.label} · ${p.breed}', style: LPText.bodyS),
                          Text(p.age, style: LPText.bodyS),
                        ],
                      ),
                    ),
                    const Icon(PhosphorIconsRegular.caretRight, size: 18, color: LP.muted),
                  ],
                ),
              ),
            ),
            const Divider(indent: 100),
          ],
          Padding(
            padding: const EdgeInsets.all(20),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, R.addPet),
              icon: const Icon(PhosphorIconsRegular.plus, size: 20),
              label: const Text('Ajouter un animal'),
            ),
          ),
        ],
      ),
    );
  }
}
