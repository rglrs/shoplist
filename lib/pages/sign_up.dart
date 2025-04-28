import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final String name = _nameController.text.trim();
    final String username = _usernameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnackBar('All fields must be filled.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Password and Confirm Password do not match.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.6:8000/api/register'),
        body: jsonEncode({
          'name': name,
          'username': username,
          'email': email,
          'password': password,
          'password_confirmation': confirmPassword,
        }),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 201) {
        _showSnackBar('Registration Successful! Please Sign In.');
        Navigator.pushReplacementNamed(context, '/signIn');
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Registration failed. Please try again.';
        _showSnackBar(errorMessage);
      }
    } on SocketException {
      _showSnackBar('No Internet connection. Please try again.');
    } catch (error) {
      _showSnackBar('An error occurred: ${error.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 48),
                _buildTextField(_nameController, 'Name', TextInputType.name),
                const SizedBox(height: 24),
                _buildTextField(
                  _usernameController,
                  'Username',
                  TextInputType.text,
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  _emailController,
                  'Email',
                  TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  _passwordController,
                  'Password',
                  TextInputType.visiblePassword,
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  _confirmPasswordController,
                  'Confirm Password',
                  TextInputType.visiblePassword,
                  obscureText: true,
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 29, 64, 109),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 3,
                            )
                            : const Text('Sign Up'),
                  ),
                ),
                const SizedBox(height: 24),
                RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                    children: [
                      TextSpan(
                        text: 'Please sign in',
                        style: const TextStyle(
                          color: Color(0xFF1E3A5F),
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushNamed(context, '/signIn');
                              },
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

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    TextInputType keyboardType, {
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFD1DFEB),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Color(0xFF718096)),
      ),
      style: const TextStyle(color: Color(0xFF718096)),
    );
  }
}
