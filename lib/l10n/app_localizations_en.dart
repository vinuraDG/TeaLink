// ignore_for_file: override_on_non_overriding_member

import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get continueButton => 'Continue';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get welcome => 'Welcome';

  @override
  String get onboarding1Title => 'Track weekly\nharvest & earnings';

  @override
  String get onboarding1Description => 'See how much tea you\'ve collected and\nhow much you\'ve earned each\nweek—clearly and easily.';

  @override
  String get onboarding2Title => 'View Collector\nDetails & Activity';

  @override
  String get onboarding2Description => 'Quickly see who your collector is, their\ncontact info, and their recent collection\nupdates.';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

   // in app_localizations_en.dart
  String get signUpTitle => 'SIGN UP';

@override
String get joinTeaLink => 'Join TeaLink Today';

@override
String get createAccount => 'Create your account to get started';

@override
String get personalInfo => 'Personal Information';

@override
String get accountDetails => 'Account Details';

@override
String get fullName => 'Full Name';

@override
String get regNo => 'Registration Number (Optional)';

@override
String get phoneNumber => 'Phone Number';

@override
String get emailAddress => 'Email Address';

@override
String get password => 'Password';

@override
String get confirmPassword => 'Confirm Password';

@override
String get createAccountButton => 'Create Account';

@override
String get googleSignUp => 'Sign up with Google';

@override
String get alreadyHaveAccount => 'Already have an account? ';

@override
String get signInHere => 'Sign in here';

@override
String get loginTitle => 'LOGIN';

@override
String get welcomeToTeaLink => 'Welcome to TeaLink';

@override
String get signInToAccount => 'Sign in to your account';

@override
String get email => 'Email';

@override
String get enterEmail => 'Enter your email';

@override
String get passwordField => 'Password';

@override
String get enterPassword => 'Enter your password';

@override
String get forgotPassword => 'Forgot password?';

@override
String get signInButton => 'Sign In';

@override
String get or => 'OR';

@override
String get continueWithGoogle => 'Continue with Google';

@override
String get dontHaveAccount => 'Don\'t have an account? ';

@override
String get signUpHere => 'Sign up here';

//role selction page
@override String get chooseRole => 'Choose Your Role';
@override String get selectRoleSubtitle => 'Please select your role to continue';
@override String get adminRole => 'ADMIN';
@override String get adminSubtitle => 'Manage the entire system';
@override String get customerRole => 'CUSTOMER';
@override String get customerSubtitle => 'Buy tea and track orders';
@override String get collectorRole => 'COLLECTOR';
@override String get collectorSubtitle => 'Collect and supply tea';
@override String get selectCollector => 'Select Your Collector';
@override String get collectorInfo => 'Choose a collector who will handle your tea orders and deliveries.';
@override String get loadingCollectors => 'Loading available collectors...';
@override String get noCollectors => 'No collectors available';
@override String get availableCollectors => 'Available Collectors';
@override String get completeRegistration => 'Complete Registration';


//customer side
// Customer Dashboard
@override String get customerDashboard => 'CUSTOMER';
@override String get hello => 'Hello';
@override String get goodMorning => 'Good Morning';
@override String get goodAfternoon => 'Good Afternoon';
@override String get goodEvening => 'Good Evening';
@override String get notifyCollector => 'Notify Collector';
@override String get dashboardOverview => 'Dashboard Overview';
@override String get trackTeaFarming => 'Track your tea farming progress';
@override String get weeklyHarvest => 'Weekly Harvest';
@override String get harvestTrends => 'Harvest Trends';
@override String get viewAnalytics => 'View analytics';
@override String get payments => 'Payments';
@override String get viewTransactions => 'View transactions';
@override String get collectorInfom => 'Collector Info';
@override String get contactDetails => 'Contact details';
@override String get quickActions => 'Quick Actions';
@override String get teaCollectionStatus => 'Tea Collection Status';
@override String get weeklyHarvestReady => 'Use the "Notify Collector" button to alert your assigned collector.';
@override String get notifyCollectorDescription => 'Use the "Notify Collector" button to alert your assigned collector.';
@override String get home => 'Home';
@override String get trends => 'Trends';
@override String get profile => 'Profile';
@override String get success => 'Success!';
@override String get collectorNotified => 'Collector Notified';
@override String get collectorNotifiedMessage => 'The collector has been notified about today\'s harvest. They will contact you soon.';
@override String get ok => 'OK';
@override String get locationRequired => 'Location is required to notify the collector.';
@override String get locationServicesDisabled => 'Location services are disabled. Please enable them.';
@override String get locationPermissionDenied => 'Location permission denied.';
@override String get locationPermissionDeniedForever => 'Location permissions are permanently denied.';
@override String get failedToGetLocation => 'Failed to get location. Please try again.';
@override String get saveYourLocation => 'Save Your Location';
@override String get locationDetectionMessage => 'We detected you don\'t have a saved location. Would you like to save your current location for future notifications?';
@override String get coordinates => 'Coordinates';
@override String get addressOptional => 'Address (Optional)';
@override String get enterAddress => 'Enter your address or location description';
@override String get skip => 'Skip';
@override String get saveLocation => 'Save Location';
@override String get locationSavedSuccessfully => 'Location saved successfully!';
@override String get failedToSaveLocation => 'Failed to save location';
@override String get profilePictureUpdated => 'Profile picture updated successfully!';
@override String get failedToUpdateProfilePicture => 'Failed to update profile picture';
@override String get registrationNumberNotFound => 'Registration number not found. Please update your profile.';
@override String get noActiveCollector => 'No active collector assigned. Please contact admin.';
@override String get failedToNotifyCollector => 'Failed to notify collector. Please try again.';
@override String get failedToLogout => 'Failed to logout. Please try again.';
@override String get loading => 'Loading...';
@override String get user => 'User';

