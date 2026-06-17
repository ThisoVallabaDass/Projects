import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme.dart';
import '../services/demo_data_service.dart';
import 'customer_main_hub.dart';
import 'vendor_baseline_camera.dart';
import 'vendor_daily_shift_camera.dart';
import 'vendor_main_hub.dart';

enum UserRole { customer, vendor }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();

  UserRole _selectedRole = UserRole.customer;
  String? _vendorCategory; // 'food' or 'non-food'
  bool _isRegistering = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Color get _activeColor => _selectedRole == UserRole.customer
      ? TinyTrailsColors.royalBlue
      : TinyTrailsColors.emeraldGreen;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _shopNameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    // For vendor registration, require category selection
    if (_isRegistering && _selectedRole == UserRole.vendor && _vendorCategory == null) {
      _showError('Please select your vendor type (Food or Non-Food)');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;

      final demoRole = _tryDemoLogin(email, password);
      if (demoRole != null) {
        if (mounted) {
          _showSuccess('Demo login successful');
          if (demoRole == 'customer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CustomerMainHub()),
            );
          } else {
            // Demo vendor - show daily hygiene check
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VendorDailyShiftCameraScreen()),
            );
            if (result == true && mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const VendorMainHub()),
              );
            }
          }
        }
        return;
      }

      if (_isRegistering) {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        final role = _selectedRole == UserRole.customer ? 'customer' : 'vendor';
        await _upsertUserProfile(
          uid: credential.user!.uid,
          email: email,
          role: role,
          vendorCategory: _vendorCategory,
          shopName: _shopNameController.text.trim(),
        );
        if (mounted) await _routeAfterRegistration(uid: credential.user!.uid);
      } else {
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        if (mounted) await _resolveAndRouteAfterLogin(uid: credential.user!.uid, email: email);
      }
    } on FirebaseAuthException catch (e) {
      _showError(_getErrorMessage(e.code));
    } catch (_) {
      _showError('Authentication failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _tryDemoLogin(String email, String password) {
    // Check if it's one of our demo accounts
    for (final demoAccount in DemoDataService.demoAccounts.values) {
      if (email == demoAccount['email'] && password == demoAccount['password']) {
        if (demoAccount['category'] == 'food' || demoAccount['category'] == 'non-food') {
          return 'vendor';
        }
      }
    }

    // Check legacy customer demo
    if (email == 'customer@tinytrails.demo' && password == '123456') {
      return 'customer';
    }

    return null;
  }

  Future<void> _upsertUserProfile({
    required String uid,
    required String email,
    required String role,
    String? vendorCategory,
    String? shopName,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
        'role': role,
        'vendorCategory': vendorCategory,
        'businessName': shopName,
        'hasPassedOnboarding': false,
        'isLive': false,
        'trustTier': 'standard',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      if (mounted) {
        _showInfo('Logged in, profile sync pending.');
      }
    }
  }

  Future<void> _routeAfterRegistration({required String uid}) async {
    if (_selectedRole == UserRole.customer) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerMainHub()),
      );
      return;
    }

    // Vendor registration routing
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

  Future<Map<String, dynamic>?> _getProfileDoc(String uid) async {
    final lower = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (lower.exists) return lower.data();
    final upper = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
    if (upper.exists) return upper.data();
    return null;
  }

  Future<void> _resolveAndRouteAfterLogin({required String uid, required String email}) async {
    try {
      final data = await _getProfileDoc(uid);
      if (!mounted) return;

      if (data == null) {
        _showError('Account incomplete. Please register again.');
        return;
      }

      final rawRole = (data['role'] as String?)?.trim().toLowerCase();
      if (rawRole != 'customer' && rawRole != 'vendor') {
        _showError('Account incomplete. Please register again.');
        return;
      }

      if (rawRole == 'customer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerMainHub()),
        );
        return;
      }

      // Vendor login routing
      final category = ((data['vendorCategory'] as String?) ??
                       (data['businessType'] as String?) ??
                       'food').trim().toLowerCase();
      final safeCategory = (category == 'non-food' || category == 'crafts' || category == 'craft') ? 'non-food' : 'food';
      final passedOnboarding = data['hasPassedOnboarding'] == true;

      // Debug logging for troubleshooting
      print('🔍 Vendor login - Category: $category, Safe category: $safeCategory, Passed onboarding: $passedOnboarding');

      if (safeCategory == 'non-food') {
        // Non-food vendor -> Go directly to dashboard (NO HYGIENE CHECKS)
        print('✅ Non-food vendor detected - skipping hygiene checks');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VendorMainHub()),
        );
        return;
      }

      // Food vendor
      if (!passedOnboarding) {
        // New food vendor who hasn't completed baseline training
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VendorBaselineCameraScreen()),
        );
        return;
      }

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
    } catch (_) {
      if (!mounted) return;
      _showError('Unable to verify account profile. Please login again.');
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found. Please register first.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'Email already registered. Please login.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'network-request-failed':
        return 'No internet connection. Try again.';
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

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: TinyTrailsColors.charcoal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: TinyTrailsColors.emeraldGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'TinyTrails',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: TinyTrailsColors.charcoal,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isRegistering ? 'Create your account' : 'Welcome back',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: TinyTrailsColors.gray500,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildRoleSwitcher(),
                    const SizedBox(height: 22),
                    // Vendor category selector (only for vendor registration)
                    if (_isRegistering && _selectedRole == UserRole.vendor) ...[
                      _buildVendorCategorySelector(),
                      const SizedBox(height: 18),
                      _buildShopNameField(),
                      const SizedBox(height: 14),
                    ],
                    _buildEmailField(),
                    const SizedBox(height: 14),
                    _buildPasswordField(),
                    const SizedBox(height: 24),
                    _buildAuthButton(),
                    const SizedBox(height: 14),
                    if (!_isRegistering) _buildDemoCredentialsCard(),
                    const SizedBox(height: 18),
                    _buildToggleAuthMode(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSwitcher() {
    final isCustomer = _selectedRole == UserRole.customer;

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TinyTrailsColors.gray100,
        borderRadius: BorderRadius.circular(28),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                alignment: isCustomer ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: (constraints.maxWidth - 8) / 2,
                  decoration: BoxDecoration(
                    color: isCustomer ? TinyTrailsColors.royalBlue : TinyTrailsColors.emeraldGreen,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedRole = UserRole.customer;
                        _vendorCategory = null;
                      }),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          'Customer',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isCustomer ? Colors.white : TinyTrailsColors.gray500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRole = UserRole.vendor),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          'Vendor',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isCustomer ? TinyTrailsColors.gray500 : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVendorCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What type of vendor are you?',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: TinyTrailsColors.charcoal,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCategoryOption(
                emoji: '🍔',
                label: 'Food Based',
                subtitle: 'AI Hygiene Required',
                value: 'food',
                isSelected: _vendorCategory == 'food',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCategoryOption(
                emoji: '🧵',
                label: 'Non-Food',
                subtitle: 'Artisans, Tailors',
                value: 'non-food',
                isSelected: _vendorCategory == 'non-food',
              ),
            ),
          ],
        ),
        if (_vendorCategory == 'food') ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TinyTrailsColors.emerald50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: TinyTrailsColors.emerald200),
            ),
            child: Row(
              children: [
                Icon(Icons.camera_alt, color: TinyTrailsColors.emeraldGreen, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You\'ll upload 5+ photos to train our AI hygiene model.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: TinyTrailsColors.emerald700,
                    ),
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? TinyTrailsColors.emerald50 : TinyTrailsColors.gray100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? TinyTrailsColors.emeraldGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? TinyTrailsColors.emeraldGreen : TinyTrailsColors.charcoal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: TinyTrailsColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopNameField() {
    return TextFormField(
      controller: _shopNameController,
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (_isRegistering && _selectedRole == UserRole.vendor) {
          if (value == null || value.trim().isEmpty) return 'Shop name is required';
        }
        return null;
      },
      decoration: _inputDecoration('Shop Name', Icons.store_outlined),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Email is required';
        if (!value.contains('@')) return 'Enter a valid email';
        return null;
      },
      decoration: _inputDecoration('Email', Icons.email_outlined),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Password is required';
        if (value.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
      decoration: _inputDecoration('Password', Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            color: TinyTrailsColors.gray400,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      labelStyle: GoogleFonts.inter(color: TinyTrailsColors.gray500),
      prefixIcon: Icon(icon, color: TinyTrailsColors.gray400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: TinyTrailsColors.gray200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: TinyTrailsColors.gray200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _activeColor, width: 1.8),
      ),
    );
  }

  Widget _buildAuthButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleAuth,
        style: ElevatedButton.styleFrom(
          backgroundColor: _activeColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          disabledBackgroundColor: _activeColor.withAlpha(150),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                _isRegistering ? 'Create Account' : 'Login',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Widget _buildDemoCredentialsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TinyTrailsColors.gray100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick demo login',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: TinyTrailsColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customer: customer@tinytrails.demo | 123456',
            style: GoogleFonts.inter(fontSize: 11, color: TinyTrailsColors.gray500),
          ),
          const SizedBox(height: 4),
          Text(
            'Non-Food: ${DemoDataService.demoAccounts['non_food_demo']!['email']} | ${DemoDataService.demoAccounts['non_food_demo']!['password']}',
            style: GoogleFonts.inter(fontSize: 10, color: TinyTrailsColors.gray500),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _selectedRole = UserRole.customer);
                    _emailController.text = 'customer@tinytrails.demo'; // Keeping existing customer demo
                    _passwordController.text = '123456';
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TinyTrailsColors.royalBlue,
                    side: const BorderSide(color: TinyTrailsColors.royalBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Customer', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _selectedRole = UserRole.vendor);
                    _emailController.text = DemoDataService.demoAccounts['non_food_demo']!['email']!;
                    _passwordController.text = DemoDataService.demoAccounts['non_food_demo']!['password']!;
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TinyTrailsColors.emeraldGreen,
                    side: const BorderSide(color: TinyTrailsColors.emeraldGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Non-Food Vendor', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleAuthMode() {
    return Center(
      child: GestureDetector(
        onTap: () => setState(() {
          _isRegistering = !_isRegistering;
          _vendorCategory = null;
        }),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(fontSize: 14, color: TinyTrailsColors.gray500),
            children: [
              TextSpan(
                text: _isRegistering ? 'Already have an account? ' : 'Don\'t have an account? ',
              ),
              TextSpan(
                text: _isRegistering ? 'Login' : 'Register',
                style: GoogleFonts.inter(color: _activeColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
