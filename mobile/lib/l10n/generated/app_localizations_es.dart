// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Planify';

  @override
  String get appTagline => 'Juntadas sin estrés';

  @override
  String get loginUserOrEmail => 'Usuario o Email';

  @override
  String get loginPassword => 'Contraseña';

  @override
  String get loginForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get loginSubmit => 'Ingresar';

  @override
  String get loginOr => 'o';

  @override
  String get loginContinueAnonymous => 'Continuar como Anónimo';

  @override
  String get loginNoAccount => '¿No tienes una cuenta?';

  @override
  String get loginCreateAccount => 'Crear cuenta';

  @override
  String get loginComingSoon => 'Próximamente';

  @override
  String get loginError => 'No pudimos iniciar sesión. Revisá tus datos.';

  @override
  String get loginAnonymousHint =>
      'Para entrar como anónimo necesitás un link de invitación a un evento.';

  @override
  String get loginAnonymousLinkLabel => 'Link de invitación';

  @override
  String get loginAnonymousNameLabel => 'Tu nombre';

  @override
  String get loginAnonymousNameHint => 'ej. Sofía';

  @override
  String get loginPendingInvitation =>
      'Te invitaron a un evento. Iniciá sesión, creá una cuenta o continuá como anónimo para unirte.';

  @override
  String get navHome => 'Inicio';

  @override
  String get navGroups => 'Grupos';

  @override
  String get navBalances => 'Saldos';

  @override
  String get navProfile => 'Perfil';

  @override
  String homeGreeting(String nombre) {
    return '¡Hola, $nombre!';
  }

  @override
  String get homeOwedToMe => 'Me deben';

  @override
  String get homeIOwe => 'Debo';

  @override
  String get homeUpcomingEvents => 'Próximos eventos';

  @override
  String get homeRecentActivity => 'Actividad reciente';

  @override
  String get homeNoEvents => 'Todavía no tenés eventos';

  @override
  String get homeNoEventsHint => 'Creá el primero con el botón +';

  @override
  String get groupsTitle => 'Grupos';

  @override
  String get groupsNoGroups => 'Todavía no tenés grupos';

  @override
  String get groupsNoGroupsHint => 'Se crean solos cuando armás un evento';

  @override
  String get groupsNewEvent => 'NUEVO';

  @override
  String groupsConfirmed(int count) {
    return '$count confirmados';
  }

  @override
  String groupsPendingTasks(int count) {
    return '$count tareas pendientes';
  }

  @override
  String groupsExpenses(int count) {
    return '$count gastos';
  }

  @override
  String get groupsNoUpcoming => 'Sin eventos próximos';

  @override
  String get balancesTitle => 'Saldos';

  @override
  String get balancesNet => 'BALANCE NETO';

  @override
  String get balancesAll => 'Todo';

  @override
  String get balancesOwedToMe => 'Me deben';

  @override
  String get balancesIOwe => 'Debo';

  @override
  String get balancesPerFriend => 'Saldos por amigo';

  @override
  String get balancesEmpty => 'No tenés saldos pendientes';

  @override
  String get balancesEmptyHint => 'Cuando cargues gastos van a aparecer acá';

  @override
  String get balancesStatePay => 'Pagar';

  @override
  String get balancesStatePending => 'Pendiente';

  @override
  String get balancesStateSettled => 'Saldado';

  @override
  String get balancesOweYou => 'Te debe';

  @override
  String get balancesYouOwe => 'Le debés';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileWeeklyAvailability => 'Disponibilidad Semanal';

  @override
  String get profileAvailabilityHint =>
      'Tocá los bloques para marcar tus ratos libres';

  @override
  String get profileHistory => 'Historial de eventos';

  @override
  String get profileLogout => 'Cerrar sesión';

  @override
  String get historyTitle => 'Historial de eventos';

  @override
  String get historyEmpty => 'Todavía no hay eventos pasados';

  @override
  String get historyToPay => 'Por pagar';

  @override
  String get historyYourShare => 'Tu aporte';

  @override
  String get eventCreateTitle => 'Nuevo evento';

  @override
  String get eventStep1Title => '¿Qué sale?';

  @override
  String get eventStep2Title => '¿Con quién?';

  @override
  String get eventNameLabel => 'Nombre del evento';

  @override
  String get eventNameHint => 'Asado en lo de Marcos';

  @override
  String get eventPlaceLabel => '¿Dónde es?';

  @override
  String get eventPlaceHint => 'Casa de Juli';

  @override
  String get eventNext => 'Siguiente';

  @override
  String get eventBack => 'Atrás';

  @override
  String get eventCreate => 'Crear evento';

  @override
  String get eventExistingGroup => 'Usar un grupo existente';

  @override
  String get eventNewGroup => 'Crear un grupo nuevo';

  @override
  String get eventNewGroupName => 'Nombre del grupo';

  @override
  String get eventCreateError => 'No pudimos crear el evento';

  @override
  String get eventDateComesLater =>
      'El horario exacto se define después, cuando todos carguen su disponibilidad dentro del rango elegido';

  @override
  String get eventDateRangeLabel => 'Rango de fechas';

  @override
  String get eventDateRangeExpiredBanner =>
      'El rango de fechas venció y ya se extendió una vez. Elegí un horario para confirmar el evento, o cancelalo desde el feed.';

  @override
  String eventDateRangeShowing(String inicio, String fin) {
    return 'Buscando horario entre $inicio y $fin';
  }

  @override
  String get eventAiButton => 'Generar con IA';

  @override
  String get eventAiTitle => 'Describí tu evento';

  @override
  String get eventAiHint => 'Ej: un asado en casa de Juli con Marcos y Sofía';

  @override
  String get eventAiGenerate => 'Generar';

  @override
  String eventAiUnmatched(String nombres) {
    return 'No encontré entre tus amigos a: $nombres';
  }

  @override
  String get eventSavedPlaces => 'Ubicaciones guardadas';

  @override
  String get eventSavePlace => 'Guardar esta ubicación';

  @override
  String get eventPlaceLabelHint => 'Etiqueta (ej. Casa de Juli)';

  @override
  String get friendMatchesTitle => 'Coincidencias con amigos';

  @override
  String friendMatchesHint(int count) {
    return 'Bloques donde vos y tus amigos ($count) coinciden. Más intenso = más gente libre.';
  }

  @override
  String get eventConfigTitle => 'Configuración del evento';

  @override
  String get eventDetailAvailability => 'Disponibilidad del grupo';

  @override
  String get eventDetailMyAvailability => 'Mi disponibilidad';

  @override
  String get eventDetailSaveAvailability => 'Guardar disponibilidad';

  @override
  String get eventDetailAttendance => '¿Vas?';

  @override
  String get eventDetailGoing => 'Voy';

  @override
  String get eventDetailNotGoing => 'No voy';

  @override
  String get eventDetailTasks => 'Tareas';

  @override
  String get eventDetailNoTasks => 'Todavía no hay tareas';

  @override
  String get eventDetailAddTask => 'Agregar tarea';

  @override
  String get eventDetailTaskTitle => '¿Qué hay que hacer?';

  @override
  String get eventDetailTakeTask => 'Tomar';

  @override
  String get eventDetailCompleteTask => 'Listo';

  @override
  String get eventDetailTaskDone => 'Completada';

  @override
  String get eventDetailTaskUnassigned => 'Sin asignar';

  @override
  String get eventDetailActivityLog => 'Log de Actividad';

  @override
  String get eventDetailQuickActions => 'Acciones rápidas';

  @override
  String get eventDetailAddExpense => 'Gasto';

  @override
  String get eventDetailExpenseDescription => '¿Qué compraste?';

  @override
  String get eventDetailExpenseAmount => 'Monto';

  @override
  String get eventDetailCancelEvent => 'Cancelar evento';

  @override
  String get eventDetailNoActivity => 'Todavía no pasó nada en este evento';

  @override
  String activityEventCreated(String actor) {
    return '$actor creó el evento';
  }

  @override
  String activityScheduleConfirmed(String actor) {
    return '$actor confirmó el horario';
  }

  @override
  String activityExpenseAdded(String actor) {
    return '$actor agregó un gasto';
  }

  @override
  String activityDebtSettled(String actor) {
    return '$actor saldó su deuda';
  }

  @override
  String activityDebtSettledWith(String actor, String personas) {
    return '$actor saldó cuentas con $personas';
  }

  @override
  String activityTaskCreated(String actor) {
    return '$actor creó una tarea';
  }

  @override
  String activityTaskAssigned(String actor) {
    return '$actor se asignó una tarea';
  }

  @override
  String activityTaskCompleted(String actor) {
    return '$actor completó una tarea';
  }

  @override
  String activityJoined(String actor) {
    return '$actor se unió al evento';
  }

  @override
  String activityAttendance(String actor) {
    return '$actor confirmó su asistencia';
  }

  @override
  String activityAvailability(String actor) {
    return '$actor cargó su disponibilidad';
  }

  @override
  String activityCancelled(String actor) {
    return '$actor canceló el evento';
  }

  @override
  String get activityRangeExtended =>
      'El rango de fechas del evento se extendió';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonAdd => 'Agregar';

  @override
  String get commonError => 'Algo salió mal';

  @override
  String get commonErrorHint => 'Revisá que el backend esté corriendo';

  @override
  String get commonLoading => 'Cargando…';

  @override
  String get commonToBeDefined => 'A definir';

  @override
  String get eventDetailCloseExpenses => 'Cerrar gastos';

  @override
  String get eventDetailCancelConfirm =>
      'Se va a cancelar el evento para todos. Esta acción no se puede deshacer.';

  @override
  String get eventDetailCancelled => 'Cancelado';

  @override
  String get eventDetailSettle => 'Saldar';

  @override
  String get eventDetailDebts => 'Deudas del evento';

  @override
  String get eventDetailNoDebts => 'No hay deudas en este evento';

  @override
  String get eventDetailAssignTo => 'Asignar a alguien';

  @override
  String get eventDetailTapToConfirm =>
      'Tocá un bloque del mapa para confirmar el horario';

  @override
  String get eventDetailWhoPaid => '¿Quién pagó?';

  @override
  String get eventDetailDivideBetween => '¿Entre quiénes se divide?';

  @override
  String get eventDetailSelectAtLeastOne =>
      'Debe seleccionar al menos una persona';

  @override
  String get eventDetailExpenseInvalid =>
      'Completá una descripción y un monto válido';

  @override
  String get eventDetailSplitEqually => 'Repartir';

  @override
  String get eventDetailPayersMustSum =>
      'Los aportes de los pagadores deben sumar el total';

  @override
  String eventDetailContributed(String aportado, String total) {
    return 'Aportado: \$$aportado de \$$total';
  }

  @override
  String get eventDetailInvite => 'Invitar';

  @override
  String get eventDetailInviteTitle => 'Invitar al evento';

  @override
  String get eventDetailInviteHint =>
      'Compartí este enlace de invitación con tus amigos para que se sumen al evento:';

  @override
  String get eventDetailCopyLink => 'Copiar enlace';

  @override
  String get eventDetailLinkCopied =>
      '¡Enlace de invitación copiado al portapapeles!';

  @override
  String get eventDetailAddFriends => 'Agregar amigos guardados';

  @override
  String get eventDetailShareLink => 'Compartir link de invitación';

  @override
  String eventDetailFriendsAdded(int count) {
    return '$count agregados al evento';
  }

  @override
  String get groupsManage => 'Administrar grupo';

  @override
  String get groupsRename => 'Cambiar nombre';

  @override
  String get groupsAddMember => 'Agregar amigo';

  @override
  String get groupsLeave => 'Abandonar grupo';

  @override
  String get groupsLeaveConfirm =>
      'Vas a dejar de ver los eventos de este grupo.';

  @override
  String get groupsMembers => 'Miembros';

  @override
  String get groupsNewName => 'Nuevo nombre';

  @override
  String get groupsFriendId => 'ID del amigo';

  @override
  String get friendsPickTitle => 'Elegir amigos';

  @override
  String get friendsEmpty =>
      'Todavía no tenés amigos para agregar. Agregá amigos desde tu perfil.';

  @override
  String friendsPickConfirm(int count) {
    return 'Agregar ($count)';
  }

  @override
  String get friendsTitle => 'Mis amigos';

  @override
  String get friendsSearchHint => 'Buscar por nombre o email';

  @override
  String get friendsAdd => 'Agregar';

  @override
  String get friendsRequests => 'Solicitudes';

  @override
  String get friendsAccept => 'Aceptar';

  @override
  String get friendsRequestSent => 'Solicitud enviada';

  @override
  String get friendsNoResults => 'Sin resultados';

  @override
  String get profileEdit => 'Editar perfil';

  @override
  String get profileName => 'Nombre';

  @override
  String get profileLanguage => 'Idioma';

  @override
  String get profileSave => 'Guardar';

  @override
  String get registerTitle => 'Crear cuenta';

  @override
  String get registerName => 'Nombre';

  @override
  String get registerEmail => 'Email';

  @override
  String get registerPassword => 'Contraseña';

  @override
  String get registerSubmit => 'Registrarme';

  @override
  String get registerHaveAccount => '¿Ya tenés cuenta? Ingresar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String activityExpensesClosed(String actor) {
    return '$actor cerró los gastos';
  }

  @override
  String activityTaskAssignedTo(String actor) {
    return '$actor asignó una tarea';
  }

  @override
  String get homeNoActivity => 'Todavía no hay actividad';

  @override
  String get balancesSettleAll => 'Saldar todo';

  @override
  String balancesSettleAllConfirm(String nombre) {
    return 'Se va a marcar como saldada tu deuda con $nombre.';
  }

  @override
  String balancesSettleAllConfirmMulti(String nombre, int count) {
    return 'Se van a saldar las $count deudas que tenés con $nombre, en todos los eventos.';
  }

  @override
  String get balancesBreakdown => 'DETALLE POR EVENTO';

  @override
  String balancesNoDebtsWith(String nombre) {
    return 'No tenés deudas pendientes con $nombre';
  }

  @override
  String balancesCompensationHint(String debo, String meDeben) {
    return 'Compensado: debés \$$debo y te deben \$$meDeben';
  }
}
