import 'package:flutter/widgets.dart';

import 'package:pet_sitter/models/models.dart';

/// Photos : Unsplash (licence libre). Tous les profils sont des exemples fictifs.
String unsplash(String id, {int w = 600, int? h}) =>
    'https://images.unsplash.com/photo-$id?w=$w${h != null ? '&h=$h' : ''}&q=70&fm=jpg&fit=crop';

class Photos {
  Photos._();
  // Animaux
  static final catOrange = unsplash('1573865526739-10659fec78a5');
  static final catTuxedo = unsplash('1514888286974-6c03e2ca1dba');
  static final catTabby = unsplash('1574158622682-e40e69881006');
  static final catNap = unsplash('1519052537078-e6302a4968d4');
  static final catWhite = unsplash('1606214174585-fe31582dc6ee');
  static final catHand = unsplash('1513360371669-4adf3dd7dff8');
  static final kitten = unsplash('1529778873920-4da4926a72c2');
  static final dogBeagle = unsplash('1543466835-00a7907e9de1');
  static final dogAussie = unsplash('1587300003388-59208cc962cb');
  static final dogsDuo = unsplash('1548199973-03cce0bbc87b');
  static final dogCavalier = unsplash('1560807707-8cc77767d783');
  static final lovebird = unsplash('1552728089-57bdde30beb3');
  static final canary = unsplash('1591198936750-16d8e15edb9e');
  static final rabbitWhite = unsplash('1585110396000-c9ffd4e4b308');
  static final rabbitLop = unsplash('1452857297128-d9c29adba80b');
  static final rabbitPie = unsplash('1535241749838-299277b6305f');
  static final goldfish = unsplash('1522069169874-c58ec4b76be5');
  static final clownfish = unsplash('1535591273668-578e31182c4f');
  static final hamster = unsplash('1425082661705-1834bfd09dca');
  static final guineaPigs = unsplash('1548767797-d8c844163c4c');
  static final catAndDog = unsplash('1450778869180-41d0601e046e');

  // Personnes
  static final amira = unsplash('1494790108377-be9c29b29330', w: 400);
  static final youssef = unsplash('1507003211169-0a1dd7228f2d', w: 400);
  static final salma = unsplash('1438761681033-6461ffad8d80', w: 400);
  static final mehdi = unsplash('1500648767791-00dcc994a43e', w: 400);
  static final ines = unsplash('1531123897727-8f129e1688ce', w: 400);
  static final nour = unsplash('1544005313-94ddf0286df2', w: 400);
  static final leila = unsplash('1534528741775-53994a69daeb', w: 400);

  // Lieux d'accueil
  static final livingPlants = unsplash('1502672260266-1c1ef2d93688', w: 900);
  static final livingBright = unsplash('1493809842364-78817add7ffb', w: 900);
  static final livingYellow = unsplash('1586023492125-27b2c045efd7', w: 900);
  static final bedroom = unsplash('1505693416388-ac5ce068fe85', w: 900);
  static final kitchen = unsplash('1484154218962-a197022b5858', w: 900);
  static final villa = unsplash('1600585154340-be6161a56a0c', w: 900);
}

class Mock {
  Mock._();

  static const ownerFirstName = 'Leïla';
  static const ownerFullName = 'Leïla Ben Salah';

  static const cities = [
    ('La Marsa', 'Tunis'),
    ('Carthage', 'Tunis'),
    ('Lac 2', 'Tunis'),
    ('Menzah 6', 'Ariana'),
    ('Ennasr', 'Ariana'),
    ('Centre-ville', 'Tunis'),
    ('Khezama', 'Sousse'),
    ('Sahloul', 'Sousse'),
    ('Route de l\'Aïn', 'Sfax'),
    ('Hammamet Nord', 'Nabeul'),
  ];

