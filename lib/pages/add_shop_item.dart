import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddShopItemPage extends StatefulWidget {
  const AddShopItemPage({super.key});

  @override
  State<AddShopItemPage> createState() => _AddShopItemPageState();
}

class _AddShopItemPageState extends State<AddShopItemPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token == null) {
      setState(() {
        _errorMessage = 'Token tidak ditemukan. Silakan login kembali.';
        _isLoading = false;
      });
      return;
    }
  }

  Future<void> _addItem() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String title = _titleController.text.trim();
    final String quantityStr = _quantityController.text.trim();

    if (title.isEmpty) {
      setState(() {
        _errorMessage = 'Nama item tidak boleh kosong.';
        _isLoading = false;
      });
      return;
    }

    if (quantityStr.isEmpty) {
      setState(() {
        _errorMessage = 'Jumlah item tidak boleh kosong.';
        _isLoading = false;
      });
      return;
    }
    final int? quantity = int.tryParse(quantityStr);
    if (quantity == null || quantity <= 0) {
      setState(() {
        _errorMessage = 'Jumlah item harus berupa angka lebih dari 0.';
        _isLoading = false;
      });
      return;
    }

    if (_token == null) {
      setState(() {
        _errorMessage = 'Token tidak tersedia. Silakan login kembali.';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.6:8000/api/shoplist'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'title': title, 'quantity': quantity}),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        Navigator.pop(context, {
          'title': responseData['title'],
          'quantity': responseData['quantity'],
        });
      } else {
        setState(() {
          _errorMessage =
              'Gagal menambahkan item: ${response.body} (Status code: ${response.statusCode})';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 16,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tambah Item Belanja Baru',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF475569),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Nama Item',
                  labelStyle: TextStyle(fontSize: 12, color: Colors.black),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF9CA3AF)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF475569)),
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.only(bottom: 4),
                ),
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  labelStyle: TextStyle(fontSize: 12, color: Colors.black),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF9CA3AF)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF475569)),
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.only(bottom: 4),
                ),
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 80,
                height: 36,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 29, 64, 109),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  onPressed: _isLoading ? null : () => _addItem(),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 3,
                          )
                          : const Text('Add'),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
