import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/hygiene_api_service.dart';
import '../theme/theme.dart';

enum _VerificationState { idle, preview, processing, success, failed }

class VendorHygieneCamera extends StatefulWidget {
  const VendorHygieneCamera({super.key});

  @override
  State<VendorHygieneCamera> createState() => _VendorHygieneCameraState();
}

class _VendorHygieneCameraState extends State<VendorHygieneCamera> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final HygieneApiService _service = HygieneApiService();

  File? _capturedImage;
  HygieneVerificationResult? _result;
  String? _errorMessage;
  bool _isUpdatingLiveStatus = false;
  _VerificationState _state = _VerificationState.idle;

  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (picked == null) return;

    setState(() {
      _capturedImage = File(picked.path);
      _result = null;
      _errorMessage = null;
      _state = _VerificationState.preview;
    });

    await _verifyImage();
  }

  Future<void> _verifyImage() async {
    final file = _capturedImage;
    if (file == null) return;

    setState(() {
      _state = _VerificationState.processing;
      _errorMessage = null;
    });

    _scanController
      ..reset()
      ..repeat();

    try {
      final response = await _service.verifyImage(file);
      final passed = response.approved;

      if (passed) {
        await _markVendorLive();
      }

      if (!mounted) return;
      setState(() {
        _result = response;
        _state = passed ? _VerificationState.success : _VerificationState.failed;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _state = _VerificationState.preview;
      });
    } finally {
      _scanController.stop();
    }
  }

  Future<void> _markVendorLive() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isUpdatingLiveStatus = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'isLive': true,
          'liveSince': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingLiveStatus = false);
      }
    }
  }

  void _resetCapture() {
    setState(() {
      _capturedImage = null;
      _result = null;
      _errorMessage = null;
      _state = _VerificationState.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TinyTrailsColors.emeraldGreen,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Stack(
                children: [
                  _buildViewport(),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 32,
                    child: _buildStatusPanel(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, _state == _VerificationState.success),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hygiene Gatekeeper',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Frame your workspace and let TinyTrails AI verify cleanliness.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewport() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: _capturedImage == null ? _buildPlaceholder() : _buildPreview(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1B4332), Color(0xFF0F172A)],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(36),
          child: CustomPaint(
            painter: _DashedBorderPainter(color: Colors.white.withValues(alpha: 0.6)),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Frame your cart/workspace here',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ensure good lighting and capture the entire prep area.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: _buildCaptureButton(),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              _capturedImage!,
              fit: BoxFit.cover,
            ),
            if (_state == _VerificationState.processing)
              AnimatedBuilder(
                animation: _scanController,
                builder: (context, child) {
                  final position = _scanController.value * constraints.maxHeight;
                  return Positioned(
                    top: position,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF67E8F9), Color(0xFF06B6D4)],
                        ),
                      ),
                    ),
                  );
                },
              ),
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Center(
                child: _state == _VerificationState.processing
                    ? _buildProcessingChip()
                    : _buildRecaptureChip(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProcessingChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Scanning workspace...',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildRecaptureChip() {
    return GestureDetector(
      onTap: _state == _VerificationState.processing ? null : _captureImage,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'Retake Image',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _state == _VerificationState.processing ? null : _captureImage,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TinyTrailsColors.emeraldGreen,
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPanel() {
    final textTheme = GoogleFonts.inter(color: TinyTrailsColors.charcoal);
    final score = _result?.score;
    final status = _result?.status.toUpperCase();
    final message = _result?.message;

    Widget content;
    switch (_state) {
      case _VerificationState.success:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🟢', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  'Workspace Approved',
                  style: textTheme.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Score ${score?.toStringAsFixed(1) ?? '--'} · ${status ?? 'APPROVED'}',
              style: textTheme.copyWith(color: TinyTrailsColors.gray500),
            ),
            const SizedBox(height: 12),
            Text(
              message ?? 'Workspace is clean. You are ready to go live!',
              style: textTheme,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isUpdatingLiveStatus
                    ? null
                    : () {
                        Navigator.pop(context, true);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TinyTrailsColors.emeraldGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isUpdatingLiveStatus
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        'Go Live on Marketplace',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        );
        break;
      case _VerificationState.failed:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🔴', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  'Hygiene Check Failed',
                  style: textTheme.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Score ${score?.toStringAsFixed(1) ?? '--'} · Needs Attention',
              style: textTheme.copyWith(color: TinyTrailsColors.gray500),
            ),
            const SizedBox(height: 12),
            Text(
              message ?? 'Please clean your workspace and capture a new image.',
              style: textTheme,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _resetCapture,
                style: OutlinedButton.styleFrom(
                  foregroundColor: TinyTrailsColors.emeraldGreen,
                  side: BorderSide(color: TinyTrailsColors.emeraldGreen),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Retry Hygiene Scan', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        );
        break;
      case _VerificationState.processing:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: TinyTrailsColors.emeraldGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'TinyTrails AI is verifying hygiene standards...',
                  style: textTheme.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Keep the device steady while we analyze your workspace.',
              style: textTheme.copyWith(color: TinyTrailsColors.gray500),
            ),
          ],
        );
        break;
      case _VerificationState.preview:
      case _VerificationState.idle:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🧼 Daily Hygiene Check',
              style: textTheme.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture a clear photo of your cart or workspace before starting your shift.',
              style: textTheme,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: textTheme.copyWith(color: TinyTrailsColors.error, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 16),
            _buildCaptureButton(),
          ],
        );
        break;
    }

    return Material(
      color: Colors.white,
      elevation: 20,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: content,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 12.0;
    const dashSpace = 8.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    void drawDashedLine(Offset start, Offset end) {
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final distance = math.sqrt(dx * dx + dy * dy);
      double drawn = 0;
      while (drawn < distance) {
        final t1 = drawn / distance;
        final t2 = (drawn + dashWidth).clamp(0, distance) / distance;
        final offset1 = Offset(start.dx + dx * t1, start.dy + dy * t1);
        final offset2 = Offset(start.dx + dx * t2, start.dy + dy * t2);
        canvas.drawLine(offset1, offset2, paint);
        drawn += dashWidth + dashSpace;
      }
    }

    drawDashedLine(const Offset(0, 0), Offset(size.width, 0));
    drawDashedLine(Offset(size.width, 0), Offset(size.width, size.height));
    drawDashedLine(Offset(size.width, size.height), Offset(0, size.height));
    drawDashedLine(Offset(0, size.height), const Offset(0, 0));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