//harvest trends page

@override
String get harvestTrend => 'Harvest Trends';
@override
String get noHarvestData => 'No harvest data available';
@override
String get harvestTrendsDescription => 'Track your tea harvest patterns over time.';
@override
String get contactCollector => 'Contact your collector to schedule a collection.';
@override
String get totalHarvest => 'Total Harvest';
@override
String get averageWeight => 'Average Weight';
@override
String get highestHarvest => 'Highest Harvest';
@override
String get collections => 'Collections';
@override
String get timePeriod => 'Time Period';
@override
String get recentCollections => 'Recent Collections';

@override
String get startuptitle => 'Loading your harvest data...';
@override
String get startupdescription => 'Please wait while we gather your records';

//collector info
@override String get collectorProfile => 'Collector Profile';
@override String get contactInformation => 'Contact Information';
@override String get registrationNumber => 'Registration Number';
@override String get phone => 'Phone Number';
@override String get emails => 'Email Address';
@override String get quickAction => 'Quick Actions';
@override String get callNow => 'Call Now';
@override String get sendEmail => 'Send Email';
@override String get whatsappChat => 'WhatsApp Chat';
@override String get collectorNotFound => 'Collector not found';
@override String get loadingProfile => 'Loading profile...';
@override String get sendmessage=> 'Send a message';

// Profile Page
@override
String get personalInformation => 'Personal Information';

@override
String get editName => 'Edit Name';

@override
String get enterYourName => 'Enter your name';

@override
String get editPhoneNumber => 'Edit Phone Number';

@override
String get enterYourPhoneNumber => 'Enter your phone number';

@override
String get currentLocation => 'Current Location';

@override
String get addYourLocation => 'Add your location';

@override
String get addLocation => 'Add Location';

@override
String get locationAndQRCode => 'Location & QR Code';

@override
String get registrationID => 'Registration ID';

@override
String get generating => 'Generating...';

@override
String get myQRCode => 'My QR Code';

@override
String get shareQRCodeDescription => 'Share this QR code for easy identification';

@override
String get generatingQRCode => 'Generating QR Code...';

@override
String get saveChanges => 'Save Changes';

@override
String get deleteAccount => 'Delete Account';

@override
String get loadingYourProfile => 'Loading your profile...';

@override
String get chooseLocation => 'Choose Location';

@override
String get confirm => 'Confirm';

@override
String get searchForLocation => 'Search for a location...';

@override
String get tapToSelectLocation => 'Tap on the map to select your location';

@override
String get selectedLocation => 'Selected Location';

@override
String get locationFound => 'Location found!';

@override
String get locationNotFound => 'Location not found. Try a different search term.';

@override
String get tryDifferentSearch => 'Try a different search term.';

@override
String get failedToSearchLocation => 'Failed to search location. Please try again.';

@override
String get currentLocationFound => 'Current location found!';

@override
String get locationRequestTimedOut => 'Location request timed out. Please try again.';

@override
String get locationPermissionRequired => 'This feature needs location permission to work properly.';

