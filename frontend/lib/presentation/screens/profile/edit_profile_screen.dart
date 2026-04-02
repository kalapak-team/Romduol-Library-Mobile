import 'package:flutter/foundation.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/romduol_button.dart';
import '../../widgets/common/romduol_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _nameKm = TextEditingController();
  final _bio = TextEditingController();
  final _bioKm = TextEditingController();
  Uint8List? _avatarBytes;
  String? _avatarFileName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      _name.text = user.name;
      _nameKm.text = user.nameKm ?? '';
      _bio.text = user.bio ?? '';
      _bioKm.text = user.bioKm ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _nameKm.dispose();
    _bio.dispose();
    _bioKm.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() {
        _avatarBytes = bytes;
        _avatarFileName = img.name;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final error = await ref.read(authStateProvider.notifier).updateProfile(
          name: _name.text.trim(),
          nameKm: _nameKm.text.trim().isEmpty ? null : _nameKm.text.trim(),
          bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
          bioKm: _bioKm.text.trim().isEmpty ? null : _bioKm.text.trim(),
          avatarBytes: _avatarBytes != null ? _avatarBytes!.toList() : null,
          avatarFileName: _avatarFileName,
        );

    if (mounted) {
      setState(() => _saving = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile_updated'.tr())),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final avatarUrl = user?.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('edit_profile'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.primaryWithOpacity12,
                      backgroundImage: _avatarBytes != null
                          ? MemoryImage(_avatarBytes!)
                          : (hasAvatar ? NetworkImage(avatarUrl) : null)
                              as ImageProvider?,
                      child: _avatarBytes == null && !hasAvatar
                          ? Text(
                              user?.name.characters.first.toUpperCase() ?? '?',
                              style: AppTextStyles.displayMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              RomduolTextField(
                controller: _name,
                labelText: 'full_name'.tr(),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'required'.tr() : null,
              ),
              RomduolTextField(
                controller: _nameKm,
                labelText: 'full_name_km'.tr(),
              ),
              RomduolTextField(
                controller: _bio,
                labelText: 'bio'.tr(),
                maxLines: 3,
              ),
              RomduolTextField(
                controller: _bioKm,
                labelText: 'bio_km'.tr(),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              RomduolButton(
                label: 'save_changes'.tr(),
                onPressed: _save,
                isLoading: _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
