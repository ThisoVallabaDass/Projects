import 'package:flutter/material.dart';

class TinyTrailSplash extends StatefulWidget {
  const TinyTrailSplash({
    super.key,
    required this.onComplete,
  });

  final VoidCallback onComplete;

  @override
  State<TinyTrailSplash> createState() => _TinyTrailSplashState();
}

class _TinyTrailSplashState extends State<TinyTrailSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: const Offset(0, -0.06),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _controller.forward();
    Future<void>.delayed(
      const Duration(milliseconds: 2100),
      () {
        if (mounted) widget.onComplete();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'TinyTrails',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF173250),
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'From Home to Your Hands',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w500,
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
