import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';

import 'package:pet_sitter/data/repositories/message_repository.dart';
import 'package:pet_sitter/data/sources/mock_data.dart';
import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/core/motion/gsap.dart';
import 'package:pet_sitter/app/routes.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/widgets/common.dart';
import 'package:pet_sitter/core/widgets/member_avatar.dart';
import 'package:pet_sitter/app/dependencies.dart';
import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/view_models/messages_view_model.dart';

/// Arguments de la route `R.chat`.
class ChatArgs {
  const ChatArgs({this.conversation, this.asSitter = false, this.initialTab = 0});
  final Conversation? conversation;
  final bool asSitter;
  final int initialTab;
}

/// Ouvre (ou retrouve) la conversation avec un membre puis l'affiche.
/// Utilisé par les profils (« Contacter ») ; affiche l'erreur dans un bandeau si besoin.
Future<void> openChatWith(BuildContext context, {required String userId, String? subject}) async {
  final deps = Deps.of(context);
  final messenger = ScaffoldMessenger.of(context);
  if (deps.messages is ApiMessageRepository && !deps.session.isAuthenticated) {
    messenger.showSnackBar(const SnackBar(content: Text('Connectez-vous pour envoyer un message.')));
    Navigator.pushNamed(context, R.login);
    return;
  }
  try {
    final conversation = await deps.messages.openConversation(userId: userId, subject: subject);
    if (!context.mounted) return;
    Navigator.pushNamed(context, R.chat, arguments: ChatArgs(conversation: conversation));
  } on MessagingException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// Message centré (liste vide, erreur, connexion requise).
class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.icon, required this.title, required this.body, this.action, this.onAction});
  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 120),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(color: LP.mintPale, shape: BoxShape.circle),
            child: Icon(icon, size: 34, color: LP.primary),
          ),
          const SizedBox(height: 16),
          Text(title, style: LPText.h3, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(body, style: LPText.bodyS, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: 18),
            FilledButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}

// ————————————————————————————————————————————— LISTE DES CONVERSATIONS

class MessagesListScreen extends StatelessWidget {
  const MessagesListScreen({super.key, this.asSitter = false});
  final bool asSitter;

