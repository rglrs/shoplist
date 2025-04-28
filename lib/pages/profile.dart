import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_profile.dart'; // Import halaman EditProfile

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // Colors from the design
  final Color _headerBgColor = const Color(0xFF6B9AC4);
  final Color _inputBgColor = const Color(0xFFCBD7E3);
  final Color _buttonBgColor = const Color.fromARGB(255, 29, 64, 109);

  // Text Editing Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic> _profileData = {}; // To store profile data
  String _profileImageUrl =
      'https://storage.googleapis.com/a1aa/image/6116a172-74e8-4d74-5f2f-69b26bdd55ad.jpg'; // Default

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchProfile();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token == null) {
      setState(() {
        _errorMessage = 'Token tidak ditemukan. Silakan login kembali.';
        _isLoading = false;
      });
    }
  }

  // Combine _loadToken and _fetchProfile for sequential execution
  Future<void> _loadTokenAndFetchProfile() async {
    setState(() {
      _isLoading = true; // Start loading
      _errorMessage = null; // Clear any previous error
    });

    await _loadToken(); // Await token loading

    if (_token != null) {
      await _fetchProfile(); // Await profile fetching
    } else {
      setState(() => _isLoading = false); // Stop loading if no token
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.0.6:8000/api/profile',
        ), // Ganti dengan URL API Anda
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _profileData = data;
          // Set text field values
          _nameController.text = data['name'] ?? '';
          _usernameController.text = data['username'] ?? '';
          _emailController.text = data['email'] ?? '';
          _profileImageUrl =
              data['avatar_path'] ??
              ''; //ambil url dari response, default jika tidak ada
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Gagal memuat profil: ${response.body} (Status Code: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $error';
        _isLoading = false;
      });
    }
  }

  // Method to refresh the profile data
  Future<void> _refreshProfileData() async {
    await _fetchProfile();
  }

  /// Helper function to get the correct ImageProvider
  ImageProvider? getProfileImageProvider(String imagePath) {
    if (imagePath.isEmpty) return null;
    if (imagePath.startsWith('http')) return NetworkImage(imagePath);
    // Jika path relatif, tambahkan base URL sesuai backend Anda
    return NetworkImage('http://192.168.0.6:8000/storage/$imagePath');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : Column(
                  children: [
                    // Header with back button, title, and avatar
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 40, bottom: 120),
                          decoration: BoxDecoration(color: _headerBgColor),
                          child: const Center(
                            child: Text(
                              'My Profil',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                color: Colors.black,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          top: 40,
                          child: GestureDetector(
                            onTap: () {
                              // Handle back action
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                size: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -48,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: CircleAvatar(
                                  radius: 48,
                                  backgroundImage: getProfileImageProvider(
                                    _profileImageUrl,
                                  ),
                                  child:
                                      (_profileImageUrl.isEmpty)
                                          ? const Icon(
                                            Icons.person,
                                            size: 48,
                                            color: Colors.white,
                                          )
                                          : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 64),
                    // Input fields
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _buildInputField(
                            'Name',
                            _inputBgColor,
                            controller: _nameController,
                            enabled: false, // Make it non-editable
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            'Username',
                            _inputBgColor,
                            controller: _usernameController,
                            enabled: false, // Make it non-editable
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            'Email',
                            _inputBgColor,
                            keyboardType: TextInputType.emailAddress,
                            controller: _emailController,
                            enabled: false, // Make it non-editable
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            // Navigasi ke halaman edit profil DAN tunggu hasilnya.
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfile(),
                              ),
                            );

                            // Check if the result is true (or any other success indicator)
                            if (result == true) {
                              // Refresh profile data after returning from EditProfile
                              await _refreshProfileData();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _buttonBgColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              fontFamily: 'Inter',
                            ),
                          ),
                          child: const Text('Edit Profil'),
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
      ),
    );
  }

  Widget _buildInputField(
    String placeholder,
    Color bgColor, {
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller,
    bool enabled = true, // Added parameter to control editable state
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled, // Use the enabled parameter to set editable property
      decoration: InputDecoration(
        hintText: placeholder,
        filled: true,
        fillColor: bgColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9999),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF6B7A8A),
          fontWeight: FontWeight.w400,
        ),
      ),
      style: const TextStyle(color: Colors.black87),
    );
  }
}
