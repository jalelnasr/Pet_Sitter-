# Pet Sitter — comprendre le projet sans rien connaître à Flutter

Ce guide explique, pas à pas, ce que fait l'application, comment elle est construite et où se trouve chaque chose.
Aucune connaissance préalable n'est nécessaire : chaque mot technique est expliqué la première fois qu'il apparaît
(et repris dans le glossaire à la fin).

---

## 1. L'application en deux minutes

**Pet Sitter** met en relation des **propriétaires d'animaux** (chats, chiens, oiseaux, lapins, poissons, petits animaux)
et des **pet sitters**, c'est-à-dire des personnes qui gardent les animaux pendant une absence ou un voyage.
L'interface est en français, les prix en dinars tunisiens (DT), et les exemples se situent à Tunis, La Marsa, Sousse et Sfax.

Ce que l'on peut faire dans l'application :

| Pour le propriétaire | Pour le pet sitter |
|---|---|
| Découvrir l'app (écran de démarrage + guide en 3 écrans) | Voir les demandes reçues, les **accepter** ou les **refuser** |
| Créer un compte ou se connecter | Voir ses gardes à venir |
| Décrire son animal (questions adaptées à l'espèce) | Ouvrir ou bloquer des jours dans son calendrier |
| Chercher un sitter (espèce, quartier, dates, service), en liste ou sur une carte | Modifier ses services et ses tarifs |
| Consulter le profil d'un sitter | Écrire dans le journal de garde |
| Envoyer une demande de réservation avec un devis clair | |
| Suivre la demande : envoyée → en attente → confirmée | |
| Discuter avec le sitter et lire le **journal de garde** (repas, soins, photos) | |
| Acheter nourriture et accessoires dans la **boutique** | |

> Toutes les données (sitters, animaux, produits, messages) sont **fictives** : l'application est une maquette
> fonctionnelle, sans serveur. La section 9 explique comment brancher un vrai serveur plus tard.

---

## 2. Flutter en 5 minutes

### 2.1 Qu'est-ce que Flutter ?

**Flutter** est un outil créé par Google pour fabriquer des applications. On écrit le code **une seule fois**,
et Flutter produit une application **iPhone**, **Android** et **web**. Le langage utilisé s'appelle **Dart**
(il ressemble à Java ou JavaScript).

### 2.2 Tout est « widget »

Dans Flutter, l'écran est construit en **emboîtant des briques**, comme des Lego. Chaque brique s'appelle un **widget** :
un texte, un bouton, une image, une colonne qui empile des éléments, une marge…

```dart
Column(                       // une colonne qui empile ses enfants de haut en bas
  children: [
    Text('Bonjour, Leïla'),   // un texte
    PawButton(                // un bouton de l'application (pilule avec une empreinte)
      label: 'Rechercher un pet sitter',
      onPressed: rechercher,  // ce qui se passe quand on appuie
    ),
  ],
)
```

Un écran entier n'est qu'un grand widget fait de milliers de petits widgets.

### 2.3 Deux sortes de widgets

- **StatelessWidget** (« sans état ») : il affiche toujours la même chose pour les mêmes informations. Exemple : une carte produit.
- **StatefulWidget** (« avec état ») : il peut changer tout seul (un onglet sélectionné, un mot de passe affiché ou masqué…).

L'**état**, ce sont les informations qui peuvent changer pendant qu'on utilise l'écran : les filtres choisis,
le contenu du panier, le texte d'une erreur, « chargement en cours ou non »…

### 2.4 La méthode `build`

Chaque widget possède une méthode `build` qui **décrit** à quoi il ressemble. Quand l'état change, Flutter
rappelle `build` et redessine. On ne dit jamais « change la couleur de ce bouton » : on change l'état,
et l'écran se redessine tout seul à partir de cet état.

### 2.5 Asynchrone : `Future`, `async`, `await`

Certaines actions prennent du temps (envoyer une demande, se connecter). On les écrit avec `async` / `await` :
« lance l'action, attends la réponse sans bloquer l'écran, puis continue ». Une telle action renvoie un `Future`
(une valeur qui arrivera plus tard).

---

## 3. Lancer le projet

1. Installer Flutter : <https://docs.flutter.dev/get-started/install>
2. Ouvrir un terminal dans le dossier `lamma_pets` puis :

```bash
flutter pub get      # télécharge les bibliothèques nécessaires
flutter run          # lance l'app (simulateur iPhone, émulateur Android ou navigateur)
flutter test         # lance les tests automatiques
```

Au lancement : écran de démarrage (logo), puis guide de bienvenue. Un retour arrière depuis le guide ouvre le
**sommaire des maquettes**, qui donne accès direct à chaque écran.

> Astuce : pendant que l'app tourne, enregistrer un fichier met l'écran à jour en une seconde (« hot reload »).

---

## 4. L'architecture MVVM, expliquée simplement

### 4.1 Le problème à résoudre

Si l'on met tout dans les écrans (l'affichage, les calculs, les données), le code devient vite un plat de spaghettis :
impossible de modifier le calcul d'un prix sans risquer de casser l'affichage, impossible de tester la logique
sans ouvrir l'application.

