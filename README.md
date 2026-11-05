# Pet Sitter — interfaces Flutter

Application mobile qui met en relation les propriétaires d'animaux (chats, chiens, oiseaux, lapins,
poissons, petits animaux) et des pet sitters en Tunisie. Interface en français, prix en DT.

## Lancer

```bash
flutter pub get
flutter run            # iOS / Android
flutter run -d chrome  # aperçu web (cadre de téléphone sur grand écran)
flutter test           # tests des ViewModels
```

L'app s'ouvre sur l'**écran de démarrage** puis le guide ; un retour arrière mène au **sommaire des maquettes** : chaque écran et chacun de ses états y est accessible,
et « Lancer le parcours complet » déroule guide → inscription → ajout d'un animal → recherche →
profil sitter → demande de réservation → suivi.
Sur le web, chaque écran a aussi une URL directe (`/#/search`, `/#/sitter`, `/#/journal`… voir `lib/app/routes.dart`).

Les captures 390 × 844 de tous les écrans sont dans `maquettes/` (ouvrir `maquettes/index.html`).
Les fichiers `*-complet.png` montrent un écran sur toute sa hauteur de défilement.

## Architecture MVVM

> **Explication complète pour débutant :** [`docs/GUIDE_DU_PROJET.md`](docs/GUIDE_DU_PROJET.md)

```
lib/
├── main.dart            point de départ (crée les dépôts, lance l'app)
├── app/                 app.dart (thème, langue), routes.dart (navigation), dependencies.dart (Deps)
├── models/              M : fiches de données et règles métier (Sitter, Pet, Booking, BookingQuote, Product…)
├── data/
│   ├── repositories/    M : un dépôt par domaine — interface + version de démonstration (Mock…)
│   └── sources/         données fictives
├── view_models/         VM : un ViewModel par écran (état + actions, aucun widget)
├── views/               V : les écrans, qui affichent l'état du ViewModel et lui transmettent les gestes
└── core/                socle MVVM (ViewModel, ViewModelBuilder), thème, widgets partagés, animations
test/                    tests des ViewModels (flutter test)
```

- Une vue ne lit jamais les données directement : elle passe par son ViewModel.
- Un ViewModel ne connaît aucun widget, ce qui permet de le tester sans écran (13 tests dans `test/`).
- Les dépôts sont créés une fois dans `Deps.mock(...)` (`lib/app/dependencies.dart`) ; pour un vrai serveur,
  il suffit de fournir d'autres implémentations des mêmes interfaces.
- Aucune dépendance externe pour le MVVM : `ChangeNotifier` + `ListenableBuilder` de Flutter.

## Écrans

| # | Écran | Fichier |
|---|-------|---------|
| 1 | Guide de bienvenue (3 écrans, progression, « Passer ») | `views/onboarding/onboarding_screen.dart` |
| 2 | Écran d'accès unique (onglets « Créer un compte » / « Se connecter »), récupération, choix du profil | `views/auth/auth_screens.dart` |
| 3 | Accueil propriétaire + moteur de recherche | `views/owner/home_screen.dart` |
| 4 | Résultats : liste, carte, filtres, aucun résultat | `views/owner/search_screen.dart` |
| 5 | Profil du pet sitter | `views/owner/sitter_profile_screen.dart` |
| 6 | Profil de l'animal + formulaire adapté à l'espèce | `views/owner/pet_screens.dart` |
| 7 | Demande de réservation + suivi (envoyée / en attente / confirmée) | `views/booking/booking_screens.dart` |
| 8 | Messagerie, conversation, journal de garde | `views/messages/messages_screens.dart` |
| 9 | Réservations, profil, favoris, notifications, aide, paramètres | `views/account/account_screens.dart` |
| 10 | Espace pet sitter : tableau de bord, disponibilités, tarifs | `views/sitter/sitter_screens.dart` |
| 11 | Boutique : catalogue (espèces, catégories, recherche), fiche produit, panier, commande | `views/shop/shop_screens.dart` |
| — | Guide de style | `views/catalog/style_guide_screen.dart` |

Navigation propriétaire : Accueil · Boutique · Réservations · Messages · Profil (`views/owner/owner_shell.dart`).

### Boutique

- Nourriture, accessoires, jouets, hygiène, pour chaque espèce ; recommandations selon les animaux enregistrés.
- Prix en DT, formats (2 kg, 4 kg…), livraison offerte dès 80 DT (sinon 7 DT), paiement à la livraison ou par carte.
- Panier partagé (`CartRepository` dans `lib/data/repositories/cart_repository.dart`) ; visuels produits dessinés (`lib/core/widgets/product_art.dart`),
  à remplacer par de vraies photos. Produits et marques fictifs.

### Règles de contenu appliquées

- Tous les sitters sont des **exemples fictifs**, signalés par le badge « Profil fictif ».
- Avis et vérifications ne s'affichent **que s'ils existent** (comparer Amira et Mehdi, nouveau sitter).
- Le formulaire d'animal change selon l'espèce : un poisson n'a ni promenade ni comportement,
  mais aquarium, eau et matériel ; un chien a promenades, temps seul, entente.
- Le journal de garde ne propose « Promenade » que si un chien est gardé.
- Tarif toujours affiché avec son unité : « 35 DT / nuit », « 18 DT / visite ».

