import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../theme/theme.dart';

class VendorDailyShiftCameraScreen extends StatefulWidget {
  const VendorDailyShiftCameraScreen({super.key});

  @override
  State<VendorDailyShiftCameraScreen> createState() => _VendorDailyShiftCameraScreenState();
}

class _VendorDailyShiftCameraScreenState extends State<VendorDailyShiftCameraScreen> {
  static const _apiBaseUrl = String.fromEnvironment(
    'HYGIENE_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  // Demo mode - simulates AI verification when backend is unavailable
  static const bool _enableDemoMode = true;

  final _picker = ImagePicker();
  File? _capturedPhoto;
  bool _isVerifying = false;
  Map<String, dynamic>? _result;
  int _attemptCount = 0;
  bool _isDemoMode = false;

  String get _vendorId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _capturePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 86,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (picked == null) return;

    setState(() {
      _capturedPhoto = File(picked.path);
      _result = null;
    });
  }

  Future<void> _verifyHygiene() async {
    if (_capturedPhoto == null) return;

    if (_vendorId.isEmpty) {
      _showError('Please login again');
      return;
    }

    setState(() {
      _isVerifying = true;
      _result = null;
      _isDemoMode = false;
    });

    try {
      // Check if backend is available
      bool useRealApi = true;

      if (_enableDemoMode) {
        try {
          final testUri = Uri.parse('$_apiBaseUrl/health');
          await http.get(testUri).timeout(const Duration(seconds: 3));
        } catch (e) {
          useRealApi = false;
          setState(() => _isDemoMode = true);
          debugPrint('Backend unavailable, using demo mode: $e');
        }
      }

      Map<String, dynamic> decoded;

      if (useRealApi) {
        decoded = await _verifyWithRealApi();
      } else {
        decoded = await _verifyWithDemoMode();
      }

      setState(() {
        _result = decoded;
        _attemptCount++;
      });

      // If hygiene passed, return success
      if (decoded['hygiene_passed'] == true && mounted) {
        await Future.delayed(const Duration(milliseconds: 800));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (_enableDemoMode && !_isDemoMode) {
        // Offer demo mode if real API failed
        _showDemoModeDialog(e.toString());
      } else {
        _showError(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<Map<String, dynamic>> _verifyWithRealApi() async {
    final uri = Uri.parse('$_apiBaseUrl/verify-daily');
    final request = http.MultipartRequest('POST', uri);

    request.fields['vendor_id'] = _vendorId;
    request.files.add(await http.MultipartFile.fromPath('image', _capturedPhoto!.path));

    final streamed = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw TimeoutException('Server took too long to respond'),
    );
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Verification failed (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _verifyWithDemoMode() async {
    // Simulate AI processing time
    await Future.delayed(const Duration(milliseconds: 1500));

    // Generate realistic demo results
    // 85% chance of passing in demo mode
    final random = Random();
    final score = 80 + random.nextInt(20); // Score between 80-99
    final passed = score >= 85;

    if (passed) {
      return {
        'hygiene_passed': true,
        'score': score,
        'message': 'Workspace looks clean and hygienic! (Demo Mode)',
        'demo_mode': true,
      };
    } else {
      return {
        'hygiene_passed': false,
        'score': score,
        'message': 'Some areas need attention (Demo Mode)',
        'bounding_boxes': [],
        'details': {
          'cleanliness': '${score}%',
          'recommendation': 'Please clean the workspace and try again.',
        },
        'demo_mode': true,
      };
    }
  }

  void _showDemoModeDialog(String error) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cloud_off, color: TinyTrailsColors.warning),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Server Unavailable',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The AI verification server is currently offline. Would you like to continue in Demo Mode?',
              style: GoogleFonts.inter(color: TinyTrailsColors.slateGray),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: TinyTrailsColors.emerald50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: TinyTrailsColors.emeraldGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Demo mode simulates hygiene verification.',
                      style: GoogleFonts.inter(fontSize: 12, color: TinyTrailsColors.emerald800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: TinyTrailsColors.gray500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _runDemoModeVerification();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TinyTrailsColors.emeraldGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Use Demo Mode',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runDemoModeVerification() async {
    setState(() {
      _isVerifying = true;
      _isDemoMode = true;
    });

    try {
      final decoded = await _verifyWithDemoMode();

      setState(() {
        _result = decoded;
        _attemptCount++;
      });

      if (decoded['hygiene_passed'] == true && mounted) {
        await Future.delayed(const Duration(milliseconds: 800));
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _retryVerification() {
    setState(() {
      _capturedPhoto = null;
      _result = null;
    });
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

  @override
  Widget build(BuildContext context) {
    final isPassed = _result?['hygiene_passed'] == true;
    final isFailed = _result?['hygiene_passed'] == false;
    final score = _result?['score'] as int?;
    final message = _result?['message'] as String?;
    final boundingBoxes = (_result?['bounding_boxes'] as List?) ?? [];
    final details = _result?['details'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: TinyTrailsColors.white,
      appBar: AppBar(
        backgroundColor: TinyTrailsColors.white,
        elevation: 0,
        foregroundColor: TinyTrailsColors.charcoal,
        title: Text(
          'Daily Hygiene Check',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_attemptCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: TinyTrailsColors.gray100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Attempt $_attemptCount',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: TinyTrailsColors.gray500,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Banner
              if (_capturedPhoto == null && _result == null) _buildInfoBanner(),

              // Photo Preview
              if (_capturedPhoto != null) ...[
                Expanded(
                  child: _buildPhotoPreview(boundingBoxes),
                ),
                const SizedBox(height: 16),
              ] else if (_result == null) ...[
                Expanded(
                  child: _buildCapturePrompt(),
                ),
              ],

              // Result Card
              if (_result != null) ...[
                if (isPassed) _buildSuccessCard(score, message),
                if (isFailed) _buildFailureCard(score, message, details),
                const SizedBox(height: 16),
              ],

              // Action Buttons
              _buildActionButtons(isPassed, isFailed),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TinyTrailsColors.emerald50,
            TinyTrailsColors.emerald100.withAlpha(150),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TinyTrailsColors.emerald200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: TinyTrailsColors.emeraldGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.verified_user, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Your Shift',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: TinyTrailsColors.emerald900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Take a photo of your workspace',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: TinyTrailsColors.emerald700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Our AI will verify your workspace is clean and hygienic before you go online. This protects both you and your customers.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: TinyTrailsColors.emerald800,
              height: 1.5,
            ),
          ),
          if (_isDemoMode) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: TinyTrailsColors.warning.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.science_outlined, color: TinyTrailsColors.warning, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Demo Mode Active',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: TinyTrailsColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCapturePrompt() {
    return GestureDetector(
      onTap: _capturePhoto,
      child: Container(
        decoration: BoxDecoration(
          color: TinyTrailsColors.gray100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TinyTrailsColors.gray300, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: TinyTrailsColors.emerald50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                size: 48,
                color: TinyTrailsColors.emeraldGreen,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tap to Take Photo',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TinyTrailsColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture your workspace clearly',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: TinyTrailsColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreview(List boundingBoxes) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            _capturedPhoto!,
            fit: BoxFit.cover,
          ),
          // Draw bounding boxes for detected issues
          if (boundingBoxes.isNotEmpty)
            CustomPaint(
              painter: _IssueBoxPainter(boundingBoxes: boundingBoxes),
            ),
          // Overlay gradient when failed
          if (_result?['hygiene_passed'] == false)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    TinyTrailsColors.error.withAlpha(60),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(int? score, String? message) {
    final isDemo = _result?['demo_mode'] == true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TinyTrailsColors.emerald50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TinyTrailsColors.emeraldGreen, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: TinyTrailsColors.emeraldGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Hygiene Check Passed!',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: TinyTrailsColors.emerald800,
                            ),
                          ),
                        ),
                        if (isDemo) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: TinyTrailsColors.warning.withAlpha(30),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'DEMO',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: TinyTrailsColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (score != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Score: $score/100',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: TinyTrailsColors.emerald700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: TinyTrailsColors.emerald700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'You can now go online and start accepting orders!',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TinyTrailsColors.emerald600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureCard(int? score, String? message, Map<String, dynamic>? details) {
    // Get issues list from new API format
    final issuesList = (_result?['issues'] as List?) ?? [];
    final attentionZone = _result?['attentionZoneLabel'] as String?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TinyTrailsColors.error, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: TinyTrailsColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hygiene Issues Detected',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: TinyTrailsColors.error,
                      ),
                    ),
                    if (score != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Score: $score/100 (Min 70 required)',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TinyTrailsColors.error.withAlpha(200),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Display detected issues
          if (issuesList.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Issues Found:',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: TinyTrailsColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            ...issuesList.map((issue) {
              final issueMap = issue as Map<String, dynamic>;
              final issueMessage = issueMap['message'] as String? ?? 'Unknown issue';
              final severity = issueMap['severity'] as String? ?? 'medium';
              final isHigh = severity == 'high';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isHigh
                          ? TinyTrailsColors.error.withAlpha(150)
                          : TinyTrailsColors.warning.withAlpha(150),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _getIssueIcon(issueMap['code'] as String? ?? ''),
                        color: isHigh ? TinyTrailsColors.error : TinyTrailsColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              issueMessage,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: TinyTrailsColors.charcoal,
                              ),
                            ),
                            if (issueMap['advice'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                issueMap['advice'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: TinyTrailsColors.gray500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isHigh
                              ? TinyTrailsColors.error.withAlpha(30)
                              : TinyTrailsColors.warning.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          severity.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isHigh ? TinyTrailsColors.error : TinyTrailsColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ] else if (message != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: TinyTrailsColors.error.withAlpha(100)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.report_problem, color: TinyTrailsColors.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TinyTrailsColors.charcoal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Attention zone indicator
          if (attentionZone != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: TinyTrailsColors.error.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, color: TinyTrailsColors.error, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Focus area: $attentionZone',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: TinyTrailsColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (details != null && issuesList.isEmpty) ...[
            const SizedBox(height: 12),
            _buildDetailsSection(details),
          ],

          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TinyTrailsColors.warning.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: TinyTrailsColors.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message ?? details?['recommendation'] ?? 'Please clean the highlighted areas and take another photo.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: TinyTrailsColors.slateGray,
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

  IconData _getIssueIcon(String code) {
    switch (code) {
      case 'dirty_vessels':
        return Icons.kitchen;
      case 'unclean_stove':
        return Icons.local_fire_department;
      case 'leftover_food':
        return Icons.fastfood;
      case 'cluttered_workspace':
        return Icons.inventory_2;
      case 'grease_stains':
        return Icons.water_drop;
      case 'water_stains':
        return Icons.water;
      case 'poor_lighting':
        return Icons.lightbulb_outline;
      case 'blurry_image':
        return Icons.blur_on;
      default:
        return Icons.warning_amber;
    }
  }

  Widget _buildDetailsSection(Map<String, dynamic> details) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: details.entries
          .where((e) => e.key != 'recommendation')
          .map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: TinyTrailsColors.gray200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_formatKey(entry.key)}: ',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: TinyTrailsColors.gray500,
                ),
              ),
              Text(
                '${entry.value}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: TinyTrailsColors.charcoal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Widget _buildActionButtons(bool isPassed, bool isFailed) {
    if (_isVerifying) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: TinyTrailsColors.emerald50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: TinyTrailsColors.emeraldGreen,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Analyzing workspace...',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: TinyTrailsColors.emerald700,
              ),
            ),
          ],
        ),
      );
    }

    if (isPassed) {
      return SizedBox(
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.arrow_forward),
          label: Text(
            'Continue to Dashboard',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: TinyTrailsColors.emeraldGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      );
    }

    if (isFailed) {
      return Column(
        children: [
          SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _retryVerification,
              icon: const Icon(Icons.refresh),
              label: Text(
                'Clean & Retake Photo',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TinyTrailsColors.emeraldGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel (Go Back)',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: TinyTrailsColors.gray500,
              ),
            ),
          ),
        ],
      );
    }

    // No photo or no result yet
    return Row(
      children: [
        if (_capturedPhoto != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _capturePhoto,
              icon: const Icon(Icons.refresh, size: 20),
              label: Text(
                'Retake',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: TinyTrailsColors.slateGray,
                side: const BorderSide(color: TinyTrailsColors.gray300, width: 2),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: _capturedPhoto != null ? 2 : 1,
          child: ElevatedButton.icon(
            onPressed: _capturedPhoto == null ? _capturePhoto : _verifyHygiene,
            icon: Icon(_capturedPhoto == null ? Icons.camera_alt : Icons.verified_user, size: 22),
            label: Text(
              _capturedPhoto == null ? 'Take Photo' : 'Verify Hygiene',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: TinyTrailsColors.emeraldGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter to draw bounding boxes around detected hygiene issues
class _IssueBoxPainter extends CustomPainter {
  _IssueBoxPainter({required this.boundingBoxes});

  final List boundingBoxes;

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = TinyTrailsColors.error
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = TinyTrailsColors.error.withAlpha(40)
      ..style = PaintingStyle.fill;

    for (final box in boundingBoxes) {
      if (box is! List || box.length < 4) continue;

      final x = (box[0] as num).toDouble();
      final y = (box[1] as num).toDouble();
      final x2 = (box[2] as num).toDouble();
      final y2 = (box[3] as num).toDouble();

      // Scale to actual size (assuming coordinates are absolute pixel values)
      // If they're normalized (0-1), we'd multiply by size.width/height
      final rect = Rect.fromLTRB(x, y, x2, y2);

      // Draw filled rect
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        fillPaint,
      );

      // Draw stroke
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        strokePaint,
      );

      // Draw corner accents
      _drawCorners(canvas, rect, strokePaint.color);
    }
  }

  void _drawCorners(Canvas canvas, Rect rect, Color color) {
    const cornerSize = 16.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(cornerSize, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, cornerSize), paint);

    // Top-right
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(-cornerSize, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, cornerSize), paint);

    // Bottom-left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(cornerSize, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -cornerSize), paint);

    // Bottom-right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(-cornerSize, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(0, -cornerSize), paint);
  }

  @override
  bool shouldRepaint(covariant _IssueBoxPainter oldDelegate) {
    return !identical(oldDelegate.boundingBoxes, boundingBoxes);
  }
}