**MVVM** (*Model – View – ViewModel*) range le code en trois couches qui ont chacune **un seul métier**.

### 4.2 L'analogie du restaurant

| Couche | Au restaurant | Dans l'app | Dossier |
|---|---|---|---|
| **View** (vue) | La salle et la carte : ce que voit le client | Les écrans : ils affichent et transmettent les gestes de l'utilisateur | `lib/views/` |
| **ViewModel** | Le serveur : il prend la commande, sait ce qui est disponible, prévient quand c'est prêt | La logique d'un écran : son état et ses actions | `lib/view_models/` |
| **Model** | La cuisine et le garde-manger : les ingrédients et les recettes | Les données et les règles métier (prix, statuts…) | `lib/models/` et `lib/data/` |

Le client (l'utilisateur) ne va jamais en cuisine : il parle au serveur. Le serveur ne cuisine pas :
il demande à la cuisine. Chacun son métier.

### 4.3 Le schéma

```
 ┌──────────────────────────┐   l'utilisateur appuie    ┌──────────────────────────┐
 │          VIEW            │ ────────────────────────▶ │        VIEWMODEL         │
 │   (lib/views/…_screen)   │   vm.ajouterAuPanier()    │  (lib/view_models/…)     │
 │  affiche l'état du VM    │ ◀──────────────────────── │  garde l'état, calcule,  │
 │                          │   notify() : « redessine »│  appelle les dépôts      │
 └──────────────────────────┘                           └────────────┬─────────────┘
                                                                     │ demande / reçoit
                                                                     ▼
                                                        ┌──────────────────────────┐
                                                        │   DÉPÔTS (repositories)  │
                                                        │   lib/data/repositories  │
                                                        │  « où sont les données ? »│
                                                        └────────────┬─────────────┘
                                                                     ▼
                                                        ┌──────────────────────────┐
                                                        │  SOURCES de données      │
                                                        │  lib/data/sources        │
                                                        │  (démo aujourd'hui,      │
                                                        │   serveur demain)        │
                                                        └──────────────────────────┘
        Les MODÈLES (lib/models) sont les « fiches » échangées entre toutes ces couches :
        Sitter, Pet, Booking, Product, BookingQuote…
```

Règles d'or, respectées partout dans le projet :

1. **Une vue ne lit jamais les données directement** : elle passe par son ViewModel.
2. **Un ViewModel ne connaît aucun widget** : pas de couleur, pas de bouton, pas de `BuildContext`.
3. **Les règles métier vivent dans les modèles** (ex. : le calcul d'un devis est dans `BookingQuote`, pas dans l'écran).
4. **La navigation reste dans la vue** : le ViewModel dit « c'est réussi », la vue choisit l'écran suivant.

### 4.4 Une action suivie de bout en bout : « Ajouter au panier »

1. Sur la fiche produit, l'utilisateur appuie sur **Ajouter au panier**
   (vue : `lib/views/shop/shop_screens.dart`, classe `ProductScreen`).
2. La vue appelle `vm.addToCart()` sur son ViewModel `ProductViewModel` (`lib/view_models/shop_view_model.dart`).
3. Le ViewModel demande au dépôt du panier `CartRepository.add(produit, format, quantité)`
   (`lib/data/repositories/cart_repository.dart`).
4. Le dépôt met à jour la liste et appelle `notifyListeners()` : « j'ai changé ! ».
5. Le petit bouton panier en haut de l'écran a son propre ViewModel (`CartViewModel`) qui **écoute** ce dépôt ;
   il reçoit la nouvelle, appelle `notify()`, et la pastille passe de 3 à 4 articles.
6. Aucun écran n'a eu besoin de connaître un autre écran : c'est le dépôt partagé qui fait le lien.

---

## 5. Où se trouve quoi : les dossiers

```
lib/
├── main.dart                  ← point de départ : crée les dépôts et lance l'app
├── app/                       ← l'application dans son ensemble
│   ├── app.dart               ←   thème, langue française, navigation
│   ├── routes.dart            ←   la liste des écrans et leurs adresses (/search, /cart…)
│   └── dependencies.dart      ←   « Deps » : met les dépôts à disposition de tous les écrans
│
├── models/                    ← M : les fiches de données (aucun affichage)
│   ├── species.dart           ←   espèces (chat, chien…) et types de service
│   ├── sitter.dart, pet.dart  ←   un sitter, un animal
│   ├── booking.dart           ←   réservation, statut, et BookingQuote (calcul du devis)
│   ├── message.dart           ←   messages, journal de garde, conversations
│   ├── product.dart           ←   produits de la boutique, lignes de panier
│   ├── pet_form.dart          ←   les questions du formulaire, différentes selon l'espèce
│   ├── search.dart            ←   critères et filtres de recherche
│   ├── sitter_space.dart      ←   demandes reçues, services éditables (espace sitter)
│   └── models.dart            ←   regroupe tout (un seul import à écrire)
│
├── data/                      ← M : d'où viennent les données
│   ├── repositories/          ←   un dépôt par domaine : interface + version de démonstration
│   │   ├── auth_repository.dart          connexion, inscription, mot de passe oublié
│   │   ├── sitter_repository.dart        sitters, recherche, favoris, villes
│   │   ├── pet_repository.dart           animaux de l'utilisateur
│   │   ├── booking_repository.dart       réservations, envoi d'une demande
│   │   ├── message_repository.dart       conversations, journal
│   │   ├── shop_repository.dart          catalogue
│   │   ├── cart_repository.dart          panier (partagé entre plusieurs écrans)
│   │   └── sitter_space_repository.dart  espace sitter
│   └── sources/               ←   les données de démonstration (fictives)
│       ├── mock_data.dart     ←     sitters, animaux, messages, photos
│       └── mock_shop_data.dart ←    produits de la boutique
│
├── view_models/               ← VM : un ViewModel par écran (état + logique)
│   ├── auth_view_model.dart, onboarding_view_model.dart, home_view_model.dart,
│   ├── search_view_model.dart, sitter_profile_view_model.dart, pet_form_view_model.dart,
│   ├── booking_view_model.dart, messages_view_model.dart, shop_view_model.dart,
│   └── sitter_space_view_model.dart, account_view_model.dart
│
├── views/                     ← V : les écrans, rangés par fonctionnalité
│   ├── onboarding/            ←   écran de démarrage, guide de bienvenue
│   ├── auth/                  ←   inscription / connexion, mot de passe oublié, choix du profil
│   ├── owner/                 ←   accueil, recherche, profil sitter, animaux, navigation
│   ├── booking/               ←   demande de réservation, suivi
│   ├── messages/              ←   conversations, journal de garde
│   ├── shop/                  ←   boutique, fiche produit, panier, commande
│   ├── account/               ←   réservations, profil, favoris, notifications, aide, paramètres
│   ├── sitter/                ←   espace pet sitter
│   └── catalog/               ←   sommaire des maquettes et guide de style
│
└── core/                      ← outils partagés par tous les écrans
    ├── mvvm/view_model.dart   ←   le socle MVVM (ViewModel, ViewModelBuilder)
    ├── theme/                 ←   couleurs, polices, icônes
    ├── widgets/               ←   briques réutilisables (boutons, cartes, calendrier, logo…)
    ├── motion/gsap.dart       ←   moteur d'animations
    └── utils/format.dart      ←   dates en français (« ven. 23 oct. »)

test/view_models_test.dart     ← tests automatiques des ViewModels
assets/                        ← logo (et images de l'écran de lancement)
```

---

## 6. Chaque couche, avec du vrai code du projet

> Les extraits sont légèrement raccourcis (« … ») pour la lecture ; le code complet est dans les fichiers indiqués.

### 6.1 Model : une fiche de données et une règle métier

`lib/models/booking.dart` — le devis d'une garde. La règle « supplément par animal + frais de service »
est écrite **une seule fois**, ici :

```dart
class BookingQuote {
  const BookingQuote({required this.unitPrice, required this.units, required this.petCount,
                      this.extraPetFee = 10, this.serviceFee = 8});

  int get base  => unitPrice * units;                                        // 35 DT × 3 nuits = 105
  int get extra => petCount > 1 ? (petCount - 1) * extraPetFee * units : 0;  // 2e animal : 10 × 3 = 30
  int get total => petCount == 0 ? 0 : base + extra + serviceFee;            // 105 + 30 + 8 = 143 DT
}
```

### 6.2 Dépôt (repository) : « où sont les données ? »

Chaque dépôt a deux parties :

- une **interface** (`abstract class`) qui décrit *ce que l'on peut demander* ;
- une **implémentation de démonstration** (`Mock…`) qui répond avec des données fictives et simule les délais.

```dart
abstract class AuthRepository {                          // CE QUE l'app peut demander
  Future<void> logIn({required String email, required String password});
  …
}

class MockAuthRepository implements AuthRepository {     // version de démonstration
  @override
  Future<void> logIn({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 1200));   // simule le réseau
    if (password.length < 8) {
      throw const AuthException('E-mail ou mot de passe incorrect. Il vous reste 4 tentatives.');
    }
  }
}
```

Le jour où un vrai serveur existe, on écrit `ApiAuthRepository implements AuthRepository` :
**aucun écran ni aucun ViewModel ne change**.

### 6.3 ViewModel : l'état et les actions d'un écran

Le socle (`lib/core/mvvm/view_model.dart`) est minuscule :

```dart
abstract class ViewModel extends ChangeNotifier {
  void notify() { if (!_disposed) notifyListeners(); }   // « l'état a changé, redessine »
}
```

Exemple réel, `CartViewModel` (`lib/view_models/shop_view_model.dart`) :

```dart
class CartViewModel extends ViewModel {
  CartViewModel(this._cart) { _cart.addListener(notify); }   // écoute le panier partagé

  int get total => _cart.total;
  int get missingForFreeShipping => CartRepository.freeShippingFrom - subtotal;  // « plus que 3 DT »

  String _payment = 'cash';
  String get payment => _payment;
  void setPayment(String p) { _payment = p; notify(); }     // change l'état puis prévient l'écran

  Future<(int, int)> order() async { … }                    // passe la commande
}
```

Un ViewModel :
- **expose** son état en lecture (`get total`, `get payment`) ;
- **propose des actions** (`setPayment`, `order`) qui modifient l'état puis appellent `notify()` ;
- **n'importe aucun widget** : on peut donc le tester sans écran (section 10).

### 6.4 View : afficher et transmettre

Une vue crée son ViewModel, puis se redessine à chaque `notify()`. Deux façons de faire, toutes deux utilisées :

```dart
// 1) Écran simple : ViewModelBuilder s'occupe de tout (créer, écouter, libérer)
ViewModelBuilder<BookingsViewModel>(
  create: (context) => BookingsViewModel(Deps.of(context).bookings),
  builder: (context, vm) => liste(vm.upcoming, vm.current, vm.past),
);

// 2) Écran avec des outils d'affichage (champs de texte, onglets…) : un State garde le ViewModel
class _CartScreenState extends State<CartScreen> {
  late final vm = CartViewModel(Deps.of(context).cart);

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: vm, builder: (context, _) => _content(context));
  …
  RadioGroup(groupValue: vm.payment, onChanged: (v) => vm.setPayment(v ?? 'cash'))   // lit l'état, transmet le geste
}
```

Ce qui **reste** dans la vue, et c'est voulu :
- les **outils d'affichage** : champs de texte (`TextEditingController`), clés de formulaire, onglets, défilement ;
- l'**état purement visuel et éphémère** : un mot de passe affiché ou masqué, l'onglet choisi dans la barre du bas,
  le cœur « favori » d'une carte. Les recommandations officielles de Flutter le préconisent aussi ;
- la **navigation** vers l'écran suivant.

### 6.5 L'injection des dépendances : `Deps`

`lib/app/dependencies.dart` crée **une seule fois** tous les dépôts au lancement, puis n'importe quel écran
peut les obtenir avec `Deps.of(context)` pour les donner à son ViewModel :

```dart
void main() {
  runApp(Deps.mock(child: const PetSitterApp()));   // aujourd'hui : données de démonstration
}
```

Pour passer à un vrai serveur, on remplacera `Deps.mock(...)` par une version qui crée les dépôts « API ».
C'est le seul endroit à changer.

---

## 7. Tableau des écrans

| Écran | Vue (`lib/views/…`) | ViewModel (`lib/view_models/…`) | Dépôts utilisés |
|---|---|---|---|
| Écran de démarrage | `onboarding/splash_screen.dart` | — (animation pure) | — |
| Guide de bienvenue | `onboarding/onboarding_screen.dart` | `OnboardingViewModel` | — |
| Inscription / connexion | `auth/auth_screens.dart` → `AuthScreen` | `AuthViewModel` | auth |
| Mot de passe oublié | `auth/auth_screens.dart` | `ForgotPasswordViewModel` | auth |
| Choix du profil | `auth/auth_screens.dart` | `RoleChoiceViewModel` | — |
| Accueil | `owner/home_screen.dart` | `HomeViewModel` | sitters, pets, shop, cart |
| Résultats, carte, filtres | `owner/search_screen.dart` | `SearchViewModel` | sitters |
| Profil d'un sitter | `owner/sitter_profile_screen.dart` | `SitterProfileViewModel` | — |
| Ajouter un animal | `owner/pet_screens.dart` → `AddPetScreen` | `PetFormViewModel` | pets |
| Mes animaux | `owner/pet_screens.dart` | `AccountViewModel` | pets, sitters |
| Demande de réservation | `booking/booking_screens.dart` | `BookingRequestViewModel` | bookings, pets |
| Suivi de la demande | `booking/booking_screens.dart` | `BookingStatusViewModel` | bookings |
| Réservations | `account/account_screens.dart` | `BookingsViewModel` | bookings |
| Messages | `messages/messages_screens.dart` | `MessagesViewModel` | messages |
| Conversation + journal | `messages/messages_screens.dart` | `ChatViewModel` | messages, pets, sitterSpace |
| Boutique | `shop/shop_screens.dart` → `ShopScreen` | `ShopViewModel` | shop, pets, cart |
| Fiche produit | `shop/shop_screens.dart` | `ProductViewModel` | cart |
| Panier | `shop/shop_screens.dart` | `CartViewModel` | cart |
| Profil, favoris | `account/account_screens.dart` | `AccountViewModel`, `FavoritesViewModel` | pets, sitters |
| Notifications, paramètres | `account/account_screens.dart` | `NotificationsViewModel`, `SettingsViewModel` | — |
| Espace sitter : tableau de bord | `sitter/sitter_screens.dart` | `SitterDashboardViewModel` | sitterSpace |
| Disponibilités | `sitter/sitter_screens.dart` | `AvailabilityViewModel` | sitterSpace |
| Services et tarifs | `sitter/sitter_screens.dart` | `ServicesPricingViewModel` | sitterSpace |

---

## 8. Le reste de l'application

### 8.1 Navigation (`lib/app/routes.dart`)

Chaque écran a une **adresse** (une « route »), par exemple `/search`, `/sitter`, `/cart`.
Pour ouvrir un écran : `Navigator.pushNamed(context, R.cart)`. Le fichier `routes.dart` fait la correspondance
« adresse → écran ». Sur la version web, ces adresses apparaissent dans l'URL (`…/#/cart`).

Parcours principal : démarrage → guide → inscription → choix du profil → ajout d'un animal → accueil → recherche
→ profil sitter → demande → suivi → messages et journal.

La barre de navigation du propriétaire (Accueil · Boutique · Réservations · Messages · Profil) est dans
`views/owner/owner_shell.dart`.

### 8.2 Apparence (`lib/core/theme/`)

- **Couleurs** dans `app_theme.dart`, classe `LP` : vert du logo `#0F5534`, jaune de l'empreinte `#FABB24`,
  crème `#FFFAF0`, blanc. Changer une couleur ici la change dans toute l'application.
- **Polices** : Outfit (titres) et Urbanist (texte).
- **Icônes** : Phosphor, déclarées dans `ph_icons.dart`.
- Le **guide de style** est visible dans l'app (sommaire → « Guide de style ») : couleurs, boutons, champs, états.

### 8.3 Briques réutilisables (`lib/core/widgets/`)

`PawButton` (bouton pilule avec empreinte), `SpeciesChips` (puces Tous · Chat · Chien…), `LPImage` (image avec
chargement), `MonthCalendar` (calendrier), `FloatingNav` (barre de navigation flottante), `ProductArt`
(emballages dessinés de la boutique), `Wordmark` / `BrandLogo` (logo).

### 8.4 Animations (`lib/core/motion/gsap.dart`)

Les animations s'inspirent de GSAP, une bibliothèque célèbre sur le web (qui ne fonctionne pas dans Flutter).
On en a recréé l'esprit :
- `monWidget.from(y: 30)` : l'élément arrive en glissant de 30 pixels vers le haut ;
- `stagger(i)` : les éléments d'une liste arrivent les uns après les autres ;
- `GsapTimeline` + `Tl(at: 0.4)` : une séquence chorégraphiée (le guide de bienvenue) ;
- `GsapLoop` : un mouvement qui se répète (photos qui flottent, main qui salue).

Si le téléphone demande de réduire les animations (réglage d'accessibilité), elles sont désactivées.

---

## 9. Brancher un vrai serveur plus tard

1. Écrire, pour chaque domaine, une classe qui respecte l'interface du dépôt, par exemple :

   ```dart
   class ApiSitterRepository implements SitterRepository {
     @override
     List<Sitter> all() { … appel au serveur … }
     …
   }
   ```

2. Dans `lib/app/dependencies.dart`, créer une fabrique `Deps.api(...)` qui utilise ces classes.
3. Dans `lib/main.dart`, remplacer `Deps.mock(...)` par `Deps.api(...)`.

Les vues et les ViewModels ne changent pas : c'est tout l'intérêt de l'architecture.
(Un vrai serveur répondant avec un délai, les lectures deviendraient des `Future` ; les ViewModels
afficheraient alors un état « chargement », comme ils le font déjà pour l'envoi d'une demande.)

---

## 10. Les tests

`test/view_models_test.dart` contient 13 tests, lancés avec `flutter test`. Ils vérifient la logique **sans
ouvrir d'écran**, ce qui n'est possible que parce que les ViewModels ne dépendent d'aucun widget. Exemples :

- le devis de 3 nuits à 35 DT pour 2 animaux fait bien **143 DT** ;
- une sitter qui ne garde pas les poissons ne peut pas recevoir Bulle le poisson rouge ;
- le formulaire d'un **poisson** ne pose pas de question de promenade, celui d'un **chien** oui ;
- la livraison devient **offerte** dès 80 DT d'achats ;
- à l'inscription, il faut accepter les conditions.

---

## 11. « Je veux modifier… » : où aller ?

| Je veux… | Fichier |
|---|---|
| Changer une couleur ou une police | `lib/core/theme/app_theme.dart` |
| Changer un texte d'un écran | le fichier de l'écran dans `lib/views/…` |
| Changer un prix, un sitter, un produit de démonstration | `lib/data/sources/mock_data.dart` ou `mock_shop_data.dart` |
| Changer une règle de calcul (frais, supplément) | `lib/models/booking.dart` (`BookingQuote`) |
| Changer le seuil de livraison offerte | `lib/data/repositories/cart_repository.dart` |
| Ajouter une question au formulaire d'un animal | `lib/models/pet_form.dart` |
| Changer le comportement d'un écran (ce qui se passe au clic) | son ViewModel dans `lib/view_models/…` |
| Ajouter un écran | une vue dans `lib/views/…`, un ViewModel si besoin, une route dans `lib/app/routes.dart` |
| Changer le logo | `assets/images/logo_pet_sitter.png` (et `assets/splash/` pour l'écran de lancement) |

**Ajouter un écran, en 4 étapes :**
1. créer le ViewModel (`lib/view_models/mon_ecran_view_model.dart`) : son état + ses actions ;
2. créer la vue (`lib/views/…/mon_ecran.dart`) qui utilise `ViewModelBuilder` ;
3. ajouter une adresse dans `R` et la ligne correspondante dans `onGenerateRoute` (`lib/app/routes.dart`) ;
4. l'ouvrir avec `Navigator.pushNamed(context, R.monEcran)`.

---

## 12. Glossaire

| Mot | Explication simple |
|---|---|
| **Flutter** | Outil de Google pour créer une app iPhone, Android et web avec le même code. |
| **Dart** | Le langage de programmation utilisé par Flutter. |
| **Widget** | Une brique d'interface (texte, bouton, image, colonne…). Un écran est un assemblage de widgets. |
| **État (state)** | Les informations qui peuvent changer pendant l'utilisation (filtres, panier, erreurs…). |
| **build** | La méthode qui décrit l'apparence d'un widget ; Flutter la rappelle quand l'état change. |
| **MVVM** | Organisation du code en trois couches : Model (données), View (écrans), ViewModel (logique d'un écran). |
| **Model** | Les fiches de données et les règles métier (un sitter, un devis…). |
| **View** | Un écran : il affiche l'état et transmet les gestes de l'utilisateur. |
| **ViewModel** | Le « cerveau » d'un écran : il garde l'état, fait les calculs et prévient l'écran quand il faut redessiner. |
| **Dépôt (repository)** | L'endroit unique où l'on demande des données ; il cache leur provenance (démo ou serveur). |
| **Interface (abstract class)** | Un contrat : la liste de ce qu'une classe doit savoir faire, sans dire comment. |
| **Mock** | Une version de démonstration qui imite un vrai service avec de fausses données. |
| **ChangeNotifier / notify** | Un objet qui peut prévenir ceux qui l'écoutent qu'il a changé. |
| **ListenableBuilder / ViewModelBuilder** | Des widgets qui redessinent une partie de l'écran quand le ViewModel prévient d'un changement. |
| **Injection de dépendances** | Donner à chaque ViewModel les dépôts dont il a besoin, au lieu qu'il les crée lui-même (ici avec `Deps`). |
| **Future, async, await** | Écrire une action qui prend du temps (réseau) sans bloquer l'écran. |
| **Route** | L'adresse d'un écran (`/cart`) utilisée pour naviguer. |
| **Hot reload** | Mise à jour quasi instantanée de l'app pendant qu'elle tourne, après avoir enregistré un fichier. |
| **Test unitaire** | Un petit programme qui vérifie automatiquement qu'une partie du code donne le bon résultat. |
