import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme.dart';

/// An animated role switcher widget with smooth sliding animation
/// and color transitions between Customer (Blue) and Vendor (Green).
class RoleSwitcher extends StatefulWidget {
  const RoleSwitcher({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleChanged;

  @override
  State<RoleSwitcher> createState() => _RoleSwitcherState();
}

class _RoleSwitcherState extends State<RoleSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: widget.selectedRole == UserRole.vendor ? 1.0 : 0.0,
    );

    _slideAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: TinyTrailsColors.royalBlue,
      end: TinyTrailsColors.emeraldGreen,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(RoleSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRole != widget.selectedRole) {
      if (widget.selectedRole == UserRole.vendor) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final thumbWidth = (constraints.maxWidth - 8) / 2;

        return Container(
          height: 56,
          decoration: BoxDecoration(
            color: TinyTrailsColors.gray100,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Stack(
            children: [
              // Animated Slider Thumb
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Positioned(
                    left: 4 + (_slideAnimation.value * thumbWidth),
                    top: 4,
                    child: Container(
                      width: thumbWidth,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _colorAnimation.value,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: (_colorAnimation.value ?? TinyTrailsColors.royalBlue)
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Role Buttons
              Row(
                children: [
                  _buildRoleOption(UserRole.customer, 'Customer'),
                  _buildRoleOption(UserRole.vendor, 'Vendor'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleOption(UserRole role, String label) {
    final isSelected = widget.selectedRole == role;

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onRoleChanged(role),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? TinyTrailsColors.white
                  : TinyTrailsColors.slateGray,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
