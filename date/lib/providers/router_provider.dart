import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_router.dart';
import '../routing/route_paths.dart';
import 'auth_providers.dart';
import 'policy_providers.dart';
import 'user_providers.dart';

/// Notifies go_router's `refreshListenable` whenever auth state, the current
/// user's profile doc, or policy acceptance changes, so `redirect` re-evaluates.
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    _authSub = ref.listen(authStateChangesProvider, (previous, next) => notifyListeners());
    _userSub = ref.listen(currentAppUserProvider, (previous, next) => notifyListeners());
    _policySub = ref.listen(policyAcceptedProvider, (previous, next) => notifyListeners());
  }

  late final ProviderSubscription _authSub;
  late final ProviderSubscription _userSub;
  late final ProviderSubscription _policySub;

  @override
  void dispose() {
    _authSub.close();
    _userSub.close();
    _policySub.close();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) => appRedirect(ref, state),
    routes: appRoutes(),
  );
});
