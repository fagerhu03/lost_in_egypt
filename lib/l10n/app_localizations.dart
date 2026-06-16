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

  /// Title of the read-only profile view screen.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileViewTitle;

  /// Empty state when the requested profile does not exist.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get profileUserNotFound;

  /// Label for the email verification badge / field.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// Label for the phone verification badge / item.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhone;

  /// Caption under the posts count on the profile stats row.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get profilePostsStat;

  /// Caption under the visited-places count on the profile stats row.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get profilePlacesStat;

  /// Label for the user role stat / field.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get profileRole;

  /// Role label: administrator.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get profileRoleAdmin;

  /// Role label: verified guide.
  ///
  /// In en, this message translates to:
  /// **'Verified Guide'**
  String get profileRoleVerifiedGuide;

  /// Role label: tourist / traveler.
  ///
  /// In en, this message translates to:
  /// **'Tourist'**
  String get profileRoleTourist;

  /// Section header for the user's bio.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileAbout;

  /// Section header / label for the user's interests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get profileInterests;

  /// Section header for the user's social links.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get profileSocial;

  /// Instagram label / brand name.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get profileInstagram;

  /// Twitter label / brand name.
  ///
  /// In en, this message translates to:
  /// **'Twitter'**
  String get profileTwitter;

  /// Section header for the user's contact details.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get profileContact;

  /// Section header for the gamification badges row.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get profileBadges;

  /// Header / button label for the edit-profile screen.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// Confirmation after the profile photo is uploaded.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated ✅'**
  String get editPhotoUpdated;

  /// Error when the profile photo upload fails.
  ///
  /// In en, this message translates to:
  /// **'Error uploading photo. Please try again.'**
  String get editPhotoUploadError;

  /// Error when the user tries to save with an unverified new phone number.
  ///
  /// In en, this message translates to:
  /// **'Phone number must be verified before saving'**
  String get editPhoneMustVerify;

  /// Validation error for an invalid Instagram handle.
  ///
  /// In en, this message translates to:
  /// **'Instagram: letters, numbers, . and _ only (max 30)'**
  String get editInstagramRule;

  /// Validation error for an invalid Twitter/X handle.
  ///
  /// In en, this message translates to:
  /// **'Twitter/X: letters, numbers, . and _ only (max 15)'**
  String get editTwitterRule;

  /// Validation error when the username field is empty.
  ///
  /// In en, this message translates to:
  /// **'Username cannot be empty'**
  String get editUsernameEmpty;

  /// Title of the dialog to request a new certified guide language.
  ///
  /// In en, this message translates to:
  /// **'Request Language Addition'**
  String get editLangRequestTitle;

  /// Explanation in the request-language dialog.
  ///
  /// In en, this message translates to:
  /// **'By Egyptian law, guides require official certification to guide in specific languages. Please enter the language you wish to add. An admin will verify your syndicate/MOTA records.'**
  String get editLangRequestBody;

  /// Hint for the language input in the request-language dialog.
  ///
  /// In en, this message translates to:
  /// **'e.g., Spanish, German, Italian'**
  String get editLangRequestHint;

  /// Button that submits a language addition request.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get editLangSubmit;

  /// Error when the user already has a pending language request.
  ///
  /// In en, this message translates to:
  /// **'You already have a pending language request.'**
  String get editLangPending;

  /// Confirmation after a language addition request is submitted.
  ///
  /// In en, this message translates to:
  /// **'Request submitted! An admin will review it shortly.'**
  String get editLangSubmitted;

  /// Confirmation after the profile is saved.
  ///
  /// In en, this message translates to:
  /// **'Profile Updated ✅'**
  String get editProfileUpdated;

  /// Label above the profile completion progress bar.
  ///
  /// In en, this message translates to:
  /// **'Profile Completion'**
  String get editProfileCompletion;

  /// Section header for basic profile fields.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get editSectionBasic;

  /// Label for the full name field.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get editFullName;

  /// Label for the username field.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get editUsername;

  /// Label for the phone number field.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get editPhoneNumber;

  /// Label for the nationality picker.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get editNationality;

  /// Section header for contact fields.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get editSectionContact;

  /// Section header for bio and interests.
  ///
  /// In en, this message translates to:
  /// **'About You'**
  String get editSectionAbout;

  /// Label for the bio field.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get editBio;

  /// Hint inside the bio field.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself...'**
  String get editBioHint;

  /// Section header for optional social links.
  ///
  /// In en, this message translates to:
  /// **'Social Links (Optional)'**
  String get editSectionSocial;

  /// Hint inside the Instagram/Twitter handle fields.
  ///
  /// In en, this message translates to:
  /// **'username (no @)'**
  String get editSocialHint;

  /// Label for the Twitter/X handle field.
  ///
  /// In en, this message translates to:
  /// **'Twitter/X'**
  String get editTwitterLabel;

  /// Section header for verified-guide credentials.
  ///
  /// In en, this message translates to:
  /// **'Guide Credentials'**
  String get editSectionGuide;

  /// Label for the read-only certified languages field.
  ///
  /// In en, this message translates to:
  /// **'Certified Languages (Locked)'**
  String get editCertifiedLangs;

  /// Placeholder when the guide has no certified languages.
  ///
  /// In en, this message translates to:
  /// **'None certified yet.'**
  String get editNoCertifiedLangs;

  /// Button to request adding a new certified language.
  ///
  /// In en, this message translates to:
  /// **'Request New Language'**
  String get editRequestNewLang;

  /// Hint in the nationality country-picker search field.
  ///
  /// In en, this message translates to:
  /// **'Search nationality'**
  String get editSearchNationality;

  /// Placeholder example handle in the username field.
  ///
  /// In en, this message translates to:
  /// **'your_handle'**
  String get editUsernameHint;

  /// Header of the verification status card.
  ///
  /// In en, this message translates to:
  /// **'Verification Status'**
  String get editVerificationStatus;

  /// Confirmation after a verification email is resent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent! Check your inbox.'**
  String get editVerificationEmailSent;

  /// Button to resend the email verification.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get editResend;

  /// Button to start phone verification.
  ///
  /// In en, this message translates to:
  /// **'Verify now'**
  String get editVerifyNow;

  /// Primary button that saves the edited profile.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get editSaveChanges;

  /// Title of the currency converter screen.
  ///
  /// In en, this message translates to:
  /// **'Currency Converter'**
  String get currencyConverterTitle;

  /// Validation error when the amount is empty or non-positive.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get currencyEnterValidAmount;

  /// Error when no exchange rate exists for the target currency.
  ///
  /// In en, this message translates to:
  /// **'Rate not available for {currency}'**
  String currencyRateUnavailable(String currency);

  /// Label above the source-currency dropdown.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get currencyFrom;

  /// Label above the target-currency dropdown.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get currencyTo;

  /// Label above the amount input.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get currencyAmount;

  /// Hint inside the amount input.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get currencyEnterAmount;

  /// Button that performs the conversion.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get currencyConvert;

  /// Label above the conversion result.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get currencyResult;

  /// Error when the on-device translator fails to initialize.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize translator'**
  String get translatorInitFailed;

  /// Validation error when the source text is empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter text to translate'**
  String get translatorEnterText;

  /// Error when translation times out.
  ///
  /// In en, this message translates to:
  /// **'Translation timed out. Models may still be downloading — try again in a moment.'**
  String get translatorTimedOut;

  /// Error when translation fails.
  ///
  /// In en, this message translates to:
  /// **'Translation failed. If offline, models may not be downloaded yet.'**
  String get translatorFailed;

  /// Status banner while language models download.
  ///
  /// In en, this message translates to:
  /// **'Downloading translation models for offline use...'**
  String get translatorDownloadingModels;

  /// Status banner once models are cached.
  ///
  /// In en, this message translates to:
  /// **'Works offline - models cached on device'**
  String get translatorWorksOffline;

  /// Hint in the source text field.
  ///
  /// In en, this message translates to:
  /// **'Enter text'**
  String get translatorEnterTextHint;

  /// Hint in the read-only translation field.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translatorTranslationHint;

  /// Button that triggers translation.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get translatorTranslate;

  /// Title of the Help & FAQ screen.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get helpFaqTitle;

  /// Help section header.
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get helpSecGettingStarted;

  /// Help section header.
  ///
  /// In en, this message translates to:
  /// **'Map & Places'**
  String get helpSecMapPlaces;

  /// Help section header.
  ///
  /// In en, this message translates to:
  /// **'Bookings & Payments'**
  String get helpSecBookings;

  /// Help section header.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get helpSecCommunity;

  /// Help section header.
  ///
  /// In en, this message translates to:
  /// **'Account & Settings'**
  String get helpSecAccount;

  /// Help section header.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get helpSecOffline;

  /// Help section header.
  ///
  /// In en, this message translates to:
  /// **'Safety & Emergency'**
  String get helpSecSafety;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'How do I discover landmarks?'**
  String get helpQDiscover;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'Open the Camera tab and point your phone at any Egyptian landmark. The AI will identify it and generate a historical story read aloud by your personal guide. Each discovery is saved to your profile and counts toward your badge progress.'**
  String get helpADiscover;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'How do I earn badges?'**
  String get helpQBadges;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'Badges are earned by discovering landmarks through the Camera tab. Visit 1, 3, 5, 10, and 20 unique landmarks to unlock Novice Explorer, Tourist, Tomb Raider, Historian, and Pharaoh badges respectively. There are also hidden badges — explore and find them!'**
  String get helpABadges;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'How do I become a tour guide?'**
  String get helpQGuide;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'Go to Account → Apply as Guide. You\'ll need your MOTA license number, syndicate number, certified languages, and supporting documents. Applications are reviewed by our admin team and you will be notified of the outcome in-app.'**
  String get helpAGuide;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'Can I save places to visit later?'**
  String get helpQSavePlaces;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'Yes! On the Map tab, tap any landmark pin and press the bookmark icon to save it. You can also save events from the Home tab by tapping the heart icon on any event card. Access all your saved places from the Map tab → Saved Places.'**
  String get helpASavePlaces;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'My camera didn\'t recognise a landmark — what should I do?'**
  String get helpQRecognise;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'Ensure the landmark fills most of the frame and is well lit. Tap the shutter button and wait a few seconds. If the landmark is very minor or off the main tourist trail it may not be in the database yet.'**
  String get helpARecognise;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'How do I book a tour?'**
  String get helpQBook;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'Go to the Home tab and browse available guided tours, or find one on the Map tab. Choose a tour, select your date and number of tickets, then complete payment using any of the available payment methods shown at checkout (card, Apple Pay, or mobile wallet).'**
  String get helpABook;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'How do I cancel a booking?'**
  String get helpQCancel;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'Go to Account → My Bookings, find the booking under the Upcoming tab, and tap Cancel. Refund policies are set by each guide — check the tour details before booking.'**
  String get helpACancel;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'Is my payment information secure?'**
  String get helpQSecure;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'Yes. Payments are processed through Paymob, a certified PCI-compliant payment gateway. Lost in Egypt never stores your card or wallet details on its servers.'**
  String get helpASecure;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'How do I change my display currency?'**
  String get helpQCurrency;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'Go to More → Settings → Preferred Currency. All tour prices across the app will display in your chosen currency. The actual charge at checkout is always processed in EGP via Paymob.'**
  String get helpACurrency;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'How do I post in the community?'**
  String get helpQPost;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'Tap the Community tab and press the + button. You can write text, add photos, tag a location, choose a category (Travel Story, Question, Tip, etc.), and use #hashtags or @mention other users.'**
  String get helpAPost;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'How do I report a post or user?'**
  String get helpQReport;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'On any community post or comment, tap the ⋮ menu and select Report. Our admin team reviews all reports and takes action within 24 hours.'**
  String get helpAReport;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'How do I change my username?'**
  String get helpQUsername;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'Go to Account → Edit Profile. Your username (e.g. @ahmed_x1) must be 3–20 characters, lowercase letters, numbers, and underscores only, and globally unique. It is displayed on all your posts and comments.'**
  String get helpAUsername;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'How do I switch between light and dark mode?'**
  String get helpQTheme;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'Go to More → Settings and toggle the Dark Mode switch. Your preference is saved to your account and synced across devices.'**
  String get helpATheme;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'What can I use without an internet connection?'**
  String get helpQOfflineWhat;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'Lost in Egypt is designed primarily as an online experience, but several features remain available offline:\n\n• Map pins — over 500 Egyptian landmarks are bundled locally in the app, so the map shows location markers even without internet (map tiles themselves require connectivity).\n• Cached images — places and event images you have previously viewed are stored on your device and load instantly offline.\n• Text recognition (Camera → Scan text) — ML Kit processes text entirely on-device.\n• Translator — once a language pack is downloaded, translation works offline.\n• App navigation, badges, and settings — always available.'**
  String get helpAOfflineWhat;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'What features require an internet connection?'**
  String get helpQOfflineNeed;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'The following features need an active connection:\n\n• Landmark identification via the Camera tab (uses Google Cloud Vision API)\n• AI historical story generation (uses Google Gemini)\n• Community posts, likes, and comments (Firestore)\n• Browsing and booking tours (Firestore)\n• Events feed (Firestore)\n• Currency conversion (live exchange rates)\n• SOS — nearest emergency services search (Google Places API)\n• Signing in or creating an account (Firebase Auth)'**
  String get helpAOfflineNeed;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'Will offline-capable features improve over time?'**
  String get helpQOfflineImprove;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'Yes. We plan to expand offline support in future updates, including downloadable city guides and cached tour content. Keep the app updated to get these improvements.'**
  String get helpAOfflineImprove;

  /// FAQ question.
  ///
  /// In en, this message translates to:
  /// **'What do I do in an emergency?'**
  String get helpQEmergency;

  /// FAQ answer.
  ///
  /// In en, this message translates to:
  /// **'Open More → SOS. You can find the nearest police station, hospital, or fire station using your current location, or dial Egypt\'s official emergency numbers directly from the app:\n• Police: 122\n• Ambulance: 123\n• Fire: 180\n• Tourist Police: 126'**
  String get helpAEmergency;

  /// Title of the solo trip page.
  ///
  /// In en, this message translates to:
  /// **'Solo Trip'**
  String get soloTripTitle;

  /// Header above the recommended curated trips.
  ///
  /// In en, this message translates to:
  /// **'Recommended Plans'**
  String get soloRecommendedPlans;

  /// Subtitle shown when a best-match trip is highlighted.
  ///
  /// In en, this message translates to:
  /// **'Personalised based on your travel history'**
  String get soloPersonalised;

  /// Badge on the best-match trip card.
  ///
  /// In en, this message translates to:
  /// **'Best for you'**
  String get soloBestForYou;

  /// Plan status: active tour.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get soloStatusActive;

  /// Plan status / tab / badge: saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get soloStatusSaved;

  /// Plan status / tab: completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get soloStatusCompleted;

  /// My Plans tab: all plans.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get soloTabAll;

  /// Error when the plans stream fails.
  ///
  /// In en, this message translates to:
  /// **'Could not load plans'**
  String get soloCouldNotLoadPlans;

  /// Button to resume an active tour.
  ///
  /// In en, this message translates to:
  /// **'Continue Tour'**
  String get soloContinueTour;

  /// Button to start a saved tour.
  ///
  /// In en, this message translates to:
  /// **'Start Tour'**
  String get soloStartTour;

  /// Error when starting a tour fails.
  ///
  /// In en, this message translates to:
  /// **'Could not start tour. Try again.'**
  String get soloCouldNotStart;

  /// Title of the delete-plan confirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete plan?'**
  String get soloDeletePlanTitle;

  /// Body when deleting an in-progress tour.
  ///
  /// In en, this message translates to:
  /// **'This tour is in progress. Deleting it will discard all your progress and cannot be undone.'**
  String get soloDeleteActiveBody;

  /// Body when deleting a saved plan.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get soloDeleteBody;

  /// Empty state title for My Plans.
  ///
  /// In en, this message translates to:
  /// **'No plans yet'**
  String get soloNoPlansYet;

  /// Empty state subtitle for My Plans.
  ///
  /// In en, this message translates to:
  /// **'Save a curated trip or create your own\nto see it here.'**
  String get soloNoPlansSub;

  /// CTA in the My Plans empty state.
  ///
  /// In en, this message translates to:
  /// **'Browse Trips'**
  String get soloBrowseTrips;

  /// Label on the customize-plan card.
  ///
  /// In en, this message translates to:
  /// **'Customize your\nown plan'**
  String get soloCustomizeOwnPlan;

  /// Button / tooltip to save a generated plan.
  ///
  /// In en, this message translates to:
  /// **'Save Plan'**
  String get soloSavePlan;

  /// Confirmation after saving a plan.
  ///
  /// In en, this message translates to:
  /// **'Plan saved! Find it in My Plans.'**
  String get soloPlanSaved;

  /// Error when saving a plan fails.
  ///
  /// In en, this message translates to:
  /// **'Could not save plan. Try again.'**
  String get soloCouldNotSave;

  /// Button to open the AI story sheet for a stop.
  ///
  /// In en, this message translates to:
  /// **'Hear the Story'**
  String get soloHearStory;

  /// Error shown when the AI story fails to load.
  ///
  /// In en, this message translates to:
  /// **'The spirits of history are silent right now.'**
  String get soloStorySilent;

  /// Story audio: pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get soloStoryPause;

  /// Story audio: resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get soloStoryResume;

  /// Story audio: start playback.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get soloStoryListen;

  /// Story audio: loading state while TTS generates.
  ///
  /// In en, this message translates to:
  /// **'Generating audio…'**
  String get soloStoryGenerating;

  /// Story audio: replay tooltip.
  ///
  /// In en, this message translates to:
  /// **'Replay from start'**
  String get soloStoryReplay;

  /// Tooltip / label to navigate to a stop.
  ///
  /// In en, this message translates to:
  /// **'Navigate here'**
  String get soloNavigateHere;

  /// Tooltip to view the whole route on the map.
  ///
  /// In en, this message translates to:
  /// **'View full route'**
  String get soloViewFullRoute;

  /// Tooltip on the curated detail map button.
  ///
  /// In en, this message translates to:
  /// **'View full route on map'**
  String get soloViewFullRouteMap;

  /// Label on the full-route button.
  ///
  /// In en, this message translates to:
  /// **'Full route'**
  String get soloFullRoute;

  /// Section header for trip highlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get soloHighlights;

  /// Section header for the itinerary.
  ///
  /// In en, this message translates to:
  /// **'Itinerary'**
  String get soloItinerary;

  /// Title of the end-tour confirmation.
  ///
  /// In en, this message translates to:
  /// **'End Tour?'**
  String get tourEndTitle;

  /// Body of the end-tour confirmation.
  ///
  /// In en, this message translates to:
  /// **'This will mark the tour as completed. You can still view it in My Plans.'**
  String get tourEndBody;

  /// Confirm button to end the tour.
  ///
  /// In en, this message translates to:
  /// **'End Tour'**
  String get tourEndConfirm;

  /// Confirmation after a tour is ended.
  ///
  /// In en, this message translates to:
  /// **'Tour ended. Find it under Completed in My Plans.'**
  String get tourEnded;

  /// Live tour status label.
  ///
  /// In en, this message translates to:
  /// **'Tour in Progress'**
  String get tourInProgress;

  /// Button to focus the map on the next stop.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get tourGo;

  /// Pill on the next incomplete stop.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get tourUpNext;

  /// Title of the tour-complete dialog.
  ///
  /// In en, this message translates to:
  /// **'Tour Complete!'**
  String get tourComplete;

  /// Stops-explored count in the tour-complete dialog.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 stop explored} other{{count} stops explored}}'**
  String tourStopsExplored(int count);

  /// Congratulatory message in the tour-complete dialog.
  ///
  /// In en, this message translates to:
  /// **'You\'ve experienced the heart of Egypt.\nGreat exploring! 🌟'**
  String get tourCompleteSub;

  /// Header above similar-place suggestions.
  ///
  /// In en, this message translates to:
  /// **'You might also love'**
  String get tourYouMightLove;

  /// Button to dismiss the tour-complete dialog.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tourDone;

  /// Headline of the active-tour onboarding sheet.
  ///
  /// In en, this message translates to:
  /// **'🗺️ Your Tour Has Started!'**
  String get tourStartedTitle;

  /// Subtitle of the active-tour onboarding sheet.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what you can do'**
  String get tourOnboardTitle;

  /// Button to dismiss the onboarding sheet.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Go!'**
  String get tourLetsGo;

  /// Onboarding feature title: view on map.
  ///
  /// In en, this message translates to:
  /// **'View on Map'**
  String get tourFeatViewMap;

  /// Onboarding feature description: view on map.
  ///
  /// In en, this message translates to:
  /// **'Tap the map icon (top-right) to see your stops on the map and navigate to any one.'**
  String get tourFeatViewMapDesc;

  /// Onboarding feature title: track progress.
  ///
  /// In en, this message translates to:
  /// **'Track Progress'**
  String get tourFeatTrack;

  /// Onboarding feature description: track progress.
  ///
  /// In en, this message translates to:
  /// **'Check off each stop as you visit it. Your progress saves automatically.'**
  String get tourFeatTrackDesc;

  /// Onboarding feature title: AI stories.
  ///
  /// In en, this message translates to:
  /// **'AI Stories'**
  String get tourFeatStories;

  /// Onboarding feature description: AI stories.
  ///
  /// In en, this message translates to:
  /// **'Expand any stop and tap \"Hear the Story\" for an AI-generated history of that place.'**
  String get tourFeatStoriesDesc;

  /// Error when trip generation fails.
  ///
  /// In en, this message translates to:
  /// **'Could not generate your plan.'**
  String get resultCouldNotGenerate;

  /// Loading title while the AI builds the itinerary.
  ///
  /// In en, this message translates to:
  /// **'Planning your trip…'**
  String get resultPlanning;

  /// Loading subtitle while the AI builds the itinerary.
  ///
  /// In en, this message translates to:
  /// **'Our AI guide is building a personalised day-by-day itinerary for you.'**
  String get resultPlanningSub;

  /// Error title when the plan can't be loaded.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your plan'**
  String get resultCouldNotLoad;

  /// Error when a stop has no coordinates yet.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t pin {name} on the map yet. Try again in a moment.'**
  String resultCouldNotPin(String name);

  /// Error when PDF export fails.
  ///
  /// In en, this message translates to:
  /// **'Could not export itinerary. Try again.'**
  String get resultCouldNotExport;

  /// Title of the discard-plan confirmation.
  ///
  /// In en, this message translates to:
  /// **'Discard plan?'**
  String get resultDiscardTitle;

  /// Body of the discard-plan confirmation.
  ///
  /// In en, this message translates to:
  /// **'This plan will not be saved. You can always generate a new one.'**
  String get resultDiscardBody;

  /// Button to keep the plan.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get resultKeep;

  /// Button to discard the plan.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get resultDiscard;

  /// Tooltip on the export-PDF button.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get resultExportPdf;

  /// Stat chip showing the number of stops.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 location} other{{count} locations}}'**
  String resultLocationsCount(int count);

  /// Forecast chip day label.
  ///
  /// In en, this message translates to:
  /// **'Day {num}'**
  String resultDayNum(int num);

  /// Link to view a stop on the map.
  ///
  /// In en, this message translates to:
  /// **'View on Maps'**
  String get resultViewOnMaps;

  /// Suffix appended when sharing a trip plan.
  ///
  /// In en, this message translates to:
  /// **'Planned with Lost in Egypt 🌍'**
  String get resultShareSuffix;

  /// Quiz next-step button.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get quizNext;

  /// Quiz final-step button.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get quizFinish;

  /// Quiz step counter.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String quizStepOf(int current, int total);

  /// Quiz step title: interests.
  ///
  /// In en, this message translates to:
  /// **'What are your interests?'**
  String get soloQuizInterestsTitle;

  /// Quiz step title: areas.
  ///
  /// In en, this message translates to:
  /// **'Where do you want to explore?'**
  String get soloQuizAreasTitle;

  /// Quiz step title: trip time.
  ///
  /// In en, this message translates to:
  /// **'Day trips or night out?'**
  String get soloQuizTripTimeTitle;

  /// Trip time option: day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get tripTimeDay;

  /// Description under the Day option.
  ///
  /// In en, this message translates to:
  /// **'Temples, markets,\nand outdoor adventures'**
  String get tripTimeDayDesc;

  /// Trip time option: night.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get tripTimeNight;

  /// Description under the Night option.
  ///
  /// In en, this message translates to:
  /// **'Dining, nightlife,\nand entertainment'**
  String get tripTimeNightDesc;

  /// Quiz step title: budget.
  ///
  /// In en, this message translates to:
  /// **'What\'s your budget?'**
  String get soloQuizBudgetTitle;

  /// Budget preset: budget tier.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetPresetBudget;

  /// Budget preset: mid-range tier.
  ///
  /// In en, this message translates to:
  /// **'Mid-range'**
  String get budgetPresetMid;

  /// Budget preset: luxury tier.
  ///
  /// In en, this message translates to:
  /// **'Luxury'**
  String get budgetPresetLuxury;

  /// Quiz step title: dates and location.
  ///
  /// In en, this message translates to:
  /// **'Choose your dates & location'**
  String get soloQuizDateTitle;

  /// Label on the from-date field.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get soloDateFrom;

  /// Hint in the from-date field.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get soloDateStartHint;

  /// Label on the to-date field.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get soloDateTo;

  /// Hint in the to-date field.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get soloDateEndHint;

  /// Nights pill between the date fields.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 night} other{{count} nights}}'**
  String soloNightsCount(int count);

  /// Hint in the location picker field.
  ///
  /// In en, this message translates to:
  /// **'Where are you starting from?'**
  String get soloStartLocationHint;

  /// Validation when no trip time is selected.
  ///
  /// In en, this message translates to:
  /// **'Please select Day, Night, or both.'**
  String get soloSelectDayNight;

  /// Max-attendees label on a tour card.
  ///
  /// In en, this message translates to:
  /// **'Up to {count}'**
  String tourCardUpTo(int count);

  /// Badge on a tour with no reviews yet.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get tourCardNew;

  /// Placeholder while reverse-geocoding a tapped point.
  ///
  /// In en, this message translates to:
  /// **'Fetching address...'**
  String get mapPickerFetching;

  /// Fallback name for a picked location.
  ///
  /// In en, this message translates to:
  /// **'Selected Location'**
  String get mapPickerSelectedLocation;

  /// Name when geocoding returns nothing.
  ///
  /// In en, this message translates to:
  /// **'Unknown Location'**
  String get mapPickerUnknownLocation;

  /// Hint in the map-picker search field.
  ///
  /// In en, this message translates to:
  /// **'Search for a landmark or destination...'**
  String get mapPickerSearchHint;

  /// Instruction shown before a point is picked.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere on the map to select a location'**
  String get mapPickerTapHint;

  /// Button to confirm the picked location.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get mapPickerConfirm;

  /// Fallback name returned for a custom pin.
  ///
  /// In en, this message translates to:
  /// **'Custom Pin Location'**
  String get mapPickerCustomPin;

  /// App bar title of the tour meetup map.
  ///
  /// In en, this message translates to:
  /// **'Meetup Location'**
  String get tourMapMeetupTitle;

  /// Marker info-window snippet for the meetup point.
  ///
  /// In en, this message translates to:
  /// **'Tour Start Point'**
  String get tourMapStartPoint;

  /// Label above the meetup location name.
  ///
  /// In en, this message translates to:
  /// **'Meeting Point'**
  String get tourMapMeetingPoint;

  /// Header above the destinations chips.
  ///
  /// In en, this message translates to:
  /// **'Destinations You Will Visit:'**
  String get tourMapDestinations;

  /// Button to open the meetup in the main map.
  ///
  /// In en, this message translates to:
  /// **'Explore in Main Map'**
  String get tourMapExplore;

  /// Button to plot the full tour route.
  ///
  /// In en, this message translates to:
  /// **'Navigate Tour Route'**
  String get tourMapNavigateRoute;

  /// App bar title of the QR check-in scanner.
  ///
  /// In en, this message translates to:
  /// **'Scan Ticket QR'**
  String get qrTitle;

  /// Instruction overlay on the scanner viewfinder.
  ///
  /// In en, this message translates to:
  /// **'Point camera at tourist\'s QR ticket'**
  String get qrPointCamera;

  /// Button to dismiss a result and resume scanning.
  ///
  /// In en, this message translates to:
  /// **'Scan Another'**
  String get qrScanAnother;

  /// Shown when a scanned booking ID has no document.
  ///
  /// In en, this message translates to:
  /// **'Booking not found'**
  String get qrBookingNotFound;

  /// Fallback tour title when the tour doc is missing.
  ///
  /// In en, this message translates to:
  /// **'Unknown Tour'**
  String get qrUnknownTour;

  /// Fallback tourist name when the user doc is missing.
  ///
  /// In en, this message translates to:
  /// **'Unknown Traveler'**
  String get qrUnknownTraveler;

  /// Validity badge for a confirmed, not-yet-checked-in ticket.
  ///
  /// In en, this message translates to:
  /// **'Valid Ticket'**
  String get qrValidTicket;

  /// Validity badge for a ticket in an invalid status (shown uppercased).
  ///
  /// In en, this message translates to:
  /// **'Invalid Ticket ({status})'**
  String qrInvalidTicket(String status);

  /// Validity badge when every ticket on the booking is scanned.
  ///
  /// In en, this message translates to:
  /// **'All Tickets Checked In'**
  String get qrAllCheckedIn;

  /// Validity badge when some but not all tickets are checked in.
  ///
  /// In en, this message translates to:
  /// **'Partially Checked In ({checked}/{total})'**
  String qrPartiallyCheckedIn(int checked, int total);

  /// Booking-sheet row label: tour name.
  ///
  /// In en, this message translates to:
  /// **'Tour'**
  String get qrRowTour;

  /// Booking-sheet row label: tour date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get qrRowDate;

  /// Booking-sheet row label: ticket count.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get qrRowTickets;

  /// Booking-sheet row label: amount paid.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get qrRowAmount;

  /// Booking-sheet row label: short booking reference.
  ///
  /// In en, this message translates to:
  /// **'Booking ID'**
  String get qrRowBookingId;

  /// Ticket quantity in the booking sheet.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ticket} other{{count} tickets}}'**
  String qrTicketsCount(int count);

  /// Suffix on the tickets row showing how many are already checked in.
  ///
  /// In en, this message translates to:
  /// **'{count} checked in'**
  String qrCheckedInCount(int count);

  /// Prompt above the partial check-in stepper.
  ///
  /// In en, this message translates to:
  /// **'Check in how many?'**
  String get qrCheckInHowMany;

  /// Check-in button for a single-ticket booking.
  ///
  /// In en, this message translates to:
  /// **'Check In Tourist'**
  String get qrCheckInTourist;

  /// Check-in button for a multi-ticket booking with a chosen quantity.
  ///
  /// In en, this message translates to:
  /// **'Check In {count} of {remaining} Remaining'**
  String qrCheckInRemaining(int count, int remaining);

  /// Success message when the booking becomes fully checked in.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Ticket checked in!} other{All {count} tickets checked in!}}'**
  String qrAllTicketsCheckedIn(int count);

  /// Success message after a partial check-in, with the number still remaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ticket checked in.} other{{count} tickets checked in.}}\n{remaining} remaining.'**
  String qrCheckedInResult(int count, int remaining);

  /// Generic No button.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// App bar title of the tour attendees screen.
  ///
  /// In en, this message translates to:
  /// **'Attendees'**
  String get attendeesTitle;

  /// Shown when the attendees stream errors.
  ///
  /// In en, this message translates to:
  /// **'Error loading attendees'**
  String get attendeesError;

  /// Hint under the attendees error about a missing Firestore index.
  ///
  /// In en, this message translates to:
  /// **'A Firestore index may be needed.\nCheck debug console for the link.'**
  String get attendeesIndexHint;

  /// Empty state title when a tour has no bookings.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet'**
  String get attendeesEmpty;

  /// Empty state subtitle for the attendees list.
  ///
  /// In en, this message translates to:
  /// **'When travelers book this tour,\nthey\'ll appear here.'**
  String get attendeesEmptySub;

  /// Summary stat label: confirmed bookings.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get attendeesStatConfirmed;

  /// Summary stat label: cancelled bookings.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get attendeesStatCancelled;

  /// Summary stat label: total bookings.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get attendeesStatTotal;

  /// Section header above confirmed attendees.
  ///
  /// In en, this message translates to:
  /// **'Confirmed ({count})'**
  String attendeesSectionConfirmed(int count);

  /// Section header above cancelled attendees.
  ///
  /// In en, this message translates to:
  /// **'Cancelled ({count})'**
  String attendeesSectionCancelled(int count);

  /// Fallback name when the attendee's user doc is missing.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get attendeesUnknownUser;

  /// Payment-status badge: paid.
  ///
  /// In en, this message translates to:
  /// **'PAID'**
  String get attendeesPaid;

  /// Payment-status badge: pending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get attendeesPending;

  /// Action button: call the attendee.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get attendeesCall;

  /// Action button: message the attendee on WhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get attendeesWhatsApp;

  /// Action button: email the attendee.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get attendeesEmail;

  /// Title/confirm button for the cancel-booking dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get attendeesCancelBooking;

  /// Body of the cancel-booking confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking? The traveler will be notified.'**
  String get attendeesCancelBody;

  /// App bar title of the guide dashboard.
  ///
  /// In en, this message translates to:
  /// **'Guide Dashboard'**
  String get guideDashTitle;

  /// Tooltip when live location sharing is on.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing live location'**
  String get guideDashStopSharing;

  /// Tooltip when live location sharing is off.
  ///
  /// In en, this message translates to:
  /// **'Share live location with tourists'**
  String get guideDashShareLocation;

  /// Tooltip for the QR scanner action.
  ///
  /// In en, this message translates to:
  /// **'Scan Ticket'**
  String get guideDashScanTicket;

  /// Empty state title when the guide has no tours.
  ///
  /// In en, this message translates to:
  /// **'No tours yet'**
  String get guideDashNoTours;

  /// Empty state subtitle prompting tour creation.
  ///
  /// In en, this message translates to:
  /// **'Create your first tour!'**
  String get guideDashCreateFirst;

  /// Section header above the guide's tour list.
  ///
  /// In en, this message translates to:
  /// **'Your Tours ({count})'**
  String guideDashYourTours(int count);

  /// Floating action button to create a new tour.
  ///
  /// In en, this message translates to:
  /// **'Create Tour'**
  String get guideDashCreateTour;

  /// Error shown when the earnings summary fails to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load earnings.\nCheck your connection and try again.'**
  String get guideDashEarningsError;

  /// Earnings summary stat: number of tours.
  ///
  /// In en, this message translates to:
  /// **'Tours'**
  String get guideDashStatTours;

  /// Earnings summary stat: number of bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get guideDashStatBookings;

  /// Earnings summary stat: total revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get guideDashStatRevenue;

  /// Max-attendees chip on a guide tour card.
  ///
  /// In en, this message translates to:
  /// **'{count} max'**
  String guideDashMax(int count);

  /// Error shown when a tour's booking count fails to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load bookings.'**
  String get guideDashBookingsError;

  /// Confirmed-bookings badge on a guide tour card.
  ///
  /// In en, this message translates to:
  /// **'📌 {count, plural, =1{1 confirmed booking} other{{count} confirmed bookings}}'**
  String guideDashConfirmedBookings(int count);

  /// Tour card action: view the tour.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get guideDashView;

  /// Title of the delete-tour confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete Tour'**
  String get guideDashDeleteTitle;

  /// Body of the delete-tour confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"? This cannot be undone.'**
  String guideDashDeleteBody(String title);

  /// Short weekday name: Monday.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMon;

  /// Short weekday name: Tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTue;

  /// Short weekday name: Wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWed;

  /// Short weekday name: Thursday.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThu;

  /// Short weekday name: Friday.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFri;

  /// Short weekday name: Saturday.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySat;

  /// Short weekday name: Sunday.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySun;

  /// App bar title when editing a tour.
  ///
  /// In en, this message translates to:
  /// **'Edit Tour'**
  String get createEditTitle;

  /// App bar title when creating a tour.
  ///
  /// In en, this message translates to:
  /// **'Create New Tour'**
  String get createNewTitle;

  /// Toast after a tour is updated.
  ///
  /// In en, this message translates to:
  /// **'Tour updated!'**
  String get createUpdatedToast;

  /// Toast after a tour is created.
  ///
  /// In en, this message translates to:
  /// **'Tour created successfully!'**
  String get createCreatedToast;

  /// Validation message for an empty required field.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get createRequired;

  /// Form field label: tour title.
  ///
  /// In en, this message translates to:
  /// **'Tour Title'**
  String get createFieldTitle;

  /// Form field label: tour description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get createFieldDesc;

  /// Section label above the destinations list.
  ///
  /// In en, this message translates to:
  /// **'Destinations (Max 5)'**
  String get createDestinationsLabel;

  /// Hint in the destination autocomplete field.
  ///
  /// In en, this message translates to:
  /// **'Search destination...'**
  String get createSearchDestination;

  /// Form field label: tour price in EGP.
  ///
  /// In en, this message translates to:
  /// **'Price (EGP)'**
  String get createFieldPrice;

  /// Form field label: maximum attendees.
  ///
  /// In en, this message translates to:
  /// **'Max Attendees'**
  String get createFieldMaxAttendees;

  /// Section header above the selected meeting location.
  ///
  /// In en, this message translates to:
  /// **'Meeting Location'**
  String get createMeetingLocation;

  /// Tile prompting the guide to pick a meeting location.
  ///
  /// In en, this message translates to:
  /// **'Select Meeting Location'**
  String get createSelectMeetingLocation;

  /// Tile prompting the guide to pick a meeting time.
  ///
  /// In en, this message translates to:
  /// **'Select Meeting Time'**
  String get createSelectMeetingTime;

  /// Tile showing the chosen meeting time.
  ///
  /// In en, this message translates to:
  /// **'Meeting Time: {time}'**
  String createMeetingTimePrefix(String time);

  /// Section label above the weekday chips.
  ///
  /// In en, this message translates to:
  /// **'Schedule Frequency (Days)'**
  String get createScheduleFreq;

  /// Section label above the image picker (create).
  ///
  /// In en, this message translates to:
  /// **'Tour Images'**
  String get createImages;

  /// Section label above the image picker (edit).
  ///
  /// In en, this message translates to:
  /// **'Edit Tour Images'**
  String get createEditImages;

  /// Submit button when editing a tour.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get createSaveChanges;

  /// Validation snackbar: no meeting time chosen.
  ///
  /// In en, this message translates to:
  /// **'Please select a meeting time.'**
  String get createSelectTime;

  /// Validation snackbar: no image selected.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one image.'**
  String get createSelectImage;

  /// Validation snackbar: no meeting location chosen.
  ///
  /// In en, this message translates to:
  /// **'Please select a meeting location on the map.'**
  String get createSelectLocation;

  /// Validation snackbar: no destination added.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one destination.'**
  String get createAddDestination;

  /// Validation snackbar: negative price.
  ///
  /// In en, this message translates to:
  /// **'Price cannot be negative.'**
  String get createPriceNegative;

  /// Validation snackbar: non-positive max attendees.
  ///
  /// In en, this message translates to:
  /// **'Max attendees must be greater than zero.'**
  String get createAttendeesZero;

  /// App bar title of the tours explorer.
  ///
  /// In en, this message translates to:
  /// **'Discover Tours'**
  String get toursDiscoverTitle;

  /// Hint in the tours explorer search field.
  ///
  /// In en, this message translates to:
  /// **'Search destinations, guides...'**
  String get toursSearchHint;

  /// Title of the tours filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get toursFilters;

  /// Filter section: price range.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get toursPriceRange;

  /// Filter section: minimum rating.
  ///
  /// In en, this message translates to:
  /// **'Minimum Rating'**
  String get toursMinRating;

  /// Label next to the star rating filter.
  ///
  /// In en, this message translates to:
  /// **'{count}+ stars'**
  String toursStarsPlus(int count);

  /// Filter section: tour frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get toursFrequency;

  /// Frequency option: daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get toursFreqDaily;

  /// Frequency option: weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get toursFreqWeekly;

  /// Frequency option: weekends.
  ///
  /// In en, this message translates to:
  /// **'Weekends'**
  String get toursFreqWeekends;

  /// Frequency option: one-time.
  ///
  /// In en, this message translates to:
  /// **'One-Time'**
  String get toursFreqOneTime;

  /// Button to apply the selected filters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get toursApplyFilters;

  /// Sort menu item: newest first.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get toursSortNewest;

  /// Sort menu item: cheapest first.
  ///
  /// In en, this message translates to:
  /// **'Cheapest First'**
  String get toursSortCheapest;

  /// Sort menu item: priciest first.
  ///
  /// In en, this message translates to:
  /// **'Priciest First'**
  String get toursSortPriciest;

  /// Sort menu item: highest rated.
  ///
  /// In en, this message translates to:
  /// **'Highest Rated'**
  String get toursSortHighestRated;

  /// Sort menu item: most popular.
  ///
  /// In en, this message translates to:
  /// **'Most Popular'**
  String get toursSortMostPopular;

  /// Sort chip label: newest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get toursSortLabelNewest;

  /// Sort chip label: cheapest.
  ///
  /// In en, this message translates to:
  /// **'Cheapest'**
  String get toursSortLabelCheapest;

  /// Sort chip label: priciest.
  ///
  /// In en, this message translates to:
  /// **'Priciest'**
  String get toursSortLabelPriciest;

  /// Sort chip label: top rated.
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get toursSortLabelTopRated;

  /// Sort chip label: popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get toursSortLabelPopular;

  /// Results count above the tour list.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 tour found} other{{count} tours found}}'**
  String toursFoundCount(int count);

  /// Error shown when the tour list fails to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load tours.\nCheck your connection and try again.'**
  String get toursLoadError;

  /// Empty state title for the tour list.
  ///
  /// In en, this message translates to:
  /// **'No tours found'**
  String get toursEmptyTitle;

  /// Empty state subtitle when filters are active.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters.'**
  String get toursEmptyFilters;

  /// Empty state subtitle when only a search is active.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search query.'**
  String get toursEmptySearch;

  /// Button to clear all active filters.
  ///
  /// In en, this message translates to:
  /// **'Clear All Filters'**
  String get toursClearFilters;

  /// Header above the personalised tour carousel.
  ///
  /// In en, this message translates to:
  /// **'Recommended for You'**
  String get toursRecommended;

  /// App bar title of the checkout screen.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get bookingCheckoutTitle;

  /// Snackbar shown when an unauthenticated user tries to book.
  ///
  /// In en, this message translates to:
  /// **'Please log in to book.'**
  String get bookingLoginRequired;

  /// Validation snackbar for an invalid wallet phone number.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid Egyptian mobile number (e.g. 01XXXXXXXXX).'**
  String get bookingInvalidWallet;

  /// Snackbar when no seats remain.
  ///
  /// In en, this message translates to:
  /// **'Sorry, this tour is now fully booked.'**
  String get bookingFullyBooked;

  /// Snackbar when fewer seats remain than requested.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Only 1 seat remaining. Please reduce your selection.} other{Only {count} seats remaining. Please reduce your selection.}}'**
  String bookingSeatsRemaining(int count);

  /// Snackbar when a card payment fails.
  ///
  /// In en, this message translates to:
  /// **'Payment was cancelled or failed.'**
  String get bookingPaymentFailed;

  /// Snackbar when a wallet payment fails.
  ///
  /// In en, this message translates to:
  /// **'Wallet payment failed.'**
  String get bookingWalletFailed;

  /// Snackbar for the not-yet-available kiosk option.
  ///
  /// In en, this message translates to:
  /// **'Kiosk payment coming soon!'**
  String get bookingKioskSoon;

  /// Snackbar prefix for a booking-creation failure.
  ///
  /// In en, this message translates to:
  /// **'Booking Error: {message}'**
  String bookingErrorPrefix(String message);

  /// Title of the booking-success dialog.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed!'**
  String get bookingConfirmedTitle;

  /// Body of the booking-success dialog.
  ///
  /// In en, this message translates to:
  /// **'Your spot on \"{title}\" is reserved!'**
  String bookingReservedBody(String title);

  /// Amount-paid line in the booking-success dialog.
  ///
  /// In en, this message translates to:
  /// **'{amount} paid successfully.'**
  String bookingPaidSuccess(String amount);

  /// Button to open booking history after success.
  ///
  /// In en, this message translates to:
  /// **'View My Bookings'**
  String get bookingViewMyBookings;

  /// Button to return to the home screen after success.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get bookingBackHome;

  /// Section title: order summary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get bookingOrderSummary;

  /// Quantity selector label.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get bookingGuests;

  /// Section title: payment method.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get bookingPaymentMethod;

  /// Payment option title: card.
  ///
  /// In en, this message translates to:
  /// **'Credit / Debit Card'**
  String get bookingPayCardTitle;

  /// Payment option subtitle: card networks.
  ///
  /// In en, this message translates to:
  /// **'Visa, Mastercard, Meeza'**
  String get bookingPayCardSub;

  /// Payment option title: mobile wallet.
  ///
  /// In en, this message translates to:
  /// **'Mobile Wallet'**
  String get bookingPayWalletTitle;

  /// Payment option subtitle: wallet providers.
  ///
  /// In en, this message translates to:
  /// **'Vodafone Cash, Orange, Etisalat'**
  String get bookingPayWalletSub;

  /// Payment option title: Apple Pay.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get bookingPayApplePayTitle;

  /// Payment option subtitle: Apple Pay status.
  ///
  /// In en, this message translates to:
  /// **'iOS only • Coming soon'**
  String get bookingPayApplePaySub;

  /// Payment option title: Fawry/kiosk.
  ///
  /// In en, this message translates to:
  /// **'Fawry / Kiosk'**
  String get bookingPayKioskTitle;

  /// Payment option subtitle: Fawry outlets.
  ///
  /// In en, this message translates to:
  /// **'Pay at any 172,000+ Fawry outlets'**
  String get bookingPayKioskSub;

  /// Label for the wallet phone-number field.
  ///
  /// In en, this message translates to:
  /// **'Wallet Phone Number'**
  String get bookingWalletPhoneLabel;

  /// Security reassurance under the payment options.
  ///
  /// In en, this message translates to:
  /// **'Payments are processed securely by Paymob. Your card details are never stored locally.'**
  String get bookingSecurityNote;

  /// Header above the similar-tours carousel on checkout.
  ///
  /// In en, this message translates to:
  /// **'Because you booked this, you might enjoy'**
  String get bookingBecauseBooked;

  /// Loading overlay text during payment.
  ///
  /// In en, this message translates to:
  /// **'Processing payment...'**
  String get bookingProcessing;

  /// Total label in the checkout bottom bar.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get bookingTotal;

  /// Note shown when paying in a non-EGP display currency.
  ///
  /// In en, this message translates to:
  /// **'Charged as EGP {amount} via Paymob'**
  String bookingChargedNote(String amount);

  /// Primary checkout button.
  ///
  /// In en, this message translates to:
  /// **'Pay Securely'**
  String get bookingPaySecurely;

  /// Popup menu item to report a tour.
  ///
  /// In en, this message translates to:
  /// **'Report Tour'**
  String get tourDetailReport;

  /// Rating label for a tour with no reviews.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get tourDetailNew;

  /// Info row label: tour date and time.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get tourDetailDateTime;

  /// Max-attendees value in the info grid.
  ///
  /// In en, this message translates to:
  /// **'{count} people'**
  String tourDetailPeople(int count);

  /// Info row label: meeting location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get tourDetailLocation;

  /// Section header: tour description.
  ///
  /// In en, this message translates to:
  /// **'About This Tour'**
  String get tourDetailAbout;

  /// Section header: destinations chips.
  ///
  /// In en, this message translates to:
  /// **'Destinations'**
  String get tourDetailDestinations;

  /// Section header: meetup map.
  ///
  /// In en, this message translates to:
  /// **'Meetup Location & Route'**
  String get tourDetailMeetupRoute;

  /// Hint overlay on the map preview.
  ///
  /// In en, this message translates to:
  /// **'Tap to expand'**
  String get tourDetailTapExpand;

  /// Section header: schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get tourDetailSchedule;

  /// Section header: image gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get tourDetailGallery;

  /// Section header / fallback name for the guide.
  ///
  /// In en, this message translates to:
  /// **'Your Guide'**
  String get tourDetailYourGuide;

  /// Header above the similar-tours carousel.
  ///
  /// In en, this message translates to:
  /// **'You might also enjoy'**
  String get tourDetailYouMightEnjoy;

  /// Disabled bottom button when the viewer owns the tour.
  ///
  /// In en, this message translates to:
  /// **'This is your tour'**
  String get tourDetailYourTour;

  /// Primary booking button.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get tourDetailBookNow;

  /// Schedule text for a one-time tour.
  ///
  /// In en, this message translates to:
  /// **'This is a one-time tour.'**
  String get tourDetailOneTime;

  /// Fallback when the guide doc is missing.
  ///
  /// In en, this message translates to:
  /// **'Guide not found'**
  String get tourDetailGuideNotFound;

  /// Guide rating subtitle.
  ///
  /// In en, this message translates to:
  /// **'{rating} ({count} reviews)'**
  String tourDetailGuideRating(String rating, int count);

  /// Reviews section header.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get tourDetailReviews;

  /// Button/dialog title to add a review.
  ///
  /// In en, this message translates to:
  /// **'Write a Review'**
  String get tourDetailWriteReview;

  /// Shown when the reviews stream errors.
  ///
  /// In en, this message translates to:
  /// **'Error loading reviews'**
  String get tourDetailReviewsError;

  /// Empty state for the reviews list.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet. Be the first to review!'**
  String get tourDetailNoReviews;

  /// Pagination button for reviews.
  ///
  /// In en, this message translates to:
  /// **'Show more reviews'**
  String get tourDetailShowMore;

  /// Fallback reviewer name.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get tourDetailAnonymous;

  /// Menu item / dialog title to edit a review.
  ///
  /// In en, this message translates to:
  /// **'Edit Review'**
  String get tourDetailEditReview;

  /// Menu item / dialog title to delete a review.
  ///
  /// In en, this message translates to:
  /// **'Delete Review'**
  String get tourDetailDeleteReview;

  /// Menu item to report a review.
  ///
  /// In en, this message translates to:
  /// **'Report Review'**
  String get tourDetailReportReview;

  /// Hint in the edit-review text field.
  ///
  /// In en, this message translates to:
  /// **'Update your experience...'**
  String get tourDetailUpdateHint;

  /// Confirm button in the edit-review dialog.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get tourDetailUpdate;

  /// Body of the delete-review confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your review? This action cannot be undone.'**
  String get tourDetailDeleteReviewBody;

  /// Hint in the add-review text field.
  ///
  /// In en, this message translates to:
  /// **'Share your experience...'**
  String get tourDetailShareHint;

  /// Confirm button in the add-review dialog.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get tourDetailSubmit;

  /// Generic pagination button.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get commonLoadMore;

  /// Booking status badge: confirmed.
  ///
  /// In en, this message translates to:
  /// **'CONFIRMED'**
  String get bookingStatusConfirmed;

  /// Booking status badge: cancelled.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get bookingStatusCancelled;

  /// Booking status badge: pending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get bookingStatusPending;

  /// Booking status badge: completed.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get bookingStatusCompleted;

  /// Booking status badge: checked in.
  ///
  /// In en, this message translates to:
  /// **'CHECKED IN'**
  String get bookingStatusCheckedIn;

  /// Booking status badge: partially checked in.
  ///
  /// In en, this message translates to:
  /// **'PARTIALLY CHECKED IN'**
  String get bookingStatusPartial;

  /// App bar title of the booking history screen.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get bookingHistTitle;

  /// Shown when no user is signed in.
  ///
  /// In en, this message translates to:
  /// **'Please log in'**
  String get bookingHistLoginRequired;

  /// Tab label: upcoming bookings.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get bookingHistUpcoming;

  /// Tab label: past bookings.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get bookingHistPast;

  /// Error shown when the bookings stream fails.
  ///
  /// In en, this message translates to:
  /// **'Could not load bookings.\nCheck your connection and try again.'**
  String get bookingHistLoadError;

  /// Empty state for the upcoming tab.
  ///
  /// In en, this message translates to:
  /// **'No upcoming tours'**
  String get bookingHistNoUpcoming;

  /// Empty state for the past tab.
  ///
  /// In en, this message translates to:
  /// **'No past tours'**
  String get bookingHistNoPast;

  /// Empty-state hint on the upcoming tab.
  ///
  /// In en, this message translates to:
  /// **'Explore tours and book your next adventure!'**
  String get bookingHistEmptyHint;

  /// Placeholder when a booking has no date.
  ///
  /// In en, this message translates to:
  /// **'TBD'**
  String get bookingHistTbd;

  /// Countdown when days remain.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}} {hours}h {minutes}m'**
  String bookingHistCountdownDHM(int days, int hours, int minutes);

  /// Countdown when only hours remain.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m {seconds}s'**
  String bookingHistCountdownHMS(int hours, int minutes, int seconds);

  /// Countdown when under an hour remains.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m {seconds}s'**
  String bookingHistCountdownMS(int minutes, int seconds);

  /// Countdown banner wrapper.
  ///
  /// In en, this message translates to:
  /// **'Starts in {time}'**
  String bookingHistStartsIn(String time);

  /// Body of the tourist-side cancel-booking dialog.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking?'**
  String get bookingHistCancelBody;

  /// Confirm button in the cancel-booking dialog.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get bookingHistYesCancel;

  /// Snackbar after a booking is cancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get bookingHistCancelled;

  /// Snackbar after a review is submitted.
  ///
  /// In en, this message translates to:
  /// **'Review submitted!'**
  String get bookingHistReviewSubmitted;

  /// Snackbar when the guide has no phone number.
  ///
  /// In en, this message translates to:
  /// **'No phone number on file'**
  String get bookingHistNoPhone;

  /// Snackbar when the guide has no email.
  ///
  /// In en, this message translates to:
  /// **'No email on file'**
  String get bookingHistNoEmail;

  /// Snackbar when the dialer can't be launched.
  ///
  /// In en, this message translates to:
  /// **'Could not open phone app'**
  String get bookingHistCantOpenPhone;

  /// Snackbar when the email app can't be launched.
  ///
  /// In en, this message translates to:
  /// **'Could not open email app'**
  String get bookingHistCantOpenEmail;

  /// Sheet title / button to leave a review.
  ///
  /// In en, this message translates to:
  /// **'Leave a Review'**
  String get bookingHistLeaveReview;

  /// Submit button in the leave-review sheet.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get bookingHistSubmitReview;

  /// Expander to show the QR ticket.
  ///
  /// In en, this message translates to:
  /// **'View QR Ticket'**
  String get bookingHistViewQr;

  /// Short booking reference under the QR code.
  ///
  /// In en, this message translates to:
  /// **'Booking ID: {id}'**
  String bookingHistBookingId(String id);

  /// Hint under the QR ticket.
  ///
  /// In en, this message translates to:
  /// **'Show this to your guide upon arrival'**
  String get bookingHistShowGuide;

  /// Tile title to open the meeting point in the map.
  ///
  /// In en, this message translates to:
  /// **'View Meeting Point'**
  String get bookingHistViewMeeting;

  /// Tile subtitle for the meeting-point action.
  ///
  /// In en, this message translates to:
  /// **'Opens in Map tab'**
  String get bookingHistOpensMap;

  /// Fallback guide name for the live-tracking sheet.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get bookingHistGuide;

  /// Tile title for live guide tracking.
  ///
  /// In en, this message translates to:
  /// **'Track Guide Live'**
  String get bookingHistTrackGuide;

  /// Tile subtitle for live guide tracking.
  ///
  /// In en, this message translates to:
  /// **'See your guide\'s real-time location'**
  String get bookingHistTrackGuideSub;

  /// Info row label: total paid.
  ///
  /// In en, this message translates to:
  /// **'Total paid'**
  String get bookingHistTotalPaid;

  /// Info row label: payment reference.
  ///
  /// In en, this message translates to:
  /// **'Payment ref'**
  String get bookingHistPaymentRef;

  /// Action chip: add booking to calendar.
  ///
  /// In en, this message translates to:
  /// **'Add to Calendar'**
  String get bookingHistAddCalendar;

  /// Action chip: share the ticket.
  ///
  /// In en, this message translates to:
  /// **'Share Ticket'**
  String get bookingHistShareTicket;

  /// Action chip: call the guide.
  ///
  /// In en, this message translates to:
  /// **'Call Guide'**
  String get bookingHistCallGuide;

  /// Action chip: email the guide.
  ///
  /// In en, this message translates to:
  /// **'Email Guide'**
  String get bookingHistEmailGuide;

  /// Button to book the tour again.
  ///
  /// In en, this message translates to:
  /// **'Re-book This Tour'**
  String get bookingHistRebook;

  /// Subtitle for a guide with no reviews.
  ///
  /// In en, this message translates to:
  /// **'New Guide'**
  String get bookingHistNewGuide;

  /// Label above the tour-day weather.
  ///
  /// In en, this message translates to:
  /// **'Weather on tour day'**
  String get bookingHistWeatherDay;

  /// Title of the live guide-location sheet.
  ///
  /// In en, this message translates to:
  /// **'{name} – Live Location'**
  String bookingHistLiveLocation(String name);

  /// Overlay while the guide hasn't shared location yet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for guide to share their location…'**
  String get bookingHistWaitingLocation;

  /// Calendar event title.
  ///
  /// In en, this message translates to:
  /// **'Lost in Egypt: {title}'**
  String bookingHistCalTitle(String title);

  /// Calendar event description.
  ///
  /// In en, this message translates to:
  /// **'Meeting point: {location}\nBooking ID: {id}'**
  String bookingHistCalDesc(String location, String id);

  /// Shared ticket text (native share sheet).
  ///
  /// In en, this message translates to:
  /// **'🏺 Lost in Egypt – Tour Ticket\n\nTour: {title}\nDate: {date}\nMeeting point: {location}\nTickets: {tickets}\nBooking ref: {ref}\n\nSee you there!'**
  String bookingHistShareText(
    String title,
    String date,
    String location,
    int tickets,
    String ref,
  );

  /// Camera header in landmark-lens mode.
  ///
  /// In en, this message translates to:
  /// **'Lens'**
  String get cameraLens;

  /// Camera header in AR-translation mode.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get cameraTranslation;

  /// Header of the translation results panel.
  ///
  /// In en, this message translates to:
  /// **'Translation Result'**
  String get cameraTranslationResult;

  /// Shown when no landmark is recognised.
  ///
  /// In en, this message translates to:
  /// **'Could not identify any landmark'**
  String get cameraNoLandmark;

  /// Shown when a landmark is recognised but missing from the database.
  ///
  /// In en, this message translates to:
  /// **'We found \"{label}\" but it\'s not in our database'**
  String cameraNotInDb(String label);

  /// Error title for an API-key/configuration problem.
  ///
  /// In en, this message translates to:
  /// **'Configuration Error'**
  String get cameraConfigError;

  /// Generic camera error title.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get cameraErrorTitle;

  /// Badge label in the result sheet.
  ///
  /// In en, this message translates to:
  /// **'Landmark Identified'**
  String get cameraLandmarkIdentified;

  /// Weather advisory chip in the landmark result sheet.
  ///
  /// In en, this message translates to:
  /// **'{condition} · Tap for forecast'**
  String cameraTapForecast(String condition);

  /// Expand the landmark description.
  ///
  /// In en, this message translates to:
  /// **'Read More'**
  String get cameraReadMore;

  /// Collapse the landmark description.
  ///
  /// In en, this message translates to:
  /// **'Read Less'**
  String get cameraReadLess;

  /// Button to generate an AI story for the landmark.
  ///
  /// In en, this message translates to:
  /// **'Tell me a story'**
  String get cameraTellStory;

  /// Loading label while the AI story is generated.
  ///
  /// In en, this message translates to:
  /// **'Consulting history...'**
  String get cameraConsulting;

  /// Play the narrated story.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get cameraListen;

  /// Pause the narration.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get cameraPause;

  /// Resume the narration.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get cameraResume;

  /// Loading label while narration audio is generated.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get cameraGenerating;

  /// Tooltip to replay the narration from the beginning.
  ///
  /// In en, this message translates to:
  /// **'Replay from start'**
  String get cameraReplay;

  /// Snackbar when TTS audio generation fails.
  ///
  /// In en, this message translates to:
  /// **'Could not generate audio. Please try again.'**
  String get cameraAudioGenFailed;

  /// Snackbar when narration playback fails.
  ///
  /// In en, this message translates to:
  /// **'Audio playback failed. Please try again.'**
  String get cameraAudioPlayFailed;

  /// Open the identified landmark in the map tab.
  ///
  /// In en, this message translates to:
  /// **'Show on Map'**
  String get cameraShowOnMap;

  /// Dismiss the landmark result sheet.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get cameraDone;

  /// Header above nearby-landmark suggestions.
  ///
  /// In en, this message translates to:
  /// **'You might also like nearby'**
  String get cameraNearby;

  /// Title of the Sphinx riddle easter-egg dialog.
  ///
  /// In en, this message translates to:
  /// **'The Sphinx\'s Riddle 🦁'**
  String get sphinxRiddleTitle;

  /// Sphinx dialog title on a correct answer.
  ///
  /// In en, this message translates to:
  /// **'You May Pass 🦁'**
  String get sphinxPassTitle;

  /// Sphinx dialog title on a wrong answer.
  ///
  /// In en, this message translates to:
  /// **'Incorrect, Mortal 🌪️'**
  String get sphinxFailTitle;

  /// The Sphinx's riddle question.
  ///
  /// In en, this message translates to:
  /// **'\"What walks on four legs in the morning, two at noon, and three in the evening?\"'**
  String get sphinxRiddleBody;

  /// Sphinx dialog body on a correct answer.
  ///
  /// In en, this message translates to:
  /// **'Your wisdom equals the ancients. The Sphinx permits your journey to continue.'**
  String get sphinxPassBody;

  /// Sphinx dialog body on a wrong answer.
  ///
  /// In en, this message translates to:
  /// **'The sands of time will swallow your ignorance. Return when you have learned.'**
  String get sphinxFailBody;

  /// Wrong answer option in the Sphinx riddle.
  ///
  /// In en, this message translates to:
  /// **'An Animal'**
  String get sphinxAnswerAnimal;

  /// Correct answer option in the Sphinx riddle.
  ///
  /// In en, this message translates to:
  /// **'A Human'**
  String get sphinxAnswerHuman;

  /// Title of the map trip-planner sheet.
  ///
  /// In en, this message translates to:
  /// **'Trip Planner'**
  String get tripPlannerTitle;

  /// Button to start the planned trip.
  ///
  /// In en, this message translates to:
  /// **'Start Trip'**
  String get tripPlannerStart;

  /// Loading label while the route is being optimised.
  ///
  /// In en, this message translates to:
  /// **'Optimising...'**
  String get tripPlannerOptimising;

  /// Hint in the trip-planner search field.
  ///
  /// In en, this message translates to:
  /// **'Search places to add…'**
  String get tripPlannerSearchHint;

  /// Info chip showing how many stops are in the itinerary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 stop — route will be optimised by shortest distance} other{{count} stops — route will be optimised by shortest distance}}'**
  String tripPlannerStopsInfo(int count);

  /// Empty-state title for the trip planner.
  ///
  /// In en, this message translates to:
  /// **'Plan your day in Egypt'**
  String get tripPlannerEmptyTitle;

  /// Empty-state subtitle for the trip planner.
  ///
  /// In en, this message translates to:
  /// **'Search above or pick from suggestions below'**
  String get tripPlannerEmptySub;

  /// Header for AI suggestions when the itinerary is empty.
  ///
  /// In en, this message translates to:
  /// **'Suggested for you'**
  String get tripPlannerSuggested;

  /// Button to add a suggested place to the itinerary.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get tripPlannerAdd;

  /// Snackbar when an unauthenticated user tries to save a place.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to save places.'**
  String get placeDetailLoginToSave;

  /// Distance label in metres.
  ///
  /// In en, this message translates to:
  /// **'{meters} m away'**
  String placeDetailMetersAway(int meters);

  /// Distance label in kilometres (pre-formatted).
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String placeDetailKmAway(String km);

  /// Estimated taxi fare range.
  ///
  /// In en, this message translates to:
  /// **'~{low}–{high} EGP by taxi'**
  String placeDetailTaxiFare(int low, int high);

  /// Opening-status label: open.
  ///
  /// In en, this message translates to:
  /// **'Open Now'**
  String get placeDetailOpenNow;

  /// Opening-status label: closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get placeDetailClosed;

  /// Button to collapse the place detail sheet.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get placeDetailClose;

  /// Action button: get directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get placeDetailDirections;

  /// Action button: share the place.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get placeDetailShare;

  /// Action button label when the place is saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get placeDetailSaved;

  /// Section header: about the place.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get placeDetailAbout;

  /// Fallback description when a place has none.
  ///
  /// In en, this message translates to:
  /// **'Explore the ancient wonders and hidden gems of Egypt. This location offers a unique glimpse into the rich history and culture of the region.'**
  String get placeDetailDefaultDesc;

  /// Info tile: entry fee in EGP.
  ///
  /// In en, this message translates to:
  /// **'{price} EGP Entry Fee'**
  String placeDetailEntryFee(String price);

  /// Section header: reviews.
  ///
  /// In en, this message translates to:
  /// **'What Travelers Say'**
  String get placeDetailReviews;

  /// Community-posts count for this place.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 traveler posted from here} other{{count} travelers posted from here}}'**
  String placeDetailPostedHere(int count);

  /// Button to open community posts from this place.
  ///
  /// In en, this message translates to:
  /// **'See Posts'**
  String get placeDetailSeePosts;

  /// Section header: similar places.
  ///
  /// In en, this message translates to:
  /// **'Similar Places'**
  String get placeDetailSimilar;

  /// Crowd badge: low density.
  ///
  /// In en, this message translates to:
  /// **'Quiet right now'**
  String get placeDetailCrowdQuiet;

  /// Crowd badge: medium density.
  ///
  /// In en, this message translates to:
  /// **'Moderately busy'**
  String get placeDetailCrowdModerate;

  /// Crowd badge: high density.
  ///
  /// In en, this message translates to:
  /// **'Very busy'**
  String get placeDetailCrowdBusy;

  /// Title of the community-posts sheet for a place.
  ///
  /// In en, this message translates to:
  /// **'Posts from {name}'**
  String placeDetailPostsFrom(String name);

  /// Empty state for the place's community posts.
  ///
  /// In en, this message translates to:
  /// **'No posts yet from this place.\nBe the first to share!'**
  String get placeDetailNoPosts;

  /// Map loading overlay title.
  ///
  /// In en, this message translates to:
  /// **'Discovering Egypt...'**
  String get mapDiscovering;

  /// Map loading overlay subtitle.
  ///
  /// In en, this message translates to:
  /// **'Loading places near you'**
  String get mapLoadingNearby;

  /// Title of the navigation-arrival dialog.
  ///
  /// In en, this message translates to:
  /// **'You\'ve Arrived!'**
  String get mapArrivedTitle;

  /// Body of the navigation-arrival dialog.
  ///
  /// In en, this message translates to:
  /// **'You have arrived at {name}'**
  String mapArrivedBody(String name);

  /// Mini-FAB label: open the trip planner.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get mapFabTrip;

  /// Mini-FAB label: nearby places.
  ///
  /// In en, this message translates to:
  /// **'Near Me'**
  String get mapFabNearMe;

  /// Mini-FAB label: saved places.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get mapFabSaved;

  /// Trip-progress label showing the current stop index.
  ///
  /// In en, this message translates to:
  /// **'Stop {current} of {total}'**
  String mapStopOf(int current, int total);

  /// Button to advance to the next trip stop.
  ///
  /// In en, this message translates to:
  /// **'Next Stop'**
  String get mapNextStop;

  /// Button to finish a planned trip.
  ///
  /// In en, this message translates to:
  /// **'Done! 🎉'**
  String get mapTripDone;

  /// Button to return to the active solo tour.
  ///
  /// In en, this message translates to:
  /// **'Back to Tour'**
  String get mapBackToTour;

  /// Loading label while a route is being computed.
  ///
  /// In en, this message translates to:
  /// **'Finding route...'**
  String get mapFindingRoute;

  /// Overall route distance + duration during live navigation.
  ///
  /// In en, this message translates to:
  /// **'{distance} · {duration} total'**
  String mapEtaTotal(String distance, String duration);

  /// Turn-by-turn step counter.
  ///
  /// In en, this message translates to:
  /// **'Step {current}/{total}'**
  String mapStepProgress(int current, int total);

  /// Badge on an AI-suggested place nudge card.
  ///
  /// In en, this message translates to:
  /// **'AI PICK'**
  String get mapAiPick;

  /// Generic loading label.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// Hint in the map search bar.
  ///
  /// In en, this message translates to:
  /// **'Search places...'**
  String get mapSearchHint;

  /// Empty state in map search results.
  ///
  /// In en, this message translates to:
  /// **'No places found'**
  String get mapNoPlacesFound;

  /// Travel mode: driving.
  ///
  /// In en, this message translates to:
  /// **'Drive'**
  String get mapModeDrive;

  /// Travel mode: walking.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get mapModeWalk;

  /// Travel mode: public transit.
  ///
  /// In en, this message translates to:
  /// **'Transit'**
  String get mapModeTransit;

  /// Number of turn-by-turn steps in a route.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 step} other{{count} steps}}'**
  String mapStepsCount(int count);

  /// Button to begin turn-by-turn navigation.
  ///
  /// In en, this message translates to:
  /// **'Start Navigation'**
  String get mapStartNavigation;

  /// Title of the route-steps sheet.
  ///
  /// In en, this message translates to:
  /// **'Route Steps'**
  String get mapRouteSteps;

  /// Final step in the route-steps list.
  ///
  /// In en, this message translates to:
  /// **'Arrive at destination'**
  String get mapArriveDestination;

  /// Easter-egg overlay text.
  ///
  /// In en, this message translates to:
  /// **'CURSE RELEASED'**
  String get mapCurseReleased;

  /// Title of the map filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Filter by Category'**
  String get mapFilterByCategory;

  /// Filter-sheet status pill: zoom filter active.
  ///
  /// In en, this message translates to:
  /// **'Zoom Filter ON'**
  String get mapZoomFilterOn;

  /// Filter-sheet status pill: a category is selected.
  ///
  /// In en, this message translates to:
  /// **'Showing All'**
  String get mapShowingAll;

  /// Visible-vs-total places counter on the map.
  ///
  /// In en, this message translates to:
  /// **'{visible}/{total} places'**
  String mapPlacesCount(int visible, int total);

  /// Filter-sheet subtitle for the All category.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 place • Zoom to see more} other{{count} places • Zoom to see more}}'**
  String mapCatPlacesZoom(int count);

  /// Filter-sheet subtitle for the Favorites category.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 saved place} other{{count} saved places}}'**
  String mapCatSavedPlaces(int count);

  /// Filter-sheet subtitle: places in a category.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 place} other{{count} places}}'**
  String mapCatPlaces(int count);

  /// Filter category: all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get mapCatAll;

  /// Filter category: favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get mapCatFavorites;

  /// Filter category: open now.
  ///
  /// In en, this message translates to:
  /// **'Open Now'**
  String get mapCatOpenNow;

  /// Filter category: tourism.
  ///
  /// In en, this message translates to:
  /// **'Tourism'**
  String get mapCatTourism;

  /// Filter category: historical.
  ///
  /// In en, this message translates to:
  /// **'Historical'**
  String get mapCatHistorical;

  /// Filter category: museums.
  ///
  /// In en, this message translates to:
  /// **'Museums'**
  String get mapCatMuseums;

  /// Filter category: hotels.
  ///
  /// In en, this message translates to:
  /// **'Hotels'**
  String get mapCatHotels;

  /// Filter category: religious.
  ///
  /// In en, this message translates to:
  /// **'Religious'**
  String get mapCatReligious;

  /// Filter category: food & dining.
  ///
  /// In en, this message translates to:
  /// **'Food & Dining'**
  String get mapCatFood;

  /// Filter category: nature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get mapCatNature;

  /// Filter category: entertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get mapCatEntertainment;

  /// Filter category: shopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get mapCatShopping;
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
