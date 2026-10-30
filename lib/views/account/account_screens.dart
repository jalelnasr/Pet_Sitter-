import 'package:flutter/material.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';

import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/core/motion/gsap.dart';
import 'package:pet_sitter/app/routes.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/widgets/common.dart';
import 'package:pet_sitter/app/dependencies.dart';
import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/view_models/account_view_model.dart';
import 'package:pet_sitter/view_models/booking_view_model.dart';
import 'package:pet_sitter/views/owner/search_screen.dart';

// ————————————————————————————————————————————— RÉSERVATIONS

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<BookingsViewModel>(
      create: (context) => BookingsViewModel(Deps.of(context).bookings),
      builder: (context, vm) => _content(context, vm),
    );
  }

  Widget _content(BuildContext context, BookingsViewModel vm) {
    final upcoming = vm.upcoming;
    final current = vm.current;
    final past = vm.past;
    return DefaultTabController(
      length: 3,
      initialIndex: 1,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('Réservations', style: LPText.h2),
          bottom: TabBar(
            isScrollable: false,
            tabs: [
              Tab(text: 'À venir · ${upcoming.length}'),
              Tab(text: 'En cours · ${current.length}'),
              const Tab(text: 'Passées'),
            ],
          ),
        ),
        body: TabBarView(children: [_list(context, upcoming), _list(context, current), _list(context, past)]),
      ),
    );
  }

  Widget _list(BuildContext context, List<Booking> items) {
    if (items.isEmpty) {
      return Center(child: Text('Aucune garde pour le moment.', style: LPText.bodyS));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(indent: 20, endIndent: 20),
      itemBuilder: (_, i) => _BookingRow(b: items[i]).from(y: 28, delay: stagger(i, start: 0.1, each: 0.08)),
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({required this.b});
  final Booking b;

  @override
  Widget build(BuildContext context) {
    final live = b.status == BookingStatus.enCours;
    return InkWell(
      onTap: () {
        if (live) {
          Navigator.pushNamed(context, R.journal);
        } else if (b.status == BookingStatus.attente || b.status == BookingStatus.confirmee) {
          Navigator.pushNamed(context, R.status, arguments: b.status);
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusPill(b.status),
                const Spacer(),
                Text('${b.total} DT', style: LPText.price.copyWith(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                LPAvatar(b.sitter.photo, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.service == ServiceType.accueil
                            ? 'Accueil chez ${b.sitter.firstName}'
                            : 'Visites de ${b.sitter.firstName}',
                        style: LPText.title.copyWith(fontSize: 16),
                      ),
                      Text(b.dates, style: LPText.bodyS),
                    ],
                  ),
                ),
                Row(
                  children: [
                    for (final p in b.pets) Align(widthFactor: 0.7, child: LPAvatar(p.photo, size: 32, ring: true)),
                  ],
                ),
              ],
            ),
            if (live) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                      onPressed: () => Navigator.pushNamed(context, R.journal),
                      icon: const Icon(PhosphorIconsRegular.notepad, size: 18),
                      label: const Text('Journal du jour'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
                    onPressed: () => Navigator.pushNamed(context, R.chat),
                    child: const Icon(PhosphorIconsRegular.chatCircleDots, size: 20, semanticLabel: 'Messages'),
                  ),
                ],
              ),
            ],
            if (b.status == BookingStatus.terminee) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () {},
                    icon: const Icon(PhosphorIconsRegular.star, size: 18),
                    label: const Text('Laisser un avis'),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => Navigator.pushNamed(context, R.booking, arguments: b.sitter),
                    icon: const Icon(PhosphorIconsRegular.arrowCounterClockwise, size: 18),
                    label: const Text('Réserver à nouveau'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ————————————————————————————————————————————— PROFIL / COMPTE

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AccountViewModel>(
      create: (context) => AccountViewModel(Deps.of(context).pets, Deps.of(context).sitters),
      builder: (context, vm) => _content(context, vm),
    );
  }

  Widget _content(BuildContext context, AccountViewModel vm) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 130),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  LPAvatar(vm.photo, size: 72),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vm.fullName, style: LPText.h2),
                        Text('La Marsa, Tunis · membre depuis 2025', style: LPText.bodyS),
                        const SizedBox(height: 4),
                        TextButton(
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                          onPressed: () {},
                          child: const Text('Modifier mon profil'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Changement de rôle — le choix initial reste modifiable
            Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(color: LP.accentSoft, borderRadius: BorderRadius.circular(LP.r20)),
              child: Row(
                children: [
                  const Icon(PhosphorIconsRegular.handHeart, color: LP.accentInk, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mode propriétaire', style: LPText.label.copyWith(color: LP.accentInk)),
                        Text(
                          'Vous aimez les animaux ? Proposez vos services.',
                          style: LPText.body(size: 13.5, color: LP.ink),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: LP.primaryDark),
                    onPressed: () => Navigator.pushNamed(context, R.sitterSpace),
                    child: const Text('Devenir sitter'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _group('Mon espace'),
            LPListTile(
              icon: PhosphorIconsRegular.pawPrint,
              title: 'Mes animaux',
              subtitle: vm.petsSummary,
              onTap: () => Navigator.pushNamed(context, R.myPets),
            ),
            LPListTile(
              icon: PhosphorIconsRegular.heart,
              title: 'Favoris',
              subtitle: '${vm.favoritesCount} pet sitters',
              onTap: () => Navigator.pushNamed(context, R.favorites),
            ),
            LPListTile(
              icon: PhosphorIconsRegular.bell,
              title: 'Notifications',
              trailing: const Pill(label: '3', bg: LP.primary, fg: LP.white),
              onTap: () => Navigator.pushNamed(context, R.notifications),
            ),
            _group('Assistance'),
            LPListTile(
              icon: PhosphorIconsRegular.lifebuoy,
              title: 'Aide',
              subtitle: 'Questions fréquentes, nous contacter',
              onTap: () => Navigator.pushNamed(context, R.help),
            ),
            LPListTile(
              icon: PhosphorIconsRegular.gearSix,
              title: 'Paramètres',
              subtitle: 'Compte, langue, confidentialité',
              onTap: () => Navigator.pushNamed(context, R.settings),
            ),
            const SizedBox(height: 8),
            LPListTile(
              icon: PhosphorIconsRegular.signOut,
              title: 'Se déconnecter',
              danger: true,
              trailing: const SizedBox.shrink(),
              onTap: () =>
                  Navigator.pushNamedAndRemoveUntil(context, R.onboarding, (r) => r.settings.name == R.catalog),
            ),
            const SizedBox(height: 20),
            Center(child: Text('Pet Sitter · version 1.0.0', style: LPText.bodyS.copyWith(fontSize: 12.5))),
          ],
        ),
      ),
    );
  }

  Widget _group(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 4),
    child: Text(t.toUpperCase(), style: LPText.overline),
  );
}