  static final amira = Sitter(
    id: 'amira',
    firstName: 'Amira',
    lastInitial: 'B.',
    area: 'La Marsa',
    city: 'Tunis',
    distanceKm: 1.2,
    photo: Photos.amira,
    homePhotos: [Photos.livingPlants, Photos.livingBright, Photos.bedroom],
    species: const [Species.chat, Species.lapin, Species.oiseau, Species.autre],
    services: const [
      SitterService(
        ServiceType.accueil,
        'Accueil chez Amira',
        'Pension à la journée et la nuit, dans son appartement',
        35,
        'nuit',
      ),
      SitterService(
        ServiceType.visite,
        'Visite à domicile',
        '30 min : repas, litière ou cage, câlins et photos',
        18,
        'visite',
      ),
    ],
    mainService: ServiceType.accueil,
    yearsExperience: 6,
    bio:
        'Ancienne assistante dans une clinique vétérinaire de La Marsa, je travaille aujourd\'hui depuis chez moi. '
        'Mon appartement est calme, avec un balcon entièrement sécurisé. J\'envoie des photos chaque jour, '
        'sans que vous ayez à les demander.',
    experience: const [
      '3 ans en clinique vétérinaire (assistante)',
      'Administration de médicaments et gouttes',
      'Habituée aux chats craintifs et aux lapins âgés',
    ],
    homeFacts: const [
      'Appartement de 95 m² au 2ᵉ étage',
      'Balcon sécurisé par un filet',
      'Pas d\'autre animal à la maison',
      'Pas d\'enfants · non-fumeuse',
    ],
    verifications: const ['Identité vérifiée', 'Téléphone vérifié', 'Adresse confirmée'],
    rating: 4.9,
    reviewCount: 23,
    reviews: const [
      Review(
        'Sarra',
        'Chat · Mimi',
        'Septembre 2026',
        5,
        'Mimi est très timide et Amira a su la mettre en confiance en deux jours. Photos tous les matins, je suis partie à Djerba sereine.',
      ),
      Review(
        'Karim',
        'Lapin · Noisette',
        'Août 2026',
        5,
        'Très attentive au foin et aux légumes frais. Noisette est revenu en pleine forme.',
      ),
      Review(
        'Olfa',
        'Perruches · Zaza et Lulu',
        'Juillet 2026',
        5,
        'Cage nettoyée, eau changée, et même une petite vidéo des chants. Je recommande.',
      ),
    ],
    responseTime: 'Répond en général en moins de 2 h',
    mapPos: const Offset(0.62, 0.30),
  );

  static final youssef = Sitter(
    id: 'youssef',
    firstName: 'Youssef',
    lastInitial: 'K.',
    area: 'Lac 2',
    city: 'Tunis',
    distanceKm: 6.8,
    photo: Photos.youssef,
    homePhotos: [Photos.villa, Photos.livingYellow],
    species: const [Species.chien, Species.chat],
    services: const [
      SitterService(ServiceType.visite, 'Visite à domicile', '45 min avec promenade pour les chiens', 22, 'visite'),
      SitterService(ServiceType.accueil, 'Accueil chez Youssef', 'Maison avec jardin clos de 200 m²', 45, 'nuit'),
    ],
    mainService: ServiceType.visite,
    yearsExperience: 4,
    bio:
        'Éducateur canin le week-end, je promène et garde chiens et chats depuis 4 ans. Jardin clos, horaires souples.',
    experience: const ['Éducation canine positive', 'Chiens de grande taille', 'Promenades en groupe'],
    homeFacts: const ['Maison avec jardin clos', 'Un chien calme à la maison (Rocky)'],
    verifications: const ['Identité vérifiée'],
    rating: 4.8,
    reviewCount: 11,
    reviews: const [Review('Hela', 'Chien · Oscar', 'Octobre 2026', 5, 'Ponctuel, rassurant, Oscar l\'adore.')],
    responseTime: 'Répond en général dans la journée',
    mapPos: const Offset(0.36, 0.62),
  );

