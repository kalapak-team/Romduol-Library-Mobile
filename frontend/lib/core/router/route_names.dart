class RouteNames {
  RouteNames._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String catalog = '/catalog';
  static const String bookDetail = '/books/:id';
  static const String reader = '/reader/:id';
  static const String search = '/search';
  static const String upload = '/upload';
  static const String profile = '/profile/:username';
  static const String editProfile = '/settings/edit-profile';
  static const String changePassword = '/settings/change-password';
  static const String bookshelf = '/bookshelf';
  static const String notifications = '/notifications';
  static const String adminDashboard = '/admin';
  static const String adminBooks = '/admin/books';
  static const String adminUsers = '/admin/users';
  static const String adminSettings = '/admin/settings';

  static String bookDetailPath(String id) => '/books/$id';
  static String readerPath(String id) => '/reader/$id';
  static String profilePath(String username) => '/profile/$username';
  static String userProfilePath(String username) => '/user/$username';
}
