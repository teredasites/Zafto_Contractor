import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ht.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tl.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

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
    Locale('es'),
    Locale('ht'),
    Locale('ko'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('tl'),
    Locale('vi'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ZAFTO'**
  String get appTitle;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

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

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navJobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get navJobs;

  /// No description provided for @navBids.
  ///
  /// In en, this message translates to:
  /// **'Bids'**
  String get navBids;

  /// No description provided for @navEstimates.
  ///
  /// In en, this message translates to:
  /// **'Estimates'**
  String get navEstimates;

  /// No description provided for @navInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get navInvoices;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get navSchedule;

  /// No description provided for @navTimeClock.
  ///
  /// In en, this message translates to:
  /// **'Time Clock'**
  String get navTimeClock;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get navSafety;

  /// No description provided for @navExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get navExpenses;

  /// No description provided for @navTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get navTeam;

  /// No description provided for @navEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get navEquipment;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @clockIn.
  ///
  /// In en, this message translates to:
  /// **'Clock In'**
  String get clockIn;

  /// No description provided for @clockOut.
  ///
  /// In en, this message translates to:
  /// **'Clock Out'**
  String get clockOut;

  /// No description provided for @onBreak.
  ///
  /// In en, this message translates to:
  /// **'On Break'**
  String get onBreak;

  /// No description provided for @startBreak.
  ///
  /// In en, this message translates to:
  /// **'Start Break'**
  String get startBreak;

  /// No description provided for @endBreak.
  ///
  /// In en, this message translates to:
  /// **'End Break'**
  String get endBreak;

  /// No description provided for @totalHours.
  ///
  /// In en, this message translates to:
  /// **'Total Hours'**
  String get totalHours;

  /// No description provided for @todayHours.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Hours'**
  String get todayHours;

  /// No description provided for @overtime.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get overtime;

  /// No description provided for @jobDetails.
  ///
  /// In en, this message translates to:
  /// **'Job Details'**
  String get jobDetails;

  /// No description provided for @newJob.
  ///
  /// In en, this message translates to:
  /// **'New Job'**
  String get newJob;

  /// No description provided for @jobNumber.
  ///
  /// In en, this message translates to:
  /// **'Job Number'**
  String get jobNumber;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @property.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get property;

  /// No description provided for @assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned To'**
  String get assignedTo;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @startJob.
  ///
  /// In en, this message translates to:
  /// **'Start Job'**
  String get startJob;

  /// No description provided for @completeJob.
  ///
  /// In en, this message translates to:
  /// **'Complete Job'**
  String get completeJob;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNote;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @materials.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get materials;

  /// No description provided for @laborHours.
  ///
  /// In en, this message translates to:
  /// **'Labor Hours'**
  String get laborHours;

  /// No description provided for @beforePhotos.
  ///
  /// In en, this message translates to:
  /// **'Before Photos'**
  String get beforePhotos;

  /// No description provided for @afterPhotos.
  ///
  /// In en, this message translates to:
  /// **'After Photos'**
  String get afterPhotos;

  /// No description provided for @customerSignature.
  ///
  /// In en, this message translates to:
  /// **'Customer Signature'**
  String get customerSignature;

  /// No description provided for @punchList.
  ///
  /// In en, this message translates to:
  /// **'Punch List'**
  String get punchList;

  /// No description provided for @changeOrder.
  ///
  /// In en, this message translates to:
  /// **'Change Order'**
  String get changeOrder;

  /// No description provided for @statusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get statusScheduled;

  /// No description provided for @statusEnRoute.
  ///
  /// In en, this message translates to:
  /// **'En Route'**
  String get statusEnRoute;

  /// No description provided for @statusOnSite.
  ///
  /// In en, this message translates to:
  /// **'On Site'**
  String get statusOnSite;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statusPaused;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusOnHold.
  ///
  /// In en, this message translates to:
  /// **'On Hold'**
  String get statusOnHold;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @newBid.
  ///
  /// In en, this message translates to:
  /// **'New Bid'**
  String get newBid;

  /// No description provided for @bidNumber.
  ///
  /// In en, this message translates to:
  /// **'Bid Number'**
  String get bidNumber;

  /// No description provided for @validUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid Until'**
  String get validUntil;

  /// No description provided for @lineItems.
  ///
  /// In en, this message translates to:
  /// **'Line Items'**
  String get lineItems;

  /// No description provided for @addLineItem.
  ///
  /// In en, this message translates to:
  /// **'Add Line Item'**
  String get addLineItem;

  /// No description provided for @depositRequired.
  ///
  /// In en, this message translates to:
  /// **'Deposit Required'**
  String get depositRequired;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @bidDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get bidDraft;

  /// No description provided for @bidSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get bidSent;

  /// No description provided for @bidAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get bidAccepted;

  /// No description provided for @bidDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get bidDeclined;

  /// No description provided for @newInvoice.
  ///
  /// In en, this message translates to:
  /// **'New Invoice'**
  String get newInvoice;

  /// No description provided for @invoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice Number'**
  String get invoiceNumber;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @paymentTerms.
  ///
  /// In en, this message translates to:
  /// **'Payment Terms'**
  String get paymentTerms;

  /// No description provided for @amountDue.
  ///
  /// In en, this message translates to:
  /// **'Amount Due'**
  String get amountDue;

  /// No description provided for @amountPaid.
  ///
  /// In en, this message translates to:
  /// **'Amount Paid'**
  String get amountPaid;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @invoicePaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get invoicePaid;

  /// No description provided for @invoiceOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get invoiceOverdue;

  /// No description provided for @invoicePartial.
  ///
  /// In en, this message translates to:
  /// **'Partially Paid'**
  String get invoicePartial;

  /// No description provided for @safetyChecklist.
  ///
  /// In en, this message translates to:
  /// **'Safety Checklist'**
  String get safetyChecklist;

  /// No description provided for @hazardReport.
  ///
  /// In en, this message translates to:
  /// **'Report Hazard'**
  String get hazardReport;

  /// No description provided for @incidentReport.
  ///
  /// In en, this message translates to:
  /// **'Report Incident'**
  String get incidentReport;

  /// No description provided for @ppeRequired.
  ///
  /// In en, this message translates to:
  /// **'PPE Required'**
  String get ppeRequired;

  /// No description provided for @emergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get emergencyContact;

  /// No description provided for @newExpense.
  ///
  /// In en, this message translates to:
  /// **'New Expense'**
  String get newExpense;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @reimbursable.
  ///
  /// In en, this message translates to:
  /// **'Reimbursable'**
  String get reimbursable;

  /// No description provided for @submitForApproval.
  ///
  /// In en, this message translates to:
  /// **'Submit for Approval'**
  String get submitForApproval;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get languageDescription;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @nItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items} =1{1 item} other{{count} items}}'**
  String nItems(int count);

  /// No description provided for @currencyAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount}'**
  String currencyAmount(double amount);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'es',
    'ht',
    'ko',
    'pl',
    'pt',
    'ru',
    'tl',
    'vi',
    'zh',
  ].contains(locale.languageCode);

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
    case 'ht':
      return AppLocalizationsHt();
    case 'ko':
      return AppLocalizationsKo();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tl':
      return AppLocalizationsTl();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
