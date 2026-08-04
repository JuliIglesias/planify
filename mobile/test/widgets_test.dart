import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/widgets/avatar_stack.dart';
import 'package:planify/core/widgets/collapsible_section.dart';
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

    testWidgets(
        'el contenedor deja lugar al borde de cada avatar y no lo recorta '
        '(Item 3, Tanda 6)', (tester) async {
      const radius = 14.0;
      await tester.pumpWidget(
        _wrap(const AvatarStack(nombres: ['Ana', 'Beto'], radius: radius)),
      );

      // Antes medía exactamente `radius * 2`: no dejaba lugar al borde
      // blanco de 2px que dibuja cada avatar, y el Stack (que recorta por
      // default) se lo comía arriba y abajo.
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(of: find.byType(AvatarStack), matching: find.byType(SizedBox)).first,
      );
      expect(sizedBox.height, greaterThan(radius * 2));

      final stack = tester.widget<Stack>(
        find.descendant(of: find.byType(AvatarStack), matching: find.byType(Stack)),
      );
      expect(stack.clipBehavior, Clip.none);
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

  group('CollapsibleSection (Item 3)', () {
    testWidgets('arranca cerrada por defecto y se abre al tocar el título',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const CollapsibleSection(
          titulo: 'Mi disponibilidad',
          child: Text('contenido de la grilla'),
        )),
      );

      expect(find.text('Mi disponibilidad'), findsOneWidget);
      expect(find.text('contenido de la grilla'), findsNothing);

      await tester.tap(find.text('Mi disponibilidad'));
      await tester.pumpAndSettle();

      expect(find.text('contenido de la grilla'), findsOneWidget);

      await tester.tap(find.text('Mi disponibilidad'));
      await tester.pumpAndSettle();

      expect(find.text('contenido de la grilla'), findsNothing);
    });

    testWidgets('initiallyExpanded la muestra abierta desde el arranque',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const CollapsibleSection(
          titulo: 'Disponibilidad Semanal',
          initiallyExpanded: true,
          child: Text('contenido de la grilla'),
        )),
      );

      expect(find.text('contenido de la grilla'), findsOneWidget);
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

    testWidgets(
        'el horario fijado se distingue con una estrella en vez del conteo '
        '(Item 5)', (tester) async {
      await tester.pumpWidget(
        _wrap(WeeklyAvailabilityGrid(
          horaInicio: 10,
          horaFin: 12,
          totalParticipantes: 5,
          heatmap: {const AvailabilitySlot(0, 10): 3},
          slotsFijados: {const AvailabilitySlot(0, 10)},
        )),
      );

      // No se ve el número de disponibles ahí: se ve la estrella.
      expect(find.text('3'), findsNothing);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('sin slotsFijados no aparece ninguna estrella', (tester) async {
      await tester.pumpWidget(
        _wrap(WeeklyAvailabilityGrid(
          horaInicio: 10,
          horaFin: 12,
          totalParticipantes: 5,
          heatmap: {const AvailabilitySlot(0, 10): 3},
        )),
      );

      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets(
        'un rango horario fijado (Item 5) pinta con estrella cada slot del '
        'rango, no solo el primero', (tester) async {
      await tester.pumpWidget(
        _wrap(WeeklyAvailabilityGrid(
          horaInicio: 19,
          horaFin: 23,
          totalParticipantes: 5,
          // 19 a 23hs → slots 19, 20, 21, 22 (el fin es el límite, no un slot).
          slotsFijados: {
            const AvailabilitySlot(2, 19),
            const AvailabilitySlot(2, 20),
            const AvailabilitySlot(2, 21),
            const AvailabilitySlot(2, 22),
          },
        )),
      );

      expect(find.byIcon(Icons.star), findsNWidgets(4));
    });
  });
}
