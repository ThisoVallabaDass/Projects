import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../shared.dart';
import '../user_model.dart';

class VendorRegistrationScreen extends StatefulWidget {
  const VendorRegistrationScreen({super.key, required this.onRegistrationSuccess});

  final VoidCallback onRegistrationSuccess;

  @override
  State<VendorRegistrationScreen> createState() => _VendorRegistrationScreenState();
}

class _VendorRegistrationScreenState extends State<VendorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pincodeController = TextEditingController();

  String _selectedCategory = 'non-food'; // 'food' or 'non-food'
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _shopNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _registerVendor() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create Firebase Auth user
      final authResult = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final uid = authResult.user!.uid;

      // Create user document in Firestore
      final userModel = UserModel(
        id: uid,
        username: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        pincode: _pincodeController.text.trim(),
        role: 'SELLER',
        businessType: _selectedCategory,
        shopName: _shopNameController.text.trim(),
        vendorCategory: _selectedCategory,
        baselinePhotos: [],
        hasPassedOnboarding: _selectedCategory == 'non-food', // Non-food vendors skip onboarding
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await FirebaseFirestore.instance.collection('vendors').doc(uid).set(userModel.toJson());

      if (!mounted) return;

      // Route based on vendor category
      if (_selectedCategory == 'non-food') {
        // Non-food vendors go directly to main hub
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/vendor-main-hub',
          (route) => false,
        );
      } else {
        // Food vendors go to baseline camera screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/vendor-baseline-camera',
          (route) => false,
        );
      }

      widget.onRegistrationSuccess();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Registration failed';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const emeraldGreen = Color(0xFF10B981);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppPalette.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Become a Vendor',
          style: TextStyle(
            color: AppPalette.ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Information Section
            const Text(
              'Your Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppPalette.ink,
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your full name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Full name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Shop Name Field
                  TextFormField(
                    controller: _shopNameController,
                    decoration: InputDecoration(
                      labelText: 'Shop Name',
                      hintText: 'Enter your shop/business name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Shop name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Create a strong password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone Field
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Phone number is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Pincode Field
                  TextFormField(
                    controller: _pincodeController,
                    decoration: InputDecoration(
                      labelText: 'Pincode',
                      hintText: 'Enter your pincode',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Pincode is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Vendor Category Section
            const Text(
              'What do you sell?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppPalette.ink,
              ),
            ),
            const SizedBox(height: 16),

            // Category Selection Cards
            Row(
              children: [
                Expanded(
                  child: _CategoryCard(
                    icon: '🍔',
                    label: 'Food &\nBeverages',
                    isSelected: _selectedCategory == 'food',
                    onTap: () {
                      setState(() => _selectedCategory = 'food');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _CategoryCard(
                    icon: '🧵',
                    label: 'Non-Food\n(Crafts, Services)',
                    isSelected: _selectedCategory == 'non-food',
                    onTap: () {
                      setState(() => _selectedCategory = 'non-food');
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEF5350)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFC62828),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Register Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: emeraldGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _registerVendor,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Register as Vendor',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldGreen = Color(0xFF10B981);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? emeraldGreen.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? emeraldGreen : const Color(0xFFD7E0EA),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? emeraldGreen : AppPalette.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
