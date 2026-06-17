import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VendorBaselineCameraScreen extends StatefulWidget {
  const VendorBaselineCameraScreen({super.key});

  @override
  State<VendorBaselineCameraScreen> createState() => _VendorBaselineCameraScreenState();
}

class _VendorBaselineCameraScreenState extends State<VendorBaselineCameraScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final List<File?> _photos = List.filled(5, null);
  bool _isUploading = false;

  Future<void> _capturePhoto(int index) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _photos[index] = File(image.path);
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

  Future<void> _uploadAndTrain() async {
    // Validate all photos are taken
    for (int i = 0; i < _photos.length; i++) {
      if (_photos[i] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please take all 5 photos (missing photo ${i + 1})')),
        );
        return;
      }
    }

    setState(() => _isUploading = true);

    try {
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:8000/train-baseline'),
      );

      // Add all 5 images
      for (int i = 0; i < _photos.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            _photos[i]!.path,
          ),
        );
      }

      // Send request
      final response = await request.send();

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Update Firestore: set hasPassedOnboarding = true
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('vendors')
              .doc(user.uid)
              .update({
                'hasPassedOnboarding': true,
                'baselinePhotos': _photos.map((p) => p!.path).toList(),
              });
        }

        // Navigate to vendor main hub
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/vendor-main-hub',
            (route) => false,
          );
        }
      } else {
        final responseBody = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${response.statusCode} - $responseBody'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading photos: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const emeraldGreen = Color(0xFF10B981);
    final allPhotosTaken = _photos.every((photo) => photo != null);

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
          'Setup Baseline Photos',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: emeraldGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: emeraldGreen),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Take 5 photos of your clean workspace',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'These photos will set your hygiene baseline. Take clear photos from different angles showing your clean workspace.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF667085),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Photo Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 5,
              itemBuilder: (context, index) {
                return _PhotoSlot(
                  index: index,
                  photo: _photos[index],
                  onTap: () => _capturePhoto(index),
                );
              },
            ),

            const SizedBox(height: 32),

            // Progress indicator
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _photos.where((p) => p != null).length / 5,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(emeraldGreen),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_photos.where((p) => p != null).length}/5',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Upload Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: emeraldGreen,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: (allPhotosTaken && !_isUploading) ? _uploadAndTrain : null,
                child: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Upload & Train AI',
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
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  final int index;
  final File? photo;
  final VoidCallback onTap;

  const _PhotoSlot({
    required this.index,
    required this.photo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldGreen = Color(0xFF10B981);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: photo != null ? emeraldGreen : const Color(0xFFD7E0EA),
            width: 2,
          ),
          color: photo == null ? Colors.white : null,
        ),
        child: photo != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  photo!,
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F9F4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: emeraldGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Photo ${index + 1}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap to capture',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF667085),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
