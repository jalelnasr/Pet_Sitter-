import 'package:flutter/material.dart';

import 'package:pet_sitter/app/dependencies.dart';
import 'package:pet_sitter/app/routes.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';
import 'package:pet_sitter/core/widgets/common.dart';
import 'package:pet_sitter/data/repositories/assistant_repository.dart';
import 'package:pet_sitter/view_models/assistant_view_model.dart';
import 'package:pet_sitter/views/shop/shop_screens.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  late final vm = AssistantViewModel(Deps.of(context).assistant, Deps.of(context).cart, Deps.of(context).session);
  final _question = TextEditingController();

  static const _examples = [
    'J\'ai un chat stérilisé de 4 kg, qu\'est-ce qu\'il lui faut ?',
    'Je viens d\'adopter un chiot, par quoi commencer ?',
    'Que me faut-il pour un poisson rouge ?',
  ];

  @override
  void dispose() {
    vm.dispose();
    _question.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (vm.needsLogin) {
      await Navigator.pushNamed(context, R.loginReturn);
      if (!mounted || vm.needsLogin) return;
    }
    FocusScope.of(context).unfocus();
    await vm.ask(_question.text);
  }

  void _useExample(String text) {
    _question.text = text;
    _send();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => Scaffold(
        appBar: AppBar(leading: const BackButton(), title: const Text('Assistant'), actions: const [CartButton()]),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text('Décrivez votre animal', style: LPText.h2),
            const SizedBox(height: 4),
            Text('Je vous propose des produits de la boutique.', style: LPText.bodyS),
            const SizedBox(height: 14),
            TextField(
              controller: _question,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(hintText: 'Espèce, âge, poids, besoin…', counterText: ''),
            ),
            const SizedBox(height: 12),
            PawButton(label: 'Demander', loading: vm.asking, onPressed: vm.asking ? null : _send),
            const SizedBox(height: 18),
            if (vm.asking)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(color: LP.primary)),
              )
            else if (vm.error != null)
              InfoNote(vm.error!, icon: PhosphorIconsRegular.warningCircle, tone: InfoTone.error)
            else if (vm.reply != null)
              _answer(vm.reply!)
            else ...[
              Text('Exemples', style: LPText.label),
              for (final e in _examples)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton(onPressed: () => _useExample(e), child: Text(e)),
                ),
            ],
            const SizedBox(height: 20),
            Text(
              'Ces conseils peuvent contenir des erreurs et ne remplacent pas un vétérinaire.',
              textAlign: TextAlign.center,
              style: LPText.bodyS.copyWith(fontSize: 12.5, color: LP.faint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _answer(AssistantReply reply) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reply.demo) ...[
          const InfoNote('Mode démonstration : cette réponse ne vient pas d\'une IA.'),
          const SizedBox(height: 12),
        ],
        Text(reply.message, style: LPText.bodyM),
        for (final pick in reply.picks)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 168,
                  child: ProductCard(product: pick.product, onAdd: () => vm.addToCart(pick.product)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(pick.reason, style: LPText.bodyM)),
              ],
            ),
          ),
      ],
    );
  }
}
