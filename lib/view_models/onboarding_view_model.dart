import 'package:pet_sitter/core/mvvm/view_model.dart';

/// Guide de bienvenue : quel écran est affiché, et est-ce le dernier ?
class OnboardingViewModel extends ViewModel {
  OnboardingViewModel({this.pageCount = 3, int initialPage = 0}) : _page = initialPage;

  final int pageCount;
  int _page;
  int get page => _page;
  bool get isLast => _page == pageCount - 1;

  void setPage(int p) {
    if (p == _page) return;
    _page = p;
    notify();
  }
}
