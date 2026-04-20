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
  'nav_read': 'Reading',
  'nav_vocabulary': 'Vocab',
  'nav_profile': 'Profile',

  // Chat Home
  'chat_home_title': 'Conversations',
  'chat_home_empty': 'No conversations yet',
  'chat_home_start': 'Start a new chat',

  // Read
  'read_title': 'Reading',
  'read_empty': 'No lessons available',
  'lesson_count': '@count scenarios',
  'lesson_locked': 'Locked',
  'language_picker_title': 'Learning language',
  'language_picker_empty': 'No languages yet. Add one from settings.',
  'language_picker_close': 'Close',

  // Vocabulary
  'vocabulary_title': 'Vocabulary',
  'vocabulary_search': 'Search words...',
  'vocabulary_empty': 'No words learned yet',

  // Language context errors
  'err_language_header_missing': 'Missing learning language. Please reopen the app.',
  'err_language_unknown': 'That language is no longer supported.',
  'err_language_not_enrolled': "You haven't enrolled in this language yet.",
  'err_language_required': 'Please pick a learning language to continue.',

  // Errors
  'network_error': 'Please check your internet connection',
  'server_error': 'Something went wrong. Please try again later',
  'session_expired': 'Session expired. Please login again',
  'unknown_error': 'An unknown error occurred',

  // Offline
  'offline': 'You are offline',
  'offline_mode': 'Offline Mode',
  'sync_pending': 'Changes will sync when online',

  // Subscription
  'subscription_title': 'Upgrade to Premium',
  'subscription_hero_description':
      'Unlock unlimited AI conversations, all lessons, and more.',
  'subscription_gate_description': 'Upgrade to access this feature.',
  'subscription_restore': 'Restore Purchases',
  'subscription_current_plan': 'Current Plan',
  'subscription_free_plan': 'Free',
  'subscription_monthly': 'Monthly',
  'subscription_yearly': 'Yearly',
  'subscription_lifetime': 'Lifetime',
  'subscription_best_value': 'Best Value',
  'subscription_purchase_button': 'Subscribe Now',
  'subscription_terms': 'Terms & Conditions',
  'subscription_privacy': 'Privacy Policy',

  // Onboarding — AI Chat (Screen 07)
  'chat_session_error': 'Could not start session. Please try again.',
  'chat_session_expired': 'Session expired. Please restart onboarding.',
  'chat_session_invalid': 'Session not found. Let\'s start a new conversation.',
  'chat_rate_limit_create': 'Too many session attempts. Please wait an hour before starting again.',
  'chat_rate_limit_chat': 'Slow down — you\'re sending messages too quickly.',
  'resume_chat_failed': 'Couldn\'t restore your previous conversation.',
  'resume_chat_retry': 'Try again',
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
  'chat_playing': 'Playing...',
  'chat_type_message': 'Type a message...',
  'chat_complete': 'Chat complete',
  'chat_listening': 'Listening...',
  'chat_tap_to_speak': 'Hold to speak',
  'chat_stt_unavailable': 'Voice input not available on this device',
  'chat_stt_timeout': 'Recording time limit reached',
  'chat_tts_auto_play': 'Auto-play messages',
  'chat_transcribing': 'Transcribing...',

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
  'google_sign_in_failed': 'Google sign-in failed. Please try again.',
  'apple_sign_in_failed': 'Apple sign-in failed. Please try again.',
  'firebase_token_error': 'Authentication error. Please try again.',

  // Auth — Signup (Screen 10)
  'signup_title': 'Create Account',
  'signup_subtitle': 'Start your language journey',
  'signup_full_name': 'Full Name',
  'signup_full_name_hint': 'Your name',
  'signup_cta': 'Create Account',
  'signup_email_exists': 'This email is already registered',

  // Auth — Login (Screen 11)
  'login_title': 'Welcome Back',
  'login_subtitle': 'Log in to continue your journey',
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
  'otp_title': 'Check Your Email',
  'otp_subtitle': 'We sent a 6-digit code to',
  'otp_resend': 'Resend',
  'otp_resend_in': 'Resend in',
  'otp_invalid': 'Invalid or expired code',

  // Auth — New Password (Screen 14)
  'new_password_title': 'New Password',
  'new_password_subtitle': 'Create a strong password for your account',
  'new_password_label': 'New Password',
  'new_password_confirm_label': 'Confirm New Password',
  'new_password_cta': 'Reset Password',
  'password_reset_success': 'Password reset successfully',
  'password_reset_title': 'Password Reset',
  'password_reset_message': 'Your password has been reset. Please log in.',

  // Word Translation (Screen 08a)
  'word_translation_title': 'Translation',
  'word_definition_label': 'Definition',
  'word_examples_label': 'Examples',
  'word_translation_error': 'Could not load translation',
  'sentence_translation_unavailable': 'Sentence translation is not available during onboarding',
  'word_translation_retry': 'Retry',
  'translation_target_language': 'Vietnamese',

  // Onboarding — Value Screens (Screens 03/04/05)
  'onboarding_skip': 'Skip',
  'onboarding_value_headline_1': 'Some are early bloomers\nSome are late bloomers\nBoth are beautiful',
  'onboarding_value_body_1': 'Flowering grows with you,\nat your own pace',
  'onboarding_value_headline_2': 'Plant it once\nWatch it bloom forever',
  'onboarding_value_body_2': 'Learn today, remember tomorrow\nand next month and forever',
  'onboarding_value_headline_3': 'Same sun\nDifferent flowers',
  'onboarding_value_body_3': 'Everyone learns differently\nFlowering creates your own path',
  'onboarding_next': 'Next',
  'onboarding_ready': 'I\'m Ready',

  // Onboarding — Language Selection (Screen 05/06)
  'language_select_title': "What language do you want to learn?",
  'native_language_title': "What is your native language?",
  'language_load_error': 'Failed to load languages',
  'language_coming_soon': 'Soon',
  'search_language': 'Search language...',
  'show_all_languages': 'Show all languages',
  'continue_button': 'Continue',

  // Onboarding — Top Bar
  'login_action': 'Log in',
  'signup_action': 'Sign up',
  'go_back': 'Go Back',
  'coming_soon_suffix': 'Coming Soon',
  'otp_didnt_receive': "Didn't receive the code?",
  'otp_resend_in_timer': 'Resend in',

  // Onboarding — Splash
  'splash_subtitle': 'Bloom in your own way',

  // Chat
  'ai_name': 'Flora',

  // Auth — Form hints
  'email_hint': 'you@example.com',
  'password_hint': 'Your password',
  'password_min_hint': 'At least 8 characters',
  'confirm_password_hint': 'Repeat your password',
  'confirm_new_password_hint': 'Repeat your new password',

  // Auth — Social
  'continue_with_apple': 'Continue with Apple',
  'continue_with_google': 'Continue with Google',

  // Auth — Firebase error codes (never expose e.message — use these mapped keys)
  'auth_error_invalid_credential': 'Invalid credentials. Please try again.',
  'auth_error_user_disabled': 'This account has been disabled.',
  'auth_error_user_not_found': 'No account found with these credentials.',
  'auth_error_wrong_password': 'Incorrect password. Please try again.',
  'auth_error_network': 'Network error. Please check your connection.',
  'auth_error_too_many_requests': 'Too many attempts. Please wait and try again.',
  'auth_error_account_exists_different_credential': 'An account already exists with a different sign-in method.',
  'auth_error_operation_not_allowed': 'This sign-in method is not enabled.',
  'auth_error_generic': 'Authentication failed. Please try again.',

  // Grammar Correction
  'corrected': 'Corrected',
  'hide': 'Hide',
  'show': 'Show',

  // Chat UI Update (08A-08E)
  'chat_try_instead': 'Try this instead:',
  'chat_save_to_words': 'Save to My Words',

  // Empty States
  'empty_no_conversations': 'No conversations yet',
  'empty_start_first_conversation': 'Start your first conversation with Flora',
  'empty_start_chat': 'Start Chat',
  'empty_no_vocabulary': 'No words saved yet',
  'empty_start_learning_vocabulary': 'Save words from your conversations',
  'empty_no_lessons_completed': 'No lessons completed yet',
  'empty_explore_lessons': 'Explore Lessons',
  'empty_no_internet': 'No internet connection',
  'empty_check_connection': 'Check your connection and try again',
};
