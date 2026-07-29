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
  String get navHome => 'Home';

  @override
  String get navGroups => 'Groups';

  @override
  String get navBalances => 'Balances';

  @override
  String get navProfile => 'Profile';
}
