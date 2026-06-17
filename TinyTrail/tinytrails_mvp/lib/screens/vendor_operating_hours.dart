import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/theme.dart';
import '../services/firebase_service.dart';
import '../models/models.dart';

class VendorOperatingHoursScreen extends StatefulWidget {
  const VendorOperatingHoursScreen({super.key});

  @override
  State<VendorOperatingHoursScreen> createState() => _VendorOperatingHoursScreenState();
}

class _VendorOperatingHoursScreenState extends State<VendorOperatingHoursScreen> {
  bool _isLoading = true;
  bool _isUpdating = false;

  final Map<String, Map<String, dynamic>> _operatingHours = {
    'monday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '18:00'},
    'tuesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '18:00'},
    'wednesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '18:00'},
    'thursday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '18:00'},
    'friday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '18:00'},
    'saturday': {'isOpen': true, 'openTime': '10:00', 'closeTime': '20:00'},
    'sunday': {'isOpen': false, 'openTime': '10:00', 'closeTime': '16:00'},
  };

  @override
  void initState() {
    super.initState();
    _loadOperatingHours();
  }

  Future<void> _loadOperatingHours() async {
    // In a real implementation, load from Firestore
    setState(() => _isLoading = false);
  }

  Future<void> _saveOperatingHours() async {
    setState(() => _isUpdating = true);

    try {
      // In a real implementation, save to Firestore
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Operating hours updated successfully!'),
            backgroundColor: TinyTrailsColors.emeraldGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: TinyTrailsColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TinyTrailsColors.gray100,
      appBar: AppBar(
        backgroundColor: TinyTrailsColors.white,
        elevation: 0,
        title: Text(
          'Operating Hours',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: TinyTrailsColors.charcoal,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isUpdating ? null : _saveOperatingHours,
            child: _isUpdating
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: TinyTrailsColors.emeraldGreen,
                    ),
                  )
                : Text(
                    'Save',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: TinyTrailsColors.emeraldGreen,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(TinyTrailsColors.emeraldGreen),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 20),
                  _buildOperatingHoursCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TinyTrailsColors.emerald50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TinyTrailsColors.emerald200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TinyTrailsColors.emeraldGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Operating Hours',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: TinyTrailsColors.emeraldGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customers can only place orders during your operating hours. This helps manage your workload better.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: TinyTrailsColors.emerald700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatingHoursCard() {
    return Container(
      decoration: BoxDecoration(
        color: TinyTrailsColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Weekly Schedule',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TinyTrailsColors.charcoal,
              ),
            ),
          ),
          ...List.generate(
            _operatingHours.length,
            (index) {
              final day = _operatingHours.keys.elementAt(index);
              final dayName = _getDayName(day);
              final data = _operatingHours[day]!;
              final isLast = index == _operatingHours.length - 1;

              return Column(
                children: [
                  _buildDayRow(day, dayName, data),
                  if (!isLast) const Divider(height: 1, color: TinyTrailsColors.gray200),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayRow(String dayKey, String dayName, Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              dayName,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: TinyTrailsColors.charcoal,
              ),
            ),
          ),
          Switch(
            value: data['isOpen'],
            onChanged: (value) {
              setState(() {
                _operatingHours[dayKey]!['isOpen'] = value;
              });
            },
            activeColor: TinyTrailsColors.emeraldGreen,
            activeTrackColor: TinyTrailsColors.emerald200,
          ),
          const SizedBox(width: 12),
          if (data['isOpen']) ...[
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: _buildTimeButton(
                      data['openTime'],
                      (time) => setState(() => _operatingHours[dayKey]!['openTime'] = time),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('to', style: TextStyle(fontSize: 12)),
                  ),
                  Expanded(
                    child: _buildTimeButton(
                      data['closeTime'],
                      (time) => setState(() => _operatingHours[dayKey]!['closeTime'] = time),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Expanded(
              flex: 2,
              child: Text(
                'Closed',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: TinyTrailsColors.gray400,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeButton(String time, Function(String) onTimeSelected) {
    return GestureDetector(
      onTap: () => _selectTime(time, onTimeSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: TinyTrailsColors.gray100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: TinyTrailsColors.gray300),
        ),
        child: Text(
          _formatTime(time),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: TinyTrailsColors.charcoal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> _selectTime(String currentTime, Function(String) onTimeSelected) async {
    final parts = currentTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );

    if (picked != null) {
      final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onTimeSelected(formattedTime);
    }
  }

  String _getDayName(String dayKey) {
    final dayNames = {
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',
    };
    return dayNames[dayKey] ?? dayKey;
  }

  String _formatTime(String time24) {
    final parts = time24.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final timeOfDay = TimeOfDay(hour: hour, minute: minute);
    return timeOfDay.format(context);
  }
}