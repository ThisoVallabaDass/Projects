import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/theme.dart';

class VendorFSSAIScreen extends StatefulWidget {
  const VendorFSSAIScreen({super.key});

  @override
  State<VendorFSSAIScreen> createState() => _VendorFSSAIScreenState();
}

class _VendorFSSAIScreenState extends State<VendorFSSAIScreen> {
  final _fssaiController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isUploading = false;
  String? _fssaiNumber;
  DateTime? _expiryDate;
  String? _documentUrl;

  @override
  void initState() {
    super.initState();
    _loadFSSAIData();
  }

  Future<void> _loadFSSAIData() async {
    setState(() => _isLoading = true);

    // In a real implementation, load from Firestore
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
      // Mock data
      _fssaiNumber = null; // No FSSAI registered yet
    });
  }

  Future<void> _saveFSSAIData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      // In a real implementation, save to Firestore
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _fssaiNumber = _fssaiController.text.trim();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('FSSAI details saved successfully!'),
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
            content: Text('Failed to save: $e'),
            backgroundColor: TinyTrailsColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  void dispose() {
    _fssaiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TinyTrailsColors.gray100,
      appBar: AppBar(
        backgroundColor: TinyTrailsColors.white,
        elevation: 0,
        title: Text(
          'FSSAI & Documents',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: TinyTrailsColors.charcoal,
          ),
        ),
        centerTitle: true,
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
                  _buildRequirementCard(),
                  const SizedBox(height: 20),
                  if (_fssaiNumber == null) _buildFSSAIForm() else _buildFSSAIStatus(),
                  const SizedBox(height: 20),
                  _buildDocumentsSection(),
                  const SizedBox(height: 20),
                  _buildHelpSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildRequirementCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TinyTrailsColors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TinyTrailsColors.warning.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TinyTrailsColors.warning,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'FSSAI License Required',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: TinyTrailsColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'As a food vendor, you need a valid FSSAI license to operate legally. This ensures food safety and builds customer trust.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: TinyTrailsColors.charcoal,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFSSAIForm() {
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter FSSAI Details',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: TinyTrailsColors.charcoal,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fssaiController,
                validator: (v) {
                  if (v?.trim().isEmpty ?? true) return 'FSSAI number is required';
                  if (v!.length != 14) return 'FSSAI number should be 14 digits';
                  return null;
                },
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'FSSAI License Number',
                  hintText: 'Enter 14-digit FSSAI number',
                  prefixIcon: const Icon(Icons.assignment_outlined),
                  filled: true,
                  fillColor: TinyTrailsColors.gray100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: TinyTrailsColors.emeraldGreen, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _expiryDate == null
                      ? 'Select Expiry Date'
                      : 'Expires: ${_formatDate(_expiryDate!)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                leading: const Icon(Icons.calendar_today_outlined),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _selectExpiryDate(),
                tileColor: TinyTrailsColors.gray100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _saveFSSAIData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TinyTrailsColors.emeraldGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text(
                          'Save FSSAI Details',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFSSAIStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: TinyTrailsColors.emerald50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.verified, color: TinyTrailsColors.emeraldGreen, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FSSAI Verified',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: TinyTrailsColors.emeraldGreen,
                      ),
                    ),
                    Text(
                      'License: $_fssaiNumber',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: TinyTrailsColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TinyTrailsColors.emerald50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: TinyTrailsColors.emeraldGreen, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your food business is legally compliant and ready to serve customers!',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: TinyTrailsColors.emerald700,
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

  Widget _buildDocumentsSection() {
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
              'Required Documents',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: TinyTrailsColors.charcoal,
              ),
            ),
          ),
          _buildDocumentItem(
            'FSSAI License Certificate',
            'Upload your FSSAI license document',
            Icons.description_outlined,
            _documentUrl != null,
          ),
          _buildDivider(),
          _buildDocumentItem(
            'Shop & Establishment License',
            'Business registration document',
            Icons.business_outlined,
            false,
          ),
          _buildDivider(),
          _buildDocumentItem(
            'PAN Card',
            'Tax identification document',
            Icons.credit_card_outlined,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(String title, String subtitle, IconData icon, bool isUploaded) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isUploaded ? TinyTrailsColors.emerald50 : TinyTrailsColors.gray100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isUploaded ? TinyTrailsColors.emeraldGreen : TinyTrailsColors.gray500,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: TinyTrailsColors.charcoal,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: TinyTrailsColors.gray500,
        ),
      ),
      trailing: isUploaded
          ? const Icon(Icons.check_circle, color: TinyTrailsColors.emeraldGreen)
          : TextButton(
              onPressed: () => _uploadDocument(title),
              child: Text(
                'Upload',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: TinyTrailsColors.emeraldGreen,
                ),
              ),
            ),
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TinyTrailsColors.royalBlue50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TinyTrailsColors.royalBlue200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline, color: TinyTrailsColors.royalBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Need Help?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: TinyTrailsColors.royalBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Apply for FSSAI license at fssai.gov.in\n• For basic license: ₹100 fee for 1 year\n• For state license: ₹2000+ fee for 1-5 years\n• Contact TinyTrails support for assistance',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: TinyTrailsColors.royalBlue,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: TinyTrailsColors.gray200),
    );
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _uploadDocument(String documentType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Document upload for $documentType coming soon!'),
        backgroundColor: TinyTrailsColors.charcoal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}