  @override
  Widget build(BuildContext context) {
    final deps = Deps.of(context);
    // Messagerie réelle : il faut un compte connecté.
    if (deps.messages is ApiMessageRepository && !deps.session.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false, title: Text('Messages', style: LPText.h2)),
        body: _StateMessage(
          icon: PhosphorIconsRegular.chatCircleDots,
          title: 'Connectez-vous pour discuter',
          body: 'La messagerie vous permet d\'échanger avec les pet sitters et les propriétaires.',
          action: 'Se connecter',
          onAction: () => Navigator.pushNamed(context, R.login),
        ),
      );
    }
    return ViewModelBuilder<MessagesViewModel>(
      create: (context) => MessagesViewModel(deps.messages, asSitter: asSitter),
      builder: (context, vm) => _content(context, vm),
    );
  }

  Future<void> _open(BuildContext context, MessagesViewModel vm, Conversation c) async {
    vm.markOpened(c);
    await Navigator.pushNamed(context, R.chat, arguments: ChatArgs(conversation: c, asSitter: asSitter));
    vm.load(silent: true);
  }

  Future<void> _newMessage(BuildContext context, MessagesViewModel vm) async {
    final conversation = await Navigator.pushNamed(context, R.newMessage);
    if (conversation is! Conversation || !context.mounted) return;
    await _open(context, vm, conversation);
  }

  Widget _content(BuildContext context, MessagesViewModel vm) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Messages', style: LPText.h2),
        actions: [
          IconButton(
            tooltip: 'Nouveau message',
            onPressed: () => _newMessage(context, vm),
            icon: const Icon(PhosphorIconsRegular.pencilSimple),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: switch (vm) {
        _ when vm.loading => const Center(child: CircularProgressIndicator()),
        _ when vm.error != null => _StateMessage(
          icon: PhosphorIconsRegular.warningCircle,
          title: 'Messages indisponibles',
          body: vm.error!,
          action: 'Réessayer',
          onAction: vm.load,
        ),
        _ when vm.isEmpty => _StateMessage(
          icon: PhosphorIconsRegular.chatCircleDots,
          title: 'Aucune conversation',
          body: asSitter
              ? 'Les propriétaires qui vous contactent apparaîtront ici.'
              : 'Écrivez à un pet sitter pour préparer une garde.',
          action: 'Nouveau message',
          onAction: () => _newMessage(context, vm),
        ),
        _ => RefreshIndicator(
          onRefresh: vm.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              for (final (i, c) in vm.conversations.indexed) ...[
                _ConversationTile(c, onTap: () => _open(context, vm, c))
                    .from(y: 24, delay: stagger(i, start: 0.1, each: 0.07)),
                const Divider(indent: 88),
              ],
            ],
          ),
        ),
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile(this.c, {required this.onTap});
  final Conversation c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = c.unread > 0;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                MemberAvatar(photo: c.photo, name: c.name, size: 54),
                if (c.live)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: LP.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: LP.bg, width: 2.5),
                      ),
                      child: const Icon(PhosphorIconsFill.pawPrint, size: 9, color: LP.primaryDark),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LPText.title.copyWith(fontSize: 16),
                        ),
                      ),
                      Text(
                        c.time,
                        style: LPText.bodyS.copyWith(
                          fontSize: 12.5,
                          color: unread ? LP.primary : LP.muted,
                          fontWeight: unread ? FontWeight.w700 : null,
                        ),
                      ),
                    ],
                  ),
                  if (c.context.isNotEmpty)
                    Text(
                      c.context,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LPText.body(size: 12.5, w: FontWeight.w600, color: LP.accentInk),
                    ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LPText.body(
                            size: 14.5,
                            color: unread ? LP.ink : LP.muted,
                            w: unread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (unread)
                        Semantics(
                          label: '${c.unread} message${c.unread > 1 ? 's' : ''} non lu${c.unread > 1 ? 's' : ''}',
                          excludeSemantics: true,
                          child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: LP.primary, borderRadius: BorderRadius.circular(99)),
                            child: Text(
                              '${c.unread}',
                              style: LPText.body(size: 12, w: FontWeight.w700, color: LP.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ————————————————————————————————————————————— NOUVEAU MESSAGE

class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key});

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  late final vm = NewMessageViewModel(Deps.of(context).messages);

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  Future<void> _open(Member m) async {
    final conversation = await vm.open(m);
    if (conversation != null && mounted) Navigator.pop(context, conversation);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: vm,
    builder: (context, _) => Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Nouveau message')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              autofocus: true,
              onChanged: vm.onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Rechercher un membre par son nom',
                prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass, size: 20),
              ),
            ),
          ),
          if (vm.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: InfoNote(vm.error!, icon: PhosphorIconsRegular.warningCircle, tone: InfoTone.error),
            ),
          if (vm.loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: !vm.loading && vm.results.isEmpty
                ? const _StateMessage(
                    icon: PhosphorIconsRegular.user,
                    title: 'Aucun membre trouvé',
                    body: 'Vérifiez l\'orthographe du nom.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 40),
                    itemCount: vm.results.length,
                    separatorBuilder: (_, _) => const Divider(indent: 84),
                    itemBuilder: (context, i) {
                      final m = vm.results[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        leading: MemberAvatar(photo: m.photoUrl ?? '', name: m.fullName, size: 46),
                        title: Text(m.fullName, style: LPText.title.copyWith(fontSize: 16)),
                        subtitle: Text(
                          [m.role.label, if (m.city != null && m.city!.isNotEmpty) m.city!].join(' · '),
                          style: LPText.bodyS,
                        ),
                        trailing: vm.isOpening(m)
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2))
                            : const Icon(PhosphorIconsRegular.chatCircleDots, color: LP.primary),
                        onTap: () => _open(m),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}

// ————————————————————————————————————————————— CONVERSATION + JOURNAL

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.conversation, this.initialTab = 0, this.asSitter = false, this.preview});

  /// Conversation à afficher ; nulle = la plus récente (aperçus, liens sans contexte).
  final Conversation? conversation;

  /// Aperçu d'un état précis (pour les captures du sommaire), sinon null.
  final String? preview;
  final int initialTab;
  final bool asSitter;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final vm = ChatViewModel(
    messages: Deps.of(context).messages,
    pets: Deps.of(context).pets,
    sitterSpace: Deps.of(context).sitterSpace,
    conversation: widget.conversation,
    asSitter: widget.asSitter,
  );

  final _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.preview == 'add-entry') {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        while (mounted && vm.loading) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        if (mounted && vm.hasJournal) _addEntry();
      });
    }
  }

  Future<void> _send() async {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    await vm.send(text);
    if (mounted && vm.riskWarning != null) await _confirmRisk();
  }

  /// L'assistant IA a signalé le message (arnaque, insulte) : l'expéditeur modifie ou confirme.
  Future<void> _confirmRisk() async {
    final warning = vm.riskWarning!;
    final send = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(PhosphorIconsRegular.warningCircle, color: LP.error, size: 32),
        title: const Text('Message à vérifier'),
        content: Text(warning.reason),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Envoyer quand même')),
          FilledButton(onPressed: () => Navigator.pop(context, false), child: const Text('Modifier')),
        ],
      ),
    );
    if (!mounted) return;
    if (send == true) {
      await vm.confirmRiskySend();
    } else {
      _input.text = vm.cancelRiskySend();
      _input.selection = TextSelection.collapsed(offset: _input.text.length);
    }
  }

  void _useSuggestion(String text) {
    _input.text = text;
    _input.selection = TextSelection.collapsed(offset: text.length);
    vm.clearSuggestions();
  }

  /// Réponses proposées par l'assistant, au-dessus de la zone de saisie.
  Widget _suggestionsBar() {
    if (!vm.suggestionsLoading && vm.suggestions.isEmpty) return const SizedBox.shrink();
    return Container(
      color: LP.bg,
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
      child: vm.suggestionsLoading
          ? Row(
              children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 10),
                Text('L\'assistant prépare des réponses…', style: LPText.bodyS),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(PhosphorIconsFill.sparkle, size: 14, color: LP.accentInk),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        vm.suggestionsFromAi ? 'Suggestions de l\'IA' : 'Suggestions',
                        style: LPText.body(size: 12.5, w: FontWeight.w700, color: LP.accentInk),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Masquer les suggestions',
                      visualDensity: VisualDensity.compact,
                      onPressed: vm.clearSuggestions,
                      icon: const Icon(PhosphorIconsRegular.x, size: 16),
                    ),
                  ],
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final s in vm.suggestions)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(s, style: LPText.body(size: 13.5)),
                            backgroundColor: LP.mintPale,
                            side: BorderSide.none,
                            onPressed: () => _useSuggestion(s),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    vm.dispose();
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: vm, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    final tabs = vm.hasJournal ? 2 : 1;
    return DefaultTabController(
      key: ValueKey(tabs),
      length: tabs,
      initialIndex: widget.initialTab.clamp(0, tabs - 1),
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          titleSpacing: 0,
          title: Row(
            children: [
              MemberAvatar(photo: vm.otherPhoto, name: vm.otherName, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vm.otherName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LPText.title.copyWith(fontSize: 16),
                    ),
                    if (vm.contextLabel.isNotEmpty)
                      Text(
                        vm.contextLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LPText.body(size: 12.5, color: LP.accentInk, w: FontWeight.w600),
                      ),
                  ],
                ),
              ),
            ],
          ),
          bottom: vm.hasJournal
              ? const TabBar(
                  tabs: [
                    Tab(text: 'Messages'),
                    Tab(text: 'Journal de garde'),
                  ],
                )
              : null,
        ),
        body: vm.hasJournal ? TabBarView(children: [_messages(), _journalView()]) : _messages(),
      ),
    );
  }

  Widget _messages() {
    if (vm.loading) return const Center(child: CircularProgressIndicator());
    if (vm.noConversation) {
      return const _StateMessage(
        icon: PhosphorIconsRegular.chatCircleDots,
        title: 'Aucune conversation',
        body: 'Contactez un pet sitter depuis son profil pour commencer à échanger.',
      );
    }
    if (vm.error != null && vm.messages.isEmpty) {
      return _StateMessage(
        icon: PhosphorIconsRegular.warningCircle,
        title: 'Conversation indisponible',
        body: vm.error!,
        action: 'Réessayer',
        onAction: vm.load,
      );
    }
    final items = vm.messages;
    final lastRead = vm.lastReadMineId;
    return Column(
      children: [
        Expanded(
          child: items.isEmpty
              ? _StateMessage(
                  icon: PhosphorIconsRegular.handHeart,
                  title: 'Dites bonjour à ${vm.otherName.split(' ').first} !',
                  body: 'Présentez votre animal et vos dates : les échanges restent dans la messagerie.',
                )
              : ListView.builder(
                  // Liste inversée : le dernier message reste collé en bas, même quand il en arrive.
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final i = items.length - 1 - index;
                    final m = items[i];
                    final day = vm.dayLabelBefore(i);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (day != null) _dayLabel(day),
                        _message(m, showRead: m.id != null && m.id == lastRead),
                      ],
                    );
                  },
                ),
        ),
        if (vm.error != null)
          Material(
            color: const Color(0xFFFDECEA),
            child: ListTile(
              dense: true,
              leading: const Icon(PhosphorIconsRegular.warningCircle, color: LP.error),
              title: Text(vm.error!, style: LPText.body(size: 13.5, color: LP.error, w: FontWeight.w600)),
              trailing: IconButton(
                tooltip: 'Fermer',
                onPressed: vm.dismissError,
                icon: const Icon(PhosphorIconsRegular.x, size: 18),
              ),
            ),
          ),
        _suggestionsBar(),
        Container(
          padding: EdgeInsets.fromLTRB(4, 8, 8, 8 + MediaQuery.paddingOf(context).bottom),
          decoration: const BoxDecoration(
            color: LP.bg,
            border: Border(top: BorderSide(color: LP.line)),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Suggestions de réponse (IA)',
                onPressed: vm.suggestionsLoading ? null : vm.loadSuggestions,
                icon: const Icon(PhosphorIconsFill.sparkle, color: LP.accentInk),
              ),
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Votre message…',
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(99),
                      borderSide: const BorderSide(color: LP.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(99),
                      borderSide: const BorderSide(color: LP.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(99),
                      borderSide: const BorderSide(color: LP.primary, width: 1.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: LP.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _send,
                  child: const SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(PhosphorIconsFill.paperPlaneRight, color: LP.white, size: 20, semanticLabel: 'Envoyer'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _message(ChatMessage m, {required bool showRead}) {
    final mine = vm.isMine(m);
    if (m.kind == MsgKind.system) return _system(m.text);
    if (m.deleted) return _deletedBubble(mine, m.time);
    final body = switch (m.kind) {
      MsgKind.photo => _bubble(m, mine, photo: photoByKey(m.photo!), caption: m.text, showRead: showRead),
      _ => _bubble(m, mine, text: m.text, showRead: showRead),
    };
    final note = _riskNote(m, mine);
    // Appui long : copier, et supprimer pour ses propres messages.
    return GestureDetector(
      onLongPress: () => _showActions(m),
      child: note == null
          ? body
          : Column(crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [body, note]),
    );
  }

  /// Bulle d'un message supprimé, identique pour l'expéditeur et le destinataire.
  Widget _deletedBubble(bool mine, String time) => Align(
    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: LP.bg,
        border: Border.all(color: LP.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(PhosphorIconsRegular.trash, size: 15, color: LP.muted),
          const SizedBox(width: 6),
          Text(
            mine ? 'Vous avez supprimé ce message' : 'Message supprimé',
            style: LPText.body(size: 13.5, color: LP.muted).copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(width: 8),
          Text(time, style: LPText.body(size: 11, color: LP.muted)),
        ],
      ),
    ),
  );

  Future<void> _showActions(ChatMessage m) async {
    final canDelete = vm.canDelete(m);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(PhosphorIconsRegular.notepad),
              title: const Text('Copier le texte'),
              onTap: () => Navigator.pop(context, 'copy'),
            ),
            if (canDelete)
              ListTile(
                leading: const Icon(PhosphorIconsRegular.trash, color: LP.error),
                title: Text(
                  m.status == MsgStatus.failed ? 'Retirer ce message non envoyé' : 'Supprimer pour tout le monde',
                  style: const TextStyle(color: LP.error),
                ),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: m.text));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message copié.')));
      return;
    }
    if (m.status != MsgStatus.failed) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Supprimer ce message ?'),
          content: const Text('Il sera remplacé par « Message supprimé » pour vous et votre interlocuteur.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: LP.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    await vm.deleteMessage(m);
  }

  /// Message signalé par l'assistant IA : avertissement pour le destinataire, rappel pour l'expéditeur.
  Widget? _riskNote(ChatMessage m, bool mine) {
    if (m.risk == MsgRisk.none || m.kind == MsgKind.system) return null;
    if (mine) {
      if (m.risk != MsgRisk.high) return null;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text('Signalé au destinataire comme message à risque', style: LPText.body(size: 11.5, color: LP.muted)),
      );
    }
    final high = m.risk == MsgRisk.high;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
        decoration: BoxDecoration(
          color: high ? const Color(0xFFFDECEA) : LP.soft,
          borderRadius: BorderRadius.circular(LP.r12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              high ? PhosphorIconsRegular.warningCircle : PhosphorIconsRegular.info,
              size: 16,
              color: high ? LP.error : LP.muted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${high ? 'Prudence' : 'À savoir'} : ${m.riskReason ?? ''}',
                style: LPText.body(size: 12.5, color: high ? LP.error : LP.muted, w: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayLabel(String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Center(child: Text(t, style: LPText.overline)),
  );

  Widget _system(String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: LP.mintPale, borderRadius: BorderRadius.circular(99)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(PhosphorIconsFill.checkCircle, size: 15, color: LP.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                t,
                style: LPText.body(size: 12.5, w: FontWeight.w600, color: LP.primaryDark),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  /// Heure, puis état d'envoi pour mes messages (envoi…, échec, lu).
  Widget _meta(ChatMessage m, bool mine, {required bool showRead}) {
    final color = mine ? LP.mint : LP.muted;
    final style = LPText.body(size: 11, color: color);
    return switch (m.status) {
      MsgStatus.sending => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsRegular.clock, size: 12, color: color),
          const SizedBox(width: 3),
          Text('Envoi…', style: style),
        ],
      ),
      MsgStatus.failed => Text(
        'Non envoyé · Toucher pour réessayer',
        style: LPText.body(size: 11, color: LP.white, w: FontWeight.w700),
      ),
      MsgStatus.sent => Text(showRead && mine ? '${m.time} · Lu' : m.time, style: style),
    };
  }

  Widget _bubble(ChatMessage m, bool mine, {String? text, String? photo, String? caption, required bool showRead}) {
    final r = const Radius.circular(20);
    final failed = m.status == MsgStatus.failed;
    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: photo != null ? const EdgeInsets.all(5) : const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: BoxDecoration(
        color: failed ? LP.error : (mine ? LP.primary : LP.white),
        border: mine ? null : Border.all(color: LP.line),
        borderRadius: BorderRadius.only(
          topLeft: r,
          topRight: r,
          bottomLeft: mine ? r : const Radius.circular(6),
          bottomRight: mine ? const Radius.circular(6) : r,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (photo != null) ...[
            LPImage(photo, width: 240, height: 200, radius: 16),
            SizedBox(
              width: 240,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(caption ?? '', style: LPText.body(size: 14.5, color: mine ? LP.white : LP.ink)),
                    ),
                    _meta(m, mine, showRead: showRead),
                  ],
                ),
              ),
            ),
          ] else ...[
            Text(text!, style: LPText.body(size: 15, color: mine ? LP.white : LP.ink, height: 1.4)),
            const SizedBox(height: 3),
            _meta(m, mine, showRead: showRead),
          ],
        ],
      ),
    );
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.76),
        child: failed ? GestureDetector(onTap: () => vm.retry(m), child: bubble) : bubble,
      ),
    );
  }

  // ———— Journal de garde (démonstration)

  Widget _journalView() {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Jour 2 sur 3', style: LPText.h3),
                      const SizedBox(height: 2),
                      Text('Retour prévu lundi 26 octobre vers 10 h', style: LPText.bodyS),
                    ],
                  ),
                ),
                for (final p in vm.caredPets)
                  Padding(padding: const EdgeInsets.only(left: 4), child: LPAvatar(p.photo, size: 36, ring: true)),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(value: 0.55, minHeight: 6, backgroundColor: LP.softDeep),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _stat(
                  PhosphorIconsRegular.bowlFood,
                  'Repas',
                  '${vm.doneCount(LogKind.repas)}/${vm.totalCount(LogKind.repas)}',
                ),
                _stat(
                  PhosphorIconsRegular.firstAidKit,
                  'Soins',
                  '${vm.doneCount(LogKind.soins)}/${vm.totalCount(LogKind.soins)}',
                ),
                _stat(PhosphorIconsRegular.camera, 'Photos', '${vm.photoCount}'),
              ],
            ),
            for (final day in vm.journal.entries) ...[
              const SizedBox(height: 26),
              Text(day.key.toUpperCase(), style: LPText.overline),
              const SizedBox(height: 12),
              for (var i = 0; i < day.value.length; i++) _entry(day.value[i], last: i == day.value.length - 1),
            ],
          ],
        ),
        if (vm.asSitter)
          Positioned(
            left: 20,
            right: 20,
            bottom: 20 + MediaQuery.paddingOf(context).bottom,
            child: FilledButton.icon(
              onPressed: _addEntry,
              icon: const Icon(PhosphorIconsBold.plus, size: 18),
              label: const Text('Ajouter au journal'),
            ),
          ),
      ],
    );
  }

  Widget _stat(IconData i, String l, String v) => Expanded(
    child: Row(
      children: [
        Icon(i, size: 20, color: LP.primary),
        const SizedBox(width: 6),
        Text(v, style: LPText.label.copyWith(fontSize: 15)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(l, style: LPText.bodyS, overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );

  Widget _entry(LogEntry e, {required bool last}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              e.time,
              style: LPText.body(size: 13, w: FontWeight.w600, color: e.done ? LP.ink : LP.muted),
            ),
          ),
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: e.done ? LP.mintPale : LP.bg,
                  shape: BoxShape.circle,
                  border: e.done ? null : Border.all(color: LP.softDeep, width: 1.5),
                ),
                child: Icon(e.kind.icon, size: 18, color: e.done ? LP.primary : LP.muted),
              ),
              if (!last)
                Expanded(
                  child: Container(width: 1.5, color: LP.line, margin: const EdgeInsets.symmetric(vertical: 4)),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.title,
                          style: LPText.label.copyWith(fontSize: 15, color: e.done ? LP.ink : LP.muted),
                        ),
                      ),
                      if (!e.done) const Pill(label: 'Prévu', bg: LP.soft, fg: LP.muted),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(e.detail, style: LPText.bodyS),
                  if (e.photo != null) ...[
                    const SizedBox(height: 10),
                    LPImage(e.photo!, height: 170, width: double.infinity, radius: LP.r16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addEntry() {
    // Le ViewModel propose les types adaptés aux animaux gardés (pas de promenade sans chien).
    final kinds = vm.availableKinds;
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ajouter au journal', style: LPText.h2),
            const SizedBox(height: 4),
            Text('Adapté à Simba (chat) et Kiwi (oiseau).', style: LPText.bodyS),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final k in kinds)
                  SizedBox(
                    width: (MediaQuery.sizeOf(context).width - 60) / 2,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        side: const BorderSide(color: LP.line, width: 1.2),
                        foregroundColor: LP.ink,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        vm.addEntry(k);
                      },
                      icon: Icon(k.icon, color: LP.primary, size: 20),
                      label: Text(k == LogKind.nettoyage ? 'Cage / litière' : k.label),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
