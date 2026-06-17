import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme.dart';

class VendorMenuTab extends StatefulWidget {
  const VendorMenuTab({super.key});

  @override
  State<VendorMenuTab> createState() => _VendorMenuTabState();
}

class _VendorMenuTabState extends State<VendorMenuTab> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isVeg = true;
  bool _isAdding = false;

  // Dummy menu data for beautiful rendering
  final List<Map<String, dynamic>> _menuItems = [
    {
      'id': '1',
      'name': 'Paneer Wrap',
      'price': 120.0,
      'isVeg': true,
      'inStock': true,
      'description': 'Grilled paneer with fresh veggies',
    },
    {
      'id': '2',
      'name': 'Masala Tea',
      'price': 20.0,
      'isVeg': true,
      'inStock': true,
      'description': 'Authentic Indian chai with spices',
    },
    {
      'id': '3',
      'name': 'Mysore Pak',
      'price': 45.0,
      'isVeg': true,
      'inStock': true,
      'description': 'Traditional South Indian sweet',
    },
    {
      'id': '4',
      'name': 'Chicken Biryani',
      'price': 180.0,
      'isVeg': false,
      'inStock': true,
      'description': 'Aromatic basmati rice with tender chicken',
    },
    {
      'id': '5',
      'name': 'Fresh Lime Soda',
      'price': 30.0,
      'isVeg': true,
      'inStock': false,
      'description': 'Refreshing citrus drink',
    },
    {
      'id': '6',
      'name': 'Samosa',
      'price': 15.0,
      'isVeg': true,
      'inStock': true,
      'description': 'Crispy pastry with spiced potato filling',
    },
    {
      'id': '7',
      'name': 'Egg Roll',
      'price': 50.0,
      'isVeg': false,
      'inStock': true,
      'description': 'Kolkata-style egg roll with onions',
    },
    {
      'id': '8',
      'name': 'Filter Coffee',
      'price': 25.0,
      'isVeg': true,
      'inStock': true,
      'description': 'South Indian style strong coffee',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isAdding = true);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _menuItems.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text),
        'isVeg': _isVeg,
        'inStock': true,
        'description': '',
      });
      _nameController.clear();
      _priceController.clear();
      _isVeg = true;
      _isAdding = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Item added to menu!'),
          backgroundColor: TinyTrailsColors.emeraldGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _deleteProduct(String id) {
    setState(() {
      _menuItems.removeWhere((item) => item['id'] == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Item removed'),
        backgroundColor: TinyTrailsColors.charcoal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _toggleStock(String id) {
    setState(() {
      final index = _menuItems.indexWhere((item) => item['id'] == id);
      if (index != -1) {
        _menuItems[index]['inStock'] = !_menuItems[index]['inStock'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TinyTrailsColors.gray100,
      appBar: AppBar(
        backgroundColor: TinyTrailsColors.white,
        elevation: 0,
        title: Text(
          'My Menu',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: TinyTrailsColors.charcoal,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: TinyTrailsColors.emerald50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.restaurant_menu, size: 16, color: TinyTrailsColors.emeraldGreen),
                const SizedBox(width: 4),
                Text(
                  '${_menuItems.length} items',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TinyTrailsColors.emeraldGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Add Item Form
          _buildAddItemForm(),
          // Menu Items List
          Expanded(child: _buildMenuList()),
        ],
      ),
    );
  }

  Widget _buildAddItemForm() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TinyTrailsColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TinyTrailsColors.emerald50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_circle_outline, color: TinyTrailsColors.emeraldGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Add New Item',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: TinyTrailsColors.charcoal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Name & Price Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _nameController,
                    validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Item Name',
                      hintStyle: GoogleFonts.inter(color: TinyTrailsColors.gray400),
                      filled: true,
                      fillColor: TinyTrailsColors.gray100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v?.trim().isEmpty ?? true) return 'Required';
                      if (double.tryParse(v!) == null) return 'Invalid';
                      return null;
                    },
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Rs. Price',
                      hintStyle: GoogleFonts.inter(color: TinyTrailsColors.gray400),
                      filled: true,
                      fillColor: TinyTrailsColors.gray100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // FIXED: Use Wrap instead of Row to prevent overflow
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Veg/Non-Veg Toggle
                _buildVegToggle(),
                // Add Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isAdding ? null : _addProduct,
                    icon: _isAdding
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white.withAlpha(200),
                            ),
                          )
                        : const Icon(Icons.add, size: 20),
                    label: Text(
                      'Add to Menu',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TinyTrailsColors.emeraldGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVegToggle() {
    return Container(
      decoration: BoxDecoration(
        color: TinyTrailsColors.gray100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isVeg = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isVeg ? TinyTrailsColors.emeraldGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _isVeg ? Colors.white : TinyTrailsColors.emeraldGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Veg',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isVeg ? Colors.white : TinyTrailsColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _isVeg = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: !_isVeg ? TinyTrailsColors.error : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: !_isVeg ? Colors.white : TinyTrailsColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Non-Veg',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: !_isVeg ? Colors.white : TinyTrailsColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList() {
    if (_menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: TinyTrailsColors.gray300),
            const SizedBox(height: 16),
            Text(
              'No items yet',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: TinyTrailsColors.gray400),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first menu item above',
              style: GoogleFonts.inter(fontSize: 14, color: TinyTrailsColors.gray400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        return _buildMenuItem(item);
      },
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> data) {
    final isVeg = data['isVeg'] ?? true;
    final inStock = data['inStock'] ?? true;
    final description = data['description'] ?? '';

    return Dismissible(
      key: Key(data['id']),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteProduct(data['id']),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: TinyTrailsColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TinyTrailsColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Veg/Non-Veg indicator
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isVeg ? TinyTrailsColors.emerald50 : TinyTrailsColors.error.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isVeg ? TinyTrailsColors.emeraldGreen : TinyTrailsColors.error,
                  ),
                  child: Icon(
                    isVeg ? Icons.eco : Icons.set_meal,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? 'Unknown',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: TinyTrailsColors.charcoal,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: TinyTrailsColors.gray400,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Rs. ${(data['price'] ?? 0).toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: TinyTrailsColors.emeraldGreen,
                    ),
                  ),
                ],
              ),
            ),
            // Stock Toggle
            Column(
              children: [
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: inStock,
                    onChanged: (_) => _toggleStock(data['id']),
                    activeColor: TinyTrailsColors.emeraldGreen,
                    activeTrackColor: TinyTrailsColors.emerald100,
                    inactiveThumbColor: TinyTrailsColors.gray400,
                    inactiveTrackColor: TinyTrailsColors.gray200,
                  ),
                ),
                Text(
                  inStock ? 'In Stock' : 'Out',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: inStock ? TinyTrailsColors.emeraldGreen : TinyTrailsColors.gray400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