@override
String get locationServicesDisabledTitle => 'Location Services Disabled';

@override
String get pleaseEnableLocationServices => 'Please enable location services to use this feature.';

@override
String get cancel => 'Cancel';

@override
String get openSettings => 'Open Settings';

@override
String get retry => 'Retry';

@override
String get locationPermissionPermanentlyDenied => 'Location permission has been permanently denied. Please enable it in app settings.';

@override
String get enableInAppSettings => 'Open Settings';

@override
String get uploadingImage => 'Uploading image...';

@override
String get profileImageUpdatedSuccessfully => 'Profile image updated successfully!';

@override
String get failedToUploadImage => 'Failed to upload image';

@override
String get gettingLocationDetails => 'Getting location details...';

@override
String get locationUpdatedSuccessfully => 'Location updated successfully!';

@override
String get locationCoordinatesSaved => 'Location coordinates saved!';

@override
String get failedToPickLocation => 'Failed to pick location';

@override
String get nameCannotBeEmpty => 'Name cannot be empty';

@override
String get savingProfile => 'Saving profile...';

@override
String get profileUpdatedSuccessfully => 'Profile updated successfully!';

@override
String get failedToUpdateProfile => 'Failed to update profile';

@override
String get deleteAccountTitle => 'Delete Account';

@override
String get deleteAccountWarning => 'This action cannot be undone. Please enter your password to confirm.';

@override
String get enterYourPassword => 'Enter your password';

@override
String get deletingAccount => 'Deleting account...';

@override
String get errorDeletingAccount => 'Error deleting account';

@override
String get tapToAdd => 'Tap to add';

@override
String get save => 'Save';

@override
String get appSettings => 'App Settings';

@override
String get language => 'Language';

@override
String get updatingLanguage => 'Updating language...';

@override
String get languageUpdatedSuccessfully => 'Language updated successfully';

@override
String get failedToUpdateLanguage => 'Failed to update language';

@override
String get languageChanged => 'Language Changed';

@override
String get restartAppForComplete => 'The language has been updated. Some parts of the app may require a restart to fully reflect the changes.';

@override
String get okay => 'OK';

//collector side 
//collector dashboard


@override
String get collectorDashboard => 'COLLECTOR';

@override
String get readyToCollectToday => 'Ready to collect today?';

@override
String get customerList => 'Customer List';

@override
String get viewAllCustomers => 'View all customers';

@override
String get history => 'History';

@override
String get viewPastCollections => 'View past collections';

@override
String get mapView => 'Map View';

@override
String get seeCustomerLocations => 'See customer locations';

@override
String get profileSettings => 'Profile Settings';

@override
String get manageCollectorProfile => 'Manage your collector profile';

@override
String get chooseActionToStart => 'Choose an action to get started';

@override
String get logout => 'Logout';

@override
String get areYouSureLogout => '    Are you sure you want to logout?';

@override
String get map => 'Map';





// Notification Page
@override
String get customerNotifications => 'Customer Notifications';

@override
String get loadingNotifications => 'Loading notifications...';

@override
String get failedToLoadNotifications => 'Failed to load notifications';

@override
String get error => 'Error';

@override
String get allCaughtUp => 'All Caught Up!';

@override
String get noPendingCollectionRequests => 'No pending collection requests';

@override
String get allCustomersCollectedToday => 'All customers have been collected today';

@override
String get pendingCollection => 'Pending Collection';

@override
String get minutesAgo => 'm ago';

@override
String get hoursAgo => 'h ago';

@override
String get daysAgoShort => 'd ago';

@override
String get at => 'at';

@override
String get collect => 'Collect';

// Collection History Page
@override
String get collectionHistory => 'Collection History';

@override
String get searchByNameOrReg => 'Search by name or reg no...';

@override
String get sortByDate => 'Sort by Date';

@override
String get sortByName => 'Sort by Name';

@override
String get sortByRegNo => 'Sort by Reg No';

@override
String get sortByWeight => 'Sort by Weight';

@override
String get ascending => 'Ascending';

@override
String get descending => 'Descending';

@override
String get today => 'Today';

@override
String get loadingCollectionHistory => 'Loading collection history...';

@override
String get somethingWentWrong => 'Something went wrong';

@override
String get unableToLoadHistory => 'Unable to load collection history';

@override
String get filterByDateRange => 'Filter by Date Range';

@override
String get startDate => 'Start Date';

