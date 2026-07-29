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
      _ => Icons.bolt,
    };

Color colorDeActividad(String tipo) => switch (tipo) {
      'gasto_agregado' || 'evento_cancelado' => AppColors.danger,
      'deuda_saldada' || 'tarea_completada' => AppColors.success,
      'horario_confirmado' || 'evento_creado' => AppColors.primary,
      _ => AppColors.warning,
    };

String textoActividad(AppLocalizations l10n, ActividadLog entrada) {
  final actor = entrada.actorNombre;
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
