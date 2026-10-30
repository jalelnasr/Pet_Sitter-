import 'package:flutter/material.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';

import 'package:pet_sitter/core/theme/app_theme.dart';

class OrDivider extends StatelessWidget {
  const OrDivider(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label, style: LPText.bodyS),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.optional = false});
  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: text, style: LPText.label),
            if (optional) TextSpan(text: '  facultatif', style: LPText.bodyS.copyWith(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.validator,
    this.hint,
    this.label,
    this.showStrength = false,
  });
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? hint;
  final String? label;
  final bool showStrength;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  int get _score {
    final v = widget.controller.text;
    var s = 0;
    if (v.length >= 8) s++;
    if (RegExp(r'\d').hasMatch(v)) s++;
    if (RegExp(r'[A-Z]').hasMatch(v) || RegExp(r'[^A-Za-z0-9]').hasMatch(v)) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['Trop court', 'Moyen', 'Bon', 'Solide'];
    final colors = [LP.error, LP.accent, LP.primary, LP.primary];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: !_visible,
          validator: widget.validator,
          onChanged: (_) => setState(() {}),
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint ?? 'Votre mot de passe',
            prefixIcon: const Icon(PhosphorIconsRegular.lockSimple, size: 20),
            suffixIcon: IconButton(
              tooltip: _visible ? 'Masquer le mot de passe' : 'Afficher le mot de passe',
              icon: Icon(_visible ? PhosphorIconsRegular.eyeSlash : PhosphorIconsRegular.eye, size: 21),
              onPressed: () => setState(() => _visible = !_visible),
            ),
          ),
        ),
        if (widget.showStrength && widget.controller.text.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: i < _score ? colors[_score] : LP.softDeep,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text(labels[_score], style: LPText.bodyS.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ],
    );
  }
}

/// Apple et Google côte à côte, à parts égales.
class SocialRow extends StatelessWidget {
  const SocialRow({super.key, required this.onApple, required this.onGoogle, this.loading});
  final VoidCallback onApple;
  final VoidCallback onGoogle;
  final String? loading; // 'apple' | 'google'

  @override
  Widget build(BuildContext context) {
    Widget spinner(Color c) =>
        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: c));
    Widget button({
      required String label,
      required IconData icon,
      required Color bg,
      required Color fg,
      required bool busy,
      required VoidCallback onTap,
      bool border = false,
    }) => Expanded(
      child: Semantics(
        button: true,
        label: 'Continuer avec $label',
        excludeSemantics: true,
        child: Material(
          color: bg,
          shape: StadiumBorder(side: border ? const BorderSide(color: LP.line, width: 1.4) : BorderSide.none),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: busy ? null : onTap,
            child: SizedBox(
              height: 54,
              child: Center(
                child: busy
                    ? spinner(fg)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 20, color: fg),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: LPText.body(size: 15.5, w: FontWeight.w700, color: fg),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
    return Row(
      children: [
        button(
          label: 'Apple',
          icon: PhosphorIconsFill.appleLogo,
          bg: LP.ink,
          fg: LP.white,
          busy: loading == 'apple',
          onTap: onApple,
        ),
        const SizedBox(width: 10),
        button(
          label: 'Google',
          icon: PhosphorIconsBold.googleLogo,
          bg: LP.white,
          fg: LP.ink,
          busy: loading == 'google',
          onTap: onGoogle,
          border: true,
        ),
      ],
    );
  }
}
