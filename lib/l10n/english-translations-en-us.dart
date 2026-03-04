/// English translations for the Flowering app
const Map<String, String> enUS = {
  // Common
  'app_name': 'Flowering',
  'loading': 'Loading...',
  'error': 'Error',
  'success': 'Success',
  'cancel': 'Cancel',
  'confirm': 'Confirm',
  'save': 'Save',
  'delete': 'Delete',
  'edit': 'Edit',
  'retry': 'Try Again',
  'ok': 'OK',
  'yes': 'Yes',
  'no': 'No',

  // Auth
  'login': 'Login',
  'register': 'Register',
  'logout': 'Logout',
  'email': 'Email',
  'password': 'Password',
  'confirm_password': 'Confirm Password',
  'forgot_password': 'Forgot Password?',
  'dont_have_account': "Don't have an account?",
  'already_have_account': 'Already have an account?',
  'login_success': 'Welcome back!',
  'register_success': 'Account created successfully!',
  'logout_confirm': 'Are you sure you want to logout?',

  // Validation
  'email_required': 'Email is required',
  'email_invalid': 'Please enter a valid email',
  'password_required': 'Password is required',
  'password_min_length': 'Password must be at least 8 characters',
  'passwords_not_match': 'Passwords do not match',

  // Home
  'home': 'Home',
  'welcome': 'Welcome',
  'continue_learning': 'Continue Learning',
  'daily_goal': 'Daily Goal',
  'streak': 'Day Streak',

  // Chat
  'chat': 'Chat',
  'new_chat': 'New Chat',
  'type_message': 'Type a message...',
  'send': 'Send',
  'voice_message': 'Voice Message',
  'recording': 'Recording...',
  'tap_to_record': 'Tap to record',
  'hold_to_record': 'Hold to record',

  // Lessons
  'lessons': 'Lessons',
  'lesson': 'Lesson',
  'start_lesson': 'Start Lesson',
  'continue_lesson': 'Continue',
  'completed': 'Completed',
  'in_progress': 'In Progress',
  'not_started': 'Not Started',
  'lesson_completed': 'Lesson Completed!',

  // Profile
  'profile': 'Profile',
  'my_profile': 'My Profile',
  'statistics': 'Statistics',
  'total_lessons': 'Total Lessons',
  'study_time': 'Study Time',
  'words_learned': 'Words Learned',
  'accuracy': 'Accuracy',

  // Settings
  'settings': 'Settings',
  'language': 'Language',
  'notifications': 'Notifications',
  'sound': 'Sound',
  'dark_mode': 'Dark Mode',
  'clear_cache': 'Clear Cache',
  'cache_cleared': 'Cache cleared successfully',
  'storage_usage': 'Storage Usage',
  'about': 'About',
  'version': 'Version',
  'privacy_policy': 'Privacy Policy',
  'terms_of_service': 'Terms of Service',

  // Bottom Navigation
  'nav_chat': 'Chat',
  'nav_read': 'Read',
  'nav_vocabulary': 'Vocabulary',
  'nav_profile': 'Profile',

  // Chat Home
  'chat_home_title': 'Conversations',
  'chat_home_empty': 'No conversations yet',
  'chat_home_start': 'Start a new chat',

  // Read
  'read_title': 'Reading',
  'read_empty': 'No lessons available',

  // Vocabulary
  'vocabulary_title': 'Vocabulary',
  'vocabulary_search': 'Search words...',
  'vocabulary_empty': 'No words learned yet',

  // Errors
  'network_error': 'Please check your internet connection',
  'server_error': 'Something went wrong. Please try again later',
  'session_expired': 'Session expired. Please login again',
  'unknown_error': 'An unknown error occurred',

  // Offline
  'offline': 'You are offline',
  'offline_mode': 'Offline Mode',
  'sync_pending': 'Changes will sync when online',

  // Onboarding — AI Chat (Screen 07)
  'chat_session_error': 'Could not start session. Please try again.',
  'chat_session_expired': 'Session expired. Please restart onboarding.',
  'chat_retry': 'Retry',
  'chat_leave_confirm': 'Leave conversation?',
  'chat_leave_message': 'Your progress will be lost if you leave now.',
  'chat_leave_action': 'Leave',
  'chat_stay_action': 'Stay',
  'chat_completing': 'Wrapping up your profile...',
  'chat_skip': 'Skip',
  'chat_translate': 'Translate',
  'chat_hide_translation': 'Hide',
  'chat_play_audio': 'Play',
  'chat_type_message': 'Type a message...',
  'chat_complete': 'Chat complete',

  // Onboarding — Scenario Gift (Screen 08)
  'scenario_title': 'Your Scenarios',
  'scenario_subtitle': 'Flora created these scenarios just for you',
  'scenario_cta': 'Start Practicing →',
  'scenario_empty': 'Your scenarios are being prepared...',
  'scenario_level': 'Level',

  // Onboarding — Login Gate (Screen 09)
  'auth_gate_title': 'Save your progress',
  'auth_gate_subtitle': 'Create an account to keep your personalized plan',
  'auth_continue_apple': 'Continue with Apple',
  'auth_continue_google': 'Continue with Google',
  'auth_continue_email': 'Sign up with Email',
  'auth_social_coming_soon': 'Coming soon',

  // Auth — Signup (Screen 10)
  'signup_title': 'Create Account',
  'signup_subtitle': 'Join Flowering and start your journey',
  'signup_full_name': 'Full Name',
  'signup_full_name_hint': 'Your name',
  'signup_cta': 'Create Account',
  'signup_email_exists': 'This email is already registered',

  // Auth — Login (Screen 11)
  'login_title': 'Welcome Back',
  'login_subtitle': 'Sign in to continue learning',
  'login_cta': 'Sign In',
  'login_or_divider': 'or',

  // Validation
  'full_name_required': 'Full name is required',
  'full_name_min_length': 'Name must be at least 2 characters',

  // Auth — Forgot Password (Screen 12)
  'forgot_title': 'Forgot Password',
  'forgot_subtitle': 'Enter your email and we\'ll send a reset code',
  'forgot_cta': 'Send Reset Code',
  'forgot_back_to_login': 'Back to Login',
  'forgot_success': 'Reset code sent to',

  // Auth — OTP (Screen 13)
  'otp_title': 'Enter Code',
  'otp_subtitle': 'We sent a 6-digit code to',
  'otp_resend': 'Resend',
  'otp_resend_in': 'Resend in',
  'otp_invalid': 'Invalid or expired code',

  // Auth — New Password (Screen 14)
  'new_password_title': 'New Password',
  'new_password_subtitle': 'Choose a strong password',
  'new_password_label': 'New Password',
  'new_password_confirm_label': 'Confirm New Password',
  'new_password_cta': 'Reset Password',
  'password_reset_success': 'Password reset successfully',
};
