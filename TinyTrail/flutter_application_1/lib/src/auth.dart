import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'shared.dart';
import 'shell.dart';
import 'vendor/baseline_setup.dart';
import 'vendor/hygiene_check.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.mode,
    required this.onModeChanged,
  });

  final AppMode mode;
  final ValueChanged<AppMode> onModeChanged;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool proceedToApp = false;
  bool isHygieneVerified = false;
  String? verifiedVendorId;
  int vendorRefreshVersion = 0;

  void _enterApp() {
    if (!mounted) return;
    setState(() => proceedToApp = true);
  }

  void _markHygieneVerified(String vendorId) {
    if (!mounted) return;
    setState(() {
      isHygieneVerified = true;
      verifiedVendorId = vendorId;
    });
  }

  void _refreshVendorState() {
    if (!mounted) return;
    setState(() {
      vendorRefreshVersion += 1;
    });
  }

  Future<Map<String, dynamic>?> _loadVendorData(String uid) async {
    final store = FirebaseFirestore.instance;

    final directDoc = await store.collection('vendors').doc(uid).get();
    if (directDoc.exists) {
      return <String, dynamic>{
        'id': directDoc.id,
        ...?directDoc.data(),
      };
    }

    final ownerQuery = await store
        .collection('vendors')
        .where('ownerId', isEqualTo: uid)
        .limit(1)
        .get();
    if (ownerQuery.docs.isNotEmpty) {
      return <String, dynamic>{
        'id': ownerQuery.docs.first.id,
        ...ownerQuery.docs.first.data(),
      };
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = authSnapshot.data;
        if (user == null) {
          if (proceedToApp || isHygieneVerified || verifiedVendorId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                proceedToApp = false;
                isHygieneVerified = false;
                verifiedVendorId = null;
              });
            });
          }
          return AuthScreen(
            mode: widget.mode,
            onModeChanged: widget.onModeChanged,
            onAuthenticated: _enterApp,
          );
        }

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final data = userSnapshot.data!.data() ?? <String, dynamic>{};
            final profile = AppProfile(
              id: user.uid,
              username: (data['username'] as String?) ?? user.email ?? 'TinyTrail User',
              email: (data['email'] as String?) ?? user.email ?? '',
              phone: (data['phone'] as String?) ?? '',
              pincode: (data['pincode'] as String?) ?? '600062',
              role: (data['role'] as String?) ?? 'BUYER',
              businessType: (data['businessType'] as String?) ??
                  (((data['role'] as String?) ?? 'BUYER') == 'SELLER' ? 'food' : 'customer'),
            );

            final expectedMode = profile.isVendor ? AppMode.vendor : AppMode.customer;
            if (widget.mode != expectedMode) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.onModeChanged(expectedMode);
              });
            }

            if (!proceedToApp) {
              return AuthScreen(
                mode: widget.mode,
                onModeChanged: widget.onModeChanged,
                currentProfile: profile,
                onContinueAsCurrentUser: _enterApp,
                onAuthenticated: _enterApp,
              );
            }

            if (!profile.isVendor) {
              return TinyTrailShell(profile: profile);
            }

            return FutureBuilder<Map<String, dynamic>?>(
              key: ValueKey<String>('${profile.id}:$vendorRefreshVersion'),
              future: _loadVendorData(profile.id),
              builder: (context, vendorSnapshot) {
                if (vendorSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final vendorData = vendorSnapshot.data;
                final baselineCount =
                    ((vendorData?['baselineImageCount'] as num?) ?? 0).toInt();
                final referenceEmbedding = vendorData?['referenceEmbedding'];
                final hasBaseline = !profile.isFoodVendor ||
                    (referenceEmbedding is List && referenceEmbedding.isNotEmpty) ||
                    baselineCount >= 5;

                if (profile.isFoodVendor && !hasBaseline) {
                  return VendorBaselineSetupScreen(
                    profile: profile,
                    onSetupComplete: () {
                      _markHygieneVerified(profile.id);
                      _refreshVendorState();
                    },
                  );
                }

                final hygienePassedForVendor =
                    !profile.isFoodVendor ||
                    (isHygieneVerified && verifiedVendorId == profile.id);
                if (!hygienePassedForVendor) {
                  return HygieneCheckScreen(
                    profile: profile,
                    onVerified: () => _markHygieneVerified(profile.id),
                  );
                }

                return TinyTrailShell(profile: profile);
              },
            );
          },
        );
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.mode,
    required this.onModeChanged,
    this.currentProfile,
    this.onContinueAsCurrentUser,
    this.onAuthenticated,
  });

  final AppMode mode;
  final ValueChanged<AppMode> onModeChanged;
  final AppProfile? currentProfile;
  final VoidCallback? onContinueAsCurrentUser;
  final VoidCallback? onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isRegister = false;
  bool isLoading = false;
  bool loginPasswordVisible = false;
  bool registerPasswordVisible = false;
  String? errorText;
  String vendorBusinessType = 'food';

  final loginEmail = TextEditingController();
  final loginPassword = TextEditingController();
  final registerUsername = TextEditingController();
  final registerEmail = TextEditingController();
  final registerPhone = TextEditingController();
  final registerPincode = TextEditingController();
  final registerPassword = TextEditingController();

  Color get accent => appAccent(widget.mode);

  String get welcomeTitle => widget.mode == AppMode.vendor
      ? "Welcome back! Let's grow your business."
      : 'Welcome back! Ready to explore locally?';

  String get roleLabel => widget.mode == AppMode.vendor ? 'vendor' : 'customer';

  List<_BusinessTypeOption> get businessTypeOptions => const <_BusinessTypeOption>[
        _BusinessTypeOption(value: 'food', label: 'Food'),
        _BusinessTypeOption(value: 'tailor', label: 'Tailor'),
        _BusinessTypeOption(value: 'artisan', label: 'Artisan'),
      ];

  bool get isDemoLogin {
    final email = loginEmail.text.trim().toLowerCase();
    return email == 'vendor@tinytrail.com' ||
        email == 'customer@tinytrail.com' ||
        email == 'tailor@tinytrail.com' ||
        email == 'artisan@tinytrail.com';
  }

  void autofillDummyCreds() {
    setState(() {
      errorText = null;
      if (widget.mode == AppMode.vendor) {
        vendorBusinessType = vendorBusinessType == 'food'
            ? 'food'
            : (vendorBusinessType == 'artisan' ? 'artisan' : 'tailor');
        final demoEmail = vendorBusinessType == 'food'
            ? 'vendor@tinytrail.com'
            : (vendorBusinessType == 'artisan'
                ? 'artisan@tinytrail.com'
                : 'tailor@tinytrail.com');
        final demoName = vendorBusinessType == 'food'
            ? 'Amma Snacks'
            : (vendorBusinessType == 'artisan'
                ? 'Priya Handmade Crafts'
                : 'Lakshmi Tailors');
        final demoPhone = vendorBusinessType == 'food'
            ? '9876543212'
            : (vendorBusinessType == 'artisan' ? '9876543214' : '9876543213');
        final demoPincode = vendorBusinessType == 'artisan' ? '600061' : '600062';

        loginEmail.text = demoEmail;
        loginPassword.text = 'password123';
        registerUsername.text = demoName;
        registerEmail.text = demoEmail;
        registerPhone.text = demoPhone;
        registerPincode.text = demoPincode;
        registerPassword.text = 'password123';
      } else {
        loginEmail.text = 'customer@tinytrail.com';
        loginPassword.text = 'password123';
        registerUsername.text = 'Tiny Customer';
        registerEmail.text = 'customer@tinytrail.com';
        registerPhone.text = '9876543211';
        registerPincode.text = '600062';
        registerPassword.text = 'password123';
      }
    });
  }

  Future<void> handleLogin() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: loginEmail.text.trim(),
        password: loginPassword.text,
      );
      widget.onAuthenticated?.call();
    } on FirebaseAuthException catch (error) {
      if (isDemoLogin) {
        try {
          await _ensureDemoAccount();
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: loginEmail.text.trim(),
            password: loginPassword.text,
          );
          widget.onAuthenticated?.call();
        } on FirebaseAuthException catch (demoError) {
          setState(() => errorText = demoError.message ?? 'Demo login failed');
        } catch (_) {
          setState(() => errorText = 'Demo login failed');
        }
      } else {
        setState(() => errorText = error.message ?? 'Login failed');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> handleRegister() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: registerEmail.text.trim(),
        password: registerPassword.text,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'username': registerUsername.text.trim(),
        'email': registerEmail.text.trim(),
        'phone': registerPhone.text.trim(),
        'pincode': registerPincode.text.trim(),
        'role': widget.mode == AppMode.vendor ? 'SELLER' : 'BUYER',
        'businessType':
            widget.mode == AppMode.vendor ? vendorBusinessType : 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (widget.mode == AppMode.vendor && vendorBusinessType != 'food') {
        await FirebaseFirestore.instance
            .collection('vendors')
            .doc(credential.user!.uid)
            .set({
          'shopName': registerUsername.text.trim(),
          'ownerId': credential.user!.uid,
          'pincode': registerPincode.text.trim(),
          'businessType': vendorBusinessType,
          'badge': vendorBusinessType == 'food' ? 'Gold' : 'Verified',
          'hygieneScore': vendorBusinessType == 'food' ? 94 : null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      widget.onAuthenticated?.call();
    } on FirebaseAuthException catch (error) {
      setState(() => errorText = error.message ?? 'Registration failed');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _ensureDemoAccount() async {
    final email = loginEmail.text.trim().toLowerCase();
    final password = loginPassword.text;

    final isFoodVendorDemo = email == 'vendor@tinytrail.com';
    final isTailorDemo = email == 'tailor@tinytrail.com';
    final isArtisanDemo = email == 'artisan@tinytrail.com';
    final isVendorDemo = isFoodVendorDemo || isTailorDemo || isArtisanDemo;
    final username = isFoodVendorDemo
        ? 'Amma Snacks'
        : isTailorDemo
            ? 'Lakshmi Tailors'
            : isArtisanDemo
                ? 'Priya Handmade Crafts'
                : 'Tiny Customer';
    final phone = isFoodVendorDemo
        ? '9876543212'
        : isTailorDemo
            ? '9876543213'
            : isArtisanDemo
                ? '9876543214'
                : '9876543211';
    final pincode = isArtisanDemo ? '600061' : '600062';
    final role = isVendorDemo ? 'SELLER' : 'BUYER';
    final businessType = isFoodVendorDemo
        ? 'food'
        : isTailorDemo
            ? 'tailor'
            : isArtisanDemo
                ? 'artisan'
                : 'customer';

    UserCredential credential;

    try {
      credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        return;
      }
      rethrow;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(credential.user!.uid)
        .set({
      'username': username,
      'email': email,
      'phone': phone,
      'pincode': pincode,
      'role': role,
      'businessType': businessType,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (isVendorDemo && businessType != 'food') {
      await FirebaseFirestore.instance.collection('vendors').doc(credential.user!.uid).set({
        'shopName': username,
        'ownerId': credential.user!.uid,
        'pincode': pincode,
        'businessType': businessType,
        'badge': businessType == 'food' ? 'Gold' : 'Verified',
        'hygieneScore': businessType == 'food' ? 94 : null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await FirebaseAuth.instance.signOut();
  }

  @override
  void dispose() {
    loginEmail.dispose();
    loginPassword.dispose();
    registerUsername.dispose();
    registerEmail.dispose();
    registerPhone.dispose();
    registerPincode.dispose();
    registerPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVendor = widget.mode == AppMode.vendor;
    final activeTextColor =
        isVendor ? const Color(0xFF166534) : const Color(0xFF1246A9);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 18, 24, 100 + keyboardInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'TinyTrails',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: accent,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'From Home to Your Hands',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F6FB),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Stack(
                          children: [
                            AnimatedAlign(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeInOut,
                              alignment: isVendor
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: 0.5,
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () =>
                                        widget.onModeChanged(AppMode.customer),
                                    style: TextButton.styleFrom(
                                      foregroundColor: isVendor
                                          ? const Color(0xFF475467)
                                          : Colors.white,
                                      minimumSize:
                                          const Size.fromHeight(52),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                    ),
                                    child: const Text(
                                      'Customer',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextButton(
                                    onPressed: () =>
                                        widget.onModeChanged(AppMode.vendor),
                                    style: TextButton.styleFrom(
                                      foregroundColor: isVendor
                                          ? Colors.white
                                          : const Color(0xFF475467),
                                      minimumSize:
                                          const Size.fromHeight(52),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                    ),
                                    child: const Text(
                                      'Vendor',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (widget.currentProfile != null) ...[
                        const SizedBox(height: 18),
                        _SignedInSessionCard(
                          profile: widget.currentProfile!,
                          accent: accent,
                          onContinue: widget.onContinueAsCurrentUser,
                          onSwitch: () async {
                            await FirebaseAuth.instance.signOut();
                          },
                        ),
                      ],
                      const SizedBox(height: 30),
                      Text(
                        welcomeTitle,
                        style: TextStyle(
                          color: activeTextColor,
                          fontSize: 28,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRegister
                            ? 'Create your TinyTrails account and get started in seconds.'
                            : 'Sign in to continue with your local TinyTrails experience.',
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          _ModeActionChip(
                            label: 'Login',
                            selected: !isRegister,
                            accent: accent,
                            onTap: () => setState(() => isRegister = false),
                          ),
                          const SizedBox(width: 10),
                          _ModeActionChip(
                            label: 'Register',
                            selected: isRegister,
                            accent: accent,
                            onTap: () => setState(() => isRegister = true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (!isRegister) ...[
                        _AuthTextField(
                          controller: loginEmail,
                          label: 'Email ID',
                          accent: accent,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _AuthTextField(
                          controller: loginPassword,
                          label: 'Password',
                          accent: accent,
                          obscureText: !loginPasswordVisible,
                          suffixIcon: IconButton(
                            onPressed: () => setState(() =>
                                loginPasswordVisible = !loginPasswordVisible),
                            icon: Icon(
                              loginPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF667085),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: accent,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ] else ...[
                        _AuthTextField(
                          controller: registerUsername,
                          label: 'Full Name',
                          accent: accent,
                        ),
                        const SizedBox(height: 16),
                        _AuthTextField(
                          controller: registerEmail,
                          label: 'Email ID',
                          accent: accent,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _AuthTextField(
                          controller: registerPhone,
                          label: 'Phone Number',
                          accent: accent,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _AuthTextField(
                          controller: registerPincode,
                          label: 'Pincode',
                          accent: accent,
                          keyboardType: TextInputType.number,
                        ),
                        if (isVendor) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: accent.withValues(alpha: 0.16)),
                            ),
                            child: Text(
                              vendorBusinessType == 'food'
                                  ? 'Food vendors must complete a baseline workspace check before the dashboard opens.'
                                  : 'Non-food vendors can start using the dashboard right after sign up.',
                              style: const TextStyle(
                                color: Color(0xFF344054),
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Business Type',
                                style: TextStyle(
                                  color: Color(0xFF667085),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: businessTypeOptions
                                    .map(
                                      (option) => _BusinessTypeChip(
                                        label: option.label,
                                        selected: vendorBusinessType == option.value,
                                        accent: accent,
                                        onTap: () => setState(
                                          () => vendorBusinessType = option.value,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        _AuthTextField(
                          controller: registerPassword,
                          label: 'Password',
                          accent: accent,
                          obscureText: !registerPasswordVisible,
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => registerPasswordVisible =
                                !registerPasswordVisible),
                            icon: Icon(
                              registerPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF667085),
                            ),
                          ),
                        ),
                      ],
                      if (errorText != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          errorText!,
                          style: const TextStyle(
                            color: Color(0xFFB42318),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 58,
                        child: FilledButton(
                          onPressed: isLoading
                              ? null
                              : (isRegister ? handleRegister : handleLogin),
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            isLoading
                                ? 'Please wait...'
                                : isRegister
                                    ? 'Create $roleLabel account'
                                    : 'Login as $roleLabel',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: const [
                          Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Color(0xFF98A2B3),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                        ],
                      ),
                      const SizedBox(height: 22),
                      OutlinedButton.icon(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(58),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFD0D5DD)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        icon: const Text(
                          'G',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFDB4437),
                          ),
                        ),
                        label: const Text(
                          'Continue with Google',
                          style: TextStyle(
                            color: Color(0xFF344054),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: GestureDetector(
                          onTap: () => setState(() => isRegister = !isRegister),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                color: Color(0xFF667085),
                                fontSize: 15,
                              ),
                              children: [
                                const TextSpan(text: 'New to TinyTrails? '),
                                TextSpan(
                                  text: 'Create an Account',
                                  style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 24,
                  bottom: 24,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: autofillDummyCreds,
                      borderRadius: BorderRadius.circular(999),
                      child: Ink(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.28),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.auto_fix_high_rounded, color: Colors.white),
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
}

class _SignedInSessionCard extends StatelessWidget {
  const _SignedInSessionCard({
    required this.profile,
    required this.accent,
    this.onContinue,
    required this.onSwitch,
  });

  final AppProfile profile;
  final Color accent;
  final VoidCallback? onContinue;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Signed in already',
            style: TextStyle(
              color: AppPalette.ink,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${profile.username} - ${profile.role == 'SELLER' ? 'Vendor' : 'Customer'}',
            style: const TextStyle(color: AppPalette.muted),
          ),
          if (profile.isVendor) ...[
            const SizedBox(height: 4),
            Text(
              '${profile.businessTypeLabel} - ${profile.pincode}',
              style: const TextStyle(color: AppPalette.muted),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onContinue,
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: onSwitch,
                child: const Text('Switch account'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BusinessTypeOption {
  const _BusinessTypeOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

class _BusinessTypeChip extends StatelessWidget {
  const _BusinessTypeChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent : const Color(0xFFD0D5DD),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? accent : const Color(0xFF344054),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ModeActionChip extends StatelessWidget {
  const _ModeActionChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent.withValues(alpha: 0.22) : const Color(0xFFD0D5DD),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? accent : const Color(0xFF344054),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.accent,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final Color accent;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      cursorColor: accent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF667085)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: accent, width: 1.6),
        ),
      ),
    );
  }
}
