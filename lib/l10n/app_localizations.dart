import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ar'),
    Locale('en'),
  ];

  /// Application name.
  ///
  /// In en, this message translates to:
  /// **'Lost in Egypt'**
  String get appTitle;

  /// Bottom navigation tab label for the Home tab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation tab label for the Community tab.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// Bottom navigation tab label for the Map tab.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// Bottom navigation tab label for the Camera tab.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get navCamera;

  /// Bottom navigation tab label for the More tab.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// Generic Cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Generic Reset button.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;

  /// Generic retry button shown on error states.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// Generic dismiss/close tooltip.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get commonDismiss;

  /// Title of the report dialog when reporting a user or guide.
  ///
  /// In en, this message translates to:
  /// **'Report User'**
  String get reportUser;

  /// Title of the report dialog when reporting a tour.
  ///
  /// In en, this message translates to:
  /// **'Report Tour'**
  String get reportTour;

  /// Title of the report dialog when reporting a community post.
  ///
  /// In en, this message translates to:
  /// **'Report Post'**
  String get reportPost;

  /// Title of the report dialog when reporting a comment.
  ///
  /// In en, this message translates to:
  /// **'Report Comment'**
  String get reportComment;

  /// Prompt above the list of report reasons.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this?'**
  String get reportReasonPrompt;

  /// Hint text for the optional report description field.
  ///
  /// In en, this message translates to:
  /// **'Additional details (optional)'**
  String get reportAdditionalDetails;

  /// Button that submits a content report.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get reportSubmit;

  /// Error shown when an unauthenticated user tries to report.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to submit a report.'**
  String get reportMustBeLoggedIn;

  /// Validation error when no report reason is selected.
  ///
  /// In en, this message translates to:
  /// **'Please select a reason for reporting.'**
  String get reportSelectReason;

  /// Validation error when the report description exceeds 500 chars.
  ///
  /// In en, this message translates to:
  /// **'Description must be 500 characters or fewer.'**
  String get reportDescriptionTooLong;

  /// Confirmation snackbar after a report is submitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted successfully. Thank you.'**
  String get reportSuccess;

  /// Hint on the weather banner that opens the 7-day forecast.
  ///
  /// In en, this message translates to:
  /// **'Tap for 7-day forecast'**
  String get weatherTapForForecast;

  /// Subtitle under the current weather conditions card.
  ///
  /// In en, this message translates to:
  /// **'Egypt conditions right now'**
  String get weatherConditionsNow;

  /// Header above the 7-day forecast list.
  ///
  /// In en, this message translates to:
  /// **'7-Day Forecast'**
  String get weather7DayForecast;

  /// Title of the Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings tile to choose the app language.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get settingsSelectLanguage;

  /// Settings tile to choose the preferred display currency.
  ///
  /// In en, this message translates to:
  /// **'Display Currency'**
  String get settingsDisplayCurrency;

  /// Settings tile to toggle light/dark theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Name of the English language, shown in the language toggle.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Name of the Arabic language, shown in the language toggle (endonym).
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// Debug-only settings tile that clears earned badges.
  ///
  /// In en, this message translates to:
  /// **'Reset Badges (Debug)'**
  String get settingsResetBadges;

  /// Confirmation snackbar after badges are reset.
  ///
  /// In en, this message translates to:
  /// **'Badges successfully reset!'**
  String get settingsBadgesResetSuccess;

  /// Debug-only settings tile that clears recommendation signals.
  ///
  /// In en, this message translates to:
  /// **'Reset Taste Signals (Debug)'**
  String get settingsResetTasteSignals;

  /// Title of the confirmation dialog for resetting taste signals.
  ///
  /// In en, this message translates to:
  /// **'Reset Taste Signals?'**
  String get settingsResetTasteSignalsTitle;

  /// Body text of the reset-taste-signals confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'This clears every personalisation signal recorded for you — saved likes, dismissals, quiz answers, visit history. Recommendations will reset to defaults until you interact again.'**
  String get settingsResetTasteSignalsBody;

  /// Confirmation snackbar after taste signals are reset.
  ///
  /// In en, this message translates to:
  /// **'Taste signals reset.'**
  String get settingsTasteSignalsReset;

  /// Error snackbar when resetting taste signals fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reset signals. Try again.'**
  String get settingsTasteSignalsResetError;

  /// App version label at the bottom of the Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// Generic Continue button.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// Hint text for the email input field.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEmailHint;

  /// Hint text for the password input field.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordHint;

  /// Tagline under the logo on the login screen.
  ///
  /// In en, this message translates to:
  /// **'Log in to unlock your journey.'**
  String get loginTagline;

  /// Primary button on the login screen.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginButton;

  /// Link to the password reset screen.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get loginForgotPassword;

  /// Divider label above social sign-in buttons.
  ///
  /// In en, this message translates to:
  /// **'OR SIGN IN WITH'**
  String get loginOrSignInWith;

  /// Prompt next to the create-account link on login.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get loginNoAccount;

  /// Link to the account creation flow.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get loginCreateAccount;

  /// Validation error when login fields are empty.
  ///
  /// In en, this message translates to:
  /// **'Please fill in your email and password.'**
  String get loginFillEmailPassword;

  /// Notice shown when a guide with a pending application logs in.
  ///
  /// In en, this message translates to:
  /// **'Your guide application is pending approval.'**
  String get loginGuidePending;

  /// Validation error when the reset email field is empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get forgotEnterEmail;

  /// Confirmation snackbar after requesting a password reset.
  ///
  /// In en, this message translates to:
  /// **'If an account exists, a reset link was sent.'**
  String get forgotResetSent;

  /// Error when the reset email could not be sent.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email'**
  String get forgotFailedSend;

  /// Error when the entered email is malformed.
  ///
  /// In en, this message translates to:
  /// **'Invalid email formatting.'**
  String get forgotInvalidEmail;

  /// Title after a reset email has been sent.
  ///
  /// In en, this message translates to:
  /// **'Email Sent!'**
  String get forgotEmailSentTitle;

  /// Title of the password reset screen.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get forgotResetTitle;

  /// Body shown after a reset email is sent.
  ///
  /// In en, this message translates to:
  /// **'If an account is registered to {email}, we\'ve sent a secure password reset link. Please check your email.'**
  String forgotEmailSentBody(String email);

  /// Instruction on the password reset screen.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a secure password reset link.'**
  String get forgotResetBody;

  /// Button that sends the password reset link.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get forgotSendLink;

  /// Button to return to the login screen after sending a reset.
  ///
  /// In en, this message translates to:
  /// **'Return to Login'**
  String get forgotReturnToLogin;

  /// Title of the create-username screen.
  ///
  /// In en, this message translates to:
  /// **'Choose your\nusername'**
  String get usernameTitle;

  /// Subtitle explaining the username on the create-username screen.
  ///
  /// In en, this message translates to:
  /// **'This is how others will find you in the community. You can change it later in your profile.'**
  String get usernameSubtitle;

  /// Feedback when the chosen username handle is available.
  ///
  /// In en, this message translates to:
  /// **'@{handle} is available!'**
  String usernameAvailable(String handle);

  /// Hint describing the username format rules.
  ///
  /// In en, this message translates to:
  /// **'3–20 characters · letters, numbers, underscores only'**
  String get usernameRules;

  /// Validation error when the username is under 3 characters.
  ///
  /// In en, this message translates to:
  /// **'Too short — minimum 3 characters'**
  String get usernameTooShort;

  /// Validation error when the username exceeds 20 characters.
  ///
  /// In en, this message translates to:
  /// **'Too long — maximum 20 characters'**
  String get usernameTooLong;

  /// Validation error when the username has invalid characters.
  ///
  /// In en, this message translates to:
  /// **'Only lowercase letters, numbers, and underscores'**
  String get usernameInvalidChars;

  /// Validation error when the username is already in use.
  ///
  /// In en, this message translates to:
  /// **'That username is already taken'**
  String get usernameTaken;

  /// Error when the username availability check fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check availability — try again'**
  String get usernameCheckFailed;

  /// Error when the username was claimed during submission.
  ///
  /// In en, this message translates to:
  /// **'That username was just taken — try another'**
  String get usernameTakenJustNow;

  /// Error when saving the username fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to save — please try again'**
  String get usernameSaveFailed;

  /// Prompt on the role selection screen asking the user to pick traveler or guide.
  ///
  /// In en, this message translates to:
  /// **'Are you a...'**
  String get roleSelectionTitle;

  /// Label on the traveler/tourist role card.
  ///
  /// In en, this message translates to:
  /// **'TRAVELER!'**
  String get roleTraveler;

  /// Label on the guide role card.
  ///
  /// In en, this message translates to:
  /// **'GUIDE!'**
  String get roleGuide;

  /// Title on the complete-profile screen for new social sign-in users.
  ///
  /// In en, this message translates to:
  /// **'One Last Step'**
  String get completeProfileTitle;

  /// Subtitle explaining why a birthdate is requested on complete-profile.
  ///
  /// In en, this message translates to:
  /// **'We need your birthdate to customize your journey in Egypt.'**
  String get completeProfileSubtitle;

  /// Button that finalizes the social profile setup.
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get completeProfileButton;

  /// Hint for the birth month dropdown.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get dobMonth;

  /// Hint for the birth day dropdown.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dobDay;

  /// Hint for the birth year dropdown.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get dobYear;

  /// Title of the sign-up screen.
  ///
  /// In en, this message translates to:
  /// **'New Account'**
  String get signupTitle;

  /// Hint for the first name field on sign-up.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get signupFirstNameHint;

  /// Hint for the last name field on sign-up.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get signupLastNameHint;

  /// Label above the date-of-birth dropdowns on sign-up.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get signupDateOfBirth;

  /// Hint for the email field on sign-up.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get signupEmailHint;

  /// Label for the phone number field on sign-up.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get signupPhoneLabel;

  /// Hint for the confirm-password field on sign-up.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get signupConfirmPasswordHint;

  /// Primary button on the sign-up screen.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signupButton;

  /// Prompt next to the log-in link on sign-up.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get signupHaveAccount;

  /// Validation error for an invalid first name.
  ///
  /// In en, this message translates to:
  /// **'First name must contain valid letters (min 2).'**
  String get signupFirstNameInvalid;

  /// Validation error for an invalid last name.
  ///
  /// In en, this message translates to:
  /// **'Last name must contain valid letters (min 2).'**
  String get signupLastNameInvalid;

  /// Validation error for an invalid email on sign-up.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get signupEmailInvalid;

  /// Validation error for a weak password on sign-up.
  ///
  /// In en, this message translates to:
  /// **'Password must be 8+ characters with at least 1 letter and 1 number.'**
  String get signupPasswordWeak;

  /// Validation error when the two passwords differ.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get signupPasswordsNoMatch;

  /// Validation error for an invalid phone number on sign-up.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number.'**
  String get signupPhoneInvalid;

  /// Confirmation after an account is created.
  ///
  /// In en, this message translates to:
  /// **'Account created! Please verify your email to continue.'**
  String get signupSuccess;

  /// Error when the email is already registered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get signupEmailInUse;

  /// Error when Firebase reports a weak password.
  ///
  /// In en, this message translates to:
  /// **'The password is too weak.'**
  String get signupPasswordTooWeak;

  /// Greeting shown before noon.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// Greeting shown between noon and 5pm.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// Greeting shown after 5pm.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// Personalised greeting line on the home screen.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name} 👋'**
  String homeGreeting(String greeting, String name);

  /// Heading above the category grid on the home screen.
  ///
  /// In en, this message translates to:
  /// **'Where do you want to go?'**
  String get homeWhereToGo;

  /// Section header for the popular places carousel.
  ///
  /// In en, this message translates to:
  /// **'Popular Places'**
  String get homePopularPlaces;

  /// Section header for the personalised recommendations carousel.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get homeForYou;

  /// Section header for the events/experiences carousel.
  ///
  /// In en, this message translates to:
  /// **'Experiences'**
  String get homeExperiences;

  /// Link to view all items in a section.
  ///
  /// In en, this message translates to:
  /// **'see all >'**
  String get homeSeeAll;

  /// Empty state when no events match the selected category filter.
  ///
  /// In en, this message translates to:
  /// **'No events in this category'**
  String get homeNoEventsInCategory;

  /// Section header for the popular tours carousel.
  ///
  /// In en, this message translates to:
  /// **'Popular Tours'**
  String get homePopularTours;

  /// Section header above the Guides / Solo trip cards.
  ///
  /// In en, this message translates to:
  /// **'Plan your trip'**
  String get homePlanYourTrip;

  /// Label on the Guides trip-planning card.
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get homeTripGuides;

  /// Label on the Solo trip card.
  ///
  /// In en, this message translates to:
  /// **'Solo trip'**
  String get homeTripSolo;

  /// Header title of the Community tab.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityTitle;

  /// Hint in the community post search field.
  ///
  /// In en, this message translates to:
  /// **'Search posts...'**
  String get communitySearchPostsHint;

  /// Tooltip on the sort icon button.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get communitySortTooltip;

  /// Title of the tag-a-location dialog.
  ///
  /// In en, this message translates to:
  /// **'Tag a Location'**
  String get communityTagLocation;

  /// Hint in the place-search field of the tag-location dialog.
  ///
  /// In en, this message translates to:
  /// **'Search places in Egypt...'**
  String get communitySearchPlacesHint;

  /// Empty state in the tag-location dialog before typing.
  ///
  /// In en, this message translates to:
  /// **'Type to search places...'**
  String get communityTypeToSearch;

  /// Header of the post category picker sheet.
  ///
  /// In en, this message translates to:
  /// **'Post Category'**
  String get communityPostCategory;

  /// Community post category: photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get communityCategoryPhotos;

  /// Community post category: questions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get communityCategoryQuestions;

  /// Community post category: guides.
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get communityCategoryGuides;

  /// Community post category: landmarks.
  ///
  /// In en, this message translates to:
  /// **'Landmarks'**
  String get communityCategoryLandmarks;

  /// Community post category: traveler's tips.
  ///
  /// In en, this message translates to:
  /// **'Traveler\'s Tips'**
  String get communityCategoryTips;

  /// Header of the sort-posts sheet.
  ///
  /// In en, this message translates to:
  /// **'Sort Posts'**
  String get communitySortPosts;

  /// Sort option: newest first.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get communitySortNewest;

  /// Sort option: most liked.
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get communitySortTopRated;

  /// Sort option: most comments.
  ///
  /// In en, this message translates to:
  /// **'Most Discussed'**
  String get communitySortMostDiscussed;

  /// Error state when the posts stream fails to load.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get communitySomethingWrong;

  /// Empty state when there are no posts at all.
  ///
  /// In en, this message translates to:
  /// **'No posts yet. Be the first!'**
  String get communityNoPostsYet;

  /// Empty state when a search returns no posts.
  ///
  /// In en, this message translates to:
  /// **'No results for \'{query}\''**
  String communityNoResultsFor(String query);

  /// Empty state when no posts match the active category/hashtag filter.
  ///
  /// In en, this message translates to:
  /// **'No posts in this category yet.'**
  String get communityNoPostsInCategory;

  /// Floating banner shown when new posts arrive.
  ///
  /// In en, this message translates to:
  /// **'New posts — tap to refresh'**
  String get communityNewPosts;

  /// Header above the trending hashtags row.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get communityTrending;

  /// Link that clears the active hashtag filter.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get communityClearFilter;

  /// Header of the leaderboard card.
  ///
  /// In en, this message translates to:
  /// **'Top Explorers This Feed'**
  String get communityTopExplorers;

  /// Post count badge on the leaderboard.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 post} other{{count} posts}}'**
  String communityPostsCount(int count);

  /// Label above the weekly challenge title.
  ///
  /// In en, this message translates to:
  /// **'Weekly Challenge'**
  String get communityWeeklyChallenge;

  /// Call-to-action chip on the weekly challenge card.
  ///
  /// In en, this message translates to:
  /// **'Post Now'**
  String get communityPostNow;

  /// Hint in the new-post composer field.
  ///
  /// In en, this message translates to:
  /// **'Share your Egypt experience...'**
  String get communityComposerHint;

  /// Button that submits a new community post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get communityPostButton;

  /// Tooltip on the composer add-photos action.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get communityAddPhotosTooltip;

  /// Tooltip on the composer tag-location action.
  ///
  /// In en, this message translates to:
  /// **'Tag location'**
  String get communityTagLocationTooltip;

  /// Tooltip on the composer category action.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get communityCategoryTooltip;

  /// Generic Save button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Generic Edit action.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// Generic Delete action.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Generic Report action.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get commonReport;

  /// Title of the edit-comment dialog.
  ///
  /// In en, this message translates to:
  /// **'Edit Comment'**
  String get commentEditTitle;

  /// Title of the delete-comment confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete Comment'**
  String get commentDeleteTitle;

  /// Body of the delete-comment confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this comment?'**
  String get commentDeleteConfirm;

  /// Button that starts a reply to a comment.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get commentReply;

  /// Banner above the composer when replying to a comment.
  ///
  /// In en, this message translates to:
  /// **'Replying to @{name}'**
  String commentReplyingTo(String name);

  /// Hint in the composer when replying.
  ///
  /// In en, this message translates to:
  /// **'Write a reply...'**
  String get commentWriteReply;

  /// Hint in the composer when commenting.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get commentWriteComment;

  /// Empty state when a post has no comments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Be the first!'**
  String get commentsEmpty;

  /// Expander to show replies under a comment.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{View 1 reply} other{View {count} replies}} ▸'**
  String commentViewReplies(int count);

  /// Collapser to hide replies under a comment.
  ///
  /// In en, this message translates to:
  /// **'Hide replies ▴'**
  String get commentHideReplies;

  /// Button that loads more comments.
  ///
  /// In en, this message translates to:
  /// **'View More Comments'**
  String get commentsViewMore;

  /// Header above the comments list with a count.
  ///
  /// In en, this message translates to:
  /// **'Comments ({count})'**
  String commentsHeader(int count);

  /// Header of the More tab.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// More tab tile: currency converter.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get moreCurrency;

  /// More tab tile: help/FAQ.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get moreHelp;

  /// More tab tile: translator.
  ///
  /// In en, this message translates to:
  /// **'Translator'**
  String get moreTranslator;

  /// More tab tile: contact us.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get moreContactUs;

  /// More tab red SOS button.
  ///
  /// In en, this message translates to:
  /// **'SOS — Emergency Numbers'**
  String get moreSosButton;

  /// Error when an external link can't be opened.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get contactCouldNotOpen;

  /// Confirmation after copying the support email.
  ///
  /// In en, this message translates to:
  /// **'{email} copied to clipboard'**
  String contactEmailCopied(String email);

  /// Title of the Contact Us screen.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactTitle;

  /// Headline on the Contact Us screen.
  ///
  /// In en, this message translates to:
  /// **'We\'re here to help'**
  String get contactHeadline;

  /// Subtitle on the Contact Us screen.
  ///
  /// In en, this message translates to:
  /// **'Reach out through any of the channels below and we\'ll get back to you as soon as possible.'**
  String get contactSubtitle;

  /// Contact tile: email support.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get contactEmailSupport;

  /// Contact channel: WhatsApp (brand name).
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get contactWhatsApp;

  /// Subtitle on the WhatsApp contact tile.
  ///
  /// In en, this message translates to:
  /// **'Chat with us directly'**
  String get contactWhatsAppSubtitle;

  /// Contact channel: Instagram (brand name).
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get contactInstagram;

  /// Header of the response-times section.
  ///
  /// In en, this message translates to:
  /// **'Response times'**
  String get contactResponseTimes;

  /// Response-time row label: email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get contactRespEmail;

  /// Response-time row label: Instagram direct messages.
  ///
  /// In en, this message translates to:
  /// **'Instagram DMs'**
  String get contactRespInstagram;

  /// Expected email response time.
  ///
  /// In en, this message translates to:
  /// **'Within 24 hours'**
  String get contactTimeEmail;

  /// Expected WhatsApp response time.
  ///
  /// In en, this message translates to:
  /// **'Within a few hours'**
  String get contactTimeWhatsApp;

  /// Expected Instagram response time.
  ///
  /// In en, this message translates to:
  /// **'1–2 business days'**
  String get contactTimeInstagram;

  /// Title of the SOS screen.
  ///
  /// In en, this message translates to:
  /// **'SOS — Emergency'**
  String get sosAppBarTitle;

  /// Section header above the nearby-help finder.
  ///
  /// In en, this message translates to:
  /// **'Find Nearest Help'**
  String get sosFindNearestHelp;

  /// Help category / dial label: police.
  ///
  /// In en, this message translates to:
  /// **'Police'**
  String get sosPolice;

  /// Help category: hospital.
  ///
  /// In en, this message translates to:
  /// **'Hospital'**
  String get sosHospital;

  /// Help category: fire station.
  ///
  /// In en, this message translates to:
  /// **'Fire Station'**
  String get sosFireStation;

  /// Button to find the nearest place of a category.
  ///
  /// In en, this message translates to:
  /// **'Find Nearest {category}'**
  String sosFindNearest(String category);

  /// Button to refresh nearby results for a category.
  ///
  /// In en, this message translates to:
  /// **'Refresh — {category}'**
  String sosRefresh(String category);

  /// Status line shown when a GPS fix is available.
  ///
  /// In en, this message translates to:
  /// **'Using your current location'**
  String get sosUsingLocation;

  /// Error when location permission is permanently denied.
  ///
  /// In en, this message translates to:
  /// **'Please enable location in your device settings to find nearby help.'**
  String get sosEnableLocation;

  /// Error when fetching the current location fails.
  ///
  /// In en, this message translates to:
  /// **'Make sure location services are enabled and try again.'**
  String get sosLocationError;

  /// Empty state when no nearby places of a category are found.
  ///
  /// In en, this message translates to:
  /// **'No {category} found within 10 km. Try moving to a different area.'**
  String sosNoResults(String category);

  /// Error when the nearby search fails.
  ///
  /// In en, this message translates to:
  /// **'Search failed — check your connection and try again.'**
  String get sosSearchFailed;

  /// Error when the phone dialler can't be opened.
  ///
  /// In en, this message translates to:
  /// **'Could not open dialler'**
  String get sosCouldNotDial;

  /// Section header above the emergency dial grid.
  ///
  /// In en, this message translates to:
  /// **'Emergency Numbers'**
  String get sosEmergencyNumbers;

  /// Footnote under the emergency numbers grid.
  ///
  /// In en, this message translates to:
  /// **'These are Egypt\'s official emergency numbers. Tourist Police (126) has English-speaking operators.'**
  String get sosNumbersNote;

  /// Dial label: tourist police.
  ///
  /// In en, this message translates to:
  /// **'Tourist Police'**
  String get sosTouristPolice;

  /// Dial label: ambulance.
  ///
  /// In en, this message translates to:
  /// **'Ambulance'**
  String get sosAmbulance;

  /// Dial label: fire brigade.
  ///
  /// In en, this message translates to:
  /// **'Fire Brigade'**
  String get sosFireBrigade;

  /// Dial label: gas emergency.
  ///
  /// In en, this message translates to:
  /// **'Gas Emergency'**
  String get sosGasEmergency;

  /// Subtitle on the featured tourist-police dial chip.
  ///
  /// In en, this message translates to:
  /// **'English-speaking operators · Available 24/7'**
  String get sosTouristPoliceSubtitle;

  /// Badge on the featured tourist-police dial chip.
  ///
  /// In en, this message translates to:
  /// **'FOR TOURISTS'**
  String get sosForTourists;

  /// Action button to call a nearby place.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get sosCall;

  /// Action button to open a nearby place on the map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get sosMap;

  /// Fallback display name when the user's name is unavailable.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get accountUser;

  /// Title of the personalised taste card on the account screen.
  ///
  /// In en, this message translates to:
  /// **'Your Taste'**
  String get accountYourTaste;

  /// Header above the account settings tiles.
  ///
  /// In en, this message translates to:
  /// **'Account Settings:'**
  String get accountSettingsHeader;

  /// Account tile: edit profile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get accountEditProfile;

  /// Account tile: apply to become a guide.
  ///
  /// In en, this message translates to:
  /// **'Apply to be a Guide'**
  String get accountApplyGuide;

  /// Account tile: booking history.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get accountMyBookings;

  /// Account tile: saved community posts.
  ///
  /// In en, this message translates to:
  /// **'Saved Posts'**
  String get accountSavedPosts;

  /// Account tile: saved solo plans.
  ///
  /// In en, this message translates to:
  /// **'My Plans'**
  String get accountMyPlans;

  /// Account tile: membership / plan.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get accountMembership;

  /// Sign-out button on the account screen.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// Label on the guide application status tile.
  ///
  /// In en, this message translates to:
  /// **'Guide Application'**
  String get accountGuideApplication;

  /// Guide application status: pending review.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get accountStatusUnderReview;

  /// Guide application status: rejected.
  ///
  /// In en, this message translates to:
  /// **'Not Approved'**
  String get accountStatusNotApproved;

  /// Name of the free membership tier.
  ///
  /// In en, this message translates to:
  /// **'Explorer — Free'**
  String get planExplorerFree;

  /// Badge showing the current plan is active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get planActive;

  /// Description of the free plan.
  ///
  /// In en, this message translates to:
  /// **'Your current plan — enjoy all the core features of Lost in Egypt at no cost.'**
  String get planCurrentDesc;

  /// Header above the included-features list.
  ///
  /// In en, this message translates to:
  /// **'What\'s included'**
  String get planWhatsIncluded;

  /// Plan feature title: AI landmark discovery.
  ///
  /// In en, this message translates to:
  /// **'AI Landmark Discovery'**
  String get planFeatDiscoveryTitle;

  /// Plan feature description: AI landmark discovery.
  ///
  /// In en, this message translates to:
  /// **'Identify unlimited landmarks with your camera'**
  String get planFeatDiscoveryDesc;

  /// Plan feature title: AI historical stories.
  ///
  /// In en, this message translates to:
  /// **'AI Historical Stories'**
  String get planFeatStoriesTitle;

  /// Plan feature description: AI historical stories.
  ///
  /// In en, this message translates to:
  /// **'Hear captivating stories about every landmark you find'**
  String get planFeatStoriesDesc;

  /// Plan feature title: interactive map.
  ///
  /// In en, this message translates to:
  /// **'Interactive Map'**
  String get planFeatMapTitle;

  /// Plan feature description: interactive map.
  ///
  /// In en, this message translates to:
  /// **'Explore 500+ Egyptian landmarks with GPS and routing'**
  String get planFeatMapDesc;

  /// Plan feature title: browse and book tours.
  ///
  /// In en, this message translates to:
  /// **'Browse & Book Tours'**
  String get planFeatToursTitle;

  /// Plan feature description: tours.
  ///
  /// In en, this message translates to:
  /// **'Browse guided tours and book with certified guides'**
  String get planFeatToursDesc;

  /// Plan feature title: badges and gamification.
  ///
  /// In en, this message translates to:
  /// **'Badges & Gamification'**
  String get planFeatBadgesTitle;

  /// Plan feature description: badges.
  ///
  /// In en, this message translates to:
  /// **'Earn badges as you explore more of Egypt'**
  String get planFeatBadgesDesc;

  /// Plan feature title: community feed.
  ///
  /// In en, this message translates to:
  /// **'Community Feed'**
  String get planFeatCommunityTitle;

  /// Plan feature description: community.
  ///
  /// In en, this message translates to:
  /// **'Share discoveries and connect with fellow travellers'**
  String get planFeatCommunityDesc;

  /// Plan feature title: translator.
  ///
  /// In en, this message translates to:
  /// **'Translator'**
  String get planFeatTranslatorTitle;

  /// Plan feature description: translator.
  ///
  /// In en, this message translates to:
  /// **'Translate text using your camera in real-time'**
  String get planFeatTranslatorDesc;

  /// Plan feature title: currency converter.
  ///
  /// In en, this message translates to:
  /// **'Currency Converter'**
  String get planFeatCurrencyTitle;

  /// Plan feature description: currency converter.
  ///
  /// In en, this message translates to:
  /// **'Convert between 16 currencies instantly'**
  String get planFeatCurrencyDesc;

  /// Plan feature title: booking notifications.
  ///
  /// In en, this message translates to:
  /// **'Booking Notifications'**
  String get planFeatNotificationsTitle;

  /// Plan feature description: notifications.
  ///
  /// In en, this message translates to:
  /// **'Get notified about your tour confirmations'**
  String get planFeatNotificationsDesc;

  /// Header of the coming-soon section.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get planComingSoon;

  /// Description under the coming-soon section.
  ///
  /// In en, this message translates to:
  /// **'We\'re working on premium features including offline mode, exclusive guided experiences, and advanced trip planning tools. Stay tuned — and the core app will always remain free.'**
  String get planComingSoonDesc;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
