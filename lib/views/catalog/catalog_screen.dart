import 'package:flutter/material.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';

import 'package:pet_sitter/app/routes.dart';
import 'package:pet_sitter/petsitter/petsitter_routes.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/widgets/common.dart';

/// Sommaire des maquettes : accÃ¨s direct Ã  chaque Ã©cran et Ã  ses Ã©tats.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  static const _groups = [
    (
      'Parcours principal',
      [
        ('0', 'Ã‰cran de dÃ©marrage', 'Logo Pet Sitter animÃ©', R.splashPreview),
        ('1', 'Guide Â· Partez l\'esprit tranquille', 'Ã‰cran 1 sur 3, Â« Passer Â»', R.onboarding),
        ('1', 'Guide Â· Une garde adaptÃ©e', 'Ã‰cran 2 sur 3', R.onboarding2),
        ('1', 'Guide Â· Gardez le lien', 'Ã‰cran 3 : crÃ©er un compte ou se connecter', R.onboarding3),
        ('2', 'Inscription', 'E-mail, Apple, Google, chargement', R.signup),
        ('2', 'Inscription Â· erreurs', 'Validation des champs', R.signupErrors),
        ('2', 'Choix du profil', 'Garde ou pet sitter, modifiable', R.role),
        ('6', 'Ajout d\'un animal', 'Questions adaptÃ©es Ã  l\'espÃ¨ce', R.addPet),
        ('3', 'Accueil propriÃ©taire', 'Recherche, comment Ã§a marche', R.owner),
        ('4', 'RÃ©sultats de recherche', 'Liste et filtres', R.search),
        ('5', 'Profil du pet sitter', 'Avis et vÃ©rifications prÃ©sents', R.sitter),
        ('7', 'Demande de rÃ©servation', 'RÃ©capitulatif et total en DT', R.booking),
        ('7', 'Demande envoyÃ©e', 'Premier Ã©tat du suivi', R.status),
        ('8', 'Suivi : journal de garde', 'Repas, soins, nouvelles', R.journal),
      ],
    ),
    (
      'Authentification',
      [
        ('2', 'Connexion', 'Afficher le mot de passe', R.login),
        ('2', 'Connexion Â· erreur', 'Identifiants incorrects', R.loginError),
        ('2', 'RÃ©cupÃ©ration de compte', 'Lien par e-mail', R.forgot),
      ],
    ),
    (
      'Recherche et profils',
      [
        ('4', 'Vue carte', 'Prix Ã©pinglÃ©s par quartier', R.searchMap),
        ('4', 'Aucun rÃ©sultat', 'Alternatives utiles', R.searchEmpty),
        ('5', 'Profil d\'un nouveau sitter', 'Sans avis ni vÃ©rification', R.sitterNew),
        ('6', 'Profil de l\'animal Â· chat', 'Simba', R.pet),
        ('6', 'Profil de l\'animal Â· poisson', 'Bulle et son aquarium', R.petFish),
        ('6', 'Formulaire Â· poisson', 'Aquarium, eau, matÃ©riel', R.addPetFish),
        ('6', 'Formulaire Â· chien', 'Promenades, comportement', R.addPetDog),
      ],
    ),
    (
      'RÃ©servation et messages',
      [
        ('7', 'En attente de rÃ©ponse', 'Ã‰tape 2 du suivi', R.statusPending),
        ('7', 'RÃ©servation confirmÃ©e', 'Ã‰tape 3 du suivi', R.statusConfirmed),
        ('8', 'Messages', 'Liste des conversations', R.messages),
        ('8', 'Conversation', 'Texte et photos', R.chat),
      ],
    ),
    (
      'Boutique',
      [
        ('11', 'Boutique', 'Nourriture et accessoires, filtres', R.shop),
        ('11', 'Fiche produit', 'Formats, quantitÃ©, livraison', R.product),
        ('11', 'Panier', 'Livraison offerte dÃ¨s 80 DT', R.cart),
        ('11', 'Commande confirmÃ©e', 'Suivi de livraison', R.orderDone),
      ],
    ),
    (
      'Ã‰tats et interactions',
      [
        ('3', 'Accueil Â· choix du quartier', 'Feuille des villes et quartiers', R.homePlace),
        ('4', 'Recherche Â· filtres', 'Budget, distance, espÃ¨ces, disponibilitÃ©', R.searchFilters),
        ('4', 'Recherche Â· chien', 'Autres rÃ©sultats selon l\'espÃ¨ce', R.searchDog),
        ('5', 'Sitter en visites seulement', 'Sans lieu d\'accueil', R.sitterVisitsOnly),
        ('6', 'Ajout d\'un animal Â· premiÃ¨re fois', 'Ã‰tape 2 sur 2 aprÃ¨s l\'inscription', R.addPetFirst),
        ('6', 'Formulaire Â· oiseau', 'Cage, sorties, fruits frais', R.addPetBird),
        ('6', 'Formulaire Â· lapin', 'Foin, habitat, manipulation', R.addPetRabbit),
        ('6', 'Formulaire Â· petit animal', 'Hamster, tortueâ€¦', R.addPetOther),
        ('6', 'Profil de l\'animal Â· oiseau', 'Kiwi', R.petBird),
        ('7', 'RÃ©servation Â· calendrier', 'Choix des dates', R.bookingDates),
        ('7', 'RÃ©servation Â· visites', 'Visites par jour, devis recalculÃ©', R.bookingVisits),
        ('2', 'Choix du profil Â· sÃ©lectionnÃ©', 'Bouton Continuer actif', R.roleChosen),
        ('2', 'Mot de passe oubliÃ© Â· envoyÃ©', 'Confirmation', R.forgotSent),
        ('8', 'Conversation Â· vue sitter', 'CÃ´tÃ© pet sitter', R.chatSitter),
        ('8', 'Journal Â· ajouter une entrÃ©e', 'Types adaptÃ©s aux animaux', R.journalAdd),
        ('11', 'Boutique Â· nourriture', 'Filtre par catÃ©gorie', R.shopFood),
        ('11', 'Produit en promotion', 'Prix barrÃ©, formats', R.productPromo),
        ('11', 'Produit accessoire', 'Choix du modÃ¨le', R.productAccessory),
        ('11', 'Panier vide', 'Ã‰tat vide', R.cartEmpty),
        ('10', 'Sitter Â· refuser une demande', 'Choix du motif', R.sitterRefuse),
        ('10', 'Sitter Â· demande acceptÃ©e', 'Confirmation', R.sitterAccepted),
        ('10', 'Sitter Â· onglet calendrier', 'DisponibilitÃ©s', R.sitterCalendar),
        ('10', 'Sitter Â· onglet messages', 'Conversations', R.sitterMessages),
        ('10', 'Sitter Â· onglet profil', 'Compte du sitter', R.sitterAccount),
      ],
    ),
    (
      'RÃ©servations et compte',
      [
        ('9', 'RÃ©servations', 'Ã€ venir, en cours, passÃ©es', R.bookings),
        ('9', 'Profil', 'Compte et changement de rÃ´le', R.account),
        ('9', 'Mes animaux', '', R.myPets),
        ('9', 'Favoris', '', R.favorites),
        ('9', 'Notifications', 'Historique et prÃ©fÃ©rences', R.notifications),
        ('9', 'Aide', 'FAQ et contact', R.help),
        ('9', 'ParamÃ¨tres', 'Langue, confidentialitÃ©', R.settings),
      ],
    ),
    (
      'Espace pet sitter',
      [
        ('10', 'Tableau de bord', 'Accepter ou refuser les demandes', R.sitterSpace),
        ('10', 'Calendrier de disponibilitÃ©', 'Bloquer ou ouvrir des jours', R.availability),
        ('10', 'Services et tarifs', 'Prix et espÃ¨ces acceptÃ©es', R.services),
      ],
    ),
    (
      'Module 2 Â· Pet Sitter & RÃ©servation (Complet)',
      [
        ('2', 'Recherche Sitters (Spring Boot)', 'Filtres, tri, pagination, API rÃ©elle', PetsitterRoutes.list),
        ('2', 'Mes RÃ©servations', 'Cycle de vie, annulation, avis en fin de garde', PetsitterRoutes.myReservations),
        ('2', 'Espace Pet Sitter (Samira)', 'Demandes reÃ§ues, accepter / refuser / terminer', PetsitterRoutes.sitterDashboard),
        ('2', 'Administration Sitters & RÃ©servations', 'Validation, modÃ©ration, mÃ©triques rÃ©elles', PetsitterRoutes.adminSitters),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Wordmark(size: 24),
                  const SizedBox(height: 22),
                  Text('Maquettes de l\'application', style: LPText.h1),
                  const SizedBox(height: 10),
                  Text(
                    'La garde d\'animaux entre voisins, en Tunisie : chats, chiens, oiseaux, lapins, poissons et petits animaux. Touchez un Ã©cran pour l\'ouvrir.',
                    style: LPText.bodyL.copyWith(color: LP.muted),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pushNamed(context, R.splash),
                      icon: const Icon(PhosphorIconsBold.play, size: 18),
                      label: const Text('Lancer le parcours complet'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, R.styleGuide),
                      icon: const Icon(PhosphorIconsRegular.palette, size: 20),
                      label: const Text('Guide de style'),
                    ),
                  ),
                ],
              ),
            ),
            for (final (title, items) in _groups) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 6),
                child: Text(title.toUpperCase(), style: LPText.overline),
              ),
              for (final (num, name, sub, route) in items)
                InkWell(
                  onTap: () => Navigator.pushNamed(context, route),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: title == 'Parcours principal' ? LP.primary : LP.mintPale,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            num,
                            style: LPText.body(
                              size: 13,
                              w: FontWeight.w700,
                              color: title == 'Parcours principal' ? LP.white : LP.primary,
                              height: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: LPText.body(size: 15.5, w: FontWeight.w600, height: 1.3)),
                              if (sub.isNotEmpty) Text(sub, style: LPText.bodyS.copyWith(fontSize: 13)),
                            ],
                          ),
                        ),
                        const Icon(PhosphorIconsRegular.caretRight, size: 18, color: LP.muted),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
