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
  String get reportReasonImpersonation => 'Impersonation';

  @override
  String get reportReasonFakeAccount => 'Fake Account';

  @override
  String get reportReasonHarassmentBullying => 'Harassment or Bullying';

  @override
  String get reportReasonInappropriateProfile =>
      'Inappropriate Profile Content';

  @override
  String get reportReasonScamFraud => 'Scam or Fraud';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get reportReasonSpamAds => 'Spam or Ads';

  @override
  String get reportReasonHateSpeech => 'Hate Speech';

  @override
  String get reportReasonFalseInfo => 'False Information';

  @override
  String get reportReasonExplicitContent => 'Explicit Content';

  @override
  String get reportReasonHarassment => 'Harassment';

  @override
  String get reportReasonUnsafe => 'Unsafe Location/Activity';

  @override
  String get reportReasonInaccurate => 'Inaccurate Description';

  @override
  String get reportReasonFakeReviews => 'Fake Reviews';

  @override
  String get reportReasonOverpriced => 'Overpriced/Hidden Fees';

  @override
  String get weatherTapForForecast => 'Tap for 7-day forecast';

  @override
  String get weatherConditionsNow => 'Egypt conditions right now';

  @override
  String get weather7DayForecast => '7-Day Forecast';

  @override
  String get weatherCondSandstorm => 'Sandstorm';

  @override
  String get weatherCondSandstormWarning => 'Sandstorm Warning';

  @override
  String get weatherCondDustHaze => 'Dust Haze';

  @override
  String get weatherCondExtremeHeat => 'Extreme Heat';

  @override
  String get weatherCondVeryHot => 'Very Hot';

  @override
  String get weatherCondExtremeUV => 'Extreme UV';

  @override
  String get weatherCondHighUV => 'High UV';

  @override
  String get weatherCondClear => 'Clear';

  @override
  String get weatherCondGood => 'Good Conditions';

  @override
  String get weatherAdvisorySandstorm =>
      'Sandstorm in the area — avoid all outdoor locations. Wear a mask if you must travel.';

  @override
  String get weatherAdvisoryDustHaze =>
      'Dust haze reducing visibility. Outdoor visits not ideal; wear sunglasses.';

  @override
  String weatherAdvisoryExtremeHeat(String temp) {
    return 'Feels like $temp°C. Visit outdoor sites before 9am or after 5pm only. Bring at least 2L of water.';
  }

  @override
  String weatherAdvisoryVeryHot(String temp) {
    return 'Very hot ($temp°C feels-like). Stay hydrated and seek shade often.';
  }

  @override
  String weatherAdvisoryExtremeUV(String uv) {
    return 'UV index $uv — extreme. Sunscreen, hat, and sunglasses are essential. Limit midday exposure.';
  }

  @override
  String weatherAdvisoryHighUV(String uv) {
    return 'UV index $uv — high. Apply sunscreen SPF 50+ before going outdoors.';
  }

  @override
  String get weatherAdvisoryGood =>
      'Great conditions for outdoor exploration today.';

  @override
  String get weatherDayToday => 'Today';

  @override
  String get weatherDayTomorrow => 'Tomorrow';

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
  String get dobMonthJanuary => 'January';

  @override
  String get dobMonthFebruary => 'February';

  @override
  String get dobMonthMarch => 'March';

  @override
  String get dobMonthApril => 'April';

  @override
  String get dobMonthMay => 'May';

  @override
  String get dobMonthJune => 'June';

  @override
  String get dobMonthJuly => 'July';

  @override
  String get dobMonthAugust => 'August';

  @override
  String get dobMonthSeptember => 'September';

  @override
  String get dobMonthOctober => 'October';

  @override
  String get dobMonthNovember => 'November';

  @override
  String get dobMonthDecember => 'December';

  @override
  String get dobErrorMissing => 'Please select your date of birth.';

  @override
  String get dobErrorInvalid => 'Invalid date of birth.';

  @override
  String dobErrorTooManyDays(String month, String year, int days) {
    return '$month $year has only $days days.';
  }

  @override
  String dobErrorUnderage(int minAge) {
    return 'You must be at least $minAge years old to use this app.';
  }

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
  String get tasteKeyHistory => 'History';

  @override
  String get tasteKeyAncientSites => 'Ancient Sites';

  @override
  String get tasteKeyAttractions => 'Attractions';

  @override
  String get tasteKeyMuseums => 'Museums';

  @override
  String get tasteKeyMosques => 'Mosques';

  @override
  String get tasteKeyChurches => 'Churches';

  @override
  String get tasteKeyParks => 'Parks';

  @override
  String get tasteKeyBeaches => 'Beaches';

  @override
  String get tasteKeyRestaurants => 'Restaurants';

  @override
  String get tasteKeyCafes => 'Cafés';

  @override
  String get tasteKeyMarkets => 'Markets';

  @override
  String get tasteKeyShopping => 'Shopping';

  @override
  String get tasteKeyMonuments => 'Monuments';

  @override
  String get tasteKeyArt => 'Art';

  @override
  String get tasteKeyNightlife => 'Nightlife';

  @override
  String get tasteKeyThemeParks => 'Theme Parks';

  @override
  String get tasteKeyAquariums => 'Aquariums';

  @override
  String get tasteKeyZoos => 'Zoos';

  @override
  String get tasteKeySpas => 'Spas';

  @override
  String get tasteKeyStadiums => 'Stadiums';

  @override
  String get tasteKeyEntertainment => 'Entertainment';

  @override
  String get tasteKeyCultural => 'Cultural';

  @override
  String get tasteKeyNature => 'Nature';

  @override
  String get tasteKeyRelaxation => 'Relaxation';

  @override
  String get tasteKeyReligious => 'Religious';

  @override
  String get tasteKeyFamily => 'Family';

  @override
  String get tasteKeyAdventure => 'Adventure';

  @override
  String get tasteKeyFood => 'Food';

  @override
  String get tasteKeyAncient => 'Ancient';

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

  @override
  String get soloTripTitle => 'Solo Trip';

  @override
  String get soloRecommendedPlans => 'Recommended Plans';

  @override
  String get soloPersonalised => 'Personalised based on your travel history';

  @override
  String get soloBestForYou => 'Best for you';

  @override
  String get soloStatusActive => 'Active';

  @override
  String get soloStatusSaved => 'Saved';

  @override
  String get soloStatusCompleted => 'Completed';

  @override
  String get soloTabAll => 'All';

  @override
  String get soloCouldNotLoadPlans => 'Could not load plans';

  @override
  String get soloContinueTour => 'Continue Tour';

  @override
  String get soloStartTour => 'Start Tour';

  @override
  String get soloCouldNotStart => 'Could not start tour. Try again.';

  @override
  String get soloDeletePlanTitle => 'Delete plan?';

  @override
  String get soloDeleteActiveBody =>
      'This tour is in progress. Deleting it will discard all your progress and cannot be undone.';

  @override
  String get soloDeleteBody => 'This cannot be undone.';

  @override
  String get soloNoPlansYet => 'No plans yet';

  @override
  String get soloNoPlansSub =>
      'Save a curated trip or create your own\nto see it here.';

  @override
  String get soloBrowseTrips => 'Browse Trips';

  @override
  String get soloCustomizeOwnPlan => 'Customize your\nown plan';

  @override
  String get soloSavePlan => 'Save Plan';

  @override
  String get soloPlanSaved => 'Plan saved! Find it in My Plans.';

  @override
  String get soloCouldNotSave => 'Could not save plan. Try again.';

  @override
  String get soloHearStory => 'Hear the Story';

  @override
  String get soloStorySilent => 'The spirits of history are silent right now.';

  @override
  String get soloStoryPause => 'Pause';

  @override
  String get soloStoryResume => 'Resume';

  @override
  String get soloStoryListen => 'Listen';

  @override
  String get soloStoryGenerating => 'Generating audio…';

  @override
  String get soloStoryReplay => 'Replay from start';

  @override
  String get soloNavigateHere => 'Navigate here';

  @override
  String get soloViewFullRoute => 'View full route';

  @override
  String get soloViewFullRouteMap => 'View full route on map';

  @override
  String get soloFullRoute => 'Full route';

  @override
  String get soloHighlights => 'Highlights';

  @override
  String get soloItinerary => 'Itinerary';

  @override
  String get tourEndTitle => 'End Tour?';

  @override
  String get tourEndBody =>
      'This will mark the tour as completed. You can still view it in My Plans.';

  @override
  String get tourEndConfirm => 'End Tour';

  @override
  String get tourEnded => 'Tour ended. Find it under Completed in My Plans.';

  @override
  String get tourInProgress => 'Tour in Progress';

  @override
  String get tourGo => 'Go';

  @override
  String get tourUpNext => 'Up next';

  @override
  String get tourComplete => 'Tour Complete!';

  @override
  String tourStopsExplored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops explored',
      one: '1 stop explored',
    );
    return '$_temp0';
  }

  @override
  String get tourCompleteSub =>
      'You\'ve experienced the heart of Egypt.\nGreat exploring! 🌟';

  @override
  String get tourYouMightLove => 'You might also love';

  @override
  String get tourDone => 'Done';

  @override
  String get tourStartedTitle => '🗺️ Your Tour Has Started!';

  @override
  String get tourOnboardTitle => 'Here\'s what you can do';

  @override
  String get tourLetsGo => 'Let\'s Go!';

  @override
  String get tourFeatViewMap => 'View on Map';

  @override
  String get tourFeatViewMapDesc =>
      'Tap the map icon (top-right) to see your stops on the map and navigate to any one.';

  @override
  String get tourFeatTrack => 'Track Progress';

  @override
  String get tourFeatTrackDesc =>
      'Check off each stop as you visit it. Your progress saves automatically.';

  @override
  String get tourFeatStories => 'AI Stories';

  @override
  String get tourFeatStoriesDesc =>
      'Expand any stop and tap \"Hear the Story\" for an AI-generated history of that place.';

  @override
  String get resultCouldNotGenerate => 'Could not generate your plan.';

  @override
  String get resultPlanning => 'Planning your trip…';

  @override
  String get resultPlanningSub =>
      'Our AI guide is building a personalised day-by-day itinerary for you.';

  @override
  String get resultCouldNotLoad => 'Couldn\'t load your plan';

  @override
  String resultCouldNotPin(String name) {
    return 'Couldn\'t pin $name on the map yet. Try again in a moment.';
  }

  @override
  String get resultCouldNotExport => 'Could not export itinerary. Try again.';

  @override
  String get resultDiscardTitle => 'Discard plan?';

  @override
  String get resultDiscardBody =>
      'This plan will not be saved. You can always generate a new one.';

  @override
  String get resultKeep => 'Keep';

  @override
  String get resultDiscard => 'Discard';

  @override
  String get resultExportPdf => 'Export PDF';

  @override
  String resultLocationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count locations',
      one: '1 location',
    );
    return '$_temp0';
  }

  @override
  String resultDayNum(int num) {
    return 'Day $num';
  }

  @override
  String get resultViewOnMaps => 'View on Maps';

  @override
  String get resultShareSuffix => 'Planned with Lost in Egypt 🌍';

  @override
  String get quizNext => 'Next';

  @override
  String get quizFinish => 'Finish';

  @override
  String quizStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get soloQuizInterestsTitle => 'What are your interests?';

  @override
  String get soloQuizAreasTitle => 'Where do you want to explore?';

  @override
  String get soloQuizTripTimeTitle => 'Day trips or night out?';

  @override
  String get tripTimeDay => 'Day';

  @override
  String get tripTimeDayDesc => 'Temples, markets,\nand outdoor adventures';

  @override
  String get tripTimeNight => 'Night';

  @override
  String get tripTimeNightDesc => 'Dining, nightlife,\nand entertainment';

  @override
  String get soloQuizBudgetTitle => 'What\'s your budget?';

  @override
  String get budgetPresetBudget => 'Budget';

  @override
  String get budgetPresetMid => 'Mid-range';

  @override
  String get budgetPresetLuxury => 'Luxury';

  @override
  String get soloQuizDateTitle => 'Choose your dates & location';

  @override
  String get soloDateFrom => 'From';

  @override
  String get soloDateStartHint => 'Start date';

  @override
  String get soloDateTo => 'To';

  @override
  String get soloDateEndHint => 'End date';

  @override
  String soloNightsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nights',
      one: '1 night',
    );
    return '$_temp0';
  }

  @override
  String get soloStartLocationHint => 'Where are you starting from?';

  @override
  String get soloSelectDayNight => 'Please select Day, Night, or both.';

  @override
  String tourCardUpTo(int count) {
    return 'Up to $count';
  }

  @override
  String get tourCardNew => 'NEW';

  @override
  String get mapPickerFetching => 'Fetching address...';

  @override
  String get mapPickerSelectedLocation => 'Selected Location';

  @override
  String get mapPickerUnknownLocation => 'Unknown Location';

  @override
  String get mapPickerSearchHint => 'Search for a landmark or destination...';

  @override
  String get mapPickerTapHint => 'Tap anywhere on the map to select a location';

  @override
  String get mapPickerConfirm => 'Confirm Location';

  @override
  String get mapPickerCustomPin => 'Custom Pin Location';

  @override
  String get tourMapMeetupTitle => 'Meetup Location';

  @override
  String get tourMapStartPoint => 'Tour Start Point';

  @override
  String get tourMapMeetingPoint => 'Meeting Point';

  @override
  String get tourMapDestinations => 'Destinations You Will Visit:';

  @override
  String get tourMapExplore => 'Explore in Main Map';

  @override
  String get tourMapNavigateRoute => 'Navigate Tour Route';

  @override
  String get qrTitle => 'Scan Ticket QR';

  @override
  String get qrPointCamera => 'Point camera at tourist\'s QR ticket';

  @override
  String get qrScanAnother => 'Scan Another';

  @override
  String get qrBookingNotFound => 'Booking not found';

  @override
  String get qrUnknownTour => 'Unknown Tour';

  @override
  String get qrUnknownTraveler => 'Unknown Traveler';

  @override
  String get qrValidTicket => 'Valid Ticket';

  @override
  String qrInvalidTicket(String status) {
    return 'Invalid Ticket ($status)';
  }

  @override
  String get qrAllCheckedIn => 'All Tickets Checked In';

  @override
  String qrPartiallyCheckedIn(int checked, int total) {
    return 'Partially Checked In ($checked/$total)';
  }

  @override
  String get qrRowTour => 'Tour';

  @override
  String get qrRowDate => 'Date';

  @override
  String get qrRowTickets => 'Tickets';

  @override
  String get qrRowAmount => 'Amount';

  @override
  String get qrRowBookingId => 'Booking ID';

  @override
  String qrTicketsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets',
      one: '1 ticket',
    );
    return '$_temp0';
  }

  @override
  String qrCheckedInCount(int count) {
    return '$count checked in';
  }

  @override
  String get qrCheckInHowMany => 'Check in how many?';

  @override
  String get qrCheckInTourist => 'Check In Tourist';

  @override
  String qrCheckInRemaining(int count, int remaining) {
    return 'Check In $count of $remaining Remaining';
  }

  @override
  String qrAllTicketsCheckedIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'All $count tickets checked in!',
      one: 'Ticket checked in!',
    );
    return '$_temp0';
  }

  @override
  String qrCheckedInResult(int count, int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets checked in.',
      one: '1 ticket checked in.',
    );
    return '$_temp0\n$remaining remaining.';
  }

  @override
  String get commonNo => 'No';

  @override
  String get attendeesTitle => 'Attendees';

  @override
  String get attendeesError => 'Error loading attendees';

  @override
  String get attendeesIndexHint =>
      'A Firestore index may be needed.\nCheck debug console for the link.';

  @override
  String get attendeesEmpty => 'No bookings yet';

  @override
  String get attendeesEmptySub =>
      'When travelers book this tour,\nthey\'ll appear here.';

  @override
  String get attendeesStatConfirmed => 'Confirmed';

  @override
  String get attendeesStatCancelled => 'Cancelled';

  @override
  String get attendeesStatTotal => 'Total';

  @override
  String attendeesSectionConfirmed(int count) {
    return 'Confirmed ($count)';
  }

  @override
  String attendeesSectionCancelled(int count) {
    return 'Cancelled ($count)';
  }

  @override
  String get attendeesUnknownUser => 'Unknown User';

  @override
  String get attendeesPaid => 'PAID';

  @override
  String get attendeesPending => 'PENDING';

  @override
  String get attendeesCall => 'Call';

  @override
  String get attendeesWhatsApp => 'WhatsApp';

  @override
  String get attendeesEmail => 'Email';

  @override
  String get attendeesCancelBooking => 'Cancel Booking';

  @override
  String get attendeesCancelBody =>
      'Are you sure you want to cancel this booking? The traveler will be notified.';

  @override
  String get guideDashTitle => 'Guide Dashboard';

  @override
  String get guideDashStopSharing => 'Stop sharing live location';

  @override
  String get guideDashShareLocation => 'Share live location with tourists';

  @override
  String get guideDashScanTicket => 'Scan Ticket';

  @override
  String get guideDashNoTours => 'No tours yet';

  @override
  String get guideDashCreateFirst => 'Create your first tour!';

  @override
  String guideDashYourTours(int count) {
    return 'Your Tours ($count)';
  }

  @override
  String get guideDashCreateTour => 'Create Tour';

  @override
  String get guideDashEarningsError =>
      'Could not load earnings.\nCheck your connection and try again.';

  @override
  String get guideDashStatTours => 'Tours';

  @override
  String get guideDashStatBookings => 'Bookings';

  @override
  String get guideDashStatRevenue => 'Revenue';

  @override
  String guideDashMax(int count) {
    return '$count max';
  }

  @override
  String get guideDashBookingsError => 'Could not load bookings.';

  @override
  String guideDashConfirmedBookings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count confirmed bookings',
      one: '1 confirmed booking',
    );
    return '📌 $_temp0';
  }

  @override
  String get guideDashView => 'View';

  @override
  String get guideDashDeleteTitle => 'Delete Tour';

  @override
  String guideDashDeleteBody(String title) {
    return 'Are you sure you want to delete \"$title\"? This cannot be undone.';
  }

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get createEditTitle => 'Edit Tour';

  @override
  String get createNewTitle => 'Create New Tour';

  @override
  String get createUpdatedToast => 'Tour updated!';

  @override
  String get createCreatedToast => 'Tour created successfully!';

  @override
  String get createRequired => 'Required';

  @override
  String get createFieldTitle => 'Tour Title';

  @override
  String get createFieldDesc => 'Description';

  @override
  String get createDestinationsLabel => 'Destinations (Max 5)';

  @override
  String get createSearchDestination => 'Search destination...';

  @override
  String get createFieldPrice => 'Price (EGP)';

  @override
  String get createFieldMaxAttendees => 'Max Attendees';

  @override
  String get createMeetingLocation => 'Meeting Location';

  @override
  String get createSelectMeetingLocation => 'Select Meeting Location';

  @override
  String get createSelectMeetingTime => 'Select Meeting Time';

  @override
  String createMeetingTimePrefix(String time) {
    return 'Meeting Time: $time';
  }

  @override
  String get createScheduleFreq => 'Schedule Frequency (Days)';

  @override
  String get createImages => 'Tour Images';

  @override
  String get createEditImages => 'Edit Tour Images';

  @override
  String get createSaveChanges => 'Save Changes';

  @override
  String get createSelectTime => 'Please select a meeting time.';

  @override
  String get createSelectImage => 'Please select at least one image.';

  @override
  String get createSelectLocation =>
      'Please select a meeting location on the map.';

  @override
  String get createAddDestination => 'Please add at least one destination.';

  @override
  String get createPriceNegative => 'Price cannot be negative.';

  @override
  String get createAttendeesZero => 'Max attendees must be greater than zero.';

  @override
  String get toursDiscoverTitle => 'Discover Tours';

  @override
  String get toursSearchHint => 'Search destinations, guides...';

  @override
  String get toursFilters => 'Filters';

  @override
  String get toursPriceRange => 'Price Range';

  @override
  String get toursMinRating => 'Minimum Rating';

  @override
  String toursStarsPlus(int count) {
    return '$count+ stars';
  }

  @override
  String get toursFrequency => 'Frequency';

  @override
  String get toursFreqDaily => 'Daily';

  @override
  String get toursFreqWeekly => 'Weekly';

  @override
  String get toursFreqWeekends => 'Weekends';

  @override
  String get toursFreqOneTime => 'One-Time';

  @override
  String get toursApplyFilters => 'Apply Filters';

  @override
  String get toursSortNewest => 'Newest First';

  @override
  String get toursSortCheapest => 'Cheapest First';

  @override
  String get toursSortPriciest => 'Priciest First';

  @override
  String get toursSortHighestRated => 'Highest Rated';

  @override
  String get toursSortMostPopular => 'Most Popular';

  @override
  String get toursSortLabelNewest => 'Newest';

  @override
  String get toursSortLabelCheapest => 'Cheapest';

  @override
  String get toursSortLabelPriciest => 'Priciest';

  @override
  String get toursSortLabelTopRated => 'Top Rated';

  @override
  String get toursSortLabelPopular => 'Popular';

  @override
  String toursFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tours found',
      one: '1 tour found',
    );
    return '$_temp0';
  }

  @override
  String get toursLoadError =>
      'Could not load tours.\nCheck your connection and try again.';

  @override
  String get toursEmptyTitle => 'No tours found';

  @override
  String get toursEmptyFilters => 'Try adjusting your filters.';

  @override
  String get toursEmptySearch => 'Try adjusting your search query.';

  @override
  String get toursClearFilters => 'Clear All Filters';

  @override
  String get toursRecommended => 'Recommended for You';

  @override
  String get bookingCheckoutTitle => 'Checkout';

  @override
  String get bookingLoginRequired => 'Please log in to book.';

  @override
  String get bookingInvalidWallet =>
      'Please enter a valid Egyptian mobile number (e.g. 01XXXXXXXXX).';

  @override
  String get bookingFullyBooked => 'Sorry, this tour is now fully booked.';

  @override
  String bookingSeatsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Only $count seats remaining. Please reduce your selection.',
      one: 'Only 1 seat remaining. Please reduce your selection.',
    );
    return '$_temp0';
  }

  @override
  String get bookingPaymentFailed => 'Payment was cancelled or failed.';

  @override
  String get bookingWalletFailed => 'Wallet payment failed.';

  @override
  String get bookingKioskSoon => 'Kiosk payment coming soon!';

  @override
  String bookingErrorPrefix(String message) {
    return 'Booking Error: $message';
  }

  @override
  String get bookingConfirmedTitle => 'Booking Confirmed!';

  @override
  String bookingReservedBody(String title) {
    return 'Your spot on \"$title\" is reserved!';
  }

  @override
  String bookingPaidSuccess(String amount) {
    return '$amount paid successfully.';
  }

  @override
  String get bookingViewMyBookings => 'View My Bookings';

  @override
  String get bookingBackHome => 'Back to Home';

  @override
  String get bookingOrderSummary => 'Order Summary';

  @override
  String get bookingGuests => 'Guests';

  @override
  String get bookingPaymentMethod => 'Payment Method';

  @override
  String get bookingPayCardTitle => 'Credit / Debit Card';

  @override
  String get bookingPayCardSub => 'Visa, Mastercard, Meeza';

  @override
  String get bookingPayWalletTitle => 'Mobile Wallet';

  @override
  String get bookingPayWalletSub => 'Vodafone Cash, Orange, Etisalat';

  @override
  String get bookingPayApplePayTitle => 'Apple Pay';

  @override
  String get bookingPayApplePaySub => 'iOS only • Coming soon';

  @override
  String get bookingPayKioskTitle => 'Fawry / Kiosk';

  @override
  String get bookingPayKioskSub => 'Pay at any 172,000+ Fawry outlets';

  @override
  String get bookingWalletPhoneLabel => 'Wallet Phone Number';

  @override
  String get bookingSecurityNote =>
      'Payments are processed securely by Paymob. Your card details are never stored locally.';

  @override
  String get bookingBecauseBooked => 'Because you booked this, you might enjoy';

  @override
  String get bookingProcessing => 'Processing payment...';

  @override
  String get bookingTotal => 'Total';

  @override
  String bookingChargedNote(String amount) {
    return 'Charged as EGP $amount via Paymob';
  }

  @override
  String get bookingPaySecurely => 'Pay Securely';

  @override
  String get tourDetailReport => 'Report Tour';

  @override
  String get tourDetailNew => 'New';

  @override
  String get tourDetailDateTime => 'Date & Time';

  @override
  String tourDetailPeople(int count) {
    return '$count people';
  }

  @override
  String get tourDetailLocation => 'Location';

  @override
  String get tourDetailAbout => 'About This Tour';

  @override
  String get tourDetailDestinations => 'Destinations';

  @override
  String get tourDetailMeetupRoute => 'Meetup Location & Route';

  @override
  String get tourDetailTapExpand => 'Tap to expand';

  @override
  String get tourDetailSchedule => 'Schedule';

  @override
  String get tourDetailGallery => 'Gallery';

  @override
  String get tourDetailYourGuide => 'Your Guide';

  @override
  String get tourDetailYouMightEnjoy => 'You might also enjoy';

  @override
  String get tourDetailYourTour => 'This is your tour';

  @override
  String get tourDetailBookNow => 'Book Now';

  @override
  String get tourDetailOneTime => 'This is a one-time tour.';

  @override
  String get tourDetailGuideNotFound => 'Guide not found';

  @override
  String tourDetailGuideRating(String rating, int count) {
    return '$rating ($count reviews)';
  }

  @override
  String get tourDetailReviews => 'Reviews';

  @override
  String get tourDetailWriteReview => 'Write a Review';

  @override
  String get tourDetailReviewsError => 'Error loading reviews';

  @override
  String get tourDetailNoReviews => 'No reviews yet. Be the first to review!';

  @override
  String get tourDetailShowMore => 'Show more reviews';

  @override
  String get tourDetailAnonymous => 'Anonymous';

  @override
  String get tourDetailEditReview => 'Edit Review';

  @override
  String get tourDetailDeleteReview => 'Delete Review';

  @override
  String get tourDetailReportReview => 'Report Review';

  @override
  String get tourDetailUpdateHint => 'Update your experience...';

  @override
  String get tourDetailUpdate => 'Update';

  @override
  String get tourDetailDeleteReviewBody =>
      'Are you sure you want to delete your review? This action cannot be undone.';

  @override
  String get tourDetailShareHint => 'Share your experience...';

  @override
  String get tourDetailSubmit => 'Submit';

  @override
  String get commonLoadMore => 'Load more';

  @override
  String get bookingStatusConfirmed => 'CONFIRMED';

  @override
  String get bookingStatusCancelled => 'CANCELLED';

  @override
  String get bookingStatusPending => 'PENDING';

  @override
  String get bookingStatusCompleted => 'COMPLETED';

  @override
  String get bookingStatusCheckedIn => 'CHECKED IN';

  @override
  String get bookingStatusPartial => 'PARTIALLY CHECKED IN';

  @override
  String get bookingHistTitle => 'My Bookings';

  @override
  String get bookingHistLoginRequired => 'Please log in';

  @override
  String get bookingHistUpcoming => 'Upcoming';

  @override
  String get bookingHistPast => 'Past';

  @override
  String get bookingHistLoadError =>
      'Could not load bookings.\nCheck your connection and try again.';

  @override
  String get bookingHistNoUpcoming => 'No upcoming tours';

  @override
  String get bookingHistNoPast => 'No past tours';

  @override
  String get bookingHistEmptyHint =>
      'Explore tours and book your next adventure!';

  @override
  String get bookingHistTbd => 'TBD';

  @override
  String bookingHistCountdownDHM(int days, int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0 ${hours}h ${minutes}m';
  }

  @override
  String bookingHistCountdownHMS(int hours, int minutes, int seconds) {
    return '${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String bookingHistCountdownMS(int minutes, int seconds) {
    return '${minutes}m ${seconds}s';
  }

  @override
  String bookingHistStartsIn(String time) {
    return 'Starts in $time';
  }

  @override
  String get bookingHistCancelBody =>
      'Are you sure you want to cancel this booking?';

  @override
  String get bookingHistYesCancel => 'Yes, Cancel';

  @override
  String get bookingHistCancelled => 'Booking cancelled';

  @override
  String get bookingHistReviewSubmitted => 'Review submitted!';

  @override
  String get bookingHistNoPhone => 'No phone number on file';

  @override
  String get bookingHistNoEmail => 'No email on file';

  @override
  String get bookingHistCantOpenPhone => 'Could not open phone app';

  @override
  String get bookingHistCantOpenEmail => 'Could not open email app';

  @override
  String get bookingHistLeaveReview => 'Leave a Review';

  @override
  String get bookingHistSubmitReview => 'Submit Review';

  @override
  String get bookingHistViewQr => 'View QR Ticket';

  @override
  String bookingHistBookingId(String id) {
    return 'Booking ID: $id';
  }

  @override
  String get bookingHistShowGuide => 'Show this to your guide upon arrival';

  @override
  String get bookingHistViewMeeting => 'View Meeting Point';

  @override
  String get bookingHistOpensMap => 'Opens in Map tab';

  @override
  String get bookingHistGuide => 'Guide';

  @override
  String get bookingHistTrackGuide => 'Track Guide Live';

  @override
  String get bookingHistTrackGuideSub => 'See your guide\'s real-time location';

  @override
  String get bookingHistTotalPaid => 'Total paid';

  @override
  String get bookingHistPaymentRef => 'Payment ref';

  @override
  String get bookingHistAddCalendar => 'Add to Calendar';

  @override
  String get bookingHistShareTicket => 'Share Ticket';

  @override
  String get bookingHistCallGuide => 'Call Guide';

  @override
  String get bookingHistEmailGuide => 'Email Guide';

  @override
  String get bookingHistRebook => 'Re-book This Tour';

  @override
  String get bookingHistNewGuide => 'New Guide';

  @override
  String get bookingHistWeatherDay => 'Weather on tour day';

  @override
  String bookingHistLiveLocation(String name) {
    return '$name – Live Location';
  }

  @override
  String get bookingHistWaitingLocation =>
      'Waiting for guide to share their location…';

  @override
  String bookingHistCalTitle(String title) {
    return 'Lost in Egypt: $title';
  }

  @override
  String bookingHistCalDesc(String location, String id) {
    return 'Meeting point: $location\nBooking ID: $id';
  }

  @override
  String bookingHistShareText(
    String title,
    String date,
    String location,
    int tickets,
    String ref,
  ) {
    return '🏺 Lost in Egypt – Tour Ticket\n\nTour: $title\nDate: $date\nMeeting point: $location\nTickets: $tickets\nBooking ref: $ref\n\nSee you there!';
  }

  @override
  String get cameraLens => 'Lens';

  @override
  String get cameraTranslation => 'Translation';

  @override
  String get cameraTranslationResult => 'Translation Result';

  @override
  String get cameraNoLandmark => 'Could not identify any landmark';

  @override
  String cameraNotInDb(String label) {
    return 'We found \"$label\" but it\'s not in our database';
  }

  @override
  String get cameraConfigError => 'Configuration Error';

  @override
  String get cameraErrorTitle => 'Error';

  @override
  String get cameraLandmarkIdentified => 'Landmark Identified';

  @override
  String cameraTapForecast(String condition) {
    return '$condition · Tap for forecast';
  }

  @override
  String get cameraStatusCapturing => 'Capturing...';

  @override
  String get cameraStatusIdentifying => 'Identifying landmark...';

  @override
  String get cameraStatusTranslating => 'Translating...';

  @override
  String cameraStatusDownloadingModel(String lang) {
    return 'Downloading $lang model (this may take a minute)...';
  }

  @override
  String get cameraErrNoCameras => 'No cameras available on this device';

  @override
  String get cameraErrInitFailed =>
      'Failed to initialize camera. Please restart the app.';

  @override
  String get cameraErrTranslationModels =>
      'Could not download translation models. Please check your internet connection.';

  @override
  String get cameraErrLanguageModel =>
      'Failed to download language model. Please check your internet connection.';

  @override
  String get cameraErrNoText => 'No text found in the selected image.';

  @override
  String get cameraReadMore => 'Read More';

  @override
  String get cameraReadLess => 'Read Less';

  @override
  String get cameraTellStory => 'Tell me a story';

  @override
  String get cameraConsulting => 'Consulting history...';

  @override
  String get cameraListen => 'Listen';

  @override
  String get cameraPause => 'Pause';

  @override
  String get cameraResume => 'Resume';

  @override
  String get cameraGenerating => 'Generating...';

  @override
  String get cameraReplay => 'Replay from start';

  @override
  String get cameraAudioGenFailed =>
      'Could not generate audio. Please try again.';

  @override
  String get cameraAudioPlayFailed =>
      'Audio playback failed. Please try again.';

  @override
  String get cameraShowOnMap => 'Show on Map';

  @override
  String get cameraDone => 'Done';

  @override
  String get cameraNearby => 'You might also like nearby';

  @override
  String get sphinxRiddleTitle => 'The Sphinx\'s Riddle 🦁';

  @override
  String get sphinxPassTitle => 'You May Pass 🦁';

  @override
  String get sphinxFailTitle => 'Incorrect, Mortal 🌪️';

  @override
  String get sphinxRiddleBody =>
      '\"What walks on four legs in the morning, two at noon, and three in the evening?\"';

  @override
  String get sphinxPassBody =>
      'Your wisdom equals the ancients. The Sphinx permits your journey to continue.';

  @override
  String get sphinxFailBody =>
      'The sands of time will swallow your ignorance. Return when you have learned.';

  @override
  String get sphinxAnswerAnimal => 'An Animal';

  @override
  String get sphinxAnswerHuman => 'A Human';

  @override
  String get tripPlannerTitle => 'Trip Planner';

  @override
  String get tripPlannerStart => 'Start Trip';

  @override
  String get tripPlannerOptimising => 'Optimising...';

  @override
  String get tripPlannerSearchHint => 'Search places to add…';

  @override
  String tripPlannerStopsInfo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops — route will be optimised by shortest distance',
      one: '1 stop — route will be optimised by shortest distance',
    );
    return '$_temp0';
  }

  @override
  String get tripPlannerEmptyTitle => 'Plan your day in Egypt';

  @override
  String get tripPlannerEmptySub =>
      'Search above or pick from suggestions below';

  @override
  String get tripPlannerSuggested => 'Suggested for you';

  @override
  String get tripPlannerAdd => 'Add';

  @override
  String get placeDetailLoginToSave => 'You must be logged in to save places.';

  @override
  String placeDetailMetersAway(int meters) {
    return '$meters m away';
  }

  @override
  String placeDetailKmAway(String km) {
    return '$km km away';
  }

  @override
  String placeDetailTaxiFare(int low, int high) {
    return '~$low–$high EGP by taxi';
  }

  @override
  String get placeDetailOpenNow => 'Open Now';

  @override
  String get placeDetailClosed => 'Closed';

  @override
  String get placeDetailClose => 'Close';

  @override
  String get placeDetailDirections => 'Directions';

  @override
  String get placeDetailShare => 'Share';

  @override
  String get placeDetailSaved => 'Saved';

  @override
  String get placeDetailAbout => 'About';

  @override
  String get placeDetailDefaultDesc =>
      'Explore the ancient wonders and hidden gems of Egypt. This location offers a unique glimpse into the rich history and culture of the region.';

  @override
  String placeDetailEntryFee(String price) {
    return '$price EGP Entry Fee';
  }

  @override
  String get placeDetailReviews => 'What Travelers Say';

  @override
  String placeDetailPostedHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count travelers posted from here',
      one: '1 traveler posted from here',
    );
    return '$_temp0';
  }

  @override
  String get placeDetailSeePosts => 'See Posts';

  @override
  String get placeDetailSimilar => 'Similar Places';

  @override
  String get placeDetailCrowdQuiet => 'Quiet right now';

  @override
  String get placeDetailCrowdModerate => 'Moderately busy';

  @override
  String get placeDetailCrowdBusy => 'Very busy';

  @override
  String placeDetailPostsFrom(String name) {
    return 'Posts from $name';
  }

  @override
  String get placeDetailNoPosts =>
      'No posts yet from this place.\nBe the first to share!';

  @override
  String get mapDiscovering => 'Discovering Egypt...';

  @override
  String get mapLoadingNearby => 'Loading places near you';

  @override
  String get mapArrivedTitle => 'You\'ve Arrived!';

  @override
  String mapArrivedBody(String name) {
    return 'You have arrived at $name';
  }

  @override
  String get mapFabTrip => 'Trip';

  @override
  String get mapFabNearMe => 'Near Me';

  @override
  String get mapFabSaved => 'Saved';

  @override
  String mapStopOf(int current, int total) {
    return 'Stop $current of $total';
  }

  @override
  String get mapNextStop => 'Next Stop';

  @override
  String get mapTripDone => 'Done! 🎉';

  @override
  String get mapBackToTour => 'Back to Tour';

  @override
  String get mapFindingRoute => 'Finding route...';

  @override
  String mapEtaTotal(String distance, String duration) {
    return '$distance · $duration total';
  }

  @override
  String mapStepProgress(int current, int total) {
    return 'Step $current/$total';
  }

  @override
  String get mapAiPick => 'AI PICK';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get mapSearchHint => 'Search places...';

  @override
  String get mapNoPlacesFound => 'No places found';

  @override
  String get mapModeDrive => 'Drive';

  @override
  String get mapModeWalk => 'Walk';

  @override
  String get mapModeTransit => 'Transit';

  @override
  String mapStepsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count steps',
      one: '1 step',
    );
    return '$_temp0';
  }

  @override
  String get mapStartNavigation => 'Start Navigation';

  @override
  String get mapRouteSteps => 'Route Steps';

  @override
  String get mapArriveDestination => 'Arrive at destination';

  @override
  String get mapCurseReleased => 'CURSE RELEASED';

  @override
  String get mapFilterByCategory => 'Filter by Category';

  @override
  String get mapZoomFilterOn => 'Zoom Filter ON';

  @override
  String get mapShowingAll => 'Showing All';

  @override
  String mapPlacesCount(int visible, int total) {
    return '$visible/$total places';
  }

  @override
  String mapCatPlacesZoom(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places • Zoom to see more',
      one: '1 place • Zoom to see more',
    );
    return '$_temp0';
  }

  @override
  String mapCatSavedPlaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saved places',
      one: '1 saved place',
    );
    return '$_temp0';
  }

  @override
  String mapCatPlaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return '$_temp0';
  }

  @override
  String get mapCatAll => 'All';

  @override
  String get mapCatFavorites => 'Favorites';

  @override
  String get mapCatOpenNow => 'Open Now';

  @override
  String get mapCatTourism => 'Tourism';

  @override
  String get mapCatHistorical => 'Historical';

  @override
  String get mapCatMuseums => 'Museums';

  @override
  String get mapCatHotels => 'Hotels';

  @override
  String get mapCatReligious => 'Religious';

  @override
  String get mapCatFood => 'Food & Dining';

  @override
  String get mapCatNature => 'Nature';

  @override
  String get mapCatEntertainment => 'Entertainment';

  @override
  String get mapCatShopping => 'Shopping';

  @override
  String get accountMenuMyAccount => 'My Account';

  @override
  String get accountMenuGuideDashboard => 'Guide Dashboard';

  @override
  String get accountMenuAdminDashboard => 'Admin Dashboard';

  @override
  String get accountMenuNotifications => 'Notification Centre';

  @override
  String get accountMenuSignOut => 'Sign Out';

  @override
  String get homeCatHotels => 'Hotels';

  @override
  String get homeCatMuseums => 'Museums';

  @override
  String get homeCatRestaurants => 'Restaurants';

  @override
  String get homeCatMosques => 'Mosques';

  @override
  String get homeCatBeaches => 'Beaches';

  @override
  String get homeCatAdventure => 'Adventure';

  @override
  String get catSort => 'Sort';

  @override
  String get catSortNameAsc => 'Name (A → Z)';

  @override
  String get catSortNameDesc => 'Name (Z → A)';

  @override
  String get catSortTopRated => 'Top Rated';

  @override
  String get catSortMostReviews => 'Most Reviews';

  @override
  String get catSortNearest => 'Nearest';

  @override
  String get catSomethingWrong => 'Something went wrong.';

  @override
  String get catNoRating => 'N/A';

  @override
  String catReviewsK(String count) {
    return '${count}k reviews';
  }

  @override
  String catReviews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String get eventCatAll => 'All';

  @override
  String get eventCatCultural => 'Cultural & Heritage';

  @override
  String get eventCatConcert => 'Concerts & Music';

  @override
  String get eventCatTheatre => 'Theatre & Performance';

  @override
  String get eventCatFestival => 'Festivals';

  @override
  String get eventCatArt => 'Art & Exhibitions';

  @override
  String get eventCatAdventure => 'Adventure & Outdoors';

  @override
  String get eventCatFood => 'Food & Markets';

  @override
  String get eventCatCruise => 'Cruise & Dining';

  @override
  String get eventsLoadError =>
      'Could not load events.\nCheck your connection and try again.';

  @override
  String get eventsEmptyTitle => 'No events right now';

  @override
  String get eventsEmptySubtitle =>
      'Check back soon for upcoming events in Egypt.';

  @override
  String get eventTailoredPick => 'Tailored pick';

  @override
  String get eventDateTime => 'DATE & TIME';

  @override
  String get eventLocation => 'LOCATION';

  @override
  String eventCairoTime(String time) {
    return '$time (Cairo Time)';
  }

  @override
  String get eventLocationEgypt => 'Egypt';

  @override
  String get eventMapButton => 'Map';

  @override
  String get eventAbout => 'About this Event';

  @override
  String get eventDefaultDescription =>
      'Join us for an unforgettable experience! This event brings together the best of culture, entertainment, and community in Egypt. Secure your tickets now and be part of something amazing.';

  @override
  String get eventShareThis => 'Share this event';

  @override
  String eventViewOn(String source) {
    return 'View on $source';
  }

  @override
  String eventPostPrompt(String title) {
    return 'Anyone going to $title? ✨';
  }

  @override
  String get eventPostToCommunity => 'Post to Community';

  @override
  String get eventPrice => 'Price';

  @override
  String get eventSeeListing => 'See Listing';

  @override
  String get eventTicketsUnavailable =>
      'Tickets are not available online for this event.';

  @override
  String get eventGetTickets => 'Get Tickets';

  @override
  String get eventRsvpNow => 'RSVP Now';

  @override
  String get eventReviewerFallback => 'Explorer';

  @override
  String get searchHint => 'Search landmarks, tours, destinations…';

  @override
  String get searchTabAll => 'All';

  @override
  String get searchTabPlaces => 'Places';

  @override
  String get searchTabTours => 'Tours';

  @override
  String get searchPersonalised => 'Personalised by your taste';

  @override
  String get searchBadgeLandmark => 'Landmark';

  @override
  String get searchBadgeTour => 'Tour';

  @override
  String get searchViewOnMap => 'View on map';

  @override
  String get searchEmptyTitle => 'Search for a landmark or tour';

  @override
  String get searchEmptyHint => 'Try \"Pyramids\", \"Luxor\", \"museum\"…';

  @override
  String searchNoResultsFor(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get searchPlacesError =>
      'Could not load places.\nCheck your connection.';

  @override
  String get searchToursError =>
      'Could not load tours.\nCheck your connection.';

  @override
  String get guidesSearchToursHint => 'Search tours...';

  @override
  String get guidesSearchGuidesHint => 'Search guides...';

  @override
  String get guidesTabTours => 'Tours';

  @override
  String get guidesTabGuides => 'Guides';

  @override
  String get guidesEmptyGuidesTitle => 'No guides found';

  @override
  String get guidesEmptyHint => 'Try adjusting your search query or filters.';

  @override
  String get guidesErrorTours => 'Error loading tours.';

  @override
  String get guidesErrorGuides => 'Error loading guides.';

  @override
  String get guidesNoneAvailable => 'No guides available.';

  @override
  String get communityFilterAll => 'All';

  @override
  String get communityFilterTips => '💡 Tips';

  @override
  String get soloInterestShopping => 'Shopping';

  @override
  String get soloInterestNightlife => 'Nightlife';

  @override
  String get soloInterestMonuments => 'Monuments';

  @override
  String get soloInterestMuseums => 'Museums';

  @override
  String get soloInterestNature => 'Nature & Parks';

  @override
  String get soloInterestBeaches => 'Beaches';

  @override
  String get soloInterestCulture => 'Culture & Traditions';

  @override
  String get soloInterestEntertainment => 'Entertainment';

  @override
  String get soloInterestAdventure => 'Adventure Activities';

  @override
  String get soloInterestLocal => 'Local Experiences';

  @override
  String get soloAreaCairo => 'Cairo';

  @override
  String get soloAreaLuxor => 'Luxor';

  @override
  String get soloAreaAswan => 'Aswan';

  @override
  String get soloAreaAlexandria => 'Alexandria';

  @override
  String get soloAreaHurghada => 'Hurghada';

  @override
  String get soloAreaSharm => 'Sharm El-Sheikh';

  @override
  String get soloAreaDahab => 'Dahab';

  @override
  String get soloAreaSiwa => 'Siwa';

  @override
  String get soloAreaFayoum => 'Fayoum';

  @override
  String get soloAreaNorthCoast => 'North Coast';

  @override
  String soloPlanStopsProgress(int done, int total) {
    return '$done/$total stops';
  }

  @override
  String get mapEasterEggCurse =>
      'You dare awaken the Pharaoh... The curse is upon you.';

  @override
  String get mapEasterEggSandstorm => 'The desert consumes all.';

  @override
  String profilePlacesVisited(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Places Visited',
      one: '$count Place Visited',
    );
    return '$_temp0';
  }

  @override
  String get accountMyProfile => 'My Profile';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsCustomize => 'Customize your notifications!';

  @override
  String get notificationsPrevious => 'Previously';

  @override
  String get notificationsEmptyTitle => 'No notifications yet';

  @override
  String get notificationsEmptyBody =>
      'Your notifications will appear here once\nyou start getting them.';

  @override
  String get notificationsSettings => 'Notification Settings';

  @override
  String get commonDone => 'Done';

  @override
  String get notifPrefTitle => 'Notification Preferences';

  @override
  String get notifPrefSubtitle => 'Choose what you want to be notified about.';

  @override
  String get notifPrefAll => 'All Notifications';

  @override
  String get notifPrefAllSub => 'Master switch for all push alerts';

  @override
  String get notifPrefBookings => 'Bookings & Tours';

  @override
  String get notifPrefBookingsSub => 'Confirmations, cancellations, updates';

  @override
  String get notifPrefCommunity => 'Community';

  @override
  String get notifPrefCommunitySub => 'Likes, comments, mentions, replies';

  @override
  String get notifPrefReviews => 'Reviews';

  @override
  String get notifPrefReviewsSub => 'When someone reviews your tour';

  @override
  String get notifPrefGuide => 'Guide Updates';

  @override
  String get notifPrefGuideSub =>
      'Application & language certification results';

  @override
  String get notifPrefDiscovery => 'AI Discovery';

  @override
  String get notifPrefDiscoverySub =>
      'Daily \'Did you know?\' fact about Egypt';

  @override
  String get badgeNoviceExplorer => 'Novice Explorer';

  @override
  String get badgeNoviceExplorerDesc => 'Discovered your first landmark.';

  @override
  String get badgeTourist => 'Tourist';

  @override
  String get badgeTouristDesc => 'Visited 3 landmarks.';

  @override
  String get badgeTombRaider => 'Tomb Raider';

  @override
  String get badgeTombRaiderDesc => 'Visited 5 landmarks.';

  @override
  String get badgeHistorian => 'Historian';

  @override
  String get badgeHistorianDesc => 'Visited 10 landmarks.';

  @override
  String get badgePharaoh => 'Pharaoh';

  @override
  String get badgePharaohDesc => 'Visited 20 landmarks.';

  @override
  String get badgeImhotep => 'High Priest Imhotep';

  @override
  String get badgeImhotepDesc =>
      'You discovered the hidden vault of the architect.';

  @override
  String get badgeDeveloperPharaoh => 'Developer Pharaoh';

  @override
  String get badgeDeveloperPharaohDesc =>
      'Discovered the hidden developer tomb.';

  @override
  String get badgeRiddleSolver => 'Riddle Solver';

  @override
  String get badgeRiddleSolverDesc => 'You answered the Riddle of the Sphinx.';
}
