import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../providers/policy_providers.dart';
import '../providers/user_providers.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/home/home_shell.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/policy/data_usage_policy_screen.dart';
import '../screens/splash/splash_screen.dart';
import 'route_paths.dart';

const _authRoutes = {
  RoutePaths.splash,
  RoutePaths.signIn,
  RoutePaths.signUp,
  RoutePaths.onboarding,
};

String? appRedirect(Ref ref, GoRouterState state) {
  final path = state.matchedLocation;

  // Gate everything behind the data usage policy on first launch — this
  // must run before auth/onboarding checks since it applies pre-sign-in.
  final policyAccepted = ref.read(policyAcceptedProvider);
  if (!policyAccepted) {
    return path == RoutePaths.policy ? null : RoutePaths.policy;
  }
  if (path == RoutePaths.policy) {
    return RoutePaths.splash;
  }

  final authState = ref.read(authStateChangesProvider);

  if (authState.isLoading) {
    return path == RoutePaths.splash ? null : RoutePaths.splash;
  }

  final firebaseUser = authState.valueOrNull;
  if (firebaseUser == null) {
    if (path == RoutePaths.signIn || path == RoutePaths.signUp) return null;
    return RoutePaths.signIn;
  }

  final userState = ref.read(currentAppUserProvider);
  if (userState.isLoading) {
    return path == RoutePaths.splash ? null : RoutePaths.splash;
  }

  final onboarded = userState.valueOrNull?.onboardingComplete ?? false;
  if (!onboarded) {
    return path == RoutePaths.onboarding ? null : RoutePaths.onboarding;
  }

  if (_authRoutes.contains(path)) {
    return RoutePaths.discovery;
  }
  return null;
}

List<RouteBase> appRoutes() {
  return [
    GoRoute(path: RoutePaths.policy, builder: (context, state) => const DataUsagePolicyScreen()),
    GoRoute(path: RoutePaths.splash, builder: (context, state) => const SplashScreen()),
    GoRoute(path: RoutePaths.signIn, builder: (context, state) => const SignInScreen()),
    GoRoute(path: RoutePaths.signUp, builder: (context, state) => const SignUpScreen()),
    GoRoute(path: RoutePaths.onboarding, builder: (context, state) => const OnboardingScreen()),
    ...homeShellRoutes(),
  ];
}
