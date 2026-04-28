import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../colors.dart';
import '../../core/locale_state.dart';
import '../../core/strings.dart';
import '../../core/auth_state.dart';
import '../../core/user_store.dart';

class ProfileScreen extends StatefulWidget {
  static const route = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editMode = false;
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  String? _selectedNationality;

  final List<String> _nationalities = [
    'Saudi', 'Emirati', 'Kuwaiti', 'Bahraini',
    'Qatari', 'Omani', 'Egyptian', 'Jordanian', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    final store = context.read<UserStore>();
    _firstNameCtrl = TextEditingController(text: store.firstName);
    _lastNameCtrl  = TextEditingController(text: store.lastName);
    _selectedNationality = store.nationality.isEmpty ? null : store.nationality;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final store = context.read<UserStore>();
    final lang = context.read<LocaleState>().locale.languageCode;
    store.setProfile(
      firstName:   _firstNameCtrl.text.trim().isEmpty ? store.firstName : _firstNameCtrl.text.trim(),
      lastName:    _lastNameCtrl.text.trim().isEmpty  ? store.lastName  : _lastNameCtrl.text.trim(),
      nationality: _selectedNationality ?? store.nationality,
    );
    setState(() => _editMode = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(lang == 'ar' ? 'تم تحديث الملف بنجاح' : 'Profile updated successfully'),
        ]),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeState = context.watch<LocaleState>();
    final lang = localeState.locale.languageCode;
    final l = L(lang);
    final auth = context.watch<AuthState>();
    final store = context.watch<UserStore>();
    final user = auth.user;

    // Sync controllers when not editing
    if (!_editMode) {
      _firstNameCtrl.text = store.firstName;
      _lastNameCtrl.text  = store.lastName;
      _selectedNationality = store.nationality.isEmpty ? null : store.nationality;
    }