@override
String get endDate => 'End Date';

@override
String get foundCollectionsInRangee => 'Found {count} collections in selected date range';

@override
String get totalCollections => 'Collections';

@override
String get totalWeight => 'Total Weight';

@override
String get collected => 'Collected';

@override
String get noCollectionsToday => 'No Collections Today';

@override
String get noCollectionHistory => 'No Collection History';

@override
String get noCollectionsTodayDescription => 'You haven\'t collected from any customers today. Start collecting to see your progress here!';

@override
String get noCollectionHistoryDescription => 'You haven\'t made any collections yet. Once you start collecting, your history will appear here.';

@override
String get startCollecting => 'Start Collecting';

@override
String get collectionDetails => 'Collection Details';

@override
String get completed => 'Completed';

@override
String get customerName => 'Customer Name';

@override
String get registrationNo => 'Registration No';

@override
String get weightCollected => 'Weight Collected';

@override
String get collectionDate => 'Collection Date';

@override
String get collectionTime => 'Collection Time';

@override
String get collectedBy => 'Collected By';

@override
String get remarks => 'Remarks';

@override
String get close => 'Close';

@override
String get collector => 'Collector';


// Collector Map Page
@override
String get todaysCustomerLocations => 'Today\'s Customer Locations';

@override
String get changeMapLayer => 'Change map layer';

@override
String get centerTodaysMarkers => 'Center today\'s markers';

@override
String get errorLoadingMap => 'Error Loading Map';

@override
String get noCollectionRequestsToday => 'No collection requests found for today.';

@override
String get noLocationDataAvailable => 'Found {count} collection requests for today, but none have location data.\n\nPossible solutions:\n1. Ask customers to enable location when requesting\n2. Check if location data is stored in a different format\n3. Verify Firestore security rules allow location reading';

@override
String get switchedToMapView => 'Switched to {layerName} view';

@override
String get streetMap => 'Street Map';

@override
String get satellite => 'Satellite';

@override
String get terrain => 'Terrain';

@override
String get collectionCompletedAlready => 'This collection has already been completed';

@override
String get errorNavigatingToLocation => 'Error navigating to location';

@override
String get collectionCompletedSuccessfully => 'Collection completed successfully!';

@override
String get errorOpeningWeightPage => 'Error opening weight page: {error}';

@override
String get weightUpdatedSuccessfully => 'Weight updated successfully!';

@override
String get errorUpdatingWeight => 'Error updating weight: {error}';

@override
String get removeWeight => 'Remove Weight';

@override
String get areYouSureRemoveWeight => 'Are you sure you want to remove the weight for {customerName}?';

@override
String get remove => 'Remove';

@override
String get weightRemovedSuccessfully => 'Weight removed successfully';

@override
String get failedToRemoveWeight => 'Failed to remove weight: {error}';

@override
String get externalNavigationComingSoon => 'External navigation feature coming soon!';

@override
String get todaysCollections => 'Today\'s Collections';

@override
String get onMap => 'On Map';

@override
String get pending => 'Pending';

@override
String get todaysTotalWeight => 'Today\'s Total Weight: {weight} kg';

@override
String get completedCollectionsHidden => '{count} completed collections today (hidden from map)';

@override
String get centerTodaysPendingCollections => 'Center today\'s pending collections';

@override
String get viewDetails => 'View Details';

@override
String get addWeight => 'Add Weight';

@override
String get navigate => 'Navigate';

@override
String get updateWeight => 'Update Weight';

@override
String get timeRequested => 'Time';

@override
String get date => 'Date';

@override
String get requested => 'Requested';

@override
String get weight => 'Weight';

@override
String get address => 'Address';

@override
String get coordinatess => 'Coordinates';

@override
String get locationSource => 'Location Source';

@override
String get userProfile => 'User Profile';

@override
String get currentGPS => 'Current GPS';


// Admin side

// Admin Dashboard
@override
String get dashboard => 'Dashboard';

@override
String get goodMorningAdmin => 'Good Morning';

@override
String get goodAfternoonAdmin => 'Good Afternoon';

@override
String get goodEveningAdmin => 'Good Evening';

@override
String get admin => 'Admin';

@override
String get realTimeSystemOverview => 'Real-time System Overview';

@override
String get todaysActivity => 'Today\'s Activity';

@override
String get newUsers => 'New Users';

@override
String get activeAlerts => 'Active Alerts';

