import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme.dart';

class CustomerAboutScreen extends StatelessWidget {
  const CustomerAboutScreen({super.key});

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
          'About TinyTrails',
          style: GoogleFonts.inter(
            color: TinyTrailsColors.charcoal,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeroSection(),
          const SizedBox(height: 24),
          _buildMissionSection(),
          const SizedBox(height: 24),
          _buildFeaturesSection(),
          const SizedBox(height: 24),
          _buildTeamSection(),
          const SizedBox(height: 24),
          _buildContactSection(context),
          const SizedBox(height: 24),
          _buildFooter(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TinyTrailsColors.royalBlue, TinyTrailsColors.royalBlue700],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'TT',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: TinyTrailsColors.royalBlue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'TinyTrails',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hyperlocal Commerce, Reimagined',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Version 1.0.0 (MVP)',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection() {
    return _buildCard(
      title: 'Our Mission',
      icon: Icons.flag_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Empowering Local Commerce',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: TinyTrailsColors.charcoal,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'TinyTrails is a hyperlocal e-commerce and food delivery marketplace designed to bridge the gap between local vendors and customers. We believe in supporting small businesses, home chefs, street vendors, and artisans by giving them a digital platform to reach more customers.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: TinyTrailsColors.gray500,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Our unique AI-driven hygiene compliance system ensures food safety standards, giving you peace of mind with every order.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: TinyTrailsColors.gray500,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {
        'icon': Icons.verified_user_outlined,
        'title': 'AI Hygiene Verification',
        'description': 'Every food vendor is verified daily using our AI vision system',
      },
      {
        'icon': Icons.location_on_outlined,
        'title': 'Hyperlocal Focus',
        'description': 'Discover and support businesses in your neighborhood',
      },
      {
        'icon': Icons.speed_outlined,
        'title': 'Fast Delivery',
        'description': 'Quick delivery from local vendors near you',
      },
      {
        'icon': Icons.store_outlined,
        'title': 'Multiple Categories',
        'description': 'Food, groceries, tailoring, repairs, beauty, and more',
      },
    ];

    return _buildCard(
      title: 'What Makes Us Different',
      icon: Icons.star_outline,
      child: Column(
        children: features.map((feature) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: TinyTrailsColors.emerald50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: TinyTrailsColors.emeraldGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: TinyTrailsColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature['description'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: TinyTrailsColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTeamSection() {
    return _buildCard(
      title: 'The Team',
      icon: Icons.people_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Built with passion by college students who believe in the power of local commerce and technology.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: TinyTrailsColors.gray500,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TinyTrailsColors.royalBlue50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_outlined, color: TinyTrailsColors.royalBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'A College Project with Real-World Impact',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: TinyTrailsColors.royalBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return _buildCard(
      title: 'Get in Touch',
      icon: Icons.email_outlined,
      child: Column(
        children: [
          _buildContactRow(Icons.email_outlined, 'Email', 'support@tinytrails.in'),
          const SizedBox(height: 12),
          _buildContactRow(Icons.language_outlined, 'Website', 'www.tinytrails.in'),
          const SizedBox(height: 12),
          _buildContactRow(Icons.phone_outlined, 'Phone', '+91 1800 123 4567'),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton(Icons.facebook, () {}),
              const SizedBox(width: 16),
              _buildSocialButton(Icons.camera_alt_outlined, () {}),
              const SizedBox(width: 16),
              _buildSocialButton(Icons.code, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: TinyTrailsColors.gray400, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: TinyTrailsColors.gray400,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: TinyTrailsColors.charcoal,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: TinyTrailsColors.gray100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: TinyTrailsColors.gray500, size: 22),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Made with love in India',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: TinyTrailsColors.gray400,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {},
              child: Text(
                'Privacy Policy',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: TinyTrailsColors.royalBlue,
                ),
              ),
            ),
            Text(
              '|',
              style: GoogleFonts.inter(color: TinyTrailsColors.gray300),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Terms of Service',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: TinyTrailsColors.royalBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '2024 TinyTrails. All rights reserved.',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: TinyTrailsColors.gray400,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: TinyTrailsColors.royalBlue, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: TinyTrailsColors.charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