// ————————————————————————————————————————————— FAVORIS

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<FavoritesViewModel>(
      create: (context) => FavoritesViewModel(Deps.of(context).sitters),
      builder: (context, vm) => _content(context, vm),
    );
  }

  Widget _content(BuildContext context, FavoritesViewModel vm) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Favoris')),
      body: ListView(
        children: [
          for (final s in vm.favorites) ...[
            SitterResultRow(sitter: s, service: s.mainService, fav: true),
            const Divider(indent: 20, endIndent: 20),
          ],
        ],
      ),
    );
  }
}

// ————————————————————————————————————————————— NOTIFICATIONS

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final vm = NotificationsViewModel();

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: vm, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    final items = [
      (PhosphorIconsRegular.camera, 'Amira a ajouté une photo de Simba', 'Il y a 12 min', true),
      (PhosphorIconsRegular.checkCircle, 'Salma a confirmé les visites pour Bulle', 'Hier, 18:20', true),
      (PhosphorIconsRegular.hourglassMedium, 'Votre demande à Inès attend une réponse', 'Lun., 10:05', true),
      (PhosphorIconsRegular.calendarCheck, 'Rappel : dépôt de Simba et Kiwi vendredi à 18 h', 'Mer., 09:00', false),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Notifications'),
        actions: [
          TextButton(onPressed: () {}, child: const Text('Tout lire')),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        children: [
          for (final (icon, title, time, unread) in items)
            Container(
              color: unread ? LP.mintPale.withValues(alpha: 0.6) : null,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: unread ? LP.white : LP.soft, shape: BoxShape.circle),
                    child: Icon(icon, size: 20, color: LP.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: LPText.body(size: 15, w: unread ? FontWeight.w600 : FontWeight.w400)),
                        Text(time, style: LPText.bodyS.copyWith(fontSize: 12.5)),
                      ],
                    ),
                  ),
                  if (unread)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(color: LP.accent, shape: BoxShape.circle),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 6),
            child: Text('PRÉFÉRENCES', style: LPText.overline),
          ),
          for (final e in vm.prefs.entries)
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              value: e.value,
              onChanged: (v) => vm.setPref(e.key, v),
              title: Text(e.key, style: LPText.bodyL),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ————————————————————————————————————————————— AIDE

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const faq = [
      (
        'Comment sont vérifiés les pet sitters ?',
        'Chaque sitter peut faire vérifier son identité, son téléphone et son adresse. Les badges ne s\'affichent que lorsque la vérification est réellement effectuée.',
      ),
      (
        'Quand suis-je débité ?',
        'Uniquement après l\'acceptation de votre demande. Le montant est versé au sitter 24 h après le début de la garde.',
      ),
      (
        'Que se passe-t-il en cas d\'urgence vétérinaire ?',
        'Le sitter contacte d\'abord votre vétérinaire s\'il est renseigné, puis vous prévient. Notre assistance reste joignable 7j/7.',
      ),
      (
        'Puis-je faire garder des animaux différents ensemble ?',
        'Oui, si le sitter accepte toutes les espèces concernées. Un supplément par animal peut s\'appliquer.',
      ),
      (
        'Comment annuler une réservation ?',
        'Depuis l\'onglet Réservations. L\'annulation est gratuite jusqu\'à 48 h avant le début de la garde.',
      ),
    ];
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Aide')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher dans l\'aide',
                prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass, size: 20),
              ),
            ),
          ),
          const SectionHeader('Questions fréquentes', padding: EdgeInsets.fromLTRB(20, 18, 20, 0)),
          for (final (q, a) in faq)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 20),
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                iconColor: LP.primary,
                collapsedIconColor: LP.muted,
                title: Text(q, style: LPText.body(size: 15.5, w: FontWeight.w600)),
                children: [Text(a, style: LPText.bodyM.copyWith(color: LP.muted))],
              ),
            ),
          const SectionHeader('Nous contacter', padding: EdgeInsets.fromLTRB(20, 26, 20, 4)),
          const LPListTile(
            icon: PhosphorIconsRegular.chatCircleDots,
            title: 'Discuter avec l\'équipe',
            subtitle: 'Réponse en moins de 30 min, 8 h – 22 h',
          ),
          const LPListTile(
            icon: PhosphorIconsRegular.phone,
            title: 'Urgence pendant une garde',
            subtitle: 'Ligne d\'assistance 7j/7',
          ),
          const LPListTile(
            icon: PhosphorIconsRegular.envelopeSimple,
            title: 'Écrire un e-mail',
            subtitle: 'aide@petsitter.tn',
          ),
        ],
      ),
    );
  }
}

