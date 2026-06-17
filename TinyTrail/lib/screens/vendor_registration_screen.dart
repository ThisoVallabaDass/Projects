import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_model.dart' as app_models;
import '../theme/theme.dart';
import 'vendor_baseline_camera.dart';
import 'vendor_main_hub.dart';

class VendorRegistrationScreen extends StatefulWidget {
  const VendorRegistrationScreen({super.key});

  @override
  State<VendorRegistrationScreen> createState() => _VendorRegistrationScreenState();
}

class _VendorRegistrationScreenState extends State<VendorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _vendorCategory = 'food';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _shopNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _registerVendor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();

      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      final user = app_models.UserModel(
        uid: uid,
        email: email,
        name: _nameController.text.trim(),
        role: app_models.UserRole.vendor,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        trustTier: app_models.TrustTier.blue,
        hygieneScore: 0,
        isLive: false,
        businessName: _shopNameController.text.trim(),
        businessType: _vendorCategory == 'food' ? 'food' : 'non-food',
        vendorCategory: _vendorCategory,
        baselinePhotos: const [],
        hasPassedOnboarding: _vendorCategory == 'non-food',
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(user.toJson(), SetOptions(merge: true));

      if (!mounted) return;

      if (_vendorCategory == 'non-food') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const VendorMainHub()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const VendorBaselineCameraScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Registration failed'),
          backgroundColor: TinyTrailsColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: TinyTrailsColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TinyTrailsColors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: TinyTrailsColors.white,
        foregroundColor: TinyTrailsColors.charcoal,
        title: Text(
          'Vendor Registration',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: TinyTrailsColors.charcoal,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create your vendor account',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: TinyTrailsColors.charcoal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set up your shop profile and start selling locally.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: TinyTrailsColors.gray500,
                  ),
                ),
                const SizedBox(height: 24),
                _buildField(
                  controller: _nameController,
                  label: 'Name',
                  icon: Icons.person_outline,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _shopNameController,
                  label: 'Shop Name',
                  icon: Icons.storefront_outlined,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Shop name is required' : null,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'What do you sell?',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: TinyTrailsColors.charcoal,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _CategoryCard(
                        emoji: '🍔',
                        title: 'Food &\nBeverages',
                        selected: _vendorCategory == 'food',
                        onTap: () => setState(() => _vendorCategory = 'food'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CategoryCard(
                        emoji: '🧵',
                        title: 'Non-Food\n(Crafts, Services)',
                        selected: _vendorCategory == 'non-food',
                        onTap: () => setState(() => _vendorCategory = 'non-food'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerVendor,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TinyTrailsColors.emeraldGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Register',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 14, color: TinyTrailsColors.charcoal),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: TinyTrailsColors.gray400),
        filled: true,
        fillColor: TinyTrailsColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: TinyTrailsColors.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: TinyTrailsColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: TinyTrailsColors.emeraldGreen, width: 1.8),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.emoji,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? TinyTrailsColors.emerald50 : TinyTrailsColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? TinyTrailsColors.emeraldGreen : TinyTrailsColors.gray200,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? TinyTrailsColors.emerald700 : TinyTrailsColors.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
