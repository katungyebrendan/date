import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../chat/chat_screen.dart';
import '../discovery/discovery_screen.dart';
import '../likes/likes_list_screen.dart';
import '../matches/matches_list_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/settings_screen.dart';
import '../profile/view_profile_screen.dart';
import '../../routing/route_paths.dart';

List<RouteBase> homeShellRoutes() {
  return [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => HomeShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: RoutePaths.discovery, builder: (context, state) => const DiscoveryScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: RoutePaths.matches, builder: (context, state) => const MatchesListScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: RoutePaths.likes, builder: (context, state) => const LikesListScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: RoutePaths.profile, builder: (context, state) => const ProfileScreen())],
        ),
      ],
    ),
    GoRoute(
      path: RoutePaths.chatThread,
      builder: (context, state) => ChatScreen(matchId: state.pathParameters['matchId']!),
    ),
    GoRoute(
      path: RoutePaths.editProfile,
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: RoutePaths.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: RoutePaths.viewProfile,
      builder: (context, state) => ViewProfileScreen(uid: state.pathParameters['uid']!),
    ),
  ];
}

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.local_fire_department_outlined), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism_outlined), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Likes'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
