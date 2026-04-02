import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/user_model.dart';
import '../../providers/admin_provider.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = '';
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(adminUsersProvider.notifier).search(query);
    });
  }

  void _onStatusFilterChanged(String status) {
    setState(() => _statusFilter = status);
    ref.read(adminUsersProvider.notifier).filterByStatus(status);
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('manage_users'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminUsersProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'search_users'.tr(),
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.textLight),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _FilterChip(
                      label: 'all'.tr(),
                      selected: _statusFilter.isEmpty,
                      onTap: () => _onStatusFilterChanged(''),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'active'.tr(),
                      selected: _statusFilter == 'active',
                      onTap: () => _onStatusFilterChanged('active'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'banned'.tr(),
                      selected: _statusFilter == 'banned',
                      onTap: () => _onStatusFilterChanged('banned'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // User list
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('error_occurred'.tr(),
                        style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 8),
                    Text(e.toString(), style: AppTextStyles.bodySmall),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(adminUsersProvider.notifier).refresh(),
                      child: Text('retry'.tr()),
                    ),
                  ],
                ),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_outline,
                            size: 64, color: AppColors.textLight),
                        const SizedBox(height: 12),
                        Text('no_users_found'.tr(),
                            style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(adminUsersProvider.notifier).refresh(),
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _UserCard(
                      user: users[index],
                      onBan: () => _confirmAction(
                        context,
                        'confirm_ban_user'.tr(),
                        () => _banUser(users[index].id),
                      ),
                      onUnban: () => _unbanUser(users[index].id),
                      onPromote: () => _confirmAction(
                        context,
                        'confirm_promote_user'.tr(),
                        () => _promoteUser(users[index].id),
                      ),
                      onDelete: () => _confirmAction(
                        context,
                        'confirm_delete_user'.tr(),
                        () => _deleteUser(users[index].id),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAction(
      BuildContext context, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('confirm'.tr(), style: AppTextStyles.titleMedium),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text('confirm'.tr(),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _banUser(String id) async {
    final error = await ref.read(adminUsersProvider.notifier).banUser(id);
    if (!mounted) return;
    _showSnackBar(error ?? 'user_banned_success'.tr(), isError: error != null);
  }

  Future<void> _unbanUser(String id) async {
    final error = await ref.read(adminUsersProvider.notifier).unbanUser(id);
    if (!mounted) return;
    _showSnackBar(error ?? 'user_unbanned_success'.tr(),
        isError: error != null);
  }

  Future<void> _promoteUser(String id) async {
    final error = await ref.read(adminUsersProvider.notifier).promoteUser(id);
    if (!mounted) return;
    _showSnackBar(error ?? 'user_promoted_success'.tr(),
        isError: error != null);
  }

  Future<void> _deleteUser(String id) async {
    final error = await ref.read(adminUsersProvider.notifier).deleteUser(id);
    if (!mounted) return;
    _showSnackBar(error ?? 'user_deleted_success'.tr(), isError: error != null);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onBan;
  final VoidCallback onUnban;
  final VoidCallback onPromote;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onBan,
    required this.onUnban,
    required this.onPromote,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isBanned = user.status == 'banned';
    final isAdmin = user.isAdmin;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isBanned
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      color: isBanned
          ? AppColors.error.withValues(alpha: 0.04)
          : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info row
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryWithOpacity12,
                  backgroundImage:
                      user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                  child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                      ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: AppTextStyles.titleMedium
                              .copyWith(color: AppColors.primary),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              style: AppTextStyles.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (isAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'admin'.tr(),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (isBanned)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'banned'.tr(),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${user.username}',
                        style: AppTextStyles.bodySmall,
                      ),
                      Text(
                        user.email,
                        style: AppTextStyles.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Stats row
            Row(
              children: [
                _StatBadge(
                    icon: Icons.upload_outlined,
                    value: '${user.booksUploaded}'),
                const SizedBox(width: 12),
                _StatBadge(
                    icon: Icons.download_outlined,
                    value: '${user.booksDownloaded}'),
                const SizedBox(width: 12),
                _StatBadge(
                  icon: Icons.calendar_today_outlined,
                  value: DateFormat('dd/MM/yyyy').format(user.createdAt),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 8),
            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!isAdmin) ...[
                  if (isBanned)
                    _ActionButton(
                      icon: Icons.lock_open,
                      label: 'unban_user'.tr(),
                      color: AppColors.success,
                      onTap: onUnban,
                    )
                  else
                    _ActionButton(
                      icon: Icons.block,
                      label: 'ban_user'.tr(),
                      color: AppColors.error,
                      onTap: onBan,
                    ),
                  _ActionButton(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'promote_admin'.tr(),
                    color: AppColors.info,
                    onTap: onPromote,
                  ),
                ],
                if (!isAdmin)
                  _ActionButton(
                    icon: Icons.delete_outline,
                    label: 'delete'.tr(),
                    color: AppColors.error,
                    onTap: onDelete,
                  ),
                if (isAdmin)
                  Text(
                    'admin_no_actions'.tr(),
                    style: AppTextStyles.bodySmall
                        .copyWith(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;

  const _StatBadge({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textLight),
        const SizedBox(width: 4),
        Text(value, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: selected ? Colors.white : AppColors.textMid,
          ),
        ),
      ),
    );
  }
}
