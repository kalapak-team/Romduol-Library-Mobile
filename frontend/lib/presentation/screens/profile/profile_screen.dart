import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/book/book_thumbnail.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/lotus_loader.dart';
import '../../../data/models/review_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? username;
  const ProfileScreen({super.key, this.username});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isFollowLoading = false;

  Future<void> _refreshBooks(String userId) async {
    ref.invalidate(authStateProvider);
    ref.invalidate(myUploadedBooksProviderFamily(userId));
    await ref.read(authStateProvider.future);
  }

  Future<void> _refreshOtherUser(String username) async {
    ref.invalidate(userProfileProvider(username));
    await ref.read(userProfileProvider(username).future);
  }

  Future<void> _toggleFollow(String userId, String username) async {
    if (_isFollowLoading) return;
    setState(() => _isFollowLoading = true);
    final repo = ref.read(userRepositoryProvider);
    await repo.toggleFollow(userId);
    ref.invalidate(userProfileProvider(username));
    if (mounted) setState(() => _isFollowLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final isSelf = widget.username == null ||
        widget.username?.toLowerCase() == 'me' ||
        widget.username == currentUser?.username;

    // Viewing another user's profile
    if (!isSelf && widget.username != null) {
      final otherUserAsync = ref.watch(userProfileProvider(widget.username!));
      return otherUserAsync.when(
        loading: () => const Scaffold(
          backgroundColor: AppColors.background,
          body: LotusLoader(),
        ),
        error: (e, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(),
          body: ErrorView(message: e.toString()),
        ),
        data: (otherUser) =>
            _buildOtherUserProfile(context, otherUser, currentUser),
      );
    }

    // Self profile — requires login
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_circle_outlined,
                size: 80,
                color: AppColors.border,
              ),
              const SizedBox(height: 16),
              Text(
                'login_to_view_profile'.tr(),
                style: AppTextStyles.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.push(RouteNames.login),
                child: Text('login'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    return _buildSelfProfile(context, currentUser);
  }

  Widget _buildSelfProfile(BuildContext context, dynamic user) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DefaultTabController(
        length: 2,
        child: RefreshIndicator(
          onRefresh: () => _refreshBooks(user.id),
          color: AppColors.primary,
          child: NestedScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            headerSliverBuilder: (_, __) => [
              SliverAppBar(
                expandedHeight: 380,
                pinned: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => _showSettingsSheet(context),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _ProfileHeader(
                    user: user,
                    isSelf: true,
                    onFollowersTap: () =>
                        _showFollowList(context, user.username, true),
                    onFollowingTap: () =>
                        _showFollowList(context, user.username, false),
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabDelegate(
                  TabBar(
                    tabs: [
                      Tab(text: 'my_books'.tr()),
                      Tab(text: 'my_reviews'.tr()),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              children: [
                _MyBooksTab(userId: user.id),
                _MyReviewsTab(userId: user.id),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtherUserProfile(
      BuildContext context, dynamic otherUser, dynamic currentUser) {
    final isLoggedIn = currentUser != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DefaultTabController(
        length: 1,
        child: RefreshIndicator(
          onRefresh: () => _refreshOtherUser(widget.username!),
          color: AppColors.primary,
          child: NestedScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            headerSliverBuilder: (_, __) => [
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _ProfileHeader(
                    user: otherUser,
                    isSelf: false,
                    followButton: isLoggedIn
                        ? _FollowButton(
                            isFollowing: otherUser.isFollowing,
                            isLoading: _isFollowLoading,
                            onPressed: () => _toggleFollow(
                              otherUser.id,
                              otherUser.username,
                            ),
                          )
                        : null,
                    onFollowersTap: () =>
                        _showFollowList(context, otherUser.username, true),
                    onFollowingTap: () =>
                        _showFollowList(context, otherUser.username, false),
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabDelegate(
                  TabBar(
                    tabs: [
                      Tab(text: 'my_books'.tr()),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              children: [
                _MyBooksTab(userId: otherUser.id),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFollowList(
      BuildContext context, String username, bool isFollowers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => _FollowListSheet(
          username: username,
          isFollowers: isFollowers,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SettingsSheet(ref: ref),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final dynamic user;
  final bool isSelf;
  final Widget? followButton;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;

  const _ProfileHeader({
    required this.user,
    required this.isSelf,
    this.followButton,
    this.onFollowersTap,
    this.onFollowingTap,
  });

  @override
  Widget build(BuildContext context) {
    final adminLabel =
        context.locale.languageCode == 'km' ? 'អ្នកគ្រប់គ្រង' : 'Admin';

    final hasAvatar =
        user.avatarUrl != null && user.avatarUrl.toString().trim().isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.background],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryWithOpacity12,
                    backgroundImage:
                        hasAvatar ? NetworkImage(user.avatarUrl!) : null,
                    child: !hasAvatar
                        ? Text(
                            (user.name?.toString().isNotEmpty == true)
                                ? user.name
                                    .toString()
                                    .substring(0, 1)
                                    .toUpperCase()
                                : '?',
                            style: AppTextStyles.displayMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.nameKm ?? user.name,
                          style: AppTextStyles.headlineSmall,
                        ),
                        Text(
                          '@${user.username}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMid,
                          ),
                        ),
                        if (user.isAdmin)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              adminLabel,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (user.bio != null) ...[
                Text(user.bio!, style: AppTextStyles.bodySmall),
                const SizedBox(height: 12),
              ],
              // Stats row: uploaded, downloaded, followers, following
              Row(
                children: [
                  _Stat(
                    value: user.booksUploaded.toString(),
                    label: 'uploaded'.tr(),
                  ),
                  const SizedBox(width: 24),
                  _Stat(
                    value: user.booksDownloaded.toString(),
                    label: 'downloaded'.tr(),
                  ),
                  const SizedBox(width: 24),
                  GestureDetector(
                    onTap: onFollowersTap,
                    child: _Stat(
                      value: (user.followersCount ?? 0).toString(),
                      label: 'followers'.tr(),
                    ),
                  ),
                  const SizedBox(width: 24),
                  GestureDetector(
                    onTap: onFollowingTap,
                    child: _Stat(
                      value: (user.followingCount ?? 0).toString(),
                      label: 'following'.tr(),
                    ),
                  ),
                ],
              ),
              if (followButton != null) ...[
                const SizedBox(height: 16),
                followButton!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final bool isLoading;
  final VoidCallback onPressed;

  const _FollowButton({
    required this.isFollowing,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: isFollowing
          ? OutlinedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_remove_outlined, size: 18),
              label: Text('unfollow'.tr()),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textMid,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person_add_outlined, size: 18),
              label: Text('follow'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
    );
  }
}

class _FollowListSheet extends ConsumerWidget {
  final String username;
  final bool isFollowers;
  final ScrollController scrollController;

  const _FollowListSheet({
    required this.username,
    required this.isFollowers,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUsers = isFollowers
        ? ref.watch(userFollowersProvider(username))
        : ref.watch(userFollowingProvider(username));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                isFollowers ? 'followers'.tr() : 'following'.tr(),
                style: AppTextStyles.headlineSmall,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: asyncUsers.when(
            loading: () => const LotusLoader(),
            error: (e, _) => ErrorView(message: e.toString()),
            data: (users) => users.isEmpty
                ? Center(
                    child: Text(
                      isFollowers ? 'no_followers'.tr() : 'no_following'.tr(),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textMid,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: users.length,
                    itemBuilder: (_, i) {
                      final u = users[i];
                      final hasAvatar =
                          u.avatarUrl != null && u.avatarUrl!.trim().isNotEmpty;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryWithOpacity12,
                          backgroundImage:
                              hasAvatar ? NetworkImage(u.avatarUrl!) : null,
                          child: !hasAvatar
                              ? Text(
                                  u.name.isNotEmpty
                                      ? u.name.substring(0, 1).toUpperCase()
                                      : '?',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(u.nameKm ?? u.name),
                        subtitle: Text(
                          '@${u.username}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMid,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.push(
                            RouteNames.userProfilePath(u.username),
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _MyBooksTab extends ConsumerWidget {
  final String userId;
  const _MyBooksTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myUploadedBooksProviderFamily(userId));
    return async.when(
      loading: () => const LotusLoader(),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (books) => books.isEmpty
          ? Center(child: Text('no_books'.tr()))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.65,
              ),
              itemCount: books.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () =>
                    context.push(RouteNames.bookDetailPath(books[i].id)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: BookThumbnail(
                    book: books[i],
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
    );
  }
}

class _MyReviewsTab extends ConsumerWidget {
  final String userId;
  const _MyReviewsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(myReviewsProvider);

    return reviewsAsync.when(
      loading: () => const Center(child: LotusLoader()),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(myReviewsProvider),
      ),
      data: (reviews) {
        if (reviews.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'no_reviews_yet'.tr(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _MyReviewCard(
            review: reviews[i],
            onTap: () => context.push(
              RouteNames.bookDetailPath(reviews[i].bookId),
            ),
          ),
        );
      },
    );
  }
}

class _MyReviewCard extends StatelessWidget {
  final ReviewModel review;
  final VoidCallback onTap;
  const _MyReviewCard({required this.review, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final book = review.book;
    final locale = context.locale.languageCode;
    final bookTitle =
        (locale == 'km' && book?.titleKm != null && book!.titleKm!.isNotEmpty)
            ? book.titleKm!
            : (book?.title ?? '');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: const Border.fromBorderSide(
            BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: book?.coverUrl != null && book!.coverUrl!.isNotEmpty
                  ? Image.network(
                      book.coverUrl!,
                      width: 56,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _coverPlaceholder(),
                    )
                  : _coverPlaceholder(),
            ),
            const SizedBox(width: 12),
            // Review content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bookTitle,
                    style: AppTextStyles.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (book?.author != null && book!.author.isNotEmpty)
                    Text(
                      book.author,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (i) => Icon(
                          i < review.rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 14,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM d, y').format(
                          DateTime.tryParse(review.createdAt) ?? DateTime.now(),
                        ),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  if (review.body != null && review.body!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      review.body!,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      width: 56,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primaryWithOpacity12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  final WidgetRef ref;
  const _SettingsSheet({required this.ref});

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final settingsTitle =
        context.locale.languageCode == 'km' ? 'ការកំណត់' : 'Settings';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(settingsTitle, style: AppTextStyles.headlineMedium),
          const Divider(),
          if (currentUser?.isAdmin == true)
            ListTile(
              leading:
                  const Icon(Icons.dashboard_rounded, color: AppColors.primary),
              title: Text(
                'admin_dashboard'.tr(),
                style:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push(RouteNames.adminDashboard);
              },
            ),
          if (currentUser?.isAdmin == true) const Divider(),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text('edit_profile'.tr()),
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.editProfile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline_rounded),
            title: Text('change_password'.tr()),
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.changePassword);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: Text('language'.tr()),
            trailing: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'km', label: Text('ខ្មែរ')),
                ButtonSegment(value: 'en', label: Text('EN')),
              ],
              selected: {lang},
              onSelectionChanged: (s) {
                ref.read(appLanguageProvider.notifier).setLanguage(s.first);
                final locale = Locale(s.first);
                context.setLocale(locale);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: Text(
              'logout'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
            onTap: () async {
              Navigator.pop(context);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text('logout'.tr()),
                  content: Text('confirm'.tr()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text('cancel'.tr()),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: Text('logout'.tr()),
                    ),
                  ],
                ),
              );

              if (confirmed != true) return;
              await ref.read(authStateProvider.notifier).logout();
              if (!context.mounted) return;
              context.go(RouteNames.login);
            },
          ),
        ],
      ),
    );
  }
}

// Family provider for any user's books
final myUploadedBooksProviderFamily = FutureProvider.family
    .autoDispose<List<dynamic>, String>((ref, userId) async {
  final repo = ref.read(bookRepositoryProvider);
  final result = await repo.getBooks(uploaderId: userId);
  return result.fold((_) => [], (p) => p.data);
});

class _TabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  const _TabDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: AppColors.background, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabDelegate oldDelegate) {
    return oldDelegate.tabBar != tabBar;
  }
}
