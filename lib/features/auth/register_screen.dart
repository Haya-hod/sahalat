import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../colors.dart';
import '../../core/auth_state.dart';
import '../../core/user_store.dart';
import '../../core/locale_state.dart';
import '../../core/strings.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  static const route = '/register';
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  DateTime? _birthdate;
  String? _nationality;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  final _nationalities = [
    'Saudi', 'Emirati', 'Kuwaiti', 'Bahraini',
    'Qatari', 'Omani', 'Egyptian', 'Jordanian', 'Other',
  ];

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickBirthdate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      initialDate: DateTime(2000),
    );
    if (picked != null && mounted) setState(() => _birthdate = picked);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final lang = context.read<LocaleState>().locale.languageCode;
    setState(() { _loading = true; _error = null; });

    final auth = context.read<AuthState>();
    final err = await auth.register(
      _email.text.trim(),
      _password.text.trim(),
      lang: lang,
    );

    if (!mounted) return;
    setState(() { _loading = false; _error = err; });

    if (err == null) {
      context.read<UserStore>().setProfile(
        firstName:   _firstName.text.trim(),
        lastName:    _lastName.text.trim(),
        nationality: _nationality ?? '',
        birthdate:   _birthdate,
      );
      Navigator.pushReplacementNamed(context, HomeScreen.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleState>().locale.languageCode;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(L(context.watch<LocaleState>().locale.languageCode).t('create_account'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Image.asset(
                'assets/logo.png',
                height: 110,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.sports_soccer,
                  size: 70,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang == 'ar' ? 'إنشاء حساب' : (lang == 'fr' ? 'Inscription' : 'Sign Up'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lang == 'ar' ? 'أنشئ حسابك في سهّلت' : (lang == 'fr' ? 'Créez votre compte Sahalat' : 'Create your Sahalat account'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Row: First + Last name
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstName,
                              decoration: InputDecoration(
                                labelText: lang == 'ar' ? 'الاسم الأول' : (lang == 'fr' ? 'Prénom' : 'First Name'),
                                prefixIcon: const Icon(Icons.person_outline_rounded),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? (lang == 'ar' ? 'مطلوب' : 'Required')
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastName,
                              decoration: InputDecoration(
                                labelText: lang == 'ar' ? 'اسم العائلة' : (lang == 'fr' ? 'Nom de famille' : 'Last Name'),
                                prefixIcon: const Icon(Icons.badge_outlined),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? (lang == 'ar' ? 'مطلوب' : 'Required')
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Birthdate
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _pickBirthdate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: lang == 'ar' ? 'تاريخ الميلاد' : (lang == 'fr' ? 'Date de naissance' : 'Birthdate'),
                            prefixIcon: const Icon(Icons.cake_outlined),
                          ),
                          child: Text(
                            _birthdate == null
                                ? (lang == 'ar' ? 'اختر التاريخ' : (lang == 'fr' ? 'Choisir la date' : 'Select date'))
                                : '${_birthdate!.day}/${_birthdate!.month}/${_birthdate!.year}',
                            style: TextStyle(
                              color: _birthdate == null
                                  ? AppColors.textHint
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Nationality
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: lang == 'ar' ? 'الجنسية' : (lang == 'fr' ? 'Nationalité' : 'Nationality'),
                          prefixIcon: const Icon(Icons.flag_outlined),
                        ),
                        items: _nationalities
                            .map((n) => DropdownMenuItem(
                                  value: n,
                                  child: Text(n),
                                ))
                            .toList(),
                        onChanged: (v) => _nationality = v,
                        validator: (v) =>
                            v == null ? (lang == 'ar' ? 'اختر الجنسية' : 'Select nationality') : null,
                      ),
                      const SizedBox(height: 14),

                      // Email
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: lang == 'ar' ? 'البريد الإلكتروني' : 'Email',
                          prefixIcon: const Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return lang == 'ar' ? 'أدخل البريد' : 'Enter email';
                          final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          if (!emailRegex.hasMatch(v.trim())) return lang == 'ar' ? 'صيغة البريد غير صحيحة' : 'Invalid email format';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Password
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: lang == 'ar' ? 'كلمة المرور' : (lang == 'fr' ? 'Mot de passe' : 'Password'),
                          prefixIcon:
                              const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textHint,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => v != null && v.length < 6
                            ? (lang == 'ar' ? 'الحد الأدنى 6 أحرف' : 'Min 6 characters')
                            : null,
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.error, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _register,
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(lang == 'ar' ? 'إنشاء الحساب' : (lang == 'fr' ? 'Créer le compte' : 'Create Account')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
