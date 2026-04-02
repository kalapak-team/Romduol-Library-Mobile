import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/route_names.dart';
import '../../../data/models/dashboard_stats_model.dart';
import '../../providers/admin_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('admin_dashboard'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(adminDashboardProvider.notifier).refresh(),
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('error_occurred'.tr(), style: AppTextStyles.titleMedium),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  e.toString(),
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(adminDashboardProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text('retry'.tr()),
              ),
            ],
          ),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () => ref.read(adminDashboardProvider.notifier).refresh(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Overview Stats ───────────────────────────────
                _buildOverviewCards(stats),
                const SizedBox(height: 20),

                // ── Book Approval Setting ────────────────────────
                Text('settings'.tr(), style: AppTextStyles.titleMedium),
                const SizedBox(height: 10),
                _BookApprovalSettingCard(
                  requireApproval: stats.requireBookApproval,
                ),
                const SizedBox(height: 24),

                // ── Quick Actions ────────────────────────────────
                Text('quick_actions'.tr(), style: AppTextStyles.titleMedium),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.book_outlined,
                        label: 'manage_books'.tr(),
                        description: 'review_pending_books'.tr(),
                        badgeCount: stats.books.pending,
                        onTap: () =>
                            context.push('${RouteNames.adminDashboard}/books'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.people_outlined,
                        label: 'manage_users'.tr(),
                        description: 'ban_or_promote'.tr(),
                        badgeCount: stats.users.banned,
                        onTap: () =>
                            context.push('${RouteNames.adminDashboard}/users'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── User Breakdown ───────────────────────────────
                Text('user_breakdown'.tr(), style: AppTextStyles.titleMedium),
                const SizedBox(height: 10),
                _buildUserBreakdown(stats.users),
                const SizedBox(height: 24),

                // ── Book Breakdown ───────────────────────────────
                Text('book_breakdown'.tr(), style: AppTextStyles.titleMedium),
                const SizedBox(height: 10),
                _buildBookBreakdown(stats.books),
                const SizedBox(height: 24),

                // ── Recent Pending Books ─────────────────────────
                if (stats.recentPendingBooks.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('pending_books'.tr(),
                          style: AppTextStyles.titleMedium),
                      TextButton(
                        onPressed: () =>
                            context.push('${RouteNames.adminDashboard}/books'),
                        child: Text('view_all'.tr(),
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...stats.recentPendingBooks
                      .map((b) => _PendingBookTile(book: b)),
                  const SizedBox(height: 16),
                ],

                // ── Recent Users ─────────────────────────────────
                if (stats.recentUsers.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('recent_users'.tr(),
                          style: AppTextStyles.titleMedium),
                      TextButton(
                        onPressed: () =>
                            context.push('${RouteNames.adminDashboard}/users'),
                        child: Text('view_all'.tr(),
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...stats.recentUsers.map((u) => _RecentUserTile(user: u)),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards(DashboardStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          icon: Icons.people,
          label: 'total_users'.tr(),
          value: '${stats.users.total}',
          color: AppColors.info,
        ),
        _StatCard(
          icon: Icons.menu_book,
          label: 'total_books'.tr(),
          value: '${stats.books.total}',
          color: AppColors.primary,
        ),
        _StatCard(
          icon: Icons.pending_actions,
          label: 'pending_books'.tr(),
          value: '${stats.books.pending}',
          color: AppColors.accent,
        ),
        _StatCard(
          icon: Icons.download,
          label: 'total_downloads'.tr(),
          value: '${stats.totalDownloads}',
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildUserBreakdown(UserStats users) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _BreakdownRow(
              label: 'active_users'.tr(),
              value: users.active,
              total: users.total,
              color: AppColors.success,
            ),
            const SizedBox(height: 10),
            _BreakdownRow(
              label: 'banned_users'.tr(),
              value: users.banned,
              total: users.total,
              color: AppColors.error,
            ),
            const SizedBox(height: 10),
            _BreakdownRow(
              label: 'admin_users'.tr(),
              value: users.admins,
              total: users.total,
              color: AppColors.info,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookBreakdown(BookStats books) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _BreakdownRow(
              label: 'approved_books'.tr(),
              value: books.approved,
              total: books.total,
              color: AppColors.success,
            ),
            const SizedBox(height: 10),
            _BreakdownRow(
              label: 'pending_books'.tr(),
              value: books.pending,
              total: books.total,
              color: AppColors.accent,
            ),
            const SizedBox(height: 10),
            _BreakdownRow(
              label: 'rejected_books'.tr(),
              value: books.rejected,
              total: books.total,
              color: AppColors.error,
            ),
            const SizedBox(height: 10),
            _BreakdownRow(
              label: 'featured_books'.tr(),
              value: books.featured,
              total: books.total,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Card ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      color: color.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: AppTextStyles.headlineMedium.copyWith(color: color)),
            ),
            Text(label,
                style: AppTextStyles.bodySmall,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ─── Breakdown Row ───────────────────────────────────────────────────────────

class _BreakdownRow extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? value / total : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(label, style: AppTextStyles.bodyMedium),
              ],
            ),
            Text('$value',
                style: AppTextStyles.titleMedium.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: AppColors.border,
            color: color,
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}

// ─── Quick Action Card ───────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final int badgeCount;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: AppColors.primary, size: 28),
                  if (badgeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(label, style: AppTextStyles.titleMedium),
              const SizedBox(height: 2),
              Text(description,
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Pending Book Tile ───────────────────────────────────────────────────────

class _PendingBookTile extends StatelessWidget {
  final RecentPendingBook book;

  const _PendingBookTile({required this.book});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: book.coverUrl != null
              ? Image.network(book.coverUrl!,
                  width: 40, height: 56, fit: BoxFit.cover)
              : Container(
                  width: 40,
                  height: 56,
                  color: AppColors.primaryWithOpacity12,
                  child: const Icon(Icons.book,
                      color: AppColors.primary, size: 20),
                ),
        ),
        title: Text(book.title,
            style:
                AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(
          book.uploaderName ?? 'Unknown',
          style: AppTextStyles.bodySmall,
        ),
        trailing: Text(
          DateFormat('dd/MM').format(book.createdAt),
          style: AppTextStyles.labelSmall,
        ),
      ),
    );
  }
}

// ─── Recent User Tile ────────────────────────────────────────────────────────

class _RecentUserTile extends StatelessWidget {
  final RecentUser user;

  const _RecentUserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primaryWithOpacity12,
          backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
              ? NetworkImage(user.avatarUrl!)
              : null,
          child: user.avatarUrl == null || user.avatarUrl!.isEmpty
              ? Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.primary),
                )
              : null,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(user.name,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 6),
            if (user.role == 'admin')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('admin'.tr(),
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.primary, fontSize: 9)),
              ),
          ],
        ),
        subtitle: Text('@${user.username}', style: AppTextStyles.bodySmall),
        trailing: Text(
          DateFormat('dd/MM').format(user.createdAt),
          style: AppTextStyles.labelSmall,
        ),
      ),
    );
  }
}

