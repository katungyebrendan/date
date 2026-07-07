class RoutePaths {
  RoutePaths._();

  static const policy = '/policy';
  static const splash = '/splash';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const onboarding = '/onboarding';

  static const discovery = '/discovery';
  static const matches = '/matches';
  static const likes = '/likes';
  static const chatThread = '/chat/:matchId';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const settings = '/profile/settings';
  static const viewProfile = '/profile/view/:uid';

  static String chatThreadPath(String matchId) => '/chat/$matchId';
  static String viewProfilePath(String uid) => '/profile/view/$uid';
}
