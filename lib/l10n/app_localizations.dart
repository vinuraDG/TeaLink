import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';

// ignore_for_file: type=lint

abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
  ];

  var unknownCustomer;

  var notAvailable;

  var foundCollectionsInRangee;

  // -----------------------------
  // Common / onboarding strings
  // -----------------------------
  String get continueButton;
  String get changeLanguage;
  String get selectLanguage;
  String get welcome;
  String get onboarding1Title;
  String get onboarding1Description;
  String get onboarding2Title;
  String get onboarding2Description;
  String get next;
  String get getStarted;

  // -----------------------------
  // Registration screen strings
  // -----------------------------
  String get signUpTitle;
  String get joinTeaLink;
  String get createAccount;
  String get personalInfo;
  String get accountDetails;
  String get fullName;
  String get regNo;
  String get phoneNumber;
  String get emailAddress;
  String get password;
  String get confirmPassword;
  String get createAccountButton;
  String get googleSignUp;
  String get alreadyHaveAccount;
  String get signInHere;

  // -----------------------------
// Login screen strings
// -----------------------------
String get loginTitle;
String get welcomeToTeaLink;
String get signInToAccount;
String get email;
String get enterEmail;
String get passwordField;
String get enterPassword;
String get forgotPassword;
String get signInButton;
String get or;
String get continueWithGoogle;
String get dontHaveAccount;
String get signUpHere;

// -----------------------------
// Role selection screen strings
// -----------------------------
String get chooseRole;
String get selectRoleSubtitle;
String get adminRole;
String get adminSubtitle;
String get customerRole;
String get customerSubtitle;
String get collectorRole;
String get collectorSubtitle;
String get selectCollector;
String get collectorInfo;
String get loadingCollectors;
String get noCollectors;
String get availableCollectors;
String get completeRegistration;


//customer side
// -----------------------------
// Customer Dashboard strings
// -----------------------------
String get customerDashboard;
String get hello;
String get goodMorning;
String get goodAfternoon;
String get goodEvening;
String get notifyCollector;
String get dashboardOverview;
String get trackTeaFarming;
String get weeklyHarvest;
String get harvestTrends;
String get viewAnalytics;
String get payments;
String get viewTransactions;
String get collectorInfom;
String get contactDetails;
String get quickActions;
String get teaCollectionStatus;
String get weeklyHarvestReady;
String get notifyCollectorDescription;
String get home;
String get trends;
String get profile;
String get success;
String get collectorNotified;
String get collectorNotifiedMessage;
String get ok;
String get locationRequired;
String get locationServicesDisabled;
String get locationPermissionDenied;
String get locationPermissionDeniedForever;
String get failedToGetLocation;
String get saveYourLocation;
String get locationDetectionMessage;
String get coordinates;
String get addressOptional;
String get enterAddress;
String get skip;
String get saveLocation;
String get locationSavedSuccessfully;
String get failedToSaveLocation;
String get profilePictureUpdated;
String get failedToUpdateProfilePicture;
String get registrationNumberNotFound;
String get noActiveCollector;
String get failedToNotifyCollector;
String get failedToLogout;
String get loading;
String get user;

//harvest trends page
String get harvestTrend;  
String get noHarvestData; 
String get harvestTrendsDescription; 
String get contactCollector;
String get totalHarvest; 
String get averageWeight; 
String get highestHarvest; 
String get collections; 
String get timePeriod; 
String get recentCollections;
String get startuptitle;
String get startupdescription;

// Collector Info Page
String get collectorProfile;
String get contactInformation;
String get registrationNumber;
String get phone;
String get emails;
String get quickAction;
String get callNow;
String get sendEmail;
String get whatsappChat;
String get collectorNotFound;
String get loadingProfile;
String get sendmessage;