// ————————————————————————————————————————————— PARAMÈTRES

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final vm = SettingsViewModel();

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: vm, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _g('Compte'),
          const LPListTile(
            icon: PhosphorIconsRegular.user,
            title: 'Informations personnelles',
            subtitle: 'Nom, e-mail, téléphone',
          ),
          const LPListTile(
            icon: PhosphorIconsRegular.lockSimple,
            title: 'Mot de passe et connexion',
            subtitle: 'Google associé',
          ),
          LPListTile(
            icon: PhosphorIconsRegular.arrowsLeftRight,
            title: 'Mon usage de Pet Sitter',
            subtitle: 'Je cherche une garde',
            onTap: () => Navigator.pushNamed(context, R.role),
          ),
          _g('Préférences'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Langue de l\'application', style: LPText.label),
                const SizedBox(height: 10),
                ChoiceGroup(
                  options: const ['Français', 'العربية', 'English'],
                  selected: {vm.language},
                  onTap: vm.setLanguage,
                ),
              ],
            ),
          ),
          const LPListTile(
            icon: PhosphorIconsRegular.coins,
            title: 'Devise',
            subtitle: 'Dinar tunisien (DT)',
            trailing: SizedBox.shrink(),
          ),
          _g('Confidentialité'),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            value: vm.sharePhone,
            onChanged: vm.setSharePhone,
            title: Text('Partager mon numéro après confirmation', style: LPText.bodyL),
            subtitle: Text('Sinon, échanges uniquement via la messagerie', style: LPText.bodyS),
          ),
          const LPListTile(icon: PhosphorIconsRegular.downloadSimple, title: 'Télécharger mes données'),
          const SizedBox(height: 12),
          const LPListTile(
            icon: PhosphorIconsRegular.trash,
            title: 'Supprimer mon compte',
            danger: true,
            trailing: SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _g(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
    child: Text(t.toUpperCase(), style: LPText.overline),
  );
}
