// profile_screen.dart
// Man hinh Xem ho so ca nhan cua ung dung BusGo.
// Hien thi avatar, ten, email, so dien thoai, ngay sinh, danh sach dia chi
// va dia chi mac dinh. Du lieu lay tu ProfileService (da luu khi chinh sua).
// Bam vao avatar de tai anh tu thu vien thiet bi (dinh dang bat ky)
// lam anh dai dien moi. Co nut "Chinh sua ho so" chuyen sang man hinh chinh sua.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Tai anh tu thu vien thiet bi (khong gioi han dinh dang) lam avatar moi.
  Future<void> _pickAvatar(BuildContext context) async {
    final ProfileService profile = ProfileService.instance;
    try {
      // ImageSource.gallery: chon tu thu vien anh tren Android/Windows/Web.
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (image == null) return; // Nguoi dung huy chon.

      // Doc thanh bytes de hien thi tren moi nen tang (khong dung File).
      final Uint8List bytes = await image.readAsBytes();
      if (!context.mounted) return;

      // Luu vao ProfileService -> ProfileService goi API /profile/me
      // de luu dung cho tai khoan dang dang nhap.
      final ProfileResult result = await profile.save(avatarBytes: bytes);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success ? context.tr('avatar_updated') : result.message,
          ),
        ),
      );
    } catch (_) {
      // Loi quyen / khong mo duoc thu vien -> thong bao cho nguoi dung.
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('avatar_pick_error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('profile_title'))),
      body: ListenableBuilder(
        // Cap nhat ngay khi ho so thay doi (sau khi doi avatar / chinh sua).
        listenable: ProfileService.instance,
        builder: (context, _) {
          final ProfileService profile = ProfileService.instance;

          // Đang tải hồ sơ từ server: hiện vòng xoay để không hiển thị
          // nhầm (hoặc thoáng qua) dữ liệu của tài khoản trước.
          if (profile.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              // ------------------------- Avatar + ten + email -------------------------
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    // Avatar co hieu may anh: bam de tai anh tu thu vien.
                    GestureDetector(
                      onTap: () => _pickAvatar(context),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: colors.primaryContainer,
                            backgroundImage: profile.avatarBytes != null
                                ? MemoryImage(profile.avatarBytes!)
                                : null,
                            child: profile.avatarBytes == null
                                ? Text(
                                    profile.initial,
                                    style: TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      color: colors.primary,
                                    ),
                                  )
                                : null,
                          ),
                          // Icon may anh: gợi ý "bam vao day de doi avatar".
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.surface,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.photo_camera,
                              size: 18,
                              color: colors.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('label_avatar'),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      profile.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.email,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ------------------------- Thong tin ca nhan -------------------------
              _SectionTitle(context.tr('personal_info')),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: context.tr('field_phone'),
                      value: profile.phone,
                    ),
                    Divider(
                      height: 1,
                      indent: 52,
                      color: colors.outlineVariant,
                    ),
                    _InfoRow(
                      icon: Icons.cake_outlined,
                      label: context.tr('field_birthday'),
                      value: profile.birthday != null
                          ? _formatDate(profile.birthday!)
                          : context.tr('not_updated'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ------------------------- Dia chi -------------------------
              _SectionTitle(context.tr('addresses')),
              if (profile.addresses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: EmptyState(
                    icon: Icons.location_off_outlined,
                    message: context.tr('no_addresses'),
                  ),
                )
              else
                Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Column(
                    children: [
                      for (int i = 0; i < profile.addresses.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            indent: 52,
                            color: colors.outlineVariant,
                          ),
                        _AddressRow(
                          index: i,
                          address: profile.addresses[i],
                          isDefault: profile.addresses.length > 1 &&
                              i == profile.defaultAddressIndex,
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // ------------------------- Chinh sua ho so -------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(context.tr('edit_profile')),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }
}

// Mot dong thong tin: icon + nhan + gia tri.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: colors.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: value == context.tr('not_updated')
                    ? colors.onSurfaceVariant
                    : colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Mot dia chi trong danh sach, co nhan "mac dinh" neu duoc chon.
class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.index,
    required this.address,
    required this.isDefault,
  });

  final int index;
  final String address;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.place, size: 18, color: colors.error),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              address,
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurface,
              ),
            ),
          ),
          if (isDefault)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                context.tr('address_default'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.onPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Tieu de nho cua mot phan tren man hinh.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: context.colors.onSurface,
        ),
      ),
    );
  }
}