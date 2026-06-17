import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/theme.dart';
import 'login_screen.dart';
import 'customer_orders_screen.dart';
import 'customer_settings_screen.dart';
import 'customer_help_screen.dart';
import 'customer_address_book.dart';
import 'customer_about_screen.dart';

class CustomerProfileTab extends StatefulWidget {
  const CustomerProfileTab({super.key});

  @override
  State<CustomerProfileTab> createState() => _CustomerProfileTabState();
}

class _CustomerProfileTabState extends State<CustomerProfileTab> {
  @override
  Widget build(BuildContext context) {
    final options = [
      _ProfileOption('Address Book', Icons.place_outlined, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerAddressBook()));
      }),
      _ProfileOption('Payment Methods', Icons.credit_card_outlined, () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment methods coming soon')),
        );
      }),
      _ProfileOption('Help & Support', Icons.chat_bubble_outline_rounded, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerHelpScreen()));
      }),
      _ProfileOption('About TinyTrails', Icons.info_outline_rounded, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerAboutScreen()));
      }),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            color: TinyTrailsColors.charcoal,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerSettingsScreen()));
            },
            icon: const Icon(Icons.settings_outlined, color: TinyTrailsColors.charcoal),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildHeroProfileCard(context),
          const SizedBox(height: 14),
          _buildOrdersHighlightCard(context),
          const SizedBox(height: 14),
          ...options.map((opt) => _buildOptionTile(context, opt)),
          const SizedBox(height: 18),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildHeroProfileCard(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'TinyTrails User';
    final email = user?.email ?? 'user@tinytrails.in';
    final phone = user?.phoneNumber ?? '+91 98765 43210';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showEditProfileSheet(context),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: TinyTrailsColors.royalBlue50,
                      backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                      child: user?.photoURL == null
                          ? const Icon(Icons.person, size: 40, color: TinyTrailsColors.royalBlue)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: TinyTrailsColors.royalBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: TinyTrailsColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 14, color: TinyTrailsColors.gray400),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 13, color: TinyTrailsColors.gray500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 14, color: TinyTrailsColors.gray400),
                        const SizedBox(width: 6),
                        Text(
                          phone,
                          style: GoogleFonts.inter(fontSize: 13, color: TinyTrailsColors.gray500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showEditProfileSheet(context),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: TinyTrailsColors.royalBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final nameController = TextEditingController(text: user?.displayName ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final phoneController = TextEditingController(text: user?.phoneNumber ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TinyTrailsColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Edit Profile',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: TinyTrailsColors.charcoal,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: TinyTrailsColors.royalBlue50,
                    backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                    child: user?.photoURL == null
                        ? const Icon(Icons.person, size: 50, color: TinyTrailsColors.royalBlue)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Photo upload coming soon')),
                        );
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: TinyTrailsColors.royalBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: GoogleFonts.inter(color: TinyTrailsColors.gray400),
                prefixIcon: const Icon(Icons.person_outline, color: TinyTrailsColors.gray400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: TinyTrailsColors.royalBlue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: GoogleFonts.inter(color: TinyTrailsColors.gray400),
                prefixIcon: const Icon(Icons.email_outlined, color: TinyTrailsColors.gray400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: TinyTrailsColors.royalBlue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: GoogleFonts.inter(color: TinyTrailsColors.gray400),
                prefixIcon: const Icon(Icons.phone_outlined, color: TinyTrailsColors.gray400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: TinyTrailsColors.royalBlue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await user?.updateDisplayName(nameController.text.trim());
                    if (emailController.text.trim() != user?.email) {
                      // Email update requires re-authentication
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Email change requires re-authentication')),
                      );
                    }
                    Navigator.pop(context);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated successfully!'),
                        backgroundColor: TinyTrailsColors.emeraldGreen,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating profile: $e'),
                        backgroundColor: TinyTrailsColors.error,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TinyTrailsColors.royalBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.inter(
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

  Widget _buildOrdersHighlightCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerOrdersScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TinyTrailsColors.royalBlue50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TinyTrailsColors.royalBlue100),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: TinyTrailsColors.royalBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long_outlined, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Orders',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: TinyTrailsColors.royalBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track, reorder & view past orders',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: TinyTrailsColors.gray500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: TinyTrailsColors.royalBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(BuildContext context, _ProfileOption option) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _cardDecoration(),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: TinyTrailsColors.gray100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(option.icon, color: TinyTrailsColors.gray500, size: 22),
        ),
        title: Text(
          option.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: TinyTrailsColors.charcoal,
          ),
        ),
        trailing: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: TinyTrailsColors.gray100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.chevron_right_rounded, color: TinyTrailsColors.gray400, size: 20),
        ),
        onTap: option.onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () async {
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Log Out',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
              content: Text(
                'Are you sure you want to log out?',
                style: GoogleFonts.inter(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(color: TinyTrailsColors.gray500),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'Log Out',
                    style: GoogleFonts.inter(color: TinyTrailsColors.error, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );

          if (shouldLogout == true) {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }
          }
        },
        icon: const Icon(Icons.logout_rounded, color: Colors.white),
        label: Text(
          'Log Out',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: TinyTrailsColors.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

class _ProfileOption {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  _ProfileOption(this.title, this.icon, this.onTap);
}
