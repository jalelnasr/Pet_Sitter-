import 'package:flutter/material.dart';

import 'package:pet_sitter/app/dependencies.dart';
import 'package:pet_sitter/app/routes.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';
import 'package:pet_sitter/core/widgets/common.dart';
import 'package:pet_sitter/core/widgets/member_avatar.dart';
import 'package:pet_sitter/view_models/profile_view_model.dart';
import 'package:pet_sitter/views/auth/auth_widgets.dart';

/// Invitation à se connecter, affichée par les écrans de compte ouverts sans session.
class _SignInRequired extends StatelessWidget {
  const _SignInRequired({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: const BackButton(), title: Text(title)),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(PhosphorIconsRegular.lockSimple, size: 44, color: LP.primary),
          const SizedBox(height: 14),
          Text('Connectez-vous pour gérer votre compte.', style: LPText.h3, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          PawButton(label: 'Se connecter', onPressed: () => Navigator.pushNamed(context, R.login)),
        ],
      ),
    ),
  );
}

// ————————————————————————————————————————————— MODIFIER MON PROFIL

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final vm = EditProfileViewModel(Deps.of(context).auth, Deps.of(context).session);
  final _form = GlobalKey<FormState>();
  late final _first = TextEditingController(text: vm.user?.firstName ?? '');
  late final _last = TextEditingController(text: vm.user?.lastName ?? '');
  late final _phone = TextEditingController(text: vm.user?.phone ?? '');
  late final _city = TextEditingController(text: vm.user?.city ?? '');
  late final _bio = TextEditingController(text: vm.user?.bio ?? '');

  @override
  void dispose() {
    vm.dispose();
    for (final c in [_first, _last, _phone, _city, _bio]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final ok = await vm.save(
      firstName: _first.text,
      lastName: _last.text,
      phone: _phone.text,
      city: _city.text,
      bio: _bio.text,
    );
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil enregistré.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!vm.canEdit) return const _SignInRequired(title: 'Mon profil');
    return ListenableBuilder(listenable: vm, builder: (context, _) => _content(context));
  }

  Widget _content(BuildContext context) {
    final user = vm.user!;
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Mon profil')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Center(child: MemberAvatar(photo: user.photoUrl ?? '', name: user.fullName, size: 88)),
            const SizedBox(height: 8),
            Center(child: Text(user.email, style: LPText.bodyS)),
            const SizedBox(height: 22),
            if (vm.error != null) ...[
              InfoNote(vm.error!, icon: PhosphorIconsRegular.warningCircle, tone: InfoTone.error),
              const SizedBox(height: 14),
            ],
            TextFormField(
              controller: _first,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Prénom',
                prefixIcon: const Icon(PhosphorIconsRegular.user, size: 20),
                errorText: vm.fieldError('firstName'),
              ),
              validator: EditProfileViewModel.validateFirstName,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _last,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nom', prefixIcon: Icon(PhosphorIconsRegular.user, size: 20)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Téléphone',
                hintText: '+216 22 333 444',
                prefixIcon: const Icon(PhosphorIconsRegular.phone, size: 20),
                errorText: vm.fieldError('phone'),
              ),
              validator: EditProfileViewModel.validatePhone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _city,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Ville',
                hintText: 'Ex. : La Marsa',
                prefixIcon: Icon(PhosphorIconsRegular.mapPin, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bio,
              minLines: 3,
              maxLines: 6,
              maxLength: 600,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Présentation',
                hintText: 'Quelques mots sur vous et vos animaux',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            PawButton(label: 'Enregistrer', loading: vm.saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

// ————————————————————————————————————————————— CHANGER LE MOT DE PASSE

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late final vm = ChangePasswordViewModel(Deps.of(context).auth);
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    vm.dispose();
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final ok = await vm.submit(current: _current.text, next: _next.text);
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mot de passe modifié. Vos autres appareils sont déconnectés.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!Deps.of(context).session.isAuthenticated) return const _SignInRequired(title: 'Mot de passe');
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => Scaffold(
        appBar: AppBar(leading: const BackButton(), title: const Text('Mot de passe')),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              if (vm.error != null) ...[
                InfoNote(vm.error!, icon: PhosphorIconsRegular.warningCircle, tone: InfoTone.error),
                const SizedBox(height: 14),
              ],
              PasswordField(
                controller: _current,
                label: 'Mot de passe actuel',
                validator: (v) => (v == null || v.isEmpty) ? 'Saisissez votre mot de passe actuel.' : null,
              ),
              const SizedBox(height: 12),
              PasswordField(
                controller: _next,
                label: 'Nouveau mot de passe',
                hint: '8 caractères minimum, dont un chiffre',
                showStrength: true,
                validator: ChangePasswordViewModel.validateNew,
              ),
              const SizedBox(height: 12),
              PasswordField(
                controller: _confirm,
                label: 'Confirmer le nouveau mot de passe',
                validator: ChangePasswordViewModel.validateConfirm(() => _next.text),
              ),
              const SizedBox(height: 18),
              PawButton(label: 'Changer mon mot de passe', loading: vm.saving, onPressed: _submit),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, R.forgot),
                child: const Text('Mot de passe actuel oublié ?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
