import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appName.
  ///
  /// In es, this message translates to:
  /// **'Planify'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In es, this message translates to:
  /// **'Juntadas sin estrés'**
  String get appTagline;

  /// No description provided for @loginUserOrEmail.
  ///
  /// In es, this message translates to:
  /// **'Usuario o Email'**
  String get loginUserOrEmail;

  /// No description provided for @loginPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get loginPassword;

  /// No description provided for @loginForgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get loginForgotPassword;

  /// No description provided for @loginSubmit.
  ///
  /// In es, this message translates to:
  /// **'Ingresar'**
  String get loginSubmit;

  /// No description provided for @loginOr.
  ///
  /// In es, this message translates to:
  /// **'o'**
  String get loginOr;

  /// No description provided for @loginContinueAnonymous.
  ///
  /// In es, this message translates to:
  /// **'Continuar como Anónimo'**
  String get loginContinueAnonymous;

  /// No description provided for @loginNoAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes una cuenta?'**
  String get loginNoAccount;

  /// No description provided for @loginCreateAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get loginCreateAccount;

  /// No description provided for @loginComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get loginComingSoon;

  /// No description provided for @loginError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos iniciar sesión. Revisá tus datos.'**
  String get loginError;

  /// No description provided for @loginAnonymousHint.
  ///
  /// In es, this message translates to:
  /// **'Para entrar como anónimo necesitás un link de invitación a un evento.'**
  String get loginAnonymousHint;

  /// No description provided for @loginAnonymousLinkLabel.
  ///
  /// In es, this message translates to:
  /// **'Link de invitación'**
  String get loginAnonymousLinkLabel;

  /// No description provided for @loginAnonymousNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Tu username'**
  String get loginAnonymousNameLabel;

  /// No description provided for @loginAnonymousNameHint.
  ///
  /// In es, this message translates to:
  /// **'ej. Sofía'**
  String get loginAnonymousNameHint;

  /// No description provided for @loginPendingInvitation.
  ///
  /// In es, this message translates to:
  /// **'Te invitaron a un evento. Iniciá sesión, creá una cuenta o continuá como anónimo para unirte.'**
  String get loginPendingInvitation;

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// No description provided for @navGroups.
  ///
  /// In es, this message translates to:
  /// **'Grupos'**
  String get navGroups;

  /// No description provided for @navBalances.
  ///
  /// In es, this message translates to:
  /// **'Saldos'**
  String get navBalances;

  /// No description provided for @navProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @homeGreeting.
  ///
  /// In es, this message translates to:
  /// **'¡Hola, {username}!'**
  String homeGreeting(String username);

  /// No description provided for @homeOwedToMe.
  ///
  /// In es, this message translates to:
  /// **'Me deben'**
  String get homeOwedToMe;

  /// No description provided for @homeIOwe.
  ///
  /// In es, this message translates to:
  /// **'Debo'**
  String get homeIOwe;

  /// No description provided for @homeUpcomingEvents.
  ///
  /// In es, this message translates to:
  /// **'Próximos eventos'**
  String get homeUpcomingEvents;

  /// No description provided for @homeRecentActivity.
  ///
  /// In es, this message translates to:
  /// **'Actividad reciente'**
  String get homeRecentActivity;

  /// No description provided for @homeNoEvents.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tenés eventos'**
  String get homeNoEvents;

  /// No description provided for @homeNoEventsHint.
  ///
  /// In es, this message translates to:
  /// **'Creá el primero con el botón +'**
  String get homeNoEventsHint;

  /// No description provided for @groupsTitle.
  ///
  /// In es, this message translates to:
  /// **'Grupos'**
  String get groupsTitle;

  /// No description provided for @groupsNoGroups.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tenés grupos'**
  String get groupsNoGroups;

  /// No description provided for @groupsNoGroupsHint.
  ///
  /// In es, this message translates to:
  /// **'Se crean solos cuando armás un evento'**
  String get groupsNoGroupsHint;

  /// No description provided for @groupsNewEvent.
  ///
  /// In es, this message translates to:
  /// **'NUEVO'**
  String get groupsNewEvent;

  /// No description provided for @groupsConfirmed.
  ///
  /// In es, this message translates to:
  /// **'{count} confirmados'**
  String groupsConfirmed(int count);

  /// No description provided for @groupsPendingTasks.
  ///
  /// In es, this message translates to:
  /// **'{count} tareas pendientes'**
  String groupsPendingTasks(int count);

  /// No description provided for @groupsExpenses.
  ///
  /// In es, this message translates to:
  /// **'{count} gastos'**
  String groupsExpenses(int count);

  /// No description provided for @groupsNoUpcoming.
  ///
  /// In es, this message translates to:
  /// **'Sin eventos próximos'**
  String get groupsNoUpcoming;

  /// No description provided for @balancesTitle.
  ///
  /// In es, this message translates to:
  /// **'Saldos'**
  String get balancesTitle;

  /// No description provided for @balancesNet.
  ///
  /// In es, this message translates to:
  /// **'BALANCE NETO'**
  String get balancesNet;

  /// No description provided for @balancesAll.
  ///
  /// In es, this message translates to:
  /// **'Todo'**
  String get balancesAll;

  /// No description provided for @balancesOwedToMe.
  ///
  /// In es, this message translates to:
  /// **'Me deben'**
  String get balancesOwedToMe;

  /// No description provided for @balancesIOwe.
  ///
  /// In es, this message translates to:
  /// **'Debo'**
  String get balancesIOwe;

  /// No description provided for @balancesPerFriend.
  ///
  /// In es, this message translates to:
  /// **'Saldos por amigo'**
  String get balancesPerFriend;

  /// No description provided for @balancesEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tenés saldos pendientes'**
  String get balancesEmpty;

  /// No description provided for @balancesEmptyHint.
  ///
  /// In es, this message translates to:
  /// **'Cuando cargues gastos van a aparecer acá'**
  String get balancesEmptyHint;

  /// No description provided for @balancesStatePay.
  ///
  /// In es, this message translates to:
  /// **'Pagar'**
  String get balancesStatePay;

  /// No description provided for @balancesStatePending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get balancesStatePending;

  /// No description provided for @balancesStateSettled.
  ///
  /// In es, this message translates to:
  /// **'Saldado'**
  String get balancesStateSettled;

  /// No description provided for @balancesOweYou.
  ///
  /// In es, this message translates to:
  /// **'Te debe'**
  String get balancesOweYou;

  /// No description provided for @balancesYouOwe.
  ///
  /// In es, this message translates to:
  /// **'Le debés'**
  String get balancesYouOwe;

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profileTitle;

  /// No description provided for @profileWeeklyAvailability.
  ///
  /// In es, this message translates to:
  /// **'Disponibilidad Semanal'**
  String get profileWeeklyAvailability;

  /// No description provided for @profileAvailabilityHint.
  ///
  /// In es, this message translates to:
  /// **'Tocá los bloques para marcar tus ratos libres'**
  String get profileAvailabilityHint;

  /// No description provided for @profileHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial de eventos'**
  String get profileHistory;

  /// No description provided for @profileLogout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get profileLogout;

  /// No description provided for @historyTitle.
  ///
  /// In es, this message translates to:
  /// **'Historial de eventos'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay eventos pasados'**
  String get historyEmpty;

  /// No description provided for @historyToPay.
  ///
  /// In es, this message translates to:
  /// **'Por pagar'**
  String get historyToPay;

  /// No description provided for @historyYourShare.
  ///
  /// In es, this message translates to:
  /// **'Tu aporte'**
  String get historyYourShare;

  /// No description provided for @eventCreateTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo evento'**
  String get eventCreateTitle;

  /// No description provided for @eventStep1Title.
  ///
  /// In es, this message translates to:
  /// **'¿Qué sale?'**
  String get eventStep1Title;

  /// No description provided for @eventStep2Title.
  ///
  /// In es, this message translates to:
  /// **'¿Con quién?'**
  String get eventStep2Title;

  /// No description provided for @eventNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del evento'**
  String get eventNameLabel;

  /// No description provided for @eventNameHint.
  ///
  /// In es, this message translates to:
  /// **'Asado en lo de Marcos'**
  String get eventNameHint;

  /// No description provided for @eventPlaceLabel.
  ///
  /// In es, this message translates to:
  /// **'¿Dónde es?'**
  String get eventPlaceLabel;

  /// No description provided for @eventPlaceHint.
  ///
  /// In es, this message translates to:
  /// **'Casa de Juli'**
  String get eventPlaceHint;

  /// No description provided for @eventNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get eventNext;

  /// No description provided for @eventBack.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get eventBack;

  /// No description provided for @eventCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear evento'**
  String get eventCreate;

  /// No description provided for @eventExistingGroup.
  ///
  /// In es, this message translates to:
  /// **'Usar un grupo existente'**
  String get eventExistingGroup;

  /// No description provided for @eventNewGroup.
  ///
  /// In es, this message translates to:
  /// **'Crear un grupo nuevo'**
  String get eventNewGroup;

  /// No description provided for @eventNewGroupName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del grupo'**
  String get eventNewGroupName;

  /// No description provided for @eventCreateError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos crear el evento'**
  String get eventCreateError;

  /// No description provided for @eventDateComesLater.
  ///
  /// In es, this message translates to:
  /// **'El horario exacto se define después, cuando todos carguen su disponibilidad dentro del rango elegido'**
  String get eventDateComesLater;

  /// No description provided for @eventDateRangeLabel.
  ///
  /// In es, this message translates to:
  /// **'Rango de fechas'**
  String get eventDateRangeLabel;

  /// No description provided for @eventDateRangeExpiredBanner.
  ///
  /// In es, this message translates to:
  /// **'El rango de fechas venció y ya se extendió una vez. Elegí un horario para confirmar el evento, o cancelalo desde el feed.'**
  String get eventDateRangeExpiredBanner;

  /// No description provided for @eventDateRangeShowing.
  ///
  /// In es, this message translates to:
  /// **'Buscando horario entre {inicio} y {fin}'**
  String eventDateRangeShowing(String inicio, String fin);

  /// No description provided for @eventAiButton.
  ///
  /// In es, this message translates to:
  /// **'Generar con IA'**
  String get eventAiButton;

  /// No description provided for @eventAiTitle.
  ///
  /// In es, this message translates to:
  /// **'Describí tu evento'**
  String get eventAiTitle;

  /// No description provided for @eventAiHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: un asado en casa de Juli con Marcos y Sofía'**
  String get eventAiHint;

  /// No description provided for @eventAiGenerate.
  ///
  /// In es, this message translates to:
  /// **'Generar'**
  String get eventAiGenerate;

  /// No description provided for @eventAiUnmatched.
  ///
  /// In es, this message translates to:
  /// **'No encontré entre tus amigos a: {nombres}'**
  String eventAiUnmatched(String nombres);

  /// No description provided for @eventSavedPlaces.
  ///
  /// In es, this message translates to:
  /// **'Ubicaciones guardadas'**
  String get eventSavedPlaces;

  /// No description provided for @eventSavePlace.
  ///
  /// In es, this message translates to:
  /// **'Guardar esta ubicación'**
  String get eventSavePlace;

  /// No description provided for @eventPlaceLabelHint.
  ///
  /// In es, this message translates to:
  /// **'Etiqueta (ej. Casa de Juli)'**
  String get eventPlaceLabelHint;

  /// No description provided for @groupAvailabilityTitle.
  ///
  /// In es, this message translates to:
  /// **'Disponibilidad del grupo'**
  String get groupAvailabilityTitle;

  /// No description provided for @groupAvailabilityHint.
  ///
  /// In es, this message translates to:
  /// **'Bloques donde los miembros de este grupo ({count}) coinciden. Más intenso = más gente libre.'**
  String groupAvailabilityHint(int count);

  /// No description provided for @groupsSeeAvailability.
  ///
  /// In es, this message translates to:
  /// **'Ver disponibilidad del grupo'**
  String get groupsSeeAvailability;

  /// No description provided for @eventConfigTitle.
  ///
  /// In es, this message translates to:
  /// **'Configuración del evento'**
  String get eventConfigTitle;

  /// No description provided for @eventDetailAvailability.
  ///
  /// In es, this message translates to:
  /// **'Disponibilidad del grupo'**
  String get eventDetailAvailability;

  /// No description provided for @eventDetailMyAvailability.
  ///
  /// In es, this message translates to:
  /// **'Mi disponibilidad'**
  String get eventDetailMyAvailability;

  /// No description provided for @eventDetailSaveAvailability.
  ///
  /// In es, this message translates to:
  /// **'Guardar disponibilidad'**
  String get eventDetailSaveAvailability;

  /// No description provided for @eventDetailAttendance.
  ///
  /// In es, this message translates to:
  /// **'¿Vas?'**
  String get eventDetailAttendance;

  /// No description provided for @eventDetailGoing.
  ///
  /// In es, this message translates to:
  /// **'Voy'**
  String get eventDetailGoing;

  /// No description provided for @eventDetailNotGoing.
  ///
  /// In es, this message translates to:
  /// **'No voy'**
  String get eventDetailNotGoing;

  /// No description provided for @eventDetailTasks.
  ///
  /// In es, this message translates to:
  /// **'Tareas'**
  String get eventDetailTasks;

  /// No description provided for @eventDetailNoTasks.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay tareas'**
  String get eventDetailNoTasks;

  /// No description provided for @eventDetailAddTask.
  ///
  /// In es, this message translates to:
  /// **'Agregar tarea'**
  String get eventDetailAddTask;

  /// No description provided for @eventDetailTaskTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué hay que hacer?'**
  String get eventDetailTaskTitle;

  /// No description provided for @eventDetailTakeTask.
  ///
  /// In es, this message translates to:
  /// **'Tomar'**
  String get eventDetailTakeTask;

  /// No description provided for @eventDetailCompleteTask.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get eventDetailCompleteTask;

  /// No description provided for @eventDetailTaskDone.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get eventDetailTaskDone;

  /// No description provided for @eventDetailTaskUnassigned.
  ///
  /// In es, this message translates to:
  /// **'Sin asignar'**
  String get eventDetailTaskUnassigned;

  /// No description provided for @eventDetailActivityLog.
  ///
  /// In es, this message translates to:
  /// **'Log de Actividad'**
  String get eventDetailActivityLog;

  /// No description provided for @eventDetailQuickActions.
  ///
  /// In es, this message translates to:
  /// **'Acciones rápidas'**
  String get eventDetailQuickActions;

  /// No description provided for @eventDetailAddExpense.
  ///
  /// In es, this message translates to:
  /// **'Gasto'**
  String get eventDetailAddExpense;

  /// No description provided for @eventDetailExpenseDescription.
  ///
  /// In es, this message translates to:
  /// **'¿Qué compraste?'**
  String get eventDetailExpenseDescription;

  /// No description provided for @eventDetailExpenseAmount.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get eventDetailExpenseAmount;

  /// No description provided for @eventDetailCancelEvent.
  ///
  /// In es, this message translates to:
  /// **'Cancelar evento'**
  String get eventDetailCancelEvent;

  /// No description provided for @eventDetailNoActivity.
  ///
  /// In es, this message translates to:
  /// **'Todavía no pasó nada en este evento'**
  String get eventDetailNoActivity;

  /// No description provided for @activityEventCreated.
  ///
  /// In es, this message translates to:
  /// **'{actor} creó el evento'**
  String activityEventCreated(String actor);

  /// No description provided for @activityScheduleConfirmed.
  ///
  /// In es, this message translates to:
  /// **'{actor} confirmó el horario'**
  String activityScheduleConfirmed(String actor);

  /// No description provided for @activityExpenseAdded.
  ///
  /// In es, this message translates to:
  /// **'{actor} agregó un gasto'**
  String activityExpenseAdded(String actor);

  /// No description provided for @activityDebtSettled.
  ///
  /// In es, this message translates to:
  /// **'{actor} saldó su deuda'**
  String activityDebtSettled(String actor);

  /// No description provided for @activityDebtSettledWith.
  ///
  /// In es, this message translates to:
  /// **'{actor} saldó cuentas con {personas}'**
  String activityDebtSettledWith(String actor, String personas);

  /// No description provided for @activityTaskCreated.
  ///
  /// In es, this message translates to:
  /// **'{actor} creó una tarea'**
  String activityTaskCreated(String actor);

  /// No description provided for @activityTaskAssigned.
  ///
  /// In es, this message translates to:
  /// **'{actor} se asignó una tarea'**
  String activityTaskAssigned(String actor);

  /// No description provided for @activityTaskCompleted.
  ///
  /// In es, this message translates to:
  /// **'{actor} completó una tarea'**
  String activityTaskCompleted(String actor);

  /// No description provided for @activityJoined.
  ///
  /// In es, this message translates to:
  /// **'{actor} se unió al evento'**
  String activityJoined(String actor);

  /// No description provided for @activityAttendance.
  ///
  /// In es, this message translates to:
  /// **'{actor} confirmó su asistencia'**
  String activityAttendance(String actor);

  /// No description provided for @activityAvailability.
  ///
  /// In es, this message translates to:
  /// **'{actor} cargó su disponibilidad'**
  String activityAvailability(String actor);

  /// No description provided for @activityCancelled.
  ///
  /// In es, this message translates to:
  /// **'{actor} canceló el evento'**
  String activityCancelled(String actor);

  /// No description provided for @activityRangeExtended.
  ///
  /// In es, this message translates to:
  /// **'El rango de fechas del evento se extendió'**
  String get activityRangeExtended;

  /// No description provided for @commonSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonAdd.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get commonAdd;

  /// No description provided for @commonError.
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal'**
  String get commonError;

  /// No description provided for @commonErrorHint.
  ///
  /// In es, this message translates to:
  /// **'Revisá que el backend esté corriendo'**
  String get commonErrorHint;

  /// No description provided for @commonLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando…'**
  String get commonLoading;

  /// No description provided for @commonToBeDefined.
  ///
  /// In es, this message translates to:
  /// **'A definir'**
  String get commonToBeDefined;

  /// No description provided for @eventDetailCloseExpenses.
  ///
  /// In es, this message translates to:
  /// **'Cerrar gastos'**
  String get eventDetailCloseExpenses;

  /// No description provided for @eventDetailCancelConfirm.
  ///
  /// In es, this message translates to:
  /// **'Se va a cancelar el evento para todos. Esta acción no se puede deshacer.'**
  String get eventDetailCancelConfirm;

  /// No description provided for @eventDetailCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get eventDetailCancelled;

  /// No description provided for @eventDetailSettle.
  ///
  /// In es, this message translates to:
  /// **'Saldar'**
  String get eventDetailSettle;

  /// No description provided for @eventDetailDebts.
  ///
  /// In es, this message translates to:
  /// **'Deudas del evento'**
  String get eventDetailDebts;

  /// No description provided for @eventDetailNoDebts.
  ///
  /// In es, this message translates to:
  /// **'No hay deudas en este evento'**
  String get eventDetailNoDebts;

  /// No description provided for @eventDetailAssignTo.
  ///
  /// In es, this message translates to:
  /// **'Asignar a alguien'**
  String get eventDetailAssignTo;

  /// No description provided for @eventDetailTapToConfirm.
  ///
  /// In es, this message translates to:
  /// **'Tocá un bloque del mapa para confirmar el horario'**
  String get eventDetailTapToConfirm;

  /// No description provided for @eventDetailPickEndTime.
  ///
  /// In es, this message translates to:
  /// **'¿Hasta qué hora?'**
  String get eventDetailPickEndTime;

  /// No description provided for @eventDetailStartTimeLabel.
  ///
  /// In es, this message translates to:
  /// **'El evento empieza a las {hora}'**
  String eventDetailStartTimeLabel(String hora);

  /// No description provided for @eventDetailAvailableForRange.
  ///
  /// In es, this message translates to:
  /// **'{disponibles} de {total} están libres en todo este rango'**
  String eventDetailAvailableForRange(int disponibles, int total);

  /// No description provided for @eventDetailWhoPaid.
  ///
  /// In es, this message translates to:
  /// **'¿Quién pagó?'**
  String get eventDetailWhoPaid;

  /// No description provided for @eventDetailDivideBetween.
  ///
  /// In es, this message translates to:
  /// **'¿Entre quiénes se divide?'**
  String get eventDetailDivideBetween;

  /// No description provided for @eventDetailSelectAtLeastOne.
  ///
  /// In es, this message translates to:
  /// **'Debe seleccionar al menos una persona'**
  String get eventDetailSelectAtLeastOne;

  /// No description provided for @eventDetailExpenseInvalid.
  ///
  /// In es, this message translates to:
  /// **'Completá una descripción y un monto válido'**
  String get eventDetailExpenseInvalid;

  /// No description provided for @eventDetailSplitEqually.
  ///
  /// In es, this message translates to:
  /// **'Repartir'**
  String get eventDetailSplitEqually;

  /// No description provided for @eventDetailPayersMustSum.
  ///
  /// In es, this message translates to:
  /// **'Los aportes de los pagadores deben sumar el total'**
  String get eventDetailPayersMustSum;

  /// No description provided for @eventDetailContributed.
  ///
  /// In es, this message translates to:
  /// **'Aportado: \${aportado} de \${total}'**
  String eventDetailContributed(String aportado, String total);

  /// No description provided for @eventDetailInvite.
  ///
  /// In es, this message translates to:
  /// **'Invitar'**
  String get eventDetailInvite;

  /// No description provided for @eventDetailInviteTitle.
  ///
  /// In es, this message translates to:
  /// **'Invitar al evento'**
  String get eventDetailInviteTitle;

  /// No description provided for @eventDetailInviteHint.
  ///
  /// In es, this message translates to:
  /// **'Compartí este enlace de invitación con tus amigos para que se sumen al evento:'**
  String get eventDetailInviteHint;

  /// No description provided for @eventDetailCopyLink.
  ///
  /// In es, this message translates to:
  /// **'Copiar enlace'**
  String get eventDetailCopyLink;

  /// No description provided for @eventDetailLinkCopied.
  ///
  /// In es, this message translates to:
  /// **'¡Enlace de invitación copiado al portapapeles!'**
  String get eventDetailLinkCopied;

  /// No description provided for @eventDetailAddFriends.
  ///
  /// In es, this message translates to:
  /// **'Agregar amigos guardados'**
  String get eventDetailAddFriends;

  /// No description provided for @eventDetailShareLink.
  ///
  /// In es, this message translates to:
  /// **'Compartir link de invitación'**
  String get eventDetailShareLink;

  /// No description provided for @eventDetailFriendsAdded.
  ///
  /// In es, this message translates to:
  /// **'{count} agregados al evento'**
  String eventDetailFriendsAdded(int count);

  /// No description provided for @groupsManage.
  ///
  /// In es, this message translates to:
  /// **'Administrar grupo'**
  String get groupsManage;

  /// No description provided for @groupsRename.
  ///
  /// In es, this message translates to:
  /// **'Cambiar nombre'**
  String get groupsRename;

  /// No description provided for @groupsUpdateImage.
  ///
  /// In es, this message translates to:
  /// **'Cambiar imagen'**
  String get groupsUpdateImage;

  /// No description provided for @groupsAddMember.
  ///
  /// In es, this message translates to:
  /// **'Agregar amigo'**
  String get groupsAddMember;

  /// No description provided for @groupsLeave.
  ///
  /// In es, this message translates to:
  /// **'Abandonar grupo'**
  String get groupsLeave;

  /// No description provided for @groupsLeaveConfirm.
  ///
  /// In es, this message translates to:
  /// **'Vas a dejar de ver los eventos de este grupo.'**
  String get groupsLeaveConfirm;

  /// No description provided for @groupsMembers.
  ///
  /// In es, this message translates to:
  /// **'Miembros'**
  String get groupsMembers;

  /// No description provided for @groupsNewName.
  ///
  /// In es, this message translates to:
  /// **'Nuevo nombre'**
  String get groupsNewName;

  /// No description provided for @groupsFriendId.
  ///
  /// In es, this message translates to:
  /// **'ID del amigo'**
  String get groupsFriendId;

  /// No description provided for @friendsPickTitle.
  ///
  /// In es, this message translates to:
  /// **'Elegir amigos'**
  String get friendsPickTitle;

  /// No description provided for @friendsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tenés amigos para agregar. Agregá amigos desde tu perfil.'**
  String get friendsEmpty;

  /// No description provided for @friendsPickConfirm.
  ///
  /// In es, this message translates to:
  /// **'Agregar ({count})'**
  String friendsPickConfirm(int count);

  /// No description provided for @friendsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis amigos'**
  String get friendsTitle;

  /// No description provided for @friendsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por username o email'**
  String get friendsSearchHint;

  /// No description provided for @friendsAdd.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get friendsAdd;

  /// No description provided for @friendsRequests.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get friendsRequests;

  /// No description provided for @friendsAccept.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get friendsAccept;

  /// No description provided for @friendsRequestSent.
  ///
  /// In es, this message translates to:
  /// **'Solicitud enviada'**
  String get friendsRequestSent;

  /// No description provided for @friendsNoResults.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get friendsNoResults;

  /// No description provided for @profileEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get profileEdit;

  /// No description provided for @profileName.
  ///
  /// In es, this message translates to:
  /// **'Username'**
  String get profileName;

  /// No description provided for @profileLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get profileLanguage;

  /// No description provided for @profileSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get profileSave;

  /// No description provided for @registerTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get registerTitle;

  /// No description provided for @registerName.
  ///
  /// In es, this message translates to:
  /// **'Username'**
  String get registerName;

  /// No description provided for @registerEmail.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get registerEmail;

  /// No description provided for @registerPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get registerPassword;

  /// No description provided for @registerSubmit.
  ///
  /// In es, this message translates to:
  /// **'Registrarme'**
  String get registerSubmit;

  /// No description provided for @registerHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tenés cuenta? Ingresar'**
  String get registerHaveAccount;

  /// No description provided for @commonConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get commonConfirm;

  /// No description provided for @activityExpensesClosed.
  ///
  /// In es, this message translates to:
  /// **'{actor} cerró los gastos'**
  String activityExpensesClosed(String actor);

  /// No description provided for @activityTaskAssignedTo.
  ///
  /// In es, this message translates to:
  /// **'{actor} asignó una tarea'**
  String activityTaskAssignedTo(String actor);

  /// No description provided for @homeNoActivity.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay actividad'**
  String get homeNoActivity;

  /// No description provided for @balancesSettleAll.
  ///
  /// In es, this message translates to:
  /// **'Saldar todo'**
  String get balancesSettleAll;

  /// No description provided for @balancesSettleAllConfirm.
  ///
  /// In es, this message translates to:
  /// **'Se va a marcar como saldada tu deuda con {username}.'**
  String balancesSettleAllConfirm(String username);

  /// No description provided for @balancesSettleAllConfirmMulti.
  ///
  /// In es, this message translates to:
  /// **'Se van a saldar las {count} deudas que tenés con {username}, en todos los eventos.'**
  String balancesSettleAllConfirmMulti(String username, int count);

  /// No description provided for @balancesBreakdown.
  ///
  /// In es, this message translates to:
  /// **'DETALLE POR EVENTO'**
  String get balancesBreakdown;

  /// No description provided for @balancesNoDebtsWith.
  ///
  /// In es, this message translates to:
  /// **'No tenés deudas pendientes con {username}'**
  String balancesNoDebtsWith(String username);

  /// No description provided for @balancesCompensationHint.
  ///
  /// In es, this message translates to:
  /// **'Compensado: debés \${debo} y te deben \${meDeben}'**
  String balancesCompensationHint(String debo, String meDeben);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
