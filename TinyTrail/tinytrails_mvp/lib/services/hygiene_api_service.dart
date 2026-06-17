import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Represents a detected hygiene issue
class HygieneIssue {
  final String code;
  final String message;
  final String advice;
  final String severity;

  HygieneIssue({
    required this.code,
    required this.message,
    required this.advice,
    required this.severity,
  });

  factory HygieneIssue.fromJson(Map<String, dynamic> json) {
    return HygieneIssue(
      code: json['code'] as String? ?? 'unknown',
      message: json['message'] as String? ?? 'Unknown issue',
      advice: json['advice'] as String? ?? 'Please clean your workspace',
      severity: json['severity'] as String? ?? 'medium',
    );
  }

  bool get isHighSeverity => severity == 'high';
  bool get isMediumSeverity => severity == 'medium';
  bool get isLowSeverity => severity == 'low';
}

/// Result of a hygiene verification
class HygieneVerificationResult {
  final double score;
  final bool approved;
  final String status;
  final String message;
  final String label;
  final String badgeText;
  final String badgeColor;
  final List<HygieneIssue> issues;
  final String attentionZone;
  final String attentionZoneLabel;
  final double confidence;
  final Map<String, dynamic>? qualityChecks;
  final bool isDemoMode;
  final String? error;

  HygieneVerificationResult({
    required this.score,
    required this.approved,
    required this.status,
    required this.message,
    required this.label,
    required this.badgeText,
    required this.badgeColor,
    required this.issues,
    required this.attentionZone,
    required this.attentionZoneLabel,
    required this.confidence,
    this.qualityChecks,
    this.isDemoMode = false,
    this.error,
  });

  factory HygieneVerificationResult.fromJson(Map<String, dynamic> json) {
    // Parse issues list
    final issuesJson = json['issues'] as List<dynamic>? ?? [];
    final issues = issuesJson
        .map((e) => HygieneIssue.fromJson(e as Map<String, dynamic>))
        .toList();

    return HygieneVerificationResult(
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      approved: json['approved'] as bool? ??
                json['status'] == 'approved' ||
                json['hygiene_passed'] == true,
      status: json['status'] as String? ?? 'unknown',
      message: json['message'] as String? ??
               json['advice'] as String? ??
               json['reason'] as String? ?? '',
      label: json['label'] as String? ?? 'unknown',
      badgeText: json['badgeText'] as String? ?? 'Review',
      badgeColor: json['badgeColor'] as String? ?? 'orange',
      issues: issues,
      attentionZone: json['attentionZone'] as String? ?? 'overall',
      attentionZoneLabel: json['attentionZoneLabel'] as String? ?? 'workspace',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      qualityChecks: json['qualityChecks'] as Map<String, dynamic>?,
      isDemoMode: json['note']?.toString().contains('mock') == true ||
                  json['note']?.toString().contains('Mock') == true,
      error: json['error'] as String?,
    );
  }

  /// Check if there are any high severity issues
  bool get hasHighSeverityIssues =>
      issues.any((issue) => issue.isHighSeverity);

  /// Get the primary issue (highest severity)
  HygieneIssue? get primaryIssue {
    if (issues.isEmpty) return null;
    // Sort by severity: high > medium > low
    final sorted = List<HygieneIssue>.from(issues);
    sorted.sort((a, b) {
      const order = {'high': 0, 'medium': 1, 'low': 2};
      return (order[a.severity] ?? 2).compareTo(order[b.severity] ?? 2);
    });
    return sorted.first;
  }

  /// Get formatted score string
  String get scoreText => '${score.toStringAsFixed(0)}%';

  /// Check if image quality is good
  bool get isGoodQuality {
    if (qualityChecks == null) return true;
    return qualityChecks!['isLowLight'] != true &&
           qualityChecks!['isBlurry'] != true;
  }
}

/// Result of baseline training
class BaselineTrainingResult {
  final bool approved;
  final String status;
  final String message;
  final int imagesSaved;
  final double averageScore;
  final int cleanImagesCount;
  final int minRequired;
  final Map<String, int> issueCounts;
  final List<String> reasons;
  final String? error;

  BaselineTrainingResult({
    required this.approved,
    required this.status,
    required this.message,
    required this.imagesSaved,
    required this.averageScore,
    required this.cleanImagesCount,
    required this.minRequired,
    required this.issueCounts,
    required this.reasons,
    this.error,
  });

