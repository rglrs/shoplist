import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/pages/add_shop_item.dart'; // Import AddTodoPage, and we'll adapt it
import 'package:todo_app/pages/profile.dart'; // Import Profile page

class ShopListPage extends StatefulWidget {
  // Rename to ShopListPage
  const ShopListPage({Key? key}) : super(key: key);

  @override
  State<ShopListPage> createState() => _ShopListPageState(); // Rename State class
}

class _ShopListPageState extends State<ShopListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<_ShopItem> _shopItems = []; // Rename _todos to _shopItems
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  List<_ShopItem> _filteredShopItems = [];

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchShopList(); // Rename function call
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

  Future<void> _loadTokenAndFetchShopList() async {
    // Rename function
    await _loadToken();
    if (_token != null) {
      _fetchShopList(); // Rename function call
    }
  }

  Future<void> _fetchShopList() async {
    // Rename function
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_token == null) {
        setState(() {
          _errorMessage = 'Token tidak tersedia. Silakan login kembali.';
          _isLoading = false;
        });
        return;
      }
      final response = await http.get(
        Uri.parse('http://192.168.0.6:8000/api/shoplist'), // Change endpoint
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _shopItems =
              data
                  .map((json) => _ShopItem.fromJson(json))
                  .toList(); // Use _ShopItem.fromJson
          _filteredShopItems = _shopItems;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Gagal memuat daftar belanja: Status code ${response.statusCode}, Response: ${response.body}'; // Change message
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${error.toString()}';
        _isLoading = false;
      });
    }
  }

  void _addShopItem(String title, int quantity) {
    // Change parameters
    if (title.isNotEmpty && quantity > 0) {
      _fetchShopList(); // Refresh
    }
  }

  void _filterShopList(String query) {
    // Rename function
    if (query.isNotEmpty) {
      setState(() {
        _filteredShopItems =
            _shopItems
                .where(
                  (item) =>
                      item.title.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      });
    } else {
      setState(() {
        _filteredShopItems = _shopItems;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddShopItemPage(),
            ), // Pass isShopList = true
          );
          if (result is Map) {
            _addShopItem(result['title'], result['quantity']);
          }
        },
        backgroundColor: const Color.fromARGB(255, 29, 64, 109),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Profile(), // Go to Profile Page
                      ),
                    );
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 29, 64, 109),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: const Color(0xFFD3E0EB),
                  borderRadius: BorderRadius.circular(9999),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: Color(0xFF4B5563),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Cari Item Belanja', // Changed hint
                          hintStyle: TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        onChanged: _filterShopList, // Call _filterShopList
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Semua Item Belanja', // Changed title
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                        ? Center(child: Text(_errorMessage!))
                        : ListView.separated(
                          itemCount:
                              _filteredShopItems.length, // Use filtered list
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final shopItem =
                                _filteredShopItems[index]; // Use filtered
                            return Container(
                              constraints: const BoxConstraints(maxWidth: 400),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        shopItem.title,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        'Jumlah: ${shopItem.quantity}', // Show quantity
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade600,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        _deleteShopItem(
                                          index,
                                        ); // Call delete function
                                      },
                                      padding: const EdgeInsets.all(6),
                                      constraints: const BoxConstraints(),
                                      splashRadius: 20,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteShopItem(int index) async {
    // Rename function
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final shopItemToDelete = _filteredShopItems[index]; // Use filtered list
    try {
      if (_token == null) {
        setState(() {
          _errorMessage = 'Token tidak tersedia. Silakan login kembali.';
          _isLoading = false;
        });
        return;
      }
      final response = await http.delete(
        Uri.parse(
          'http://192.168.0.6:8000/api/shoplist/${shopItemToDelete.id}',
        ), // Change endpoint
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _shopItems.removeWhere((item) => item.id == shopItemToDelete.id);
          _filteredShopItems.removeWhere(
            (item) => item.id == shopItemToDelete.id,
          ); // Remove from filtered
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Gagal menghapus item: Status code ${response.statusCode}, Response: ${response.body}'; // change message
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${error.toString()}';
        _isLoading = false;
      });
    }
  }
}

class _ShopItem {
  // Rename class
  String id;
  String title;
  int quantity; // Change to int

  _ShopItem({
    required this.id,
    required this.title,
    required this.quantity, // Receive quantity
  });

  factory _ShopItem.fromJson(Map<String, dynamic> json) {
    return _ShopItem(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      quantity: json['quantity'] ?? 0, // Parse quantity, default to 0 if null
    );
  }
}
