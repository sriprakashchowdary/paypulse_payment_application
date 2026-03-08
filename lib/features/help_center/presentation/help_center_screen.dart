import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/premium_widgets.dart';

class HelpCenterScreen extends ConsumerStatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  ConsumerState<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends ConsumerState<HelpCenterScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();

  bool _isListening = false;
  bool _isBotTyping = false;
  String? _selectedCategory;
  String? _ticketNumber;

  final List<String> _categories = [
    'Transaction Failed',
    'Card Issues',
    'Gold Investment',
    'Account Security',
    'KYC Verification',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _startChat();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);

    _tts.setErrorHandler((msg) {
      debugPrint("TTS Error: $msg");
      setState(() => _isBotTyping = false);
    });
  }

  void _startChat() async {
    await Future.delayed(500.ms);
    _addBotMessage(
        "Hello! I'm your PayPulse assistant. How can I help you today? You can type your issue or select one of these common ones as a hint.");
  }

  void _addBotMessage(String text) async {
    setState(() => _isBotTyping = true);
    await Future.delayed(1500.ms);

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(text: text, isUser: false));
        _isBotTyping = false;
      });
      _scrollToBottom();
      await _tts.speak(text);
    }
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });
    _scrollToBottom();
    _handleUserResponse(text);
  }

  void _handleUserResponse(String text) {
    if (_selectedCategory == null) {
      setState(() => _selectedCategory = text);
      _addBotMessage(
          "Got it. You're reporting an issue regarding '$text'. Could you please provide a brief explanation of what's happening?");
    } else if (_ticketNumber == null) {
      _generateTicket();
    }
  }

  void _generateTicket() {
    final random = Random();
    final id = random.nextInt(900000) + 100000;
    final ticket = "PP-$id";
    setState(() => _ticketNumber = ticket);

    _addBotMessage(
        "Thank you for the information. I've created a support ticket for you: #$ticket. Our team will review this and get back to you shortly.");
  }

  void _scrollToBottom() {
    Future.delayed(100.ms, () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      // Check microphone permission
      var status = await Permission.microphone.status;
      if (status.isDenied) {
        status = await Permission.microphone.request();
        if (status.isDenied) {
          if (mounted) {
            PremiumSnackbar.show(
              context,
              'Microphone permission is required for voice input.',
              isError: true,
            );
          }
          return;
        }
      }

      if (status.isPermanentlyDenied) {
        if (mounted) {
          PremiumSnackbar.show(
            context,
            'Please enable microphone permission in settings.',
            isError: true,
          );
        }
        openAppSettings();
        return;
      }

      bool available = await _stt.initialize(
        onStatus: (status) => debugPrint('STT status: $status'),
        onError: (error) => debugPrint('STT error: $error'),
      );
      if (available) {
        setState(() => _isListening = true);
        _stt.listen(
          onResult: (result) {
            if (result.finalResult) {
              setState(() => _isListening = false);
              _textController.text = result.recognizedWords;
              _handleSend();
            }
          },
        );
      } else {
        if (mounted) {
          PremiumSnackbar.show(
            context,
            'Speech recognition is not available on this device.',
            isError: true,
          );
        }
      }
    } else {
      setState(() => _isListening = false);
      _stt.stop();
    }
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      _textController.clear();
      _addUserMessage(text);
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _stt.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isBotTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const TypingIndicator();
                }
                return _ChatBubble(message: _messages[index]);
              },
            ),
          ),
          if (_selectedCategory == null && !_isBotTyping)
            _CategorySelection(
              categories: _categories,
              onSelected: (cat) => _addUserMessage(cat),
            ),
          _buildInputArea(isDark),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : AppColors.bgLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.border,
                ),
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _CircleIconButton(
            icon: _isListening ? Icons.mic : Icons.mic_none,
            color: _isListening ? AppColors.error : AppColors.primary,
            onPressed: _toggleListening,
          )
              .animate(target: _isListening ? 1 : 0)
              .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
          const SizedBox(width: 8),
          _CircleIconButton(
            icon: Icons.send_rounded,
            color: AppColors.primary,
            onPressed: _handleSend,
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : null,
            fontSize: 15,
          ),
        ),
      ).animate().fadeIn(duration: 300.ms).slideX(begin: isUser ? 0.2 : -0.2),
    );
  }
}

class _CategorySelection extends StatelessWidget {
  final List<String> categories;
  final Function(String) onSelected;

  const _CategorySelection({
    required this.categories,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 3.5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const NeverScrollableScrollPhysics(),
        children: categories.map((cat) {
          return InkWell(
            onTap: () => onSelected(cat),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                cat,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn().slideY(begin: 0.5);
  }
}

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .scale(
                  duration: 600.ms,
                  delay: (index * 200).ms,
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                )
                .then()
                .scale(begin: const Offset(1, 1), end: const Offset(0.5, 0.5));
          }),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _CircleIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}
