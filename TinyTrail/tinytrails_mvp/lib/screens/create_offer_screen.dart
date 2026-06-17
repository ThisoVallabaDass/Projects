import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/offers_service.dart';
import '../theme/theme.dart';

class CreateOfferScreen extends StatefulWidget {
  final String vendorId;
  final OfferModel? offer;

  const CreateOfferScreen({
    super.key,
    required this.vendorId,
    this.offer,
  });

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final OffersService _offersService = OffersService();

  bool _isLoading = false;

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _promoCodeController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _maxDiscountController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _totalUsageLimitController = TextEditingController();
  final _perUserLimitController = TextEditingController();

  // Form values
  OfferType _selectedType = OfferType.percentage;
  OfferStatus _selectedStatus = OfferStatus.active;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isNewUserOnly = false;
  bool _isVisible = true;
  bool _isFeatured = false;
  int _priority = 1;
  List<String> _terms = ['Valid till stocks last'];

  @override
  void initState() {
    super.initState();
    if (widget.offer != null) {
      _populateFormWithOffer(widget.offer!);
    } else {
      _generatePromoCode();
    }
  }

  void _populateFormWithOffer(OfferModel offer) {
    _titleController.text = offer.title;
    _descriptionController.text = offer.description;
    _promoCodeController.text = offer.promoCode;
    _discountValueController.text = offer.discountValue.toString();
    _maxDiscountController.text = offer.maxDiscountAmount?.toString() ?? '';
    _minOrderController.text = offer.minOrderAmount?.toString() ?? '';
    _totalUsageLimitController.text = offer.totalUsageLimit?.toString() ?? '';
    _perUserLimitController.text = offer.perUserLimit?.toString() ?? '';

    _selectedType = offer.type;
    _selectedStatus = offer.status;
    _startDate = offer.startDate;
    _endDate = offer.endDate;
    _isNewUserOnly = offer.isNewUserOnly;
    _isVisible = offer.isVisible;
    _isFeatured = offer.isFeatured;
    _priority = offer.priority;
    _terms = List<String>.from(offer.terms);
  }

