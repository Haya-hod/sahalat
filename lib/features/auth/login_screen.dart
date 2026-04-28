import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_state.dart';
import '../../core/locale_state.dart';
import '../../core/strings.dart';

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
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login({required bool asAdmin}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthState>();
    final err = await auth.signIn(
      _email.text.trim(),
      _password.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
      _error = err;
    });

    if (err == null) {
      auth.setAdmin(asAdmin);

      if (asAdmin) {
        Navigator.of(context).pushReplacementNamed(
          AdminDashboardScreen.route,
        );
      } else {
        Navigator.of(context).pushReplacementNamed(
          HomeScreen.route,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeState = context.watch<LocaleState>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA), // خلفية ناعمة
      body: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.language, color: Colors.blue),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: localeState.locale.languageCode,
                      items: const [
                        DropdownMenuItem(
                            value: 'ar', child: Text('العربية')),
                        DropdownMenuItem(
                            value: 'en', child: Text('English')),
                        DropdownMenuItem(
                            value: 'fr', child: Text('Français')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        localeState.setLocale(Locale(v));
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Image.asset(
                  'assets/logo.png',
                  height: 220,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.sports_soccer, size: 80),
                ),

                const SizedBox(height: 20),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "Enter email";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (_error != null)
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _loading ? null : () => _login(asAdmin: false),
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text("Log In"),
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextButton(
                        onPressed:
                            _loading ? null : () => _login(asAdmin: true),
                        child: const Text(
                          "Admin",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(
                              context, RegisterScreen.route);
                        },
                        child: const Text(
                          "Don't have an account? Create one",
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
