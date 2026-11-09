import 'package:flutter/material.dart';

import 'package:pet_sitter/core/motion/gsap.dart';
import 'package:pet_sitter/app/routes.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';
import 'package:pet_sitter/core/widgets/big_shapes.dart';
import 'package:pet_sitter/core/widgets/common.dart';
import 'package:pet_sitter/app/dependencies.dart';
import 'package:pet_sitter/models/user.dart';
import 'package:pet_sitter/view_models/auth_view_model.dart';
import 'package:pet_sitter/views/auth/auth_widgets.dart';

// ————————————————————————————————————————————— Gabarit commun

/// En-tête crème avec le logo et une grande empreinte jaune, puis un panneau blanc qui monte.
class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Scaffold(
      backgroundColor: LP.cream,
      body: GsapTimeline(
        duration: 1.2,
        child: Stack(
          children: [
            // grande empreinte jaune qui dépasse en haut à droite
            Positioned(
              right: -46,
              top: -24,
              width: 190,
              height: 190,
              child: Tl(
                duration: 0.9,
                vars: const GsapVars(scale: 0.4, rotation: -30, opacity: 0),
                ease: Ease.backOutSoft,
                child: Transform.rotate(
                  angle: 0.42,
                  child: CustomPaint(
                    painter: BigShapePainter(BigShape.paw, color: LP.brandYellow, cutout: LP.cream),
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              // Le panneau blanc remplit toujours l'espace restant jusqu'en bas.
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 52,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: canPop
                                ? Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: RoundIconButton(
                                      PhosphorIconsRegular.caretLeft,
                                      bg: LP.white,
                                      tooltip: 'Retour',
                                      onTap: () => Navigator.maybePop(context),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const Tl(
                          at: 0.1,
                          duration: 0.8,
                          vars: GsapVars(scale: 0.7, y: 20, opacity: 0),
                          ease: Ease.backOutSoft,
                          child: Center(child: BrandLogo(size: 128)),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(28, 2, 28, 22),
                          child: Tl(
                            at: 0.25,
                            child: Column(
                              children: [
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: LPText.display(size: 28, color: LP.primaryDark),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  subtitle,
                                  textAlign: TextAlign.center,
                                  style: LPText.bodyM.copyWith(color: LP.muted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Tl(
                      at: 0.2,
                      duration: 0.8,
                      vars: const GsapVars(y: 160, opacity: 1),
                      ease: Ease.power4Out,
                      child: Container(
                        padding: EdgeInsets.fromLTRB(20, 22, 20, 24 + MediaQuery.paddingOf(context).bottom),
                        decoration: const BoxDecoration(
                          color: LP.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                          boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 30, offset: Offset(0, -6))],
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ————————————————————————————————————————————— Inscription / connexion

/// Un seul écran d'accès : onglets « Créer un compte » / « Se connecter » de même taille.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.initialMode = AuthMode.signup, this.showErrors = false});
  final AuthMode initialMode;

  /// Aperçu des états d'erreur (validation ou identifiants refusés).
  final bool showErrors;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Le ViewModel porte l'état et la logique ; la vue ne garde que les outils d'affichage.
  late final vm = AuthViewModel(
    Deps.of(context).auth,
    initialMode: widget.initialMode,
    initialError: widget.showErrors && widget.initialMode == AuthMode.login
        ? 'E-mail ou mot de passe incorrect. Il vous reste 4 tentatives.'
        : Deps.of(context).session.wasExpired
        ? 'Votre session a expiré. Reconnectez-vous.'
        : null,
  );

  // Une clé de formulaire par onglet : changer d'onglet efface les erreurs sans vider les champs.
  final _forms = {AuthMode.signup: GlobalKey<FormState>(), AuthMode.login: GlobalKey<FormState>()};
  GlobalKey<FormState> get _form => _forms[vm.mode]!;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pwd = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.showErrors) {
      if (widget.initialMode == AuthMode.signup) {
        _name.text = 'Leïla';
        _email.text = 'leila.bensalah@';
        _pwd.text = 'chat';
        WidgetsBinding.instance.addPostFrameCallback((_) => _submit());
      } else {
        _email.text = 'leila.bensalah@gmail.com';
        _pwd.text = 'motdepasse';
      }
    }
  }

  @override
  void dispose() {
    vm.dispose();
    _name.dispose();
    _email.dispose();
    _pwd.dispose();
    super.dispose();
  }

  /// Après succès, la vue choisit l'écran suivant (la navigation reste du ressort de la vue).
  void _goNext() {
    if (!mounted) return;
    if (vm.isSignup) {
      Navigator.pushNamed(context, R.role);
    } else {
      // Le pet sitter arrive sur son espace, le propriétaire sur l'accueil.
      final home = vm.user?.role == AppRole.petsitter ? R.sitterSpace : R.owner;
      Navigator.pushNamedAndRemoveUntil(context, home, (r) => r.settings.name == R.catalog);
    }
  }

  Future<void> _submit() async {
    final ok = await vm.submit(
      fieldsValid: _form.currentState!.validate(),
      name: _name.text,
      email: _email.text,
      password: _pwd.text,
    );
    if (ok) _goNext();
  }

  Future<void> _socialSignIn(String provider) async {
    if (await vm.signInWith(provider)) _goNext();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: vm, builder: (context, _) => _content(context));
  }

  Widget _content(BuildContext context) {
    return AuthShell(
      title: vm.isSignup ? 'Bienvenue !' : 'Bon retour !',
      subtitle: vm.isSignup ? 'Créez votre compte en quelques secondes.' : 'Retrouvez vos animaux et vos gardes.',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ModeToggle(mode: vm.mode, onChanged: vm.switchMode),
            const SizedBox(height: 20),
            if (vm.banner != null) ...[
              InfoNote(vm.banner!, icon: PhosphorIconsRegular.warningCircle, tone: InfoTone.error),
              const SizedBox(height: 14),
            ],
            AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Ease.power3Out,
              alignment: Alignment.topCenter,
              child: Column(
                key: ValueKey(vm.mode),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (vm.isSignup) ...[
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                        hintText: 'Ex. : Leïla Ben Salah',
                        prefixIcon: Icon(PhosphorIconsRegular.user, size: 20),
                      ),
                      validator: AuthViewModel.validateName,
                    ).from(y: 18, duration: 0.45),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Adresse e-mail',
                      hintText: 'nom@exemple.tn',
                      prefixIcon: Icon(PhosphorIconsRegular.envelopeSimple, size: 20),
                    ),
                    validator: AuthViewModel.validateEmail,
                  ).from(key: ValueKey('e${vm.mode}'), y: 18, delay: 0.05, duration: 0.45),
                  const SizedBox(height: 12),
                  PasswordField(
                    controller: _pwd,
                    label: 'Mot de passe',
                    hint: vm.isSignup ? '8 caractères minimum' : 'Votre mot de passe',
                    showStrength: vm.isSignup,
                    validator: vm.validatePassword,
                  ).from(key: ValueKey('p${vm.mode}'), y: 18, delay: 0.1, duration: 0.45),
                  if (vm.isSignup) ...[
                    const SizedBox(height: 8),
                    _TermsCheck(value: vm.termsAccepted, error: vm.termsError, onChanged: vm.setTerms),
                  ] else
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(context, R.forgot),
                        child: const Text('Mot de passe oublié ?'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PawButton(
              label: vm.isSignup ? 'Créer mon compte' : 'Se connecter',
              loading: vm.loading,
              onPressed: _submit,
            ),
            const OrDivider('ou continuer avec'),
            SocialRow(
              loading: vm.socialLoading,
              onApple: () => _socialSignIn('apple'),
              onGoogle: () => _socialSignIn('google'),
            ),
            const SizedBox(height: 16),
            Text(
              "Votre mot de passe est chiffré et n'est jamais partagé.",
              textAlign: TextAlign.center,
              style: LPText.bodyS.copyWith(fontSize: 12.5, color: LP.faint),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sélecteur à deux onglets de même taille, indicateur vert qui glisse.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});
  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(AuthMode m, String label) {
      final on = m == mode;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(m),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: LPText.body(size: 15.5, w: FontWeight.w800, color: on ? LP.white : LP.muted),
                child: Text(label),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 56,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: LP.soft, borderRadius: BorderRadius.circular(99)),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 380),
            curve: Ease.backOutSoft,
            alignment: mode == AuthMode.signup ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: LP.primary,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(color: LP.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
              ),
            ),
          ),
          Row(children: [tab(AuthMode.signup, 'Créer un compte'), tab(AuthMode.login, 'Se connecter')]),
        ],
      ),
    );
  }
}

class _TermsCheck extends StatelessWidget {
  const _TermsCheck({required this.value, required this.error, required this.onChanged});
  final bool value;
  final bool error;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(LP.r12),
          onTap: () => onChanged(!value),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(value: value, isError: error, onChanged: (v) => onChanged(v ?? false)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 11),
                  child: Text.rich(
                    TextSpan(
                      style: LPText.body(size: 13.5),
                      children: [
                        const TextSpan(text: 'J\'accepte les '),
                        TextSpan(
                          text: 'conditions d\'utilisation',
                          style: LPText.body(size: 13.5, w: FontWeight.w800, color: LP.primary),
                        ),
                        const TextSpan(text: ' et la '),
                        TextSpan(
                          text: 'politique de confidentialité',
                          style: LPText.body(size: 13.5, w: FontWeight.w800, color: LP.primary),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (error)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              'Veuillez accepter les conditions pour continuer.',
              style: LPText.body(size: 13, color: LP.error, w: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

// ————————————————————————————————————————————— MOT DE PASSE OUBLIÉ

/// Récupération en trois étapes : adresse e-mail → code à 6 chiffres + nouveau mot de passe → terminé.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.preview});

  /// Aperçu d'un état précis (pour les captures du sommaire), sinon null.
  final String? preview;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final vm = ForgotPasswordViewModel(
    Deps.of(context).auth,
    sentTo: widget.preview == 'sent' ? 'leila.bensalah@gmail.com' : null,
  );

  final _emailForm = GlobalKey<FormState>();
  final _resetForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _pwd = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    vm.dispose();
    _email.dispose();
    _code.dispose();
    _pwd.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_emailForm.currentState!.validate()) return;
    await vm.send(_email.text);
  }

  Future<void> _reset() async {
    if (!_resetForm.currentState!.validate()) return;
    await vm.reset(code: _code.text, newPassword: _pwd.text);
  }

  void _finish() {
    final home = Deps.of(context).session.user?.role == AppRole.petsitter ? R.sitterSpace : R.owner;
    Navigator.pushNamedAndRemoveUntil(context, home, (r) => r.settings.name == R.catalog);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: vm, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    final (title, subtitle) = switch (vm.step) {
      ResetStep.email => ('Mot de passe oublié', 'Nous vous envoyons un code pour en choisir un nouveau.'),
      ResetStep.code => ('Vérifiez votre boîte mail', 'Le code reste valable 15 minutes.'),
      ResetStep.done => ('C\'est fait !', 'Votre nouveau mot de passe est enregistré.'),
    };
    return AuthShell(
      title: title,
      subtitle: subtitle,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (vm.step) {
          ResetStep.email => _emailView(),
          ResetStep.code => _codeView(),
          ResetStep.done => _doneView(),
        },
      ),
    );
  }

  Widget _errorNote() => vm.error == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: InfoNote(vm.error!, icon: PhosphorIconsRegular.warningCircle, tone: InfoTone.error),
        );

  Widget _emailView() => Form(
    key: _emailForm,
    child: Column(
      key: const ValueKey('email'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _errorNote(),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Adresse e-mail',
            hintText: 'nom@exemple.tn',
            prefixIcon: Icon(PhosphorIconsRegular.envelopeSimple, size: 20),
          ),
          validator: AuthViewModel.validateEmail,
          onFieldSubmitted: (_) => _send(),
        ),
        const SizedBox(height: 18),
        PawButton(label: 'Recevoir le code', loading: vm.loading, onPressed: _send),
        const SizedBox(height: 18),
        const InfoNote(
          'Inscrit avec Apple ou Google ? Utilisez le même bouton pour vous connecter, sans mot de passe.',
        ),
      ],
    ),
  );

  Widget _codeView() => Form(
    key: _resetForm,
    child: Column(
      key: const ValueKey('code'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            style: LPText.bodyM.copyWith(color: LP.muted),
            children: [
              const TextSpan(text: 'Si un compte existe pour '),
              TextSpan(
                text: vm.email,
                style: LPText.bodyM.copyWith(fontWeight: FontWeight.w800, color: LP.ink),
              ),
              const TextSpan(text: ', un code à 6 chiffres vient d\'y être envoyé. Pensez aux courriers indésirables.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (vm.info != null) ...[
          InfoNote(vm.info!, icon: PhosphorIconsRegular.checkCircle),
          const SizedBox(height: 14),
        ],
        _errorNote(),
        TextFormField(
          controller: _code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofillHints: const [AutofillHints.oneTimeCode],
          textAlign: TextAlign.center,
          style: LPText.display(size: 24).copyWith(letterSpacing: 8),
          decoration: const InputDecoration(
            labelText: 'Code reçu',
            counterText: '',
            prefixIcon: Icon(PhosphorIconsRegular.key, size: 20),
          ),
          validator: ForgotPasswordViewModel.validateCode,
        ),
        const SizedBox(height: 12),
        PasswordField(
          controller: _pwd,
          label: 'Nouveau mot de passe',
          hint: '8 caractères minimum',
          showStrength: true,
          validator: AuthViewModel.validateNewPassword,
        ),
        const SizedBox(height: 12),
        PasswordField(
          controller: _confirm,
          label: 'Confirmer le mot de passe',
          hint: 'Saisissez-le à nouveau',
          validator: (v) => v != _pwd.text ? 'Les deux mots de passe ne correspondent pas.' : null,
        ),
        const SizedBox(height: 18),
        PawButton(label: 'Changer mon mot de passe', loading: vm.loading, onPressed: _reset),
        const SizedBox(height: 6),
        TextButton(
          onPressed: vm.canResend ? vm.resend : null,
          child: Text(
            vm.resendIn > 0
                ? 'Renvoyer le code dans 0:${vm.resendIn.toString().padLeft(2, '0')}'
                : 'Renvoyer le code',
          ),
        ),
        TextButton(onPressed: vm.loading ? null : vm.changeEmail, child: const Text('Modifier l\'adresse e-mail')),
      ],
    ),
  );

  Widget _doneView() => Column(
    key: const ValueKey('done'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Center(
        child: Container(
          width: 76,
          height: 76,
          decoration: const BoxDecoration(color: LP.mint, shape: BoxShape.circle),
          child: const Icon(PhosphorIconsFill.checkCircle, size: 36, color: LP.primary),
        ).from(scale: 0.3, duration: 0.9, ease: Ease.elasticOut),
      ),
      const SizedBox(height: 18),
      Text(
        'Vous êtes connecté. Les autres appareils devront se reconnecter avec le nouveau mot de passe.',
        style: LPText.bodyL.copyWith(color: LP.muted),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      PawButton(label: 'Continuer', onPressed: _finish),
    ],
  );
}

// ————————————————————————————————————————————— CHOIX DU PROFIL

class RoleChoiceScreen extends StatefulWidget {
  const RoleChoiceScreen({super.key, this.fromSettings = false, this.preview});

  /// Aperçu d'un état précis (pour les captures du sommaire), sinon null.
  final String? preview;
  final bool fromSettings;

  @override
  State<RoleChoiceScreen> createState() => _RoleChoiceScreenState();
}

class _RoleChoiceScreenState extends State<RoleChoiceScreen> {
  late final vm = () {
    final deps = Deps.of(context);
    final signedIn = deps.session.isAuthenticated;
    // Sans compte connecté (aperçu du sommaire), le choix n'est pas enregistré.
    return RoleChoiceViewModel(signedIn ? deps.auth : null, deps.session.user?.firstName)
      ..choose(widget.preview == 'chosen' ? 0 : -1);
  }();

  Future<void> _continue() async {
    if (!await vm.confirm() || !mounted) return;
    if (vm.choice == 0) {
      Navigator.pushNamed(context, R.addPet, arguments: true);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, R.sitterSpace, (r) => r.settings.name == R.catalog);
    }
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: vm, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bienvenue, ${vm.firstName ?? 'Leïla'}', style: LPText.overline.copyWith(color: LP.accentInk)),
              const SizedBox(height: 10),
              Text('Comment souhaitez-vous utiliser Pet Sitter ?', style: LPText.h1),
              const SizedBox(height: 28),
              _RoleOption(
                icon: PhosphorIconsRegular.magnifyingGlass,
                title: 'Je cherche une garde',
                body: 'Pour mon chat, mon chien, mon oiseau ou tout autre compagnon pendant mes absences.',
                selected: vm.choice == 0,
                onTap: () => vm.choose(0),
              ),
              const SizedBox(height: 14),
              _RoleOption(
                icon: PhosphorIconsRegular.handHeart,
                title: 'Je souhaite devenir pet sitter',
                body: 'J\'accueille des animaux chez moi ou je leur rends visite, et je fixe mes tarifs.',
                selected: vm.choice == 1,
                onTap: () => vm.choose(1),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(PhosphorIconsRegular.arrowCounterClockwise, size: 18, color: LP.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Ce choix reste modifiable à tout moment depuis votre profil.', style: LPText.bodyS),
                  ),
                ],
              ),
              const Spacer(),
              if (vm.error != null) ...[
                InfoNote(vm.error!, icon: PhosphorIconsRegular.warningCircle, tone: InfoTone.error),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: vm.canContinue ? _continue : null,
                  child: vm.loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: LP.white),
                        )
                      : const Text('Continuer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.icon,
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LP.r20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected ? LP.mintPale : LP.white,
            borderRadius: BorderRadius.circular(LP.r20),
            border: Border.all(color: selected ? LP.primary : LP.line, width: selected ? 2 : 1.2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: selected ? LP.primary : LP.accentSoft, shape: BoxShape.circle),
                child: Icon(icon, color: selected ? LP.white : LP.accentInk, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: LPText.title),
                    const SizedBox(height: 4),
                    Text(body, style: LPText.bodyS),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.circle,
                color: selected ? LP.primary : LP.line,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
