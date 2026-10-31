import 'package:flutter/material.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';

import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/core/motion/gsap.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/widgets/common.dart';

/// Mini guide de style : couleurs, typographie, boutons, champs, icônes, états.
class StyleGuideScreen extends StatelessWidget {
  const StyleGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Guide de style')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
        children: [
          const Center(child: BrandLogo(size: 220)),
          const SizedBox(height: 8),
          Text(
            'Chaleureux, rassurant, joueur. Les couleurs du logo partout : le vert de la maison, le jaune de l\'empreinte, le fond crème ; des formes géantes et des photos cadrées en cercles.',
            style: LPText.bodyL.copyWith(color: LP.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Wordmark(size: 22),
              const SizedBox(width: 18),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: LP.night, borderRadius: BorderRadius.circular(16)),
                child: const Wordmark(size: 18, color: LP.white),
              ),
            ],
          ),

          _h('01', 'Couleurs'),
          _swatches('Logo', const [
            ('Vert', LP.primary, '#0F5534', 'Maison, boutons · 8,6:1'),
            ('Jaune', LP.accent, '#FABB24', 'Empreinte, étoiles'),
            ('Crème', LP.cream, '#FFFAF0', 'Démarrage, guide'),
          ]),
          _swatches('Fonds', const [
            ('Blanc', LP.bg, '#FFFFFF', 'Fond principal'),
            ('Doux', LP.soft, '#F3F6F5', 'Zones, recherche'),
            ('Vert doux', LP.mintBg, '#D2EAD9', 'Cercles photo'),
            ('Vert clair', LP.mint, '#DFF0E4', 'Sélection douce'),
          ]),
          _swatches('Vert foncé · panneaux', const [
            ('Vert nuit', LP.night, '#0E3B26', 'Panneaux, navigation'),
            ('Vert nuit doux', LP.nightSoft, '#1B4C35', 'Puces sur fond sombre'),
            ('Texte sur vert', LP.onNightMuted, '#B7CFC0', 'Secondaire · 7,6:1'),
          ]),
          _swatches('Jaune · accent', const [
            ('Jaune pâle', LP.accentSoft, '#FEF0C7', 'Badges'),
            ('Jaune encre', LP.accentInk, '#7A5300', 'Texte accent · 6,4:1'),
          ]),
          _swatches('Texte et états', const [
            ('Encre', LP.ink, '#151816', 'Texte · 17:1'),
            ('Gris', LP.muted, '#5C6461', 'Secondaire · 6:1'),
            ('Erreur', LP.error, '#B3261E', 'Erreurs, refus'),
            ('Attente', LP.warning, '#7A5200', 'En attente'),
          ]),
          const SizedBox(height: 4),
          const InfoNote(
            'Règle : le jaune sert de fond, d\'icône ou de forme, jamais de texte sur blanc ; pour du texte jaune, utiliser « Jaune encre ». Tous les couples texte/fond atteignent au moins 4,5:1.',
            icon: PhosphorIconsRegular.eye,
          ),

          _h('02', 'Typographie'),
          _type('Outfit · 800 · 34', 'Partez l\'esprit tranquille', LPText.h1),
          _type('Outfit · 700 · 25', 'Qui gardons-nous ?', LPText.h2),
          _type('Outfit · 700 · 19', 'Services et tarifs', LPText.h3),
          _type('Urbanist · 700 · 17', 'Accueil chez Amira', LPText.title),
          _type('Urbanist · 500 · 16', 'Échangez des messages et recevez des nouvelles en photos.', LPText.bodyL),
          _type('Urbanist · 500 · 13,5 · gris', 'La Marsa · à 1,2 km', LPText.bodyS),
          _type('Urbanist · 800 · 12 · capitales', 'SUGGESTIONS', LPText.overline),
          _type('Prix · Outfit 800', '35 DT / nuit', LPText.price),

          _h('03', 'Boutons'),
          _label('Principal · pilule à empreinte'),
          PawButton(label: 'Rechercher un pet sitter', onPressed: () {}),
          const SizedBox(height: 10),
          _label('Sur fond sombre ou menthe'),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: LP.night, borderRadius: BorderRadius.circular(LP.r28)),
            child: PawButton(label: 'Demander une réservation', dark: false, onPressed: () {}),
          ),
          const SizedBox(height: 10),
          _label('Compact · menthe'),
          Align(
            alignment: Alignment.centerLeft,
            child: PawButton(label: 'Voir plus', mint: true, expand: false, onPressed: () {}),
          ),
          const SizedBox(height: 10),
          _label('Secondaire · contour'),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(onPressed: () {}, child: const Text('Se connecter')),
          ),
          const SizedBox(height: 10),
          _label('Tertiaire · lien'),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: () {}, child: const Text('Mot de passe oublié ?')),
          ),
          const SizedBox(height: 10),
          _label('États'),
          Row(
            children: [
              const Expanded(child: PawButton(label: 'Désactivé', onPressed: null)),
              const SizedBox(width: 10),
              Expanded(
                child: PawButton(label: 'Envoi…', loading: true, onPressed: () {}),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: LP.error),
                  onPressed: () {},
                  child: const Text('Refuser'),
                ),
              ),
              const SizedBox(width: 10),
              RoundIconButton(PhosphorIconsRegular.heart, tooltip: 'Icône'),
              const SizedBox(width: 8),
              RoundIconButton(PhosphorIconsRegular.bell, badge: true, tooltip: 'Avec pastille'),
            ],
          ),
          const SizedBox(height: 8),
          Text('Hauteur 58 px · pilule · pastille de 48 px · cible tactile ≥ 44 px', style: LPText.bodyS),
          const SizedBox(height: 18),
          _label('Puces d\'espèce'),
          Transform.translate(
            offset: const Offset(-20, 0),
            child: SpeciesChips(selected: Species.chat, onChanged: (_) {}),
          ),

          _h('04', 'Champs'),
          _label('Par défaut'),
          const TextField(
            decoration: InputDecoration(
              hintText: 'nom@exemple.tn',
              prefixIcon: Icon(PhosphorIconsRegular.envelopeSimple, size: 20),
            ),
          ),
          const SizedBox(height: 14),
          _label('Focus'),
          const _FocusedField(),
          const SizedBox(height: 14),
          _label('Erreur'),
          const TextField(
            decoration: InputDecoration(
              hintText: 'leila@',
              errorText: 'Cette adresse e-mail semble incomplète.',
              prefixIcon: Icon(PhosphorIconsRegular.envelopeSimple, size: 20),
            ),
          ),
          const SizedBox(height: 14),
          _label('Désactivé'),
          const TextField(enabled: false, decoration: InputDecoration(hintText: 'Non modifiable')),
          const SizedBox(height: 14),
          _label('Sélections'),
          ChoiceGroup(options: const ['Intérieur', 'Balcon', 'Extérieur'], selected: const {'Balcon'}, onTap: (_) {}),
          const SizedBox(height: 10),
          Row(
            children: [
              Switch(value: true, onChanged: (_) {}),
              Switch(value: false, onChanged: (_) {}),
              Checkbox(value: true, onChanged: (_) {}),
              Checkbox(value: false, onChanged: (_) {}),
              const Spacer(),
              Counter(value: 2, onChanged: (_) {}),
            ],
          ),

          _h('05', 'Icônes'),
          Text('Phosphor · trait régulier 1,5 px · versions pleines pour l\'état actif', style: LPText.bodyS),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 16,
            children: [
              for (final s in Species.values) _icon(s.icon, s.label),
              _icon(PhosphorIconsRegular.houseLine, 'Accueil'),
              _icon(PhosphorIconsRegular.key, 'Visite'),
              _icon(PhosphorIconsRegular.calendarBlank, 'Dates'),
              _icon(PhosphorIconsRegular.mapPin, 'Lieu'),
              _icon(PhosphorIconsRegular.chatCircleDots, 'Message'),
              _icon(PhosphorIconsRegular.bowlFood, 'Repas'),
              _icon(PhosphorIconsRegular.firstAidKit, 'Soins'),
              _icon(PhosphorIconsRegular.camera, 'Photo'),
              _icon(PhosphorIconsRegular.footprints, 'Promenade'),
              _icon(PhosphorIconsRegular.sealCheck, 'Vérifié'),
              _icon(PhosphorIconsRegular.heart, 'Favori'),
            ],
          ),
          const SizedBox(height: 18),
          _label('Catégories visuelles (sélecteur d\'espèce)'),
          Transform.translate(
            offset: const Offset(-20, 0),
            child: SpeciesPicker(selected: const {Species.oiseau}, onChanged: (_) {}),
          ),

          _h('06', 'États des composants'),
          _label('Statuts de réservation'),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final s in BookingStatus.values) StatusPill(s)]),
          const SizedBox(height: 18),
          _label('Badges'),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FictifBadge(),
              NewSitterTag(),
              Pill(label: 'Identité vérifiée', icon: PhosphorIconsBold.sealCheck),
              Pill(label: 'Prévu', bg: LP.soft, fg: LP.muted),
            ],
          ),
          const SizedBox(height: 18),
          _label('Messages d\'information'),
          const InfoNote('Aucun paiement maintenant.', icon: PhosphorIconsRegular.shieldCheck, tone: InfoTone.success),
          const SizedBox(height: 8),
          const InfoNote(
            'E-mail ou mot de passe incorrect.',
            icon: PhosphorIconsRegular.warningCircle,
            tone: InfoTone.error,
          ),
          const SizedBox(height: 8),
          const InfoNote('Exemples fictifs, pour illustrer l\'application.', tone: InfoTone.apricot),
          const SizedBox(height: 18),
          _label('Tarif · toujours avec son unité'),
          const Wrap(spacing: 24, children: [PriceTag(35, 'nuit'), PriceTag(18, 'visite')]),

          _h('07', 'Espacements et rayons'),
          Text('Grille de 4 px · marges d\'écran 20 px · sections espacées de 28 à 32 px', style: LPText.bodyM),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final r in [8.0, 12.0, 16.0, 20.0, 28.0])
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: LP.mint,
                          borderRadius: BorderRadius.circular(r),
                          border: Border.all(color: LP.primary),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('${r.round()}', style: LPText.bodyS.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),

          _h('08', 'Motion'),
          Text(
            'Modèle GSAP recréé en Flutter (lib/motion/gsap.dart) : from(), timelines, stagger, yoyo. '
            'Tout se coupe si le système demande de réduire les animations.',
            style: LPText.bodyM.copyWith(color: LP.muted),
          ),
          const SizedBox(height: 14),
          for (final (name, use) in const [
            ('power3.out · 0,6 s', 'Entrées d\'éléments, y 28 → 0'),
            ('stagger 0,06–0,08 s', 'Listes, puces, cartes (8 éléments max)'),
            ('back.out(1.7)', 'Pastilles, cercles photo, badges'),
            ('elastic.out(1, .55)', 'Confirmation, pastille centrale'),
            ('power4.out · SplitText', 'Titres du guide, mot par mot'),
            ('sine.inOut · yoyo', 'Flottement des photos, main qui salue'),
            ('Transition de page', 'Fondu + montée 24 px, 420 ms'),
            ('Appui', 'scale 0,96 en 120 ms, retour en back.out'),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  SizedBox(width: 160, child: Text(name, style: LPText.label.copyWith(fontSize: 13.5))),
                  Expanded(child: Text(use, style: LPText.bodyS)),
                ],
              ),
            ),
          const SizedBox(height: 14),
          const _MotionDemo(),
        ],
      ),
    );
  }

  Widget _h(String n, String t) => Padding(
    padding: const EdgeInsets.only(top: 40, bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(n, style: LPText.display(size: 15, color: LP.accentInk)),
        const SizedBox(width: 10),
        Text(t, style: LPText.h2),
      ],
    ),
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: LPText.overline),
  );

  Widget _swatches(String title, List<(String, Color, String, String)> items) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(title.toUpperCase()),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (name, c, hex, use) in items)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(LP.r12),
                          border: Border.all(color: LP.line),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(name, style: LPText.label.copyWith(fontSize: 13)),
                      Text(hex, style: LPText.bodyS.copyWith(fontSize: 12)),
                      Text(use, style: LPText.bodyS.copyWith(fontSize: 11.5, height: 1.25)),
                    ],
                  ),
                ),
              ),
            for (var i = items.length; i < 4; i++) const Expanded(child: SizedBox()),
          ],
        ),
      ],
    ),
  );

  Widget _type(String spec, String sample, TextStyle style) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(spec, style: LPText.bodyS.copyWith(fontSize: 12)),
        const SizedBox(height: 4),
        Text(sample, style: style),
      ],
    ),
  );

  Widget _icon(IconData i, String l) => SizedBox(
    width: 72,
    child: Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(color: LP.mintPale, shape: BoxShape.circle),
          child: Icon(i, color: LP.primary, size: 24),
        ),
        const SizedBox(height: 6),
        Text(l, style: LPText.bodyS.copyWith(fontSize: 12), textAlign: TextAlign.center),
      ],
    ),
  );
}

