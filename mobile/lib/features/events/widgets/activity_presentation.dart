import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Cómo se muestra cada tipo de actividad.
///
/// Vive acá y no en una pantalla porque lo usan dos: el feed de Home y el log
/// del evento. El backend manda solo el tipo (`gasto_agregado`), nunca texto
/// traducido, así que la traducción se resuelve en un único lugar.

IconData iconoDeActividad(String tipo) => switch (tipo) {
      'gasto_agregado' => Icons.receipt_long,
      'deuda_saldada' => Icons.price_check,
      'gastos_cerrados' => Icons.lock_outline,
      'tarea_creada' || 'tarea_asignada' => Icons.checklist,
      'tarea_completada' => Icons.task_alt,
      'horario_confirmado' => Icons.event_available,
      'evento_creado' => Icons.celebration_outlined,
      'evento_cancelado' => Icons.event_busy,
      'participante_se_unio' => Icons.person_add,
      'disponibilidad_cargada' => Icons.calendar_month,
      'asistencia_confirmada' => Icons.how_to_reg,
      'rango_extendido' => Icons.date_range,
      _ => Icons.bolt,
    };

Color colorDeActividad(String tipo) => switch (tipo) {
      'gasto_agregado' || 'evento_cancelado' => AppColors.danger,
      'deuda_saldada' || 'tarea_completada' => AppColors.success,
      'horario_confirmado' || 'evento_creado' => AppColors.primary,
      _ => AppColors.warning,
    };

String textoActividad(AppLocalizations l10n, ActividadLog entrada) {
  final actor = entrada.actorUsername;
  return switch (entrada.tipo) {
    'evento_creado' => l10n.activityEventCreated(actor),
    'horario_confirmado' => l10n.activityScheduleConfirmed(actor),
    'gasto_agregado' => l10n.activityExpenseAdded(actor),
    'gastos_cerrados' => l10n.activityExpensesClosed(actor),
    'deuda_saldada' => l10n.activityDebtSettled(actor),
    'tarea_creada' => l10n.activityTaskCreated(actor),
    // El payload distingue "me la tomé" de "se la asigné a alguien".
    'tarea_asignada' => (entrada.payload?['autoAsignada'] as bool? ?? true)
        ? l10n.activityTaskAssigned(actor)
        : l10n.activityTaskAssignedTo(actor),
    'tarea_completada' => l10n.activityTaskCompleted(actor),
    'participante_se_unio' => l10n.activityJoined(actor),
    'asistencia_confirmada' => l10n.activityAttendance(actor),
    'disponibilidad_cargada' => l10n.activityAvailability(actor),
    'evento_cancelado' => l10n.activityCancelled(actor),
    // Disparado por el sistema (Item 1), no por un participante real.
    'rango_extendido' => l10n.activityRangeExtended,
    _ => actor,
  };
}

/// El monto que muestra el feed a la derecha, cuando la actividad tiene uno.
String? montoDeActividad(ActividadLog entrada) {
  final monto = entrada.payload?['monto'];
  if (monto == null) return null;

  return switch (entrada.tipo) {
    'gasto_agregado' => '-\$$monto',
    'deuda_saldada' => '+\$$monto',
    _ => '\$$monto',
  };
}

/// Item 2 — una entrada de actividad ya agrupada. `entrada` es la primera
/// del grupo (de ahí salen ícono/texto/hora); `cantidad`, cuántas se
/// fusionaron en esa línea.
class ActividadAgrupada {
  const ActividadAgrupada({required this.entrada, required this.cantidad});
  final ActividadLog entrada;
  final int cantidad;
}

/// Agrupa entradas consecutivas del mismo actor + mismo tipo + mismo evento
/// en una sola línea, y corta en [limite] grupos. Así una racha de acciones
/// iguales seguidas (ej. saldar gasto tras gasto) no se come todo el espacio
/// del feed de "Actividad reciente" — cada grupo cuenta como una sola
/// entrada dentro del tope, liberando lugar para actividad distinta.
List<ActividadAgrupada> agruparActividades(List<ActividadLog> entradas, {int limite = 5}) {
  final resultado = <ActividadAgrupada>[];
  for (final entrada in entradas) {
    if (resultado.isNotEmpty) {
      final ultimo = resultado.last;
      if (ultimo.entrada.actorUsername == entrada.actorUsername &&
          ultimo.entrada.tipo == entrada.tipo &&
          ultimo.entrada.eventoId == entrada.eventoId) {
        resultado[resultado.length - 1] =
            ActividadAgrupada(entrada: ultimo.entrada, cantidad: ultimo.cantidad + 1);
        continue;
      }
    }
    // No agrega una línea nueva pasado el tope, pero sigue recorriendo el
    // resto — una entrada más adelante todavía puede fusionarse con la
    // última línea ya agregada (`continue`, no `break`).
    if (resultado.length >= limite) continue;
    resultado.add(ActividadAgrupada(entrada: entrada, cantidad: 1));
  }
  return resultado;
}

/// El texto de una entrada agrupada: el texto normal + "(×N)" si se
/// fusionaron varias, sin nombrar a nadie más que el actor — en Home no se
/// especifica con quién, a diferencia del log del evento (Item 2).
String textoActividadAgrupada(AppLocalizations l10n, ActividadAgrupada grupo) {
  final base = textoActividad(l10n, grupo.entrada);
  return grupo.cantidad > 1 ? '$base (×${grupo.cantidad})' : base;
}

/// Item 2 — dentro del log de UN evento (a diferencia del feed de Home) sí
/// interesa saber con quién: varios "saldó su deuda" seguidos del mismo
/// actor se fusionan nombrando a todas las contrapartes.
class ActividadLogAgrupada {
  const ActividadLogAgrupada({required this.entrada, required this.contrapartes});
  final ActividadLog entrada;
  final List<String> contrapartes;
}

List<ActividadLogAgrupada> agruparLogDeEvento(List<ActividadLog> entradas) {
  final resultado = <ActividadLogAgrupada>[];
  for (final entrada in entradas) {
    final esSaldado = entrada.tipo == 'deuda_saldada';
    final contraparte = entrada.payload?['contraparteNombre'] as String?;

    if (esSaldado && resultado.isNotEmpty) {
      final ultimo = resultado.last;
      if (ultimo.entrada.tipo == 'deuda_saldada' &&
          ultimo.entrada.actorUsername == entrada.actorUsername) {
        resultado[resultado.length - 1] = ActividadLogAgrupada(
          entrada: ultimo.entrada,
          contrapartes: [
            ...ultimo.contrapartes,
            if (contraparte != null && contraparte.isNotEmpty) contraparte,
          ],
        );
        continue;
      }
    }

    resultado.add(ActividadLogAgrupada(
      entrada: entrada,
      contrapartes: esSaldado && contraparte != null && contraparte.isNotEmpty
          ? [contraparte]
          : const [],
    ));
  }
  return resultado;
}

String textoActividadLogAgrupada(AppLocalizations l10n, ActividadLogAgrupada grupo) {
  if (grupo.entrada.tipo == 'deuda_saldada' && grupo.contrapartes.length > 1) {
    return l10n.activityDebtSettledWith(
      grupo.entrada.actorUsername,
      _formatearNombres(grupo.contrapartes),
    );
  }
  return textoActividad(l10n, grupo.entrada);
}

String _formatearNombres(List<String> nombres) {
  if (nombres.length == 1) return nombres.first;
  return '${nombres.sublist(0, nombres.length - 1).join(', ')} y ${nombres.last}';
}
