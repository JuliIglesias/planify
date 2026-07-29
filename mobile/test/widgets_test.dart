import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/widgets/avatar_stack.dart';
import 'package:planify/core/widgets/event_card.dart';
import 'package:planify/core/widgets/status_badge.dart';
import 'package:planify/core/widgets/weekly_availability_grid.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('StatusBadge', () {
    testWidgets('muestra el texto además del color (accesibilidad)', (tester) async {
      await tester.pumpWidget(
        _wrap(StatusBadge.saldo(SaldoEstado.pendiente, 'Pendiente')),
      );

      expect(find.text('PENDIENTE'), findsOneWidget);
    });
  });

  group('AvatarStack', () {
    testWidgets('muestra iniciales y el contador de restantes', (tester) async {
      await tester.pumpWidget(
        _wrap(const AvatarStack(nombres: ['Ana Perez', 'Beto', 'Caro', 'Dani', 'Eve'])),
      );

      expect(find.text('AP'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('no rompe con la lista vacía', (tester) async {
      await tester.pumpWidget(_wrap(const AvatarStack(nombres: [])));
      expect(tester.takeException(), isNull);
    });
  });

  group('EventCard', () {
    testWidgets('muestra título, subtítulo, chips y monto', (tester) async {
      await tester.pumpWidget(
        _wrap(const EventCard(
          titulo: 'Asado en lo de Marcos',
          subtitulo: 'Jueves 12 · Casa de Nacho',
          participantes: ['Ana', 'Beto'],
          chips: ['4 confirmados'],
          montoLabel: 'Por pagar',
          monto: r'$1.200',
        )),
      );

      expect(find.text('Asado en lo de Marcos'), findsOneWidget);
      expect(find.text('Jueves 12 · Casa de Nacho'), findsOneWidget);
      expect(find.text('4 confirmados'), findsOneWidget);
      expect(find.text(r'$1.200'), findsOneWidget);
    });
  });

  group('WeeklyAvailabilityGrid', () {
    testWidgets('en modo editable notifica el slot tocado', (tester) async {
      AvailabilitySlot? tocado;

      await tester.pumpWidget(
        _wrap(WeeklyAvailabilityGrid(
          horaInicio: 10,
          horaFin: 12,
          onToggle: (slot) => tocado = slot,
        )),
      );

      // Primera celda de la grilla: lunes, 10h.
      await tester.tap(find.byType(GestureDetector).first);
      expect(tocado, const AvailabilitySlot(0, 10));
    });

    testWidgets('en modo heatmap muestra cuántos pueden y no es editable',
        (tester) async {
      await tester.pumpWidget(
        _wrap(WeeklyAvailabilityGrid(
          horaInicio: 10,
          horaFin: 12,
          totalParticipantes: 5,
          heatmap: {const AvailabilitySlot(0, 10): 3},
        )),
      );

      expect(find.text('3'), findsOneWidget);
    });
  });
}
