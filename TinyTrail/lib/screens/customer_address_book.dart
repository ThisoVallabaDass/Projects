import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme.dart';

class CustomerAddressBook extends StatefulWidget {
  const CustomerAddressBook({super.key});

  @override
  State<CustomerAddressBook> createState() => _CustomerAddressBookState();
}

class _CustomerAddressBookState extends State<CustomerAddressBook> {
  final List<Map<String, dynamic>> _addresses = [
    {
      'id': '1',
      'label': 'Home',
      'address': '123 Main St, Anna Nagar',
      'fullAddress': '123 Main St, Anna Nagar, Chennai - 600040',
      'isDefault': true,
      'icon': Icons.home_outlined,
    },
    {
      'id': '2',
      'label': 'Work',
      'address': 'Tech Park, OMR Road',
      'fullAddress': 'Building 5, Tech Park, OMR Road, Chennai - 600096',
      'isDefault': false,
      'icon': Icons.work_outline,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TinyTrailsColors.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Address Book',
          style: GoogleFonts.inter(
            color: TinyTrailsColors.charcoal,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCurrentLocationCard(),
          const SizedBox(height: 16),
          _buildAddNewAddressCard(),
          const SizedBox(height: 20),
          if (_addresses.isNotEmpty) ...[
            Text(
              'Saved Addresses',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TinyTrailsColors.gray500,
              ),
            ),
            const SizedBox(height: 12),
            ...(_addresses.map((address) => _buildAddressCard(address)).toList()),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [TinyTrailsColors.royalBlue, TinyTrailsColors.royalBlue600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use Current Location',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enable GPS for accurate delivery',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _getCurrentLocation,
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewAddressCard() {
    return GestureDetector(
      onTap: () => _showAddAddressDialog(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TinyTrailsColors.royalBlue, width: 1.5, style: BorderStyle.solid),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: TinyTrailsColors.royalBlue50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_location_alt_outlined, color: TinyTrailsColors.royalBlue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Add New Address',
                style: GoogleFonts.inter(
                  color: TinyTrailsColors.royalBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.add, color: TinyTrailsColors.royalBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address) {
    final isDefault = address['isDefault'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDefault ? Border.all(color: TinyTrailsColors.emeraldGreen, width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: TinyTrailsColors.gray100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(address['icon'], color: TinyTrailsColors.gray500, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          address['label'],
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: TinyTrailsColors.charcoal,
                          ),
                        ),
                        if (isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: TinyTrailsColors.emerald50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'DEFAULT',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: TinyTrailsColors.emeraldGreen,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address['fullAddress'],
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: TinyTrailsColors.gray500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!isDefault)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _setAsDefault(address),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: TinyTrailsColors.gray300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Set as Default',
                      style: GoogleFonts.inter(
                        color: TinyTrailsColors.gray500,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              if (!isDefault) const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _editAddress(address),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: TinyTrailsColors.royalBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Edit',
                    style: GoogleFonts.inter(
                      color: TinyTrailsColors.royalBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _deleteAddress(address),
                icon: const Icon(Icons.delete_outline, color: TinyTrailsColors.error),
                style: IconButton.styleFrom(
                  backgroundColor: TinyTrailsColors.error.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fetching your location...')),
      );

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final address = '${place.street}, ${place.subLocality}, ${place.locality} - ${place.postalCode}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location found: $address')),
        );

        _showAddAddressDialogWithAddress(address);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showAddAddressDialog() {
    _showAddressForm(null, null);
  }

  void _showAddAddressDialogWithAddress(String address) {
    _showAddressForm(null, address);
  }

  void _editAddress(Map<String, dynamic> address) {
    _showAddressForm(address, null);
  }

  void _showAddressForm(Map<String, dynamic>? existingAddress, String? prefillAddress) {
    final labelController = TextEditingController(text: existingAddress?['label'] ?? '');
    final flatController = TextEditingController(text: existingAddress?['flat'] ?? '');
    final buildingController = TextEditingController(text: existingAddress?['building'] ?? '');
    final streetController = TextEditingController(text: existingAddress?['street'] ?? '');
    final areaController = TextEditingController(text: existingAddress?['area'] ?? '');
    final landmarkController = TextEditingController(text: existingAddress?['landmark'] ?? '');
    final pincodeController = TextEditingController(text: existingAddress?['pincode'] ?? '');
    String selectedType = existingAddress?['label'] ?? 'Home';

    // If prefillAddress is provided (from GPS), try to parse it
    if (prefillAddress != null && prefillAddress.isNotEmpty) {
      final parts = prefillAddress.split(',');
      if (parts.isNotEmpty) streetController.text = parts[0].trim();
      if (parts.length > 1) areaController.text = parts[1].trim();
      if (parts.length > 2) {
        final cityPin = parts[2].trim().split(' - ');
        if (cityPin.length > 1) pincodeController.text = cityPin[1].trim();
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TinyTrailsColors.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    existingAddress != null ? 'Edit Address' : 'Add New Address',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: TinyTrailsColors.charcoal,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      'Address Type',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: TinyTrailsColors.gray500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: ['Home', 'Work', 'Other'].map((type) {
                        final isSelected = selectedType == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedType = type),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? TinyTrailsColors.royalBlue : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? TinyTrailsColors.royalBlue : TinyTrailsColors.gray200,
                                ),
                              ),
                              child: Text(
                                type,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : TinyTrailsColors.gray500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    if (selectedType == 'Other') ...[
                      _buildFormField(labelController, 'Label', 'e.g., Mom\'s House'),
                      const SizedBox(height: 12),
                    ],
                    _buildFormField(flatController, 'Flat / House No. *', 'e.g., Flat 12A, House No. 45'),
                    const SizedBox(height: 12),
                    _buildFormField(buildingController, 'Building / Apartment Name', 'e.g., Sunshine Apartments'),
                    const SizedBox(height: 12),
                    _buildFormField(streetController, 'Street / Road', 'e.g., MG Road, 2nd Cross Street'),
                    const SizedBox(height: 12),
                    _buildFormField(areaController, 'Area / Locality *', 'e.g., Anna Nagar, Adyar'),
                    const SizedBox(height: 12),
                    _buildFormField(landmarkController, 'Landmark', 'e.g., Near City Mall, Opposite Bus Stand'),
                    const SizedBox(height: 12),
                    _buildFormField(pincodeController, 'Pincode *', 'e.g., 600040', isNumber: true),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (flatController.text.trim().isEmpty ||
                              areaController.text.trim().isEmpty ||
                              pincodeController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill all required fields (*)')),
                            );
                            return;
                          }

                          final label = selectedType == 'Other' && labelController.text.isNotEmpty
                              ? labelController.text
                              : selectedType;

                          final fullAddress = _buildFullAddress(
                            flatController.text,
                            buildingController.text,
                            streetController.text,
                            areaController.text,
                            landmarkController.text,
                            pincodeController.text,
                          );

                          setState(() {
                            if (existingAddress != null) {
                              final index = _addresses.indexWhere((a) => a['id'] == existingAddress['id']);
                              if (index != -1) {
                                _addresses[index] = {
                                  ..._addresses[index],
                                  'label': label,
                                  'address': '${flatController.text}, ${areaController.text}',
                                  'fullAddress': fullAddress,
                                  'flat': flatController.text,
                                  'building': buildingController.text,
                                  'street': streetController.text,
                                  'area': areaController.text,
                                  'landmark': landmarkController.text,
                                  'pincode': pincodeController.text,
                                };
                              }
                            } else {
                              _addresses.add({
                                'id': DateTime.now().millisecondsSinceEpoch.toString(),
                                'label': label,
                                'address': '${flatController.text}, ${areaController.text}',
                                'fullAddress': fullAddress,
                                'flat': flatController.text,
                                'building': buildingController.text,
                                'street': streetController.text,
                                'area': areaController.text,
                                'landmark': landmarkController.text,
                                'pincode': pincodeController.text,
                                'isDefault': _addresses.isEmpty,
                                'icon': label == 'Home'
                                    ? Icons.home_outlined
                                    : label == 'Work'
                                        ? Icons.work_outline
                                        : Icons.location_on_outlined,
                              });
                            }
                          });

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(existingAddress != null ? 'Address updated!' : 'Address added!'),
                              backgroundColor: TinyTrailsColors.emeraldGreen,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TinyTrailsColors.royalBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          existingAddress != null ? 'Update Address' : 'Save Address',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(TextEditingController controller, String label, String hint, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: TinyTrailsColors.gray500),
        hintStyle: GoogleFonts.inter(fontSize: 12, color: TinyTrailsColors.gray300),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: TinyTrailsColors.royalBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  String _buildFullAddress(String flat, String building, String street, String area, String landmark, String pincode) {
    final parts = <String>[];
    if (flat.isNotEmpty) parts.add(flat);
    if (building.isNotEmpty) parts.add(building);
    if (street.isNotEmpty) parts.add(street);
    if (area.isNotEmpty) parts.add(area);
    if (landmark.isNotEmpty) parts.add('Near $landmark');
    if (pincode.isNotEmpty) parts.add('- $pincode');
    return parts.join(', ');
  }

  void _setAsDefault(Map<String, dynamic> address) {
    setState(() {
      for (var addr in _addresses) {
        addr['isDefault'] = addr['id'] == address['id'];
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${address['label']} set as default address'),
        backgroundColor: TinyTrailsColors.emeraldGreen,
      ),
    );
  }

  void _deleteAddress(Map<String, dynamic> address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Address',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete "${address['label']}"?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: TinyTrailsColors.gray500),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _addresses.removeWhere((a) => a['id'] == address['id']);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Address deleted'),
                  backgroundColor: TinyTrailsColors.error,
                ),
              );
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: TinyTrailsColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
