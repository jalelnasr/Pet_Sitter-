/// Données de l'espace pet sitter : demandes reçues et services proposés.
library;

import 'package:flutter/widgets.dart';

enum RequestState { pending, accepted, refused }

/// Une demande de garde reçue par le sitter.
class SitterRequest {
  SitterRequest({
    required this.owner,
    required this.ownerPhoto,
    required this.pets,
    required this.petPhoto,
    required this.service,
    required this.dates,
    required this.earn,
    required this.message,
    required this.received,
  });

  final String owner;
  final String ownerPhoto;
  final String pets;
  final String petPhoto;
  final String service;
  final String dates;
  final int earn;
  final String message;
  final String received;
  RequestState state = RequestState.pending;
}

/// Une garde à venir dans l'agenda du sitter.
class UpcomingCare {
  const UpcomingCare(this.photo, this.pets, this.who, this.when, {this.live = false});
  final String photo;
  final String pets;
  final String who;
  final String when;
  final bool live;
}

/// Un service que le sitter peut activer et dont il fixe le prix.
class EditableService {
  EditableService(this.icon, this.name, this.detail, this.price, this.unit, this.on);
  final IconData icon;
  final String name;
  final String detail;
  int price;
  final String unit;
  bool on;
}
