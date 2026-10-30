import 'package:flutter/material.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';

import 'package:pet_sitter/app/routes.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/widgets/common.dart';

/// Sommaire des maquettes : accès direct à chaque écran et à ses états.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  static const _groups = [
    (
      'Parcours principal',
      [
        ('0', 'Écran de démarrage', 'Logo Pet Sitter animé', R.splashPreview),
        ('1', 'Guide · Partez l\'esprit tranquille', 'Écran 1 sur 3, « Passer »', R.onboarding),
        ('1', 'Guide · Une garde adaptée', 'Écran 2 sur 3', R.onboarding2),
        ('1', 'Guide · Gardez le lien', 'Écran 3 : créer un compte ou se connecter', R.onboarding3),
        ('2', 'Inscription', 'E-mail, Apple, Google, chargement', R.signup),
        ('2', 'Inscription · erreurs', 'Validation des champs', R.signupErrors),
        ('2', 'Choix du profil', 'Garde ou pet sitter, modifiable', R.role),
        ('6', 'Ajout d\'un animal', 'Questions adaptées à l\'espèce', R.addPet),
        ('3', 'Accueil propriétaire', 'Recherche, comment ça marche', R.owner),
        ('4', 'Résultats de recherche', 'Liste et filtres', R.search),
        ('5', 'Profil du pet sitter', 'Avis et vérifications présents', R.sitter),
        ('7', 'Demande de réservation', 'Récapitulatif et total en DT', R.booking),
        ('7', 'Demande envoyée', 'Premier état du suivi', R.status),
        ('8', 'Suivi : journal de garde', 'Repas, soins, nouvelles', R.journal),
      ],
    ),
    (
      'Authentification',
      [
        ('2', 'Connexion', 'Afficher le mot de passe', R.login),
        ('2', 'Connexion · erreur', 'Identifiants incorrects', R.loginError),
        ('2', 'Récupération de compte', 'Lien par e-mail', R.forgot),
      ],
    ),
    (
      'Recherche et profils',
      [
        ('4', 'Vue carte', 'Prix épinglés par quartier', R.searchMap),
        ('4', 'Aucun résultat', 'Alternatives utiles', R.searchEmpty),
        ('5', 'Profil d\'un nouveau sitter', 'Sans avis ni vérification', R.sitterNew),
        ('6', 'Profil de l\'animal · chat', 'Simba', R.pet),
        ('6', 'Profil de l\'animal · poisson', 'Bulle et son aquarium', R.petFish),
        ('6', 'Formulaire · poisson', 'Aquarium, eau, matériel', R.addPetFish),
        ('6', 'Formulaire · chien', 'Promenades, comportement', R.addPetDog),
      ],
    ),
    (
      'Réservation et messages',
      [
        ('7', 'En attente de réponse', 'Étape 2 du suivi', R.statusPending),
        ('7', 'Réservation confirmée', 'Étape 3 du suivi', R.statusConfirmed),
        ('8', 'Messages', 'Liste des conversations', R.messages),
        ('8', 'Conversation', 'Texte et photos', R.chat),
      ],
    ),
    (
      'Boutique',
      [
        ('11', 'Boutique', 'Nourriture et accessoires, filtres', R.shop),
        ('11', 'Fiche produit', 'Formats, quantité, livraison', R.product),
        ('11', 'Panier', 'Livraison offerte dès 80 DT', R.cart),
        ('11', 'Commande confirmée', 'Suivi de livraison', R.orderDone),
      ],
    ),
    (
      'États et interactions',
      [
        ('3', 'Accueil · choix du quartier', 'Feuille des villes et quartiers', R.homePlace),
        ('4', 'Recherche · filtres', 'Budget, distance, espèces, disponibilité', R.searchFilters),
        ('4', 'Recherche · chien', 'Autres résultats selon l\'espèce', R.searchDog),
        ('5', 'Sitter en visites seulement', 'Sans lieu d\'accueil', R.sitterVisitsOnly),
        ('6', 'Ajout d\'un animal · première fois', 'Étape 2 sur 2 après l\'inscription', R.addPetFirst),
        ('6', 'Formulaire · oiseau', 'Cage, sorties, fruits frais', R.addPetBird),
        ('6', 'Formulaire · lapin', 'Foin, habitat, manipulation', R.addPetRabbit),
        ('6', 'Formulaire · petit animal', 'Hamster, tortue…', R.addPetOther),
        ('6', 'Profil de l\'animal · oiseau', 'Kiwi', R.petBird),
        ('7', 'Réservation · calendrier', 'Choix des dates', R.bookingDates),
        ('7', 'Réservation · visites', 'Visites par jour, devis recalculé', R.bookingVisits),
        ('2', 'Choix du profil · sélectionné', 'Bouton Continuer actif', R.roleChosen),
        ('2', 'Mot de passe oublié · envoyé', 'Confirmation', R.forgotSent),
        ('8', 'Conversation · vue sitter', 'Côté pet sitter', R.chatSitter),
        ('8', 'Journal · ajouter une entrée', 'Types adaptés aux animaux', R.journalAdd),
        ('11', 'Boutique · nourriture', 'Filtre par catégorie', R.shopFood),
        ('11', 'Produit en promotion', 'Prix barré, formats', R.productPromo),
        ('11', 'Produit accessoire', 'Choix du modèle', R.productAccessory),
        ('11', 'Panier vide', 'État vide', R.cartEmpty),
        ('10', 'Sitter · refuser une demande', 'Choix du motif', R.sitterRefuse),
        ('10', 'Sitter · demande acceptée', 'Confirmation', R.sitterAccepted),
        ('10', 'Sitter · onglet calendrier', 'Disponibilités', R.sitterCalendar),
        ('10', 'Sitter · onglet messages', 'Conversations', R.sitterMessages),
        ('10', 'Sitter · onglet profil', 'Compte du sitter', R.sitterAccount),
      ],
    ),
    (
      'Réservations et compte',
      [
        ('9', 'Réservations', 'À venir, en cours, passées', R.bookings),
        ('9', 'Profil', 'Compte et changement de rôle', R.account),
        ('9', 'Mes animaux', '', R.myPets),
        ('9', 'Favoris', '', R.favorites),
        ('9', 'Notifications', 'Historique et préférences', R.notifications),
        ('9', 'Aide', 'FAQ et contact', R.help),
        ('9', 'Paramètres', 'Langue, confidentialité', R.settings),
      ],
    ),
    (
      'Espace pet sitter',
      [
        ('10', 'Tableau de bord', 'Accepter ou refuser les demandes', R.sitterSpace),
        ('10', 'Calendrier de disponibilité', 'Bloquer ou ouvrir des jours', R.availability),
        ('10', 'Services et tarifs', 'Prix et espèces acceptées', R.services),
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
                    'La garde d\'animaux entre voisins, en Tunisie : chats, chiens, oiseaux, lapins, poissons et petits animaux. Touchez un écran pour l\'ouvrir.',
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
