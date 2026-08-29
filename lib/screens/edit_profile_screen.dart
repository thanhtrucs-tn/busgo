// edit_profile_screen.dart
// Man hinh Chinh sua ho so cua ung dung BusGo.
// - Form + validation: Ho va ten, Email, So dien thoai, Mat khau, Ngay sinh.
// - Chon anh dai dien tu thu vien (image_picker): bam vao avatar HAY icon
//   may anh de mo thu vien, khong gioi han dinh dang / dung luong.
// - Quan ly nhieu dia chi, moi dia chi co Switch "Dat lam dia chi mac dinh"
//   (chi duy nhat 1 dia chi mac dinh mot luc).
// - Nut "Luu thay doi" kiem tra toan bo form truoc khi submit.
//
// Luu anh dang BYTES (Uint8List) + Image.memory: tuong thich moi nen tang
// (Android, Windows, Web) - khong dung dart:io File vi se loi tren Web.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';

// Regex kiem tra email: ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
final RegExp _emailReg = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
// Regex kiem tra so dien thoai: dung 10 chu so, bat dau bang so 0.
final RegExp _phoneReg = RegExp(r'^0[0-9]{9}$');

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Du lieu form.
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _dobCtrl;

  // Thiet bi chon anh + anh dai dien dang chon (luu dang bytes).
  final ImagePicker _picker = ImagePicker();
  Uint8List? _avatarBytes;

  // Ngay thang nam sinh (khong bat buoc).
  DateTime? _birthday;

  // Quan ly danh sach dia chi.
  late final List<TextEditingController> _addressCtrls;
  int _defaultAddressIndex = 0;

  // An/hien mat khau.
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Do du lieu hien tai tu ProfileService de nguoi dung sua tiep.
    final ProfileService profile = ProfileService.instance;

    _nameCtrl = TextEditingController(text: profile.name);
    _emailCtrl = TextEditingController(text: profile.email);
    _phoneCtrl = TextEditingController(text: profile.phone);
    _passwordCtrl = TextEditingController();
    _dobCtrl = TextEditingController(
      text: profile.birthday != null ? _formatDate(profile.birthday!) : '',
    );
    _birthday = profile.birthday;
    _avatarBytes = profile.avatarBytes;

    // Khoi tao dia chi tu ho so (neu chua co thi de 1 o trong).
    _addressCtrls = [
      for (final address in profile.addresses)
        TextEditingController(text: address),
      if (profile.addresses.isEmpty) TextEditingController(),
    ];
    _defaultAddressIndex = _addressCtrls.isEmpty
        ? 0
        : profile.defaultAddressIndex.clamp(0, _addressCtrls.length - 1);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _dobCtrl.dispose();
    for (final c in _addressCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  // ------------------------- Validators -------------------------

  String? _validateName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return context.tr('err_name_required');
    if (v.length > 32) return context.tr('err_name_max');
    return null;
  }

  String? _validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return context.tr('err_email_required');
    if (v.length > 64) return context.tr('err_email_max');
    if (!_emailReg.hasMatch(v)) return context.tr('err_email_format');
    return null;
  }

  String? _validatePhone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return context.tr('err_phone_required');
    if (!_phoneReg.hasMatch(v)) return context.tr('err_phone_format');
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.length > 32) return context.tr('err_password_max');
    return null;
  }

  // ------------------------- Avatar -------------------------

  // Mo thu vien anh, chon anh dai dien (khong gioi han loai/dung luong).
  Future<void> _pickAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return; // Nguoi dung huy chon.

      // Doc thanh bytes de hien thi tren moi nen tang (Android/Windows/Web).
      final Uint8List bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() => _avatarBytes = bytes);
    } catch (_) {
      // Loi quyen / khong mo duoc thu vien -> thong bao cho nguoi dung.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('avatar_pick_error'))),
      );
    }
  }

  // ------------------------- Ngay sinh -------------------------

  Future<void> _pickBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;

    setState(() {
      _birthday = picked;
      _dobCtrl.text = _formatDate(picked);
    });
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  // ------------------------- Dia chi -------------------------

  void _addAddress() {
    setState(() => _addressCtrls.add(TextEditingController()));
  }

  void _removeAddress(int index) {
    if (_addressCtrls.length <= 1) return;
    setState(() {
      _addressCtrls.removeAt(index).dispose();
      if (_defaultAddressIndex >= _addressCtrls.length) {
        _defaultAddressIndex = _addressCtrls.length - 1;
      }
    });
  }

  // Bat/Tat "dia chi mac dinh" cho mot dia chi.
  // Khi ban BAN ON cho dia chi moi, dia chi cu tu dong tat (chi 1 mac dinh).
  // Khi tat ON cua dia chi dang la mac dinh -> chuyen mac dinh ve dia chi dau.
  void _toggleDefault(int index, bool on) {
    setState(() {
      if (on) {
        _defaultAddressIndex = index;
      } else if (index == _defaultAddressIndex) {
        _defaultAddressIndex = _addressCtrls.isEmpty ? -1 : 0;
      }
    });
  }

  // ------------------------- Luu -------------------------

  void _save() {
    // Kiem tra toan bo form; neu khong hop le thi khong submit.
    if (!_formKey.currentState!.validate()) return;

    // Chi giu lai cac dia chi khong rong; tinh lai index mac dinh.
    final List<int> nonEmptyRows = <int>[];
    for (int i = 0; i < _addressCtrls.length; i++) {
      if (_addressCtrls[i].text.trim().isNotEmpty) nonEmptyRows.add(i);
    }
    final List<String> addresses =
        nonEmptyRows.map((i) => _addressCtrls[i].text.trim()).toList();
    final int defaultFiltered = nonEmptyRows.indexOf(_defaultAddressIndex);
    final int defaultIndex = addresses.isEmpty
        ? 0
        : (defaultFiltered < 0 ? 0 : defaultFiltered);

    // Luu ho so (hien thi lai dung truc tiep trong app).
    ProfileService.instance.save(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      birthday: _birthday,
      avatarBytes: _avatarBytes,
      addresses: addresses,
      defaultAddressIndex: defaultIndex,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('saved_success'))),
    );
    Navigator.pop(context);
  }

  // ------------------------- Giao dien -------------------------

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Ky tu dau cua ten de hien thi mac dinh khi chua chon anh.
    final String initial = _nameCtrl.text.trim().isEmpty
        ? '?'
        : _nameCtrl.text.trim().characters.first;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('edit_title'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            // ------------------------- Avatar -------------------------
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  // Chay vao avatar (hoac icon may anh) de mo thu vien anh.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _pickAvatar,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: colors.primaryContainer,
                          backgroundImage: _avatarBytes != null
                              ? MemoryImage(_avatarBytes!)
                              : null,
                          child: _avatarBytes == null
                              ? Text(
                                  initial,
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: colors.primary,
                                  ),
                                )
                              : null,
                        ),
                        // Icon may anh: vung cham rieng, ro rang.
                        GestureDetector(
                          onTap: _pickAvatar,
                          child: Container(
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
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.tr('label_avatar'),
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ------------------------- Thong tin ca nhan -------------------------
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                children: [
                  _field(
                    context,
                    TextFormField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      validator: _validateName,
                      decoration: InputDecoration(
                        labelText: context.tr('field_fullname'),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                  ),
                  _divider(context),
                  _field(
                    context,
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                      decoration: InputDecoration(
                        labelText: context.tr('field_email'),
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                    ),
                  ),
                  _divider(context),
                  _field(
                    context,
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: _validatePhone,
                      decoration: InputDecoration(
                        labelText: context.tr('field_phone'),
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                    ),
                  ),
                  _divider(context),
                  _field(
                    context,
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                      decoration: InputDecoration(
                        labelText: context.tr('field_password'),
                        hintText: context.tr('hint_password'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                    ),
                  ),
                  _divider(context),
                  _field(
                    context,
                    TextFormField(
                      controller: _dobCtrl,
                      readOnly: true,
                      enableInteractiveSelection: false,
                      onTap: _pickBirthday,
                      decoration: InputDecoration(
                        labelText: context.tr('field_birthday'),
                        hintText: context.tr('birthday_optional'),
                        prefixIcon: const Icon(Icons.cake_outlined),
                        suffixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ------------------------- Dia chi -------------------------
            _SectionTitle(context.tr('addresses')),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                children: [
                  for (int i = 0; i < _addressCtrls.length; i++) ...[
                    if (i > 0) _divider(context),
                    // O nhap dia chi + nut xoa.
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            context,
                            TextField(
                              controller: _addressCtrls[i],
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: context.tr('address_hint'),
                                prefixIcon: const Icon(Icons.place_outlined),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: context.tr('delete_address'),
                          disabledColor: colors.outlineVariant,
                          onPressed: _addressCtrls.length > 1
                              ? () => _removeAddress(i)
                              : null,
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                    // Switch "Dat lam dia chi mac dinh" cho tung dia chi.
                    SwitchListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.only(left: 12, right: 8),
                      secondary: Icon(
                        i == _defaultAddressIndex
                            ? Icons.star
                            : Icons.star_border,
                        color: i == _defaultAddressIndex
                            ? colors.primary
                            : colors.outlineVariant,
                        size: 20,
                      ),
                      title: Text(
                        context.tr('address_set_default'),
                        style: TextStyle(
                          fontSize: 13.5,
                          color: colors.onSurface,
                        ),
                      ),
                      value: i == _defaultAddressIndex,
                      onChanged: (on) => _toggleDefault(i, on),
                    ),
                  ],
                  _divider(context),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _addAddress,
                        icon: const Icon(Icons.add),
                        label: Text(context.tr('add_address')),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ------------------------- Luu thay doi -------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: Text(context.tr('save_changes')),
                  onPressed: _save,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(BuildContext context, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: child,
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 52,
      color: context.colors.outlineVariant,
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