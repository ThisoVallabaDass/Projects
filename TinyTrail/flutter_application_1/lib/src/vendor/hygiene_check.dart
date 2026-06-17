import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../shared.dart';
import 'hygiene_client.dart';
class HygieneCheckScreen extends StatefulWidget {
  const HygieneCheckScreen({
    super.key,
    required this.profile,
    required this.onVerified,
  });

  final AppProfile profile;
  final VoidCallback onVerified;

  @override
  State<HygieneCheckScreen> createState() => _HygieneCheckScreenState();
}

class _HygieneCheckScreenState extends State<HygieneCheckScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late final AnimationController _successController;
  late final AnimationController _scanController;
  late final AnimationController _failureController;

  bool _isChecking = false;
  bool _passed = false;
  String? _message;
  String? _attentionZone;
  List<String> _issues = <String>[];

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _failureController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void dispose() {
    _successController.dispose();
    _scanController.dispose();
    _failureController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCheck(ImageSource source) async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
      _message = null;
      _passed = false;
      _attentionZone = null;
      _issues = <String>[];
    });
    _scanController.repeat();

    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 72,
        maxWidth: 1280,
      );

      if (image == null) {
        setState(() {
          _isChecking = false;
          _message = 'Capture cancelled. Please take a workspace photo to continue.';
        });
        _scanController.stop();
        return;
      }

      final result = await _verifyImage(File(image.path));
      final attentionZone = result['attentionZone'] as String?;
      final issues = ((result['issues'] as List?) ?? const []).whereType<String>().toList();
      final allow = result['go_live_allowed'] == true ||
          result['allowed'] == true ||
          result['status'] == 'approved';

      if (!allow) {
        setState(() {
          _isChecking = false;
          _message = _friendlyMessage(result);
          _attentionZone = attentionZone;
          _issues = issues;
        });
        _scanController.stop();
        await _failureController.forward(from: 0);
        return;
      }

      setState(() {
        _isChecking = false;
        _passed = true;
        _message = (result['reason'] as String?) ??
            'Hygiene standards met. You are now ready to go live.';
        _attentionZone = attentionZone;
        _issues = issues;
      });
      _scanController.stop();
      await _successController.forward(from: 0);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (mounted) widget.onVerified();
    } catch (error) {
      setState(() {
        _isChecking = false;
        _message = error.toString().replaceFirst('Exception: ', '');
      });
      _scanController.stop();
      await _failureController.forward(from: 0);
    }
  }

  Future<Map<String, dynamic>> _verifyImage(File imageFile) async {
    if (kIsWeb) {
      throw Exception('Hygiene camera flow is supported on Android for now.');
    }

    return VendorHygieneClient.verifyShift(
      profile: widget.profile,
      image: imageFile,
    );
  }

  String _friendlyMessage(Map<String, dynamic> payload) {
    final text = [
      payload['reason'],
      payload['message'],
      payload['error'],
      payload['details'],
    ].whereType<String>().join(' ').toLowerCase();

    if (text.contains('utensil')) {
      return 'No utensils detected. Keep the stove and vessels clearly visible.';
    }
    if (text.contains('blur')) {
      return 'Photo looks blurry. Please hold steady and try again.';
    }
    if (text.contains('light') || text.contains('dark')) {
      return 'Low light detected. Turn on a light and retake the photo.';
    }
    if (text.contains('clean')) {
      return 'Hygiene check failed. Please clean the workspace and try again.';
    }

    return 'Hygiene check failed. Please capture your workspace again.';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF081420),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF12324D),
                        Color(0xFF081420),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vendor Hygiene Check',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Capture your workspace for hygiene verification before you go live.',
                      style: TextStyle(
                        color: Color(0xFFD4E3F5),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: AnimatedBuilder(
                            animation: _failureController,
                            builder: (context, child) {
                              final shakeOffset =
                                  math.sin(_failureController.value * math.pi * 8) * 8;
                              return Transform.translate(
                                offset: Offset(shakeOffset, 0),
                                child: child,
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                color: const Color(0xFF0D2134),
                                boxShadow: _passed
                                    ? const [
                                        BoxShadow(
                                          color: Color(0x5522C55E),
                                          blurRadius: 28,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                                border: Border.all(
                                  color: _passed
                                      ? const Color(0xFF22C55E)
                                      : (_message != null && !_isChecking)
                                          ? const Color(0xFFEF4444)
                                          : Colors.white.withValues(alpha: 0.95),
                                  width: 2.2,
                                ),
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final scanTop =
                                      22 + ((constraints.maxHeight - 44) * _scanController.value);

                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(18),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(22),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.55),
                                              width: 1.6,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (_isChecking)
                                        Positioned(
                                          left: 28,
                                          right: 28,
                                          top: scanTop,
                                          child: Container(
                                            height: 4,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(999),
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0x0067E8F9),
                                                  Color(0xFF67E8F9),
                                                  Color(0x0067E8F9),
                                                ],
                                              ),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color(0x7767E8F9),
                                                  blurRadius: 12,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      if (_isChecking)
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            SizedBox(
                                              width: 54,
                                              height: 54,
                                              child: CircularProgressIndicator(
                                                color: Color(0xFF67E8F9),
                                                strokeWidth: 3,
                                              ),
                                            ),
                                            SizedBox(height: 18),
                                            Text(
                                              'TinyTrails AI is checking your workspace...',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        )
                                      else if (_passed)
                                        ScaleTransition(
                                          scale: CurvedAnimation(
                                            parent: _successController,
                                            curve: Curves.elasticOut,
                                          ),
                                          child: const Icon(
                                            Icons.verified_rounded,
                                            size: 92,
                                            color: Color(0xFF22C55E),
                                          ),
                                        )
                                      else
                                        const Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.photo_camera_outlined,
                                              size: 72,
                                              color: Colors.white,
                                            ),
                                            SizedBox(height: 18),
                                            Text(
                                              'Frame your cart or kitchen inside the box',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 17,
                                                fontWeight: FontWeight.w800,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(height: 10),
                                            Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 28),
                                              child: Text(
                                                'Focus on utensils, stove, and the active cooking area. Background walls do not matter.',
                                                style: TextStyle(
                                                  color: Color(0xFFD4E3F5),
                                                  height: 1.5,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _passed
                              ? const Color(0xFF12341E)
                              : const Color(0xFF351014),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _passed
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _message!,
                              style: TextStyle(
                                color: _passed
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFFFECACA),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                            if (_attentionZone != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Focus area: ${_attentionZone!.replaceAll('_', ' ')}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            if (_issues.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ..._issues.map(
                                (issue) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '- ${issue.replaceAll('_', ' ')}',
                                    style: const TextStyle(color: Color(0xFFD4E3F5)),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: FilledButton.icon(
                              onPressed: _isChecking
                                  ? null
                                  : () => _pickAndCheck(ImageSource.camera),
                              icon: Icon(
                                _message != null && !_passed
                                    ? Icons.refresh_rounded
                                    : Icons.camera_alt_rounded,
                              ),
                              label: Text(
                                _isChecking
                                    ? 'Checking...'
                                    : _message != null && !_passed
                                        ? 'Retry'
                                        : 'Capture',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF22A35A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: _isChecking
                                  ? null
                                  : () => _pickAndCheck(ImageSource.gallery),
                              icon: const Icon(Icons.file_upload_outlined),
                              label: const Text(
                                'Upload',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.24),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