class _FocusedField extends StatelessWidget {
  const _FocusedField();

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      isFocused: true,
      decoration: const InputDecoration(prefixIcon: Icon(PhosphorIconsRegular.user, size: 20, color: LP.primary)),
      child: Text('Leïla Ben Salah', style: LPText.bodyL),
    );
  }
}

class _MotionDemo extends StatefulWidget {
  const _MotionDemo();

  @override
  State<_MotionDemo> createState() => _MotionDemoState();
}

class _MotionDemoState extends State<_MotionDemo> {
  int _run = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: LP.cream, borderRadius: BorderRadius.circular(LP.r28)),
      child: GsapTimeline(
        duration: 1.6,
        replayKey: _run,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 5; i++)
                  Tl(
                    at: i * 0.08,
                    duration: 0.7,
                    vars: const GsapVars(y: 40, scale: 0.4, opacity: 0),
                    ease: Ease.backOut,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(color: LP.primary, shape: BoxShape.circle),
                      child: Icon(Species.values[i].iconFill, color: LP.white, size: 22),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TlSplitWords('Gardez le lien, même à distance', at: 0.45, style: LPText.display(size: 24)),
            const SizedBox(height: 14),
            PawButton(label: 'Rejouer l\'animation', dark: false, onPressed: () => setState(() => _run++)),
          ],
        ),
      ),
    );
  }
}