  factory BaselineTrainingResult.fromJson(Map<String, dynamic> json) {
    final issueCountsJson = json['issueCounts'] as Map<String, dynamic>? ?? {};
    final issueCounts = issueCountsJson.map(
      (key, value) => MapEntry(key, (value as num).toInt()),
    );

    final reasonsJson = json['reasons'] as List<dynamic>? ?? [];
    final reasons = reasonsJson.map((e) => e.toString()).toList();

    return BaselineTrainingResult(
      approved: json['approved'] as bool? ?? false,
      status: json['status'] as String? ?? 'unknown',
      message: json['message'] as String? ?? '',
      imagesSaved: json['images_saved'] as int? ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      cleanImagesCount: json['cleanImagesCount'] as int? ?? 0,
      minRequired: json['minRequired'] as int? ?? 3,
      issueCounts: issueCounts,
      reasons: reasons,
      error: json['error'] as String?,
    );
  }
}

/// Handles communication with the hygiene API service
class HygieneApiService {
  HygieneApiService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'HYGIENE_API_BASE_URL',
              defaultValue: 'http://10.0.2.2:8000',
            );

  final http.Client _client;
  final String _baseUrl;

  /// Check if the service is available
  Future<bool> isServiceAvailable() async {
    try {
      final uri = Uri.parse('$_baseUrl/health');
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Get service health info
  Future<Map<String, dynamic>> getHealthInfo() async {
    final uri = Uri.parse('$_baseUrl/health');
    try {
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 5),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'status': 'error', 'error': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'status': 'unavailable', 'error': e.toString()};
    }
  }

  /// Verify a single hygiene image
  Future<HygieneVerificationResult> verifyImage(File imageFile) async {
    final uri = Uri.parse('$_baseUrl/verify-hygiene');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    http.StreamedResponse streamed;
    try {
      streamed = await _client.send(request).timeout(
        const Duration(seconds: 30),
      );
    } on SocketException catch (e) {
      throw HttpException('Unable to reach hygiene server: ${e.message}');
    }

    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return HygieneVerificationResult.fromJson(decoded);
      } catch (_) {
        throw const HttpException('Invalid response from hygiene server.');
      }
    }

    throw HttpException(
      'Hygiene verification failed (${response.statusCode}). ${response.body}',
    );
  }

  /// Train baseline for a vendor with multiple images
  Future<BaselineTrainingResult> trainBaseline(
    String vendorId,
    List<File> images,
  ) async {
    if (images.length < 5) {
      throw HttpException('At least 5 images required for baseline training');
    }

    final uri = Uri.parse('$_baseUrl/train-baseline');
    final request = http.MultipartRequest('POST', uri)
      ..fields['vendor_id'] = vendorId;

    for (final image in images) {
      request.files.add(
        await http.MultipartFile.fromPath('images', image.path),
      );
    }

    http.StreamedResponse streamed;
    try {
      streamed = await _client.send(request).timeout(
        const Duration(seconds: 60),
      );
    } on SocketException catch (e) {
      throw HttpException('Unable to reach hygiene server: ${e.message}');
    }

    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return BaselineTrainingResult.fromJson(decoded);
      } catch (_) {
        throw const HttpException('Invalid response from hygiene server.');
      }
    }

    throw HttpException(
      'Baseline training failed (${response.statusCode}). ${response.body}',
    );
  }

  /// Verify daily shift hygiene
  Future<HygieneVerificationResult> verifyDailyShift(
    String vendorId,
    File imageFile,
  ) async {
    final uri = Uri.parse('$_baseUrl/verify-daily');
    final request = http.MultipartRequest('POST', uri)
      ..fields['vendor_id'] = vendorId
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    http.StreamedResponse streamed;
    try {
      streamed = await _client.send(request).timeout(
        const Duration(seconds: 30),
      );
    } on SocketException catch (e) {
      throw HttpException('Unable to reach hygiene server: ${e.message}');
    }

    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return HygieneVerificationResult.fromJson(decoded);
      } catch (_) {
        throw const HttpException('Invalid response from hygiene server.');
      }
    }

    throw HttpException(
      'Daily verification failed (${response.statusCode}). ${response.body}',
    );
  }

  /// Check baseline status for a vendor
  Future<Map<String, dynamic>> getBaselineStatus(String vendorId) async {
    final uri = Uri.parse('$_baseUrl/vendors/$vendorId/baseline-status');

    try {
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'has_baseline': false, 'status': 'error'};
    } catch (e) {
      return {'has_baseline': false, 'status': 'unavailable', 'error': e.toString()};
    }
  }

  /// Get list of all issue categories
  Future<Map<String, dynamic>> getIssueCategories() async {
    final uri = Uri.parse('$_baseUrl/issue-categories');

    try {
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  void dispose() {
    _client.close();
  }
}