// ─── Book Approval Setting Card ──────────────────────────────────────────────

class _BookApprovalSettingCard extends ConsumerStatefulWidget {
  final bool requireApproval;

  const _BookApprovalSettingCard({required this.requireApproval});

  @override
  ConsumerState<_BookApprovalSettingCard> createState() =>
      _BookApprovalSettingCardState();
}

class _BookApprovalSettingCardState
    extends ConsumerState<_BookApprovalSettingCard> {
  late bool _requireApproval;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _requireApproval = widget.requireApproval;
  }

  @override
  void didUpdateWidget(covariant _BookApprovalSettingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requireApproval != widget.requireApproval) {
      _requireApproval = widget.requireApproval;
    }
  }

  Future<void> _onChanged(bool value) async {
    setState(() {
      _requireApproval = value;
      _loading = true;
    });

    final error = await ref
        .read(adminDashboardProvider.notifier)
        .toggleRequireBookApproval(value);

    if (!mounted) return;

    setState(() => _loading = false);

    if (error != null) {
      // Revert on failure
      setState(() => _requireApproval = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('approval_setting_updated'.tr()),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('require_book_approval'.tr(),
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    _requireApproval
                        ? 'books_need_approval_desc'.tr()
                        : 'books_auto_approved_desc'.tr(),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            if (_loading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else
              Switch.adaptive(
                value: _requireApproval,
                onChanged: _onChanged,
                activeColor: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
