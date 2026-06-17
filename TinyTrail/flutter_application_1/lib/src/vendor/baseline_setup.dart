import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../shared.dart';
import 'hygiene_client.dart';

class VendorBaselineSetupScreen extends StatefulWidget {
  const VendorBaselineSetupScreen({
    super.key,
    required this.profile,
    required this.onSetupComplete,
  });

  final AppProfile profile;
  final VoidCallback onSetupComplete;

  @override
  State<VendorBaselineSetupScreen> createState() => _VendorBaselineSetupScreenState();
}

class _VendorBaselineSetupScreenState extends State<VendorBaselineSetupScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = <XFile>[];

  bool _submitting = false;
  String? _message;
  String? _attentionZone;
  List<String> _issues = <String>[];

  bool get _canSubmit => _images.length >= 5 && !_submitting;

  Future<void> _captureImage() async {
    if (_images.length >= 10) return;
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 74,
      maxWidth: 1280,
    );
    if (image == null) return;
    setState(() {
      _message = null;
      _images.add(image);
    });
  }

  Future<void> _uploadImages() async {
    if (_images.length >= 10) return;
    final picked = await _picker.pickMultiImage(
      imageQuality: 74,
      maxWidth: 1280,
    );
    if (picked.isEmpty) return;

    final remaining = 10 - _images.length;
    setState(() {
      _message = null;
      _images.addAll(picked.take(remaining));
    });
  }

  Future<void> _submitBaseline() async {
    if (!_canSubmit) return;

    setState(() {
      _submitting = true;
      _message = null;
      _attentionZone = null;
      _issues = <String>[];
    });

    try {
      if (kIsWeb) {
        throw Exception('Baseline workspace setup is supported on Android for now.');
      }

      final payload = await VendorHygieneClient.registerBaseline(
        profile: widget.profile,
        images: _images.take(10).map((image) => File(image.path)).toList(),
      );

      if (!mounted) return;
      setState(() {
        _submitting = false;
        _message =
            'Baseline workspace approved. Daily hygiene checks will now compare against this clean setup.';
        _attentionZone = payload['attentionZone'] as String?;
        _issues = ((payload['reasons'] as List?) ?? const []).whereType<String>().toList();
      });
      await Future<void>.delayed(const Duration(milliseconds: 450));
      widget.onSetupComplete();
      return;
    } catch (error) {
      setState(() {
        _submitting = false;
        _message = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF59D7A5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2610B981),
                      blurRadius: 26,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Set up your clean workspace',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Food vendors must upload 5 to 10 clean workspace photos before going live. Focus on the stove, utensils, prep counter, and cooking zone.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.94),
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        StatusPill(
                          label: '${_images.length}/10 images',
                          background: Colors.white24,
                          foreground: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        const StatusPill(
                          label: 'Need at least 5',
                          background: Colors.white24,
                          foreground: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What the model should see',
                      style: TextStyle(
                        color: AppPalette.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Good photos clearly show clean vessels, the stove, the active prep area, and the food workspace. Dirty walls or old paint matter much less than the cooking zone itself.',
                      style: TextStyle(color: AppPalette.muted, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _submitting || _images.length >= 10 ? null : _captureImage,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Capture'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _submitting || _images.length >= 10 ? null : _uploadImages,
                      icon: const Icon(Icons.file_upload_outlined),
                      label: const Text('Upload'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (_images.isEmpty)
                const SoftCard(
                  child: SizedBox(
                    height: 160,
                    child: Center(
                      child: Text(
                        'No workspace photos added yet.\nCapture or upload baseline images to continue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppPalette.muted, height: 1.5),
                      ),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List<Widget>.generate(_images.length, (index) {
                    final image = _images[index];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            File(image.path),
                            width: 102,
                            height: 102,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 6,
                          top: 6,
                          child: InkWell(
                            onTap: _submitting
                                ? null
                                : () => setState(() => _images.removeAt(index)),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                SoftCard(
                  color: _issues.isEmpty ? const Color(0xFFE7F7EC) : const Color(0xFFFFECE9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _message!,
                        style: TextStyle(
                          color: _issues.isEmpty ? const Color(0xFF166534) : const Color(0xFFB42318),
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                        ),
                      ),
                      if (_attentionZone != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Focus area: ${_attentionZone!.replaceAll('_', ' ')}',
                          style: const TextStyle(
                            color: AppPalette.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (_issues.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ..._issues.map(
                          (issue) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '- ${issue.replaceAll('_', ' ')}',
                              style: const TextStyle(color: AppPalette.ink),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton.icon(
                  onPressed: _canSubmit ? _submitBaseline : null,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.verified_rounded),
                  label: Text(_submitting ? 'Verifying workspace...' : 'Submit baseline setup'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.vendor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
