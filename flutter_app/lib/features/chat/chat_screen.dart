import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/models.dart' hide Intent;
import '../../models/models.dart' as models;
import 'chat_controller.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String companyId;
  const ChatScreen({super.key, required this.companyId});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  List<models.Intent> _suggestions = [];

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() => Future.delayed(const Duration(milliseconds: 80), () {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });

  void _onTyping(String value) {
    final state = ref.read(chatControllerProvider(widget.companyId));
    if (value.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final norm = value.toLowerCase().trim();
    final matched = state.intents.where((i) {
      if (!i.isActive) return false;
      if (i.name.toLowerCase().contains(norm)) return true;
      return i.trainingPhrases.any((p) => p.toLowerCase().contains(norm));
    }).take(3).toList();
    setState(() => _suggestions = matched);
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    setState(() => _suggestions = []);
    await ref.read(chatControllerProvider(widget.companyId).notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _sendSuggestion(models.Intent intent) {
    final phrase = intent.trainingPhrases.isNotEmpty
        ? intent.trainingPhrases.first
        : intent.name;
    _ctrl.text = phrase;
    setState(() => _suggestions = []);
    _send();
  }

  @override
  Widget build(BuildContext context) {
    final state   = ref.watch(chatControllerProvider(widget.companyId));
    final company = state.company;
    final color   = company?.color ?? AppColors.primary;

    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(company?.name ?? 'Smart Support',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const Text('Online · replies instantly',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ]),
        ]),
      ),
      body: Column(children: [
        // Messages list
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            itemCount: state.messages.length + (state.isTyping ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == state.messages.length) return _TypingBubble(color: color);
              return _MessageBubble(msg: state.messages[i], color: color);
            },
          ),
        ),

        // Typing suggestions
        if (_suggestions.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _suggestions.map((i) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(i.name, style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.primaryLight,
                    side: const BorderSide(color: AppColors.primary),
                    labelStyle: const TextStyle(color: AppColors.primary),
                    onPressed: () => _sendSuggestion(i),
                  ),
                )).toList(),
              ),
            ),
          ),

        // Input area
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: 'Type your question...',
                  filled: true,
                  fillColor: AppColors.grey50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onChanged: _onTyping,
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: color,
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                onPressed: _send,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final Message msg;
  final Color color;
  const _MessageBubble({required this.msg, required this.color});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.sender == MessageSender.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
        decoration: BoxDecoration(
          color: isUser ? color : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Text(msg.content,
            style: TextStyle(
              color: isUser ? Colors.white : AppColors.grey900,
              fontSize: 14,
              height: 1.5,
            )),
      ),
    );
  }
}

// ── Typing Bubble ─────────────────────────────────────────────────────────────
class _TypingBubble extends StatelessWidget {
  final Color color;
  const _TypingBubble({required this.color});
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 7, height: 7,
          decoration: BoxDecoration(color: color.withOpacity(.5), shape: BoxShape.circle),
        )),
      ),
    ),
  );
}
