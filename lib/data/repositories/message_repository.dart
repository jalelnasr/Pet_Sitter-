/// Messagerie et journal de garde.
library;

import 'package:pet_sitter/data/sources/mock_data.dart';
import 'package:pet_sitter/models/models.dart';

abstract class MessageRepository {
  List<Conversation> conversations({required bool asSitter});
  List<ChatMessage> messages();
  Map<String, List<LogEntry>> journal();
}

class MockMessageRepository implements MessageRepository {
  @override
  List<Conversation> conversations({required bool asSitter}) => asSitter
      ? [
          Conversation(
            photo: Photos.leila,
            name: 'Leïla B.',
            lastMessage: 'Merci, ça me rassure beaucoup ! Et Kiwi ?',
            time: '08:50',
            unread: 0,
            context: 'Garde en cours · Simba, Kiwi',
            live: true,
          ),
          Conversation(
            photo: Photos.salma,
            name: 'Sami R.',
            lastMessage: 'Bonjour, accepteriez-vous un lapin âgé ?',
            time: 'Hier',
            unread: 1,
            context: 'Nouvelle demande · 1er–4 nov.',
            live: false,
          ),
        ]
      : [
          Conversation(
            photo: Mock.amira.photo,
            name: 'Amira',
            lastMessage: 'Elle chante depuis 7 h 😄 Graines et pomme ok, eau changée.',
            time: '08:53',
            unread: 2,
            context: 'Garde en cours · Simba, Kiwi',
            live: true,
          ),
          Conversation(
            photo: Mock.salma.photo,
            name: 'Salma',
            lastMessage: 'Je passerai vers 9 h pour nourrir Bulle et vérifier le filtre.',
            time: 'Hier',
            unread: 0,
            context: 'Confirmée · 23–26 oct.',
            live: false,
          ),
          Conversation(
            photo: Mock.ines.photo,
            name: 'Inès',
            lastMessage: 'Bonjour ! Simba est-il habitué à rester seul la journée ?',
            time: 'Lun.',
            unread: 0,
            context: 'Demande en attente · 18–21 déc.',
            live: false,
          ),
        ];

  @override
  List<ChatMessage> messages() => [...Mock.chat];

  @override
  Map<String, List<LogEntry>> journal() => {
    for (final e in Mock.journal.entries) e.key: [...e.value],
  };
}
