import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../services/ai_service.dart';
import '../../theme/app_colors.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final List<Message> messages = [];
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final AiService aiService = AiService();
  bool isSending = false;

  Future<void> sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty || isSending) return;

    setState(() {
      isSending = true;
      messages.add(Message(text: text, isUser: true));
    });

    controller.clear();
    scrollToBottom();

    try {
      final reply = await aiService.getRecommendation(prompt: text);
      setState(() {
        messages.add(Message(text: reply, isUser: false));
      });
    } catch (e) {
      setState(() {
        messages.add(Message(text: e.toString(), isUser: false));
      });
    } finally {
      setState(() => isSending = false);
      scrollToBottom();
    }
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.jumpTo(
          scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("NutriFit AI Assistant"),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.heroGradient,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final m = messages[index];
                  final align = m.isUser ? Alignment.centerRight : Alignment.centerLeft;
                  final color = m.isUser ? AppColors.primary : AppColors.card;
                  final textColor = m.isUser ? Colors.white : AppColors.textSecondary;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    alignment: align,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: const BoxConstraints(maxWidth: 320),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(m.isUser ? 16 : 4),
                          bottomRight: Radius.circular(m.isUser ? 4 : 16),
                        ),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        m.text,
                        style: TextStyle(color: textColor, fontSize: 16, height: 1.4),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: "Введите запрос...",
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: isSending ? null : sendMessage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(14),
                      shape: const CircleBorder(),
                    ),
                    child: isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