## Guide de style

Direction inspirée de la référence fournie, aux couleurs du logo : vert, jaune, crème et blanc,
photos cadrées en cercles, formes noires géantes, boutons pilule à empreinte, panneau sombre en dôme.

### Logo et écran de démarrage

- Logo fourni : `assets/splash/logo_source.webp`. Version à fond transparent pour l'app :
  `assets/images/logo_pet_sitter.png` ; version vectorielle du symbole : `LogoMark` (`lib/core/widgets/common.dart`).
- Écran de lancement natif (iOS, Android dont Android 12, web) généré par `flutter_native_splash`
  (configuration dans `pubspec.yaml`, régénérer avec `dart run flutter_native_splash:create`).
- Écran de démarrage animé (`lib/views/onboarding/splash_screen.dart`) : même fond crème, logo qui apparaît,
  halo, empreintes qui « marchent », puis enchaînement automatique sur le guide.

### Couleurs (tirées du logo)

| Rôle | Nom | Hex | Usage |
|------|-----|-----|-------|
| Logo | Vert | `#0F5534` | boutons, sélection, formes du guide (8,6:1 sur blanc) |
| Logo | Jaune | `#FABB24` | empreinte, étoiles, détails — jamais en texte sur blanc |
| Logo | Crème | `#FFFAF0` | écran de démarrage, guide de bienvenue |
| Fond | Blanc | `#FFFFFF` | fond principal |
| Fond | Doux | `#F3F6F5` | zones secondaires, bloc de recherche |
| Fond | Vert doux | `#D2EAD9` | cercles photo |
| Panneau | Vert nuit | `#0E3B26` | panneaux sombres, barre de navigation flottante |
| Accent | Jaune pâle | `#FEF0C7` | badges, trait de fond du guide |
| Accent | Jaune encre | `#7A5300` | texte accent (6,4:1) |
| Texte | Encre | `#151816` | texte principal (17:1) |
| Texte | Gris | `#5C6461` | texte secondaire (6:1) |
| Texte | Sur vert nuit | `#B7CFC0` | texte secondaire sur fond sombre (7,6:1) |
| État | Erreur | `#B3261E` | erreurs, refus |

### Typographie

- **Outfit** (titres, prix) : 34 / 25 / 19, graisse 700–800, interlettrage −0,8.
- **Urbanist** (texte) : 17 titre de ligne, 16 corps, 15 courant, 13,5 secondaire, 12 capitales.

### Composants

- Bouton principal : pilule 58 px avec pastille ronde et empreinte (`PawButton`) —
  noir sur fond clair, blanc sur fond sombre ou menthe, version compacte menthe (« Voir plus »).
- Secondaire : contour noir. Tertiaire : lien. États désactivé et chargement dans la pastille.
- Puces d'espèce : pilules contour, noires quand sélectionnées (Tous · Chat · Chien · Oiseau…).
- Navigation : pilule sombre flottante ; l'onglet actif devient une pastille blanche avec son libellé.
- Profil sitter : portrait dans un grand cercle menthe, panneau sombre à bord en dôme,
  tuiles de traits en pointillés, encart « À propos » pointillé.
- Icônes Phosphor ; version pleine pour l'état actif.

### Motion (modèle GSAP en Flutter)

GSAP est une bibliothèque JavaScript : elle ne s'exécute pas dans Flutter. `lib/core/motion/gsap.dart`
en reprend le modèle avec des `AnimationController` :

| API | Équivalent GSAP | Usage |
|-----|-----------------|-------|
| `widget.from(y: 28, delay: .2)` / `GsapFrom` | `gsap.from()` | entrées d'éléments |
| `stagger(i, each: .08)` | `stagger: { each }` | listes (8 éléments max) |
| `GsapTimeline` + `Tl(at: .4)` | `gsap.timeline()` + position | guide, profil sitter |
| `TlSplitWords` | SplitText + stagger | titres mot par mot |
| `GsapLoop` | `repeat: -1, yoyo: true` | flottement des photos, main qui salue |
| `CountUp` | `gsap.to(obj, { snap })` | total de la réservation |
| `Ease.power3Out`, `backOut`, `elasticOut`… | eases nommées | courbes |
| `GsapPageTransitionsBuilder` | — | transition entre écrans |

Toutes les animations se coupent si le système demande de réduire les animations.

## Notes techniques

- Les animations n'utilisent aucune dépendance : tout est dans `lib/core/motion/gsap.dart`.
- `phosphor_flutter` 2.1.0 ne compile plus avec Flutter 3.44 (sa classe d'icône étend `IconData`,
  devenue `final`). Le paquet fournit encore les polices ; les icônes utilisées sont déclarées
  dans `lib/core/theme/ph_icons.dart`.
- Les polices viennent de `google_fonts` (téléchargées à l'exécution). Pour la production,
  les embarquer dans `assets/` et désactiver `GoogleFonts.config.allowRuntimeFetching`.
- Photos : Unsplash, chargées par URL. Les remplacer par des assets ou un CDN avant publication.
- La carte des résultats est une illustration (`CustomPainter`), à remplacer par un vrai
  fournisseur de cartes.
- Les données sont fictives (`lib/data/sources/`) ; aucun backend. Pour en brancher un, voir le guide, section 9.
