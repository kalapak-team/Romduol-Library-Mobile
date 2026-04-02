import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/romduol_button.dart';
import '../../widgets/common/romduol_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _usernameCtrl,
      _emailCtrl,
      _passwordCtrl,
      _confirmCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final error = await ref
        .read(authStateProvider.notifier)
        .register(
          name: _nameCtrl.text.trim(),
          username: _usernameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          passwordConfirmation: _confirmCtrl.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    } else {
      context.go(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('register'.tr()),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                RomduolTextField(
                  controller: _nameCtrl,
                  labelText: 'name'.tr(),
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(
                    Icons.person_outlined,
                    color: AppColors.textLight,
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'name'.tr() : null,
                ),
                const SizedBox(height: 14),
                RomduolTextField(
                  controller: _usernameCtrl,
                  labelText: 'username'.tr(),
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(
                    Icons.alternate_email_rounded,
                    color: AppColors.textLight,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'username'.tr();
                    if (v.length < 3) return 'Min 3 characters';
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
                      return 'Letters, numbers and _ only';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                RomduolTextField(
                  controller: _emailCtrl,
                  labelText: 'email'.tr(),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: AppColors.textLight,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'email'.tr();
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                RomduolTextField(
                  controller: _passwordCtrl,
                  labelText: 'password'.tr(),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(
                    Icons.lock_outlined,
                    color: AppColors.textLight,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textLight,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'password'.tr();
                    if (v.length < 8) return 'Min 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                RomduolTextField(
                  controller: _confirmCtrl,
                  labelText: 'confirm_password'.tr(),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(
                    Icons.lock_outlined,
                    color: AppColors.textLight,
                  ),
                  onSubmitted: (_) => _register(),
                  validator: (v) {
                    if (v != _passwordCtrl.text)
                      return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                RomduolButton(
                  label: 'register'.tr(),
                  onPressed: _register,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('have_account'.tr(), style: AppTextStyles.bodyMedium),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        'login'.tr(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
