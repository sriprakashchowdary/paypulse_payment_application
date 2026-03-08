import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('hi')
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @dataAndLegal.
  ///
  /// In en, this message translates to:
  /// **'Data & Legal'**
  String get dataAndLegal;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @biometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get biometricLogin;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @emergencyLock.
  ///
  /// In en, this message translates to:
  /// **'Emergency Lock'**
  String get emergencyLock;

  /// No description provided for @roundUpAutoSave.
  ///
  /// In en, this message translates to:
  /// **'Round-Up Auto Save'**
  String get roundUpAutoSave;

  /// No description provided for @exportTransactions.
  ///
  /// In en, this message translates to:
  /// **'Export Transactions'**
  String get exportTransactions;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @biometricSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require fingerprint/face on launch'**
  String get biometricSubtitle;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and cannot be undone. All your data and transaction history will be permanently removed. If you have a wallet balance, it will be refunded to your primary card prior to closure.\n\nAre you sure you want to proceed?'**
  String get deleteAccountConfirmMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @accountDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account successfully deleted.'**
  String get accountDeletedSuccess;

  /// No description provided for @failedToDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account'**
  String get failedToDeleteAccount;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search title, amount, category'**
  String get searchHint;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @savings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get savings;

  /// No description provided for @noTransactionsFound.
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get noTransactionsFound;

  /// No description provided for @cards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get cards;

  /// No description provided for @addNewCard.
  ///
  /// In en, this message translates to:
  /// **'Add New Card'**
  String get addNewCard;

  /// No description provided for @noCardsYet.
  ///
  /// In en, this message translates to:
  /// **'No cards added yet'**
  String get noCardsYet;

  /// No description provided for @noCardsDesc.
  ///
  /// In en, this message translates to:
  /// **'Add your credit or debit cards to manage them in one place with PayPulse.'**
  String get noCardsDesc;

  /// No description provided for @cardDetails.
  ///
  /// In en, this message translates to:
  /// **'Card Details'**
  String get cardDetails;

  /// No description provided for @cardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get cardNumber;

  /// No description provided for @expiryDateHint.
  ///
  /// In en, this message translates to:
  /// **'MM/YY'**
  String get expiryDateHint;

  /// No description provided for @cardHolderName.
  ///
  /// In en, this message translates to:
  /// **'Cardholder Name'**
  String get cardHolderName;

  /// No description provided for @saveCard.
  ///
  /// In en, this message translates to:
  /// **'Save Card'**
  String get saveCard;

  /// No description provided for @freezeCard.
  ///
  /// In en, this message translates to:
  /// **'Freeze Card'**
  String get freezeCard;

  /// No description provided for @unfreezeCard.
  ///
  /// In en, this message translates to:
  /// **'Unfreeze Card'**
  String get unfreezeCard;

  /// No description provided for @cardAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Card added successfully'**
  String get cardAddedSuccess;

  /// No description provided for @cardRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Card removed successfully'**
  String get cardRemovedSuccess;

  /// No description provided for @freezeCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Temporarily disable all transactions'**
  String get freezeCardDesc;

  /// No description provided for @unfreezeCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlock card for transactions'**
  String get unfreezeCardDesc;

  /// No description provided for @showDetails.
  ///
  /// In en, this message translates to:
  /// **'Show Card Details'**
  String get showDetails;

  /// No description provided for @hideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide Card Details'**
  String get hideDetails;

  /// No description provided for @detailsDesc.
  ///
  /// In en, this message translates to:
  /// **'View CVV & Expiry for online payments'**
  String get detailsDesc;

  /// No description provided for @removeCard.
  ///
  /// In en, this message translates to:
  /// **'Remove Card'**
  String get removeCard;

  /// No description provided for @removeCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove this card'**
  String get removeCardDesc;

  /// No description provided for @cvv.
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get cvv;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalance;

  /// No description provided for @pulseScore.
  ///
  /// In en, this message translates to:
  /// **'Pulse Score'**
  String get pulseScore;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get active;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @receive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive;

  /// No description provided for @split.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get split;

  /// No description provided for @gold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get gold;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @enterWalletPin.
  ///
  /// In en, this message translates to:
  /// **'Enter Wallet PIN'**
  String get enterWalletPin;

  /// No description provided for @revealBalanceDesc.
  ///
  /// In en, this message translates to:
  /// **'To reveal your balance privately'**
  String get revealBalanceDesc;

  /// No description provided for @incorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get incorrectPin;

  /// No description provided for @walletUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Wallet Unlocked'**
  String get walletUnlocked;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @aiInsights.
  ///
  /// In en, this message translates to:
  /// **'AI Insights'**
  String get aiInsights;

  /// No description provided for @monthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Monthly Budget'**
  String get monthlyBudget;

  /// No description provided for @prediction.
  ///
  /// In en, this message translates to:
  /// **'Prediction'**
  String get prediction;

  /// No description provided for @estimatedSpend.
  ///
  /// In en, this message translates to:
  /// **'Estimated spend'**
  String get estimatedSpend;

  /// No description provided for @categoryBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Category Breakdown'**
  String get categoryBreakdown;

  /// No description provided for @detectedSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Detected Subscriptions'**
  String get detectedSubscriptions;

  /// No description provided for @noRecurringPatterns.
  ///
  /// In en, this message translates to:
  /// **'No recurring subscription patterns detected yet.'**
  String get noRecurringPatterns;

  /// No description provided for @noSpendingData.
  ///
  /// In en, this message translates to:
  /// **'No spending data yet.'**
  String get noSpendingData;

  /// No description provided for @invalidReceiverEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid receiver email'**
  String get invalidReceiverEmail;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get invalidAmount;

  /// No description provided for @authorizeTransfer.
  ///
  /// In en, this message translates to:
  /// **'To authorize this transfer'**
  String get authorizeTransfer;

  /// No description provided for @transferSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Transferred!'**
  String get transferSuccessful;

  /// No description provided for @sentTo.
  ///
  /// In en, this message translates to:
  /// **'sent to'**
  String get sentTo;
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
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
