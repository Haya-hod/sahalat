import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_state.dart';
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
  String? _error;

  final _nationalities = [
    "Saudi",
    "Emirati",
    "Kuwaiti",
    "Bahraini",
    "Qatari",
    "Omani",
    "Egyptian",
    "Jordanian",
    "Other",
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

    if (picked != null) setState(() => _birthdate = picked);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthState>();
    final err = await auth.register(
      _email.text.trim(),
      _password.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
      _error = err;
    });

    if (err == null) {
      Navigator.pushReplacementNamed(context, HomeScreen.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(title: const Text("Create Account")),
      body: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 150,
                ),
                const SizedBox(height: 20),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      /// FIRST NAME
                      TextFormField(
                        controller: _firstName,
                        decoration: const InputDecoration(
                          labelText: "First Name",
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? "Enter first name" : null,
                      ),
                      const SizedBox(height: 12),

                      /// LAST NAME
                      TextFormField(
                        controller: _lastName,
                        decoration: const InputDecoration(
                          labelText: "Last Name",
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? "Enter last name" : null,
                      ),
                      const SizedBox(height: 12),

                      /// BIRTHDATE
                      InkWell(
                        onTap: _pickBirthdate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: "Birthdate",
                            prefixIcon: Icon(Icons.cake),
                          ),
                          child: Text(
                            _birthdate == null
                                ? "Select date"
                                : "${_birthdate!.day}/${_birthdate!.month}/${_birthdate!.year}",
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      /// NATIONALITY
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Nationality",
                          prefixIcon: Icon(Icons.flag),
                        ),
                        items: _nationalities
                            .map((n) => DropdownMenuItem(
                                  value: n,
                                  child: Text(n),
                                ))
                            .toList(),
                        onChanged: (v) => _nationality = v,
                        validator: (v) =>
                            v == null ? "Select nationality" : null,
                      ),
                      const SizedBox(height: 12),

                      /// EMAIL
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? "Enter email" : null,
                      ),
                      const SizedBox(height: 12),

                      /// PASSWORD
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock),
                        ),
                        validator: (v) =>
                            v != null && v.length < 6
                                ? "Min 6 characters"
                                : null,
                      ),
                      const SizedBox(height: 16),

                      if (_error != null)
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),

                      const SizedBox(height: 16),

                      /// BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _register,
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text("Create Account"),
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
