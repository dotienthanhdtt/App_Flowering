import 'package:get/get.dart';
import 'app-route-constants.dart';
import 'app-route-transition-config.dart';
import 'app-placeholder-screen.dart';
import '../../features/auth/bindings/auth_binding.dart';
import '../../features/auth/views/login_email_screen.dart';
import '../../features/auth/views/signup_email_screen.dart';
import '../../features/auth/views/forgot_password_screen.dart';
import '../../features/auth/views/otp_verification_screen.dart';
import '../../features/auth/views/new_password_screen.dart';

/// Auth flow pages: login, register, signup, forgot password, OTP, new password
final List<GetPage> authPages = [
  // Auth — login (Screen 11)
  GetPage(
    name: AppRoutes.login,
    page: () => const LoginEmailScreen(),
    binding: AuthBinding(),
    transition: Transition.fade,
    transitionDuration: kDefaultDuration,
  ),

  // Auth — register placeholder
  GetPage(
    name: AppRoutes.register,
    page: () => const AppPlaceholderScreen('Register'),
    transition: kDefaultTransition,
    transitionDuration: kDefaultDuration,
    curve: kDefaultCurve,
  ),

  // Auth — signup (Screen 10)
  GetPage(
    name: AppRoutes.signup,
    page: () => const SignupEmailScreen(),
    binding: AuthBinding(),
    transition: kDefaultTransition,
    transitionDuration: kDefaultDuration,
    curve: kDefaultCurve,
  ),

  // Auth — forgot password (Screen 12)
  GetPage(
    name: AppRoutes.forgotPassword,
    page: () => const ForgotPasswordScreen(),
    binding: AuthBinding(),
    transition: kDefaultTransition,
    transitionDuration: kDefaultDuration,
    curve: kDefaultCurve,
  ),

  // Auth — OTP verification (Screen 13)
  GetPage(
    name: AppRoutes.otpVerification,
    page: () => const OtpVerificationScreen(),
    binding: AuthBinding(),
    transition: kDefaultTransition,
    transitionDuration: kDefaultDuration,
    curve: kDefaultCurve,
  ),

  // Auth — new password (Screen 14)
  GetPage(
    name: AppRoutes.newPassword,
    page: () => const NewPasswordScreen(),
    binding: AuthBinding(),
    transition: kDefaultTransition,
    transitionDuration: kDefaultDuration,
    curve: kDefaultCurve,
  ),
];
