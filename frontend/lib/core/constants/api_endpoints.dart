class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl =
      'http://localhost:8000'; // localhost (works for web/desktop + Android emulator via 10.0.2.2)
  static const String apiBase = '$baseUrl/api/v1';

  // Auth
  static const String register = '$apiBase/auth/register';
  static const String login = '$apiBase/auth/login';
  static const String logout = '$apiBase/auth/logout';
  static const String me = '$apiBase/auth/me';
  static const String forgotPassword = '$apiBase/auth/forgot-password';
  static const String resetPassword = '$apiBase/auth/reset-password';
  static const String verifyEmail = '$apiBase/auth/verify-email';
  static const String updateProfile = '$apiBase/auth/profile';
  static const String changePassword = '$apiBase/auth/change-password';

  // Books
  static const String books = '$apiBase/books';
  static const String featuredBooks = '$apiBase/books/featured';
  static const String newArrivals = '$apiBase/books/new-arrivals';
  static const String searchBooks = '$apiBase/books/search';
  static String bookDetail(String id) => '$apiBase/books/$id';
  static String bookUpdate(String id) => '$apiBase/books/$id';
  static String bookDelete(String id) => '$apiBase/books/$id';
  static String bookRead(String id) => '$apiBase/books/$id/read';
  static String bookDownload(String id) => '$apiBase/books/$id/download';
  static String bookReviews(String id) => '$apiBase/books/$id/reviews';
  static String reportBook(String id) => '$apiBase/books/$id/report';

  // Categories
  static const String categories = '$apiBase/categories';
  static String categoryBooks(String slug) => '$apiBase/categories/$slug/books';

  // User
  static String userProfile(String username) => '$apiBase/users/$username';
  static String userBooks(String username) => '$apiBase/users/$username/books';
  static String userFollowers(String username) =>
      '$apiBase/users/$username/followers';
  static String userFollowingList(String username) =>
      '$apiBase/users/$username/following';
  static String toggleFollow(String userId) => '$apiBase/users/$userId/follow';
  static const String myFollowing = '$apiBase/me/following';
  static const String myReviews = '$apiBase/me/reviews';
  static const String favorites = '$apiBase/me/favorites';
  static String toggleFavorite(String bookId) =>
      '$apiBase/books/$bookId/favorite';
  static const String readingList = '$apiBase/profile/reading-list';
  static String updateReadingList(String bookId) =>
      '$apiBase/profile/reading-list/$bookId';

  // Admin
  static const String adminDashboard = '$apiBase/admin/dashboard';
  static const String adminBooks = '$apiBase/admin/books';
  static const String adminPendingBooks = '$apiBase/admin/books/pending';
  static String adminApproveBook(String id) =>
      '$apiBase/admin/books/$id/approve';
  static String adminRejectBook(String id) => '$apiBase/admin/books/$id/reject';
  static String adminFeatureBook(String id) =>
      '$apiBase/admin/books/$id/feature';
  static String adminDeleteBook(String id) => '$apiBase/admin/books/$id';
  static String adminUpdateBook(String id) => '$apiBase/admin/books/$id';
  static const String adminUsers = '$apiBase/admin/users';
  static String adminBanUser(String id) => '$apiBase/admin/users/$id/ban';
  static String adminUnbanUser(String id) => '$apiBase/admin/users/$id/unban';
  static String adminPromoteUser(String id) =>
      '$apiBase/admin/users/$id/promote';
  static const String adminSettings = '$apiBase/admin/settings';
  static const String adminReports = '$apiBase/admin/reports';
  static const String adminStats = '$apiBase/admin/stats';

  // Stats
  static const String communityStats = '$apiBase/stats';

  // Public Settings
  static const String publicSettings = '$apiBase/settings/public';
}
