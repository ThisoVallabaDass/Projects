import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/theme.dart';
import '../services/firebase_service.dart';
import '../services/demo_data_service.dart';
import '../models/models.dart';

class VendorMenuTab extends StatefulWidget {
  const VendorMenuTab({super.key});

  @override
  State<VendorMenuTab> createState() => _VendorMenuTabState();
}

class _VendorMenuTabState extends State<VendorMenuTab> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isVeg = true;
  bool _isAdding = false;
  bool _isLoading = true;
  String? _vendorId;
  String _vendorCategory = 'non-food';
  bool _isDemoAccount = false;

  @override
  void initState() {
    super.initState();
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    _isDemoAccount = DemoDataService.isDemoAccount(user.email ?? '');

    final userData = await firebaseService.getUserData(user.uid);
    if (userData != null && mounted) {
      setState(() {
        _vendorId = user.uid;
        _vendorCategory = userData.vendorCategory;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate() || _vendorId == null) return;

    setState(() => _isAdding = true);

    try {
      final now = DateTime.now();
      final product = ProductModel(
        id: '', // Will be set by Firestore
        vendorId: _vendorId!,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        isVeg: _isVeg,
        inStock: true,
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );

      final addedProduct = await firebaseService.addProduct(product);

      if (addedProduct != null && mounted) {
        _nameController.clear();
        _priceController.clear();
        _descriptionController.clear();
        _categoryController.clear();
        _isVeg = true;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Item added to menu!'),
            backgroundColor: TinyTrailsColors.emeraldGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to add item. Please try again.'),
            backgroundColor: TinyTrailsColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: TinyTrailsColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  Future<void> _deleteProduct(String productId) async {
    final success = await firebaseService.deleteProduct(productId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Item removed'),
          backgroundColor: TinyTrailsColors.charcoal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _toggleStock(ProductModel product) async {
    final updatedProduct = product.copyWith(inStock: !product.inStock);
    await firebaseService.updateProduct(updatedProduct);
  }

  bool _shouldShowVegToggle() {
    // Only show veg/non-veg toggle for food vendors
    return _vendorCategory == 'food';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(TinyTrailsColors.emeraldGreen),
          ),
        ),
      );
    }

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
          if (_isDemoAccount)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: TinyTrailsColors.badgeGold.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    'DEMO',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: TinyTrailsColors.badgeGold,
                    ),
                  ),
                ],
              ),
            ),
          StreamBuilder<List<ProductModel>>(
            stream: _vendorId != null ? firebaseService.getVendorProducts(_vendorId!) : const Stream.empty(),
            builder: (context, snapshot) {
              final itemCount = snapshot.data?.length ?? 0;
              return Container(
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
                      '$itemCount items',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TinyTrailsColors.emeraldGreen,
                      ),
                    ),
                  ],
                ),
              );
            },
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
                  child: Icon(
                    _vendorCategory == 'food' ? Icons.restaurant_menu : Icons.shopping_bag_outlined,
                    color: TinyTrailsColors.emeraldGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _vendorCategory == 'food' ? 'Add New Food Item' : 'Add New Product',
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
                      hintText: _vendorCategory == 'food' ? 'Dish Name' : 'Product Name',
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
            const SizedBox(height: 12),
            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: _vendorCategory == 'food' ? 'Brief description (optional)' : 'Product description (optional)',
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
            const SizedBox(height: 12),
            // Category
            TextFormField(
              controller: _categoryController,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: _vendorCategory == 'food' ? 'Category (e.g., Main Course, Snacks)' : 'Category (e.g., Textiles, Pottery)',
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
            const SizedBox(height: 16),
            // Controls Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Veg/Non-Veg Toggle (only for food vendors)
                if (_shouldShowVegToggle())
                  Expanded(
                    child: _buildVegToggle(),
                  ),
                if (_shouldShowVegToggle()) const SizedBox(width: 12),
                // Add Button
                Expanded(
                  flex: _shouldShowVegToggle() ? 1 : 2,
                  child: SizedBox(
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
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
    if (_vendorId == null) {
      return const Center(
        child: Text('Please log in to manage your menu.')
      );
    }

    return StreamBuilder<List<ProductModel>>(
      stream: firebaseService.getVendorProducts(_vendorId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Try fallback method for non-food vendors or when orderBy fails
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where('vendorId', isEqualTo: _vendorId!)
                .snapshots(),
            builder: (context, fallbackSnapshot) {
              if (fallbackSnapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: TinyTrailsColors.error),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading menu items',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: TinyTrailsColors.charcoal),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please try again later',
                        style: GoogleFonts.inter(fontSize: 14, color: TinyTrailsColors.gray400),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TinyTrailsColors.emeraldGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (fallbackSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(TinyTrailsColors.emeraldGreen),
                  ),
                );
              }

              final docs = fallbackSnapshot.data?.docs ?? [];
              final products = docs
                  .map((doc) => ProductModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
                  .toList();

              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _vendorCategory == 'food' ? Icons.restaurant_menu : Icons.shopping_bag_outlined,
                        size: 64,
                        color: TinyTrailsColors.gray300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _vendorCategory == 'food' ? 'No menu items yet' : 'No products yet',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: TinyTrailsColors.gray400),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _vendorCategory == 'food' ? 'Add your first dish above' : 'Add your first product above',
                        style: GoogleFonts.inter(fontSize: 14, color: TinyTrailsColors.gray400),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _buildMenuItem(product);
                },
              );
            },
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(TinyTrailsColors.emeraldGreen),
            ),
          );
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _vendorCategory == 'food' ? Icons.restaurant_menu : Icons.shopping_bag_outlined,
                  size: 64,
                  color: TinyTrailsColors.gray300,
                ),
                const SizedBox(height: 16),
                Text(
                  _vendorCategory == 'food' ? 'No menu items yet' : 'No products yet',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: TinyTrailsColors.gray400),
                ),
                const SizedBox(height: 8),
                Text(
                  _vendorCategory == 'food' ? 'Add your first dish above' : 'Add your first product above',
                  style: GoogleFonts.inter(fontSize: 14, color: TinyTrailsColors.gray400),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildMenuItem(product);
          },
        );
      },
    );
  }

  Widget _buildMenuItem(ProductModel product) {
    final showVegIndicator = _vendorCategory == 'food';

    return Dismissible(
      key: Key(product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteProduct(product.id),
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
            // Product Icon or Veg/Non-Veg indicator
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: showVegIndicator
                    ? (product.isVeg ? TinyTrailsColors.emerald50 : TinyTrailsColors.error.withAlpha(25))
                    : TinyTrailsColors.emerald50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: showVegIndicator
                    ? Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: product.isVeg ? TinyTrailsColors.emeraldGreen : TinyTrailsColors.error,
                        ),
                        child: Icon(
                          product.isVeg ? Icons.eco : Icons.set_meal,
                          size: 12,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.shopping_bag_outlined,
                        size: 24,
                        color: TinyTrailsColors.emeraldGreen,
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
                    product.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: TinyTrailsColors.charcoal,
                    ),
                  ),
                  if (product.description != null && product.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      product.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: TinyTrailsColors.gray400,
                      ),
                    ),
                  ],
                  if (product.category != null && product.category!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: TinyTrailsColors.gray100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.category!,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: TinyTrailsColors.gray500,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    product.formattedPrice,
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
                    value: product.inStock,
                    onChanged: (_) => _toggleStock(product),
                    activeColor: TinyTrailsColors.emeraldGreen,
                    activeTrackColor: TinyTrailsColors.emerald100,
                    inactiveThumbColor: TinyTrailsColors.gray400,
                    inactiveTrackColor: TinyTrailsColors.gray200,
                  ),
                ),
                Text(
                  product.inStock ? 'In Stock' : 'Out',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: product.inStock ? TinyTrailsColors.emeraldGreen : TinyTrailsColors.gray400,
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