  static final salma = Sitter(
    id: 'salma',
    firstName: 'Salma',
    lastInitial: 'M.',
    area: 'Carthage',
    city: 'Tunis',
    distanceKm: 3.4,
    photo: Photos.salma,
    homePhotos: [Photos.livingBright, Photos.kitchen],
    species: const [Species.oiseau, Species.poisson, Species.autre, Species.lapin],
    services: const [
      SitterService(
        ServiceType.visite,
        'Visite à domicile',
        '20 min : nourriture, eau, contrôle de l\'aquarium',
        15,
        'visite',
      ),
    ],
    mainService: ServiceType.visite,
    yearsExperience: 8,
    bio:
        'Passionnée d\'aquariophilie et d\'oiseaux depuis l\'enfance. Je connais bien les besoins des NAC et des aquariums d\'eau douce.',
    experience: const [
      'Aquariums d\'eau douce et d\'eau de mer',
      'Oiseaux de cage et de volière',
      'Hamsters et cochons d\'Inde',
    ],
    homeFacts: const ['Visites uniquement'],
    verifications: const ['Identité vérifiée', 'Téléphone vérifié'],
    rating: 5.0,
    reviewCount: 7,
    reviews: const [
      Review(
        'Nizar',
        'Poissons · aquarium 120 L',
        'Août 2026',
        5,
        'Paramètres de l\'eau notés à chaque passage. Parfait.',
      ),
    ],
    responseTime: 'Répond en général en moins d\'1 h',
    mapPos: const Offset(0.74, 0.52),
  );

  static final ines = Sitter(
    id: 'ines',
    firstName: 'Inès',
    lastInitial: 'H.',
    area: 'Gammarth',
    city: 'Tunis',
    distanceKm: 2.6,
    photo: Photos.ines,
    homePhotos: [Photos.livingYellow, Photos.bedroom],
    species: const [Species.chat],
    services: const [
      SitterService(ServiceType.accueil, 'Accueil chez Inès', 'Chats uniquement, une famille à la fois', 30, 'nuit'),
      SitterService(ServiceType.visite, 'Visite à domicile', '30 min', 16, 'visite'),
    ],
    mainService: ServiceType.accueil,
    yearsExperience: 3,
    bio: 'Je n\'accueille qu\'une famille de chats à la fois pour qu\'ils restent tranquilles.',
    experience: const ['Chats âgés et diabétiques'],
    homeFacts: const ['Appartement calme, fenêtres sécurisées'],
    verifications: const ['Identité vérifiée'],
    rating: 4.7,
    reviewCount: 5,
    reviews: const [Review('Mouna', 'Chat · Pacha', 'Juin 2026', 5, 'Très douce et organisée.')],
    responseTime: 'Répond en général en moins de 3 h',
    mapPos: const Offset(0.50, 0.18),
  );

  /// Nouveau sitter : pas d'avis ni de vérification → sections masquées.
  static final mehdi = Sitter(
    id: 'mehdi',
    firstName: 'Mehdi',
    lastInitial: 'T.',
    area: 'La Marsa Plage',
    city: 'Tunis',
    distanceKm: 0.9,
    photo: Photos.mehdi,
    homePhotos: [Photos.livingPlants],
    species: const [Species.chien, Species.chat, Species.lapin],
    services: const [
      SitterService(
        ServiceType.accueil,
        'Accueil chez Mehdi',
        'Appartement avec terrasse, proche de la plage',
        28,
        'nuit',
      ),
      SitterService(ServiceType.visite, 'Visite à domicile', '30 min', 14, 'visite'),
    ],
    mainService: ServiceType.accueil,
    yearsExperience: 2,
    bio: 'Étudiant en médecine vétérinaire à Sidi Thabet, j\'ai grandi avec deux chiens et un lapin.',
    experience: const ['Étudiant vétérinaire (4ᵉ année)'],
    homeFacts: const ['Terrasse clôturée', 'Pas d\'autre animal'],
    responseTime: 'Nouveau sur Pet Sitter',
    mapPos: const Offset(0.70, 0.38),
  );

