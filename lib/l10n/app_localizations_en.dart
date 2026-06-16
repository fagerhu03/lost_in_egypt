// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Lost in Egypt';

  @override
  String get navHome => 'Home';

  @override
  String get navCommunity => 'Community';

  @override
  String get navMap => 'Map';

  @override
  String get navCamera => 'Camera';

  @override
  String get navMore => 'More';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get commonDismiss => 'Dismiss';

  @override
  String get reportUser => 'Report User';

  @override
  String get reportTour => 'Report Tour';

  @override
  String get reportPost => 'Report Post';

  @override
  String get reportComment => 'Report Comment';

  @override
  String get reportReasonPrompt => 'Why are you reporting this?';

  @override
  String get reportAdditionalDetails => 'Additional details (optional)';

  @override
  String get reportSubmit => 'Submit Report';

  @override
  String get reportMustBeLoggedIn =>
      'You must be logged in to submit a report.';

  @override
  String get reportSelectReason => 'Please select a reason for reporting.';

  @override
  String get reportDescriptionTooLong =>
      'Description must be 500 characters or fewer.';

  @override
  String get reportSuccess => 'Report submitted successfully. Thank you.';

  @override
  String get weatherTapForForecast => 'Tap for 7-day forecast';

  @override
  String get weatherConditionsNow => 'Egypt conditions right now';

  @override
  String get weather7DayForecast => '7-Day Forecast';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSelectLanguage => 'Select Language';

  @override
  String get settingsDisplayCurrency => 'Display Currency';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get settingsResetBadges => 'Reset Badges (Debug)';

  @override
  String get settingsBadgesResetSuccess => 'Badges successfully reset!';

  @override
  String get settingsResetTasteSignals => 'Reset Taste Signals (Debug)';

  @override
  String get settingsResetTasteSignalsTitle => 'Reset Taste Signals?';

  @override
  String get settingsResetTasteSignalsBody =>
      'This clears every personalisation signal recorded for you — saved likes, dismissals, quiz answers, visit history. Recommendations will reset to defaults until you interact again.';

  @override
  String get settingsTasteSignalsReset => 'Taste signals reset.';

  @override
  String get settingsTasteSignalsResetError =>
      'Couldn\'t reset signals. Try again.';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get commonContinue => 'Continue';

  @override
  String get authEmailHint => 'Enter your email';

  @override
  String get authPasswordHint => 'Enter your password';

  @override
  String get loginTagline => 'Log in to unlock your journey.';

  @override
  String get loginButton => 'Log In';

  @override
  String get loginForgotPassword => 'Forgot Password?';

  @override
  String get loginOrSignInWith => 'OR SIGN IN WITH';

  @override
  String get loginNoAccount => 'Don\'t have an account?';

  @override
  String get loginCreateAccount => 'Create Account';

  @override
  String get loginFillEmailPassword =>
      'Please fill in your email and password.';

  @override
  String get loginGuidePending => 'Your guide application is pending approval.';

  @override
  String get forgotEnterEmail => 'Please enter your email';

  @override
  String get forgotResetSent => 'If an account exists, a reset link was sent.';

  @override
  String get forgotFailedSend => 'Failed to send reset email';

  @override
  String get forgotInvalidEmail => 'Invalid email formatting.';

  @override
  String get forgotEmailSentTitle => 'Email Sent!';

  @override
  String get forgotResetTitle => 'Reset Password';

  @override
  String forgotEmailSentBody(String email) {
    return 'If an account is registered to $email, we\'ve sent a secure password reset link. Please check your email.';
  }

  @override
  String get forgotResetBody =>
      'Enter your email to receive a secure password reset link.';

  @override
  String get forgotSendLink => 'Send Reset Link';

  @override
  String get forgotReturnToLogin => 'Return to Login';

  @override
  String get usernameTitle => 'Choose your\nusername';

  @override
  String get usernameSubtitle =>
      'This is how others will find you in the community. You can change it later in your profile.';

  @override
  String usernameAvailable(String handle) {
    return '@$handle is available!';
  }

  @override
  String get usernameRules =>
      '3–20 characters · letters, numbers, underscores only';

  @override
  String get usernameTooShort => 'Too short — minimum 3 characters';

  @override
  String get usernameTooLong => 'Too long — maximum 20 characters';

  @override
  String get usernameInvalidChars =>
      'Only lowercase letters, numbers, and underscores';

  @override
  String get usernameTaken => 'That username is already taken';

  @override
  String get usernameCheckFailed => 'Couldn\'t check availability — try again';

  @override
  String get usernameTakenJustNow =>
      'That username was just taken — try another';

  @override
  String get usernameSaveFailed => 'Failed to save — please try again';

  @override
  String get roleSelectionTitle => 'Are you a...';

  @override
  String get roleTraveler => 'TRAVELER!';

  @override
  String get roleGuide => 'GUIDE!';

  @override
  String get completeProfileTitle => 'One Last Step';

  @override
  String get completeProfileSubtitle =>
      'We need your birthdate to customize your journey in Egypt.';

  @override
  String get completeProfileButton => 'Complete Setup';

  @override
  String get dobMonth => 'Month';

  @override
  String get dobDay => 'Day';

  @override
  String get dobYear => 'Year';

  @override
  String get signupTitle => 'New Account';

  @override
  String get signupFirstNameHint => 'First Name';

  @override
  String get signupLastNameHint => 'Last Name';

  @override
  String get signupDateOfBirth => 'Date of birth';

  @override
  String get signupEmailHint => 'Email';

  @override
  String get signupPhoneLabel => 'Phone Number';

  @override
  String get signupConfirmPasswordHint => 'Confirm your password';

  @override
  String get signupButton => 'Sign Up';

  @override
  String get signupHaveAccount => 'Already have an account?';

  @override
  String get signupFirstNameInvalid =>
      'First name must contain valid letters (min 2).';

  @override
  String get signupLastNameInvalid =>
      'Last name must contain valid letters (min 2).';

  @override
  String get signupEmailInvalid => 'Please enter a valid email address.';

  @override
  String get signupPasswordWeak =>
      'Password must be 8+ characters with at least 1 letter and 1 number.';

  @override
  String get signupPasswordsNoMatch => 'Passwords do not match.';

  @override
  String get signupPhoneInvalid => 'Please enter a valid phone number.';

  @override
  String get signupSuccess =>
      'Account created! Please verify your email to continue.';

  @override
  String get signupEmailInUse => 'This email is already registered.';

  @override
  String get signupPasswordTooWeak => 'The password is too weak.';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String homeGreeting(String greeting, String name) {
    return '$greeting, $name 👋';
  }

  @override
  String get homeWhereToGo => 'Where do you want to go?';

  @override
  String get homePopularPlaces => 'Popular Places';

  @override
  String get homeForYou => 'For You';

  @override
  String get homeExperiences => 'Experiences';

  @override
  String get homeSeeAll => 'see all >';

  @override
  String get homeNoEventsInCategory => 'No events in this category';

  @override
  String get homePopularTours => 'Popular Tours';

  @override
  String get homePlanYourTrip => 'Plan your trip';

  @override
  String get homeTripGuides => 'Guides';

  @override
  String get homeTripSolo => 'Solo trip';

  @override
  String get communityTitle => 'Community';

  @override
  String get communitySearchPostsHint => 'Search posts...';

  @override
  String get communitySortTooltip => 'Sort';

  @override
  String get communityTagLocation => 'Tag a Location';

  @override
  String get communitySearchPlacesHint => 'Search places in Egypt...';

  @override
  String get communityTypeToSearch => 'Type to search places...';

  @override
  String get communityPostCategory => 'Post Category';

  @override
  String get communityCategoryPhotos => 'Photos';

  @override
  String get communityCategoryQuestions => 'Questions';

  @override
  String get communityCategoryGuides => 'Guides';

  @override
  String get communityCategoryLandmarks => 'Landmarks';

  @override
  String get communityCategoryTips => 'Traveler\'s Tips';

  @override
  String get communitySortPosts => 'Sort Posts';

  @override
  String get communitySortNewest => 'Newest';

  @override
  String get communitySortTopRated => 'Top Rated';

  @override
  String get communitySortMostDiscussed => 'Most Discussed';

  @override
  String get communitySomethingWrong =>
      'Something went wrong. Please try again.';

  @override
  String get communityNoPostsYet => 'No posts yet. Be the first!';

  @override
  String communityNoResultsFor(String query) {
    return 'No results for \'$query\'';
  }

  @override
  String get communityNoPostsInCategory => 'No posts in this category yet.';

  @override
  String get communityNewPosts => 'New posts — tap to refresh';

  @override
  String get communityTrending => 'Trending';

  @override
  String get communityClearFilter => 'Clear filter';

  @override
  String get communityTopExplorers => 'Top Explorers This Feed';

  @override
  String communityPostsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count posts',
      one: '1 post',
    );
    return '$_temp0';
  }

  @override
  String get communityWeeklyChallenge => 'Weekly Challenge';

  @override
  String get communityPostNow => 'Post Now';

  @override
  String get communityComposerHint => 'Share your Egypt experience...';

  @override
  String get communityPostButton => 'Post';

  @override
  String get communityAddPhotosTooltip => 'Add photos';

  @override
  String get communityTagLocationTooltip => 'Tag location';

  @override
  String get communityCategoryTooltip => 'Category';

  @override
  String get commonSave => 'Save';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonReport => 'Report';

  @override
  String get commentEditTitle => 'Edit Comment';

  @override
  String get commentDeleteTitle => 'Delete Comment';

  @override
  String get commentDeleteConfirm =>
      'Are you sure you want to delete this comment?';

  @override
  String get commentReply => 'Reply';

  @override
  String commentReplyingTo(String name) {
    return 'Replying to @$name';
  }

  @override
  String get commentWriteReply => 'Write a reply...';

  @override
  String get commentWriteComment => 'Write a comment...';

  @override
  String get commentsEmpty => 'No comments yet. Be the first!';

  @override
  String commentViewReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'View $count replies',
      one: 'View 1 reply',
    );
    return '$_temp0 ▸';
  }

  @override
  String get commentHideReplies => 'Hide replies ▴';

  @override
  String get commentsViewMore => 'View More Comments';

  @override
  String commentsHeader(int count) {
    return 'Comments ($count)';
  }

  @override
  String get moreTitle => 'More';

  @override
  String get moreCurrency => 'Currency';

  @override
  String get moreHelp => 'Help';

  @override
  String get moreTranslator => 'Translator';

  @override
  String get moreContactUs => 'Contact us';

  @override
  String get moreSosButton => 'SOS — Emergency Numbers';

  @override
  String get contactCouldNotOpen => 'Could not open link';

  @override
  String contactEmailCopied(String email) {
    return '$email copied to clipboard';
  }

  @override
  String get contactTitle => 'Contact Us';

  @override
  String get contactHeadline => 'We\'re here to help';

  @override
  String get contactSubtitle =>
      'Reach out through any of the channels below and we\'ll get back to you as soon as possible.';

  @override
  String get contactEmailSupport => 'Email Support';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => 'Chat with us directly';

  @override
  String get contactInstagram => 'Instagram';

  @override
  String get contactResponseTimes => 'Response times';

  @override
  String get contactRespEmail => 'Email';

  @override
  String get contactRespInstagram => 'Instagram DMs';

  @override
  String get contactTimeEmail => 'Within 24 hours';

  @override
  String get contactTimeWhatsApp => 'Within a few hours';

  @override
  String get contactTimeInstagram => '1–2 business days';

  @override
  String get sosAppBarTitle => 'SOS — Emergency';

  @override
  String get sosFindNearestHelp => 'Find Nearest Help';

  @override
  String get sosPolice => 'Police';

  @override
  String get sosHospital => 'Hospital';

  @override
  String get sosFireStation => 'Fire Station';

  @override
  String sosFindNearest(String category) {
    return 'Find Nearest $category';
  }

  @override
  String sosRefresh(String category) {
    return 'Refresh — $category';
  }

  @override
  String get sosUsingLocation => 'Using your current location';

  @override
  String get sosEnableLocation =>
      'Please enable location in your device settings to find nearby help.';

  @override
  String get sosLocationError =>
      'Make sure location services are enabled and try again.';

  @override
  String sosNoResults(String category) {
    return 'No $category found within 10 km. Try moving to a different area.';
  }

  @override
  String get sosSearchFailed =>
      'Search failed — check your connection and try again.';

  @override
  String get sosCouldNotDial => 'Could not open dialler';

  @override
  String get sosEmergencyNumbers => 'Emergency Numbers';

  @override
  String get sosNumbersNote =>
      'These are Egypt\'s official emergency numbers. Tourist Police (126) has English-speaking operators.';

  @override
  String get sosTouristPolice => 'Tourist Police';

  @override
  String get sosAmbulance => 'Ambulance';

  @override
  String get sosFireBrigade => 'Fire Brigade';

  @override
  String get sosGasEmergency => 'Gas Emergency';

  @override
  String get sosTouristPoliceSubtitle =>
      'English-speaking operators · Available 24/7';

  @override
  String get sosForTourists => 'FOR TOURISTS';

  @override
  String get sosCall => 'Call';

  @override
  String get sosMap => 'Map';

  @override
  String get accountUser => 'User';

  @override
  String get accountYourTaste => 'Your Taste';

  @override
  String get accountSettingsHeader => 'Account Settings:';

  @override
  String get accountEditProfile => 'Edit Profile';

  @override
  String get accountApplyGuide => 'Apply to be a Guide';

  @override
  String get accountMyBookings => 'My Bookings';

  @override
  String get accountSavedPosts => 'Saved Posts';

  @override
  String get accountMyPlans => 'My Plans';

  @override
  String get accountMembership => 'Membership';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountGuideApplication => 'Guide Application';

  @override
  String get accountStatusUnderReview => 'Under Review';

  @override
  String get accountStatusNotApproved => 'Not Approved';

  @override
  String get planExplorerFree => 'Explorer — Free';

  @override
  String get planActive => 'Active';

  @override
  String get planCurrentDesc =>
      'Your current plan — enjoy all the core features of Lost in Egypt at no cost.';

  @override
  String get planWhatsIncluded => 'What\'s included';

  @override
  String get planFeatDiscoveryTitle => 'AI Landmark Discovery';

  @override
  String get planFeatDiscoveryDesc =>
      'Identify unlimited landmarks with your camera';

  @override
  String get planFeatStoriesTitle => 'AI Historical Stories';

  @override
  String get planFeatStoriesDesc =>
      'Hear captivating stories about every landmark you find';

  @override
  String get planFeatMapTitle => 'Interactive Map';

  @override
  String get planFeatMapDesc =>
      'Explore 500+ Egyptian landmarks with GPS and routing';

  @override
  String get planFeatToursTitle => 'Browse & Book Tours';

  @override
  String get planFeatToursDesc =>
      'Browse guided tours and book with certified guides';

  @override
  String get planFeatBadgesTitle => 'Badges & Gamification';

  @override
  String get planFeatBadgesDesc => 'Earn badges as you explore more of Egypt';

  @override
  String get planFeatCommunityTitle => 'Community Feed';

  @override
  String get planFeatCommunityDesc =>
      'Share discoveries and connect with fellow travellers';

  @override
  String get planFeatTranslatorTitle => 'Translator';

  @override
  String get planFeatTranslatorDesc =>
      'Translate text using your camera in real-time';

  @override
  String get planFeatCurrencyTitle => 'Currency Converter';

  @override
  String get planFeatCurrencyDesc => 'Convert between 16 currencies instantly';

  @override
  String get planFeatNotificationsTitle => 'Booking Notifications';

  @override
  String get planFeatNotificationsDesc =>
      'Get notified about your tour confirmations';

  @override
  String get planComingSoon => 'Coming soon';

  @override
  String get planComingSoonDesc =>
      'We\'re working on premium features including offline mode, exclusive guided experiences, and advanced trip planning tools. Stay tuned — and the core app will always remain free.';

  @override
  String get profileViewTitle => 'Profile';

  @override
  String get profileUserNotFound => 'User not found';

  @override
  String get profileEmail => 'Email';

  @override
  String get profilePhone => 'Phone';

  @override
  String get profilePostsStat => 'Posts';

  @override
  String get profilePlacesStat => 'Places';

  @override
  String get profileRole => 'Role';

  @override
  String get profileRoleAdmin => 'Admin';

  @override
  String get profileRoleVerifiedGuide => 'Verified Guide';

  @override
  String get profileRoleTourist => 'Tourist';

  @override
  String get profileAbout => 'About';

  @override
  String get profileInterests => 'Interests';

  @override
  String get profileSocial => 'Social';

  @override
  String get profileInstagram => 'Instagram';

  @override
  String get profileTwitter => 'Twitter';

  @override
  String get profileContact => 'Contact';

  @override
  String get profileBadges => 'Badges';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get editPhotoUpdated => 'Profile photo updated ✅';

  @override
  String get editPhotoUploadError => 'Error uploading photo. Please try again.';

  @override
  String get editPhoneMustVerify =>
      'Phone number must be verified before saving';

  @override
  String get editInstagramRule =>
      'Instagram: letters, numbers, . and _ only (max 30)';

  @override
  String get editTwitterRule =>
      'Twitter/X: letters, numbers, . and _ only (max 15)';

  @override
  String get editUsernameEmpty => 'Username cannot be empty';

  @override
  String get editLangRequestTitle => 'Request Language Addition';

  @override
  String get editLangRequestBody =>
      'By Egyptian law, guides require official certification to guide in specific languages. Please enter the language you wish to add. An admin will verify your syndicate/MOTA records.';

  @override
  String get editLangRequestHint => 'e.g., Spanish, German, Italian';

  @override
  String get editLangSubmit => 'Submit Request';

  @override
  String get editLangPending => 'You already have a pending language request.';

  @override
  String get editLangSubmitted =>
      'Request submitted! An admin will review it shortly.';

  @override
  String get editProfileUpdated => 'Profile Updated ✅';

  @override
  String get editProfileCompletion => 'Profile Completion';

  @override
  String get editSectionBasic => 'Basic Information';

  @override
  String get editFullName => 'Full name';

  @override
  String get editUsername => 'Username';

  @override
  String get editPhoneNumber => 'Phone number';

  @override
  String get editNationality => 'Nationality';

  @override
  String get editSectionContact => 'Contact Information';

  @override
  String get editSectionAbout => 'About You';

  @override
  String get editBio => 'Bio';

  @override
  String get editBioHint => 'Tell us about yourself...';

  @override
  String get editSectionSocial => 'Social Links (Optional)';

  @override
  String get editSocialHint => 'username (no @)';

  @override
  String get editTwitterLabel => 'Twitter/X';

  @override
  String get editSectionGuide => 'Guide Credentials';

  @override
  String get editCertifiedLangs => 'Certified Languages (Locked)';

  @override
  String get editNoCertifiedLangs => 'None certified yet.';

  @override
  String get editRequestNewLang => 'Request New Language';

  @override
  String get editSearchNationality => 'Search nationality';

  @override
  String get editUsernameHint => 'your_handle';

  @override
  String get editVerificationStatus => 'Verification Status';

  @override
  String get editVerificationEmailSent =>
      'Verification email sent! Check your inbox.';

  @override
  String get editResend => 'Resend';

  @override
  String get editVerifyNow => 'Verify now';

  @override
  String get editSaveChanges => 'Save Changes';

  @override
  String get currencyConverterTitle => 'Currency Converter';

  @override
  String get currencyEnterValidAmount => 'Please enter a valid amount';

  @override
  String currencyRateUnavailable(String currency) {
    return 'Rate not available for $currency';
  }

  @override
  String get currencyFrom => 'From';

  @override
  String get currencyTo => 'To';

  @override
  String get currencyAmount => 'Amount';

  @override
  String get currencyEnterAmount => 'Enter amount';

  @override
  String get currencyConvert => 'Convert';

  @override
  String get currencyResult => 'Result';

  @override
  String get translatorInitFailed => 'Failed to initialize translator';

  @override
  String get translatorEnterText => 'Please enter text to translate';

  @override
  String get translatorTimedOut =>
      'Translation timed out. Models may still be downloading — try again in a moment.';

  @override
  String get translatorFailed =>
      'Translation failed. If offline, models may not be downloaded yet.';

  @override
  String get translatorDownloadingModels =>
      'Downloading translation models for offline use...';

  @override
  String get translatorWorksOffline =>
      'Works offline - models cached on device';

  @override
  String get translatorEnterTextHint => 'Enter text';

  @override
  String get translatorTranslationHint => 'Translation';

  @override
  String get translatorTranslate => 'Translate';

  @override
  String get helpFaqTitle => 'Help & FAQ';

  @override
  String get helpSecGettingStarted => 'Getting Started';

  @override
  String get helpSecMapPlaces => 'Map & Places';

  @override
  String get helpSecBookings => 'Bookings & Payments';

  @override
  String get helpSecCommunity => 'Community';

  @override
  String get helpSecAccount => 'Account & Settings';

  @override
  String get helpSecOffline => 'Offline Mode';

  @override
  String get helpSecSafety => 'Safety & Emergency';

  @override
  String get helpQDiscover => 'How do I discover landmarks?';

  @override
  String get helpADiscover =>
      'Open the Camera tab and point your phone at any Egyptian landmark. The AI will identify it and generate a historical story read aloud by your personal guide. Each discovery is saved to your profile and counts toward your badge progress.';

  @override
  String get helpQBadges => 'How do I earn badges?';

  @override
  String get helpABadges =>
      'Badges are earned by discovering landmarks through the Camera tab. Visit 1, 3, 5, 10, and 20 unique landmarks to unlock Novice Explorer, Tourist, Tomb Raider, Historian, and Pharaoh badges respectively. There are also hidden badges — explore and find them!';

  @override
  String get helpQGuide => 'How do I become a tour guide?';

  @override
  String get helpAGuide =>
      'Go to Account → Apply as Guide. You\'ll need your MOTA license number, syndicate number, certified languages, and supporting documents. Applications are reviewed by our admin team and you will be notified of the outcome in-app.';

  @override
  String get helpQSavePlaces => 'Can I save places to visit later?';

  @override
  String get helpASavePlaces =>
      'Yes! On the Map tab, tap any landmark pin and press the bookmark icon to save it. You can also save events from the Home tab by tapping the heart icon on any event card. Access all your saved places from the Map tab → Saved Places.';

  @override
  String get helpQRecognise =>
      'My camera didn\'t recognise a landmark — what should I do?';

  @override
  String get helpARecognise =>
      'Ensure the landmark fills most of the frame and is well lit. Tap the shutter button and wait a few seconds. If the landmark is very minor or off the main tourist trail it may not be in the database yet.';

  @override
  String get helpQBook => 'How do I book a tour?';

  @override
  String get helpABook =>
      'Go to the Home tab and browse available guided tours, or find one on the Map tab. Choose a tour, select your date and number of tickets, then complete payment using any of the available payment methods shown at checkout (card, Apple Pay, or mobile wallet).';

  @override
  String get helpQCancel => 'How do I cancel a booking?';

  @override
  String get helpACancel =>
      'Go to Account → My Bookings, find the booking under the Upcoming tab, and tap Cancel. Refund policies are set by each guide — check the tour details before booking.';

  @override
  String get helpQSecure => 'Is my payment information secure?';

  @override
  String get helpASecure =>
      'Yes. Payments are processed through Paymob, a certified PCI-compliant payment gateway. Lost in Egypt never stores your card or wallet details on its servers.';

  @override
  String get helpQCurrency => 'How do I change my display currency?';

  @override
  String get helpACurrency =>
      'Go to More → Settings → Preferred Currency. All tour prices across the app will display in your chosen currency. The actual charge at checkout is always processed in EGP via Paymob.';

  @override
  String get helpQPost => 'How do I post in the community?';

  @override
  String get helpAPost =>
      'Tap the Community tab and press the + button. You can write text, add photos, tag a location, choose a category (Travel Story, Question, Tip, etc.), and use #hashtags or @mention other users.';

  @override
  String get helpQReport => 'How do I report a post or user?';

  @override
  String get helpAReport =>
      'On any community post or comment, tap the ⋮ menu and select Report. Our admin team reviews all reports and takes action within 24 hours.';

  @override
  String get helpQUsername => 'How do I change my username?';

  @override
  String get helpAUsername =>
      'Go to Account → Edit Profile. Your username (e.g. @ahmed_x1) must be 3–20 characters, lowercase letters, numbers, and underscores only, and globally unique. It is displayed on all your posts and comments.';

  @override
  String get helpQTheme => 'How do I switch between light and dark mode?';

  @override
  String get helpATheme =>
      'Go to More → Settings and toggle the Dark Mode switch. Your preference is saved to your account and synced across devices.';

  @override
  String get helpQOfflineWhat =>
      'What can I use without an internet connection?';

  @override
  String get helpAOfflineWhat =>
      'Lost in Egypt is designed primarily as an online experience, but several features remain available offline:\n\n• Map pins — over 500 Egyptian landmarks are bundled locally in the app, so the map shows location markers even without internet (map tiles themselves require connectivity).\n• Cached images — places and event images you have previously viewed are stored on your device and load instantly offline.\n• Text recognition (Camera → Scan text) — ML Kit processes text entirely on-device.\n• Translator — once a language pack is downloaded, translation works offline.\n• App navigation, badges, and settings — always available.';

  @override
  String get helpQOfflineNeed =>
      'What features require an internet connection?';

  @override
  String get helpAOfflineNeed =>
      'The following features need an active connection:\n\n• Landmark identification via the Camera tab (uses Google Cloud Vision API)\n• AI historical story generation (uses Google Gemini)\n• Community posts, likes, and comments (Firestore)\n• Browsing and booking tours (Firestore)\n• Events feed (Firestore)\n• Currency conversion (live exchange rates)\n• SOS — nearest emergency services search (Google Places API)\n• Signing in or creating an account (Firebase Auth)';

  @override
  String get helpQOfflineImprove =>
      'Will offline-capable features improve over time?';

  @override
  String get helpAOfflineImprove =>
      'Yes. We plan to expand offline support in future updates, including downloadable city guides and cached tour content. Keep the app updated to get these improvements.';

  @override
  String get helpQEmergency => 'What do I do in an emergency?';

  @override
  String get helpAEmergency =>
      'Open More → SOS. You can find the nearest police station, hospital, or fire station using your current location, or dial Egypt\'s official emergency numbers directly from the app:\n• Police: 122\n• Ambulance: 123\n• Fire: 180\n• Tourist Police: 126';
}
