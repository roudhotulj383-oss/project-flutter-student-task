import 'package:flutter/material.dart';

import '../../services/auth_services.dart';
import '../../utils/validators.dart';
import 'register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }

    final result = await AuthService().login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/dashboard',
        (route) => false,
      );
    } else {
      setState(() {
        _errorMessage = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Form(
              key: _formKey,

              child: Column(
                children: [
                  Image.asset(
      'assets/images/welcome.png',
          width: 120,
      height: 120,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Login',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium,
                  ),

                  const SizedBox(height: 30),

                  TextFormField(
                    controller: _emailController,

                    decoration: InputDecoration(
                      labelText: 'Email',

                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),

                      prefixIcon:
                          const Icon(Icons.email),
                    ),

                    validator: Validators.email,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,

                    obscureText: _obscurePassword,

                    decoration: InputDecoration(
                      labelText: 'Password',

                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),

                      prefixIcon:
                          const Icon(Icons.lock),

                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),

                        onPressed: () {
                          setState(() {
                            _obscurePassword =
                                !_obscurePassword;
                          });
                        },
                      ),
                    ),

                    validator: Validators.password,
                  ),

                  const SizedBox(height: 20),

                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: colorScheme.error,
                      ),
                    ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,

                    child: ElevatedButton(
                      onPressed:
                          _isLoading ? null : _handleLogin,

                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Masuk'),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [

                      const Text(
                        'Belum punya akun?',
                      ),

                      TextButton(
                        onPressed: () {

                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder: (context) =>
                                  const RegisterScreen(),
                            ),
                          );
                        },

                        child: const Text(
                          'Daftar',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}