  static final nour = Sitter(
    id: 'nour',
    firstName: 'Nour',
    lastInitial: 'S.',
    area: 'Menzah 6',
    city: 'Ariana',
    distanceKm: 9.5,
    photo: Photos.nour,
    homePhotos: [Photos.livingBright],
    species: const [Species.chien, Species.chat, Species.oiseau],
    services: const [
      SitterService(ServiceType.accueil, 'Accueil chez Nour', 'Villa avec jardin', 40, 'nuit'),
      SitterService(ServiceType.visite, 'Visite à domicile', '30 min', 20, 'visite'),
    ],
    mainService: ServiceType.accueil,
    yearsExperience: 5,
    bio: 'Maison familiale avec grand jardin, idéale pour les chiens actifs.',
    experience: const ['Chiens actifs', 'Oiseaux'],
    homeFacts: const ['Villa avec jardin clos'],
    verifications: const ['Identité vérifiée', 'Téléphone vérifié'],
    rating: 4.9,
    reviewCount: 31,
    reviews: const [Review('Amine', 'Chien · Rex', 'Mai 2026', 5, 'Rex a adoré le jardin.')],
    responseTime: 'Répond en général en moins de 2 h',
    mapPos: const Offset(0.22, 0.40),
  );

  static final sitters = [amira, mehdi, ines, salma, youssef, nour];

  static final simba = Pet(
    id: 'simba',
    name: 'Simba',
    species: Species.chat,
    breed: 'Européen roux',
    age: '4 ans',
    sex: 'Mâle stérilisé',
    photo: Photos.catOrange,
    food: const {
      'Nourriture': 'Croquettes stérilisé + 1 sachet le soir',
      'Quantité': '40 g matin et soir',
      'Eau': 'Fontaine, à remplir tous les 2 jours',
    },
    habits: const {
      'Mode de vie': 'Chat d\'intérieur',
      'Litière': 'Agglomérante, nettoyée chaque jour',
      'Sommeil': 'Dort sur le canapé, au soleil l\'après-midi',
    },
    behavior: const ['Câlin', 'Un peu craintif au début', 'Ne s\'entend pas avec les chiens'],
    care: 'Gouttes oculaires 1 fois par jour (le matin) jusqu\'au 30 octobre.',
    vet: 'Dr Hamdi · Clinique des Berges du Lac · 71 000 000',
  );

  static final kiwi = Pet(
    id: 'kiwi',
    name: 'Kiwi',
    species: Species.oiseau,
    breed: 'Inséparable à face rose',
    age: '2 ans',
    sex: 'Femelle',
    photo: Photos.lovebird,
    food: const {
      'Nourriture': 'Mélange de graines pour inséparables',
      'Frais': 'Pomme ou carotte, 3 fois par semaine',
      'Eau': 'À changer chaque jour',
    },
    habits: const {
      'Cage': '60 × 40 cm, loin des courants d\'air',
      'Sorties': 'Vol libre 1 h le soir, fenêtres fermées',
      'Nuit': 'Couvrir la cage vers 21 h',
    },
    behavior: const ['Bavarde le matin', 'Pince quand on l\'attrape'],
    care: 'Aucun soin particulier.',
  );

  static final bulle = Pet(
    id: 'bulle',
    name: 'Bulle',
    species: Species.poisson,
    breed: 'Poisson rouge (et 3 compagnons)',
    age: '1 an',
    sex: '—',
    photo: Photos.goldfish,
    food: const {'Nourriture': 'Flocons, une pincée', 'Fréquence': '1 fois par jour, le matin'},
    habits: const {
      'Aquarium': 'Eau douce · 60 L · 22 °C',
      'Éclairage': 'Programmé de 9 h à 19 h',
      'Entretien': 'Ne pas changer l\'eau pendant la garde',
    },
    behavior: const [],
    care: 'Vérifier que le filtre fonctionne (bruit léger normal).',
  );

  static final pets = [simba, kiwi, bulle];

