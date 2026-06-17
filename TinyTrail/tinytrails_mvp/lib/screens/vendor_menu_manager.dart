import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/theme.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';

class VendorMenuManager extends StatefulWidget {
  const VendorMenuManager({super.key});

  @override
  State<VendorMenuManager> createState() => _VendorMenuManagerState();
}

class _VendorMenuManagerState extends State<VendorMenuManager> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isVeg = true;
  bool _isAdding = false;

  String? get _vendorId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vendorId == null) return;

    setState(() {
      _isAdding = true;
    });

    final now = DateTime.now();
    final product = ProductModel(
      id: '', // Will be assigned by Firestore
      vendorId: _vendorId!,
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text),
      isVeg: _isVeg,
      inStock: true,
      createdAt: now,
      updatedAt: now,
    );

    final result = await firebaseService.addProduct(product);

    setState(() {
      _nameController.clear();
      _priceController.clear();
      _isVeg = true;
      _isAdding = false;
    });

    if (result != null) {
      _showSnackbar('Product added successfully!');
    } else {
      _showSnackbar('Failed to add product', isError: true);
    }
  }

  Future<void> _toggleStock(ProductModel product) async {
    final updatedProduct = product.copyWith(
      inStock: !product.inStock,
      updatedAt: DateTime.now(),
    );
    await firebaseService.updateProduct(updatedProduct);
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final success = await firebaseService.deleteProduct(product.id);
    if (success) {
      _showSnackbar('${product.name} removed');
    } else {
      _showSnackbar('Failed to delete', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? TinyTrailsColors.error : TinyTrailsColors.emeraldGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TinyTrailsColors.white,
      appBar: AppBar(
        backgroundColor: TinyTrailsColors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios,
            color: TinyTrailsColors.charcoal,
            size: 20,
          ),
        ),
        title: Text(
          'Manage Menu',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: TinyTrailsColors.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Add Item Form
          _buildAddItemForm(),
          // Divider
          Container(
            height: 8,
            color: TinyTrailsColors.gray100,
          ),
          // Products List
          Expanded(
            child: _buildProductsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TinyTrailsColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Item',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: TinyTrailsColors.charcoal,
              ),
            ),
            const SizedBox(height: 16),
            // Name and Price Row
            Row(
              children: [
                // Name Field
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: TinyTrailsColors.charcoal,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Item Name',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: TinyTrailsColors.gray400,
                      ),
                      filled: true,
                      fillColor: TinyTrailsColors.gray100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: TinyTrailsColors.emeraldGreen,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Price Field
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: TinyTrailsColors.charcoal,
                    ),
                    decoration: InputDecoration(
                      hintText: '₹ Price',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: TinyTrailsColors.gray400,
                      ),
                      filled: true,
                      fillColor: TinyTrailsColors.gray100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: TinyTrailsColors.emeraldGreen,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Veg/Non-Veg Toggle and Add Button
            Row(
              children: [
                // Veg/Non-Veg Toggle
                _buildVegToggle(),
                const Spacer(),
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          )
                        : const Icon(Icons.add, size: 20),
                    label: Text(
                      'Add to Menu',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TinyTrailsColors.emeraldGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
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
          // Veg Option
          GestureDetector(
            onTap: () => setState(() => _isVeg = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _isVeg ? TinyTrailsColors.emeraldGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🟢',
                    style: TextStyle(fontSize: _isVeg ? 14 : 12),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Veg',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isVeg
                          ? Colors.white
                          : TinyTrailsColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Non-Veg Option
          GestureDetector(
            onTap: () => setState(() => _isVeg = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: !_isVeg ? TinyTrailsColors.error : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🔴',
                    style: TextStyle(fontSize: !_isVeg ? 14 : 12),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Non-Veg',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: !_isVeg
                          ? Colors.white
                          : TinyTrailsColors.gray500,
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

  Widget _buildProductsList() {
    if (_vendorId == null) {
      return const Center(child: Text('Please log in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('vendorId', isEqualTo: _vendorId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading products'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(TinyTrailsColors.emeraldGreen),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant_menu_outlined,
                  size: 64,
                  color: TinyTrailsColors.gray300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No items yet',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: TinyTrailsColors.gray400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first menu item above',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: TinyTrailsColors.gray400,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final product = ProductModel.fromJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
            return _buildProductCard(product);
          },
        );
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Dismissible(
      key: Key(product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteProduct(product),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: TinyTrailsColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TinyTrailsColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TinyTrailsColors.gray200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Veg/Non-Veg Indicator
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: product.isVeg
                    ? TinyTrailsColors.emerald50
                    : TinyTrailsColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  product.vegIndicator,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Product Details
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
                  const SizedBox(height: 4),
                  Text(
                    product.formattedPrice,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: TinyTrailsColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            // Stock Toggle
            Column(
              children: [
                Switch(
                  value: product.inStock,
                  onChanged: (_) => _toggleStock(product),
                  activeThumbColor: TinyTrailsColors.emeraldGreen,
                  activeTrackColor: TinyTrailsColors.emerald200,
                ),
                Text(
                  product.stockStatus,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: product.inStock
                        ? TinyTrailsColors.emeraldGreen
                        : TinyTrailsColors.gray400,
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
