/// Socle MVVM, sans dépendance externe.
///
/// - Un **ViewModel** garde l'état d'un écran et contient sa logique. Il ne connaît aucun widget.
///   Quand son état change, il appelle [notify] : l'écran se redessine.
/// - [ViewModelBuilder] crée le ViewModel d'un écran, le garde en vie tant que l'écran existe,
///   et reconstruit l'écran à chaque changement.
library;

import 'package:flutter/widgets.dart';

abstract class ViewModel extends ChangeNotifier {
  bool _disposed = false;

  /// Prévient l'écran que l'état a changé (sans erreur si l'écran a déjà été fermé).
  @protected
  void notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class ViewModelBuilder<T extends ChangeNotifier> extends StatefulWidget {
  const ViewModelBuilder({super.key, required this.create, required this.builder});

  /// Fabrique le ViewModel (appelée une seule fois).
  final T Function(BuildContext context) create;

  /// Dessine l'écran à partir de l'état du ViewModel.
  final Widget Function(BuildContext context, T vm) builder;

  @override
  State<ViewModelBuilder<T>> createState() => _ViewModelBuilderState<T>();
}

class _ViewModelBuilderState<T extends ChangeNotifier> extends State<ViewModelBuilder<T>> {
  late final T _vm = widget.create(context);

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: _vm, builder: (context, _) => widget.builder(context, _vm));
}
