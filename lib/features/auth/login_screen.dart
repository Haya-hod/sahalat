import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../colors.dart';
import '../../core/auth_state.dart';
import '../../core/locale_state.dart';
import '../home/home_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  static const route = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final lang = context.read<LocaleState>().locale.languageCode;
    setState(() { _loading = true; _error = null; });
    final auth = context.read<AuthState>();
    final err = await auth.signIn(_email.text.trim(), _password.text.trim(), lang: lang);
    if (!mounted) return;
    setState(() { _loading = false; _error = err; });
    if (err == null) {
      Navigator.of(context).pushReplacementNamed(
        auth.isAdmin ? AdminDashboardScreen.route : HomeScreen.route,
      );
    }
  }

  Future<void> _showAdminDialog() async {
    final lang = context.read<LocaleState>().locale.languageCode;
    final codeCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang == 'ar' ? 'دخول المدير' : 'Admin Access'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            lang == 'ar'
                ? 'أدخل كود الإدارة للمتابعة'
                : 'Enter the admin code to continue',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: codeCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: lang == 'ar' ? 'كود الإدارة' : 'Admin Code',
              prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(lang == 'ar' ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(lang == 'ar' ? 'تحقق' : 'Verify'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() { _loading = true; _error = null; });
    final auth = context.read<AuthState>();

    // Sign in with Firebase first.
    final loginErr = await auth.signIn(_email.text.trim(), _password.text.trim(), lang: lang);
    if (!mounted) return;
    if (loginErr != null) {
      setState(() { _loading = false; _error = loginErr; });
      return;
    }

    // Verify admin passcode (synchronous — no network call needed).
    final adminErr = auth.requestAdminAccess(codeCtrl.text.trim(), lang: lang);
    if (!mounted) return;
    setState(() { _loading = false; _error = adminErr; });
    if (adminErr == null) {
      Navigator.of(context).pushReplacementNamed(AdminDashboardScreen.route);
    }
  }


  @override
  Widget build(BuildContext context) {
    final localeState = context.watch<LocaleState>();
    final lang = localeState.locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Language picker
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language, color: AppColors.primary, size: 18),
                      const SizedBox(width: 6),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: lang,
                          isDense: true,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'ar', child: Text('العربية')),
                            DropdownMenuItem(value: 'en', child: Text('English')),
                            DropdownMenuItem(value: 'fr', child: Text('Français')),
                          ],
                          onChanged: (v) {
                            if (v != null) localeState.setLocale(Locale(v));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Logo
              Image.asset(
                'assets/logo.png',
                height: 160,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.sports_soccer,
                  size: 90,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 32),

              // Card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang == 'ar' ? 'تسجيل الدخول' : (lang == 'fr' ? 'Connexion' : 'Log In'),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lang == 'ar' ? 'مرحباً بعودتك 👋' : (lang == 'fr' ? 'Bon retour 👋' : 'Welcome back 👋'),
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: lang == 'ar' ? 'البريد الإلكتروني' : (lang == 'fr' ? 'E-mail' : 'Email'),
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

                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: lang == 'ar' ? 'كلمة المرور' : (lang == 'fr' ? 'Mot de passe' : 'Password'),
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textHint,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty ? (lang == 'ar' ? 'أدخل كلمة المرور' : 'Enter password') : null,
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_error!,
                                  style: const TextStyle(color: AppColors.error, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _loading
                              ? const SizedBox(width: 22, height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : Text(lang == 'ar' ? 'تسجيل الدخول' : (lang == 'fr' ? 'Connexion' : 'Log In')),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Admin Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : _showAdminDialog,
                          icon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
                          label: Text(lang == 'ar' ? 'مدير النظام' : 'Admin'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.green,
                            side: const BorderSide(color: AppColors.green, width: 1.8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      lang == 'ar' ? 'ليس لديك حساب؟' : "Don't have an account?",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, RegisterScreen.route),
                    child: Text(
                      lang == 'ar' ? 'أنشئ حساباً' : 'Create one',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
