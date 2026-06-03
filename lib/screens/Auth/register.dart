import 'package:flutter/material.dart';

import '../../services/auth_services.dart';
import '../../utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {

  final _formKey = GlobalKey<FormState>();

  final _nameController =
      TextEditingController();

  final _emailController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  bool _isLoading = false;

  String? _errorMessage;

  @override
  void dispose() {

    _nameController.dispose();

    _emailController.dispose();

    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _handleRegister() async {

    if (_isLoading) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    if (!_formKey.currentState!.validate()) {

      setState(() => _isLoading = false);

      return;
    }

    final result =
        await AuthService().register(

      name: _nameController.text.trim(),

      email: _emailController.text.trim(),

      password:
          _passwordController.text.trim(),

      role: 'student',
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success) {

      Navigator.of(context)
          .pushNamedAndRemoveUntil(
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

    final colorScheme =
        Theme.of(context).colorScheme;

    return Scaffold(

      appBar: AppBar(
        title: const Text('Register'),
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(24),

        child: Form(

          key: _formKey,

          child: Column(

            children: [

              TextFormField(
                controller: _nameController,

                decoration: InputDecoration(
                  labelText: 'Nama',

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),

                validator: Validators.name,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,

                decoration: InputDecoration(
                  labelText: 'Email',

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),

                validator: Validators.email,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,

                obscureText: true, 

                decoration: InputDecoration(
                  labelText: 'Password',

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
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

                  onPressed: _isLoading
                      ? null
                      : _handleRegister,

                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Daftar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}