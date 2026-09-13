import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart' show Content;
import 'package:image_picker/image_picker.dart';

import '../providers/app_providers.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';

class _ChatMessage {
  _ChatMessage({required this.text, required this.fromUser, this.imagePath});
  final String text;
  final bool fromUser;
  final String? imagePath;
}

/// AIScreen — Smart Farm AI Advisor.
/// Conversational agronomy chat with quick-recommendation chips and
/// crop-disease photo diagnosis, grounded with the latest SoilLog.
class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  final List<Content> _history = [];
  bool _sending = false;

  static const _quickChips = ['Chunguza Udongo', 'Ushauri wa Umwagiliaji', 'Tambua Ugonjwa wa Zao'];

  Future<void> _send(String text, {File? image}) async {
    if (text.trim().isEmpty && image == null) return;
    final gemini = ref.read(geminiServiceProvider);
    final latest = ref.read(latestSoilLogProvider);

    setState(() {
      _messages.add(_ChatMessage(text: text, fromUser: true, imagePath: image?.path));
      _sending = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final reply = image != null
          ? await (text.trim().isEmpty
              ? gemini.askWithImage(imageFile: image, latestSoilLog: latest)
              : gemini.askWithImage(imageFile: image, prompt: text, latestSoilLog: latest))
          : await gemini.askText(prompt: text, latestSoilLog: latest, history: _history);

      _history.add(Content.text(text));
      _history.add(Content.model([]));

      setState(() => _messages.add(_ChatMessage(text: reply, fromUser: false)));
    } on GeminiKeyMissingException {
      setState(() => _messages.add(_ChatMessage(
            text: 'Tafadhali weka Gemini API key yako kwenye Mipangilio ili kutumia AI Advisor.',
            fromUser: false,
          )));
      if (mounted) _promptForApiKey();
    } catch (e) {
      setState(() => _messages.add(_ChatMessage(text: 'Hitilafu: $e', fromUser: false)));
    } finally {
      setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (xfile == null) return;
    await _send('Tambua ugonjwa wa zao kwenye picha hii.', image: File(xfile.path));
  }

  Future<void> _promptForApiKey() async {
    final keyController = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gemini API Key (BYOK)'),
        content: TextField(
          controller: keyController,
          decoration: const InputDecoration(hintText: 'Bandika API key yako hapa'),
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ghairi')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hifadhi')),
        ],
      ),
    );
    if (saved == true && keyController.text.trim().isNotEmpty) {
      await ref.read(geminiServiceProvider).saveApiKey(keyController.text.trim());
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Advisor'),
        actions: [
          IconButton(icon: const Icon(Icons.vpn_key), onPressed: _promptForApiKey),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(14),
              itemCount: _messages.length,
              itemBuilder: (context, i) => _MessageBubble(message: _messages[i]),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickChips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => ActionChip(
                label: Text(_quickChips[i], style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.forestSurface,
                onPressed: _sending ? null : () => _send(_quickChips[i]),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.camera_alt), onPressed: _sending ? null : _pickAndSendImage),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Andika swali lako…'),
                    onSubmitted: _sending ? null : (v) => _send(v),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: _sending
                      ? const SizedBox(
                          width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  onPressed: _sending ? null : () => _send(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryGreen : AppColors.forestSurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(File(message.imagePath!), height: 140, fit: BoxFit.cover),
              ),
            if (message.text.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: message.imagePath != null ? 8 : 0),
                child: Text(message.text, style: const TextStyle(fontSize: 14)),
              ),
          ],
        ),
      ),
    );
  }
}
