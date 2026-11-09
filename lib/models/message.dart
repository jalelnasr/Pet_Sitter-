/// Messages de la conversation et entrées du journal de garde.
library;

import 'package:flutter/widgets.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';

enum MsgKind { text, photo, system }

/// État d'envoi d'un message écrit depuis l'appareil.
enum MsgStatus { sent, sending, failed }

/// Évaluation de l'assistant IA : arnaque ou insulte (élevé), paiement externe ou coordonnées (faible).
enum MsgRisk { none, low, high }

class ChatMessage {
  /// Vrai si le message a été envoyé par l'utilisateur courant.
  final bool mine;
  final MsgKind kind;
  final String text;

  /// Heure affichée sous la bulle (« 08:50 »).
  final String time;
  final String? photo;

  /// Identifiant serveur (nul tant que le message n'est pas enregistré).
  final String? id;
  final DateTime? sentAt;

  /// Lu par le destinataire (pour mes messages).
  final bool read;
  final MsgStatus status;

  /// Risque détecté par l'assistant IA, et son explication lisible.
  final MsgRisk risk;
  final String? riskReason;

  /// Supprimé par son expéditeur : la bulle affiche « Message supprimé ».
  final bool deleted;

  const ChatMessage(
    this.mine,
    this.kind,
    this.text,
    this.time, {
    this.photo,
    this.id,
    this.sentAt,
    this.read = false,
    this.status = MsgStatus.sent,
    this.risk = MsgRisk.none,
    this.riskReason,
    this.deleted = false,
  });

  ChatMessage copyWith({
    bool? mine,
    String? id,
    DateTime? sentAt,
    String? time,
    bool? read,
    MsgStatus? status,
    bool? deleted,
  }) =>
      ChatMessage(
        mine ?? this.mine,
        kind,
        text,
        time ?? this.time,
        photo: photo,
        id: id ?? this.id,
        sentAt: sentAt ?? this.sentAt,
        read: read ?? this.read,
        status: status ?? this.status,
        risk: deleted == true ? MsgRisk.none : risk,
        riskReason: deleted == true ? null : riskReason,
        deleted: deleted ?? this.deleted,
      );
}

enum LogKind { repas, nouvelles, visite, soins, promenade, nettoyage }

extension LogKindX on LogKind {
  String get label => switch (this) {
    LogKind.repas => 'Repas',
    LogKind.nouvelles => 'Nouvelles',
    LogKind.visite => 'Visite',
    LogKind.soins => 'Soins',
    LogKind.promenade => 'Promenade',
    LogKind.nettoyage => 'Entretien',
  };
  IconData get icon => switch (this) {
    LogKind.repas => PhosphorIconsRegular.bowlFood,
    LogKind.nouvelles => PhosphorIconsRegular.camera,
    LogKind.visite => PhosphorIconsRegular.doorOpen,
    LogKind.soins => PhosphorIconsRegular.firstAidKit,
    LogKind.promenade => PhosphorIconsRegular.footprints,
    LogKind.nettoyage => PhosphorIconsRegular.broom,
  };
}

class LogEntry {
  final LogKind kind;
  final String time;
  final String title;
  final String detail;
  final String? photo;
  final bool done;
  const LogEntry(this.kind, this.time, this.title, this.detail, {this.photo, this.done = true});
}

/// Une conversation de la messagerie (aperçu dans la liste).
class Conversation {
  const Conversation({
    this.id = '',
    this.otherUserId,
    required this.photo,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.context,
    required this.live,
    this.lastMessageAt,
    this.lastMessageMine = false,
  });

  final String id;

  /// Identifiant de l'autre membre (pour lui écrire depuis son profil).
  final String? otherUserId;

  /// Photo de l'autre membre ; vide s'il n'en a pas (les initiales sont affichées).
  final String photo;
  final String name;
  final String lastMessage;

  /// Moment du dernier message, déjà mis en forme (« 08:53 », « Hier », « lun. »).
  final String time;
  final int unread;
  final String context; // ex. « Garde en cours · Simba, Kiwi » ; vide si aucun contexte
  final bool live; // garde en cours : le journal de garde est proposé
  final DateTime? lastMessageAt;
  final bool lastMessageMine;

  Conversation copyWith({int? unread, String? lastMessage, String? time, DateTime? lastMessageAt, bool? lastMessageMine}) =>
      Conversation(
        id: id,
        otherUserId: otherUserId,
        photo: photo,
        name: name,
        lastMessage: lastMessage ?? this.lastMessage,
        time: time ?? this.time,
        unread: unread ?? this.unread,
        context: context,
        live: live,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        lastMessageMine: lastMessageMine ?? this.lastMessageMine,
      );
}