  void _generatePromoCode() {
    // Generate a random promo code
    final prefix = ['SAVE', 'DEAL', 'OFFER', 'SALE', 'DISCOUNT'][DateTime.now().millisecond % 5];
    final suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    _promoCodeController.text = '$prefix$suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TinyTrailsColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: TinyTrailsColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          widget.offer == null ? 'Create New Offer' : 'Edit Offer',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveOffer,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildDiscountSection(),
            const SizedBox(height: 24),
            _buildValiditySection(),
            const SizedBox(height: 24),
            _buildUsageLimitsSection(),
            const SizedBox(height: 24),
            _buildSettingsSection(),
            const SizedBox(height: 24),
            _buildTermsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      'Basic Information',
      Icons.info_outline,
      [
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Offer Title',
            hintText: 'e.g., Weekend Special Discount',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter offer title';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Describe your offer to attract customers',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter offer description';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _promoCodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Promo Code',
                  hintText: 'SAVE20',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter promo code';
                  }
                  if (value.length < 3) {
                    return 'Code must be at least 3 characters';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _generatePromoCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: TinyTrailsColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Generate', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiscountSection() {
    return _buildSection(
      'Discount Details',
      Icons.local_offer_outlined,
      [
        DropdownButtonFormField<OfferType>(
          value: _selectedType,
          decoration: const InputDecoration(
            labelText: 'Discount Type',
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(
              value: OfferType.percentage,
              child: Row(
                children: [
                  Icon(Icons.percent, color: TinyTrailsColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text('Percentage Off'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: OfferType.fixedAmount,
              child: Row(
                children: [
                  Icon(Icons.currency_rupee, color: TinyTrailsColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text('Fixed Amount Off'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: OfferType.freeDelivery,
              child: Row(
                children: [
                  Icon(Icons.delivery_dining, color: TinyTrailsColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text('Free Delivery'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: OfferType.buyOneGetOne,
              child: Row(
                children: [
                  Icon(Icons.add_shopping_cart, color: TinyTrailsColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text('Buy One Get One'),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedType = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        if (_selectedType != OfferType.freeDelivery)
          TextFormField(
            controller: _discountValueController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: _selectedType == OfferType.percentage
                  ? 'Discount Percentage'
                  : 'Discount Amount',
              hintText: _selectedType == OfferType.percentage ? '20' : '100',
              prefixText: _selectedType == OfferType.percentage ? '' : '₹ ',
              suffixText: _selectedType == OfferType.percentage ? '%' : '',
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter discount value';
              }
              final numValue = double.tryParse(value);
              if (numValue == null || numValue <= 0) {
                return 'Please enter a valid positive number';
              }
              if (_selectedType == OfferType.percentage && numValue > 100) {
                return 'Percentage cannot exceed 100%';
              }
              return null;
            },
          ),
        if (_selectedType == OfferType.percentage) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _maxDiscountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Maximum Discount Amount (Optional)',
              hintText: '500',
              prefixText: '₹ ',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: _minOrderController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Minimum Order Amount (Optional)',
            hintText: '299',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildValiditySection() {
    return _buildSection(
      'Validity Period',
      Icons.schedule_outlined,
      [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectDate(context, true),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.arrow_forward, color: Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => _selectDate(context, false),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<OfferStatus>(
          value: _selectedStatus,
          decoration: const InputDecoration(
            labelText: 'Status',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: OfferStatus.active,
              child: Text('Active'),
            ),
            DropdownMenuItem(
              value: OfferStatus.inactive,
              child: Text('Inactive'),
            ),
            DropdownMenuItem(
              value: OfferStatus.scheduled,
              child: Text('Scheduled'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedStatus = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildUsageLimitsSection() {
    return _buildSection(
      'Usage Limits',
      Icons.people_outline,
      [
        TextFormField(
          controller: _totalUsageLimitController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Total Usage Limit (Optional)',
            hintText: '100',
            helperText: 'Maximum number of times this offer can be used',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _perUserLimitController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Per User Limit (Optional)',
            hintText: '1',
            helperText: 'Maximum uses per customer',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return _buildSection(
      'Settings',
      Icons.settings_outlined,
      [
        SwitchListTile(
          title: const Text('New Users Only'),
          subtitle: const Text('Only first-time customers can use this offer'),
          value: _isNewUserOnly,
          onChanged: (value) {
            setState(() {
              _isNewUserOnly = value;
            });
          },
          activeColor: TinyTrailsColors.primary,
        ),
        SwitchListTile(
          title: const Text('Visible to Customers'),
          subtitle: const Text('Show this offer in your store'),
          value: _isVisible,
          onChanged: (value) {
            setState(() {
              _isVisible = value;
            });
          },
          activeColor: TinyTrailsColors.primary,
        ),
        SwitchListTile(
          title: const Text('Featured Offer'),
          subtitle: const Text('Highlight this offer prominently'),
          value: _isFeatured,
          onChanged: (value) {
            setState(() {
              _isFeatured = value;
            });
          },
          activeColor: TinyTrailsColors.primary,
        ),
        TextFormField(
          initialValue: _priority.toString(),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Priority',
            hintText: '1',
            helperText: 'Higher number = shown first (1-10)',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _priority = int.tryParse(value) ?? 1;
          },
        ),
      ],
    );
  }

  Widget _buildTermsSection() {
    return _buildSection(
      'Terms & Conditions',
      Icons.description_outlined,
      [
        Column(
          children: [
            for (int i = 0; i < _terms.length; i++) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _terms[i],
                      decoration: InputDecoration(
                        labelText: 'Term ${i + 1}',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _terms[i] = value;
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _terms.removeAt(i);
                      });
                    },
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _terms.add('');
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Term'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TinyTrailsColors.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TinyTrailsColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: TinyTrailsColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: TinyTrailsColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _saveOffer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final offer = OfferModel(
        id: widget.offer?.id ?? '',
        vendorId: widget.vendorId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        status: _selectedStatus,
        discountValue: double.parse(_discountValueController.text),
        maxDiscountAmount: _maxDiscountController.text.isEmpty
            ? null
            : double.parse(_maxDiscountController.text),
        minOrderAmount: _minOrderController.text.isEmpty
            ? null
            : double.parse(_minOrderController.text),
        startDate: _startDate,
        endDate: _endDate,
        totalUsageLimit: _totalUsageLimitController.text.isEmpty
            ? null
            : int.parse(_totalUsageLimitController.text),
        perUserLimit: _perUserLimitController.text.isEmpty
            ? null
            : int.parse(_perUserLimitController.text),
        terms: _terms.where((term) => term.trim().isNotEmpty).toList(),
        isNewUserOnly: _isNewUserOnly,
        promoCode: _promoCodeController.text.trim().toUpperCase(),
        isVisible: _isVisible,
        isFeatured: _isFeatured,
        priority: _priority,
        createdAt: widget.offer?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        totalUsed: widget.offer?.totalUsed ?? 0,
        userUsage: widget.offer?.userUsage ?? {},
      );

      if (widget.offer == null) {
        await _offersService.createOffer(offer);
      } else {
        await _offersService.updateOffer(offer);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.offer == null
                ? 'Offer created successfully!'
                : 'Offer updated successfully!'),
            backgroundColor: TinyTrailsColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving offer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _promoCodeController.dispose();
    _discountValueController.dispose();
    _maxDiscountController.dispose();
    _minOrderController.dispose();
    _totalUsageLimitController.dispose();
    _perUserLimitController.dispose();
    super.dispose();
  }
}