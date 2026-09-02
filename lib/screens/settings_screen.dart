// settings_screen.dart
// Man hinh Cai dat cua ung dung BusGo.
// Danh sach duoc chia thanh cac nhom: Tai khoan, Tuy chinh,
// Thong bao, Bo nho & Ban do, He thong.
// Cac tuy chon duoc luu qua shared_preferences (SettingsService),
// mau sac lay tu theme, van ban lay tu he thong da ngon ngu.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/profile_service.dart';
import '../services/session_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Kich thuoc bo nho tam (mo phong).
  String _cacheSize = '12.4 MB';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings_title'))),
      body: ListenableBuilder(
        // Lang nghe SettingsService + ProfileService de cap nhat giao dien.
        listenable: Listenable.merge([
          SettingsService.instance,
          ProfileService.instance,
        ]),
        builder: (context, _) {
          final settings = SettingsService.instance;
          final profile = ProfileService.instance;

          return ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              // ============================ TÀI KHOẢN ============================
              _SectionHeader(label: context.tr('group_account')),
              _group(context, [
                _AccountCard(
                  name: profile.name,
                  email: profile.email,
                  avatarBytes: profile.avatarBytes,
                  onTap: _openProfile,
                ),
              ]),

              // ============================ TÙY CHỈNH ============================
              _SectionHeader(label: context.tr('group_prefs')),
              _group(context, [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: Text(context.tr('dark_mode')),
                  subtitle: Text(context.tr('dark_mode_sub')),
                  value: settings.darkMode,
                  onChanged: (v) => settings.setDarkMode(v),
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(context.tr('language')),
                  subtitle: Text(
                    context.tr('language_sub'),
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: settings.language,
                      borderRadius: BorderRadius.circular(12),
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                      ],
                      onChanged: (v) {
                        if (v != null) settings.setLanguage(v);
                      },
                    ),
                  ),
                ),
              ]),

              // ============================ THÔNG BÁO ============================
              _SectionHeader(label: context.tr('group_notifs')),
              _group(context, [
                SwitchListTile(
                  secondary: const Icon(Icons.directions_bus_outlined),
                  title: Text(context.tr('notif_arrival')),
                  subtitle: Text(context.tr('notif_arrival_sub')),
                  value: settings.notifyArrival,
                  onChanged: (v) => settings.setNotifyArrival(v),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.warning_amber_outlined),
                  title: Text(context.tr('notif_issue')),
                  subtitle: Text(context.tr('notif_issue_sub')),
                  value: settings.notifyIssue,
                  onChanged: (v) => settings.setNotifyIssue(v),
                ),
              ]),

              // ========================== BỘ NHỚ & BẢN ĐỒ ==========================
              _SectionHeader(label: context.tr('group_storage')),
              _group(context, [
                ListTile(
                  leading: const Icon(Icons.cleaning_services_outlined),
                  title: Text(context.tr('clear_cache')),
                  subtitle: Text(
                    context.tr('clear_cache_sub', params: {'size': _cacheSize}),
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colors.outlineVariant,
                  ),
                  onTap: _confirmClearCache,
                ),
                ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: Text(context.tr('offline_map')),
                  subtitle: Text(
                    context.tr('offline_map_sub'),
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colors.outlineVariant,
                  ),
                  onTap: _onDownloadOfflineMap,
                ),
              ]),

              // ============================ HỆ THỐNG ============================
              _SectionHeader(label: context.tr('group_system')),
              _group(context, [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(context.tr('about_app')),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colors.outlineVariant,
                  ),
                  onTap: _onAboutApp,
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(context.tr('privacy_policy')),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colors.outlineVariant,
                  ),
                  onTap: _onPrivacyPolicy,
                ),
              ]),

              const SizedBox(height: 12),

              // Nut dang xuat mau do noi bat.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.error,
                      foregroundColor: colors.onError,
                    ),
                    icon: const Icon(Icons.logout),
                    label: Text(context.tr('logout')),
                    onPressed: _confirmLogout,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Bao boc mot nhom cac dong cai dat vao khoi mau surface co vien.
  Widget _group(BuildContext context, List<Widget> tiles) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 56, color: context.colors.outlineVariant),
            tiles[i],
          ],
        ],
      ),
    );
  }

  // Mo man hinh xem ho so ca nhan.
  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  // Xac nhan xoa bo nho tam.
  void _confirmClearCache() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('clear_cache_confirm_title')),
        content: Text(context.tr('clear_cache_confirm_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _cacheSize = '0 KB');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('cache_cleared'))),
              );
            },
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
  }

  // Tai ban do ngoai tuyen (mo phong).
  void _onDownloadOfflineMap() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('downloading_map'))),
    );
  }

  // Hien thong tin ve ung dung.
  void _onAboutApp() {
    showAboutDialog(
      context: context,
      applicationName: 'BusGo',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.directions_bus,
        size: 40,
        color: context.colors.primary,
      ),
      children: [
        Text(context.tr('about_content')),
      ],
    );
  }

  // Hien chinh sach bao mat (noi dung tom tat).
  void _onPrivacyPolicy() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('privacy_policy')),
        content: Text(context.tr('privacy_content')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('close')),
          ),
        ],
      ),
    );
  }

  // Xac nhan dang xuat: xoa JWT + phien dang nhap, quay ve man hinh dang nhap.
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('logout_confirm_title')),
        content: Text(context.tr('logout_confirm_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: context.colors.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('logout')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Xoa JWT khoi secure storage + user khoi bo nho.
    await SessionService.instance.logout();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('logged_out'))),
    );

    // Quay ve man hinh dang nhap (bo toan bo stack hien tai).
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

// Tieu de mot nhom cai dat.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: context.colors.primary,
        ),
      ),
    );
  }
}

// Hien thi thong tin tai khoan: avatar, ten, email.
// Cham vao the de mo man hinh xem ho so ca nhan.
class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.name,
    required this.email,
    this.avatarBytes,
    required this.onTap,
  });

  final String name;
  final String email;
  final Uint8List? avatarBytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final String initial = name.isEmpty ? '?' : name.trim().characters.first;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: colors.primaryContainer,
        backgroundImage:
            avatarBytes != null ? MemoryImage(avatarBytes!) : null,
        child: avatarBytes == null
            ? Text(
                initial,
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              )
            : null,
      ),
      title: Text(
        name,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
        ),
      ),
      subtitle: Text(
        email,
        style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
      ),
      trailing: Icon(Icons.chevron_right, color: colors.outlineVariant),
    );
  }
}