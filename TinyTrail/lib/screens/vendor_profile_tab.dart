import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/theme.dart';
import '../services/firebase_service.dart';
import 'login_screen.dart';
import 'vendor_menu_manager.dart';
import 'vendor_operating_hours.dart';
import 'vendor_fssai_screen.dart';
import 'vendor_analytics_screen.dart';

class VendorProfileTab extends StatefulWidget {
  const VendorProfileTab({super.key});

  @override
  State<VendorProfileTab> createState() => _VendorProfileTabState();
}

class _VendorProfileTabState extends State<VendorProfileTab> {
  // Vendor data - loaded from Firestore
  String _shopName = 'My Shop';
  String _vendorId = '';
  String _trustTier = 'standard';
  double _outstandingPayout = 0.0;
  String _vendorCategory = 'non-food';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    final userData = await firebaseService.getUserData(uid);
    if (userData != null && mounted) {
      setState(() {
        _shopName = userData.businessName ?? 'My Shop';
        _vendorId = uid.substring(0, 6).toUpperCase();
        _trustTier = userData.trustTier?.name ?? 'standard';
        _vendorCategory = userData.vendorCategory;
        _outstandingPayout = 0.0; // Will be fetched from payments collection later
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  String get _trustTierLabel {
    switch (_trustTier) {
      case 'platinum':
        return 'Platinum Partner';
      case 'gold':
        return 'Gold Partner';
      default:
        return 'Standard Partner';
    }
  }

  IconData get _trustTierIcon {
    switch (_trustTier) {
      case 'platinum':
        return Icons.diamond_outlined;
      case 'gold':
        return Icons.verified;
      default:
        return Icons.shield_outlined;
    }
  }

  Color get _trustTierColor {
    switch (_trustTier) {
      case 'platinum':
        return TinyTrailsColors.badgePlatinum;
      case 'gold':
        return TinyTrailsColors.badgeGold;
      default:
        return TinyTrailsColors.badgeBlue;
    }
  }

  void _showWithdrawSheet() {
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: TinyTrailsColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                'Withdraw Funds',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: TinyTrailsColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Available balance: Rs. ${_outstandingPayout.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: TinyTrailsColors.gray500,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Amount to Withdraw',
                  hintText: 'Enter amount',
                  prefixText: 'Rs. ',
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
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: TinyTrailsColors.gray100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance, color: TinyTrailsColors.gray500, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HDFC Bank ****4521',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: TinyTrailsColors.charcoal,
                            ),
                          ),
                          Text(
                            'Primary Account',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: TinyTrailsColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle, color: TinyTrailsColors.emeraldGreen, size: 22),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Withdrawal request submitted!'),
                        backgroundColor: TinyTrailsColors.emeraldGreen,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TinyTrailsColors.emeraldGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Confirm Transfer to Bank',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String itemName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $itemName...'),
        backgroundColor: TinyTrailsColors.emeraldGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleLogout() async {
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
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TinyTrailsColors.gray100,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Header with overlapping payout card
            Stack(
              clipBehavior: Clip.none,
              children: [
                _buildHeroHeader(),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: -50,
                  child: _buildPayoutCard(),
                ),
              ],
            ),
            const SizedBox(height: 66),
            // Business Management Section
            _buildManagementSection(),
            const SizedBox(height: 20),
            // Log Out Button
            _buildLogoutButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 70,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TinyTrailsColors.emerald900,
            TinyTrailsColors.emerald800,
            TinyTrailsColors.emerald700,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withAlpha(200),
                ),
              ),
              GestureDetector(
                onTap: () => _showSnackBar('Settings'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Shop info row
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.storefront_rounded, color: TinyTrailsColors.emeraldGreen, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _shopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Vendor ID: $_vendorId',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Trust tier badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _trustTierColor.withAlpha(40),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_trustTierIcon, color: _trustTierColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  _trustTierLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _trustTierColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TinyTrailsColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
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
                child: const Icon(Icons.account_balance_wallet_outlined, color: TinyTrailsColors.emeraldGreen, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Outstanding Payout',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: TinyTrailsColors.gray500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // FIXED: Using Expanded and FittedBox to prevent overflow
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Rs. ${_outstandingPayout.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: TinyTrailsColors.charcoal,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _showWithdrawSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TinyTrailsColors.emeraldGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Withdraw',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManagementSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Management',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: TinyTrailsColors.charcoal,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: TinyTrailsColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSettingsItem(
                  icon: Icons.restaurant_menu_outlined,
                  title: 'Menu & Catalog',
                  subtitle: 'Manage items and pricing',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VendorMenuManager()),
                    );
                  },
                ),
                _buildDivider(),
                if (_vendorCategory == 'food') ...[
                  _buildSettingsItem(
                    icon: Icons.description_outlined,
                    title: 'FSSAI & Documents',
                    subtitle: 'Upload food licenses',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VendorFSSAIScreen()),
                      );
                    },
                    badge: 'Required',
                    badgeColor: TinyTrailsColors.warning,
                  ),
                  _buildDivider(),
                ],
                _buildSettingsItem(
                  icon: Icons.schedule_outlined,
                  title: 'Operating Hours',
                  subtitle: 'Set availability',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VendorOperatingHoursScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsItem(
                  icon: Icons.account_balance_outlined,
                  title: 'Payout Accounts',
                  subtitle: 'Bank details',
                  onTap: () => _showSnackBar('Payout Accounts'),
                ),
                _buildDivider(),
                _buildSettingsItem(
                  icon: Icons.analytics_outlined,
                  title: 'Analytics',
                  subtitle: 'Sales reports',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VendorAnalyticsScreen()),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsItem(
                  icon: Icons.support_agent_outlined,
                  title: 'Help & Support',
                  subtitle: 'Get assistance',
                  onTap: () => _showSnackBar('Help & Support'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: TinyTrailsColors.gray100,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: TinyTrailsColors.emeraldGreen, size: 20),
              ),
              const SizedBox(width: 12),
              // FIXED: Wrapped in Expanded to prevent overflow
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: TinyTrailsColors.charcoal,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (badgeColor ?? TinyTrailsColors.emeraldGreen).withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: badgeColor ?? TinyTrailsColors.emeraldGreen,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: TinyTrailsColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: TinyTrailsColors.gray400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Divider(height: 1, thickness: 1, color: TinyTrailsColors.gray100),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: _handleLogout,
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: Text(
            'Log Out',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: TinyTrailsColors.error,
            side: const BorderSide(color: TinyTrailsColors.error, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: TinyTrailsColors.error.withAlpha(10),
          ),
        ),
      ),
    );
  }
}
