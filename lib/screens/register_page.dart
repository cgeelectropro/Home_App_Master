import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_app/services/provider/user_provider.dart';
import 'package:home_app/screens/home_page.dart';

class RegisterPage extends StatefulWidget {
  static const String route = '/register';

  const RegisterPage({super.key});
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController(); // For admin notification
  bool _isPasswordVisible = false;
  bool _isNewUser = false;
  bool _isRequestPending = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      try {
        if (_isNewUser) {
          // Send registration request to admin
          _isRequestPending = await userProvider.requestAccess(
            email: _emailController.text,
            password: _passwordController.text,
          );

          if (_isRequestPending && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Registration request sent to administrator. You will be notified when approved.')),
            );
            // Reset form or navigate to waiting screen
            _formKey.currentState!.reset();
          }
        } else {
          // Normal login for existing users
          final success = await userProvider.login(
            _emailController.text,
            _passwordController.text,
          );

          if (success && mounted) {
            Navigator.pushReplacementNamed(context, HomePage.route);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Authentication failed: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final existingUser = userProvider.user;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (existingUser != null) ...[
                  // Existing user profile widgets
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(
                        existingUser.picture.isNotEmpty
                            ? existingUser.picture
                            : 'https://via.placeholder.com/100'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome back, ${existingUser.name}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 32),
                ],

                if (_isNewUser) ...[
                  // Email field for new registration
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      helperText:
                          'Administrator will send approval to this email',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (_isNewUser && value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit button
                ElevatedButton(
                  onPressed: userProvider.isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: userProvider.isLoading
                      ? const CircularProgressIndicator()
                      : Text(_isNewUser ? 'Request Access' : 'Login'),
                ),
                const SizedBox(height: 16),

                // Toggle button
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isNewUser = !_isNewUser;
                      _formKey.currentState?.reset();
                    });
                  },
                  child: Text(_isNewUser
                      ? 'Already have an account? Login'
                      : 'Request new account'),
                ),

                if (!_isNewUser) ...[
                  TextButton(
                    onPressed: () {
                      // Handle forgot password
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
