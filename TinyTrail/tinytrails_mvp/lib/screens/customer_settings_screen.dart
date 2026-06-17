import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme.dart';

class CustomerSettingsScreen extends StatefulWidget {
  const CustomerSettingsScreen({super.key});

  @override
  State<CustomerSettingsScreen> createState() => _CustomerSettingsScreenState();
}

class _CustomerSettingsScreenState extends State<CustomerSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _darkMode = false;
  bool _orderUpdates = true;
  bool _promotions = false;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TinyTrailsColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            color: TinyTrailsColors.charcoal,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Notifications'),
          _buildSettingsCard([
            _buildSwitchTile(
              'Push Notifications',
              'Receive push notifications',
              Icons.notifications_outlined,
              _notificationsEnabled,
              (value) => setState(() => _notificationsEnabled = value),
            ),
            _buildDivider(),
            _buildSwitchTile(
              'Order Updates',
              'Get updates about your orders',
              Icons.local_shipping_outlined,
              _orderUpdates,
              (value) => setState(() => _orderUpdates = value),
            ),
            _buildDivider(),
            _buildSwitchTile(
              'Promotions & Offers',
              'Receive promotional notifications',
              Icons.local_offer_outlined,
              _promotions,
              (value) => setState(() => _promotions = value),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSectionTitle('App Settings'),
          _buildSettingsCard([
            _buildSwitchTile(
              'Location Services',
              'Allow app to access your location',
              Icons.location_on_outlined,
              _locationEnabled,
              (value) => setState(() => _locationEnabled = value),
            ),
            _buildDivider(),
            _buildSwitchTile(
              'Dark Mode',
              'Use dark theme',
              Icons.dark_mode_outlined,
              _darkMode,
              (value) => setState(() => _darkMode = value),
            ),
            _buildDivider(),
            _buildDropdownTile(
              'Language',
              'Select app language',
              Icons.language_outlined,
              _language,
              ['English', 'Tamil', 'Hindi'],
              (value) => setState(() => _language = value!),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSectionTitle('Privacy & Security'),
          _buildSettingsCard([
            _buildNavigationTile(
              'Change Password',
              'Update your account password',
              Icons.lock_outline,
              () => _showComingSoon('Change Password'),
            ),
            _buildDivider(),
            _buildNavigationTile(
              'Privacy Policy',
              'Read our privacy policy',
              Icons.privacy_tip_outlined,
              () => _showComingSoon('Privacy Policy'),
            ),
            _buildDivider(),
            _buildNavigationTile(
              'Terms of Service',
              'Read our terms of service',
              Icons.description_outlined,
              () => _showComingSoon('Terms of Service'),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSectionTitle('Data'),
          _buildSettingsCard([
            _buildNavigationTile(
              'Clear Cache',
              'Free up storage space',
              Icons.cleaning_services_outlined,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared successfully!')),
                );
              },
            ),
            _buildDivider(),
            _buildNavigationTile(
              'Delete Account',
              'Permanently delete your account',
              Icons.delete_forever_outlined,
              () => _showDeleteAccountDialog(),
              isDestructive: true,
            ),
          ]),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'TinyTrails v1.0.0',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: TinyTrailsColors.gray400,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: TinyTrailsColors.gray500,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 56, color: TinyTrailsColors.gray100);
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: TinyTrailsColors.royalBlue50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: TinyTrailsColors.royalBlue, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: TinyTrailsColors.charcoal,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: TinyTrailsColors.gray400,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: TinyTrailsColors.royalBlue,
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: TinyTrailsColors.royalBlue50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: TinyTrailsColors.royalBlue, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: TinyTrailsColors.charcoal,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: TinyTrailsColors.gray400,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(
              option,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: TinyTrailsColors.charcoal,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNavigationTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive ? TinyTrailsColors.error.withValues(alpha: 0.1) : TinyTrailsColors.royalBlue50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? TinyTrailsColors.error : TinyTrailsColors.royalBlue,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDestructive ? TinyTrailsColors.error : TinyTrailsColors.charcoal,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: TinyTrailsColors.gray400,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDestructive ? TinyTrailsColors.error : TinyTrailsColors.gray400,
      ),
      onTap: onTap,
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon!')),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Account',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: TinyTrailsColors.error,
          ),
        ),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: TinyTrailsColors.gray500),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion request submitted'),
                  backgroundColor: TinyTrailsColors.error,
                ),
              );
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: TinyTrailsColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
