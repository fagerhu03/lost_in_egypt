/// ✅ Centralized string domain to avoid hardcoded strings
class AppStrings {
  // ===== GENERAL =====
  static const String appName = 'Lost in Egypt';
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String cancel = 'Cancel';
  static const String ok = 'OK';
  static const String retry = 'Retry';
  static const String back = 'Back';
  static const String save = 'Save';
  static const String submit = 'Submit';

  // ===== AUTHENTICATION =====
  static const String login = 'Login';
  static const String signup = 'Sign Up';
  static const String signout = 'Sign out';
  static const String forgotPassword = 'Forgot Password?';
  static const String dontHaveAccount = 'Don\'t have an account?';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String newPassword = 'New Password';
  static const String firstName = 'First Name';
  static const String lastName = 'Last Name';
  static const String phoneNumber = 'Phone Number';
  static const String enterEmail = 'Enter your email';
  static const String enterPassword = 'Enter your password';
  static const String enterFirstName = 'Enter first name';
  static const String enterLastName = 'Enter last name';
  static const String selectDOB = 'Select Date of Birth';
  static const String termsAccepted = 'I agree to the Terms & Conditions';

  // ===== VALIDATION MESSAGES =====
  static const String requiredField = 'This field is required';
  static const String invalidEmail = 'Please enter a valid email address';
  static const String passwordMismatch = 'Passwords do not match';
  static const String passwordWeak =
      'Password must be 8+ chars with letters and numbers';
  static const String nameTooShort = 'Name must be at least 2 characters';
  static const String invalidPhone = 'Please enter a valid phone number';
  static const String minAge = 'You must be at least 16 years old to sign up';
  static const String emailExists = 'This email is already registered';
  static const String invalidPassword = 'Invalid password';

  // ===== NETWORK & ERRORS =====
  static const String noInternet =
      'No internet connection. Please check your network.';
  static const String networkError =
      'Network error occurred. Please try again.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unexpectedError = 'An unexpected error occurred.';
  static const String timeoutError = 'Request timed out. Please try again.';
  static const String permissionDenied =
      'You do not have permission to perform this action.';
  static const String accountDisabled = 'This account has been disabled.';
  static const String contactSupport = 'Please contact support.';

  // ===== SUCCESS MESSAGES =====
  static const String loginSuccess = 'Welcome back!';
  static const String signupSuccess = 'Account created successfully!';
  static const String passwordResetSuccess = 'Password reset successfully!';
  static const String profileUpdated = 'Profile updated successfully!';
  static const String phoneVerified = 'Phone verified successfully!';
  static const String postCreated = 'Post created successfully!';
  static const String postDeleted = 'Post deleted successfully!';

  // ===== HOME SCREEN =====
  static const String home = 'Home';
  static const String featuredPlaces = 'Featured Places';
  static const String exploreMore = 'Explore More';

  // ===== COMMUNITY =====
  static const String community = 'Community';
  static const String createPost = 'Create a Post';
  static const String writePost = 'Share your thoughts...';
  static const String addImages = 'Add Images';
  static const String tagLocation = 'Tag Location';
  static const String post = 'Post';
  static const String postCreating = 'Creating post...';
  static const String likes = 'Likes';
  static const String comments = 'Comments';
  static const String report = 'Report';
  static const String delete = 'Delete';
  static const String edit = 'Edit';

  // ===== MAP =====
  static const String map = 'Map';
  static const String allPlaces = 'All Places';
  static const String noMarkersFound = 'No markers found for this category';
  static const String locationPermission =
      'Location permission is required to use maps';

  // ===== CAMERA =====
  static const String camera = 'Camera';
  static const String landmark = 'Landmark';
  static const String identifyLandmark = 'Identify Landmark';
  static const String landmarkIdentified = 'Landmark Identified';
  static const String viewDetails = 'View Details';

  // ===== ACCOUNT =====
  static const String account = 'Account';
  static const String editProfile = 'Edit Profile';
  static const String settings = 'Settings';
  static const String places = 'Places';
  static const String cardsDetail = 'Cards Detail';
  static const String registeredTours = 'Registered tours';
  static const String yourPlan = 'Your plan';
  static const String nationality = 'Nationality';

  // ===== MORE =====
  static const String more = 'More';
  static const String currency = 'Currency';
  static const String help = 'Help';
  static const String translator = 'Translator';
  static const String contactUs = 'Contact us';

  // ===== ONBOARDING =====
  static const String welcome = 'Welcome to Egypt';
  static const String welcomeSubtitle = 'Where every street tells a story';
  static const String startExploring = 'START EXPLORING';
  static const String skip = 'Skip';
  static const String next = 'Next';

  // ===== PHONE VERIFICATION =====
  static const String verifyPhone = 'Verify Phone Number';
  static const String enterPhone = 'Enter your phone number';
  static const String sendCode = 'Send Code';
  static const String enterOTP = 'Enter OTP';
  static const String verify = 'Verify';
  static const String resendCode = 'Resend Code';
  static const String codeExpiring = 'Code expires in';
  static const String phoneVerificationRequired =
      'Phone verification is required to post';

  // ===== NOTIFICATIONS =====
  static const String notifications = 'Notifications';
  static const String enableNotifications = 'Enable Notifications';
  static const String disableNotifications = 'Disable Notifications';
}