    final displayName = store.fullName.isNotEmpty
        ? store.fullName
        : (user?.email?.split('@').first ?? 'User');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.t('my_profile')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _editMode
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    TextButton(
                      onPressed: () => setState(() => _editMode = false),
                      child: Text(lang == 'ar' ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        minimumSize: const Size(70, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(lang == 'ar' ? 'حفظ' : 'Save', style: const TextStyle(fontSize: 14)),
                    ),
                  ])
                : TextButton.icon(
                    onPressed: () => setState(() => _editMode = true),
                    icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                    label: Text(lang == 'ar' ? 'تعديل' : 'Edit', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          // ── Avatar Card ──
          _Card(child: Row(children: [
            Stack(children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.surfaceAlt,
                child: const Icon(Icons.person_rounded, size: 38, color: AppColors.primary),
              ),
              if (_editMode)
                Positioned(right: 0, bottom: 0,
                  child: Container(
                    width: 22, height: 22,
                    decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_outlined, size: 13, color: Colors.white),
                  )),
            ]),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(displayName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(user?.email ?? '',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ])),
          ])),

          const SizedBox(height: 16),

          // ── Profile Info ──
          _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionTitle(lang == 'ar' ? 'ملفي الشخصي' : 'My Profile'),
            const SizedBox(height: 16),

            // Email (read-only)
            _InfoRow(icon: Icons.mail_outline_rounded, label: lang == 'ar' ? 'البريد' : 'Email', value: user?.email ?? ''),
            const _Divider(),

            // First Name
            _editMode
                ? _EditField(controller: _firstNameCtrl, label: lang == 'ar' ? 'الاسم الأول' : 'First Name', icon: Icons.person_outline_rounded)
                : _InfoRow(icon: Icons.person_outline_rounded, label: lang == 'ar' ? 'الاسم الأول' : 'First Name',
                    value: store.firstName.isEmpty ? '-' : store.firstName),
            const _Divider(),

            // Last Name
            _editMode
                ? _EditField(controller: _lastNameCtrl, label: lang == 'ar' ? 'اسم العائلة' : 'Last Name', icon: Icons.badge_outlined)
                : _InfoRow(icon: Icons.badge_outlined, label: lang == 'ar' ? 'اسم العائلة' : 'Last Name',
                    value: store.lastName.isEmpty ? '-' : store.lastName),
            const _Divider(),

            // Birthdate
            _editMode
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                          initialDate: store.birthdate ?? DateTime(2000),
                        );
                        if (picked != null) store.updateBirthdate(picked);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: lang == 'ar' ? 'تاريخ الميلاد' : 'Birthdate',
                          prefixIcon: const Icon(Icons.cake_outlined),
                          isDense: true,
                        ),
                        child: Text(
                          store.birthdate == null
                              ? (lang == 'ar' ? 'اختر التاريخ' : 'Select date')
                              : '${store.birthdate!.day}/${store.birthdate!.month}/${store.birthdate!.year}',
                          style: TextStyle(
                            color: store.birthdate == null ? AppColors.textHint : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  )
                : _InfoRow(
                    icon: Icons.cake_outlined,
                    label: lang == 'ar' ? 'تاريخ الميلاد' : 'Birthdate',
                    value: store.birthdate == null
                        ? '-'
                        : '${store.birthdate!.day}/${store.birthdate!.month}/${store.birthdate!.year}',
                  ),
            const _Divider(),

            // Nationality
            _editMode
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: DropdownButtonFormField<String>(
                      value: _selectedNationality,
                      decoration: InputDecoration(
                        labelText: lang == 'ar' ? 'الجنسية' : 'Nationality',
                        prefixIcon: const Icon(Icons.flag_outlined),
                        isDense: true,
                      ),
                      items: _nationalities
                          .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedNationality = v),
                    ),
                  )
                : _InfoRow(icon: Icons.flag_outlined, label: lang == 'ar' ? 'الجنسية' : 'Nationality',
                    value: store.nationality.isEmpty ? '-' : store.nationality),
          ])),

          const SizedBox(height: 16),

          // ── Language ──
          _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionTitle(l.t('language')),
            const SizedBox(height: 14),
            Row(children: [
              _IconBubble(icon: Icons.language_rounded, color: AppColors.surfaceAlt, iconColor: AppColors.primary),
              const SizedBox(width: 14),
              Expanded(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: lang,
                    isExpanded: true,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                    items: const [
                      DropdownMenuItem(value: 'ar', child: Text('العربية')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'fr', child: Text('Français')),
                    ],
                    onChanged: (v) { if (v != null) localeState.setLocale(Locale(v)); },
                  ),
                ),
              )),
            ]),
          ])),

          const SizedBox(height: 16),

          // ── Account Badge ──
          _Card(child: Row(children: [
            _IconBubble(
              icon: auth.isAdmin ? Icons.admin_panel_settings_outlined : Icons.verified_user_outlined,
              color: auth.isAdmin ? const Color(0xFFFFFBEB) : AppColors.greenPale,
              iconColor: auth.isAdmin ? AppColors.warning : AppColors.green,
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(auth.isAdmin ? lang == 'ar' ? 'مدير' : 'Admin' : lang == 'ar' ? 'زائر' : 'Visitor',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
              Text(
                auth.isAdmin ? lang == 'ar' ? 'لديك صلاحية لوحة الازدحام.' : 'You have access to the crowd dashboard.' : lang == 'ar' ? 'حساب زائر عادي.' : 'Standard visitor account.',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: auth.isAdmin ? AppColors.warning : AppColors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                auth.isAdmin ? lang == 'ar' ? 'مدير' : 'ADMIN' : lang == 'ar' ? 'زائر' : 'VISITOR',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),
          ])),

          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// ── Helpers ──

Widget _sectionTitle(String text) => Text(text,
  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary));

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(children: [
      Icon(icon, size: 20, color: AppColors.primary),
      const SizedBox(width: 8),
      Flexible(
        flex: 2,
        child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ),
      const Spacer(),
      const SizedBox(width: 8),
      Flexible(
        flex: 3,
        child: Text(value, textAlign: TextAlign.end, overflow: TextOverflow.ellipsis, maxLines: 1,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
    ]),
  );
}

class _EditField extends StatelessWidget {
  final TextEditingController controller; final String label; final IconData icon;
  const _EditField({required this.controller, required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), isDense: true),
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Divider(height: 1, thickness: 1, color: AppColors.border);
}

class _IconBubble extends StatelessWidget {
  final IconData icon; final Color color, iconColor;
  const _IconBubble({required this.icon, required this.color, required this.iconColor});
  @override
  Widget build(BuildContext context) => Container(
    width: 44, height: 44,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
    child: Icon(icon, color: iconColor, size: 22),
  );
}