@override
String get alertsNeedAttention => '{count} alert(s) need attention';

@override
String get overview => 'Overview';

@override
String get totalUsers => 'Total Users';

@override
String get customers => 'Customers';

@override
String get collectors => 'Collectors';

@override
String get quickActionsTitle => 'Quick Actions';

@override
String get manageUsers => 'Manage Users';

@override
String get viewAndManageUsers => 'View and manage all users';

@override
String get uploadPaymentSlip => 'Upload Payment Slip';

@override
String get checkPaymentRecords => 'Check payment records';

@override
String get systemAlerts => 'System Alerts';

@override
String get monitorSystemNotifications => 'Monitor system notifications';

@override
String get logoutTitle => 'Logout';

@override
String get logoutConfirmation => 'Are you sure you want to log out?';

@override
String get logoutButton => 'Logout';

@override
String get activeAlertsTitle => 'Active Alerts';


// Manage Users Page
@override
String get userManagement => 'User Management';

@override
String get refreshUsers => 'Refresh Users';

@override
String get loadingUsers => 'Loading users...';

@override
String get userNotAuthenticated => 'User not authenticated';

@override
String get userDocumentNotFound => 'User document not found';

@override
String get accessDenied => 'Access denied. Admin privileges required.';

@override
String get adminAccessRequired => 'Admin access required';

@override
String get errorCheckingPermissions => 'Error checking permissions';

@override
String get errorLoadingUsers => 'Error loading users';

@override
String customersCount(int count) => 'Customers ($count)';

@override
String collectorsCount(int count) => 'Collectors ($count)';

@override
String get accessError => 'Access Error';

@override
String get tryAgain => 'Try Again';

@override
String get noCustomersFound => 'No customers found';

@override
String get noCollectorsFound => 'No collectors found';

@override
String get customersWillAppear => 'Customers will appear here once they register';

@override
String get collectorsWillAppear => 'Collectors will appear here once they register';

@override
String get unknownUser => 'Unknown User';

@override
String get noEmail => 'No email';

@override
String get reg => 'Reg';

@override
String get viewDetailsAction => 'View Details';

@override
String get editUser => 'Edit User';

@override
String get deleteUser => 'Delete User';

@override
String get invalidDate => 'Invalid date';

@override
String get personalInformationTitle => 'Personal Information';

@override
String get fullNameLabel => 'Full Name';

@override
String get emailAddressLabel => 'Email Address';

@override
String get registrationNoLabel => 'Registration No.';

@override
String get userRole => 'User Role';

@override
String get accountInformation => 'Account Information';

@override
String get joinedDate => 'Joined Date';

@override
String get lastUpdated => 'Last Updated';

@override
String get done => 'Done';

@override
String get editUserTitle => 'Edit User';

@override
String get fullNameField => 'Full Name';

@override
String get emailAddressField => 'Email Address';

@override
String get registrationNumberField => 'Registration Number';

@override
String get userRoleField => 'User Role';

@override
String get updateUser => 'Update User';

@override
String get nameAndEmailRequired => 'Name and Email are required';

@override
String get userUpdatedSuccessfully => 'User updated successfully';

@override
String get errorUpdatingUser => 'Error updating user';

@override
String get deleteUserTitle => 'Delete User';

@override
String get cannotDeleteOwnAccount => 'Cannot delete your own admin account';

@override
String deleteUserConfirmation(String userName) => 
    'Are you sure you want to delete "$userName"? This action cannot be undone and will permanently remove all user data.';

@override
String get userDeletedSuccessfully => 'User deleted successfully';

@override
String get errorDeletingUser => 'Error deleting user';

@override
String get payment => 'Payment';


@override
String get users => 'Users';

@override
String get settings => 'Settings';


// Payment Slip Page
@override
String get uploadPaymentSlipTitle => 'Upload Payment Slip';

@override
String get paymentSlipUpload => 'Payment Slip Upload';

@override
String get uploadPaymentSlipsForCustomers => 'Upload payment slips for customers';

@override
String get selectCustomerStep => 'Select Customer';

@override
String get uploadPaymentSlipStep => 'Upload Payment Slip';

@override
String get additionalNotes => 'Additional Notes';

@override
String get optional => 'Optional';

@override
String get tapToSelectCustomer => 'Tap to select customer';

@override
String get selectCustomerTitle => 'Select Customer';

@override
String get searchByNameEmailOrReg => 'Search by name, email, or reg number...';