  static final bookings = [
    Booking('b1', amira, [simba, kiwi], ServiceType.accueil, 'Ven. 23 → lun. 26 oct.', 143, BookingStatus.enCours),
    Booking(
      'b2',
      salma,
      [bulle],
      ServiceType.visite,
      'Ven. 23 → lun. 26 oct. · 3 visites',
      53,
      BookingStatus.confirmee,
    ),
    Booking('b3', ines, [simba], ServiceType.accueil, 'Ven. 18 → lun. 21 déc.', 98, BookingStatus.attente),
    Booking('b4', amira, [simba], ServiceType.accueil, 'Jeu. 13 → dim. 16 août', 113, BookingStatus.terminee),
    Booking('b5', youssef, [simba], ServiceType.visite, 'Sam. 4 → lun. 6 juil.', 74, BookingStatus.annulee),
  ];

  static const chat = [
    ChatMessage(false, MsgKind.system, 'Réservation confirmée · Accueil du ven. 23 au lun. 26 octobre', ''),
    ChatMessage(
      true,
      MsgKind.text,
      'Bonjour Amira ! Je vous dépose Simba et Kiwi vendredi vers 18 h, ça vous convient ?',
      '09:12',
    ),
    ChatMessage(
      false,
      MsgKind.text,
      'Parfait, je serai là. Pensez aux gouttes de Simba et à la housse de la cage 🙂',
      '09:20',
    ),
    ChatMessage(false, MsgKind.system, 'Garde commencée · ven. 23 octobre, 18:05', ''),
    ChatMessage(
      false,
      MsgKind.text,
      'Bonne nouvelle : Simba a mangé toute sa gamelle ce matin et il a déjà trouvé le coin soleil.',
      '08:41',
    ),
    ChatMessage(false, MsgKind.photo, 'Sieste sur le canapé', '08:42', photo: 'catNap'),
    ChatMessage(true, MsgKind.text, 'Merci, ça me rassure beaucoup ! Et Kiwi ?', '08:50'),
    ChatMessage(false, MsgKind.text, 'Elle chante depuis 7 h 😄 Graines et pomme ok, eau changée.', '08:53'),
  ];

  static final journal = <String, List<LogEntry>>{
    'Aujourd\'hui · samedi 24 octobre': [
      LogEntry(
        LogKind.repas,
        '08:10',
        'Petit-déjeuner',
        'Simba : 40 g de croquettes · Kiwi : graines + quartier de pomme',
      ),
      LogEntry(LogKind.soins, '08:20', 'Gouttes oculaires', 'Simba · 1 goutte dans chaque œil, bien acceptées'),
      LogEntry(
        LogKind.nouvelles,
        '08:42',
        'Sieste au soleil',
        'Simba a trouvé son coin préféré près du balcon.',
        photo: Photos.catNap,
      ),
      LogEntry(LogKind.nettoyage, '10:30', 'Cage de Kiwi', 'Fond changé, eau fraîche, perchoirs nettoyés'),
      LogEntry(LogKind.repas, '19:00', 'Dîner', 'Simba : sachet + croquettes', done: false),
    ],
    'Hier · vendredi 23 octobre': [
      LogEntry(
        LogKind.visite,
        '18:05',
        'Arrivée chez Amira',
        'Simba explore prudemment, Kiwi installée dans le salon.',
      ),
      LogEntry(LogKind.repas, '19:30', 'Dîner', 'Simba a mangé la moitié — normal le premier soir.'),
    ],
  };

  static const howItWorks = [
    ('Présentez votre animal', 'Habitudes, repas, soins : son profil suit chaque demande.'),
    ('Choisissez votre sitter', 'Comparez les profils près de chez vous et échangez avant de réserver.'),
    ('Recevez des nouvelles', 'Messages, photos et journal de garde au quotidien.'),
  ];
}

String photoByKey(String key) => switch (key) {
  'catNap' => Photos.catNap,
  _ => Photos.catOrange,
};
