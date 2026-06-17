import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VendorDailyShiftCameraScreen extends StatefulWidget {
  const VendorDailyShiftCameraScreen({super.key});

  @override
  State<VendorDailyShiftCameraScreen> createState() => _VendorDailyShiftCameraScreenState();
}

class _VendorDailyShiftCameraScreenState extends State<VendorDailyShiftCameraScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _capturedPhoto;
  bool _isVerifying = false;
  Map<String, dynamic>? _verificationResult;

  Future<void> _capturePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _capturedPhoto = File(image.path);
          _verificationResult = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing photo: $e')),
        );
      }
    }
  }

  Future<void> _verifyHygiene() async {
    if (_capturedPhoto == null) return;

    setState(() => _isVerifying = true);

    try {
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:8000/verify-daily'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _capturedPhoto!.path,
        ),
      );

      final response = await request.send();

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final result = json.decode(responseBody);

        setState(() {
          _verificationResult = result;
        });

        if (result['status'] == 'passed') {
          // Show success dialog
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('✓ Hygiene Check Passed'),
              content: const Text('Your workspace passed the hygiene check. You can now start your shift.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context); // Return to previous screen
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying photo: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _retakPhoto() {
    setState(() {
      _capturedPhoto = null;
      _verificationResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    const emeraldGreen = Color(0xFF10B981);

    if (_capturedPhoto == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Daily Hygiene Check',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(Icons.camera_alt, size: 64, color: Colors.white54),
              const SizedBox(height: 24),
              const Text(
                'Take a photo of your workspace',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This will be verified against your baseline for cleanliness.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FloatingActionButton(
                onPressed: _capturePhoto,
                backgroundColor: emeraldGreen,
                child: const Icon(Icons.camera_alt),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    }

    // Photo captured - show preview and verification button
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verify Photo',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _verificationResult == null
          ? _buildPreviewView(emeraldGreen)
          : _verificationResult!['status'] == 'passed'
              ? _buildPassedView(emeraldGreen)
              : _buildFailedView(emeraldGreen),
    );
  }

  Widget _buildPreviewView(Color emeraldGreen) {
    return Column(
      children: [
        // Image preview
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140F172A),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _capturedPhoto!,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        // Buttons
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Verify button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: emeraldGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isVerifying ? null : _verifyHygiene,
                  child: _isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify Hygiene',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              // Retake button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: emeraldGreen, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _retakPhoto,
                  child: Text(
                    'Retake Photo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: emeraldGreen,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPassedView(Color emeraldGreen) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: emeraldGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.check_circle,
              color: Color(0xFF10B981),
              size: 60,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Hygiene Check Passed!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your workspace looks clean and ready for business.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF667085),
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: emeraldGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Start Shift',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFailedView(Color emeraldGreen) {
    final anomalies = _verificationResult!['anomalies'] as List? ?? [];

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Image with bounding boxes
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140F172A),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.file(
                    _capturedPhoto!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                  CustomPaint(
                    painter: AnomalyPainter(anomalies: anomalies),
                    size: Size.infinite,
                  ),
                ],
              ),
            ),
          ),

          // Error message
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEF5350)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ Hygiene Check Failed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC62828),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please clean the highlighted areas and retry.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Detected issues
          if (anomalies.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Issues Detected:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...anomalies.map((anomaly) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF5350),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              anomaly['issue'] ?? 'Unknown issue',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF667085),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: emeraldGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _retakPhoto,
                    child: const Text(
                      'Retake Photo',
                      style: TextStyle(
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
        ],
      ),
    );
  }
}

class AnomalyPainter extends CustomPainter {
  final List<dynamic> anomalies;

  AnomalyPainter({required this.anomalies});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEF5350)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (var anomaly in anomalies) {
      if (anomaly is Map && anomaly.containsKey('box')) {
        final box = anomaly['box'] as List;
        if (box.length >= 4) {
          final x = box[0] as num;
          final y = box[1] as num;
          final width = box[2] as num;
          final height = box[3] as num;

          // Scale to actual image size
          final rect = Rect.fromLTWH(
            x.toDouble() * size.width,
            y.toDouble() * size.height,
            width.toDouble() * size.width,
            height.toDouble() * size.height,
          );

          // Draw bounding box
          canvas.drawRect(rect, paint);

          // Draw corner markers
          const cornerSize = 12.0;
          final cornerPaint = Paint()
            ..color = const Color(0xFFEF5350)
            ..strokeWidth = 3;

          // Top-left
          canvas.drawLine(
            Offset(rect.left, rect.top),
            Offset(rect.left + cornerSize, rect.top),
            cornerPaint,
          );
          canvas.drawLine(
            Offset(rect.left, rect.top),
            Offset(rect.left, rect.top + cornerSize),
            cornerPaint,
          );

          // Top-right
          canvas.drawLine(
            Offset(rect.right, rect.top),
            Offset(rect.right - cornerSize, rect.top),
            cornerPaint,
          );
          canvas.drawLine(
            Offset(rect.right, rect.top),
            Offset(rect.right, rect.top + cornerSize),
            cornerPaint,
          );

          // Bottom-left
          canvas.drawLine(
            Offset(rect.left, rect.bottom),
            Offset(rect.left + cornerSize, rect.bottom),
            cornerPaint,
          );
          canvas.drawLine(
            Offset(rect.left, rect.bottom),
            Offset(rect.left, rect.bottom - cornerSize),
            cornerPaint,
          );

          // Bottom-right
          canvas.drawLine(
            Offset(rect.right, rect.bottom),
            Offset(rect.right - cornerSize, rect.bottom),
            cornerPaint,
          );
          canvas.drawLine(
            Offset(rect.right, rect.bottom),
            Offset(rect.right, rect.bottom - cornerSize),
            cornerPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(AnomalyPainter oldDelegate) {
    return oldDelegate.anomalies != anomalies;
  }
}
