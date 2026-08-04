// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Planify';

  @override
  String get appTagline => 'Get-togethers without the stress';

  @override
  String get loginUserOrEmail => 'Username or Email';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginForgotPassword => 'Forgot your password?';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginOr => 'or';

  @override
  String get loginContinueAnonymous => 'Continue as Guest';

  @override
  String get loginNoAccount => 'Don\'t have an account?';

  @override
  String get loginCreateAccount => 'Create account';

  @override
  String get loginComingSoon => 'Coming soon';

  @override
  String get loginError => 'We couldn\'t sign you in. Check your details.';

  @override
  String get loginAnonymousHint =>
      'To join as a guest you need an event invitation link.';

  @override
  String get loginAnonymousLinkLabel => 'Invitation link';

  @override
  String get loginAnonymousNameLabel => 'Your username';

  @override
  String get loginAnonymousNameHint => 'e.g. Sofía';

  @override
  String get loginPendingInvitation =>
      'You\'ve been invited to an event. Sign in, create an account, or continue as a guest to join.';

  @override
  String get navHome => 'Home';

  @override
  String get navGroups => 'Groups';

  @override
  String get navBalances => 'Balances';

  @override
  String get navProfile => 'Profile';

  @override
  String homeGreeting(String username) {
    return 'Hi, $username!';
  }

  @override
  String get homeOwedToMe => 'Owed to me';

  @override
  String get homeIOwe => 'I owe';

  @override
  String get homeUpcomingEvents => 'Upcoming events';

  @override
  String get homeRecentActivity => 'Recent activity';

  @override
  String get homeNoEvents => 'You have no events yet';

  @override
  String get homeNoEventsHint => 'Create your first one with the + button';

  @override
  String get groupsTitle => 'Groups';

  @override
  String get groupsNoGroups => 'You have no groups yet';

  @override
  String get groupsNoGroupsHint =>
      'They\'re created automatically when you set up an event';

  @override
  String get groupsNewEvent => 'NEW';

  @override
  String groupsConfirmed(int count) {
    return '$count confirmed';
  }

  @override
  String groupsPendingTasks(int count) {
    return '$count pending tasks';
  }

  @override
  String groupsExpenses(int count) {
    return '$count expenses';
  }

  @override
  String get groupsNoUpcoming => 'No upcoming events';

  @override
  String get balancesTitle => 'Balances';

  @override
  String get balancesNet => 'NET BALANCE';

  @override
  String get balancesAll => 'All';

  @override
  String get balancesOwedToMe => 'Owed to me';

  @override
  String get balancesIOwe => 'I owe';

  @override
  String get balancesPerFriend => 'Balances by friend';

  @override
  String get balancesEmpty => 'You have no pending balances';

  @override
  String get balancesEmptyHint => 'They\'ll show up here once you add expenses';

  @override
  String get balancesStatePay => 'Pay';

  @override
  String get balancesStatePending => 'Pending';

  @override
  String get balancesStateSettled => 'Settled';

  @override
  String get balancesOweYou => 'Owes you';

  @override
  String get balancesYouOwe => 'You owe';

  @override
  String get expensesPickEventTitle => 'Which event is this for?';

  @override
  String get expensesNoEventsToPick =>
      'You don\'t have any active events to add an expense to yet';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileWeeklyAvailability => 'Weekly Availability';

  @override
  String get profileAvailabilityHint => 'Tap the blocks to mark your free time';

  @override
  String get profileHistory => 'Event history';

  @override
  String get profileLogout => 'Sign out';

  @override
  String get historyTitle => 'Event history';

  @override
  String get historyEmpty => 'No past events yet';

  @override
  String get historyToPay => 'To pay';

  @override
  String get historyYourShare => 'Your share';

  @override
  String get eventCreateTitle => 'New event';

  @override
  String get eventStep1Title => 'What\'s the plan?';

  @override
  String get eventStep2Title => 'With whom?';

  @override
  String get eventNameLabel => 'Event name';

  @override
  String get eventNameHint => 'BBQ at Marcos\'';

  @override
  String get eventPlaceLabel => 'Where is it?';

  @override
  String get eventPlaceHint => 'Juli\'s place';

  @override
  String get eventNext => 'Next';

  @override
  String get eventBack => 'Back';

  @override
  String get eventCreate => 'Create event';

  @override
  String get eventExistingGroup => 'Use an existing group';

  @override
  String get eventNewGroup => 'Create a new group';

  @override
  String get eventNewGroupName => 'Group name';

  @override
  String get eventCreateError => 'We couldn\'t create the event';

  @override
  String get eventDateComesLater =>
      'The exact time is set later, once everyone shares their availability within the chosen range';

  @override
  String get eventDateRangeLabel => 'Date range';

  @override
  String get eventDateRangeExpiredBanner =>
      'The date range expired and was already extended once. Pick a time to confirm the event, or cancel it from the feed.';

  @override
  String eventDateRangeShowing(String inicio, String fin) {
    return 'Looking for a time between $inicio and $fin';
  }

  @override
  String get eventAiButton => 'Generate with AI';

  @override
  String get eventAiTitle => 'Describe your event';

  @override
  String get eventAiHint =>
      'E.g.: a barbecue at Juli\'s place with Marcos and Sofía';

  @override
  String get eventAiGenerate => 'Generate';

  @override
  String eventAiUnmatched(String nombres) {
    return 'Couldn\'t find these among your friends: $nombres';
  }

  @override
  String get eventSavedPlaces => 'Saved places';

  @override
  String get eventSavePlace => 'Save this place';

  @override
  String get eventPlaceLabelHint => 'Label (e.g. Juli\'s place)';

  @override
  String get groupAvailabilityTitle => 'Group availability';

  @override
  String groupAvailabilityHint(int count) {
    return 'Slots where this group\'s members ($count) overlap. Darker = more people free.';
  }

  @override
  String get groupsSeeAvailability => 'See group availability';

  @override
  String get eventConfigTitle => 'Event settings';

  @override
  String get eventDetailAvailability => 'Group availability';

  @override
  String get eventDetailMyAvailability => 'My availability';

  @override
  String get eventDetailSaveAvailability => 'Save availability';

  @override
  String get eventDetailAttendance => 'Are you in?';

  @override
  String get eventDetailGoing => 'I\'m in';

  @override
  String get eventDetailNotGoing => 'Can\'t make it';

  @override
  String get eventDetailTasks => 'Tasks';

  @override
  String get eventDetailNoTasks => 'No tasks yet';

  @override
  String get eventDetailAddTask => 'Add task';

  @override
  String get eventDetailTaskTitle => 'What needs doing?';

  @override
  String get eventDetailTakeTask => 'Take it';

  @override
  String get eventDetailCompleteTask => 'Done';

  @override
  String get eventDetailTaskDone => 'Completed';

  @override
  String get eventDetailTaskUnassigned => 'Unassigned';

  @override
  String get eventDetailActivityLog => 'Activity Log';

  @override
  String get eventDetailQuickActions => 'Quick actions';

  @override
  String get eventDetailAddExpense => 'Expense';

  @override
  String get eventDetailExpenseDescription => 'What did you buy?';

  @override
  String get eventDetailExpenseAmount => 'Amount';

  @override
  String get eventDetailCancelEvent => 'Cancel event';

  @override
  String get eventDetailNoActivity => 'Nothing has happened in this event yet';

  @override
  String activityEventCreated(String actor) {
    return '$actor created the event';
  }

  @override
  String activityScheduleConfirmed(String actor) {
    return '$actor confirmed the time';
  }

  @override
  String activityExpenseAdded(String actor) {
    return '$actor added an expense';
  }

  @override
  String activityDebtSettled(String actor) {
    return '$actor settled their debt';
  }

  @override
  String activityDebtSettledWith(String actor, String personas) {
    return '$actor settled up with $personas';
  }

  @override
  String activityTaskCreated(String actor) {
    return '$actor created a task';
  }

  @override
  String activityTaskAssigned(String actor) {
    return '$actor took a task';
  }

  @override
  String activityTaskCompleted(String actor) {
    return '$actor completed a task';
  }

  @override
  String activityJoined(String actor) {
    return '$actor joined the event';
  }

  @override
  String activityAttendance(String actor) {
    return '$actor confirmed attendance';
  }

  @override
  String activityAvailability(String actor) {
    return '$actor shared their availability';
  }

  @override
  String activityCancelled(String actor) {
    return '$actor cancelled the event';
  }

  @override
  String get activityRangeExtended => 'The event\'s date range was extended';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get commonErrorHint => 'Check that the backend is running';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonToBeDefined => 'To be defined';

  @override
  String get eventDetailCloseExpenses => 'Close expenses';

  @override
  String get eventDetailCancelConfirm =>
      'This will cancel the event for everyone. It cannot be undone.';

  @override
  String get eventDetailCancelled => 'Cancelled';

  @override
  String get eventDetailSettle => 'Settle';

  @override
  String get eventDetailDebts => 'Event debts';

  @override
  String get eventDetailNoDebts => 'No debts in this event';

  @override
  String get eventDetailAssignTo => 'Assign to someone';

  @override
  String get eventDetailTapToConfirm =>
      'Tap a block on the map to confirm the time';

  @override
  String get eventDetailPickEndTime => 'Until what time?';

  @override
  String eventDetailStartTimeLabel(String hora) {
    return 'The event starts at $hora';
  }

  @override
  String eventDetailAvailableForRange(int disponibles, int total) {
    return '$disponibles of $total are free for this whole range';
  }

  @override
  String get eventDetailWhoPaid => 'Who paid?';

  @override
  String get eventDetailDivideBetween => 'Divide between:';

  @override
  String get eventDetailSelectAtLeastOne => 'Select at least one person';

  @override
  String get eventDetailExpenseInvalid =>
      'Enter a description and a valid amount';

  @override
  String get eventDetailSplitEqually => 'Split';

  @override
  String get eventDetailPayersMustSum =>
      'The payers\' contributions must add up to the total';

  @override
  String eventDetailContributed(String aportado, String total) {
    return 'Contributed: \$$aportado of \$$total';
  }

  @override
  String get eventDetailInvite => 'Invite';

  @override
  String get eventDetailInviteTitle => 'Invite to event';

  @override
  String get eventDetailInviteHint =>
      'Share this invitation link with your friends so they can join the event:';

  @override
  String get eventDetailCopyLink => 'Copy link';

  @override
  String get eventDetailLinkCopied => 'Invitation link copied to clipboard!';

  @override
  String get eventDetailAddFriends => 'Add saved friends';

  @override
  String get eventDetailShareLink => 'Share invitation link';

  @override
  String eventDetailFriendsAdded(int count) {
    return '$count added to the event';
  }

  @override
  String get groupsManage => 'Manage group';

  @override
  String get groupsRename => 'Rename';

  @override
  String get groupsUpdateImage => 'Cambiar imagen';

  @override
  String get groupsAddMember => 'Add friend';

  @override
  String get groupsLeave => 'Leave group';

  @override
  String get groupsLeaveConfirm => 'You will stop seeing this group events.';

  @override
  String get groupsMembers => 'Members';

  @override
  String get groupsNewName => 'New name';

  @override
  String get groupsFriendId => 'Friend ID';

  @override
  String get friendsPickTitle => 'Pick friends';

  @override
  String get friendsEmpty =>
      'You have no friends to add yet. Add friends from your profile.';

  @override
  String friendsPickConfirm(int count) {
    return 'Add ($count)';
  }

  @override
  String get friendsTitle => 'My friends';

  @override
  String get friendsSearchHint => 'Search by username or email';

  @override
  String get friendsAdd => 'Add';

  @override
  String get friendsRequests => 'Requests';

  @override
  String get friendsAccept => 'Accept';

  @override
  String get friendsRequestSent => 'Request sent';

  @override
  String get friendsNoResults => 'No results';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profileName => 'Username';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileSave => 'Save';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerName => 'Username';

  @override
  String get registerEmail => 'Email';

  @override
  String get registerPassword => 'Password';

  @override
  String get registerSubmit => 'Sign up';

  @override
  String get registerHaveAccount => 'Already have an account? Sign in';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String activityExpensesClosed(String actor) {
    return '$actor closed the expenses';
  }

  @override
  String activityTaskAssignedTo(String actor) {
    return '$actor assigned a task';
  }

  @override
  String get homeNoActivity => 'No activity yet';

  @override
  String get balancesSettleAll => 'Settle all';

  @override
  String balancesSettleAllConfirm(String username) {
    return 'Your debt with $username will be marked as settled.';
  }

  @override
  String balancesSettleAllConfirmMulti(String username, int count) {
    return 'This will settle all $count debts you have with $username, across every event.';
  }

  @override
  String get balancesBreakdown => 'BREAKDOWN BY EVENT';

  @override
  String balancesNoDebtsWith(String username) {
    return 'You have no pending debts with $username';
  }

  @override
  String balancesCompensationHint(String debo, String meDeben) {
    return 'Offset: you owe \$$debo and you are owed \$$meDeben';
  }
}
