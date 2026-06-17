import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/ai_chat_service.dart';
import '../services/cart_service.dart';
import '../theme/theme.dart';
import 'customer_cart_tab.dart';

/// Message model for chat
class ChatMessage {
  final String id;
  final String message;
  final bool isUser;
  final String type; // 'text', 'action_order', 'action_offer', 'action_navigate'
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.message,
    required this.isUser,
    this.type = 'text',
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Trail AI Chat Screen
/// Beautiful conversational commerce interface with dynamic widget rendering
class CustomerAiChatScreen extends StatefulWidget {
  const CustomerAiChatScreen({super.key});

  @override
  State<CustomerAiChatScreen> createState() => _CustomerAiChatScreenState();
}

class _CustomerAiChatScreenState extends State<CustomerAiChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiChatService _aiService = AiChatService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Send welcome message
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message:
            'Hello! I\'m Trail AI, your TinyTrails assistant. 👋\n\nI can help you find food, place orders, discover offers, and navigate the app. How can I help you today?',
        isUser: false,
        type: 'text',
      ));
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = text.trim();
    _messageController.clear();

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: userMessage,
        isUser: true,
      ));
      _isLoading = true;
    });

    // Scroll to bottom
    _scrollToBottom();

    // Get AI response
    try {
      final response = await _aiService.sendMessage(userMessage);

      setState(() {
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: response['message'] as String,
          isUser: false,
          type: response['type'] as String,
          data: response['data'] as Map<String, dynamic>?,
        ));
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: 'Sorry, I encountered an error. Please try again.',
          isUser: false,
          type: 'text',
        ));
        _isLoading = false;
      });
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

  void _handleQuickAction(String action) {
    _sendMessage(action);
  }

  void _addToCartAndNavigate(Map<String, dynamic> data) {
    final cart = CartService();

    // Create cart item from order data
    final cartItem = {
      'id': 'murukku-1', // Unique ID for the item
      'name': data['item'] as String,
      'price': (data['price'] as int).toDouble(),
      'isVeg': true, // Assuming vegetarian
      'vendorId': 'lakshmi-sweets',
      'vendorName': data['vendor'] as String,
    };

    // Add to cart
    cart.addItem(cartItem);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${data['item']} to cart!',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: TinyTrailsColors.emeraldGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );

    // Navigate to cart screen
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CustomerCartTab()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TinyTrailsColors.offWhite,
      appBar: AppBar(
        backgroundColor: TinyTrailsColors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: TinyTrailsColors.charcoal),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    TinyTrailsColors.royalBlue,
                    TinyTrailsColors.royalBlue400,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Trail AI',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: TinyTrailsColors.charcoal,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: TinyTrailsColors.gray200,
          ),
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: TinyTrailsColors.gray200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            TinyTrailsColors.royalBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Trail AI is thinking...',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: TinyTrailsColors.slateGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Input Area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  TinyTrailsColors.royalBlue,
                  TinyTrailsColors.royalBlue400,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Trail AI',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: TinyTrailsColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your intelligent food & commerce assistant',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: TinyTrailsColors.gray400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Message Bubble
          Row(
            mainAxisAlignment: message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        TinyTrailsColors.royalBlue,
                        TinyTrailsColors.royalBlue400,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? TinyTrailsColors.royalBlue
                        : TinyTrailsColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.message,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.5,
                      color: message.isUser
                          ? Colors.white
                          : TinyTrailsColors.charcoal,
                    ),
                  ),
                ),
              ),
              if (message.isUser) ...[
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: TinyTrailsColors.royalBlue100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: TinyTrailsColors.royalBlue,
                    size: 16,
                  ),
                ),
              ],
            ],
          ),

          // Dynamic Widget Rendering based on message type
          if (!message.isUser && message.type != 'text')
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 8),
              child: _buildActionWidget(message),
            ),
        ],
      ),
    );
  }

  /// Build dynamic action widgets based on message type
  Widget _buildActionWidget(ChatMessage message) {
    switch (message.type) {
      case 'action_order':
        return _buildOrderCard(message.data!);
      case 'action_offer':
        return _buildOfferCards(message.data!);
      case 'action_navigate':
        return _buildNavigationCard(message.data!);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Order Card Widget - Beautiful card with order details and checkout button
  Widget _buildOrderCard(Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Order Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: TinyTrailsColors.royalBlue50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: TinyTrailsColors.royalBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['item'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: TinyTrailsColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data['vendor'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: TinyTrailsColors.gray400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: TinyTrailsColors.gray200,
                ),
                const SizedBox(height: 16),
                _buildOrderDetailRow(
                  icon: Icons.currency_rupee,
                  label: 'Price',
                  value: '₹${data['price']}',
                ),
                const SizedBox(height: 12),
                _buildOrderDetailRow(
                  icon: Icons.location_on,
                  label: 'Delivery to',
                  value: data['address'] as String,
                ),
              ],
            ),
          ),
          // Checkout Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  TinyTrailsColors.emeraldGreen,
                  TinyTrailsColors.emerald600,
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Add item to cart
                  final cart = CartService();
                  final currentVendorId = cart.getVendorId();
                  final newVendorId = 'lakshmi-sweets'; // From mock data

                  // Check if cart has items from different vendor
                  if (currentVendorId != null && currentVendorId != newVendorId) {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text(
                          'Replace cart items?',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                        content: Text(
                          'Your cart contains items from another shop. Would you like to replace them?',
                          style: GoogleFonts.inter(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text('Cancel', style: GoogleFonts.inter(color: TinyTrailsColors.gray500)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              cart.clearCart();
                              _addToCartAndNavigate(data);
                            },
                            child: Text(
                              'Replace',
                              style: GoogleFonts.inter(color: TinyTrailsColors.royalBlue, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    _addToCartAndNavigate(data);
                  }
                },
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shopping_cart_checkout,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Proceed to Checkout',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: TinyTrailsColors.gray400),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: TinyTrailsColors.gray400,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: TinyTrailsColors.charcoal,
          ),
        ),
      ],
    );
  }

  /// Offer Cards Widget
  Widget _buildOfferCards(Map<String, dynamic> data) {
    final offers = data['offers'] as List<dynamic>;
    return Column(
      children: offers.map((offer) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                TinyTrailsColors.warning.withOpacity(0.1),
                TinyTrailsColors.warning.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: TinyTrailsColors.warning.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TinyTrailsColors.warning,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_offer,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  offer as String,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: TinyTrailsColors.charcoal,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: TinyTrailsColors.gray400,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Navigation Card Widget
  Widget _buildNavigationCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TinyTrailsColors.royalBlue50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TinyTrailsColors.royalBlue200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.navigation,
            color: TinyTrailsColors.royalBlue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'Navigating to ${data['route']}...',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: TinyTrailsColors.royalBlue,
            ),
          ),
        ],
      ),
    );
  }

  /// Input Area with quick actions and text field
  Widget _buildInputArea() {
    final quickActions = _aiService.getQuickActions();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick Action Chips
          if (quickActions.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: quickActions.map((action) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        onPressed: () => _handleQuickAction(action),
                        label: Text(action),
                        labelStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TinyTrailsColors.royalBlue,
                        ),
                        backgroundColor: TinyTrailsColors.royalBlue50,
                        side: BorderSide(
                          color: TinyTrailsColors.royalBlue200,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // Divider
          Container(
            height: 1,
            color: TinyTrailsColors.gray200,
          ),

          // Text Input
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: TinyTrailsColors.offWhite,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: TinyTrailsColors.gray200),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask Trail AI anything...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: TinyTrailsColors.gray400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (text) => _sendMessage(text),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        TinyTrailsColors.royalBlue,
                        TinyTrailsColors.royalBlue400,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _sendMessage(_messageController.text),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
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
}
