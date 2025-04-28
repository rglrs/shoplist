import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading =
      false; // Untuk menampilkan indikator loading saat proses login

  // Fungsi untuk melakukan login ke API
  Future<void> _login() async {
    if (_isLoading) return; // Prevent multiple login requests

    setState(() {
      _isLoading = true; // Set loading state
    });

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    // Validasi input
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Email dan password harus diisi.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.0.6:8000/api/login',
        ), // Sesuaikan dengan endpoint login Anda
        body: jsonEncode({'email': email, 'password': password}),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        // Jika login berhasil
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String token = data['token']; // Ambil token dari respons API Anda

        // Simpan token menggunakan shared_preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        // Navigasi ke halaman setelah login (ganti '/home' dengan rute yang sesuai)
        Navigator.pushReplacementNamed(context, '/shopList');
        _showSnackBar('Login Berhasil');
      } else {
        // Jika login gagal
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        final String errorMessage =
            errorData['message'] ??
            'Login gagal. Coba lagi.'; // Ambil pesan dari response
        _showSnackBar(errorMessage);
      }
    } catch (error) {
      // Handle error koneksi atau error lainnya
      _showSnackBar('Terjadi kesalahan: $error');
    } finally {
      setState(() {
        _isLoading = false; // Set loading state ke false setelah selesai
      });
    }
  }

  // Fungsi untuk menampilkan SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                  'Sign In',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
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
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
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
                ),
                const SizedBox(height: 8),
                Container(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 20),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading ? null : _login, // Disable saat loading
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 29, 64, 109),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth:
                                  3, // Optional: Sesuaikan ketebalan indikator
                            )
                            : const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 24),
                RichText(
                  text: TextSpan(
                    text: 'Belum punya akun? ',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                    children: [
                      TextSpan(
                        text: 'Silahkan sign up',
                        style: const TextStyle(
                          color: Color(0xFF1E3A5F),
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushNamed(context, '/signUp');
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
}
