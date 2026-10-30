/// Messages de la conversation et entrées du journal de garde.
library;

import 'package:flutter/widgets.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';

enum MsgKind { text, photo, system }

class ChatMessage {
  final bool mine;
  final MsgKind kind;
  final String text;
  final String time;
  final String? photo;
  const ChatMessage(this.mine, this.kind, this.text, this.time, {this.photo});
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
    required this.photo,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.context,
    required this.live,
  });

  final String photo;
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final String context; // ex. « Garde en cours · Simba, Kiwi »
  final bool live; // garde en cours
}
