import 'package:flutter/material.dart';

import 'package:pet_sitter/core/theme/app_theme.dart';

const _monthsFr = [
  'Janvier',
  'Février',
  'Mars',
  'Avril',
  'Mai',
  'Juin',
  'Juillet',
  'Août',
  'Septembre',
  'Octobre',
  'Novembre',
  'Décembre',
];

/// Calendrier mensuel léger : disponibles, indisponibles, réservés, plage choisie.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    this.unavailable = const {},
    this.booked = const {},
    this.selectedRange,
    this.today = 16,
    this.onTapDay,
    this.showHeader = true,
  });

  final DateTime month;
  final Set<int> unavailable;
  final Set<int> booked;
  final (int, int)? selectedRange;
  final int today;
  final ValueChanged<int>? onTapDay;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final offset = first.weekday - 1;
    final cells = offset + days;
    final rows = (cells / 7).ceil();

    return Column(
      children: [
        if (showHeader)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [Text('${_monthsFr[month.month - 1]} ${month.year}', style: LPText.title)]),
          ),
        Row(
          children: [
            for (final d in ['L', 'M', 'M', 'J', 'V', 'S', 'D'])
              Expanded(
                child: Center(child: Text(d, style: LPText.overline)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var r = 0; r < rows; r++)
          Row(children: [for (var c = 0; c < 7; c++) Expanded(child: _cell(r * 7 + c - offset + 1, days))]),
      ],
    );
  }

  Widget _cell(int day, int days) {
    if (day < 1 || day > days) return const SizedBox(height: 44);
    final past = day < today;
    final isUnavailable = unavailable.contains(day);
    final isBooked = booked.contains(day);
    final range = selectedRange;
    final inRange = range != null && day >= range.$1 && day <= range.$2;
    final isEdge = range != null && (day == range.$1 || day == range.$2);

    Color? bg;
    Color fg = LP.ink;
    var weight = FontWeight.w500;
    TextDecoration? deco;
    BorderRadius radius = BorderRadius.circular(99);

    if (past) {
      fg = LP.faint;
    } else if (isEdge) {
      bg = LP.primary;
      fg = LP.white;
      weight = FontWeight.w700;
    } else if (inRange) {
      bg = LP.mint;
      fg = LP.primaryDark;
      weight = FontWeight.w600;
      radius = BorderRadius.zero;
    } else if (isBooked) {
      bg = LP.accentSoft;
      fg = LP.accentInk;
      weight = FontWeight.w700;
    } else if (isUnavailable) {
      fg = LP.faint;
      deco = TextDecoration.lineThrough;
    }

    Widget child = Container(
      height: 40,
      margin: EdgeInsets.symmetric(vertical: 2, horizontal: inRange && !isEdge ? 0 : 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: day == today && bg == null ? Border.all(color: LP.accent, width: 1.5) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '$day',
        style: LPText.body(
          size: 14.5,
          w: weight,
          color: fg,
          height: 1,
        ).copyWith(decoration: deco, decorationColor: LP.faint),
      ),
    );
    if (onTapDay != null && !past) {
      child = InkWell(borderRadius: BorderRadius.circular(99), onTap: () => onTapDay!(day), child: child);
    }
    return Semantics(
      label:
          '$day ${isUnavailable
              ? 'indisponible'
              : isBooked
              ? 'réservé'
              : 'disponible'}',
      child: child,
    );
  }
}

class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key, this.withSelection = true});
  final bool withSelection;

  @override
  Widget build(BuildContext context) {
    Widget item(Widget dot, String l) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: 6),
        Text(l, style: LPText.bodyS.copyWith(fontSize: 12.5)),
      ],
    );
    Widget dot(Color c, {Color? border}) => Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: border != null ? Border.all(color: border, width: 1.4) : null,
      ),
    );
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        item(dot(LP.white, border: LP.line), 'Disponible'),
        item(
          Text(
            '12',
            style: LPText.body(size: 12, color: LP.faint).copyWith(decoration: TextDecoration.lineThrough),
          ),
          'Indisponible',
        ),
        item(dot(LP.accentSoft), 'Réservé'),
        if (withSelection) item(dot(LP.primary), 'Vos dates'),
      ],
    );
  }
}