@override
String get noMatchingCustomers => 'No matching customers';

@override
String get tapToSelectFile => 'Tap to select file';

@override
String get pdfJpgPngSupported => 'PDF, JPG, PNG supported';

@override
String get enterAdditionalNotes => 'Enter any additional notes...';

@override
String get clearForm => 'Clear form';

@override
String get fileSelected => 'File selected';

@override
String get noFileSelected => 'No file selected';

@override
String get pleaseSelectCustomer => 'Please select a customer';

@override
String get pleaseSelectPaymentSlipFile => 'Please select a payment slip file';

@override
String get adminNotLoggedIn => 'Admin not logged in';

@override
String get uploadFailed => 'Upload failed';

@override
String get successTitle => 'Success!';

@override
String get paymentSlipUploadedTo => 'Payment slip uploaded to';

@override
String get folder => 'folder';

@override
String get uploadingTo => 'Uploading to';

@override
String get uploadPaymentSlipButton => 'Upload Payment Slip';

@override
String get step => 'Step';

// Alert Page - Main
@override
String get systemAlert => 'System Alert';

@override
String get loadingAlerts => 'Loading alerts...';

@override
String get noAlertsFound => 'No Alerts Found';

@override
String get noAlertsDescription => 'You\'re all caught up! No new alerts at the moment.';

@override
String get alertDeletedSuccessfully => 'Alert deleted successfully';

// Alert Filters
@override
String get allAlerts => 'All Alerts';

@override
String get criticalAlerts => 'Critical';

@override
String get warningAlerts => 'Warnings';

@override
String get infoAlerts => 'Info';

@override
String get successAlerts => 'Success';

// Alert Details
@override
String get alertDescription => 'Description';

@override
String get noDescriptionAvailable => 'No description available';

@override
String get additionalDetails => 'Additional Details';

@override
String get markAsRead => 'Mark as Read';

@override
String get deleteAlert => 'Delete Alert';

@override
String get deleteAlertConfirmation => 'Are you sure you want to delete this alert?';

@override
String get delete => 'Delete';

@override
String get alertMarkedAsRead => 'Alert marked as read';

// Alert Types
@override
String get criticalAlert => 'Critical Alert';

@override
String get warningAlert => 'Warning Alert';

@override
String get infoAlert => 'Information Alert';

@override
String get successAlert => 'Success Alert';

// Alert Actions
@override
String get viewAlert => 'View Alert';

@override
String get dismissAlert => 'Dismiss Alert';

@override
String get readAlerts => 'Read Alerts';

@override
String get unreadAlerts => 'Unread Alerts';

@override
String get clearAllAlerts => 'Clear All Alerts';

@override
String get noUnreadAlerts => 'No unread alerts';

@override
String get alertsCleared => 'All alerts cleared';

//Customer Payment Slip Page -
@override
String get paymentSlips => 'Payment Slips';

@override
String get loadingPaymentSlips => 'Loading payment slips...';

@override
String get noPaymentSlips => 'No Payment Slips';

@override
String get paymentSlipsWillAppearHere => 'Payment slips will appear here';

@override
String get filterSort => 'Filter & Sort';

@override
String get download => 'Download';

@override
String get downloading => 'Downloading';

@override
String get share => 'Share';

@override
String get apply => 'Apply';

@override
String get slips => 'Slips';

@override
String get total => 'Total';

@override
String get verified => 'Verified';

@override
String get all => 'All';

@override
String get no => 'No';

@override
String get sortAndFilter => 'Sort & Filter';

@override
String get order => 'Order';

@override
String get paymentId => 'Payment ID';

@override
String get status => 'Status';

@override
String get fileName => 'File Name';

@override
String get fileSize => 'File Size';


@override
String get uploadedBy => 'Uploaded By';

@override
String get refresh => 'Refresh';

@override
String get notes => 'Notes';

@override
String get sortBy => 'Sort By';

// Swipe Actions
@override
String get swipeToMarkAsRead => 'Swipe right to mark as read';

@override
String get swipeToDelete => 'Swipe left to delete';

@override
String customerCollectedSuccessfullyWithWeight(String customerName, double weight) {
  return '$customerName collected successfully (${weight}kg)';
}

@override
String customerCollectedSuccessfully(String customerName) {
  return '$customerName collected successfully';
}

  @override
  String foundCollectionsInRange(int count) {
    // TODO: implement foundCollectionsInRange
    throw UnimplementedError();
  }

}