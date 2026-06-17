import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../theme/theme.dart';
import 'vendor_main_hub.dart';

class VendorBaselineCameraScreen extends StatefulWidget {
  const VendorBaselineCameraScreen({super.key});

  @override
  State<VendorBaselineCameraScreen> createState() => _VendorBaselineCameraScreenState();
}

class _VendorBaselineCameraScreenState extends State<VendorBaselineCameraScreen> {
  static const _apiBaseUrl = String.fromEnvironment(
    'HYGIENE_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  // Demo mode - simulates AI training when backend is unavailable
  static const bool _enableDemoMode = true;

  static const int _minPhotos = 5;
  static const int _maxPhotos = 10;

  final _picker = ImagePicker();
  final List<File> _photos = [];
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _statusMessage;
  bool _isDemoMode = false;

  String get _vendorId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _capturePhoto() async {
    if (_photos.length >= _maxPhotos) {
      _showMessage('Maximum $_maxPhotos photos reached', isError: true);
      return;
    }

    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (picked == null) return;

    setState(() {
      _photos.add(File(picked.path));
    });
  }

  Future<void> _pickFromGallery() async {
    if (_photos.length >= _maxPhotos) {
      _showMessage('Maximum $_maxPhotos photos reached', isError: true);
      return;
    }

    final remaining = _maxPhotos - _photos.length;
    final picked = await _picker.pickMultiImage(
      imageQuality: 85,
      limit: remaining,
    );
    if (picked.isEmpty) return;

    setState(() {
      for (final img in picked) {
        if (_photos.length < _maxPhotos) {
          _photos.add(File(img.path));
        }
      }
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? TinyTrailsColors.error : TinyTrailsColors.emeraldGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _uploadAndTrainBaseline() async {
    if (_photos.length < _minPhotos) {
      _showMessage('Please capture at least $_minPhotos photos', isError: true);
      return;
    }

    if (_vendorId.isEmpty) {
      _showMessage('Please login again', isError: true);
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _statusMessage = 'Preparing photos...';
      _isDemoMode = false;
    });

    try {
      // Try to connect to the real API first
      bool useRealApi = true;

      if (_enableDemoMode) {
        // Quick connectivity check
        try {
          final testUri = Uri.parse('$_apiBaseUrl/health');
          await http.get(testUri).timeout(const Duration(seconds: 3));
        } catch (e) {
          // Backend unavailable, switch to demo mode
          useRealApi = false;
          setState(() => _isDemoMode = true);
          debugPrint('Backend unavailable, using demo mode: $e');
        }
      }

      if (useRealApi) {
        // Real API flow
        await _trainWithRealApi();
      } else {
        // Demo mode - simulate AI training
        await _trainWithDemoMode();
      }

      // Update Firestore profile
      setState(() {
        _uploadProgress = 0.95;
        _statusMessage = 'Saving profile...';
      });

      await FirebaseFirestore.instance.collection('users').doc(_vendorId).set({
        'hasPassedOnboarding': true,
        'baselineTrainedAt': FieldValue.serverTimestamp(),
        'baselinePhotoCount': _photos.length,
        'isDemoMode': _isDemoMode,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _uploadProgress = 1.0;
        _statusMessage = 'Complete!';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Show success and navigate
      final successMsg = _isDemoMode
          ? 'Demo AI Model created! (Backend offline)'
          : 'AI Model trained successfully!';
      _showMessage(successMsg);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const VendorMainHub()),
        (route) => false,
      );
    } catch (e) {
      // If real API fails and demo mode is enabled, offer to use demo mode
      if (_enableDemoMode && !_isDemoMode) {
        _showDemoModeDialog(e.toString());
      } else {
        _showMessage('Training failed: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0;
          _statusMessage = null;
        });
      }
    }
  }

  Future<void> _trainWithRealApi() async {
    final uri = Uri.parse('$_apiBaseUrl/train-baseline');
    final request = http.MultipartRequest('POST', uri);

    // Add vendor ID
    request.fields['vendor_id'] = _vendorId;

    // Add all photos
    setState(() => _statusMessage = 'Uploading photos...');
    for (int i = 0; i < _photos.length; i++) {
      request.files.add(await http.MultipartFile.fromPath('images', _photos[i].path));
      setState(() => _uploadProgress = (i + 1) / _photos.length * 0.6);
    }

    setState(() {
      _uploadProgress = 0.7;
      _statusMessage = 'Training AI model...';
    });

    // Send request with timeout
    final streamed = await request.send().timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw TimeoutException('Server took too long to respond'),
    );
    final response = await http.Response.fromStream(streamed);

    setState(() => _uploadProgress = 0.9);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Upload failed (${response.statusCode}): ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    // Check for success
    if (json['status'] != 'success') {
      final message = json['message'] ?? 'Baseline training failed';
      throw Exception(message);
    }
  }

  Future<void> _trainWithDemoMode() async {
    // Simulate photo processing
    setState(() => _statusMessage = 'Processing photos (Demo)...');
    for (int i = 0; i < _photos.length; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() => _uploadProgress = (i + 1) / _photos.length * 0.5);
    }

    // Simulate AI training
    setState(() {
      _uploadProgress = 0.6;
      _statusMessage = 'Analyzing workspace (Demo)...';
    });
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _uploadProgress = 0.75;
      _statusMessage = 'Training AI model (Demo)...';
    });
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _uploadProgress = 0.9;
      _statusMessage = 'Finalizing model (Demo)...';
    });
    await Future.delayed(const Duration(milliseconds: 500));
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
            Text(
              'Server Unavailable',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The AI training server is currently offline. Would you like to continue in Demo Mode?',
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
                      'Demo mode simulates AI training so you can explore the app.',
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
              _runDemoModeTraining();
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

    setState(() {
      _isUploading = false;
      _uploadProgress = 0;
      _statusMessage = null;
    });
  }

  Future<void> _runDemoModeTraining() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _statusMessage = 'Starting Demo Mode...';
      _isDemoMode = true;
    });

    try {
      await _trainWithDemoMode();

      // Update Firestore profile
      setState(() {
        _uploadProgress = 0.95;
        _statusMessage = 'Saving profile...';
      });

      await FirebaseFirestore.instance.collection('users').doc(_vendorId).set({
        'hasPassedOnboarding': true,
        'baselineTrainedAt': FieldValue.serverTimestamp(),
        'baselinePhotoCount': _photos.length,
        'isDemoMode': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _uploadProgress = 1.0;
        _statusMessage = 'Complete!';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      _showMessage('Demo AI Model created successfully!');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const VendorMainHub()),
        (route) => false,
      );
    } catch (e) {
      _showMessage('Demo training failed: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0;
          _statusMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _photos.length >= _minPhotos;

    return Scaffold(
      backgroundColor: TinyTrailsColors.white,
      appBar: AppBar(
        backgroundColor: TinyTrailsColors.white,
        elevation: 0,
        foregroundColor: TinyTrailsColors.charcoal,
        title: Text(
          'AI Hygiene Setup',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              _buildInfoBanner(),
              const SizedBox(height: 20),

              // Progress indicator
              _buildProgressIndicator(),
              const SizedBox(height: 20),

              // Photo Grid
              Expanded(child: _buildPhotoGrid()),
              const SizedBox(height: 16),

              // Action Buttons
              if (!_isUploading) _buildActionButtons(),

              // Upload Progress
              if (_isUploading) _buildUploadProgress(),

              const SizedBox(height: 12),

              // Train Button
              _buildTrainButton(ready),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TinyTrailsColors.emeraldGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Train Your AI Model',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: TinyTrailsColors.emerald900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Take photos of your CLEAN workspace from different angles. This trains the AI to recognize your hygienic baseline.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: TinyTrailsColors.emerald800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTip('Counter top'),
              const SizedBox(width: 8),
              _buildTip('Cooking area'),
              const SizedBox(width: 8),
              _buildTip('Storage'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: TinyTrailsColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: TinyTrailsColors.emeraldGreen,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final progress = _photos.length / _minPhotos;
    final isComplete = _photos.length >= _minPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_photos.length} / $_minPhotos minimum photos',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isComplete ? TinyTrailsColors.emeraldGreen : TinyTrailsColors.slateGray,
              ),
            ),
            if (_photos.length < _maxPhotos)
              Text(
                'Max $_maxPhotos',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: TinyTrailsColors.gray400,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: TinyTrailsColors.gray200,
            valueColor: AlwaysStoppedAnimation(
              isComplete ? TinyTrailsColors.emeraldGreen : TinyTrailsColors.warning,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      itemCount: _photos.length + (_photos.length < _maxPhotos ? 1 : 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        // Add photo button
        if (index == _photos.length && _photos.length < _maxPhotos) {
          return GestureDetector(
            onTap: _capturePhoto,
            child: Container(
              decoration: BoxDecoration(
                color: TinyTrailsColors.gray100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: TinyTrailsColors.gray300,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    color: TinyTrailsColors.gray400,
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add Photo',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: TinyTrailsColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Photo tile
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: TinyTrailsColors.emeraldGreen,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _photos[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            // Photo number badge
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: TinyTrailsColors.emeraldGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Remove button
            Positioned(
              right: 6,
              top: 6,
              child: GestureDetector(
                onTap: () => _removePhoto(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: TinyTrailsColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _capturePhoto,
            icon: const Icon(Icons.camera_alt_outlined, size: 20),
            label: Text(
              'Camera',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: TinyTrailsColors.emeraldGreen,
              side: const BorderSide(color: TinyTrailsColors.emeraldGreen, width: 2),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickFromGallery,
            icon: const Icon(Icons.photo_library_outlined, size: 20),
            label: Text(
              'Gallery',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: TinyTrailsColors.slateGray,
              side: const BorderSide(color: TinyTrailsColors.gray300, width: 2),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TinyTrailsColors.emerald50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TinyTrailsColors.emerald200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  value: _uploadProgress,
                  backgroundColor: TinyTrailsColors.emerald200,
                  valueColor: const AlwaysStoppedAnimation(TinyTrailsColors.emeraldGreen),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusMessage ?? 'Processing...',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TinyTrailsColors.emerald800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(_uploadProgress * 100).toInt()}% complete',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: TinyTrailsColors.emerald600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _uploadProgress,
              minHeight: 6,
              backgroundColor: TinyTrailsColors.emerald200,
              valueColor: const AlwaysStoppedAnimation(TinyTrailsColors.emeraldGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainButton(bool ready) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: (!ready || _isUploading) ? null : _uploadAndTrainBaseline,
        icon: _isUploading
            ? const SizedBox.shrink()
            : const Icon(Icons.model_training, size: 22),
        label: Text(
          _isUploading
              ? 'Training AI...'
              : ready
                  ? 'Train AI Model (${_photos.length} photos)'
                  : 'Need ${_minPhotos - _photos.length} more photos',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: TinyTrailsColors.emeraldGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: TinyTrailsColors.gray300,
          disabledForegroundColor: TinyTrailsColors.gray500,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }
}
