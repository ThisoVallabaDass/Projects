import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../backend.dart';
import '../shared.dart';

class VendorHygieneClient {
  static Future<Map<String, dynamic>?> loadVendorDoc(String uid) async {
    final store = FirebaseFirestore.instance;

    final directDoc = await store.collection('vendors').doc(uid).get();
    if (directDoc.exists) {
      return <String, dynamic>{
        'id': directDoc.id,
        ...?directDoc.data(),
      };
    }

    final ownerQuery = await store
        .collection('vendors')
        .where('ownerId', isEqualTo: uid)
        .limit(1)
        .get();
    if (ownerQuery.docs.isNotEmpty) {
      return <String, dynamic>{
        'id': ownerQuery.docs.first.id,
        ...ownerQuery.docs.first.data(),
      };
    }

    return null;
  }

  static Future<Map<String, dynamic>> registerBaseline({
    required AppProfile profile,
    required List<File> images,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${BackendConfig.hygieneBaseUrl}/verify-registration'),
    )..fields['min_score'] = '0.75';

    for (final image in images.take(10)) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'images',
          image.path,
          filename: p.basename(image.path),
        ),
      );
    }

    final payload = await _sendMultipart(request, failurePrefix: 'Baseline verification failed');
    if (payload['approved'] != true) {
      throw Exception(_extractPrimaryMessage(payload, fallback: 'Workspace baseline setup failed.'));
    }

    await _upsertVendorBaseline(
      profile: profile,
      payload: payload,
      imageCount: images.take(10).length,
    );

    return payload;
  }

  static Future<Map<String, dynamic>> verifyShift({
    required AppProfile profile,
    required File image,
  }) async {
    final vendorData = await loadVendorDoc(profile.id);
    if (vendorData == null) {
      throw Exception('Vendor baseline not found. Please complete workspace setup first.');
    }

    final referenceEmbedding = (vendorData['referenceEmbedding'] as List?) ?? const [];
    if (referenceEmbedding.isEmpty) {
      throw Exception('Reference workspace is missing. Please redo baseline setup.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${BackendConfig.hygieneBaseUrl}/verify-shift'),
    )
      ..fields['reference_embedding'] = jsonEncode(referenceEmbedding)
      ..fields['score_threshold'] = '0.70'
      ..fields['similarity_threshold'] = '0.60'
      ..files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
          filename: p.basename(image.path),
        ),
      );

    final payload = await _sendMultipart(request, failurePrefix: 'Shift hygiene verification failed');
    final allowed =
        payload['allowed'] == true || payload['go_live_allowed'] == true || payload['status'] == 'approved';

    await _updateShiftResult(
      uid: profile.id,
      payload: payload,
      allowed: allowed,
    );

    if (!allowed) {
      throw Exception(_extractPrimaryMessage(payload, fallback: 'Hygiene check failed. Please clean the workspace and try again.'));
    }

    return payload;
  }

  static Future<Map<String, dynamic>> _sendMultipart(
    http.MultipartRequest request, {
    required String failurePrefix,
  }) async {
    try {
      final response = await request.send().timeout(const Duration(seconds: 120));
      final payloadText = await response.stream.bytesToString();
      final payload = payloadText.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(payloadText) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return payload;
      }

      throw Exception(_extractPrimaryMessage(payload, fallback: '$failurePrefix.'));
    } catch (error) {
      throw Exception(
        '$failurePrefix. Make sure the hygiene API is reachable at ${BackendConfig.hygieneBaseUrl}.',
      );
    }
  }

  static Future<void> _upsertVendorBaseline({
    required AppProfile profile,
    required Map<String, dynamic> payload,
    required int imageCount,
  }) async {
    final store = FirebaseFirestore.instance;
    final vendorRef = store.collection('vendors').doc(profile.id);
    final existing = await vendorRef.get();
    final existingData = existing.data() ?? <String, dynamic>{};

    final data = <String, dynamic>{
      ...existingData,
      'shopName': existingData['shopName'] ?? profile.username,
      'ownerId': profile.id,
      'pincode': profile.pincode,
      'businessType': 'food',
      'badge': existingData['badge'] ?? 'Gold',
      'tagline': existingData['tagline'] ?? 'Fresh local food prepared in a verified workspace',
      'story': existingData['story'] ?? 'Verified food vendor workspace for TinyTrails.',
      'imageUrl': existingData['imageUrl'] ?? 'https://picsum.photos/seed/${profile.id}/400/300',
      'hygieneApproved': payload['approved'] == true,
      'requiresDailyHygieneCheck': true,
      'hygieneScore': _asDouble(payload['referenceAverageScore'] ?? payload['averageScore']),
      'referenceEmbedding': (payload['referenceEmbedding'] as List?) ?? const [],
      'baselineImageCount': imageCount,
      'baselineAttentionZone': payload['attentionZone'],
      'baselineReasons': ((payload['reasons'] as List?) ?? const []).whereType<String>().toList(),
      'baselineReferenceAverageScore':
          _asDouble(payload['referenceAverageScore'] ?? payload['averageScore']),
      'lastCheckScore': _asDouble(payload['referenceAverageScore'] ?? payload['averageScore']),
      'lastCheckedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await vendorRef.set(data, SetOptions(merge: true));
  }

  static Future<void> _updateShiftResult({
    required String uid,
    required Map<String, dynamic> payload,
    required bool allowed,
  }) async {
    final vendorRef = FirebaseFirestore.instance.collection('vendors').doc(uid);
    await vendorRef.set({
      'lastCheckScore': _asDouble(payload['score']),
      'lastCheckSimilarity': _asDouble(payload['similarity']),
      'lastCheckAttentionZone': payload['attentionZone'],
      'lastCheckIssues': ((payload['issues'] as List?) ?? const []).whereType<String>().toList(),
      'isHygieneVerified': allowed,
      'lastCheckedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static String _extractPrimaryMessage(
    Map<String, dynamic> payload, {
    required String fallback,
  }) {
    final reasons = ((payload['reasons'] as List?) ?? const []).whereType<String>().toList();
    if (reasons.isNotEmpty) {
      return reasons.first;
    }

    final detail = payload['detail'];
    if (detail is String && detail.isNotEmpty) {
      return detail;
    }

    final message = payload['reason'] ?? payload['message'] ?? payload['error'];
    if (message is String && message.isNotEmpty) {
      return message;
    }

    return fallback;
  }

  static double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
