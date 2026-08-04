import 'package:flutter_test/flutter_test.dart';
import 'package:planify/core/models/models.dart';
import 'package:planify/features/events/widgets/activity_presentation.dart';
import 'package:planify/l10n/generated/app_localizations.dart';

import 'helpers/test_app.dart';

/// Item 2 (Fase 4) — agrupación de "Actividad reciente" (Home, genérica,
/// tope 5) y del log de un evento (nombra contrapartes al saldar deudas).
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await prepararLocalizaciones();
  });

  ActividadLog entrada({
    required String tipo,
    required String actor,
    String eventoId = 'evt-1',
    String? contraparteNombre,
  }) =>
      ActividadLog(
        id: 'a-${DateTime.now().microsecondsSinceEpoch}-${actor}_$tipo$eventoId'
            '${contraparteNombre ?? ''}',
        tipo: tipo,
        actorUsername: actor,
        createdAt: DateTime(2026, 8, 1),
        eventoId: eventoId,
        payload: contraparteNombre != null ? {'contraparteNombre': contraparteNombre} : null,
      );

  group('agruparActividades (Home)', () {
    test('agrupa mismo actor + mismo tipo + mismo evento consecutivos', () {
      final entradas = [
        entrada(tipo: 'deuda_saldada', actor: 'Marcos'),
        entrada(tipo: 'deuda_saldada', actor: 'Marcos'),
        entrada(tipo: 'deuda_saldada', actor: 'Marcos'),
      ];

      final grupos = agruparActividades(entradas);

      expect(grupos, hasLength(1));
      expect(grupos.first.cantidad, 3);
      expect(textoActividadAgrupada(l10n, grupos.first),
          '${l10n.activityDebtSettled('Marcos')} (×3)');
    });

    test('no agrupa si se interrumpe con otro tipo/actor en el medio', () {
      final entradas = [
        entrada(tipo: 'deuda_saldada', actor: 'Marcos'),
        entrada(tipo: 'tarea_creada', actor: 'Marcos'),
        entrada(tipo: 'deuda_saldada', actor: 'Marcos'),
      ];

      final grupos = agruparActividades(entradas);

      expect(grupos, hasLength(3));
      expect(grupos.every((g) => g.cantidad == 1), isTrue);
    });

    test('no agrupa el mismo tipo+actor si vienen de eventos distintos', () {
      final entradas = [
        entrada(tipo: 'deuda_saldada', actor: 'Marcos', eventoId: 'evt-1'),
        entrada(tipo: 'deuda_saldada', actor: 'Marcos', eventoId: 'evt-2'),
      ];

      expect(agruparActividades(entradas), hasLength(2));
    });

    test('nunca devuelve más de 5 grupos, pero sigue fusionando el último',
        () {
      final entradas = [
        for (final actor in ['A', 'B', 'C', 'D', 'E', 'F'])
          entrada(tipo: 'tarea_creada', actor: actor),
        // Una racha más del último actor que sí entró (E): se fusiona en su
        // grupo sin agregar una 6ta línea.
        entrada(tipo: 'tarea_creada', actor: 'E'),
      ];

      final grupos = agruparActividades(entradas, limite: 5);

      expect(grupos, hasLength(5));
      expect(grupos.map((g) => g.entrada.actorUsername), ['A', 'B', 'C', 'D', 'E']);
      expect(grupos.last.cantidad, 2);
    });
  });

  group('agruparLogDeEvento (dentro de un evento)', () {
    test('varias deudas saldadas seguidas del mismo actor nombran a todas las '
        'contrapartes', () {
      final entradas = [
        entrada(tipo: 'deuda_saldada', actor: 'Marcos', contraparteNombre: 'Sofía'),
        entrada(tipo: 'deuda_saldada', actor: 'Marcos', contraparteNombre: 'Juan'),
        entrada(tipo: 'deuda_saldada', actor: 'Marcos', contraparteNombre: 'Pedro'),
      ];

      final grupos = agruparLogDeEvento(entradas);

      expect(grupos, hasLength(1));
      expect(
        textoActividadLogAgrupada(l10n, grupos.first),
        l10n.activityDebtSettledWith('Marcos', 'Sofía, Juan y Pedro'),
      );
    });

    test('una sola deuda saldada no cambia el texto habitual', () {
      final entradas = [
        entrada(tipo: 'deuda_saldada', actor: 'Marcos', contraparteNombre: 'Sofía'),
      ];

      final grupos = agruparLogDeEvento(entradas);

      expect(textoActividadLogAgrupada(l10n, grupos.first),
          l10n.activityDebtSettled('Marcos'));
    });

    test('actividades de otro tipo no se agrupan entre sí', () {
      final entradas = [
        entrada(tipo: 'tarea_creada', actor: 'Marcos'),
        entrada(tipo: 'tarea_creada', actor: 'Marcos'),
      ];

      final grupos = agruparLogDeEvento(entradas);

      expect(grupos, hasLength(2));
    });
  });
}
