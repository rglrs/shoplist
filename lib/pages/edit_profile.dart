import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfile extends StatefulWidget {
  const EditProfile({Key? key}) : super(key: key);

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _mailController = TextEditingController();
  // Removed _imageController as it's better to handle the image file directly
  // and display the current image differently if needed.

  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  File? _imageFile;
  String? _currentAvatarUrl; // To store the initial avatar URL

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _mailController.dispose();
    // _imageController.dispose(); // Removed
    super.dispose();
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

  Future<void> _loadTokenAndFetchProfile() async {
    await _loadToken();
    if (_token != null) {
      await _fetchProfile();
    }
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_token == null) {
      setState(() {
        _errorMessage = 'Token tidak tersedia.';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.6:8000/api/profile'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/json', // Added Accept header
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _nameController.text = data['name'] ?? '';
          _usernameController.text = data['username'] ?? '';
          _mailController.text = data['email'] ?? '';
          _currentAvatarUrl = data['avatar']; // Store current avatar URL
          // Don't set _imageController.text anymore
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
        _errorMessage = 'Terjadi kesalahan saat memuat profil: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        // No need to update a text controller for the image path
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_isLoading || _token == null) return; // Check token again

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use PUT for update, but API might expect POST for multipart/form-data
      // Double-check your API documentation. Let's assume PUT is correct for now.
      var request = http.MultipartRequest(
        'POST', //  Use POST.  Laravel often expects POST for form-data
        Uri.parse('http://192.168.0.6:8000/api/profile'),
      );

      request.headers['Authorization'] = 'Bearer $_token';
      // Add Accept header for consistency
      request.headers['Accept'] = 'application/json';

      // Add text fields
      request.fields['name'] = _nameController.text;
      request.fields['username'] = _usernameController.text;
      request.fields['email'] = _mailController.text;
      // IMPORTANT: Add method spoofing for PUT/PATCH in Laravel
      request.fields['_method'] = 'POST'; //  add this line

      // Only add the avatar file if a new one was picked
      if (_imageFile != null) {
        var stream = http.ByteStream(_imageFile!.openRead());
        var length = await _imageFile!.length();
        var multipartFile = http.MultipartFile(
          'avatar', // Make sure this field name matches your backend API
          stream,
          length,
          filename: _imageFile!.path.split('/').last,
        );
        request.files.add(multipartFile);
      }
      // DO NOT send the 'avatar' field if _imageFile is null.

      print('Sending update request...');
      print('Fields: ${request.fields}');
      print('Files: ${request.files.map((f) => f.filename)}');

      // Send the request and get the response
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Update Response Status Code: ${response.statusCode}');
      print('Update Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Optionally decode response if backend sends back updated user data
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        setState(() {
          _isLoading = false;
          // Clear the selected image file after successful upload
          _imageFile = null;
          // Optionally update _currentAvatarUrl if response contains new URL
          _currentAvatarUrl =
              responseData['avatar'] ?? _currentAvatarUrl; //  updated this line
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diupdate!'),
            backgroundColor: Colors.green,
          ),
        );
        // Pop *after* showing SnackBar and setting state
        Navigator.of(context).pop(true); // Pass true to indicate success
      } else {
        // Try to decode error message from JSON response body
        String serverError = response.body;
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          serverError = errorData['message'] ?? response.body;
          // Check for validation errors if your API provides them
          if (errorData.containsKey('errors')) {
            // Handle validation errors display more specifically if needed
            print('Validation Errors: ${errorData['errors']}');
          }
        } catch (e) {
          // Ignore if response body is not JSON
          print("Could not decode error response as JSON: $e");
        }

        setState(() {
          _errorMessage =
              'Gagal update profil: $serverError (Status Code: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error during profile update: $error');
      setState(() {
        _errorMessage = 'Terjadi kesalahan jaringan atau lainnya: $error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFD1DCE9);
    const buttonColor = Color.fromARGB(255, 29, 64, 109);
    const placeholderStyle = TextStyle(color: Color(0xFF6B7280));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Edit Profil',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          fontFamily: 'Inter',
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Placeholder for alignment
                ],
              ),
              const SizedBox(height: 24), // Reduced space a bit
              // Display Current Avatar and Chosen Image Preview
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: bgColor,
                      backgroundImage:
                          _imageFile != null
                              ? FileImage(
                                _imageFile!,
                              ) // Show picked image preview
                              : (_currentAvatarUrl != null &&
                                          _currentAvatarUrl!.isNotEmpty
                                      ? NetworkImage(
                                        _currentAvatarUrl!,
                                      ) // Show current network image
                                      : null)
                                  as ImageProvider?, // Cast to ImageProvider?
                      child:
                          (_imageFile == null &&
                                  (_currentAvatarUrl == null ||
                                      _currentAvatarUrl!.isEmpty))
                              ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              ) // Placeholder icon
                              : null,
                    ),
                    Material(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _pickImage,
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        hintText: 'Name',
                        bgColor: bgColor,
                        placeholderStyle: placeholderStyle,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _usernameController,
                        hintText: 'Username',
                        bgColor: bgColor,
                        placeholderStyle: placeholderStyle,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _mailController,
                        hintText: 'Mail',
                        keyboardType: TextInputType.emailAddress,
                        bgColor: bgColor,
                        placeholderStyle: placeholderStyle,
                      ),
                      const SizedBox(height: 32), // Adjusted spacing
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              fontFamily: 'Inter',
                            ),
                            disabledBackgroundColor: buttonColor.withOpacity(
                              0.5,
                            ), // Indicate disabled state
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                  : const Text(
                                    'Simpan Perubahan',
                                  ), // Changed button text
                        ),
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(
                        height: 20,
                      ), // Add some padding at the bottom
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // _buildTextField remains the same
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    Color? bgColor,
    TextStyle? placeholderStyle,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false, // Added readOnly option
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: TextStyle(
        color:
            readOnly
                ? Colors.grey[700]
                : Colors.black, // Adjust style if readOnly
        fontSize: 16,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: placeholderStyle,
        filled: true,
        fillColor: bgColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          // Ensure consistent border look
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          // Ensure consistent border look
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
