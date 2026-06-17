import 'dart:async';

/// AI Chat Service for Trail AI
/// Simulates intelligent LLM responses with structured JSON output
class AiChatService {
  /// Sends a message to the AI and returns a structured response
  /// with type, message, and optional data fields
  Future<Map<String, dynamic>> sendMessage(String query) async {
    // Simulate network delay for realistic feel
    await Future.delayed(const Duration(milliseconds: 800));

    final lowerQuery = query.toLowerCase().trim();

    // Check for order-related queries (murukku, order)
    if (lowerQuery.contains('murukku') || lowerQuery.contains('order')) {
      return {
        'type': 'action_order',
        'message':
            'I found Murukku from Lakshmi Sweets. Would you like me to prepare this order?',
        'data': {
          'vendor': 'Lakshmi Sweets',
          'item': 'Murukku',
          'price': 45,
          'address': 'Home - 123 Main St',
        },
      };
    }

    // Check for offer/discount queries
    if (lowerQuery.contains('offer') || lowerQuery.contains('discount')) {
      return {
        'type': 'action_offer',
        'message': 'Here are the top offers near you right now!',
        'data': {
          'offers': [
            '20% off at Biryani Bhai',
            'Free delivery on Street Snacks',
          ],
        },
      };
    }

    // Check for cart/navigate queries
    if (lowerQuery.contains('cart') || lowerQuery.contains('navigate')) {
      return {
        'type': 'action_navigate',
        'message': 'Taking you to your cart now...',
        'data': {
          'route': '/cart',
        },
      };
    }

    // Default greeting/help response
    return {
      'type': 'text',
      'message':
          'I am your Trail AI assistant! I can help you find food, place orders, or check offers. Try asking me about murukku, offers, or your cart!',
    };
  }

  /// Gets quick action suggestions for the user
  List<String> getQuickActions() {
    return [
      'Order Murukku',
      'Show Offers',
      'Take me to Cart',
    ];
  }
}
