import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/theme.dart';
import 'vendor_main_hub.dart';
import 'vendor_baseline_camera.dart';
import 'vendor_daily_shift_camera.dart';

class VendorAuthScreen extends StatefulWidget {
  const VendorAuthScreen({super.key});

  @override
  State<VendorAuthScreen> createState() => _VendorAuthScreenState();
}

class _VendorAuthScreenState extends State<VendorAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _vendorCategory; // 'food' or 'non-food' - null means not selected

  @override
  void dispose() {
    _shopNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _vendorCategory = null;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _handleLoginOrSignup() async {
    if (!_formKey.currentState!.validate()) return;

    // For signup, ensure vendor category is selected
    if (!_isLogin && _vendorCategory == null) {
      _showError('Please select your vendor type (Food or Non-Food)');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // LOGIN FLOW
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        final uid = credential.user?.uid;
        if (uid == null) throw Exception('Login failed');

        // Fetch user profile from Firestore
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final data = doc.data() ?? {};

        final vendorCategory = (data['vendorCategory'] as String?) ?? 'non-food';
        final hasPassedOnboarding = data['hasPassedOnboarding'] == true;

        if (mounted) {
          if (vendorCategory == 'non-food') {
            // Non-food vendor -> Go directly to dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const VendorMainHub()),
            );
          } else {
            // Food vendor
            if (!hasPassedOnboarding) {
              // New food vendor who hasn't completed baseline training
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const VendorBaselineCameraScreen()),
              );
            } else {
              // Returning food vendor -> Must pass daily hygiene check
              final hygieneResult = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VendorDailyShiftCameraScreen()),
              );
              if (hygieneResult == true && mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const VendorMainHub()),
                );
              }
            }
          }
        }
      } else {
        // SIGNUP FLOW
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        final uid = credential.user?.uid;
        if (uid == null) throw Exception('Signup failed');

        // Save vendor profile to Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': _emailController.text.trim(),
          'businessName': _shopNameController.text.trim(),
          'vendorCategory': _vendorCategory,
          'role': 'vendor',
          'hasPassedOnboarding': false,
          'isLive': false,
          'trustTier': 'standard',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          if (_vendorCategory == 'non-food') {
            // Non-food vendor -> Go directly to dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const VendorMainHub()),
            );
          } else {
            // Food vendor -> Must upload 5+ baseline photos to train AI model
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const VendorBaselineCameraScreen()),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(_getFirebaseErrorMessage(e.code));
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: TinyTrailsColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TinyTrailsColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo & Branding
                _buildHeader(),
                const SizedBox(height: 40),
                // Vendor Category Selector (for both login and signup to choose flow)
                if (!_isLogin) ...[
                  _buildVendorCategorySelector(),
                  const SizedBox(height: 28),
                ],
                // Form Fields
                _buildFormFields(),
                const SizedBox(height: 28),
                // Submit Button
                _buildSubmitButton(),
                const SizedBox(height: 20),
                // Toggle Login/Signup
                _buildToggleText(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [TinyTrailsColors.emerald600, TinyTrailsColors.emeraldGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: TinyTrailsColors.emeraldGreen.withAlpha(80),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.storefront_rounded,
            size: 42,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        // Title
        Text(
          _isLogin ? 'Welcome Back' : 'Join as Vendor',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: TinyTrailsColors.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin
              ? 'Sign in to manage your shop'
              : 'Create your vendor account',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: TinyTrailsColors.gray500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVendorCategorySelector() {
    return Column(
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
              child: const Icon(Icons.category_outlined, color: TinyTrailsColors.emeraldGreen, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'What type of vendor are you?',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: TinyTrailsColors.charcoal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildCategoryOption(
                emoji: '🍔',
                label: 'Food Based',
                subtitle: 'Requires AI Hygiene Check',
                value: 'food',
                isSelected: _vendorCategory == 'food',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCategoryOption(
                emoji: '🧵',
                label: 'Non-Food',
                subtitle: 'Artisans, Tailors, etc.',
                value: 'non-food',
                isSelected: _vendorCategory == 'non-food',
              ),
            ),
          ],
        ),
        // Info banner for food vendors
        if (_vendorCategory == 'food') ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TinyTrailsColors.emerald50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TinyTrailsColors.emerald200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: TinyTrailsColors.emeraldGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Hygiene Verification Required',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: TinyTrailsColors.emerald800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'After signup, you\'ll upload 5+ photos of your clean workspace to train our AI. Before each shift, you\'ll verify your workspace is clean.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: TinyTrailsColors.emerald700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryOption({
    required String emoji,
    required String label,
    required String subtitle,
    required String value,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _vendorCategory = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? TinyTrailsColors.emerald50 : TinyTrailsColors.gray100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? TinyTrailsColors.emeraldGreen : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: TinyTrailsColors.emeraldGreen.withAlpha(40),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSelected ? TinyTrailsColors.emeraldGreen : TinyTrailsColors.charcoal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: TinyTrailsColors.gray500,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: TinyTrailsColors.emeraldGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Selected',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        // Shop Name (Only for Signup)
        if (!_isLogin) ...[
          TextFormField(
            controller: _shopNameController,
            textCapitalization: TextCapitalization.words,
            validator: (v) {
              if (v?.trim().isEmpty ?? true) return 'Shop name is required';
              if (v!.trim().length < 2) return 'Enter a valid shop name';
              return null;
            },
            style: GoogleFonts.inter(fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Shop Name',
              hintText: 'e.g., Ramu\'s Tea Stall',
              prefixIcon: const Icon(Icons.store_outlined, color: TinyTrailsColors.gray400),
              filled: true,
              fillColor: TinyTrailsColors.gray100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: TinyTrailsColors.emeraldGreen, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: TinyTrailsColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: TinyTrailsColors.error, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Email Field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          validator: (v) {
            if (v?.trim().isEmpty ?? true) return 'Email is required';
            if (!v!.contains('@') || !v.contains('.')) return 'Enter a valid email';
            return null;
          },
          style: GoogleFonts.inter(fontSize: 15),
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'you@example.com',
            prefixIcon: const Icon(Icons.email_outlined, color: TinyTrailsColors.gray400),
            filled: true,
            fillColor: TinyTrailsColors.gray100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: TinyTrailsColors.emeraldGreen, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: TinyTrailsColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: TinyTrailsColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
        const SizedBox(height: 14),

        // Password Field
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Password is required';
            if (!_isLogin && v!.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
          style: GoogleFonts.inter(fontSize: 15),
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: _isLogin ? 'Enter your password' : 'Min. 6 characters',
            prefixIcon: const Icon(Icons.lock_outline, color: TinyTrailsColors.gray400),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: TinyTrailsColors.gray400,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: TinyTrailsColors.gray100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: TinyTrailsColors.emeraldGreen, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: TinyTrailsColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: TinyTrailsColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final bool canSubmit = _isLogin || _vendorCategory != null;

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: (_isLoading || !canSubmit) ? null : _handleLoginOrSignup,
        style: ElevatedButton.styleFrom(
          backgroundColor: TinyTrailsColors.emeraldGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: TinyTrailsColors.gray300,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin ? 'Sign In' : 'Create Account',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!_isLogin && _vendorCategory == 'food') ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+ AI Setup',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildToggleText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? "Don't have an account? " : 'Already have an account? ',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: TinyTrailsColors.gray500,
          ),
        ),
        GestureDetector(
          onTap: _toggleAuthMode,
          child: Text(
            _isLogin ? 'Sign up' : 'Sign in',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: TinyTrailsColors.emeraldGreen,
            ),
          ),
        ),
      ],
    );
  }
}
