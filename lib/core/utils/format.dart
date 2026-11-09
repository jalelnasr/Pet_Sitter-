/// Mise en forme des dates à la française (« ven. 23 oct. »).
library;

String frDate(DateTime d, {bool weekday = true}) {
  const days = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
  const months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
  final w = weekday ? '${days[d.weekday - 1]} ' : '';
  return '$w${d.day} ${months[d.month - 1]}';
}

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _two(int v) => v.toString().padLeft(2, '0');

/// Heure courte : « 08:50 ».
String clockTime(DateTime d) {
  final l = d.toLocal();
  return '${_two(l.hour)}:${_two(l.minute)}';
}

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Moment d'un message dans la liste des conversations : « 08:53 », « Hier », « lun. », « 12 oct. ».
String chatListTime(DateTime d, {DateTime? now}) {
  final l = d.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  if (_sameDay(l, today)) return clockTime(l);
  if (_sameDay(l, today.subtract(const Duration(days: 1)))) return 'Hier';
  if (today.difference(l).inDays < 7) {
    const days = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
    return capitalize(days[l.weekday - 1]);
  }
  return frDate(l, weekday: false);
}

/// Séparateur de jour dans une conversation : « Aujourd'hui », « Hier », « Jeudi 22 octobre ».
String chatDayLabel(DateTime d, {DateTime? now}) {
  final l = d.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  if (_sameDay(l, today)) return "Aujourd'hui";
  if (_sameDay(l, today.subtract(const Duration(days: 1)))) return 'Hier';
  const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
  const months = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  final year = l.year == today.year ? '' : ' ${l.year}';
  return '${days[l.weekday - 1]} ${l.day} ${months[l.month - 1]}$year';
}

/// Vrai si les deux dates tombent le même jour (heure locale).
bool sameDay(DateTime a, DateTime b) => _sameDay(a.toLocal(), b.toLocal());
