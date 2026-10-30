import 'package:flutter/material.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';

import 'package:pet_sitter/data/sources/mock_data.dart';
import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/core/motion/gsap.dart';
import 'package:pet_sitter/app/routes.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/widgets/common.dart';
import 'package:pet_sitter/app/dependencies.dart';
import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/view_models/messages_view_model.dart';

// ————————————————————————————————————————————— LISTE DES CONVERSATIONS

class MessagesListScreen extends StatelessWidget {
  const MessagesListScreen({super.key, this.asSitter = false});
  final bool asSitter;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<MessagesViewModel>(
      create: (context) => MessagesViewModel(Deps.of(context).messages, asSitter: asSitter),
      builder: (context, vm) => _content(context, vm.conversations),
    );
  }

  Widget _content(BuildContext context, List<Conversation> convs) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Messages', style: LPText.h2),
        actions: [
          IconButton(tooltip: 'Rechercher', onPressed: () {}, icon: const Icon(PhosphorIconsRegular.magnifyingGlass)),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          for (final (i, c) in convs.indexed) ...[
            InkWell(
              onTap: () => Navigator.pushNamed(context, R.chat, arguments: asSitter),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        LPAvatar(c.photo, size: 54),
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
                              Expanded(child: Text(c.name, style: LPText.title.copyWith(fontSize: 16))),
                              Text(
                                c.time,
                                style: LPText.bodyS.copyWith(
                                  fontSize: 12.5,
                                  color: c.unread > 0 ? LP.primary : LP.muted,
                                  fontWeight: c.unread > 0 ? FontWeight.w700 : null,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            c.context,
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
                                    color: c.unread > 0 ? LP.ink : LP.muted,
                                    w: c.unread > 0 ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (c.unread > 0)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(color: LP.primary, borderRadius: BorderRadius.circular(99)),
                                  child: Text(
                                    '$c.unread',
                                    style: LPText.body(size: 12, w: FontWeight.w700, color: LP.white),
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
            ).from(y: 24, delay: stagger(i, start: 0.1, each: 0.07)),
            const Divider(indent: 88),
          ],
          if (!asSitter)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Text(
                'Les conversations avec les sitters fictifs illustrent le fonctionnement de la messagerie.',
                style: LPText.bodyS,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

// ————————————————————————————————————————————— CONVERSATION + JOURNAL

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.initialTab = 0, this.asSitter = false, this.preview});

  /// Aperçu d'un état précis (pour les captures du sommaire), sinon null.
  final String? preview;
  final int initialTab;
  final bool asSitter;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late final vm = ChatViewModel(
    messages: Deps.of(context).messages,
    pets: Deps.of(context).pets,
    sitterSpace: Deps.of(context).sitterSpace,
    asSitter: widget.asSitter,
  );

  late final _tabs = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.preview == 'add-entry') WidgetsBinding.instance.addPostFrameCallback((_) => _addEntry());
  }

  void _send() {
    vm.send(_input.text);
    _input.clear();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    vm.dispose();
    _tabs.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: vm, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    final otherPhoto = vm.otherPhoto;
    final otherName = vm.otherName;
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        titleSpacing: 0,
        title: Row(
          children: [
            LPAvatar(otherPhoto, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(otherName, style: LPText.title.copyWith(fontSize: 16)),
                  Text(
                    'Garde en cours · Simba, Kiwi',
                    style: LPText.body(size: 12.5, color: LP.accentInk, w: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(tooltip: 'Appeler', onPressed: () {}, icon: const Icon(PhosphorIconsRegular.phone)),
          IconButton(tooltip: 'Plus', onPressed: () {}, icon: const Icon(PhosphorIconsRegular.dotsThreeVertical)),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Messages'),
            Tab(text: 'Journal de garde'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabs, children: [_messages(), _journalView()]),
    );
  }

  Widget _messages() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              for (var i = 0; i < vm.messages.length; i++) ...[
                if (_dayBreaks.containsKey(i)) _dayLabel(_dayBreaks[i]!),
                _message(vm.messages[i]),
              ],
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + MediaQuery.paddingOf(context).bottom),
          decoration: const BoxDecoration(
            color: LP.bg,
            border: Border(top: BorderSide(color: LP.line)),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Ajouter une photo',
                onPressed: () {},
                icon: const Icon(PhosphorIconsRegular.image, color: LP.primary),
              ),
              IconButton(
                tooltip: 'Prendre une photo',
                onPressed: () {},
                icon: const Icon(PhosphorIconsRegular.camera, color: LP.primary),
              ),
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Votre message…',
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

  static const _dayBreaks = {0: 'Jeudi 22 octobre', 3: 'Vendredi 23 octobre', 4: 'Aujourd\'hui'};

  Widget _message(ChatMessage m) {
    final mine = vm.isMine(m);
    return switch (m.kind) {
      MsgKind.system => _system(m.text),
      MsgKind.photo => _bubble(mine, m.time, photo: photoByKey(m.photo!), caption: m.text),
      MsgKind.text => _bubble(mine, m.time, text: m.text),
    };
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

  Widget _bubble(bool mine, String time, {String? text, String? photo, String? caption}) {
    final r = const Radius.circular(20);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.76),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: photo != null ? const EdgeInsets.all(5) : const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: mine ? LP.primary : LP.white,
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
                        Text(time, style: LPText.body(size: 11, color: mine ? LP.mint : LP.muted)),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Text(text!, style: LPText.body(size: 15, color: mine ? LP.white : LP.ink, height: 1.4)),
                const SizedBox(height: 3),
                Text(time, style: LPText.body(size: 11, color: mine ? LP.mint : LP.muted)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ———— Journal de garde

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
