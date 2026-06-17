import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../theme/theme.dart';
import '../services/firebase_service.dart';
import '../models/models.dart';

class VendorAIChatWidget extends StatefulWidget {
  final String vendorId;
  final String vendorCategory;

  const VendorAIChatWidget({
    super.key,
    required this.vendorId,
    required this.vendorCategory,
  });

  @override
  State<VendorAIChatWidget> createState() => _VendorAIChatWidgetState();
}

class _VendorAIChatWidgetState extends State<VendorAIChatWidget>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isExpanded = false;

  late AnimationController _fabAnimationController;
  late AnimationController _chatAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<Offset> _chatSlideAnimation;
  late Animation<double> _chatOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeChat();
  }

  void _initAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _chatAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    _chatSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _chatAnimationController,
      curve: Curves.easeOutBack,
    ));

    _chatOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chatAnimationController, curve: Curves.easeIn),
    );
  }

  void _initializeChat() {
    _messages.add(
      ChatMessage(
        text: widget.vendorCategory == 'food'
            ? "🍽️ Hi! I'm Trail AI, your food business assistant! I can help you:\n\n• Add new dishes to your menu\n• Upload food photos\n• Create special offers\n• Manage your inventory\n\nWhat would you like to do today?"
            : "🛍️ Hi! I'm Trail AI, your business assistant! I can help you:\n\n• Add new products to your catalog\n• Upload product photos\n• Create special offers\n• Manage your inventory\n\nWhat would you like to do today?",
        isAI: true,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _fabAnimationController.dispose();
    _chatAnimationController.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _fabAnimationController.forward();
      _chatAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
      _chatAnimationController.reverse();
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isAI: false,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate AI response based on message content
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      final aiResponse = _generateAIResponse(text);
      setState(() {
        _messages.add(aiResponse);
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  ChatMessage _generateAIResponse(String userMessage) {
    final lowercaseMessage = userMessage.toLowerCase();

    if (lowercaseMessage.contains('add') && (lowercaseMessage.contains('dish') || lowercaseMessage.contains('product') || lowercaseMessage.contains('item'))) {
      return ChatMessage(
        text: "I'll help you add a new ${widget.vendorCategory == 'food' ? 'dish' : 'product'}! Please provide:\n\n1. ${widget.vendorCategory == 'food' ? 'Dish' : 'Product'} name\n2. Price (in ₹)\n3. Description\n4. Category${widget.vendorCategory == 'food' ? '\n5. Veg or Non-Veg?' : ''}\n\nOr you can use the quick add form above!",
        isAI: true,
        timestamp: DateTime.now(),
        actions: [
          ChatAction(
            label: 'Quick Add Form',
            onTap: () => _showQuickAddForm(),
          ),
        ],
      );
    } else if (lowercaseMessage.contains('photo') || lowercaseMessage.contains('image') || lowercaseMessage.contains('picture')) {
      return ChatMessage(
        text: "📸 I can help you upload photos! You can:\n\n• Take a new photo with camera\n• Choose from gallery\n• Add photos to existing ${widget.vendorCategory == 'food' ? 'dishes' : 'products'}\n\nGood photos increase customer interest by 40%!",
        isAI: true,
        timestamp: DateTime.now(),
        actions: [
          ChatAction(
            label: 'Take Photo',
            onTap: () => _pickImage(ImageSource.camera),
          ),
          ChatAction(
            label: 'Choose from Gallery',
            onTap: () => _pickImage(ImageSource.gallery),
          ),
        ],
      );
    } else if (lowercaseMessage.contains('offer') || lowercaseMessage.contains('discount') || lowercaseMessage.contains('coupon')) {
      return ChatMessage(
        text: "🎉 Great! Let's create an attractive offer. Popular options:\n\n• Buy 1 Get 1 Free\n• 20% off on orders above ₹200\n• Flat ₹50 off\n• Combo deals\n\nWhat type of offer would you like to create?",
        isAI: true,
        timestamp: DateTime.now(),
        actions: [
          ChatAction(
            label: 'Percentage Discount',
            onTap: () => _showOfferForm('percentage'),
          ),
          ChatAction(
            label: 'Flat Amount Off',
            onTap: () => _showOfferForm('flat'),
          ),
          ChatAction(
            label: 'Buy 1 Get 1',
            onTap: () => _showOfferForm('bogo'),
          ),
        ],
      );
    } else if (lowercaseMessage.contains('inventory') || lowercaseMessage.contains('stock')) {
      return ChatMessage(
        text: "📦 I can help manage your inventory! You can:\n\n• Mark items as in-stock or out-of-stock\n• View stock status of all items\n• Get alerts for low stock\n\nWould you like to check your current inventory?",
        isAI: true,
        timestamp: DateTime.now(),
        actions: [
          ChatAction(
            label: 'View Inventory',
            onTap: () => _showInventoryDialog(),
          ),
        ],
      );
    } else if (lowercaseMessage.contains('help') || lowercaseMessage.contains('what can you do')) {
      return ChatMessage(
        text: widget.vendorCategory == 'food'
            ? "🤖 I'm your AI assistant for food business! I can help with:\n\n🍽️ Menu Management\n📸 Photo Upload\n🎯 Marketing & Offers\n📦 Inventory Tracking\n📊 Sales Insights\n🔧 Business Setup\n\nJust tell me what you need!"
            : "🤖 I'm your AI assistant for your business! I can help with:\n\n🛍️ Product Management\n📸 Photo Upload\n🎯 Marketing & Offers\n📦 Inventory Tracking\n📊 Sales Insights\n🔧 Business Setup\n\nJust tell me what you need!",
        isAI: true,
        timestamp: DateTime.now(),
      );
    } else {
      // Generic helpful response
      final responses = [
        "That's interesting! Could you tell me more about what you'd like to achieve?",
        "I'm here to help with your business! Try asking about adding ${widget.vendorCategory == 'food' ? 'dishes' : 'products'}, uploading photos, or creating offers.",
        "Let me help you with that! What specific task would you like assistance with?",
        "I can assist with menu management, photos, offers, and inventory. What would you like to work on?",
      ];
      return ChatMessage(
        text: responses[DateTime.now().millisecond % responses.length],
        isAI: true,
        timestamp: DateTime.now(),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _messages.add(ChatMessage(
            text: "📸 Photo selected! Here's what I can do with it:\n\n• Add to existing ${widget.vendorCategory == 'food' ? 'dish' : 'product'}\n• Create new ${widget.vendorCategory == 'food' ? 'menu item' : 'product'} with this photo\n• Use for promotional content",
            isAI: true,
            timestamp: DateTime.now(),
            imagePath: image.path,
            actions: [
              ChatAction(
                label: 'Add to Existing Item',
                onTap: () => _showAddToExistingDialog(image.path),
              ),
              ChatAction(
                label: 'Create New Item',
                onTap: () => _showQuickAddForm(imagePath: image.path),
              ),
            ],
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: TinyTrailsColors.error,
        ),
      );
    }
  }

  void _showQuickAddForm({String? imagePath}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickAddForm(
        vendorId: widget.vendorId,
        vendorCategory: widget.vendorCategory,
        imagePath: imagePath,
        onSuccess: () {
          setState(() {
            _messages.add(ChatMessage(
              text: "✅ Great! Your ${widget.vendorCategory == 'food' ? 'dish' : 'product'} has been added to your menu successfully!",
              isAI: true,
              timestamp: DateTime.now(),
            ));
          });
          _scrollToBottom();
        },
      ),
    );
  }

  void _showOfferForm(String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OfferCreationForm(
        vendorId: widget.vendorId,
        offerType: type,
        onSuccess: () {
          setState(() {
            _messages.add(ChatMessage(
              text: "🎉 Awesome! Your offer has been created and will attract more customers!",
              isAI: true,
              timestamp: DateTime.now(),
            ));
          });
          _scrollToBottom();
        },
      ),
    );
  }

  void _showInventoryDialog() {
    // Placeholder for inventory management
    setState(() {
      _messages.add(ChatMessage(
        text: "📦 Inventory management feature coming soon! For now, you can manage stock status from your menu tab.",
        isAI: true,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _showAddToExistingDialog(String imagePath) {
    // Placeholder for adding image to existing product
    setState(() {
      _messages.add(ChatMessage(
        text: "📸 Image-to-product feature coming soon! For now, you can add images when creating new items.",
        isAI: true,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Chat Interface
        if (_isExpanded)
          Positioned(
            bottom: 80,
            right: 16,
            child: SlideTransition(
              position: _chatSlideAnimation,
              child: FadeTransition(
                opacity: _chatOpacityAnimation,
                child: Container(
                  width: 320,
                  height: 500,
                  decoration: BoxDecoration(
                    color: TinyTrailsColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildChatHeader(),
                      Expanded(child: _buildMessagesList()),
                      _buildMessageInput(),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Floating Action Button
        Positioned(
          bottom: 16,
          right: 16,
          child: AnimatedBuilder(
            animation: _fabScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _fabScaleAnimation.value,
                child: FloatingActionButton(
                  onPressed: _toggleChat,
                  backgroundColor: TinyTrailsColors.emeraldGreen,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isExpanded
                        ? const Icon(Icons.close, key: Key('close'))
                        : const Icon(Icons.smart_toy, key: Key('bot')),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [TinyTrailsColors.emeraldGreen, TinyTrailsColors.emerald700],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trail AI',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Your Business Assistant',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isLoading) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: message.isAI ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: message.isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.isAI)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: TinyTrailsColors.emerald50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy, size: 16, color: TinyTrailsColors.emeraldGreen),
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: message.isAI ? TinyTrailsColors.gray100 : TinyTrailsColors.emeraldGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.imagePath != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(message.imagePath!),
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        message.text,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: message.isAI ? TinyTrailsColors.charcoal : Colors.white,
                          height: 1.4,
                        ),
                      ),
                      if (message.actions.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ...message.actions.map((action) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: action.onTap,
                              style: TextButton.styleFrom(
                                backgroundColor: TinyTrailsColors.emeraldGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                action.label,
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: TinyTrailsColors.emerald50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, size: 16, color: TinyTrailsColors.emeraldGreen),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TinyTrailsColors.gray100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _chatAnimationController,
      builder: (context, child) {
        final animationValue = (_chatAnimationController.value * 3 - index).clamp(0.0, 1.0);
        return Transform.scale(
          scale: 0.5 + (animationValue * 0.5),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: TinyTrailsColors.emeraldGreen.withAlpha((255 * animationValue).round()),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TinyTrailsColors.gray100,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ask Trail AI anything...',
                hintStyle: GoogleFonts.inter(color: TinyTrailsColors.gray400),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: TinyTrailsColors.emeraldGreen,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => _sendMessage(_messageController.text),
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isAI;
  final DateTime timestamp;
  final String? imagePath;
  final List<ChatAction> actions;

  ChatMessage({
    required this.text,
    required this.isAI,
    required this.timestamp,
    this.imagePath,
    this.actions = const [],
  });
}

class ChatAction {
  final String label;
  final VoidCallback onTap;

  ChatAction({
    required this.label,
    required this.onTap,
  });
}

// Quick Add Form Widget
class QuickAddForm extends StatefulWidget {
  final String vendorId;
  final String vendorCategory;
  final String? imagePath;
  final VoidCallback? onSuccess;

  const QuickAddForm({
    super.key,
    required this.vendorId,
    required this.vendorCategory,
    this.imagePath,
    this.onSuccess,
  });

  @override
  State<QuickAddForm> createState() => _QuickAddFormState();
}

class _QuickAddFormState extends State<QuickAddForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();

  bool _isVeg = true;
  bool _isAdding = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isAdding = true);

    try {
      final now = DateTime.now();
      final product = ProductModel(
        id: '',
        vendorId: widget.vendorId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        isVeg: _isVeg,
        inStock: true,
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        // TODO: Add image upload functionality
        createdAt: now,
        updatedAt: now,
      );

      final addedProduct = await firebaseService.addProduct(product);

      if (addedProduct != null && mounted) {
        Navigator.pop(context);
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: TinyTrailsColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: TinyTrailsColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 20),
              Text(
                widget.vendorCategory == 'food' ? 'Add New Dish' : 'Add New Product',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: TinyTrailsColors.charcoal,
                ),
              ),
              const SizedBox(height: 20),
              if (widget.imagePath != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(widget.imagePath!),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nameController,
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                decoration: InputDecoration(
                  labelText: widget.vendorCategory == 'food' ? 'Dish Name' : 'Product Name',
                  filled: true,
                  fillColor: TinyTrailsColors.gray100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v?.trim().isEmpty ?? true) return 'Required';
                  if (double.tryParse(v!) == null) return 'Invalid price';
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Price (₹)',
                  filled: true,
                  fillColor: TinyTrailsColors.gray100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  filled: true,
                  fillColor: TinyTrailsColors.gray100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (widget.vendorCategory == 'food') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Type: ',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Radio<bool>(
                            value: true,
                            groupValue: _isVeg,
                            onChanged: (value) => setState(() => _isVeg = value!),
                          ),
                          const Text('Veg'),
                          Radio<bool>(
                            value: false,
                            groupValue: _isVeg,
                            onChanged: (value) => setState(() => _isVeg = value!),
                          ),
                          const Text('Non-Veg'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isAdding ? null : _addProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TinyTrailsColors.emeraldGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isAdding
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text(
                          widget.vendorCategory == 'food' ? 'Add Dish' : 'Add Product',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
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

// Offer Creation Form Widget (placeholder)
class OfferCreationForm extends StatefulWidget {
  final String vendorId;
  final String offerType;
  final VoidCallback? onSuccess;

  const OfferCreationForm({
    super.key,
    required this.vendorId,
    required this.offerType,
    this.onSuccess,
  });

  @override
  State<OfferCreationForm> createState() => _OfferCreationFormState();
}

class _OfferCreationFormState extends State<OfferCreationForm> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: TinyTrailsColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 20),
            Text(
              'Create Offer',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: TinyTrailsColors.charcoal,
              ),
            ),
            const SizedBox(height: 20),
            const Text('🚧 Offer creation feature coming soon!'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onSuccess?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TinyTrailsColors.emeraldGreen,
                ),
                child: const Text('Coming Soon'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}