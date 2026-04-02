import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/admin/admin_books_screen.dart';
import '../../presentation/screens/admin/admin_dashboard_screen.dart';
import '../../presentation/screens/admin/admin_users_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/book_detail/book_detail_screen.dart';
import '../../presentation/screens/bookshelf/bookshelf_screen.dart';
import '../../presentation/screens/catalog/catalog_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/notifications/notifications_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/profile/change_password_screen.dart';
import '../../presentation/screens/profile/edit_profile_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/reader/reader_screen.dart';
import '../../presentation/screens/search/search_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/upload/upload_screen.dart';
import '../../presentation/widgets/common/main_scaffold.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      if (state.matchedLocation == RouteNames.splash) return null;

      // Protected routes
      final protectedRoutes = [
        RouteNames.upload,
        RouteNames.bookshelf,
        '/admin',
        '/settings',
      ];
      final needsAuth = protectedRoutes.any(
        (r) => state.matchedLocation.startsWith(r),
      );

      if (needsAuth && !isLoggedIn) return RouteNames.login;

      // Admin role guard
      if (state.matchedLocation.startsWith('/admin')) {
        final user = authState.valueOrNull;
        if (user == null || !user.isAdmin) return RouteNames.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: RouteNames.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: RouteNames.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      // Main scaffold with bottom nav
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: RouteNames.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: RouteNames.catalog,
            builder: (_, __) => const CatalogScreen(),
          ),
          GoRoute(
            path: RouteNames.upload,
            builder: (_, __) => const UploadScreen(),
          ),
          GoRoute(
            path: RouteNames.bookshelf,
            builder: (_, __) => const BookshelfScreen(),
          ),
          GoRoute(
            path: '/profile/:username',
            builder: (_, state) =>
                ProfileScreen(username: state.pathParameters['username']!),
          ),
        ],
      ),
      // Full-page routes (no bottom nav)
      GoRoute(
        path: '/books/:id',
        builder: (_, state) =>
            BookDetailScreen(bookId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reader/:id',
        builder: (_, state) =>
            ReaderScreen(bookId: state.pathParameters['id']!),
      ),
      // User profile (outside shell, no bottom nav) — for viewing other users
      GoRoute(
        path: '/user/:username',
        builder: (_, state) =>
            ProfileScreen(username: state.pathParameters['username']!),
      ),
      GoRoute(
        path: RouteNames.search,
        builder: (_, state) =>
            SearchScreen(query: state.uri.queryParameters['q']),
      ),
      GoRoute(
        path: RouteNames.editProfile,
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.changePassword,
        builder: (_, __) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      // Admin routes
      GoRoute(
        path: RouteNames.adminDashboard,
        builder: (_, __) => const AdminDashboardScreen(),
        routes: [
          GoRoute(path: 'books', builder: (_, __) => const AdminBooksScreen()),
          GoRoute(path: 'users', builder: (_, __) => const AdminUsersScreen()),
        ],
      ),
    ],
  );
});
