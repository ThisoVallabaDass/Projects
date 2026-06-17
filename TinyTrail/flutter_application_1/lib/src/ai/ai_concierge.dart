import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../backend.dart';
import '../shared.dart';

class AiConciergeScreen extends StatefulWidget {
  const AiConciergeScreen({super.key});

  @override
  State<AiConciergeScreen> createState() => _AiConciergeScreenState();
}

class _AiConciergeScreenState extends State<AiConciergeScreen> {
  final TextEditingController controller = TextEditingController();
  final List<_ChatMessage> messages = <_ChatMessage>[
    const _ChatMessage(
      fromUser: false,
      text: 'Hi, I am TinyTrails. Search using voice or text.',
    ),
  ];
  bool isLoading = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add(_ChatMessage(fromUser: true, text: text));
      isLoading = true;
    });
    controller.clear();

    try {
      final response = await http.post(
        Uri.parse('${BackendConfig.baseUrl}/ai/query'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{
          'text': text,
          'locale': 'en-IN',
          'location': '600062',
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final suggestions =
            (payload['vendorSuggestions'] as List<dynamic>? ?? <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .map(
                  (item) => _SuggestionCardData(
                    vendorName: 'Vendor ${item['vendorId'] ?? ''}'.trim(),
                    productName: 'Suggested item',
                    priceLabel: 'Tap to add',
                  ),
                )
                .toList();

        setState(() {
          messages.add(
            _ChatMessage(
              fromUser: false,
              text: (payload['text'] as String?) ??
                  'Here are some vendors near you.',
              suggestions: suggestions,
            ),
          );
        });
      } else {
        throw Exception('backend error');
      }
    } catch (_) {
      setState(() {
        messages.add(
          const _ChatMessage(
            fromUser: false,
            text: 'Here are some vendors near you.',
            suggestions: <_SuggestionCardData>[
              _SuggestionCardData(
                vendorName: "Lakshmi's Kitchen",
                productName: 'Homemade Murukku',
                priceLabel: 'Rs. 50',
              ),
              _SuggestionCardData(
                vendorName: 'Anita Snacks',
                productName: 'Masala Bajji Combo',
                priceLabel: 'Rs. 60',
              ),
            ],
          ),
        );
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask TinyTrails'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 6, 18, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Search using voice or text',
                style: TextStyle(color: AppPalette.muted),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Align(
                  alignment: message.fromUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 310),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: message.fromUser
                            ? AppPalette.customer
                            : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.text,
                            style: TextStyle(
                              color: message.fromUser
                                  ? Colors.white
                                  : AppPalette.ink,
                              height: 1.45,
                            ),
                          ),
                          if (message.suggestions.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ...message.suggestions.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.vendorName,
                                        style: const TextStyle(
                                          color: AppPalette.ink,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.productName,
                                        style: const TextStyle(color: AppPalette.muted),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            item.priceLabel,
                                            style: const TextStyle(
                                              color: AppPalette.ink,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const Spacer(),
                                          FilledButton.tonal(
                                            onPressed: () {},
                                            child: const Text('Add to Cart'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton.tonal(
                                  onPressed: () {},
                                  child: const Text('Add Suggested Items'),
                                ),
                                FilledButton.tonal(
                                  onPressed: () {},
                                  child: const Text('View Vendors'),
                                ),
                                FilledButton.tonal(
                                  onPressed: () {},
                                  child: const Text('Order Now'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isLoading) const LinearProgressIndicator(minHeight: 2),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: "Try: murukku near me",
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Voice not supported yet on this build. Use text for now.'),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Ink(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppPalette.customer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic_rounded, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: isLoading ? null : _send,
                    child: const Text('Send'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.fromUser,
    required this.text,
    this.suggestions = const <_SuggestionCardData>[],
  });

  final bool fromUser;
  final String text;
  final List<_SuggestionCardData> suggestions;
}

class _SuggestionCardData {
  const _SuggestionCardData({
    required this.vendorName,
    required this.productName,
    required this.priceLabel,
  });

  final String vendorName;
  final String productName;
  final String priceLabel;
}
