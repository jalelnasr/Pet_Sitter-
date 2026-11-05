/// Mise en forme des dates à la française (« ven. 23 oct. »).
library;

String frDate(DateTime d, {bool weekday = true}) {
  const days = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
  const months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
  final w = weekday ? '${days[d.weekday - 1]} ' : '';
  return '$w${d.day} ${months[d.month - 1]}';
}

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
