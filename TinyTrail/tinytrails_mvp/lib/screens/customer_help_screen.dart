import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme.dart';

class CustomerHelpScreen extends StatefulWidget {
  const CustomerHelpScreen({super.key});

  @override
  State<CustomerHelpScreen> createState() => _CustomerHelpScreenState();
}

class _CustomerHelpScreenState extends State<CustomerHelpScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _chatMessages = [];
  bool _showChat = false;
  String? _selectedIssue;

  final List<Map<String, dynamic>> _commonIssues = [
    {
      'category': 'Order Issues',
      'icon': Icons.shopping_bag_outlined,
      'issues': [
        'Order not delivered',
        'Wrong items delivered',
        'Items missing from order',
        'Order arrived late',
        'Food quality issue',
        'Order cancelled by vendor',
      ],
    },
    {
      'category': 'Payment Issues',
      'icon': Icons.payment_outlined,
      'issues': [
        'Payment failed but amount deducted',
        'Double charged for order',
        'Refund not received',
        'Unable to make payment',
        'Promo code not applied',
      ],
    },
    {
      'category': 'Account Issues',
      'icon': Icons.person_outline,
      'issues': [
        'Unable to login',
        'OTP not received',
        'Profile update not working',
        'Want to change phone number',
        'Delete my account',
      ],
    },
    {
      'category': 'Delivery Issues',
      'icon': Icons.local_shipping_outlined,
      'issues': [
        'Delivery partner not reachable',
        'Wrong delivery address',
        'Delivery partner behavior',
        'Package damaged during delivery',
      ],
    },
  ];

  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How do I track my order?',
      'answer': 'You can track your order in real-time from the Orders section. Once your order is confirmed, you will see a "Track Order" button.',
    },
    {
      'question': 'How do I cancel my order?',
      'answer': 'You can cancel your order before it starts preparing. Go to Your Orders > Active Orders > Select the order and tap Cancel.',
    },
    {
      'question': 'What is the refund policy?',
      'answer': 'Refunds are processed within 5-7 business days. The amount will be credited to your original payment method.',
    },
    {
      'question': 'How does AI Hygiene verification work?',
      'answer': 'Our AI system analyzes vendor workspace photos daily to ensure cleanliness standards. Vendors must pass this check to accept orders.',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TinyTrailsColors.charcoal),
          onPressed: () {
            if (_showChat) {
              setState(() => _showChat = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _showChat ? 'Support Chat' : 'Help & Support',
          style: GoogleFonts.inter(
            color: TinyTrailsColors.charcoal,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _showChat ? _buildChatView() : _buildHelpView(),
    );
  }

  Widget _buildHelpView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildContactCard(),
        const SizedBox(height: 20),
        _buildSectionTitle('Report an Issue'),
        ...(_commonIssues.map((category) => _buildIssueCategory(category)).toList()),
        const SizedBox(height: 20),
        _buildSectionTitle('Frequently Asked Questions'),
        ..._faqs.map((faq) => _buildFaqCard(faq)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [TinyTrailsColors.royalBlue, TinyTrailsColors.royalBlue700],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.support_agent, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                'Need Help?',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Our support team is available 24/7 to help you with any issues.',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showChat = true;
                      _addBotMessage("Hello! I'm TinyBot, your support assistant. How can I help you today?");
                    });
                  },
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('Start Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: TinyTrailsColors.royalBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calling support...')),
                  );
                },
                icon: const Icon(Icons.phone_outlined),
                label: const Text('Call'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: TinyTrailsColors.charcoal,
        ),
      ),
    );
  }

  Widget _buildIssueCategory(Map<String, dynamic> category) {
    final isExpanded = _selectedIssue == category['category'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: TinyTrailsColors.royalBlue50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(category['icon'], color: TinyTrailsColors.royalBlue),
            ),
            title: Text(
              category['category'],
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: TinyTrailsColors.charcoal,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: TinyTrailsColors.gray400,
            ),
            onTap: () {
              setState(() {
                _selectedIssue = isExpanded ? null : category['category'];
              });
            },
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: (category['issues'] as List<String>).map((issue) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    dense: true,
                    title: Text(
                      issue,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: TinyTrailsColors.gray500,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20, color: TinyTrailsColors.gray400),
                    onTap: () {
                      setState(() {
                        _showChat = true;
                        _addBotMessage("I understand you're facing an issue with: $issue\n\nI'm here to help! Can you please provide more details about your problem?");
                      });
                    },
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFaqCard(Map<String, dynamic> faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          faq['question'],
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: TinyTrailsColors.charcoal,
          ),
        ),
        children: [
          Text(
            faq['answer'],
            style: GoogleFonts.inter(
              fontSize: 13,
              color: TinyTrailsColors.gray500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatView() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            reverse: true,
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final message = _chatMessages[_chatMessages.length - 1 - index];
              return _buildChatBubble(message);
            },
          ),
        ),
        _buildQuickActions(),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> message) {
    final isBot = message['isBot'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBot) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: TinyTrailsColors.royalBlue,
              child: const Icon(Icons.support_agent, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isBot ? Colors.white : TinyTrailsColors.royalBlue,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: isBot ? const Radius.circular(4) : null,
                  bottomRight: !isBot ? const Radius.circular(4) : null,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message['text'],
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isBot ? TinyTrailsColors.charcoal : Colors.white,
                ),
              ),
            ),
          ),
          if (!isBot) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final quickActions = [
      'Track my order',
      'Request refund',
      'Talk to agent',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: quickActions.map((action) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OutlinedButton(
                onPressed: () => _sendQuickAction(action),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: TinyTrailsColors.royalBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  action,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: TinyTrailsColors.royalBlue,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: GoogleFonts.inter(color: TinyTrailsColors.gray400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: TinyTrailsColors.gray100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: TinyTrailsColors.royalBlue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _addBotMessage(String text) {
    setState(() {
      _chatMessages.add({'text': text, 'isBot': true});
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _chatMessages.add({'text': text, 'isBot': false});
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _addUserMessage(text);
    _messageController.clear();

    Future.delayed(const Duration(seconds: 1), () {
      _addBotMessage("Thank you for your message. Our support team has been notified and will get back to you shortly. In the meantime, is there anything else I can help you with?");
    });
  }

  void _sendQuickAction(String action) {
    _addUserMessage(action);

    Future.delayed(const Duration(milliseconds: 500), () {
      String response;
      switch (action) {
        case 'Track my order':
          response = "I can help you track your order! Please go to 'Your Orders' in the Profile tab to see real-time tracking for all your active orders.";
          break;
        case 'Request refund':
          response = "To request a refund, please select the specific order from 'Your Orders' and tap on 'Request Refund'. Our team will process it within 5-7 business days.";
          break;
        case 'Talk to agent':
          response = "I'm connecting you to a live agent. Please wait a moment... A support executive will be with you shortly.";
          break;
        default:
          response = "I'll help you with that. Can you please provide more details?";
      }
      _addBotMessage(response);
    });
  }
}