// -----------------------------
// Profile Page strings
// -----------------------------
String get personalInformation ;
String get editName ;
String get enterYourName;
String get editPhoneNumber ;
String get enterYourPhoneNumber ;
String get currentLocation;
String get addYourLocation ;
String get addLocation ;
String get locationAndQRCode ;
String get registrationID ;
String get generating ;
String get myQRCode ;
String get shareQRCodeDescription ;
String get generatingQRCode ;
String get saveChanges ;
String get deleteAccount ;
String get loadingYourProfile ;
String get chooseLocation ;
String get confirm ;
String get searchForLocation ;
String get tapToSelectLocation ;
String get selectedLocation ;
String get locationFound ;
String get locationNotFound ;
String get tryDifferentSearch ;
String get failedToSearchLocation ;
String get currentLocationFound ;
String get locationRequestTimedOut ;
String get locationPermissionRequired ;
String get locationServicesDisabledTitle ;
String get pleaseEnableLocationServices;
String get cancel ;
String get openSettings ;
String get retry ;
String get locationPermissionPermanentlyDenied ;
String get enableInAppSettings ;
String get uploadingImage ;
String get profileImageUpdatedSuccessfully ;
String get failedToUploadImage ;
String get gettingLocationDetails ;
String get locationUpdatedSuccessfully ;
String get locationCoordinatesSaved ;
String get failedToPickLocation ;
String get nameCannotBeEmpty ;
String get savingProfile ;
String get profileUpdatedSuccessfully ;
String get failedToUpdateProfile ;
String get deleteAccountTitle ;
String get deleteAccountWarning ;
String get enterYourPassword ;
String get deletingAccount ;
String get errorDeletingAccount ;
String get tapToAdd ;
String get save ;
String get appSettings;
String get language;
String get updatingLanguage;
String get languageUpdatedSuccessfully;
String get failedToUpdateLanguage;
String get languageChanged;
String get restartAppForComplete;
String get okay;

//collector side

// Collector Dashboard 
//collector side
//collector dashboard

String get collectorDashboard ;
String get readyToCollectToday ;
String get customerList;
String get viewAllCustomers;
String get history ;
String get viewPastCollections ;
String get mapView ;
String get seeCustomerLocations ;
String get profileSettings ;
String get manageCollectorProfile ;
String get chooseActionToStart ;
String get logout;
String get areYouSureLogout;
String get map ;



// Notification Page
String get customerNotifications;
String get loadingNotifications;
String get failedToLoadNotifications;
String get error;
String get allCaughtUp;
String get noPendingCollectionRequests;
String get allCustomersCollectedToday;
String get pendingCollection;
String get minutesAgo;
String get hoursAgo;
String get daysAgoShort;
String get at;
String get collect;
String customerCollectedSuccessfullyWithWeight(String customerName, double weight);
String customerCollectedSuccessfully(String customerName);

 // Collection History Page methods
  String get collectionHistory;
  String get searchByNameOrReg;
  String get sortByDate;
  String get sortByName;
  String get sortByRegNo;
  String get sortByWeight;
  String get ascending;
  String get descending;
  String get today;
  String get loadingCollectionHistory;
  String get somethingWentWrong;
  String get unableToLoadHistory;
  String get filterByDateRange;
  String get startDate;
  String get endDate;
  String foundCollectionsInRange(int count);
  String get totalCollections;
  String get totalWeight;
  String get collected;
  String get noCollectionsToday;
  String get noCollectionHistory;
  String get noCollectionsTodayDescription;
  String get noCollectionHistoryDescription;
  String get startCollecting;
  String get collectionDetails;
  String get completed;
  String get customerName;
  String get registrationNo;
  String get weightCollected;
  String get collectionDate;
  String get collectionTime;
  String get collectedBy;
  String get remarks;
  String get close;
  String get collector;



// Collector Map Page - Missing abstract declarations
String get todaysCustomerLocations;
String get changeMapLayer;
String get centerTodaysMarkers;
String get errorLoadingMap;
String get noCollectionRequestsToday;
String get noLocationDataAvailable;
String get switchedToMapView;
String get streetMap;
String get satellite;
String get terrain;
String get collectionCompletedAlready;
String get errorNavigatingToLocation;
String get collectionCompletedSuccessfully;
String get errorOpeningWeightPage;
String get weightUpdatedSuccessfully;
String get errorUpdatingWeight;
String get removeWeight;
String get areYouSureRemoveWeight;
String get remove;
String get weightRemovedSuccessfully;
String get failedToRemoveWeight;
String get externalNavigationComingSoon;
String get todaysCollections;
String get onMap;
String get pending;
String get todaysTotalWeight;
String get completedCollectionsHidden;
String get centerTodaysPendingCollections;
String get viewDetails;
String get addWeight;
String get navigate;
String get updateWeight;
String get timeRequested;
String get date;
String get requested;
String get weight;
String get address;
String get coordinatess; // Note: fixed typo from 'coordinatess'
String get locationSource;
String get userProfile;
String get currentGPS;

// Admin Dashboard

String get dashboard ;
String get goodMorningAdmin ;
String get goodAfternoonAdmin ;
String get goodEveningAdmin ;
String get admin ;
String get realTimeSystemOverview ;
String get todaysActivity;
String get newUsers;
String get activeAlerts;
String get alertsNeedAttention;
String get overview;
String get totalUsers;
String get customers;
String get collectors;
String get quickActionsTitle;
String get manageUsers ;
String get viewAndManageUsers;
String get uploadPaymentSlip;
String get checkPaymentRecords;
String get systemAlerts;
String get monitorSystemNotifications;
String get logoutTitle;
String get logoutConfirmation;
String get logoutButton ;
String get activeAlertsTitle;
String get users;
String get settings;

// Manage Users Page
  String get userManagement;
  String get refreshUsers;
  String get loadingUsers;
  String get userNotAuthenticated;
  String get userDocumentNotFound;
  String get accessDenied;
  String get adminAccessRequired;
  String get errorCheckingPermissions;
  String get errorLoadingUsers;
  String customersCount(int count);
  String collectorsCount(int count);
  String get accessError;
  String get tryAgain;
  String get noCustomersFound;
  String get noCollectorsFound;
  String get customersWillAppear;
  String get collectorsWillAppear;
  String get unknownUser;
  String get noEmail;
  String get reg;
  String get viewDetailsAction;
  String get editUser;
  String get deleteUser;
  String get invalidDate;
  String get personalInformationTitle;
  String get fullNameLabel;
  String get emailAddressLabel;
  String get registrationNoLabel;
  String get userRole;
  String get accountInformation;
  String get joinedDate;
  String get lastUpdated;
  String get done;
  String get editUserTitle;
  String get fullNameField;
  String get emailAddressField;
  String get registrationNumberField;
  String get userRoleField;
  String get updateUser;
  String get nameAndEmailRequired;
  String get userUpdatedSuccessfully;
  String get errorUpdatingUser;
  String get deleteUserTitle;
  String get cannotDeleteOwnAccount;
  String deleteUserConfirmation(String userName);
  String get userDeletedSuccessfully;
  String get errorDeletingUser;
  String get payment;

  // Payment Slip Page

String get uploadPaymentSlipTitle;
String get paymentSlipUpload;
String get uploadPaymentSlipsForCustomers;
String get selectCustomerStep;
String get uploadPaymentSlipStep;
String get additionalNotes;
String get optional;
String get tapToSelectCustomer;
String get selectCustomerTitle;
String get searchByNameEmailOrReg;
String get noMatchingCustomers;
String get tapToSelectFile;
String get pdfJpgPngSupported;
String get enterAdditionalNotes;
String get clearForm;
String get fileSelected;
String get noFileSelected;
String get pleaseSelectCustomer;
String get pleaseSelectPaymentSlipFile;
String get adminNotLoggedIn;
String get uploadFailed;
String get successTitle;
String get paymentSlipUploadedTo;
String get folder;
String get uploadingTo;
String get uploadPaymentSlipButton;
String get step;

// Alert Page - Main

String get systemAlert;
String get loadingAlerts;
String get noAlertsFound;
String get noAlertsDescription;
String get alertDeletedSuccessfully;
String get allAlerts;
String get criticalAlerts;
String get warningAlerts;
String get infoAlerts;
String get successAlerts;
String get alertDescription;
String get noDescriptionAvailable;
String get additionalDetails;
String get markAsRead;
String get deleteAlert;
String get deleteAlertConfirmation;
String get alertMarkedAsRead;
String get criticalAlert;
String get warningAlert;
String get infoAlert;
String get successAlert;
String get viewAlert;
String get dismissAlert;
String get readAlerts;
String get unreadAlerts;
String get clearAllAlerts;
String get noUnreadAlerts;
String get alertsCleared ;
String get swipeToMarkAsRead;
String get swipeToDelete;


//Customer Payment Slip Page
String get paymentSlips;
String get loadingPaymentSlips;
String get noPaymentSlips;
String get paymentSlipsWillAppearHere;
String get filterSort;
String get download;
String get downloading;
String get share;
String get apply;
String get slips;
String get total;
String get verified;
String get all;
String get no;
String get sortAndFilter;
String get order;
String get paymentId;
String get status;
String get fileName;
String get fileSize;
String get uploadedBy;
String get refresh;
String get notes;
String get sortBy;


}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(
        lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'si'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". '
    'This is likely an issue with the localizations generation tool. '
    'Please file an issue on GitHub with a reproducible sample app and the '
    'gen-l10n configuration that was used.',
  );
}